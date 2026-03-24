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
procedure RGBToHSV(const R, G, B: Byte; out H, S, V: Single);
function MakeAlphaColor(Color: TAlphaColor; Alpha: Byte): TAlphaColor;
function CheckPointF(const PF1, PF2: TPointF): Boolean;
function WinGetTickCount(): Cardinal;
function Clamp(const Value, Min, Max: Integer): Integer;
function ClampD(const Value, Min, Max: Single): Single;
function GetColorFromHSL(AHH, ASS, ALL: Single): TAlphaColor;
function CaptureComponent(const AControl: TControl; const ASavefile: string): Boolean;

function ReadAllText_Unicode(const AFilePath: string=''): string;
function WriteAllText_Unicode(const AFilePath, AContents: string): Boolean;

implementation

uses
  SYstem.UIConsts;

{ Global_TrimAppMemorySizeEx }

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

{ Colors ... }

  { ---- RGB to HSV Conversion ----------------------------------------------- }
  { System.UIConsts.RGBToHSL computes L (Lightness) as (Max+Min)/2, which      }
  { over-darkens highly saturated deep greens and makes them hard to           }
  { distinguish from shadows.                                                  }
  { HSV's V = Max(R,G,B) is a better fit for separating vegetation             }
  { from shadows in satellite imagery.                                         }

procedure RGBToHSV(const R, G, B: Byte; out H, S, V: Single);
var
  RF, GF, BF, MaxC, MinC, Delta: Single;
begin
  RF    := R / 255.0;
  GF    := G / 255.0;
  BF    := B / 255.0;
  MaxC  := Max(RF, Max(GF, BF));
  MinC  := Min(RF, Min(GF, BF));
  Delta := MaxC - MinC;
  V     := MaxC;
  if MaxC > 0 then S := Delta / MaxC else S := 0;
  if Delta = 0 then
    H := 0
  else if MaxC = RF then
    H := 60.0 * (GF - BF) / Delta
  else if MaxC = GF then
    H := 60.0 * ((BF - RF) / Delta + 2.0)
  else
    H := 60.0 * ((RF - GF) / Delta + 4.0);
  if H < 0 then H := H + 360.0;
end;

{ From Delphi 13 - System.UIConsts ------------------------------------------- }

procedure RGB2HSL(const RGB: TAlphaColor; out H, S, L: Single);   { =Copy from RGBToHSL }
var
  R, G, B: Single;
  D, mx, mn: Single;

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
  R := TAlphaColorRec(RGB).R / $FF;
  G := TAlphaColorRec(RGB).G / $FF;
  B := TAlphaColorRec(RGB).B / $FF;
  mx := _Max(_Max(R, G), B);
  mn := _Min(_Min(R, G), B);
  H := (mx + mn) / 2;
  L := H;
  S := H;
  if (mx = mn) then
  begin
    S := 0;
    H := 0;
  end
  else
  begin
    D := mx - mn;
    if L > 0.5 then
      S := D / (2 - mx - mn)
    else
      S := D / (mx + mn);
    if (mx = R) then
      H := (G - B) / D
    else if (mx = G) then
      H := (B - R) / D + 2
    else
      H := (R - G) / D + 4;
    H := H / 6;
    if H < 0 then
      H := H + 1;
  end;
end;

function RGBtoHSL(const AR, AG, AB: Byte; out H, S, L: Single): TAlphaCOlor;
begin
  var _RGBCOlor := MakeColor(AR, AG, AB, 255);
  RGB2HSL(_RGBCOlor, H, S, L);
end;

function MakeAlphaColor(Color: TAlphaColor; Alpha: Byte): TAlphaColor;
var Rec: TAlphaColorRec;
begin
  Rec.Color := Color;
  Rec.A := Alpha;
  Result := Rec.Color;
end;

{ MousePosChecker }

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

{ TControlHelper }

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

{ TVectorHelper }

{ Helper function to create TVector with X, Y, W (Delphi 12 Athens standard) }
function Vec(const X, Y: Single; const W: Single = 0): TVector; inline;
begin
  { Based on the user's definition: TVector = (X, Y, W) }
  Result := TVector.Create(X, Y, W);
end;

{ IIF.Cast ... }

class function IIF.CastBool<T>(AExpression: Boolean; const ATrue, AFalse: T): T;
begin
  if AExpression
    then Result := ATrue
    else Result := AFalse;
end;

function Clamp(const Value, Min, Max: Integer): Integer;
begin
  if Value < Min then Result := Min else
  if Value > Max then Result := Max
  else Result := Value;
end;

function ClampD(const Value, Min, Max: Single): Single;
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
  while _Diff > Pi do _Diff := _Diff - 2 * Pi;

  Result := Current + _Diff * Amount;
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
  var _L: Single := Self.Length;
  if _L > 0 then
  begin
    Result.X := Self.X / _L;
    Result.Y := Self.Y / _L;
    Result.W := 1.0;
  end
  else
    Result := Self;
end;

function TVectorHelper.Limit(AMax: Single): TVector;
begin
  var _L: Single := Self.Length;
  if _L > AMax then
  begin
    Result := Self.Normalize * AMax;
    Result.W := 1.0;
  end
  else
    Result := Self;
end;

{ Functions ... }

function Limit_Point(V: TPointF; Max: Single): TPointF;
begin
  var MagSq: Single := V.X * V.X + V.Y * V.Y;
  if MagSq > Max * Max then
    Result := V.Normalize * Max
  else
    Result := V;
end;

function Set_Mag(V: TPointF; Mag: Single): TPointF;
begin
  Result := V.Normalize * Mag;
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

{ Deprecating ... }

function GetDirectionColor2(const Theta: Double): TAlphaColor;
var
  _R, _G, _B: Byte;
begin
  var _Hue: Double := (Theta + Pi) / (2 * Pi);
  if _Hue < 0.33 then
    begin
      _R := 255;
      _G := Clamp(Round(_Hue*765), 0, 255);
      _B := 0;
    end else
  if _Hue < 0.66 then
    begin
      _R := 0;
      _G := 255;
      _B := Clamp(Round((_Hue - 0.33) * 765), 0, 255);
    end
  else
    begin
      _R := Clamp(Round((1 - _Hue) * 765), 0, 255);
      _G := 0;
      _B := 255;
    end;

  Result := TAlphaColorRec.Alpha or (_R shl 16) or (_G shl 8) or _B;
end;

function CaptureComponent(const AControl: TControl; const ASavefile: string): Boolean;
begin
  Result := False;
  var LScreenshot: TBitmap := AControl.MakeScreenshot;
  try
    // reserved ... Image1.Bitmap.Assign(LScreenshot);
    LScreenshot.SaveToFile(ASavefile);
    Result := FileExists(ASavefile);
  finally
    LScreenshot.Free;
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

// Reserved ...
function CaptureForm(const AForm: TForm; const ASavefile: string): Boolean;
begin
  Result := False;
  var LScreenshot: TBitmap := TControl(AForm).MakeScreenshot;
  try
    LScreenshot.SaveToFile(ASavefile);
    Result := FileExists(ASavefile);
  finally
    LScreenshot.Free;
  end;
end;

end.
