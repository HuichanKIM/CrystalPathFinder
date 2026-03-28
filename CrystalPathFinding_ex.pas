unit CrystalPathFinding_ex;

{ ============================================================================ }
{  Crystal Path Finding — High Performance Edition                             }
{  Delphi 13 Florence                                                          }
{                                                                              }
{  Features:                                                                   }
{   • A* algorithm with Binary Heap priority queue                             }
{   • Generation-based visited array (eliminates O(N) reset loop)              }
{   • Thread-safe Parallel pathfinding                                         }
{   • Supports Square, Diagonal, DiagonalEx, and Hexagonal maps                }
{   • Weighted terrain cost support                                            }
{                                                                              }
{  Inspired by https://github.com/d-mozulyov/CrystalPathFinding                }
{ ============================================================================ }

{$SCOPEDENUMS ON}
{$POINTERMATH ON}
{$BOOLEVAL OFF}
{$INLINE ON}

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Math,
  System.SyncObjs,
  System.Threading,
  System.Generics.Collections;

type
  ECrystalPathFinding = class(Exception);

  PPoint      = ^TPoint;
  PPointArray = ^TPointArray;
  TPointArray = array[0..MaxInt div SizeOf(TPoint) - 1] of TPoint;

  TTileMapKind = (mkSimple, mkDiagonal, mkDiagonalEx, mkHexagonal);

  TTileMapWeights  = array[0..MaxInt div SizeOf(Byte) - 1] of Byte;
  PTileMapWeights  = ^TTileMapWeights;

  { ------------------------------------------------------------------ }
  { TTileMapPath - Result of a pathfinding operation                     }
  { ------------------------------------------------------------------ }
  TTileMapPath = record
    Points:   PPointArray;
    Count:    NativeInt;
    Distance: Double;

    procedure Release;
    procedure Free; inline;           // Back-compatibility
    procedure Assign(const APoints: array of TPoint; ADistance: Double);
  end;

  PPathNode = ^TPathNode;
  PPPathNode = ^PPathNode;

  TPathNode = record
    Pos:    TPoint;
    G, H:   Single;                   // G = cost from start, H = heuristic
    F:      Single;                   // F = G + H
    Parent: PPathNode;
    VisitedID: Integer;
  end;

  TTileMapParams = record
    Starts:   TArray<TPoint>;
    Finish:   TPoint;
    Weights:  PTileMapWeights;
    Excludes: TArray<TPoint>;
  end;

  { ------------------------------------------------------------------ }
  { TBinaryHeap - Min-Heap priority queue                                }
  { ------------------------------------------------------------------ }
  TBinaryHeap = record
  private
    FData:     PPPathNode;
    FCount:    Integer;
    FCapacity: Integer;
    procedure Grow; inline;
    procedure SiftUp(Index: Integer);
    procedure SiftDown(Index: Integer);
  public
    procedure Initialize(ACapacity: Integer);
    procedure Release;
    procedure Push(Node: PPathNode); inline;
    function  Pop: PPathNode; inline;
    function  IsEmpty: Boolean; inline;
    property  Count: Integer read FCount;
  end;

  { ------------------------------------------------------------------ }
  { TTileMap - Main pathfinding class                                    }
  { ------------------------------------------------------------------ }
  TTileMap = class
  private
    FWidth:        Integer;
    FHeight:       Integer;
    FKind:         TTileMapKind;
    FData:         PByte;                     // 0 = walkable, 1 = wall
    FDataLock:     TCriticalSection;

    FGlobalNodePool: TArray<TPathNode>; // 프로그램 시작 시 맵 크기만큼 딱 한 번 할당
    FSearchID: Integer; // 탐색할 때마다 1씩 증가

    { Generation-based visited system for O(1) reset and thread safety }
    FGeneration:   UInt64;
    FVisitedG:     TArray<Single>;            // Best known G cost
    FVisitedGen:   TArray<UInt32>;            // Generation stamp
    FVisitedPoolSize: Integer;
    FPoolLock:     TCriticalSection;

    FMapSize: Integer;                        // for Debug ...
    FMaxNodes: Integer;                       // for Debug ...
    FPoolCount: Integer;                      // for Debug ...
    procedure SetWidth(const Value: Integer);
    procedure SetHeight(const Value: Integer);
    function  GetDataSize: NativeUInt; inline;

    function IsValid(const AP: TPoint): Boolean; inline;
    procedure BuildExcludeBitmap(const AExcludes: TArray<TPoint>; out ABitmap: TArray<Boolean>; AWidth, AHeight, AMapSize: Integer);
    procedure SnapshotMapState(out AData: PByte; out AWidth, AHeight: Integer);
    procedure AcquireVisitedSlice(ASize: Integer; out AGSlice: PSingle; out AGGenSlice: PUInt32; out AGen: UInt32);
    function GetOptimalPoolSize(const AMapSize: Integer): Integer;
  protected
    function DoFindPath(const AParams: TTileMapParams): TTileMapPath; virtual;
  public
    constructor Create(AWidth, AHeight: Integer; AKind: TTileMapKind = TTileMapKind.mkSimple);
    destructor  Destroy; override;

    function  GetHeuristic(const AP1, AP2: TPoint): Single; inline;
    function FindPath(const AStart, AFinish: TPoint; const AWeights: PTileMapWeights = nil; const AExcludes: TArray<TPoint> = nil): TTileMapPath;
    function FindPathParallel(const AStarts: array of TPoint; const AFinish: TPoint; const AWeights: PTileMapWeights = nil; const AExcludes: TArray<TPoint> = nil): TTileMapPath;
    { Placeholder for Weighted Jump Point Search (see CrystalWeightedJPS.pas) }
    function FindPathJPS(const AStart, AFinish: TPoint; const AWeights: PTileMapWeights = nil; const AExcludes: TArray<TPoint> = nil): TTileMapPath;

    property Width:  Integer        read FWidth    write SetWidth;
    property Height: Integer        read FHeight   write SetHeight;
    property Kind:   TTileMapKind   read FKind     write FKind;
    property Data:   PByte          read FData;
    // for Debug
    property MapSize:  Integer      read FMapSize;
    property MaxNodes: Integer      read FMaxNodes;
    property PoolCount: Integer     read FPoolCount;
  end;

implementation

{ ============================================================================ }
{ TTileMapPath                                                                 }
{ ============================================================================ }

procedure TTileMapPath.Release;
begin
  if Points <> nil then
  begin
    FreeMem(Points);
    Points := nil;
  end;
  Count := 0;
  Distance := 0;
end;

procedure TTileMapPath.Free; // inline;
begin
  Release;
end;

procedure TTileMapPath.Assign(const APoints: array of TPoint; ADistance: Double);
begin
  Release;
  Count := Length(APoints);
  if Count > 0 then
  begin
    GetMem(Points, SizeOf(TPoint) * Count);
    Move(APoints[0], Points^, SizeOf(TPoint) * Count);
  end;
  Distance := ADistance;
end;

{ ============================================================================ }
{ TBinaryHeap                                                                  }
{ ============================================================================ }

procedure TBinaryHeap.Initialize(ACapacity: Integer);
begin
  FCapacity := Max(ACapacity, 64);
  GetMem(FData, SizeOf(PPathNode) * FCapacity);
  FCount := 0;
end;

procedure TBinaryHeap.Release;
begin
  if FData <> nil then FreeMem(FData);
  FData     := nil;
  FCount    := 0;
  FCapacity := 0;
end;

procedure TBinaryHeap.Grow;
begin
  { Conservative growth: 1.5x instead of 2x to reduce memory overhead }
  var NewCapacity := FCapacity + (FCapacity shr 1);
  ReallocMem(FData, SizeOf(PPathNode) * NewCapacity);
  FCapacity := NewCapacity;
end;

function TBinaryHeap.IsEmpty: Boolean;
begin
  Result := FCount = 0;
end;

procedure TBinaryHeap.Push(Node: PPathNode);
begin
  if FCount >= FCapacity then Grow;
  FData[FCount] := Node;
  SiftUp(FCount);
  Inc(FCount);
end;

function TBinaryHeap.Pop: PPathNode;
begin
  if FCount = 0 then Exit(nil);
  Result := FData[0];
  Dec(FCount);
  if FCount > 0 then
  begin
    FData[0] := FData[FCount];
    SiftDown(0);
  end;
end;

procedure TBinaryHeap.SiftUp(Index: Integer);
var
  ParentIdx: Integer;
  Temp: PPathNode;
  CurrentNode: PPathNode;
begin
  CurrentNode := FData[Index];
  while Index > 0 do
  begin
    ParentIdx := (Index - 1) shr 1;
    if CurrentNode^.F >= FData[ParentIdx]^.F then Break;

    FData[Index] := FData[ParentIdx];
    Index := ParentIdx;
  end;
  FData[Index] := CurrentNode;
end;

procedure TBinaryHeap.SiftDown(Index: Integer);
var
  ChildIdx: Integer;
  Temp: PPathNode;
  CurrentNode: PPathNode;
begin
  CurrentNode := FData[Index];
  while True do
  begin
    ChildIdx := (Index shl 1) + 1;
    if ChildIdx >= FCount then Break;

    if (ChildIdx + 1 < FCount) and (FData[ChildIdx + 1]^.F < FData[ChildIdx]^.F) then
      Inc(ChildIdx);

    if CurrentNode^.F <= FData[ChildIdx]^.F then Break;

    FData[Index] := FData[ChildIdx];
    Index := ChildIdx;
  end;
  FData[Index] := CurrentNode;
end;

{ ============================================================================ }
{ TTileMap                                                                     }
{ ============================================================================ }

constructor TTileMap.Create(AWidth, AHeight: Integer; AKind: TTileMapKind);
begin
  inherited Create;

  FWidth  := AWidth;
  FHeight := AHeight;
  FKind   := AKind;

  FDataLock := TCriticalSection.Create;
  FPoolLock := TCriticalSection.Create;

  GetMem(FData, GetDataSize);
  FillChar(FData^, GetDataSize, 0);

  var _mapsize := GetOptimalPoolSize(AWidth * AHeight);

  SetLength(FGlobalNodePool, _mapsize);
  for var _i := 0 to High(FGlobalNodePool) do
     FGlobalNodePool[_i].G := MaxSingle;
  FSearchID := 0;

  FVisitedPoolSize := AWidth * AHeight;
  SetLength(FVisitedG,   FVisitedPoolSize);
  SetLength(FVisitedGen, FVisitedPoolSize);
  FGeneration := 0;
end;

destructor TTileMap.Destroy;
begin
  if FData <> nil then FreeMem(FData);
  SetLength(FGlobalNodePool, 0);
  FDataLock.Free;
  FPoolLock.Free;
  inherited;
end;

function TTileMap.GetDataSize: NativeUInt;
begin
  Result := NativeUInt(FWidth) * NativeUInt(FHeight);
end;

function TTileMap.IsValid(const AP: TPoint): Boolean;
begin
  Result := (AP.X >= 0) and (AP.X < FWidth) and (AP.Y >= 0) and (AP.Y < FHeight);
end;

{ Calculate optimal initial pool size based on map dimensions }
function TTileMap.GetOptimalPoolSize(const AMapSize: Integer): Integer;
begin
  {
    Adaptive sizing strategy:
    - Small maps (< 10K cells): Use fixed 1024 nodes (sufficient for most cases)
    - Medium maps (10K-100K): Use 10% of map size
    - Large maps (100K-1M): Use 5% of map size
    - Very large maps (> 1M): Use fixed 65536 nodes (reasonable upper limit)

    This avoids excessive allocation while remaining safe for worst-case scenarios.
  }

  Result := AMapSize * 2;
  Exit;

  { Reserved ... }
  if AMapSize < 10000   then Result := AMapSize div 2 else
  if AMapSize < 100000  then Result := AMapSize div 5 else
  if AMapSize < 1000000 then Result := AMapSize div 10 else
  Result := AMapSize;//65536;
end;

function TTileMap.GetHeuristic(const AP1, AP2: TPoint): Single;
begin
  var _DX := Abs(AP1.X - AP2.X);
  var _DY := Abs(AP1.Y - AP2.Y);

  case FKind of
    TTileMapKind.mkSimple:
      Result := _DX + _DY;                                            // Manhattan

    TTileMapKind.mkDiagonal, TTileMapKind.mkDiagonalEx:
      Result := Max(_DX, _DY) + 0.4142 * Min(_DX, _DY);               // Octile

    TTileMapKind.mkHexagonal:
      begin
        var CubeX1 := AP1.X - (AP1.Y - (AP1.Y and 1)) div 2;
        var CubeZ1 := AP1.Y;
        var CubeY1 := -CubeX1 - CubeZ1;
        var CubeX2 := AP2.X - (AP2.Y - (AP2.Y and 1)) div 2;
        var CubeZ2 := AP2.Y;
        var CubeY2 := -CubeX2 - CubeZ2;
        Result := (Abs(CubeX1 - CubeX2) + Abs(CubeY1 - CubeY2) + Abs(CubeZ1 - CubeZ2)) / 2.0;
      end;
  else
    Result := Sqrt(_DX * _DX + _DY * _DY);
  end;
end;

procedure TTileMap.BuildExcludeBitmap(const AExcludes: TArray<TPoint>; out ABitmap: TArray<Boolean>; AWidth, AHeight, AMapSize: Integer);
begin
  if Length(AExcludes) = 0 then
  begin
    ABitmap := nil;
    Exit;
  end;

  SetLength(ABitmap, AMapSize);
  FillChar(ABitmap[0], AMapSize * SizeOf(Boolean), 0);

  for var _i := 0 to High(AExcludes) do
  begin
    var P := AExcludes[_i];
    if (P.X >= 0) and (P.X < AWidth) and (P.Y >= 0) and (P.Y < AHeight) then
      ABitmap[P.Y * AWidth + P.X] := True;
  end;
end;

procedure TTileMap.SnapshotMapState(out AData: PByte; out AWidth, AHeight: Integer);
begin
  FDataLock.Enter;
  try
    AData   := FData;
    AWidth  := FWidth;
    AHeight := FHeight;
  finally
    FDataLock.Leave;
  end;
end;

procedure TTileMap.AcquireVisitedSlice(ASize: Integer;
                                       out AGSlice: PSingle;
                                       out AGGenSlice: PUInt32;
                                       out AGen: UInt32);
begin
  FPoolLock.Enter;
  try
    if ASize > FVisitedPoolSize then
    begin
      FVisitedPoolSize := ASize;
      SetLength(FVisitedG,   ASize);
      SetLength(FVisitedGen, ASize);
    end;

    AGen := TInterlocked.Increment(FGeneration) and $FFFFFFFF;
    AGSlice    := @FVisitedG[0];
    AGGenSlice := @FVisitedGen[0];
  finally
    FPoolLock.Leave;
  end;
end;

procedure TTileMap.SetWidth(const Value: Integer);
begin
  FDataLock.Enter;
  try
    if FWidth <> Value then
    begin
      FWidth := Value;
      ReallocMem(FData, GetDataSize);
      FillChar(FData^, GetDataSize, 0);
    end;
  finally
    FDataLock.Leave;
  end;
end;

procedure TTileMap.SetHeight(const Value: Integer);
begin
  FDataLock.Enter;
  try
    if FHeight <> Value then
    begin
      FHeight := Value;
      ReallocMem(FData, GetDataSize);
      FillChar(FData^, GetDataSize, 0);
    end;
  finally
    FDataLock.Leave;
  end;
end;

{ ============================================================================ }
{ Public Interface                                                             }
{ ============================================================================ }

function TTileMap.FindPath(const AStart, AFinish: TPoint;
                           const AWeights: PTileMapWeights = nil;
                           const AExcludes: TArray<TPoint> = nil): TTileMapPath;
var
  LParams: TTileMapParams;
begin
  LParams.Starts   := [AStart];
  LParams.Finish   := AFinish;
  LParams.Weights  := AWeights;
  LParams.Excludes := AExcludes;
  Result := DoFindPath(LParams);
end;

function TTileMap.FindPathParallel(const AStarts: array of TPoint;
                                   const AFinish: TPoint;
                                   const AWeights: PTileMapWeights = nil;
                                   const AExcludes: TArray<TPoint> = nil): TTileMapPath;
begin
  if Length(AStarts) = 0 then Exit(Default(TTileMapPath));

  var _StartsCopy: TArray<TPoint>;
  SetLength(_StartsCopy, Length(AStarts));
  for var _j := 0 to High(AStarts) do
    _StartsCopy[_j] := AStarts[_j];

  var _Paths: TArray<TTileMapPath>;
  SetLength(_Paths, Length(_StartsCopy));
  FillChar(_Paths[0], Length(_Paths) * SizeOf(TTileMapPath), 0);

  var _BestFound := False;
  var _BestLock := TCriticalSection.Create;
  try
    TParallel.For(0, High(_StartsCopy),
      procedure(Index: Integer)
      var
        _Params: TTileMapParams;
      begin
        { Early exit if best path already found by another thread }
        _BestLock.Enter;
        try
          if _BestFound then Exit;
        finally
          _BestLock.Leave;
        end;

        _Params.Starts   := [_StartsCopy[Index]];
        _Params.Finish   := AFinish;
        _Params.Weights  := AWeights;
        _Params.Excludes := AExcludes;
        _Paths[Index] := DoFindPath(_Params);

        { Mark success if path found }
        if _Paths[Index].Count > 0 then
        begin
          _BestLock.Enter;
          try
            _BestFound := True;
          finally
            _BestLock.Leave;
          end;
        end;
      end);

  var _BestIdx := -1;
  var _MinDist := MaxDouble;
  for var _j := 0 to High(_Paths) do
    if (_Paths[_j].Count > 0) and (_Paths[_j].Distance < _MinDist) then
    begin
      _MinDist := _Paths[_j].Distance;
      _BestIdx := _j;
    end;

  if _BestIdx <> -1 then
  begin
    Result := _Paths[_BestIdx];
    for var _k := 0 to High(_Paths) do
      if _k <> _BestIdx then _Paths[_k].Release;
  end
  else
    Result := Default(TTileMapPath);
  finally
    _BestLock.Free;
  end;
end;

function TTileMap.FindPathJPS(const AStart, AFinish: TPoint;
                              const AWeights: PTileMapWeights = nil;
                              const AExcludes: TArray<TPoint> = nil): TTileMapPath;
begin
  { Full Weighted JPS is implemented in CrystalWeightedJPS.pas }
  Result := FindPath(AStart, AFinish, AWeights, AExcludes);
end;

{ ============================================================================ }
{ DoFindPath - Core A* Algorithm                                               }
{ ============================================================================ }

function TTileMap.DoFindPath(const AParams: TTileMapParams): TTileMapPath;
var
  _SnapData:   PByte;
  _SnapWidth:  Integer;
  _SnapHeight: Integer;

  _VisitedG:   PSingle;
  _VisitedGen: PUInt32;
  _MyGen:      UInt32;

  _Heap:       TBinaryHeap;

  _Orthogonal: array[0..3] of TPoint;
  _Diagonal:   array[0..3] of TPoint;

  function DiagonalClear(const AOrthoA, AOrthoB: TPoint;
                         const ASnapWidth: Integer;
                         const ASnapData: PByte): Boolean; inline;
  var
    _IdxA, _IdxB: Integer;
  begin
    _IdxA := AOrthoA.Y * ASnapWidth + AOrthoA.X;
    _IdxB := AOrthoB.Y * ASnapWidth + AOrthoB.X;
    Result := ((ASnapData + _IdxA)^ = 0) and ((ASnapData + _IdxB)^ = 0);
  end;

begin
  Result := Default(TTileMapPath);

  SnapshotMapState(_SnapData, _SnapWidth, _SnapHeight);
  var _MapSize := _SnapWidth * _SnapHeight;
  if _MapSize = 0 then Exit;

  var _ExcludeBitmap: TArray<Boolean>;
  BuildExcludeBitmap(AParams.Excludes, _ExcludeBitmap, _SnapWidth, _SnapHeight, _MapSize);
  var _HasExcludes := Length(_ExcludeBitmap) > 0;

  AcquireVisitedSlice(_MapSize, _VisitedG, _VisitedGen, _MyGen);

  // Memory Pool size ------------------------------------------------------- //
  var _MaxNodes := Length(FGlobalNodePool);
  // ------------------------------------------------------------------------ //
  var _PoolCount := 0;

  _Heap.Initialize(_MaxNodes);
  try
    _Orthogonal[0] := TPoint.Create(0, 1);
    _Orthogonal[1] := TPoint.Create(0, -1);
    _Orthogonal[2] := TPoint.Create(1, 0);
    _Orthogonal[3] := TPoint.Create(-1, 0);

    _Diagonal[0] := TPoint.Create(1, 1);
    _Diagonal[1] := TPoint.Create(1, -1);
    _Diagonal[2] := TPoint.Create(-1, 1);
    _Diagonal[3] := TPoint.Create(-1, -1);

    var _DirCount := IfThen(FKind in [TTileMapKind.mkSimple, TTileMapKind.mkHexagonal], 4, 8);
    var _IsDiagonalEx := (FKind = TTileMapKind.mkDiagonalEx);

    var _Current: PPathNode := nil;
    var _CellIdx: Integer := 0;

    { Seed start nodes }
    for var _j := 0 to High(AParams.Starts) do
    begin
      if not IsValid(AParams.Starts[_j]) then Continue;

      _CellIdx := AParams.Starts[_j].Y * _SnapWidth + AParams.Starts[_j].X;
      if (_SnapData + _CellIdx)^ = 1 then Continue;
      // Ensuring sufficient memory size -/ emergency use  ------------------ //
      if _PoolCount >= _MaxNodes then
      begin
        _MaxNodes := Length(FGlobalNodePool) + _MapSize;
        SetLength(FGlobalNodePool, _MaxNodes);
        for var _m := High(FGlobalNodePool) downto High(FGlobalNodePool) - (_MapSize-1) do
           FGlobalNodePool[_m].G := MaxSingle;
       end;
      // -------------------------------------------------------------------- //
      _Current         := @FGlobalNodePool[_PoolCount];
                          Inc(_PoolCount);
      _Current^.Pos    := AParams.Starts[_j];
      _Current^.G      := 0;
      _Current^.H      := GetHeuristic(_Current^.Pos, AParams.Finish);
      _Current^.F      := _Current^.H;
      _Current^.Parent := nil;

      _VisitedG[_CellIdx]   := 0;
      _VisitedGen[_CellIdx] := _MyGen;
      _Heap.Push(_Current);
    end;

    { Main A* Loop }
    var _NextPos: TPoint;
    var _StepCost: Single;
    var _Neighbor: PPathNode;
    var _NewG: Single;

    while not _Heap.IsEmpty do
    begin
      _Current := _Heap.Pop;
      _CellIdx := _Current^.Pos.Y * _SnapWidth + _Current^.Pos.X;

      if (_VisitedGen[_CellIdx] = _MyGen) and (_Current^.G > _VisitedG[_CellIdx] + 1e-5) then
        Continue;

      if _Current^.Pos = AParams.Finish then
      begin
        var _PathLen := 0;
        var _Tracer := _Current;
        while _Tracer <> nil do
        begin
          Inc(_PathLen);
          _Tracer := _Tracer^.Parent;
        end;

        var _TempPath: TArray<TPoint>;
        SetLength(_TempPath, _PathLen);

        _Tracer := _Current;
        for var _i := _PathLen - 1 downto 0 do
        begin
          _TempPath[_i] := _Tracer^.Pos;
          _Tracer := _Tracer^.Parent;
        end;

        Result.Assign(_TempPath, _Current^.G);
        Break;
      end;

      { Orthogonal neighbors }
      for var _k := 0 to 3 do
      begin
        _NextPos := _Current^.Pos + _Orthogonal[_k];
        if not IsValid(_NextPos) then Continue;

        _CellIdx := _NextPos.Y * _SnapWidth + _NextPos.X;
        if (_SnapData + _CellIdx)^ = 1 then Continue;
        if _HasExcludes and _ExcludeBitmap[_CellIdx] then Continue;

        _StepCost := 1.0;
        if AParams.Weights <> nil then
          _StepCost := _StepCost + AParams.Weights^[_CellIdx] * 0.1;

        _NewG := _Current^.G + _StepCost;



        if (_VisitedGen[_CellIdx] <> _MyGen) or (_NewG < _VisitedG[_CellIdx]) then
        begin
          _VisitedG[_CellIdx]   := _NewG;
          _VisitedGen[_CellIdx] := _MyGen;
          // Ensuring sufficient memory size -/ emergency use  -------------- //
          if _PoolCount >= _MaxNodes then
          begin
            _MaxNodes := Length(FGlobalNodePool) + _MapSize;
            SetLength(FGlobalNodePool, _MaxNodes);
            for var _m := High(FGlobalNodePool) downto High(FGlobalNodePool) - (_MapSize-1) do
              FGlobalNodePool[_m].G := MaxSingle;
          end;
          // ---------------------------------------------------------------- //
          _Neighbor         := @FGlobalNodePool[_PoolCount];
                               Inc(_PoolCount);
          _Neighbor^.Pos    := _NextPos;
          _Neighbor^.G      := _NewG;
          _Neighbor^.H      := GetHeuristic(_NextPos, AParams.Finish);
          _Neighbor^.F      := _NewG + _Neighbor^.H;
          _Neighbor^.Parent := _Current;

          _Heap.Push(_Neighbor);
        end;
      end;

      { Process diagonal neighbors (8-directional movement) }
      if _DirCount = 8 then
        for var _m := 0 to 3 do
        begin
          _NextPos := _Current^.Pos + _Diagonal[_m];
          if not IsValid(_NextPos) then Continue;

          _CellIdx := _NextPos.Y * _SnapWidth + _NextPos.X;
          if (_SnapData + _CellIdx)^ = 1 then Continue;
          if _HasExcludes and _ExcludeBitmap[_CellIdx] then Continue;
           { DiagonalEx mode: check corner is not blocked }
          if _IsDiagonalEx then
          begin
            var _OrthoA := TPoint.Create(_Current^.Pos.X + _Diagonal[_m].X, _Current^.Pos.Y);
            var _OrthoB := TPoint.Create(_Current^.Pos.X, _Current^.Pos.Y + _Diagonal[_m].Y);
            if not IsValid(_OrthoA) or not IsValid(_OrthoB) then Continue;
            if not DiagonalClear(_OrthoA, _OrthoB, _SnapWidth, _SnapData) then Continue;
          end;

          _StepCost := 1.41421356237;
          if AParams.Weights <> nil then
            _StepCost := _StepCost + AParams.Weights^[_CellIdx] * 0.1;

          _NewG := _Current^.G + _StepCost;

          if (_VisitedGen[_CellIdx] <> _MyGen) or (_NewG < _VisitedG[_CellIdx]) then
          begin
            _VisitedG[_CellIdx]   := _NewG;
            _VisitedGen[_CellIdx] := _MyGen;

            if _PoolCount >= _MaxNodes then _MaxNodes := Min(_MapSize, _MaxNodes * 2);

            _Neighbor         := @FGlobalNodePool[_PoolCount];
                                 Inc(_PoolCount);
            _Neighbor^.Pos    := _NextPos;
            _Neighbor^.G      := _NewG;
            _Neighbor^.H      := GetHeuristic(_NextPos, AParams.Finish);
            _Neighbor^.F      := _NewG + _Neighbor^.H;
            _Neighbor^.Parent := _Current;

            _Heap.Push(_Neighbor);
          end;
        end;
    end;
    // for Debug ...
    FPoolCount := _PoolCount;
  finally
    _Heap.Release;
  end;

  // for Debug ...
  FMaxNodes := _MaxNodes;
  FMapSize  := _MapSize;
end;

end.