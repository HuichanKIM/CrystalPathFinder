unit CrystalPathFinding_ex;

{ ============================================================================ }
{  Crystal Path Finding — High Performance Edition                             }
{  Delphi 12 Athens / Delphi 13 Florence                                       }
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
  System.Generics.Defaults,
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
  { TTileMapPath                                                       }
  { ------------------------------------------------------------------ }
  TTileMapPath = record
    Points:   PPointArray;
    Count:    NativeInt;
    Distance: Double;
    { Primary name is now Release; Free is a back-compat alias }
    procedure Release;
    procedure Free; inline;                                                     // back-compat — calls Release
    procedure Assign(const APoints: array of TPoint; ADistance: Double);
  end;

  PPathNode  = ^TPathNode;
  PPPathNode = ^PPathNode;

  TPathNode = record
    Pos:    TPoint;
    G, H:   Single;                                                             // Single is sufficient; halves node size
    F:      Single;
    Parent: PPathNode;
  end;

  TTileMapParams = record
    Starts:   TArray<TPoint>;
    Finish:   TPoint;
    Weights:  PTileMapWeights;
    Excludes: TArray<TPoint>;
  end;

  { ------------------------------------------------------------------ }
  { TBinaryHeap — min-heap priority queue, O(log N) push/pop           }
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
  { TTileMap                                                           }
  { ------------------------------------------------------------------ }
  TTileMap = class
  private
    FWidth:        Integer;
    FHeight:       Integer;
    FKind:         TTileMapKind;
    FData:         PByte;
    FDataLock:     TCriticalSection;

    { Reusable Visited pool — grows but never shrinks.                  }
    { Stores best-known G cost per cell (MaxSingle = unvisited).        }
    FVisitedPool:     TArray<Single>;
    FVisitedPoolSize: Integer;
    FPoolLock:        TCriticalSection;                                         // guards FVisitedPool resize

    procedure SetWidth(const Value: Integer);
    procedure SetHeight(const Value: Integer);
    function  GetDataSize: NativeUInt; inline;

    { Full heuristic per map kind }
    function  GetHeuristic(const AP1, AP2: TPoint): Single; inline;
    function  IsValid(const AP: TPoint): Boolean; inline;

    { Exclude check now done via a flat Boolean bitmap }
    procedure BuildExcludeBitmap(const AExcludes: TArray<TPoint>; out ABitmap: TArray<Boolean>; AMapSize: Integer);

    { Local snapshot taken under FDataLock before search begins }
    procedure SnapshotMapState(out AData: PByte; out AWidth, AHeight: Integer);

    { Acquire a slice of FVisitedPool, growing if necessary }
    procedure AcquireVisitedSlice(ASize: Integer; out ASlice: PSingle);

  protected
    function DoFindPath(const AParams: TTileMapParams): TTileMapPath; virtual;

  public
    constructor Create(AWidth, AHeight: Integer; AKind: TTileMapKind = TTileMapKind.mkSimple);
    destructor  Destroy; override;

    function FindPath(const AStart, AFinish: TPoint;
                      const AWeights:  PTileMapWeights = nil;
                      const AExcludes: TArray<TPoint>  = nil): TTileMapPath;

    function FindPathParallel(const AStarts:   array of TPoint;
                              const AFinish:   TPoint;
                              const AWeights:  PTileMapWeights = nil;
                              const AExcludes: TArray<TPoint>  = nil
                              ): TTileMapPath;

    property Width:  Integer        read FWidth    write SetWidth;
    property Height: Integer        read FHeight   write SetHeight;
    property Kind:   TTileMapKind   read FKind     write FKind;
    property Data:   PByte          read FData;
  end;

implementation

{ ============================================================================ }
{ TTileMapPath                                                                 }
{ ============================================================================ }

procedure TTileMapPath.Release;
begin
  if Points <> nil then FreeMem(Points);
  Points   := nil;
  Count    := 0;
  Distance := 0;
end;

procedure TTileMapPath.Free;                                                    // back-compat alias
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
  { Double capacity instead of silently dropping the node }
  FCapacity := FCapacity * 2;
  ReallocMem(FData, SizeOf(PPathNode) * FCapacity);
end;

function TBinaryHeap.IsEmpty: Boolean;
begin
  Result := FCount = 0;
end;

procedure TBinaryHeap.Push(Node: PPathNode);
begin
  if FCount >= FCapacity then Grow;                                             // grow, never drop
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
  Temp:      PPathNode;
begin
  while Index > 0 do
  begin
    ParentIdx := (Index - 1) shr 1;                                             // div 2 via shift — marginally faster
    if FData[Index]^.F >= FData[ParentIdx]^.F then Break;
    Temp                  := FData[Index];
    FData[Index]          := FData[ParentIdx];
    FData[ParentIdx]      := Temp;
    Index                 := ParentIdx;
  end;
end;

procedure TBinaryHeap.SiftDown(Index: Integer);
var
  ChildIdx: Integer;
  Temp:     PPathNode;
begin
  while True do
  begin
    ChildIdx := (Index shl 1) + 1;                                              // left child
    if ChildIdx >= FCount then Break;
    if (ChildIdx + 1 < FCount) and
       (FData[ChildIdx + 1]^.F < FData[ChildIdx]^.F) then
      Inc(ChildIdx);                                                            // right child is smaller
    if FData[Index]^.F <= FData[ChildIdx]^.F then Break;
    Temp             := FData[Index];
    FData[Index]     := FData[ChildIdx];
    FData[ChildIdx]  := Temp;
    Index            := ChildIdx;
  end;
end;

{ ============================================================================ }
{ TTileMap — construction / destruction                                        }
{ ============================================================================ }

constructor TTileMap.Create(AWidth, AHeight: Integer; AKind: TTileMapKind);
begin
  inherited Create;

  FWidth    := AWidth;
  FHeight   := AHeight;
  FKind     := AKind;
  FDataLock := TCriticalSection.Create;
  FPoolLock := TCriticalSection.Create;

  GetMem(FData, GetDataSize);
  FillChar(FData^, GetDataSize, 0);

  { Pre-allocate visited pool at map size }
  FVisitedPoolSize := AWidth * AHeight;
  SetLength(FVisitedPool, FVisitedPoolSize);
end;

destructor TTileMap.Destroy;
begin
  if FData <> nil then FreeMem(FData);
  FDataLock.Free;
  FPoolLock.Free;
  inherited;
end;

{ ============================================================================ }
{ TTileMap — private helpers                                                   }
{ ============================================================================ }

function TTileMap.GetDataSize: NativeUInt;
begin
  Result := NativeUInt(FWidth) * NativeUInt(FHeight);
end;

function TTileMap.IsValid(const AP: TPoint): Boolean;
begin
  Result := (AP.X >= 0) and (AP.X < FWidth) and
            (AP.Y >= 0) and (AP.Y < FHeight);
end;

function TTileMap.GetHeuristic(const AP1, AP2: TPoint): Single;
begin
  var _DX := Abs(AP1.X - AP2.X);
  var _DY := Abs(AP1.Y - AP2.Y);
  case FKind of

    TTileMapKind.mkSimple:
      { Manhattan distance — admissible for 4-directional grids }
      Result := _DX + _DY;

    TTileMapKind.mkDiagonal,
    TTileMapKind.mkDiagonalEx:
      { Chebyshev / Octile distance — admissible for 8-directional grids  }
      { = max(_DX,_DY) + (sqrt(2)-1)*min(_DX,_DY) ≈ max + 0.4142*min      }
      Result := Max(_DX, _DY) + 0.4142 * Min(_DX, _DY);

    TTileMapKind.mkHexagonal:
      { Offset-coordinate hex grid distance                               }
      { For even-row offset (most common Google-map style):               }
      {   convert offset → cube coords, then use cube distance.           }
      begin
        var CubeX1 := AP1.X - (AP1.Y - (AP1.Y and 1)) div 2;
        var CubeZ1 := AP1.Y;
        var CubeY1 := -CubeX1 - CubeZ1;
        var CubeX2 := AP2.X - (AP2.Y - (AP2.Y and 1)) div 2;
        var CubeZ2 := AP2.Y;
        var CubeY2 := -CubeX2 - CubeZ2;
        Result := (Abs(CubeX1 - CubeX2) +
                   Abs(CubeY1 - CubeY2) +
                   Abs(CubeZ1 - CubeZ2)) / 2.0;
      end;

  else
    Result := Sqrt(_DX * _DX + _DY * _DY);
  end;
end;

{ Build a flat Boolean bitmap for O(1) exclude lookup.                       }
{ ABitmap[Y*AWidth+X] = True means the cell is excluded.                     }
{ Returns immediately (zero-length bitmap) when AExcludes is empty.          }
procedure TTileMap.BuildExcludeBitmap(const AExcludes: TArray<TPoint>;
                                      out ABitmap: TArray<Boolean>;
                                      AMapSize: Integer);
begin
  if Length(AExcludes) = 0 then
  begin
    ABitmap := nil;
    Exit;
  end;
  SetLength(ABitmap, AMapSize);
  FillChar(ABitmap[0], AMapSize * SizeOf(Boolean), 0);
  var _Idx: Integer := 0;
  for var _i := 0 to High(AExcludes) do
  begin
    if not IsValid(AExcludes[_i]) then Continue;
    _Idx := AExcludes[_i].Y * FWidth + AExcludes[_i].X;
    ABitmap[_Idx] := True;
  end;
end;

{ Capture a consistent snapshot of FData/FWidth/FHeight under lock.           }
{ DoFindPath works exclusively with these local copies so that a concurrent   }
{ SetWidth/SetHeight call cannot corrupt the search mid-flight.               }
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

{ Hand out a pointer into the shared visited pool.                            }
{ The pool grows (but never shrinks) to cover the largest map seen so far.    }
{ Each DoFindPath call re-fills its slice with MaxSingle before use.          }
procedure TTileMap.AcquireVisitedSlice(ASize: Integer; out ASlice: PSingle);
begin
  FPoolLock.Enter;
  try
    if ASize > FVisitedPoolSize then
    begin
      FVisitedPoolSize := ASize;
      SetLength(FVisitedPool, FVisitedPoolSize);
    end;
    ASlice := @FVisitedPool[0];
  finally
    FPoolLock.Leave;
  end;
end;

{ ============================================================================ }
{ TTileMap — property setters                                                  }
{ ============================================================================ }

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
{ TTileMap — FindPath / FindPathParallel                                       }
{ ============================================================================ }

function TTileMap.FindPath(const AStart, AFinish: TPoint;
                           const AWeights:  PTileMapWeights;
                           const AExcludes: TArray<TPoint>): TTileMapPath;
var
  LParams: TTileMapParams;
begin
  LParams.Starts   := [AStart];
  LParams.Finish   := AFinish;
  LParams.Weights  := AWeights;
  LParams.Excludes := AExcludes;
  Result := DoFindPath(LParams);
end;

function TTileMap.FindPathParallel(const AStarts:   array of TPoint;
                                   const AFinish:   TPoint;
                                   const AWeights:  PTileMapWeights;
                                   const AExcludes: TArray<TPoint>
                                   ): TTileMapPath;
begin
  if Length(AStarts) = 0 then Exit(Default(TTileMapPath));

  { Copy open array to a managed TArray for parallel capture }
  var _StartsCopy: TArray<TPoint>;
  SetLength(_StartsCopy, Length(AStarts));
  for var _i := 0 to High(AStarts) do
    _StartsCopy[_i] := AStarts[_i];

  var _Paths: TArray<TTileMapPath>;
  SetLength(_Paths, Length(_StartsCopy));

  { Zero-initialise the result array BEFORE launching threads.          }
  { If TParallel.For raises internally, any untouched slots will have   }
  { Points=nil, so the cleanup loop below is safe.                      }
  FillChar(_Paths[0], Length(_Paths) * SizeOf(TTileMapPath), 0);

  TParallel.For(0, High(_StartsCopy),
    procedure(Index: Integer)
    var
      ThreadParams: TTileMapParams;
    begin
      ThreadParams.Starts   := [_StartsCopy[Index]];
      ThreadParams.Finish   := AFinish;
      ThreadParams.Weights  := AWeights;
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
      for var _i := 0 to High(_Paths) do
        if _i <> _BestIdx then _Paths[_i].Release;                              // Release, not Free
    end
  else
    Result := Default(TTileMapPath);
end;

{ ============================================================================ }
{ TTileMap — DoFindPath (A* core)                                              }
{ ============================================================================ }

function TTileMap.DoFindPath(const AParams: TTileMapParams): TTileMapPath;
var
  { Local snapshot — immune to concurrent SetWidth/SetHeight }
  _SnapData:          PByte;
  _SnapWidth, SnapH:  Integer;
  _Heap:         TBinaryHeap;
  { Directions split into _Orthogonal + _Diagonal for mkDiagonalEx }
  _Orthogonal: array[0..3] of TPoint;
  _Diagonal:   array[0..3] of TPoint;

  { Helper: checks that a _Diagonal move does not cut a corner }
  function DiagonalClear(const AOrthoA, AOrthoB: TPoint): Boolean;              // compile error ? inline;
  var
    _IdxA, _IdxB: Integer;
  begin
    _IdxA := AOrthoA.Y * _SnapWidth + AOrthoA.X;
    _IdxB := AOrthoB.Y * _SnapWidth + AOrthoB.X;
    Result := ((_SnapData + _IdxA)^ = 0) and ((_SnapData + _IdxB)^ = 0);
  end;

begin
  Result := Default(TTileMapPath);

  { --- Capture a consistent map snapshot  --- }
  SnapshotMapState(_SnapData, _SnapWidth, SnapH);
  var _MapSize := _SnapWidth * SnapH;
  if _MapSize = 0 then Exit;

  { --- Build exclude bitmap --- }
  { Exclude bitmap — O(1) lookup }
  var _ExcludeBitmap: TArray<Boolean>;
  BuildExcludeBitmap(AParams.Excludes, _ExcludeBitmap, _MapSize);
  var _HasExcludes := Length(_ExcludeBitmap) > 0;
  { Pointer into the shared _Visited pool (re-filled each call) }
  var _Visited: PSingle;
  { --- Acquire _Visited slice --- }
  AcquireVisitedSlice(_MapSize, _Visited);
  { Fill with MaxSingle (= unvisited) — FillChar trick for Single }
  for var _i := 0 to _MapSize - 1 do
    _Visited[_i] := MaxSingle;

  { --- Node pool : starts at _MapSize, grows on demand --- }
  var _MaxNodes := _MapSize;
  { Node pool — starts at _MapSize, doubles on overflow }
  var _NodePool: PPathNode;
  GetMem(_NodePool, SizeOf(TPathNode) * _MaxNodes);
  var _PoolCount: Integer := 0;

  _Heap.Initialize(_MaxNodes);
  try
    { --- Direction tables --- }
    _Orthogonal[0] := TPoint.Create( 0,  1);
    _Orthogonal[1] := TPoint.Create( 0, -1);
    _Orthogonal[2] := TPoint.Create( 1,  0);
    _Orthogonal[3] := TPoint.Create(-1,  0);
    _Diagonal[0]   := TPoint.Create( 1,  1);
    _Diagonal[1]   := TPoint.Create( 1, -1);
    _Diagonal[2]   := TPoint.Create(-1,  1);
    _Diagonal[3]   := TPoint.Create(-1, -1);

    var _DirCount: Integer := 0;
    case FKind of
      TTileMapKind.mkSimple,
      TTileMapKind.mkHexagonal: _DirCount := 4;
    else
      _DirCount := 8;                                                           // mkDiagonal, mkDiagonalEx
    end;

    var _Current: PPathNode := nil;;
    var _CellIdx:  Integer := 0;
    { --- Seed start nodes --- }
    for var _j := 0 to High(AParams.Starts) do
    begin
      if not IsValid(AParams.Starts[_j]) then Continue;
      _CellIdx := AParams.Starts[_j].Y * _SnapWidth + AParams.Starts[_j].X;
      if (_SnapData + _CellIdx)^ = 1     then Continue;                         // start on a wall? skip

      { Grow node pool if needed }
      if _PoolCount >= _MaxNodes then
      begin
        _MaxNodes := _MaxNodes * 2;
        ReallocMem(_NodePool, SizeOf(TPathNode) * _MaxNodes);
        _Heap.FCapacity := _MaxNodes;                                           // keep _Heap capacity in sync
        ReallocMem(_Heap.FData, SizeOf(PPathNode) * _MaxNodes);
      end;

      _Current         := @_NodePool[_PoolCount]; Inc(_PoolCount);
      _Current^.Pos    := AParams.Starts[_j];
      _Current^.G      := 0;
      _Current^.H      := GetHeuristic(_Current^.Pos, AParams.Finish);
      _Current^.F      := _Current^.H;
      _Current^.Parent := nil;

      _Heap.Push(_Current);
      _Visited[_CellIdx] := 0;
    end;

    { ================================================================== }
    { Main A* loop                                                       }
    { ================================================================== }
    var _NextPos:  TPoint := Point(0,0);
    var _StepCost: Single := 0;
    var _Neighbor: PPathNode := nil;
    var _NewG:     Single := 0;
    var _TempPath: TArray<TPoint>;
    var _Tracer:   PPathNode := nil;
    var _PathLen:  Integer := 0;

    while not _Heap.IsEmpty do
    begin
      _Current := _Heap.Pop;

      { Stale-node guard:                                                }
      { A node is stale when a shorter path to its cell was found and    }
      { recorded in _Visited AFTER this node was pushed.  Skip it.       }
      _CellIdx := _Current^.Pos.Y * _SnapWidth + _Current^.Pos.X;
      if _Current^.G > _Visited[_CellIdx] + 1e-5 then Continue;

      { --- Goal check --- }
      if _Current^.Pos = AParams.Finish then
      begin
        { Reconstruct path by walking Parent pointers }
        _PathLen := 0;
        _Tracer  := _Current;
        while _Tracer <> nil do
        begin
          Inc(_PathLen);
          _Tracer := _Tracer^.Parent;
        end;

        SetLength(_TempPath, _PathLen);
        _Tracer := _Current;
        for var _i := _PathLen - 1 downto 0 do
        begin
          _TempPath[_i] := _Tracer^.Pos;
          _Tracer      := _Tracer^.Parent;
        end;
        Result.Assign(_TempPath, _Current^.G);
        Break;
      end;

      { --- Expand neighbours --- }
      { _Orthogonal moves (always 4 directions) }
      for var _k := 0 to 3 do
      begin
        _NextPos := _Current^.Pos + _Orthogonal[_k];
        if not IsValid(_NextPos)                     then Continue;
        _CellIdx := _NextPos.Y * _SnapWidth + _NextPos.X;
        if (_SnapData + _CellIdx)^ = 1               then Continue;
        if _HasExcludes and _ExcludeBitmap[_CellIdx] then Continue;

        _StepCost := 1.0;
        if AParams.Weights <> nil then
          _StepCost := _StepCost + AParams.Weights^[_CellIdx] * 0.1;

        _NewG := _Current^.G + _StepCost;
        if _NewG < _Visited[_CellIdx] then
        begin
          _Visited[_CellIdx] := _NewG;

          { Grow node pool dynamically if full }
          if _PoolCount >= _MaxNodes then
          begin
            _MaxNodes := _MaxNodes * 2;
            ReallocMem(_NodePool, SizeOf(TPathNode) * _MaxNodes);
          end;

          _Neighbor         := @_NodePool[_PoolCount]; Inc(_PoolCount);
          _Neighbor^.Pos    := _NextPos;
          _Neighbor^.G      := _NewG;
          _Neighbor^.H      := GetHeuristic(_NextPos, AParams.Finish);
          _Neighbor^.F      := _NewG + _Neighbor^.H;
          _Neighbor^.Parent := _Current;

          _Heap.Push(_Neighbor);
        end;
      end;

      { _Diagonal moves (only for mkDiagonal and mkDiagonalEx) }
      if _DirCount = 8 then
        for var _m := 0 to 3 do
        begin
          _NextPos := _Current^.Pos + _Diagonal[_m];
          if not IsValid(_NextPos)                     then Continue;
          _CellIdx := _NextPos.Y * _SnapWidth + _NextPos.X;
          if (_SnapData + _CellIdx)^ = 1               then Continue;
          if _HasExcludes and _ExcludeBitmap[_CellIdx] then Continue;

          { mkDiagonalEx: block _Diagonal if either _Orthogonal           }
          { neighbour along that _Diagonal is a wall (no corner cutting). }
          if FKind = TTileMapKind.mkDiagonalEx then
          begin
            var OrthoA := TPoint.Create(_Current^.Pos.X + _Diagonal[_m].X, _Current^.Pos.Y);
            var OrthoB := TPoint.Create(_Current^.Pos.X, _Current^.Pos.Y + _Diagonal[_m].Y);
            if not IsValid(OrthoA) or not IsValid(OrthoB) then Continue;
            if not DiagonalClear(OrthoA, OrthoB)          then Continue;
          end;

          { _Diagonal step cost: sqrt(2) ≈ 1.4142 }
          _StepCost := 1.4142;
          if AParams.Weights <> nil then
            _StepCost := _StepCost + AParams.Weights^[_CellIdx] * 0.1;

          _NewG := _Current^.G + _StepCost;
          if _NewG < _Visited[_CellIdx] then
          begin
            _Visited[_CellIdx] := _NewG;

            if _PoolCount >= _MaxNodes then
            begin
              _MaxNodes := _MaxNodes * 2;
              ReallocMem(_NodePool, SizeOf(TPathNode) * _MaxNodes);
            end;

            _Neighbor         := @_NodePool[_PoolCount]; Inc(_PoolCount);
            _Neighbor^.Pos    := _NextPos;
            _Neighbor^.G      := _NewG;
            _Neighbor^.H      := GetHeuristic(_NextPos, AParams.Finish);
            _Neighbor^.F      := _NewG + _Neighbor^.H;
            _Neighbor^.Parent := _Current;

            _Heap.Push(_Neighbor);
          end;
        end;

    end; { while not _Heap.IsEmpty }

  finally
    _Heap.Release;
    FreeMem(_NodePool);
    { _Visited slice is NOT freed — it belongs to FVisitedPool. }
  end;
end;

end.
