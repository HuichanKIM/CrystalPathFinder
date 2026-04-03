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
  Winapi.Windows,
  Winapi.Messages,
  FMX.Types,
  FMX.Graphics,
  FMX.Controls,
  FMX.StdCtrls,
  FMX.Memo,
  FMX.Forms;

const
  C_BackgroundColor = TAlphaColor($16253d);  // R,G,B = 22,37,61

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

procedure Global_TrimAppMemorySizeEx(const AStrategy: Integer);
procedure ShowFixedMsg(const ATitle, AMsg: string);
procedure RGBToHSV(const R, G, B: Byte; out H, S, V: Single);
function MakeAlphaColor(Color: TAlphaColor; Alpha: Byte): TAlphaColor;
function CheckPointF(const PF1, PF2: TPointF): Boolean;
function WinGetTickCount(): Cardinal;
function Clamp_I(const Value, Min, Max: Integer): Integer;
function Clamp_D(const Value, Min, Max: Single): Single;
function GetColorFromHSL(AHH, ASS, ALL: Single): TAlphaColor;
function CaptureComponent(const AControl: FMX.Controls.TControl; const ASavefile: string): Boolean;

function ReadAllText_Unicode(const AFilePath: string=''): string;
function WriteAllText_Unicode(const AFilePath, AContents: string): Boolean;

procedure CaptureCleanWorkArea(const AFileName: string);
procedure CaptureScreenToFile(const AFileName: string);

implementation

uses
  SYstem.UIConsts,
  Vcl.Graphics,
  Unit_Main;

{ Message DIalog }

const
  C_ShortKeys = '''

                *** Shortcut Keys [Shift-key, Key-Char] ***
                [ Ctrl+A, a ] Show Cell Weights
                [ Ctrl+B, b ] Center Map
                [ Ctrl+F, f ] Filter Buildings
                [ Ctrl+G, g ] Show Grids
                [ Ctrl+M, m ] Load Map
                [ Ctrl+O, o ] Options
                [ Ctrl+Q, q ] Draw SmoothLine Path
                [ Ctrl+R, r ] Reset
                [ Ctrl+S, s ] SnapShot
                [ Ctrl+H, h ] Help
                [ Space-Key ] Batch change Weight of Cell (+ ML/MR Button)

                *** Mouse Actions ***
                [ ML-Down   ] Drag / Pan  ( if Space-Key then Bypass)
                [ MR-Down   ] Change Cell Weight (0 <-> 255)
                [ MR+Shift  ] Sequencial Change Cell Weight -> 255
                [ MR+ALt    ] Sequencial Change Cell Weight -> 0 (*)
                [ Wheel     ] Zoom

                *** KeyBoard (COntrol Map Screen) ***
                [ Left      ] Move to Left
                [ Right     ] Move to Right
                [ Up        ] Move to Up
                [ Down      ] Move to Down
                [ Ctrl+Up   ] Zoom In
                [ Ctrl+Down ] Zoom Out

                (*) by Value of <Edit Weight>

                --------------------------
                Inspired by
                https://github.com/d-mozulyov/CrystalPathFinding
                with the help of AI Gemini, Claude

              ''';

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
begin
  var _MsgForm := TForm.CreateNew(Application);
  var _Handler: TKeyHandler := TKeyHandler.Create(_MsgForm);

  try
    if (Application.MainForm <> nil) and
       (Application.MainForm.StyleBook <> nil) then
    _MsgForm.StyleBook := Application.MainForm.StyleBook;

    with _MsgForm do
    begin
      Caption := 'Crystal Path Finder - 2026';
      Width := 550;
      Height := 700;
      BorderIcons := [];
      Position := TFormPosition.MainFormCenter;
      BorderStyle := TFmxFormBorderStyle.Single; // None - No Title
      BorderIcons := [];

      OnKeyDown := _Handler.FormKeyDown;
    end;

    var _MsgText := TMemo.Create(_MsgForm);
    with _MsgText do
    begin
      Parent := _MsgForm;
      Align := TAlignLayout.Client;
      Margins.Rect := TRectF.Create(10, 10, 10, 50);
      ReadOnly := True;
      HitTest := False;
      Text := C_ShortKeys;

      TextSettings.Font.Family := 'Consolas';
      TextSettings.Font.Size := 14;
      StyledSettings := StyledSettings - [TStyledSetting.Family, TStyledSetting.Size];
    end;

    var _OkBtn := TButton.Create(_MsgForm);
    with _OkBtn do
    begin
      Parent := _MsgForm;
      Text := 'OK';
      Width := 80;
      Height := 30;
      CanFocus := True;
      Position.X := (_MsgForm.Width - _OkBtn.Width) / 2;
      Position.Y := _MsgForm.Height - 75;
      Default := True;

      ModalResult := mrOk;
    end;

    _MsgForm.ShowModal;
  finally
    _MsgForm.Free;
  end;
end;

{ CaptureScreen -------------------------------------------------------------- }

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

procedure Global_TrimAppMemorySizeEx(const AStrategy: Integer);
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

procedure RGBToHSV(const R, G, B: Byte; out H, S, V: Single);
var
  _RF, _GF, _BF, _MaxC, _MinC, _Delta: Single;
begin
  _RF    := R / 255.0;
  _GF    := G / 255.0;
  _BF    := B / 255.0;
  _MaxC  := Max(_RF, Max(_GF, _BF));
  _MinC  := Min(_RF, Min(_GF, _BF));
  _Delta := _MaxC - _MinC;
  V     := _MaxC;
  if _MaxC > 0   then S := _Delta / _MaxC else S := 0;
  if _Delta = 0  then H := 0  else
  if _MaxC = _RF then H := 60.0 * (_GF - _BF) / _Delta else
  if _MaxC = _GF then H := 60.0 * ((_BF - _RF) / _Delta + 2.0)
                 else H := 60.0 * ((_RF - _GF) / _Delta + 4.0);
  if H < 0 then H := H + 360.0;
end;

{ From Delphi 13 - System.UIConsts ------------------------------------------- }

procedure RGB2HSL(const RGB: TAlphaColor; out H, S, L: Single);   { = Copy from RGBToHSL }
var
  _R, _G, _B: Single;
  _D, _mx, _mn: Single;

  function _Max(AVarFirst, AVarSecond : Single) : Single ;
  begin
    if AVarFirst < AVarSecond then
      Result := AVarSecond
    else
      Result := AVarFirst ;
  end ;

  function _Min(AVarFirst, AVarSecond : Single) : Single ;
  begin
    if AVarFirst > AVarSecond then
      Result := AVarSecond
    else
      Result := AVarFirst ;
  end ;

begin
  _R  := TAlphaColorRec(RGB).R / $FF;
  _G  := TAlphaColorRec(RGB).G / $FF;
  _B  := TAlphaColorRec(RGB).B / $FF;
  _mx := _Max(_Max(_R, _G), _B);
  _mn := _Min(_Min(_R, _G), _B);
  H  := (_mx + _mn) / 2;
  L  := H;
  S  := H;

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

function RGBtoHSL(const AR, AG, AB: Byte; out H, S, L: Single): TAlphaCOlor;
begin
  var _RGBCOlor := MakeColor(AR, AG, AB, 255);
  RGB2HSL(_RGBCOlor, H, S, L);
end;

function MakeAlphaColor(Color: TAlphaColor; Alpha: Byte): TAlphaColor;
var
  _Rec: TAlphaColorRec;
begin
  _Rec.Color := Color;
  _Rec.A := Alpha;
  Result := _Rec.Color;
end;

function GetColorFromHSL(AHH, ASS, ALL: Single): TAlphaColor;
begin
  Result :=  SYstem.UIConsts.HSLtoRGB(AHH, ASS, ALL);
end;

{ Returns a color based on direction angle using HSL color model
   Creates rainbow-like directional coloring often used in generative art }

function GetDirectionColor(const Angle: Single): TAlphaColor;  overload;
begin
  // Normalize angle to 0..1 range for hue
  var _Hue := Frac((Angle / (2 * Pi)) + 0.5);   // Hue ranging from 0.0 to 1.0

  // 1. HSL ¡æ RGB conversion (System.UIConsts unit required)
  // Hue: 0..1, Saturation: 0.85, Lightness: 0.65 ¡æ vivid but not too bright
  Result := SYstem.UIConsts.HSLtoRGB(_Hue, 0.85, 0.65);     // Alpha = $FF Auto apply

  // 2. with TAlphaColorF
  // var _AF := TAlphaColorF.Create(HSLtoRGB(_Hue, 0.85, 0.65));
  // Result := _AF.ToAlphaColor;
end;

function GetDirectionColor(const Angle, Speed: Single): TAlphaColor;  overload;
begin
  //// Normalize angle to 0..1 range for hue
  var _Hue := Frac((Angle / (2 * Pi)) + 0.5);  // Hue ranging from 0.0 to 1.0

  // 1. HSL ¡æ RGB conversion (System.UIConsts unit required)
  // Hue: 0..1, Saturation: 0.85, Lightness: 0.65 ¡æ vivid but not too bright
  Result := SYstem.UIConsts.HSLtoRGB(_Hue, 0.85, 0.65);     // Alpha = $FF  Auto apply

  // 2. with TAlphaColorF
  // var _AF := TAlphaColorF.Create(HSLtoRGB(_Hue, 0.85, 0.65));
  // Result := _AF.ToAlphaColor;
end;

{ MousePosChecker ------------------------------------------------------------ }

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

{ IIF.Cast ------------------------------------------------------------------- }

class function IIF.CastBool<T>(AExpression: Boolean; const ATrue, AFalse: T): T;
begin
  if AExpression
    then Result := ATrue
    else Result := AFalse;
end;

{ Others Section ------------------------------------------------------------- }

function Clamp_I(const Value, Min, Max: Integer): Integer;
begin
  if Value < Min then Result := Min else
  if Value > Max then Result := Max
                 else Result := Value;
end;

function Clamp_D(const Value, Min, Max: Single): Single;
begin
  if Value < Min then Result := Min else
  if Value > Max then Result := Max
                 else Result := Value;
end;

function OneDiv(aPoint: TPointF): TPointF;
begin
  var _Q := aPoint;
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
  if _MagSq > Max * Max then
    Result := V.Normalize * Max
  else
    Result := V;
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

function GetDirectionColor2(const Theta: Double): TAlphaColor;
var
  _R, _G, _B: Byte;
begin
  var _Hue: Double := (Theta + Pi) / (2 * Pi);
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
