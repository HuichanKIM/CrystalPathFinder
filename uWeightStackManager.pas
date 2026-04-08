unit uWeightStackManager;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.JSON;

type
  { Record representing a simple stack of Byte values  ---------------------   }
  TWeightStack = record
  private
    FItems: TArray<Byte>;                       // Dynamic array to store stack elements
    FCount: Integer;                            // Current number of elements
    FKey: Byte;                                 // Current Target Value
    procedure EnsureCapacity(const ACount: Integer);
  public
    procedure Push(const AValue: Byte);         // Add a value to the stack
    function Pop: Byte;                         // Remove and return the last value
    procedure Clear;                            // Clear all values
    function Count: Integer;                    // Return number of elements
    function Key: Integer;                      // Return Target Value
    function ToArray: TArray<Byte>;             // Return all values as an array
    procedure SetKeyValue(const AKey: Byte);

    function ToJSON: TJSONObject;               // Convert stack to JSON object
    procedure FromJSON(JSONObj: TJSONObject);   // Load stack from JSON object
  end;

  { Manager class to handle multiple named stacks  --------------------------- }
  TWeightStackManager = class
  private
    FStacksDic: TDictionary<string, TWeightStack>;
    FSaveFileName: string;
    FCurrentName: string;
    function GetCurrentStack: TWeightStack;
    procedure SetCurrentStack(const Value: TWeightStack);
  public
    constructor Create(const AName, ASaveName: string);
    destructor Destroy; override;

    function Exists(const AName: string): Boolean;
    procedure CleanupEmptyStacks;
    function GetNames: TArray<string>;

    procedure AddStack(const AName: string);
    function AddStack_ex(const AName: string): TWeightStack;
    procedure RemoveStack(const AName: string);
    function GetStack(const AName: string): TWeightStack;
    procedure UpdateStack(const AName: string; const AStack: TWeightStack);
    function UpdateStackKey(const AName: string; const AKey: Byte): Boolean;
    function GetStackKey(const AName: string): Integer;

    function PushToCurrent(const AValue: Byte): Boolean;
    function PushToStack(const AName: string; const AValue: Byte): Boolean;
    { Sequencial Routine }
    function PushToCurrent_seq(const ALow, AHigh: Byte; const AKey: Integer): Boolean;
    function PushToStackUsr_seq(const AName: string; const ALow, AHigh: Byte; const AKey: Integer): Boolean;
    function GetFromCurrent_seq(const AName: string; out ALow, AHigh, AKey: Byte): Boolean;
    function IsStackValid(const AName: string): Boolean;
    function ChangeStackName(const AOldName, ANewName: string): Boolean;

    procedure SaveToFile(const AFileName: string = '');
    procedure LoadFromFile(const AFileName: string = '');
    //
    property CurrentName: string        read FCurrentName    write FCurrentName;
    property CurrentStack: TWeightStack read GetCurrentStack write SetCurrentStack;
    property SaveFileName: string       read FSaveFileName   write FSaveFileName;
  end;

implementation

uses
  uCommons,
  System.Math,
  System.IOUtils;

const
  EM_000 = 'E:000 Not Found CurrentStack';

{ TWeightStack --------------------------------------------------------------- }

procedure TWeightStack.EnsureCapacity(const ACount: Integer);
begin
  if Length(FItems) < ACount then
    SetLength(FItems, Max(ACount, Length(FItems) * 2));
end;

procedure TWeightStack.Push(const AValue: Byte);
begin
  EnsureCapacity(FCount + 1);
  FItems[FCount] := AValue;
  Inc(FCount);
end;

procedure TWeightStack.SetKeyValue(const AKey: Byte);
begin
  FKey := AKey;
end;

function TWeightStack.Pop: Byte;
begin
  if FCount = 0 then raise Exception.Create('Stack is empty');
  Dec(FCount);
  Result := FItems[FCount];
end;

procedure TWeightStack.Clear;
begin
  FItems := nil;
  FCount := 0;
end;

function TWeightStack.Count: Integer;
begin
  Result := FCount;
end;

function TWeightStack.Key: Integer;
begin
  Result := FKey;
end;

function TWeightStack.ToArray: TArray<Byte>;
begin
  Result := Copy(FItems, 0, FCount);
end;

function TWeightStack.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('Key', TJSONNumber.Create(FKey));
  Result.AddPair('Count', TJSONNumber.Create(FCount));

  var _arr := TJSONArray.Create;
  for var _i := 0 to FCount - 1 do
    _arr.Add(FItems[_i]);

  Result.AddPair('Items', _arr);
end;

procedure TWeightStack.FromJSON(JSONObj: TJSONObject);
begin
  if JSONObj = nil then Exit;

  Clear;
  FKey   := JSONObj.GetValue<Integer>('Key');
  FCount := JSONObj.GetValue<Integer>('Count');
  var _arr := JSONObj.GetValue<TJSONArray>('Items');
  if _arr <> nil then
  begin
    SetLength(FItems, _arr.Count);
    for var _i := 0 to _arr.Count - 1 do
      FItems[_i] := _arr.Items[_i].AsType<Byte>;
  end;
end;

{ TStackManager -------------------------------------------------------------- }

constructor TWeightStackManager.Create(const AName, ASaveName: string);
begin
  FStacksDic    := TDictionary<string, TWeightStack>.Create;
  FSaveFileName := ASaveName;
  FCurrentName  := AName;

  AddStack(AName);

  if FileExists(FSaveFileName) then
    LoadFromFile();
end;

destructor TWeightStackManager.Destroy;
begin
  try
    try SaveToFile; except end;
  finally
    FStacksDic.Free;
  end;

  inherited;
end;

procedure TWeightStackManager.AddStack(const AName: string);
begin
  if not FStacksDic.ContainsKey(AName) then
  begin
    var _Stack: TWeightStack;
    _Stack.Clear;
    FStacksDic.Add(AName, _Stack);
  end;
end;

function TWeightStackManager.AddStack_ex(const AName: string): TWeightStack;
begin
  if FStacksDic.ContainsKey(AName) then
    Result := FStacksDic[AName]
  else
    begin
      var _Stack: TWeightStack;
      _Stack.Clear;
      FStacksDic.Add(AName, _Stack);
      Result := _Stack;
    end;
end;

procedure TWeightStackManager.RemoveStack(const AName: string);
begin
  FStacksDic.Remove(AName);
  CleanupEmptyStacks;
end;

function TWeightStackManager.GetCurrentStack: TWeightStack;
begin
  if FStacksDic.ContainsKey(FCurrentName)
    then Result := FStacksDic[FCurrentName]
    else Result.Clear;
end;

procedure TWeightStackManager.SetCurrentStack(const Value: TWeightStack);
begin
  FStacksDic.AddOrSetValue(FCurrentName, Value);
end;

function TWeightStackManager.GetStack(const AName: string): TWeightStack;
begin
  if not FStacksDic.TryGetValue(AName, Result)then
    Result := Default(TWeightStack);
end;

procedure TWeightStackManager.UpdateStack(const AName: string; const AStack: TWeightStack);
begin
  FStacksDic[AName] := AStack;
end;

function TWeightStackManager.UpdateStackKey(const AName: string; const AKey: Byte): Boolean;
var
  _Stack: TWeightStack;
begin
  if FStacksDic.TryGetValue(AName, _Stack) then
  begin
    _Stack.FKey := AKey;
    FStacksDic[FCurrentName] := _Stack;
    Exit(True);
  end;
end;

function TWeightStackManager.PushToCurrent(const AValue: Byte): Boolean;
var
  _Stack: TWeightStack;
begin
  if FStacksDic.TryGetValue(FCurrentName, _Stack) then
  begin
    _Stack.Push(AValue);
    FStacksDic[FCurrentName] := _Stack;

    Exit(True);
  end;
end;

function TWeightStackManager.PushToStack(const AName: string; const AValue: Byte): Boolean;
var
  _Stack: TWeightStack;
begin
  if FStacksDic.TryGetValue(AName, _Stack) then
  begin
    _Stack.Push(AValue);
    FStacksDic[AName] := _Stack;

    Exit(True);
  end;
end;

function TWeightStackManager.PushToCurrent_seq(const ALow, AHigh: Byte; const AKey: Integer): Boolean;
begin
  if not FStacksDic.ContainsKey(FCurrentName) then Exit(False);

  var _Stack := FStacksDic[FCurrentName];
  _Stack.Clear;
  _Stack.Push(Byte(AKey));

  for var _i := ALow to AHigh do
    _Stack.Push(_i);

  FStacksDic[FCurrentName] := _Stack;
  Result := True;
end;

function TWeightStackManager.GetStackKey(const AName: string): Integer;
begin
  Result := -1;
  if FStacksDic.ContainsKey(AName) then
    Result := FStacksDic[AName].Key;
end;

function TWeightStackManager.PushToStackUsr_seq(const AName: string; const ALow, AHigh: Byte; const AKey: Integer): Boolean;
begin
  var _Name := AName;
  if _Name = '' then _Name := 'U_' + FormatDateTime('mmddhhnnss', Now);
  var _Stack: TWeightStack;
  if not FStacksDic.TryGetValue(_Name, _Stack) then
    _Stack := AddStack_ex(_Name);

  _Stack.Clear;
  _Stack.FKey := AKey;
  for var _i := ALow to AHigh do
    _Stack.Push(_i);

  FStacksDic[_Name] := _Stack;
  FCurrentName := _Name;
  Result := True;
end;

function TWeightStackManager.IsStackValid(const AName: string): Boolean;
begin
  var _Name := AName;
  if _Name = '' then _Name := FCurrentName;

  var _Stack: TWeightStack;
  Result := FStacksDic.TryGetValue(_Name, _Stack) and (_Stack.Count >= 3);
end;

function TWeightStackManager.GetFromCurrent_seq(const AName: string; out ALow, AHigh, AKey: Byte): Boolean;
begin
  var _Name := AName;
  if _Name = '' then _Name := FCurrentName;

  CleanupEmptyStacks;

  var _Stack: TWeightStack;
  if FStacksDic.TryGetValue(_Name, _Stack) and (_Stack.Count >= 2) then
  begin
      AKey  :=  _Stack.FKey;
      var _Data := _Stack.ToArray;
      ALow  := _Data[0];
      AHigh := _Data[High(_Data)];

      FCurrentName := _Name;
      Exit(True);
  end;

  Result := False;
end;

function TWeightStackManager.Exists(const AName: string): Boolean;
begin
  Result := FStacksDic.ContainsKey(AName);
end;

function TWeightStackManager.ChangeStackName(const AOldName, ANewName: string): Boolean;
begin
  Result := False;
  if not FStacksDic.ContainsKey(AOldName) then Exit;

  var _FinalName := ANewName;
  if FStacksDic.ContainsKey(_FinalName) then
    _FinalName := 'U_' + FormatDateTime('mmdd_hhnnss', Now);

  var _Pair: TPair<string, TWeightStack>;
  _Pair := FStacksDic.ExtractPair(AOldName);

  FStacksDic.Add(_FinalName, _Pair.Value);
  Result := FStacksDic[_FinalName].Count > 3;
end;

procedure TWeightStackManager.CleanupEmptyStacks;
begin
  var _keysToRemove := TList<string>.Create;
  var _key: string := '';
  try
    for _key in FStacksDic.Keys do
      if FStacksDic[_key].Count = 0 then
        _keysToRemove.Add(_key);

    for _key in _keysToRemove do
      FStacksDic.Remove(_key);
  finally
    _keysToRemove.Free;
  end;
end;

function TWeightStackManager.GetNames: TArray<string>;
begin
  Result := FStacksDic.Keys.ToArray;
end;

procedure TWeightStackManager.SaveToFile(const AFileName: string ='');
begin
  CleanupEmptyStacks;

  var _FileName :=  IIF.CastBool<string>(AFileName <> '', AFileName, FSaveFileName);
  if _FileName = '' then Exit;

  var _JSONObject := TJSONObject.Create;
  try
    for var _key in FStacksDic.Keys do
    begin
      var _StackJSON := FStacksDic[_key].ToJSON;
      _JSONObject.AddPair(_key, _StackJSON);
    end;

    TFile.WriteAllText(_FileName, _JSONObject.Format(2), TEncoding.UTF8);
  finally
    _JSONObject.Free;
  end;
end;

procedure TWeightStackManager.LoadFromFile(const AFileName: string = '');
begin
  var _Path := IIF.CastBool<string>(AFileName <> '', AFileName, FSaveFileName);
  if not TFile.Exists(_Path) then Exit;

  try
    var _Content := TFile.ReadAllText(_Path, TEncoding.UTF8);
    var _JSONObject := TJSONObject.ParseJSONValue(_Content) as TJSONObject;
    if _JSONObject = nil then Exit;

    try
      FStacksDic.Clear;
      for var _Pair in _JSONObject do
      begin
        var _Stack: TWeightStack;
        _Stack.FromJSON(_Pair.JsonValue as TJSONObject);
        FStacksDic.Add(_Pair.JsonString.Value, _Stack);
      end;
    finally
      _JSONObject.Free;
    end;
  except
    on E: Exception do ;
  end;
end;

end.
