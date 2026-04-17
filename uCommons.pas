unit uCommons;

interface

{$INLINE AUTO}

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  System.Math,
  System.Math.Vectors,

  Winapi.Windows,        { - for Windows PlatForm}

  FMX.Types,
  FMX.Graphics,
  FMX.Controls,
  FMX.StdCtrls,
  FMX.Memo,
  FMX.Forms;

const
  C_BackgroundColor = TAlphaColor($16253d);  // R,G,B = 22,37,61

  SYMBOL_STAR_FILL  = #$2605; // ★
  SYMBOL_STAR_EMPTY = #$2606; // ☆

type
  TVectorHelper = record helper for TVector
    function Length: Single;
    function Normalize: TVector;
    function Limit(AMax: Single): TVector;
  end;

  { MousePosChecker }
  TFormHelper = class helper for TCommonCustomForm
  public
    function IsMouseInside(): Boolean;
  end;

  TControlHelper = class helper for TControl
  public
    function IsMouseInside(): Boolean;
    procedure SetDragCursor(const AIsDragging: Boolean; const ATag: Boolean = True);
  end;

type
  IIF = class
    class function CastBool<T>(AExpression: Boolean; const ATrue, AFalse: T): T; static;
  end;

function  PreventSleep: Boolean;
procedure AllowSleep;

procedure Global_TrimAppMemorySizeEx(const AStrategy: Integer=0);
procedure ShowFixedMsg(const ATitle, AMsg: string);

procedure RGBToHSV(const R, G, B: Byte; out H, S, V: Single); overload;
procedure RGBToHSV(const ARGB: TAlphaColor; out H, S, V: Single); overload;
procedure HSVToRGB(const H, S, V: Single; out R, G, B: Byte);

function  MakeAlphaColor(const AColor: TAlphaColor; const AAlpha: Byte): TAlphaColor; overload;
function  MakeAlphaColor(const R, G, B: Byte; const A: Byte = $FF): TAlphaColor; overload;
function  MakeAlphaColor(const AColor: TAlphaColor; const AOpacity: Single): TAlphaColor; overload;

function  CaptureComponent(const AControl: FMX.Controls.TControl; const ASavefile: string): Boolean;
procedure CaptureCleanWorkArea(const AFileName: string);
procedure CaptureScreenToFile(const AFileName: string);

function AreStaticArraysEqual(const A, B; const ASize: NativeInt): Boolean;

implementation

uses
  SYstem.UIConsts,
  Vcl.Graphics, { - for Windows PlatForm}
  Unit_Main;

const
    C_ShortKeys = '''

                  *** Shortcut Keys [Ctrl / Key] ***
                  [ Ctrl+A, a ] Toggle Cell Weights (Heatmap)
                  [ Ctrl+B, b ] Center Map
                  [ Ctrl+F, f ] Toggle Building Filter
                  [ Ctrl+G, g ] Toggle Grids
                  [ Ctrl+M, m ] Load Map Image
                  [ Ctrl+O, o ] Open Options
                  [ Ctrl+Q, q ] Draw Smooth Path Line
                  [ Ctrl+R, r ] Reset Map
                  [ Ctrl+S, s ] Save Snapshot
                  [ Ctrl+W, w ] Edit Custom Weights
                  [ Ctrl+H, h ] Show Help
                  [ Spacebar  ] Batch Change Cell Weight (+ Left/Right Click)
                  [ ESC       ] Close Current Toolbax or Restore Map backup.

                  *** Mouse Actions ***
                  [ Left Drag   ] Pan Map (Disabled if Spacebar is held)
                  [ Right Click ] Toggle Cell Weight (0 <-> 255)
                  [ Shift+Right ] Sequential Paint: Weight -> 255 (Wall)
                  [ Alt+Right   ] Sequential Paint: Weight -> 0 (*)
                  [ Mouse Wheel ] Zoom In / Zoom Out

                  *** Keyboard (Map Screen Controls) ***
                  [ Left Arrow  ] Pan Left
                  [ Right Arrow ] Pan Right
                  [ Up Arrow    ] Pan Up
                  [ Down Arrow  ] Pan Down
                  [ Ctrl+Up     ] Zoom In  (or Increase Weight Scale)
                  [ Ctrl+Down   ] Zoom Out (or Decrease Weight Scale)

                  (*) Value depends on the <Cell Weight> slider setting.
                  -----------------------------------------------------------
                  Inspired by https://github.com/d-mozulyov/CrystalPathFinding
                  Developed with the help of AI (Gemini, Claude)
                ''';

{ AreArraysEqual }

function AreStaticArraysEqual(const A, B; const ASize: NativeInt): Boolean;
begin
  Result := CompareMem(@A, @B, ASize);
end;

{ TFormHelper / MousePosChecker ---------------------------------------------- }

function TFormHelper.IsMouseInside(): Boolean;
begin
  // 1. Get the current mouse position relative to the screen.
  var _MousePos: TPointF := Screen.MousePos;
  // 2. Convert the screen coordinates to local coordinates relative to the current form.
  var _RelativePos: TPointF := Self.ScreenToClient(_MousePos);
  // 3. Check if the converted coordinates are within the form's client area (0, 0, Width, Height).
  // TRectF.Contains returns True if the point is within the rectangle.
  Result := TRectF.Create(0, 0, Self.ClientWidth, Self.ClientHeight).Contains(_RelativePos);
end;


{ TControlHelper ------------------------------------------------------------- }

function TControlHelper.IsMouseInside(): Boolean;
begin
  var _MousePos: TPointF := Screen.MousePos;
  var _LocalPos: TPointF := Self.ScreenToLocal(_MousePos);
  Result := TRectF.Create(0, 0, Self.Width, Self.Height).Contains(_LocalPos);
end;

procedure TControlHelper.SetDragCursor(const AIsDragging: Boolean; const ATag: Boolean);
begin
  var _dragcursor: TCursor := IIF.CastBool<TCursor>(ATag, crDrag, crHandPoint);
  Self.Cursor := IIF.CastBool<TCursor>(AIsDragging, _dragcursor, crDefault);
end;

{ TVectorHelper -------------------------------------------------------------- }

{ Helper function to create TVector with X, Y, W (Delphi 12 Athens standard) }
function Vec(const X, Y: Single; const W: Single = 0): TVector; inline;
begin
  { Based on the user's definition: TVector = (X, Y, W) }
  Result := TVector.Create(X, Y, W);
end;

{ Safe check if a vector is near zero length }
function IsVectorEmpty(const V: TVector): Boolean; inline;
begin
  Result := (Abs(V.X) < 1E-6) and (Abs(V.Y) < 1E-6);
end;

function TVectorHelper.Length: Single;
begin
  Result := Sqrt(Sqr(Self.X) + Sqr(Self.Y));
end;

function TVectorHelper.Normalize: TVector;
begin
  var _Len: Single := Self.Length;
  if _Len > 0 then
    begin
      Result.X := Self.X / _Len;
      Result.Y := Self.Y / _Len;
      Result.W := 1.0;
    end
  else
    Result := Self;
end;

function TVectorHelper.Limit(AMax: Single): TVector;
begin
  var _Len: Single := Self.Length;
  if _Len > AMax then
    begin
      Result := Self.Normalize * AMax;
      Result.W := 1.0;
    end
  else
    Result := Self;
end;

// Start sleep protection
// Flag ...
// ES_CONTINUOUS        : Keep settings consistent (use alone when turned off)
// ES_SYSTEM_REQUIRED   : Preventing the system from entering sleep mode
// ES_DISPLAY_REQUIRED  : Prevent the monitor from turning off
// ES_AWAYMODE_REQUIRED : For background operations such as media servers (Away Mode)
function PreventSleep: Boolean;
begin
  var _result: EXECUTION_STATE := SetThreadExecutionState(
                                    ES_CONTINUOUS or
                                    ES_SYSTEM_REQUIRED or   // Preventing System Power Saving
                                    ES_DISPLAY_REQUIRED     // Screen Off Prevention
                                  );

  Result := _result <> 0;
end;

// Turn off sleep protection (restore)
procedure AllowSleep;
begin
  SetThreadExecutionState(ES_CONTINUOUS);
end;

{ Replacing anonymous methods ------------------------------------------------ }

type
  TKeyHandler = class(TComponent)
  public
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
  end;

procedure TKeyHandler.FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  if Key = vkEscape then
    begin
      TForm(Sender).ModalResult := mrCancel;
      Key := 0;
    end else
  if (KeyChar = 'h') then
    begin
      TForm(Sender).ModalResult := mrCancel;
    end;
  if (KeyChar = 'u') then
    begin
      FormMain.Action_ScreenCapExecute(nil);
    end;
end;

{ Help / Info ---------------------------------------------------------------- }

procedure ShowFixedMsg(const ATitle, AMsg: string);
const
  c_Welcome = ' - Welcome to Crystal Path Finder';
begin
  var _MsgForm := TForm.CreateNew(Application);
  var _Handler: TKeyHandler := TKeyHandler.Create(_MsgForm);

  try
    if (Application.MainForm <> nil) and
       (Application.MainForm.StyleBook <> nil) then
    _MsgForm.StyleBook := Application.MainForm.StyleBook;

    with _MsgForm do
    begin
      if ATitle <> '' then Caption := ' '+ATitle+c_Welcome
                      else Caption := 'Crystal Path Finder - 2026';
      Width       := 550;
      Height      := 700;
      Position    := TFormPosition.MainFormCenter;
      BorderStyle := TFmxFormBorderStyle.Single;
      BorderIcons := [];

      OnKeyDown   := _Handler.FormKeyDown;
    end;

    var _MsgText := TMemo.Create(_MsgForm);
    with _MsgText do
    begin
      Parent       := _MsgForm;
      Align        := TAlignLayout.Client;
      Margins.Rect := TRectF.Create(10, 10, 10, 50);
      ReadOnly     := True;
      HitTest      := False;
      if AMsg <> '' then Text := AMsg
                    else Text := C_ShortKeys;

      StyledSettings := StyledSettings - [TStyledSetting.Family, TStyledSetting.Size];
      TextSettings.Font.Family := 'Consolas';
      TextSettings.Font.Size := 14;
    end;

    var _OkBtn := TButton.Create(_MsgForm);
    with _OkBtn do
    begin
      Parent     := _MsgForm;
      Text       := 'OK';
      Width      := 80;
      Height     := 30;
      CanFocus   := True;

      Position.X := (_MsgForm.Width - Width) / 2;
      Position.Y := _MsgForm.Height - 75;
      Anchors    := [TAnchorKind.akBottom];
      Default    := True;

      ModalResult := mrOk;
    end;

    _MsgForm.ShowModal;
  finally
    _MsgForm.Free;
  end;
end;

{ ... CaptureScreen / for Windows PlatForm --------------------------------------- }

procedure CaptureScreenToFile(const AFileName: string);
begin
  var _dc: HDC := GetDC(0);
  var _vclBmp: Vcl.Graphics.TBitmap := Vcl.Graphics.TBitmap.Create;
  try
    _vclBmp.SetSize(GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN));
    BitBlt(_vclBmp.Canvas.Handle, 0, 0, _vclBmp.Width, _vclBmp.Height, _dc, 0, 0, SRCCOPY);
    _vclBmp.PixelFormat := Vcl.Graphics.TPixelFormat.pf32bit;
    _vclBmp.SaveToFile(AFileName);
  finally
    _vclBmp.Free;
    ReleaseDC(0, _dc);
  end;
end;

procedure CaptureCleanWorkArea(const AFileName: string);
var
  _WorkRect: TRect;
begin
  if not SystemParametersInfo(SPI_GETWORKAREA, 0, @_WorkRect, 0) then
  begin
    _WorkRect := Rect(0, 0, GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN));
  end;

  var _dc: HDC := GetDC(0);
  var _vclBmp: Vcl.Graphics.TBitmap := Vcl.Graphics.TBitmap.Create;
  try
    _vclBmp.SetSize(_WorkRect.Width, _WorkRect.Height);
    BitBlt(_vclBmp.Canvas.Handle, 0, 0, _vclBmp.Width, _vclBmp.Height,
           _dc, _WorkRect.Left, _WorkRect.Top, SRCCOPY);
    _vclBmp.PixelFormat := Vcl.Graphics.TPixelFormat.pf32bit;
    _vclBmp.SaveToFile(AFileName);
  finally
    _vclBmp.Free;
    ReleaseDC(0, _dc);
  end;
end;

{ Global_TrimAppMemorySizeEx ------------------------------------------------- }

procedure Global_TrimAppMemorySizeEx(const AStrategy: Integer=0);
begin
  if AStrategy = 0 then
  begin
    var _MainHandle: THandle := Winapi.Windows.OpenProcess(PROCESS_ALL_ACCESS, False, Winapi.Windows.GetCurrentProcessID);
    if _MainHandle > 0 then
    try
      Winapi.Windows.SetProcessWorkingSetSize(_MainHandle, High(SIZE_T), High(SIZE_T));   // Win64
    finally
      Winapi.Windows.CloseHandle(_MainHandle);
    end;
  end;
  Application.ProcessMessages;
end;

{ From Winapi.Windows }

function WinGetTickCount(): Cardinal;
begin
  Result := Winapi.Windows.GetTickCount;
end;

{ ... for Windows PlatForm --------------------------------------------------- }

function CheckPointF(const PF1, PF2: TPointF): Boolean;
begin
  Result := PF2.EqualsTo(PF1);
end;

{ Color Functions ------------------------------------------------------------ }

{ ---- RGB to HSV Conversion ------------------------------------------------- }
{ System.UIConsts.RGBToHSL computes L (Lightness) as (Max+Min)/2, which        }
{ over-darkens highly saturated deep greens and makes them hard to             }
{ distinguish from shadows.                                                    }
{ HSV's V = Max(R,G,B) is a better fit for separating vegetation               }
{ from shadows in satellite imagery.                                           }

procedure RGBToHSV(const R, G, B: Byte; out H, S, V: Single); overload;
begin
  var _RF    := R / 255.0;
  var _GF    := G / 255.0;
  var _BF    := B / 255.0;
  var _MaxC  := Max(_RF, Max(_GF, _BF));
  var _MinC  := Min(_RF, Min(_GF, _BF));
  var _Delta := _MaxC - _MinC;

  V     := _MaxC;
  if _MaxC > 0   then S := _Delta / _MaxC else S := 0;
  if _Delta = 0  then H := 0  else
  if _MaxC = _RF then H := 60.0 * (_GF - _BF) / _Delta else
  if _MaxC = _GF then H := 60.0 * ((_BF - _RF) / _Delta + 2.0)
                 else H := 60.0 * ((_RF - _GF) / _Delta + 4.0);
  if H < 0 then H := H + 360.0;
end;

procedure RGBToHSV(const ARGB: TAlphaColor; out H, S, V: Single); overload;
begin
  var _RF    := ARGB / 255.0;
  var _GF    := ARGB / 255.0;
  var _BF    := ARGB / 255.0;
  var _MaxC  := Max(_RF, Max(_GF, _BF));
  var _MinC  := Min(_RF, Min(_GF, _BF));
  var _Delta := _MaxC - _MinC;

  V     := _MaxC;
  if _MaxC > 0   then S := _Delta / _MaxC else S := 0;
  if _Delta = 0  then H := 0  else
  if _MaxC = _RF then H := 60.0 * (_GF - _BF) / _Delta else
  if _MaxC = _GF then H := 60.0 * ((_BF - _RF) / _Delta + 2.0)
                 else H := 60.0 * ((_RF - _GF) / _Delta + 4.0);
  if H < 0 then H := H + 360.0;
end;

{ ---- HSV to RGB Conversion ------------------------------------------------- }
{ Exact inverse of RGBToHSV above.                                             }
{ H : 0.0 ~ 360.0 (degrees)                                                    }
{ S : 0.0 ~ 1.0                                                                }
{ V : 0.0 ~ 1.0                                                                }
{ R, G, B : 0 ~ 255                                                            }

procedure HSVToRGB(const H, S, V: Single; out R, G, B: Byte);
begin
  if S <= 0.0 then
  begin
    { Achromatic — no hue, pure gray }
    R := EnsureRange(Round(V * 255), 0, 255);
    G := R;
    B := R;
    Exit;
  end;

  { Hue sector 0~5  (each sector spans 60°) }
  var _Hi := Trunc(H / 60.0) mod 6;
  var _F  := (H / 60.0) - Trunc(H / 60.0);   { fractional part within sector }
  var _P  := V * (1.0 - S);
  var _Q  := V * (1.0 - S * _F);
  var _T  := V * (1.0 - S * (1.0 - _F));
  var _RF, _GF, _BF : Single;

  case _Hi of
    0: begin _RF := V;  _GF := _T;  _BF := _P; end;
    1: begin _RF := _Q; _GF := V;   _BF := _P; end;
    2: begin _RF := _P; _GF := V;   _BF := _T; end;
    3: begin _RF := _P; _GF := _Q;  _BF := V;  end;
    4: begin _RF := _T; _GF := _P;  _BF := V;  end;
  else { 5 }
       _RF := V;  _GF := _P;  _BF := _Q;
  end;

  R := EnsureRange(Round(_RF * 255), 0, 255);
  G := EnsureRange(Round(_GF * 255), 0, 255);
  B := EnsureRange(Round(_BF * 255), 0, 255);
end;

{ From Delphi 13 - System.UIConsts ------------------------------------------- }

procedure RGB2HSL(const RGB: TAlphaColor; out H, S, L: Single);   { = Copy from RGBToHSL }

  function _Max(AVarFirst, AVarSecond : Single) : Single ;
  begin
    if AVarFirst < AVarSecond
      then Result := AVarSecond
      else Result := AVarFirst ;
  end ;

  function _Min(AVarFirst, AVarSecond : Single) : Single ;
  begin
    if AVarFirst > AVarSecond
      then Result := AVarSecond
      else Result := AVarFirst ;
  end ;

begin
  var _R  := TAlphaColorRec(RGB).R / $FF;
  var _G  := TAlphaColorRec(RGB).G / $FF;
  var _B  := TAlphaColorRec(RGB).B / $FF;
  var _mx := _Max(_Max(_R, _G), _B);
  var _mn := _Min(_Min(_R, _G), _B);
  H  := (_mx + _mn) / 2;
  L  := H;
  S  := H;

  var _D: Single := 0;
  if (_mx = _mn) then
    begin
      S := 0;
      H := 0;
    end
  else
    begin
      _D := _mx - _mn;
      if L > 0.5  then S := _D / (2 - _mx - _mn)
                  else S := _D / (_mx + _mn);
      if (_mx = _R) then H := (_G - _B) / _D else
      if (_mx = _G) then H := (_B - _R) / _D + 2
                    else H := (_R - _G) / _D + 4;
      H := H / 6;
      if H < 0    then H := H + 1;
    end;
end;

function RGBtoHSL(const R, G, B: Byte; out H, S, L: Single): TAlphaCOlor;
begin
  var _RGBCOlor := MakeAlphaColor(R, G, B, 255);
  RGB2HSL(_RGBCOlor, H, S, L);
end;

{ Copy From System.UIConsts }

function MakeAlphaColor(const R, G, B: Byte; const A: Byte = $FF): TAlphaColor; overload;
begin
  TAlphaColorRec(Result).R := R;
  TAlphaColorRec(Result).G := G;
  TAlphaColorRec(Result).B := B;
  TAlphaColorRec(Result).A := A;
end;

function MakeAlphaColor(const AColor: TAlphaColor; const AOpacity: Single): TAlphaColor; overload;
begin
  Result := AColor;
  if AOpacity < 1 then
    TAlphaColorRec(Result).A := Trunc(TAlphaColorRec(Result).A * AOpacity);
end;

function MakeAlphaColor(const AColor: TAlphaColor; const AAlpha: Byte): TAlphaColor; overload;
begin
  Result := AColor;
  TAlphaColorRec(Result).A := AAlpha;
end;

function GetColorFromHSL(AHH, ASS, ALL: Single): TAlphaColor;
begin
  Result :=  SYstem.UIConsts.HSLtoRGB(AHH, ASS, ALL);
end;

{ IIF.Cast ------------------------------------------------------------------- }

class function IIF.CastBool<T>(AExpression: Boolean; const ATrue, AFalse: T): T;
begin
  if AExpression
    then Result := ATrue
    else Result := AFalse;
end;

{ Others Section ------------------------------------------------------------- }

function Clamp_I(const AValue, AMin, AMax: Integer): Integer;
begin
  if AValue < AMin then Result := AMin else
  if AValue > AMax then Result := AMax
                   else Result := AValue;
end;

function Clamp_S(const AValue, AMin, AMax: Single): Single;
begin
  if AValue < AMin then Result := AMin else
  if AValue > AMax then Result := AMax
                   else Result := AValue;
end;

function OneDiv(APoint: TPointF): TPointF;
begin
  var _Q := APoint;
  if _Q.X = 0.0 then _Q.X := 1E-5;
  if _Q.Y = 0.0 then _Q.Y := 1E-5;
  Result := PointF(1 / Abs(_Q.X), 1 / Abs(_Q.Y));
end;

function LerpAngle(Current, Target, Amount: Double): Double;
begin
  var _Diff: Double := Target - Current;
  // Normalize the angle difference to the range -Pi to Pi
  while _Diff < -Pi do _Diff := _Diff + 2 * Pi;
  while _Diff > Pi  do _Diff := _Diff - 2 * Pi;

  Result := Current + _Diff * Amount;
end;

function Limit_Point(V: TPointF; Max: Single): TPointF;
begin
  var _MagSq: Single := V.X * V.X + V.Y * V.Y;
  if _MagSq > Max * Max
    then Result := V.Normalize * Max
    else Result := V;
end;

function Set_Mag(V: TPointF; Mag: Single): TPointF;
begin
  Result := V.Normalize * Mag;
end;

function CaptureComponent(const AControl: FMX.Controls.TControl; const ASavefile: string): Boolean;
begin
  Result := False;
  var _Screenshot: FMX.Graphics.TBitmap := AControl.MakeScreenshot;
  try
    // reserved ... Image1.Bitmap.Assign(LScreenshot);
    _Screenshot.SaveToFile(ASavefile);
    Result := FileExists(ASavefile);
  finally
    _Screenshot.Free;
  end;
end;

function ReadAllText_Unicode(const AFilePath: string=''): string;
begin
  Result := '';
  if FileExists(AFilePath) then
  begin
    var _strings: TStrings := TStringList.Create;
    try
      _strings.LoadFromFile(AFilePath);
      Result := _strings.Text;
    finally
      _strings.Free;
    end;
  end;
end;

function WriteAllText_Unicode(const AFilePath, AContents: string): Boolean;
begin
  Result := False;
  var _strings: TStrings := TStringList.Create;
  try
    _strings.Text := AContents;
    _strings.SaveToFile(AFilePath);
  finally
    _strings.Free;
  end;
  Result := FileExists(AFilePath);
end;

{ Deprecating ... }

function GetDirectionColor2(const ATheta: Double): TAlphaColor;
var
  _R, _G, _B: Byte;
begin
  var _Hue: Double := (ATheta + Pi) / (2 * Pi);
  if _Hue < 0.33 then
    begin
      _R := 255;
      _G := Clamp_I(Round(_Hue*765), 0, 255);
      _B := 0;
    end else
  if _Hue < 0.66 then
    begin
      _R := 0;
      _G := 255;
      _B := Clamp_I(Round((_Hue - 0.33) * 765), 0, 255);
    end
  else
    begin
      _R := Clamp_I(Round((1 - _Hue) * 765), 0, 255);
      _G := 0;
      _B := 255;
    end;

  Result := TAlphaColorRec.Alpha or (_R shl 16) or (_G shl 8) or _B;
end;

end.
