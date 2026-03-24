unit CrystalPathFinding_ex;

{ ***************************************************************************** }
{ Crystal Path Finding - High Performance Version for Delphi 13 Florence        }
{ Optimized with Binary Heap, Minimal Memory Allocation and Parallel Safety     }
{ ----------------------------------------------------------------------------- }
{ This is inspired by https://github.com/d-mozulyov/CrystalPathFinding          }
{ ***************************************************************************** }

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

  TTileMapKind = (mkSimple, mkDiagonal, mkDiagonalEx, mkHexagonal);

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

  { TBinaryHeap: Priority Queue Optimization (O(log N)) }
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
  Points := nil;
  Count := 0;
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
  FWidth := AWidth;
  FHeight := AHeight;
  FKind := AKind;
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
  for var i := 0 to High(AExcludes) do
    if (AExcludes[i].X = AP.X) and (AExcludes[i].Y = AP.Y) then Exit(True);
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
  LParams.Starts := [AStart];
  LParams.Finish := AFinish;
  LParams.Weights := AWeights;
  LParams.Excludes := AExcludes;
  Result := DoFindPath(LParams);
end;

function TTileMap.FindPathParallel(const AStarts: array of TPoint; const AFinish: TPoint; const AWeights: PTileMapWeights; const AExcludes: TArray<TPoint>): TTileMapPath;
var
  LPaths: TArray<TTileMapPath>;
  LStartsCopy: TArray<TPoint>;
  I: Integer;
begin
  if Length(AStarts) = 0 then Exit(Default(TTileMapPath));

  { Copy Open Array to TArray for Parallel Processing }
  SetLength(LStartsCopy, Length(AStarts));
  for I := 0 to High(AStarts) do
    LStartsCopy[I] := AStarts[I];

  SetLength(LPaths, Length(LStartsCopy));

  TParallel.For(0, High(LStartsCopy),
    procedure(Index: Integer)
    var ThreadParams: TTileMapParams;
    begin
      ThreadParams.Starts := [LStartsCopy[Index]];
      ThreadParams.Finish := AFinish;
      ThreadParams.Weights := AWeights;
      ThreadParams.Excludes := AExcludes;
      LPaths[Index] := DoFindPath(ThreadParams);
    end);

  var BestIdx := -1;
  var MinDist := MaxDouble;
  for I := 0 to High(LPaths) do
    if (LPaths[I].Count > 0) and (LPaths[I].Distance < MinDist) then
    begin
      MinDist := LPaths[I].Distance;
      BestIdx := I;
    end;

  if BestIdx <> -1 then
  begin
    Result := LPaths[BestIdx];
    for I := 0 to High(LPaths) do if I <> BestIdx then LPaths[I].Free;
  end else Result := Default(TTileMapPath);
end;

function TTileMap.DoFindPath(const AParams: TTileMapParams): TTileMapPath;
var
  Heap: TBinaryHeap;
  Visited: PDouble;
  NodePool: PPathNode;
  PoolCount: Integer;
  Current, Neighbor: PPathNode;
  Directions: array[0..7] of TPoint;
  DirCount: Integer;
  MapSize: Integer;
begin
  Result := Default(TTileMapPath);
  MapSize := FWidth * FHeight;

  { Memory Allocation for Visited Status }
  GetMem(Visited, SizeOf(Double) * MapSize);
  for var i := 0 to MapSize - 1 do Visited[i] := MaxDouble;

  { Pre-allocate Node Pool to avoid frequent memory allocations }
  var MaxNodes := MapSize + 1024;
  GetMem(NodePool, SizeOf(TPathNode) * MaxNodes);
  PoolCount := 0;

  Heap.Initialize(MaxNodes);
  try
    { Define valid directions based on Map Kind }
    if FKind in [TTileMapKind.mkDiagonal, TTileMapKind.mkDiagonalEx] then
    begin
      Directions[0] := TPoint.Create(0,1); Directions[1] := TPoint.Create(0,-1);
      Directions[2] := TPoint.Create(1,0); Directions[3] := TPoint.Create(-1,0);
      Directions[4] := TPoint.Create(1,1); Directions[5] := TPoint.Create(1,-1);
      Directions[6] := TPoint.Create(-1,1); Directions[7] := TPoint.Create(-1,-1);
      DirCount := 8;
    end else begin
      Directions[0] := TPoint.Create(0,1); Directions[1] := TPoint.Create(0,-1);
      Directions[2] := TPoint.Create(1,0); Directions[3] := TPoint.Create(-1,0);
      DirCount := 4;
    end;

    { Setup Initial Nodes }
    for var i := 0 to High(AParams.Starts) do
    begin
      if not IsValid(AParams.Starts[i]) then Continue;
      Current := @NodePool[PoolCount]; Inc(PoolCount);
      Current^.Pos := AParams.Starts[i];
      Current^.G := 0;
      Current^.H := GetHeuristic(Current^.Pos, AParams.Finish);
      Current^.F := Current^.G + Current^.H;
      Current^.Parent := nil;
      Heap.Push(Current);
      Visited[Current^.Pos.Y * FWidth + Current^.Pos.X] := 0;
    end;

    { Main Loop: A* Algorithm }
    while not Heap.IsEmpty do
    begin
      Current := Heap.Pop;

      { Check if target reached }
      if Current^.Pos = AParams.Finish then
      begin
        var TempPath: TArray<TPoint>;
        var Tracer := Current;
        var PathLen := 0;
        while Tracer <> nil do begin Inc(PathLen); Tracer := Tracer^.Parent; end;
        SetLength(TempPath, PathLen);
        Tracer := Current;
        for var i := PathLen - 1 downto 0 do begin TempPath[i] := Tracer^.Pos; Tracer := Tracer^.Parent; end;
        Result.Assign(TempPath, Current^.G);
        Break;
      end;

      { Search Neighbors }
      for var i := 0 to DirCount - 1 do
      begin
        var NextPos := Current^.Pos + Directions[i];
        if not IsValid(NextPos) then Continue;

        var CellIdx := NextPos.Y * FWidth + NextPos.X;
        if (FData + CellIdx)^ = 1 then Continue;
        if IsExcluded(NextPos, AParams.Excludes) then Continue;

        { Calculate cost including weights }
        var StepCost := IfThen((Directions[i].X <> 0) and (Directions[i].Y <> 0), 1.4142, 1.0);
        if AParams.Weights <> nil then StepCost := StepCost + (AParams.Weights^[CellIdx] * 0.1);

        var NewG := Current^.G + StepCost;
        if NewG < Visited[CellIdx] then
        begin
          Visited[CellIdx] := NewG;
          if PoolCount < MaxNodes then
          begin
            Neighbor := @NodePool[PoolCount]; Inc(PoolCount);
            Neighbor^.Pos := NextPos;
            Neighbor^.G := NewG;
            Neighbor^.H := GetHeuristic(NextPos, AParams.Finish);
            Neighbor^.F := Neighbor^.G + Neighbor^.H;
            Neighbor^.Parent := Current;
            Heap.Push(Neighbor);
          end;
        end;
      end;
    end;
  finally
    Heap.Release;
    FreeMem(NodePool);
    FreeMem(Visited);
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
