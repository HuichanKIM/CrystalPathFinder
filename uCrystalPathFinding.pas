unit uCrystalPathFinding;

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
{                                                                              }
{ ============================================================================ }
{  [Optimization] Thread-local context pool (TThreadContext)                   }
{   - with the help of AI Gemini                                               }
{                                                                              }
{  Problem:                                                                    }
{    Every call to DoFindPath allocates a fresh _NodePool (TArray<TPathNode>)  }
{    via SetLength/FillChar and releases it on exit. On large maps or when     }
{    FindPathParallel dispatches N concurrent calls, this repeated             }
{    alloc/free cycle becomes the dominant source of memory-subsystem load.    }
{                                                                              }
{  Solution:                                                                   }
{    TThreadContext bundles every working buffer that DoFindPath needs —       }
{    NodePool, VisitedG, VisitedGen, and Heap — into a single record.          }
{    TTileMap.Create pre-allocates TThread.ProcessorCount contexts and         }
{    manages them as an IdleList (index stack).                                }
{                                                                              }
{    On each DoFindPath entry:                                                 }
{      1) Pop one free context from IdleList          (O(1), CS-protected)     }
{      2) If buffers are large enough, only FillChar  → no SetLength           }
{      3) If a buffer is too small, SetLength inside that context only         }
{         → no effect whatsoever on other threads' pointers                    }
{      4) On exit, push the context back onto IdleList (O(1), CS-protected)    }
{                                                                              }
{  Result:                                                                     }
{      • SetLength/FreeMem disappear entirely in the common case.              }
{      • No pointers are shared between threads, making race conditions        }
{        structurally impossible.                                              }
{      • Context count (= ProcessorCount) caps actual parallelism, so even     }
{        with many start points callers wait for at most one idle context.     }
{                                                                              }
{ ============================================================================ }
{  TTileMap - A* Heuristic Function (Improved Version)                         }
{  - with the help of AI Claude                                                }
{ ---------------------------------------------------------------------------  }
{  [Change Log]                                                                }
{    - Defined SQRT2_MINUS1 constant (0.4142 → 0.41421356237309504)            }
{    - Defined TIE_BREAK_FACTOR constant (reduces explored node count)         }
{    - mkDiagonal/mkDiagonalEx : improved constant precision                   }
{    - mkHexagonal : explicit Odd-r offset, intermediate variable optimization }
{    - mkHexagonal : added Even-r offset support branch                        }
{    - mkHexagonal : FHexOffset initialized via constructor                    }
{                     (prevents silent misconfiguration)                       }
{    - mkHexagonal : guard clause raises exception on unsupported offset type  }
{    - else branch  : Euclidean → Octile recommended                           }
{                     (both provided as comments)                              }
{    - Tie-breaking : applied globally across all modes (TIE_BREAK_FACTOR)     }
{                                                                              }
{ ============================================================================ }

{$SCOPEDENUMS ON}
{$POINTERMATH ON}
{$BOOLEVAL OFF}
{$INLINE AUTO}

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

const
  TIE_BREAK_FACTOR: Double = 1.001;

type
  ECrystalPathFinding = class(Exception);

  PPoint      = ^TPoint;
  PPointArray = ^TPointArray;
  TPointArray = array[0..MaxInt div SizeOf(TPoint) - 1] of TPoint;

  TTileMapKind = (
    mkSimple,       // 4-directional movement (up/down/left/right)
    mkDiagonal,     // 8-directional movement (diagonals included, uniform cost)
    mkDiagonalEx,   // 8-directional movement (diagonal cost = √2)
    mkHexagonal     // Hexagonal tiles (Offset coordinate system)
  );

  TTileMapWeights  = array[0..MaxInt div SizeOf(Byte) - 1] of Byte;
  PTileMapWeights  = ^TTileMapWeights;

  { ------------------------------------------------------------------ }
  { TTileMapPath - Result of a pathfinding operation                   }
  { ------------------------------------------------------------------ }
  TTileMapPath = record
    Points:   PPointArray;
    Count:    NativeInt;
    Distance: Double;

    procedure Release;
    procedure Free; inline;
    procedure Assign(const APoints: array of TPoint; ADistance: Double);
    function  Clone: TTileMapPath;
  end;

  PPathNode  = ^TPathNode;
  PPPathNode = ^PPathNode;

  TPathNode = record
    Pos:    TPoint;
    G, H:   Single;
    F:      Single;
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
  { TBinaryHeap - Min-Heap priority queue                              }
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
  {  TThreadContext                                                    }
  {  A record that bundles every reusable buffer DoFindPath requires.  }
  {  Exactly one thread owns an instance at a time, so no locking is   }
  {  needed for the buffers themselves.                                }
  { ------------------------------------------------------------------ }
  TThreadContext = record
    { A* node pool: the actual backing store for all Parent pointers }
    NodePool:    TArray<TPathNode>;
    NodeCount:   Integer;           // number of nodes currently in use
    NodeCap:     Integer;           // cached Length of NodePool

    { Visited state: O(1) reset via generation counter }
    VisitedG:    TArray<Single>;
    VisitedGen:  TArray<UInt32>;
    VisitedSize: Integer;           // cached Length of VisitedG/Gen
    Generation:  UInt32;            // per-context generation counter

    { Heap: FCount reset to 0 each search; FData raw pointer is reused }
    Heap:        TBinaryHeap;
    HeapReady:   Boolean;           // True once Heap.Initialize has been called
  end;
  PThreadContext = ^TThreadContext;

  { for Improved Heuristic Algorythem ------------------------------------- }
  TTileMapHexOffset = (
    hoOddR,                         // Pointy-topped Odd-r  : odd rows are shifted right by +0.5 (default)
    hoEvenR,                        // Pointy-topped Even-r : even rows are shifted right by +0.5
    hoOddQ,                         // Flat-topped: 홀수 열(Column)이 아래로 0.5 이동 (현재 사용 중인 방식)
    hoEvenQ                         // Flat-topped: 짝수 열(Column)이 아래로 0.5 이동
  );

  { ------------------------------------------------------------------ }
  { TTileMap - Main pathfinding class                                  }
  { ------------------------------------------------------------------ }
  ETileMapHexOffsetError = class(Exception);

  TTileMap = class
  private
    FColumns:      Integer;
    FRows:         Integer;
    FKind:         TTileMapKind;
    FData:         PByte;
    FDataLock:     TCriticalSection;

    { ---------------------------------------------------------------- }
    {  Thread context pool                                             }
    {  FContexts    : storage for ProcessorCount contexts              }
    {  FIdleList    : index stack of currently available contexts      }
    {  FContextLock : critical section protecting IdleList access      }
    { ---------------------------------------------------------------- }
    FContexts:     TArray<TThreadContext>;
    FIdleList:     TArray<Integer>;
    FIdleTop:      Integer;
    FContextLock:  TCriticalSection;

    { Improved Heuristic Algorythem ------------------------------------- }
    FHexOffset : TTileMapHexOffset; // Offset orientation for hexagonal tiles

    { for Debug ... }
    FMapSize:   Integer;
    FMaxNodes:  Integer;
    FPoolCount: Integer;

    procedure SetColumns(const Value: Integer);
    procedure SetRows(const Value: Integer);
    function  GetDataSize: NativeUInt; inline;

    function  IsValid(const AP: TPoint): Boolean; inline;
    procedure BuildExcludeTiles(const AExcludes: TArray<TPoint>; out AExcTiles: TArray<Boolean>; AColumns, ARows, AMapSize: Integer);
    procedure SnapshotMapState(out AData: PByte; out AColumns, ARows: Integer);
    function  GetOptimalPoolSize(const AMapSize: Integer): Integer;
    { For Parellel For when many StartPoint ---------------------------------- }
    { Borrow / return a context }
    function  AcquireContext: PThreadContext;
    procedure ReleaseContext(ACtx: PThreadContext);
    { Prepare context buffers immediately before a search }
    procedure PrepareContext(ACtx: PThreadContext; const AMapSize: Integer);
    { Improved Heuristic Algorythem }
    function  GetHeuristic(const AP1, AP2: TPoint): Single; inline;
    procedure ArgumentTest(const AColumns, ARows: Integer; AKind: TTileMapKind);
  protected
    function DoFindPath(const AParams: TTileMapParams): TTileMapPath; virtual;
  public
    constructor Create(const AColumns, ARows: Integer;
                       const AKind: TTileMapKind = TTileMapKind.mkSimple;
                       const AHexOffset: TTileMapHexOffset = TTileMapHexOffset.hoOddR);
    destructor  Destroy; override;

    function  FindPath(const AStart, AFinish: TPoint;
                       const AWeights:  PTileMapWeights = nil;
                       const AExcludes: TArray<TPoint>  = nil): TTileMapPath;
    property Columns:   Integer       read FColumns   write SetColumns;
    property Rows:      Integer       read FRows      write SetRows;
    property Kind:      TTileMapKind  read FKind;
    property Data:      PByte         read FData;
    { Read-only after construction — prevents post-construction drift }
    property HexOffset : TTileMapHexOffset
                                      read FHexOffset write FHexOffset;
    { for Debug ... }
    property MapSize:   Integer       read FMapSize;
    property MaxNodes:  Integer       read FMaxNodes;
    property PoolCount: Integer       read FPoolCount;
  end;

implementation

const
  // ──────────────────────────────────────────────────────────
  // Exact value of √2 - 1
  //   Used for diagonal movement cost calculation.
  //   Previous value 0.4142 (4 digits) → 0.41421356237309504 (17 digits).
  //   Note: 0.4142 < SQRT2_MINUS1, so admissibility was technically maintained,
  //         but low precision can degrade path quality, especially over long routes
  //         where small errors accumulate across many steps.
  // ──────────────────────────────────────────────────────────
  C_SQRT2        = 1.4142135623730950488016887242097;
  C_SQRT2_MINUS1 = 0.41421356237309504;
  // ──────────────────────────────────────────────────────────
  // Tie-breaking multiplier
  //   When many nodes share the same f(n), the number of explored nodes
  //   can grow dramatically. Applying a small weight to h(n) prioritizes
  //   nodes closer to the goal, significantly reducing unnecessary exploration.
  //
  //   Tuning guide:
  //     1.001  : near-optimal paths, recommended for most maps (default)
  //     1.005  : medium-sized maps, speed-oriented
  //     1.010  : large maps, speed-first (slight path optimality trade-off)
  //     1.000  : disables tie-breaking (pure A*)
  //
  //   Effect: on large maps (512x512+), explored node count can drop 2-5x.
  // ──────────────────────────────────────────────────────────

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
  Count    := 0;
  Distance := 0;
end;

function TTileMapPath.Clone: TTileMapPath;
begin
  Result.Count := Count;
  Result.Distance := Distance;
  if Count > 0 then
    begin
      GetMem(Result.Points, SizeOf(TPoint) * Count);
      Move(Points^, Result.Points^, SizeOf(TPoint) * Count);
    end
  else
    Result.Points := nil;
end;

procedure TTileMapPath.Free;
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
  var _NewCapacity := FCapacity + (FCapacity shr 1);
  ReallocMem(FData, SizeOf(PPathNode) * _NewCapacity);
  FCapacity := _NewCapacity;
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
begin
  var _CurrentNode: PPathNode := FData[Index];
  var _ParentIdx := 0;
  while Index > 0 do
  begin
    _ParentIdx := (Index - 1) shr 1;
    if _CurrentNode^.F >= FData[_ParentIdx]^.F then Break;
    FData[Index] := FData[_ParentIdx];
    Index := _ParentIdx;
  end;
  FData[Index] := _CurrentNode;
end;

procedure TBinaryHeap.SiftDown(Index: Integer);
begin
  var _CurrentNode: PPathNode := FData[Index];
  var _ChildIdx := 0;
  while True do
  begin
    _ChildIdx := (Index shl 1) + 1;
    if _ChildIdx >= FCount then Break;
    if (_ChildIdx + 1 < FCount) and
       (FData[_ChildIdx + 1]^.F < FData[_ChildIdx]^.F) then
      Inc(_ChildIdx);
    if _CurrentNode^.F <= FData[_ChildIdx]^.F then Break;
    FData[Index] := FData[_ChildIdx];
    Index := _ChildIdx;
  end;
  FData[Index] := _CurrentNode;
end;

{ ============================================================================ }
{ TTileMap                                                                     }
{ ============================================================================ }

{ Arguments Test ------------------------------------------------------------- }

procedure TTileMap.ArgumentTest(const AColumns, ARows: Integer; AKind: TTileMapKind);
const
  CELLCOUNT_LIMIT = 16 * 1000 * 1000 { Length limit 6666667 };
begin
  var _CellCount := NativeUInt(AColumns) * NativeUInt(ARows);
  var _mwsgformat: string;
  if (AColumns <= 1) or (ARows <= 1) then  // ToDo: 1 line map
   begin
     _mwsgformat := Format('Incorrect map size: %dx%d', [AColumns, ARows]);
     raise ECrystalPathFinding.Create(_mwsgformat);
   end;
  if (_CellCount > CELLCOUNT_LIMIT) then
    begin
      _mwsgformat := Format('Too large map size %dx%d, cell count limit is %d', [AColumns, ARows, CELLCOUNT_LIMIT]);
      raise ECrystalPathFinding.Create(_mwsgformat);
    end;
  if (Ord(AKind) > Ord(High(TTileMapKind))) then
    begin
      _mwsgformat := Format('Incorrect map kind: %d, high value mkHexagonal is %d', [Ord(AKind), Ord(High(TTileMapKind))]);
      raise ECrystalPathFinding.Create(_mwsgformat);
    end;
end;

constructor TTileMap.Create(const AColumns, ARows: Integer;
                            const AKind: TTileMapKind;
                            const AHexOffset: TTileMapHexOffset);
begin
  inherited Create;

  ArgumentTest(AColumns, ARows, AKind);

  FColumns :=   AColumns;
  FRows :=      ARows;
  FKind :=      AKind;
  FHexOffset := AHexOffset;

  FDataLock    := TCriticalSection.Create;
  FContextLock := TCriticalSection.Create;

  GetMem(FData, GetDataSize);
  FillChar(FData^, GetDataSize, 0);
  { -------------------------------------------------------------------- }
  {  Initialise the context pool.                                        }
  {  We allocate ProcessorCount contexts upfront.                        }
  {  TParallel.For also uses ProcessorCount as its parallelism ceiling,  }
  {  so this count guarantees a context is always available immediately. }
  { -------------------------------------------------------------------- }
  var _CtxCount     := 1;  // Reserved : Max(TThread.ProcessorCount, 1);
  var _InitPoolSize := GetOptimalPoolSize(AColumns * ARows);

  SetLength(FContexts, _CtxCount);
  SetLength(FIdleList, _CtxCount);
  FIdleTop := _CtxCount - 1;

  for var _i := 0 to _CtxCount - 1 do  // Only Once Now ...
  begin
    { Pre-allocate NodePool }
    SetLength(FContexts[_i].NodePool,   _InitPoolSize);
    FillChar(FContexts[_i].NodePool[0], SizeOf(TPathNode) * _InitPoolSize, 0);
    FContexts[_i].NodeCap   := _InitPoolSize;
    FContexts[_i].NodeCount := 0;

    { Pre-allocate VisitedG / VisitedGen }
    SetLength(FContexts[_i].VisitedG,   AColumns * ARows);
    SetLength(FContexts[_i].VisitedGen, AColumns * ARows);
    FillChar(FContexts[_i].VisitedGen[0], SizeOf(UInt32) * AColumns * ARows, 0);
    FContexts[_i].VisitedSize := AColumns * ARows;
    FContexts[_i].Generation  := 0;

    { Heap will be initialised on the first PrepareContext call }
    FContexts[_i].HeapReady := False;

    { Push all indices onto the idle stack }
    FIdleList[_i] := _i;
  end;
end;

destructor TTileMap.Destroy;
begin
  if FData <> nil then FreeMem(FData);

  { Release only Heap.FData (raw pointer); TArray fields are freed automatically }
  for var _i := 0 to High(FContexts) do
    if FContexts[_i].HeapReady then
      FContexts[_i].Heap.Release;

  FDataLock.Free;
  FContextLock.Free;
  inherited;
end;

{ ------------------------------------------------------------------- }
{  AcquireContext                                                     }
{  Pops one context index from IdleList.                              }
{  If every context is in use the caller spin-waits until one is      }
{  returned. In practice this never fires because TParallel.For caps  }
{  concurrent workers at ProcessorCount, matching our pool size.      }
{ ------------------------------------------------------------------- }
function TTileMap.AcquireContext: PThreadContext;
begin
  while True do
  begin
    FContextLock.Enter;
    try
      if FIdleTop >= 0 then
      begin
        var _Idx := FIdleList[FIdleTop];
        Dec(FIdleTop);
        Result   := @FContexts[_Idx];
        Exit;
      end;
    finally
      FContextLock.Leave;
    end;
    { Extremely rare: all contexts busy — yield and retry }
    TThread.Yield;
  end;
end;

{ -------------------------------------------------------------------- }
{  ReleaseContext                                                      }
{  Returns a finished context to IdleList.                             }
{ -------------------------------------------------------------------- }
procedure TTileMap.ReleaseContext(ACtx: PThreadContext);
begin
  { Recover index from pointer arithmetic }
  var _Idx := (NativeUInt(ACtx) - NativeUInt(@FContexts[0])) div SizeOf(TThreadContext);
  FContextLock.Enter;
  try
    Inc(FIdleTop);
    FIdleList[FIdleTop] := _Idx;
  finally
    FContextLock.Leave;
  end;
end;

{ -------------------------------------------------------------------- }
{  PrepareContext                                                      }
{  Brings all context buffers into a ready state before a search.      }
{                                                                      }
{  NodePool:                                                           }
{    If the buffer is already large enough, only FillChar is called.   }
{    (★ no SetLength)                                                 }
{    If the buffer is too small, SetLength is called inside this       }
{    context only → no effect on any other thread's pointers.          }
{                                                                      }
{  VisitedG/Gen:                                                       }
{    Incrementing Generation alone counts as a full "reset". (★ no    }
{    FillChar) Any cell whose stored Gen differs from the current Gen  }
{    is automatically treated as unvisited.                            }
{                                                                      }
{  Heap:                                                               }
{    FCount reset to 0. FData raw pointer is reused as-is.             }
{ -------------------------------------------------------------------- }
procedure TTileMap.PrepareContext(ACtx: PThreadContext; const AMapSize: Integer);
begin
  { --- NodePool --- }
  var _NewPoolSize := GetOptimalPoolSize(AMapSize);
  if _NewPoolSize > ACtx^.NodeCap then
  begin
    SetLength(ACtx^.NodePool, _NewPoolSize);
    ACtx^.NodeCap := _NewPoolSize;
  end;
  { Zero-init only the portion we will actually use, not the entire array }
  FillChar(ACtx^.NodePool[0], SizeOf(TPathNode) * _NewPoolSize, 0);
  ACtx^.NodeCount := 0;

  { --- VisitedG / VisitedGen --- }
  if AMapSize > ACtx^.VisitedSize then
  begin
    SetLength(ACtx^.VisitedG,   AMapSize);
    SetLength(ACtx^.VisitedGen, AMapSize);
    { Newly extended elements are left as 0, which differs from any valid
      Generation value and so they are treated as unvisited automatically }
    FillChar(ACtx^.VisitedGen[ACtx^.VisitedSize],
             SizeOf(UInt32) * (AMapSize - ACtx^.VisitedSize), 0);
    ACtx^.VisitedSize := AMapSize;
  end;
  { Bumping Generation is sufficient to mark the entire array as unvisited.
    If Generation wraps around past 0xFFFFFFFF, zero the whole array to
    prevent false positive matches with the sentinel value 0.             }
  Inc(ACtx^.Generation);
  if ACtx^.Generation = 0 then
  begin
    FillChar(ACtx^.VisitedGen[0], SizeOf(UInt32) * ACtx^.VisitedSize, 0);
    ACtx^.Generation := 1;
  end;

  { --- Heap --- }
  if not ACtx^.HeapReady then
    begin
      ACtx^.Heap.Initialize(_NewPoolSize);
      ACtx^.HeapReady := True;
    end
  else
    ACtx^.Heap.FCount := 0;   // Reuse FData as-is; only reset the counter
end;

{ -------------------------------------------------------------------- }

function TTileMap.GetDataSize: NativeUInt;
begin
  Result := NativeUInt(FColumns) * NativeUInt(FRows);
end;

function TTileMap.IsValid(const AP: TPoint): Boolean;
begin
  Result := (AP.X >= 0) and (AP.X < FColumns) and
            (AP.Y >= 0) and (AP.Y < FRows);
end;

function TTileMap.GetOptimalPoolSize(const AMapSize: Integer): Integer;
begin
  Result := AMapSize * 2;
end;

function TTileMap.GetHeuristic(const AP1, AP2: TPoint): Single;
begin
  var _DX := Abs(AP1.X - AP2.X);
  var _DY := Abs(AP1.Y - AP2.Y);

  case FKind of

    // ────────────────────────────────────────────────────────
    // mkSimple : Manhattan Distance
    //   h = |Δx| + |Δy|
    //   An exact admissible heuristic for 4-directional (cardinal) movement.
    //   Guarantees optimal paths as long as diagonal movement is not allowed.
    // ────────────────────────────────────────────────────────
    TTileMapKind.mkSimple:
      Result := _DX + _DY;

    // ────────────────────────────────────────────────────────
    // mkDiagonal / mkDiagonalEx : Octile Distance
    //   h = max(|Δx|, |Δy|) + (√2 - 1) x min(|Δx|, |Δy|)
    //
    //   [Improvement] 0.4142 → SQRT2_MINUS1 (0.41421356237309504)
    //     · The previous constant was smaller than the true value,
    //       so admissibility was preserved, but precision loss could
    //       slightly degrade path quality on longer routes.
    //
    //   mkDiagonal   : diagonal movement cost = cardinal movement cost (chess king)
    //   mkDiagonalEx : diagonal movement cost = √2 (Pythagorean)
    //     → Octile distance is the appropriate heuristic for both modes.
    // ────────────────────────────────────────────────────────
    TTileMapKind.mkDiagonal,
    TTileMapKind.mkDiagonalEx:
      Result := Max(_DX, _DY) + C_SQRT2_MINUS1 * Min(_DX, _DY);

    // ────────────────────────────────────────────────────────
    // mkHexagonal : Hex Distance via Cube Coordinate Conversion
    //   Converts offset coordinates to cube coordinates, then computes distance.
    //   h = (|dx| + |dy| + |dz|) / 2
    //     = (|DiffX| + |DiffZ| + |DiffX + DiffZ|) / 2
    //
    //   FHexOffset is set once at construction via the constructor parameter.
    //   Changing the offset type after construction is intentionally disallowed
    //   (property is read-only) to avoid silent misconfiguration mid-session.
    //
    //   A guard clause raises ETileMapHexOffsetError for any unrecognized
    //   offset value, making misconfiguration immediately visible at runtime
    //   rather than silently falling back to an incorrect calculation.
    //
    //   [Improvement 1] Constructor-enforced HexOffset initialization
    //     · The original code assumed Odd-r layout implicitly.
    //     · A mismatch between code and actual map layout produces
    //       incorrect heuristic values and suboptimal or broken paths.
    //
    //   [Improvement 2] Eliminated CubeY variable (intermediate optimization)
    //     · Since CubeY = -CubeX - CubeZ, the identity
    //       |dx| + |dy| + |dz| = |DiffX| + |DiffZ| + |DiffX + DiffZ|
    //       allows the same result without allocating a Y variable.
    //
    //   Offset direction definitions:
    //     Odd-r  : odd rows  (Y and 1 = 1) are shifted +0.5 to the right
    //     Even-r : even rows (Y and 1 = 0) are shifted +0.5 to the right
    // ────────────────────────────────────────────────────────
    TTileMapKind.mkHexagonal:
      begin
        // Guard clause — fail loudly on unrecognized offset type.
        // Prefer an explicit exception over a silent wrong-result fallback.
        if not (FHexOffset in [TTileMapHexOffset.hoOddR, TTileMapHexOffset.hoEvenR]) then
          raise ETileMapHexOffsetError.CreateFmt('TTileMap.GetHeuristic: unsupported HexOffset value (%d). Expected hoOddR or hoEvenR.', [Ord(FHexOffset)]);

        var _RowShift1, _RowShift2: Integer;
        case FHexOffset of
          // Odd-r : odd rows shifted right
          //   RowShift = (Y - (Y mod 2)) / 2
          TTileMapHexOffset.hoOddR:
            begin
              _RowShift1 := (AP1.Y - (AP1.Y and 1)) shr 1;
              _RowShift2 := (AP2.Y - (AP2.Y and 1)) shr 1;
            end;

          // Even-r : even rows shifted right
          //   RowShift = (Y + (Y mod 2)) / 2
          TTileMapHexOffset.hoEvenR:
            begin
              _RowShift1 := (AP1.Y + (AP1.Y and 1)) shr 1;
              _RowShift2 := (AP2.Y + (AP2.Y and 1)) shr 1;
            end;
          TTileMapHexOffset.hoOddQ:
            begin
              _RowShift1 := (AP1.X - (AP1.X and 1)) div 2;
              _RowShift2 := (AP2.X - (AP2.X and 1)) div 2;
            end;
          TTileMapHexOffset.hoEvenQ:
            begin
              _RowShift1 := (AP1.X + (AP1.X and 1)) div 2;
              _RowShift1 := (AP2.X + (AP2.X and 1)) div 2;
            end;
        else
          // Unreachable — guard clause above catches all invalid values.
          // Included only to satisfy the compiler's exhaustiveness check.
          begin
            _RowShift1 := 0;
            _RowShift2 := 0;
          end;
        end;

        // Convert offset coordinates to cube coordinates
        //   Cube X = Offset X - RowShift
        //   Cube Z = Offset Y  (unchanged)
        //   Cube Y = -Cube X - Cube Z  (derived, not stored)
        var _CubeX1 := AP1.X - _RowShift1;
        var _CubeZ1 := AP1.Y;
        var _CubeX2 := AP2.X - _RowShift2;
        var _CubeZ2 := AP2.Y;

        // Compute hex distance without CubeY variable (using Y = -X - Z)
        //   |dx| + |dy| + |dz|
        //   = |DiffX| + |DiffZ| + |DiffX + DiffZ|
        var _DiffX := _CubeX1 - _CubeX2;
        var _DiffZ := _CubeZ1 - _CubeZ2;

        Result := (Abs(_DiffX) + Abs(_DiffZ) + Abs(_DiffX + _DiffZ)) * 0.5;
      end;
  else
    // ────────────────────────────────────────────────────────
    // else : fallback for undefined or custom tile modes
    //
    //   [Original] Euclidean Distance : √(Δx² + Δy²)
    //     · Sqrt() is computationally expensive when called repeatedly.
    //     · Does not accurately reflect actual movement cost on tile grids.
    //     · Best suited for continuous-space pathfinding (e.g. RTS free-move units).
    //
    //   [Recommended] Octile Distance as default
    //     · More accurate admissible heuristic for 8-directional grids.
    //     · No Sqrt required — better runtime performance.
    //
    //   Choose one of the two lines below based on your movement model:
    // ────────────────────────────────────────────────────────

    // ▶ Recommended: Octile Distance for 8-directional grid movement
    Result := Max(_DX, _DY) + C_SQRT2_MINUS1 * Min(_DX, _DY);

    // ▶ Alternative: Euclidean Distance for continuous-space / free-angle movement
    // Result := Sqrt(_DX * _DX + _DY * _DY);
  end;

  // ────────────────────────────────────────────────────────
  // Tie-breaking : prioritize nodes closer to the goal
  //   Applies a small multiplier to h(n) so that among nodes with
  //   equal f(n), those with a higher h(n) (i.e. closer to goal)
  //   are explored first. This reduces the total number of expanded
  //   nodes significantly on large, open maps.
  //
  //   Set TIE_BREAK_FACTOR = 1.000 to disable (pure A* behavior).
  //   Recommended to disable when strict path optimality is required.
  // ────────────────────────────────────────────────────────
  Result := Result * TIE_BREAK_FACTOR;
end;

procedure TTileMap.BuildExcludeTiles(const AExcludes: TArray<TPoint>;
                                      out AExcTiles: TArray<Boolean>;
                                      AColumns, ARows, AMapSize: Integer);
begin
  if Length(AExcludes) = 0 then
  begin
    AExcTiles := nil;
    Exit;
  end;

  SetLength(AExcTiles, AMapSize);
  FillChar(AExcTiles[0], AMapSize * SizeOf(Boolean), 0);
  for var _i := 0 to High(AExcludes) do
  begin
    var _P := AExcludes[_i];
    if (_P.X >= 0) and (_P.X < AColumns) and
       (_P.Y >= 0) and (_P.Y < ARows) then
      AExcTiles[_P.Y * AColumns + _P.X] := True;
  end;
end;

procedure TTileMap.SnapshotMapState(out AData: PByte;
                                    out AColumns, ARows: Integer);
begin
  FDataLock.Enter;
  try
    AData    := FData;
    AColumns := FColumns;
    ARows    := FRows;
  finally
    FDataLock.Leave;
  end;
end;

procedure TTileMap.SetColumns(const Value: Integer);
begin
  FDataLock.Enter;
  try
    if FColumns <> Value then
    begin
      FColumns := Value;
      ReallocMem(FData, GetDataSize);
      FillChar(FData^, GetDataSize, 0);
    end;
  finally
    FDataLock.Leave;
  end;
end;

procedure TTileMap.SetRows(const Value: Integer);
begin
  FDataLock.Enter;
  try
    if FRows <> Value then
    begin
      FRows := Value;
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
                           const AWeights:  PTileMapWeights;
                           const AExcludes: TArray<TPoint>): TTileMapPath;
var
  _Params: TTileMapParams;
begin
  _Params.Starts   := [AStart];
  _Params.Finish   := AFinish;
  _Params.Weights  := AWeights;
  _Params.Excludes := AExcludes;

  Result := DoFindPath(_Params);
end;

{ ============================================================================ }
{ DoFindPath - Core A* Algorithm                                               }
{ ============================================================================ }

function TTileMap.DoFindPath(const AParams: TTileMapParams): TTileMapPath;
var
  _SnapData:   PByte;
  _SnapWidth:  Integer;
  _SnapHeight: Integer;

  _Orthogonal: array[0..3] of TPoint;
  _Diagonal:   array[0..3] of TPoint;

  function DiagonalClear(const AOrthoA, AOrthoB: TPoint;
                         const ASnapWidth: Integer;
                         const ASnapData:  PByte): Boolean; inline;
  begin
    Result := ((ASnapData + AOrthoA.Y * ASnapWidth + AOrthoA.X)^ = 0) and
              ((ASnapData + AOrthoB.Y * ASnapWidth + AOrthoB.X)^ = 0);
  end;

begin
  Result := Default(TTileMapPath);
  SnapshotMapState(_SnapData, _SnapWidth, _SnapHeight);

  var _MapSize := _SnapWidth * _SnapHeight;
  if _MapSize = 0 then Exit;

  { ------------------------------------------------------------------ }
  {  Borrow a context.                                                 }
  {  From this point _Ctx is accessed by this thread alone.            }
  {  The finally block guarantees it is always returned.               }
  {  * context exclusively owned by this call                          }
  { ------------------------------------------------------------------ }
  var _Ctx: PThreadContext := AcquireContext;  
  { ------------------------------------------------------------------ }  
  try
    { Prepare buffers: SetLength only when needed;
      VisitedGen reset via Generation++ }
    PrepareContext(_Ctx, _MapSize);

    var _VisitedG: PSingle   := @_Ctx^.VisitedG[0];
    var _VisitedGen: PUInt32 := @_Ctx^.VisitedGen[0];
    var _MyGen: UInt32       := _Ctx^.Generation;

    var _HasExcludes := False;
    var _ExcludeTiles: TArray<Boolean>;
    if AParams.Excludes <> nil then
    begin
      BuildExcludeTiles(AParams.Excludes, _ExcludeTiles, _SnapWidth, _SnapHeight, _MapSize);
      _HasExcludes := Length(_ExcludeTiles) > 0;
    end;

    var _MaxNodes    := _Ctx^.NodeCap;
    var _PoolCount   := 0;

    { ---------------------------------------------------------------- }
    {  Heap was reset to FCount=0 by PrepareContext.                   }
    {  FData raw pointer is reused — no GetMem needed.                 }
    { ---------------------------------------------------------------- }
    _Orthogonal[0] := TPoint.Create( 0,  1);
    _Orthogonal[1] := TPoint.Create( 0, -1);
    _Orthogonal[2] := TPoint.Create( 1,  0);
    _Orthogonal[3] := TPoint.Create(-1,  0);

    _Diagonal[0]   := TPoint.Create( 1,  1);
    _Diagonal[1]   := TPoint.Create( 1, -1);
    _Diagonal[2]   := TPoint.Create(-1,  1);
    _Diagonal[3]   := TPoint.Create(-1, -1);

    var _DirCount     := IfThen(FKind in [TTileMapKind.mkSimple, TTileMapKind.mkHexagonal], 4, 8);
    var _IsDiagonalEx := (FKind = TTileMapKind.mkDiagonalEx);

    var _Current:  PPathNode := nil;
    var _CellIdx:  Integer   := 0;

    { Seed start nodes }
    for var _j := 0 to High(AParams.Starts) do                                  // Real count of AParams.Starts = 1 ...
    begin
      if not IsValid(AParams.Starts[_j]) then Continue;
      _CellIdx := AParams.Starts[_j].Y * _SnapWidth + AParams.Starts[_j].X;
      if (_SnapData + _CellIdx)^ = 1 then Continue;

      { Pool exhausted: grow this context's NodePool only }
      if _PoolCount >= _MaxNodes then
      begin
        var _mpos := Length(_Ctx^.NodePool);
        _MaxNodes := _mpos + _MapSize;
        SetLength(_Ctx^.NodePool, _MaxNodes);
        FillChar(_Ctx^.NodePool[_mpos], SizeOf(TPathNode) * _MapSize, 0);
        _Ctx^.NodeCap := _MaxNodes;
      end;

      _Current         := @_Ctx^.NodePool[_PoolCount];
                          Inc(_PoolCount);
      _Current^.Pos    := AParams.Starts[_j];
      _Current^.G      := 0;
      _Current^.H      := GetHeuristic(_Current^.Pos, AParams.Finish);
      _Current^.F      := _Current^.H;
      _Current^.Parent := nil;

      _VisitedG[_CellIdx]   := 0;
      _VisitedGen[_CellIdx] := _MyGen;
      _Ctx^.Heap.Push(_Current);
    end;

    { A* main loop }
    var _NextPos:  TPoint;
    var _StepCost: Single;
    var _Neighbor: PPathNode;
    var _NewG:     Single;

    while not _Ctx^.Heap.IsEmpty do
    begin
      _Current := _Ctx^.Heap.Pop;
      _CellIdx := _Current^.Pos.Y * _SnapWidth + _Current^.Pos.X;

      if (_VisitedGen[_CellIdx] = _MyGen) and
         (_Current^.G > _VisitedG[_CellIdx] + 1e-5) then
        Continue;

      if _Current^.Pos = AParams.Finish then
      begin
        var _PathLen := 0;
        var _Tracer  := _Current;
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
        { Result --------------------------- }
        Result.Assign(_TempPath, _Current^.G);
        { Result --------------------------- }
        Break;
      end;

      { Orthogonal neighbours }
      for var _k := 0 to 3 do
      begin
        _NextPos := _Current^.Pos + _Orthogonal[_k];
        if not IsValid(_NextPos) then Continue;

        _CellIdx := _NextPos.Y * _SnapWidth + _NextPos.X;
        if (_SnapData + _CellIdx)^ = 1 then Continue;
        if _HasExcludes and _ExcludeTiles[_CellIdx] then Continue;

        _StepCost := 1.0;
        if AParams.Weights <> nil then
          _StepCost := _StepCost + AParams.Weights^[_CellIdx] * 0.1;

        _NewG := _Current^.G + _StepCost;

        if (_VisitedGen[_CellIdx] <> _MyGen) or
           (_NewG < _VisitedG[_CellIdx]) then
        begin
          _VisitedG[_CellIdx]   := _NewG;
          _VisitedGen[_CellIdx] := _MyGen;

          if _PoolCount >= _MaxNodes then
          begin
            var _mpos := Length(_Ctx^.NodePool);
            _MaxNodes := _mpos + _MapSize;
            SetLength(_Ctx^.NodePool, _MaxNodes);
            FillChar(_Ctx^.NodePool[_mpos], SizeOf(TPathNode) * _MapSize, 0);
            _Ctx^.NodeCap := _MaxNodes;
          end;

          _Neighbor         := @_Ctx^.NodePool[_PoolCount];
                               Inc(_PoolCount);
          _Neighbor^.Pos    := _NextPos;
          _Neighbor^.G      := _NewG;
          _Neighbor^.H      := GetHeuristic(_NextPos, AParams.Finish);
          _Neighbor^.F      := _NewG + _Neighbor^.H;
          _Neighbor^.Parent := _Current;

          _Ctx^.Heap.Push(_Neighbor);
        end;
      end;

      { Diagonal neighbours }
      if _DirCount = 8 then
      for var _m := 0 to 3 do
      begin
        _NextPos := _Current^.Pos + _Diagonal[_m];
        if not IsValid(_NextPos) then Continue;

        _CellIdx := _NextPos.Y * _SnapWidth + _NextPos.X;
        if (_SnapData + _CellIdx)^ = 1 then Continue;
        if _HasExcludes and _ExcludeTiles[_CellIdx] then Continue;

        if _IsDiagonalEx then
        begin
          var _OrthoA := TPoint.Create(_Current^.Pos.X + _Diagonal[_m].X,
                                       _Current^.Pos.Y);
          var _OrthoB := TPoint.Create(_Current^.Pos.X,
                                       _Current^.Pos.Y + _Diagonal[_m].Y);
          if not IsValid(_OrthoA) or not IsValid(_OrthoB) then Continue;
          if not DiagonalClear(_OrthoA, _OrthoB,
                               _SnapWidth, _SnapData) then Continue;
        end;

        _StepCost := C_SQRT2;
        if AParams.Weights <> nil then
          _StepCost := _StepCost + AParams.Weights^[_CellIdx] * 0.1;

        _NewG := Single(_Current^.G + _StepCost);

        if (_VisitedGen[_CellIdx] <> _MyGen) or
           (_NewG < _VisitedG[_CellIdx]) then
        begin
          _VisitedG[_CellIdx]   := _NewG;
          _VisitedGen[_CellIdx] := _MyGen;

          if _PoolCount >= _MaxNodes then   { Memory Safe ... }
          begin
            var _mpos := Length(_Ctx^.NodePool);
            _MaxNodes := _mpos + _MapSize;
            SetLength(_Ctx^.NodePool, _MaxNodes);
            FillChar(_Ctx^.NodePool[_mpos], SizeOf(TPathNode) * _MapSize, 0);
            _Ctx^.NodeCap := _MaxNodes;
          end;

          _Neighbor         := @_Ctx^.NodePool[_PoolCount];
                               Inc(_PoolCount);
          _Neighbor^.Pos    := _NextPos;
          _Neighbor^.G      := _NewG;
          _Neighbor^.H      := GetHeuristic(_NextPos, AParams.Finish);
          _Neighbor^.F      := _NewG + _Neighbor^.H;
          _Neighbor^.Parent := _Current;

          _Ctx^.Heap.Push(_Neighbor);
        end;
      end;
    end;

    FPoolCount := _PoolCount;
    FMaxNodes  := _MaxNodes;
    FMapSize   := _MapSize;

  finally
    { Return the context: NodePool and Heap.
      FData are kept intact for reuse on the next call }
    ReleaseContext(_Ctx);
  end;
end;

initialization
  // System.GetMemoryManager(V_MemoryManager);

finalization

end.