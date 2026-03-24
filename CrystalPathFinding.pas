unit CrystalPathFinding;

{ ****************************************************************************** }
{ Crystal Path Finding - High Performance Version for Delphi 12 Athens          }
{ Optimized with Binary Heap, Minimal Memory Allocation and Parallel Safety     }
{ ****************************************************************************** }

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
  System.Generics.Collections,
  System.Threading,
  System.Generics.Defaults;

type
  ECrystalPathFinding = class(Exception);

  PPoint = ^TPoint;
  PPointArray = ^TPointArray;
  TPointArray = array[0..MaxInt div SizeOf(TPoint) - 1] of TPoint;

  TTileMapKind = (mkSimple = 0, mkDiagonal, mkDiagonalEx, mkHexagonal);

  TTileMapWeights = array[0..MaxInt div SizeOf(Byte) - 1] of Byte;
  PTileMapWeights = ^TTileMapWeights;

  TTileMapPath = record
    Points: PPointArray;
    Count: NativeInt;
    Distance: Double;
    procedure Free;
    procedure Assign(const APoints: array of TPoint; ADistance: Double);
  end;

  PPathNode = ^TPathNode;
  PPPathNode = ^PPathNode;

  TPathNode = record
    Pos: TPoint;
    G, H: Double;
    F: Double;
    Parent: PPathNode;
  end;

  TTileMapParams = record
    Starts: TArray<TPoint>;
    Finish: TPoint;
    Weights: PTileMapWeights;
    Excludes: TArray<TPoint>;
  end;

  { TBinaryHeap: 우선순위 큐 최적화 (O(log N)) }
  TBinaryHeap = record
  private
    FData: PPPathNode;
    FCount: Integer;
    FCapacity: Integer;
    procedure SiftUp(Index: Integer);
    procedure SiftDown(Index: Integer);
  public
    procedure Initialize(ACapacity: Integer);
    procedure Release;
    procedure Push(Node: PPathNode);
    function Pop: PPathNode;
    function IsEmpty: Boolean; inline;
    property Count: Integer read FCount;
  end;

  TTileMap = class
  private
    FWidth: Integer;
    FHeight: Integer;
    FKind: TTileMapKind;
    FData: PByte;
    FDataLock: TCriticalSection;
    procedure SetWidth(const Value: Integer);
    procedure SetHeight(const Value: Integer);
    function GetDataSize: NativeUInt; inline;
    function GetHeuristic(const AP1, AP2: TPoint): Double; inline;
    function IsValid(const AP: TPoint): Boolean; inline;
    function IsExcluded(const AP: TPoint; const AExcludes: TArray<TPoint>): Boolean;
  protected
    function DoFindPath(const AParams: TTileMapParams): TTileMapPath; virtual;
  public
    constructor Create(AWidth, AHeight: Integer; AKind: TTileMapKind = TTileMapKind.mkSimple);
    destructor Destroy; override;

    function FindPath(const AStart, AFinish: TPoint;
                      const AWeights: PTileMapWeights = nil;
                      const AExcludes: TArray<TPoint> = nil): TTileMapPath;

    function FindPathParallel(const AStarts: array of TPoint;
                              const AFinish: TPoint;
                              const AWeights: PTileMapWeights = nil;
                              const AExcludes: TArray<TPoint> = nil): TTileMapPath;

    property Width: Integer read FWidth write SetWidth;
    property Height: Integer read FHeight write SetHeight;
    property Kind: TTileMapKind read FKind write FKind;
    property Data: PByte read FData;
  end;

implementation

{ TTileMapPath }

procedure TTileMapPath.Assign(const APoints: array of TPoint; ADistance: Double);
begin
  Free;
  Count := Length(APoints);
  if Count > 0 then
  begin
    GetMem(Points, SizeOf(TPoint) * Count);
    Move(APoints[0], Points^, SizeOf(TPoint) * Count);
  end;
  Distance := ADistance;
end;

procedure TTileMapPath.Free;
begin
  if Points <> nil then FreeMem(Points);
  Points :=   nil;
  Count :=    0;
  Distance := 0;
end;

{ TBinaryHeap Implementation }

procedure TBinaryHeap.Initialize(ACapacity: Integer);
begin
  FCapacity := ACapacity;
  GetMem(FData, SizeOf(PPathNode) * FCapacity);
  FCount := 0;
end;

procedure TBinaryHeap.Release;
begin
  if FData <> nil then FreeMem(FData);
  FData := nil;
end;

function TBinaryHeap.IsEmpty: Boolean;
begin
  Result := FCount = 0;
end;

procedure TBinaryHeap.Push(Node: PPathNode);
begin
  if FCount >= FCapacity then Exit;
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
begin
  while Index > 0 do
  begin
    ParentIdx := (Index - 1) div 2;
    if FData[Index]^.F >= FData[ParentIdx]^.F then Break;
    Temp := FData[Index];
    FData[Index] := FData[ParentIdx];
    FData[ParentIdx] := Temp;
    Index := ParentIdx;
  end;
end;

procedure TBinaryHeap.SiftDown(Index: Integer);
var
  ChildIdx: Integer;
  Temp: PPathNode;
begin
  while True do
  begin
    ChildIdx := Index * 2 + 1;
    if ChildIdx >= FCount then Break;
    if (ChildIdx + 1 < FCount) and (FData[ChildIdx + 1]^.F < FData[ChildIdx]^.F) then
      Inc(ChildIdx);
    if FData[Index]^.F <= FData[ChildIdx]^.F then Break;
    Temp := FData[Index];
    FData[Index] := FData[ChildIdx];
    FData[ChildIdx] := Temp;
    Index := ChildIdx;
  end;
end;

{ TTileMap }

constructor TTileMap.Create(AWidth, AHeight: Integer; AKind: TTileMapKind);
begin
  inherited Create;
  FWidth :=    AWidth;
  FHeight :=   AHeight;
  FKind :=     AKind;
  FDataLock := TCriticalSection.Create;
  GetMem(FData, GetDataSize);
  FillChar(FData^, GetDataSize, 0);
end;

destructor TTileMap.Destroy;
begin
  if FData <> nil then FreeMem(FData);
  FDataLock.Free;
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

function TTileMap.IsExcluded(const AP: TPoint; const AExcludes: TArray<TPoint>): Boolean;
begin
  if Length(AExcludes) = 0 then Exit(False);
  for var _i := 0 to High(AExcludes) do
    if (AExcludes[_i].X = AP.X) and (AExcludes[_i].Y = AP.Y) then Exit(True);
  Result := False;
end;

function TTileMap.GetHeuristic(const AP1, AP2: TPoint): Double;
begin
  case FKind of
    TTileMapKind.mkSimple: Result := Abs(AP1.X - AP2.X) + Abs(AP1.Y - AP2.Y);
                    else Result := Sqrt(Sqr(AP1.X - AP2.X) + Sqr(AP1.Y - AP2.Y));
  end;
end;

function TTileMap.FindPath(const AStart, AFinish: TPoint; const AWeights: PTileMapWeights; const AExcludes: TArray<TPoint>): TTileMapPath;
var
  LParams: TTileMapParams;
begin
  LParams.Starts :=   [AStart];
  LParams.Finish :=   AFinish;
  LParams.Weights :=  AWeights;
  LParams.Excludes := AExcludes;
  Result := DoFindPath(LParams);
end;

function TTileMap.FindPathParallel(const AStarts: array of TPoint; const AFinish: TPoint; const AWeights: PTileMapWeights; const AExcludes: TArray<TPoint>): TTileMapPath;
var
  _Paths: TArray<TTileMapPath>;
  _StartsCopy: TArray<TPoint>;
begin
  if Length(AStarts) = 0 then Exit(Default(TTileMapPath));

  // 병렬 처리를 위해 Open Array를 TArray로 명시적 복사 (해결된 부분)
  SetLength(_StartsCopy, Length(AStarts));
  for var _i := 0 to High(AStarts) do
    _StartsCopy[_i] := AStarts[_i];

  SetLength(_Paths, Length(_StartsCopy));

  TParallel.For(0, High(_StartsCopy),
    procedure(Index: Integer)
    var ThreadParams: TTileMapParams;
    begin
      ThreadParams.Starts :=   [_StartsCopy[Index]];
      ThreadParams.Finish :=   AFinish;
      ThreadParams.Weights :=  AWeights;
      ThreadParams.Excludes := AExcludes;

      _Paths[Index] := DoFindPath(ThreadParams);
    end);

  var _BestIdx := -1;
  var _MinDist := MaxDouble;
  for var _i := 0 to High(_Paths) do
    if (_Paths[_i].Count > 0) and (_Paths[_i].Distance < _MinDist) then
    begin
      _MinDist := _Paths[_i].Distance;
      _BestIdx := _i;
    end;

  if _BestIdx <> -1 then
    begin
      Result := _Paths[_BestIdx];
      for var _i := 0 to High(_Paths) do if _i <> _BestIdx then _Paths[_i].Free;
    end
  else
    Result := Default(TTileMapPath);
end;

function TTileMap.DoFindPath(const AParams: TTileMapParams): TTileMapPath;
var
  _Visited: PDouble;
  _NodePool: PPathNode;
  _Current, _Neighbor: PPathNode;
  _Directions: array[0..7] of TPoint;
begin
  Result := Default(TTileMapPath);
  var _MapSize := FWidth * FHeight;

  GetMem(_Visited, SizeOf(Double) * _MapSize);
  for var i := 0 to _MapSize - 1 do _Visited[i] := MaxDouble;

  var MaxNodes := _MapSize + 1024;
  GetMem(_NodePool, SizeOf(TPathNode) * MaxNodes);
  var _PoolCount: Integer := 0;
  var _DirCount: Integer  := 0;
  var _Heap: TBinaryHeap;
  _Heap.Initialize(MaxNodes);

  try
    if FKind in [TTileMapKind.mkDiagonal, TTileMapKind.mkDiagonalEx] then
    begin
      _Directions[0] := TPoint.Create(0,1); _Directions[1] := TPoint.Create(0,-1);
      _Directions[2] := TPoint.Create(1,0); _Directions[3] := TPoint.Create(-1,0);
      _Directions[4] := TPoint.Create(1,1); _Directions[5] := TPoint.Create(1,-1);
      _Directions[6] := TPoint.Create(-1,1); _Directions[7] := TPoint.Create(-1,-1);
      _DirCount := 8;
    end else begin
      _Directions[0] := TPoint.Create(0,1); _Directions[1] := TPoint.Create(0,-1);
      _Directions[2] := TPoint.Create(1,0); _Directions[3] := TPoint.Create(-1,0);
      _DirCount := 4;
    end;

    for var i := 0 to High(AParams.Starts) do
    begin
      if not IsValid(AParams.Starts[i]) then Continue;
      _Current := @_NodePool[_PoolCount]; Inc(_PoolCount);
      _Current^.Pos := AParams.Starts[i];
      _Current^.G := 0;
      _Current^.H := GetHeuristic(_Current^.Pos, AParams.Finish);
      _Current^.F := _Current^.G + _Current^.H;
      _Current^.Parent := nil;
      _Heap.Push(_Current);
      _Visited[_Current^.Pos.Y * FWidth + _Current^.Pos.X] := 0;
    end;

    while not _Heap.IsEmpty do
    begin
      _Current := _Heap.Pop;

      if _Current^.Pos = AParams.Finish then
      begin
        var TempPath: TArray<TPoint>;
        var Tracer := _Current;
        var PathLen := 0;
        while Tracer <> nil do
        begin
          Inc(PathLen);
          Tracer := Tracer^.Parent;
        end;
        SetLength(TempPath, PathLen);
        Tracer := _Current;
        for var i := PathLen - 1 downto 0 do
        begin
          TempPath[i] := Tracer^.Pos; Tracer := Tracer^.Parent;
        end;
        Result.Assign(TempPath, _Current^.G);
        Break;
      end;

      for var i := 0 to _DirCount - 1 do
      begin
        var _NextPos := _Current^.Pos + _Directions[i];
        if not IsValid(_NextPos) then Continue;

        var _CellIdx := _NextPos.Y * FWidth + _NextPos.X;
        if (FData + _CellIdx)^ = 1 then Continue;
        if IsExcluded(_NextPos, AParams.Excludes) then Continue;

        var _StepCost := IfThen((_Directions[i].X <> 0) and (_Directions[i].Y <> 0), 1.4142, 1.0);
        if AParams.Weights <> nil then
          _StepCost := _StepCost + (AParams.Weights^[_CellIdx] * 0.1);

        var _NewG := _Current^.G + _StepCost;
        if _NewG < _Visited[_CellIdx] then
        begin
          _Visited[_CellIdx] := _NewG;
          if _PoolCount < MaxNodes then
          begin
            _Neighbor := @_NodePool[_PoolCount]; Inc(_PoolCount);
            _Neighbor^.Pos := _NextPos;
            _Neighbor^.G := _NewG;
            _Neighbor^.H := GetHeuristic(_NextPos, AParams.Finish);
            _Neighbor^.F := _Neighbor^.G + _Neighbor^.H;
            _Neighbor^.Parent := _Current;
            _Heap.Push(_Neighbor);
          end;
        end;
      end;
    end;
  finally
    _Heap.Release;
    FreeMem(_NodePool);
    FreeMem(_Visited);
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

end.
