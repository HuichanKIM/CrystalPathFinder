unit uSplashDrawing;

{ ============================================================================ }
{  Crystal Path Finding System — Splash Screen Drawing Routine                 }
{  Delphi 12 Athens / FMX                                                      }
{                                                                              }
{  Fonts used (must be installed on the target system):                        }
{    "CRYSTAL"          : Orbitron Bold  (Google Fonts — free)                 }
{                         Fallback: Consolas Bold / Courier New Bold           }
{    "PATH FINDING..."  : Rajdhani Medium  (Google Fonts — free)              }
{                         Fallback: Segoe UI Light / Arial Narrow              }
{    "System Ready."   : Rajdhani Light                                        }
{                                                                              }
{  How to embed Orbitron/Rajdhani in your FMX app:                            }
{    1. Download .ttf files from fonts.google.com                              }
{    2. Add to your project via TFontCollection or register at startup:        }
{         AddFontResourceEx(PChar(FontPath), FR_PRIVATE, nil)                  }
{    3. If unavailable, the fallback chain below keeps the sci-fi look.        }
{                                                                              }
{  Usage:                                                                      }
{    In your splash PaintBox OnPaint (or TTimer-driven canvas):               }
{      DrawCrystalSplash(Canvas, PaintBox.Width, PaintBox.Height, FProgress); }
{    FProgress : 0.0 (empty) to 1.0 (full) — drives the progress bar.        }
{ ============================================================================ }

{$SCOPEDENUMS ON}
{$INLINE ON}

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Math,
  FMX.Types,
  FMX.Graphics,
  FMX.Objects;

{ Main entry point — call from PaintBox.OnPaint }
procedure DrawCrystalSplash(ACanvas: TCanvas;
                             const AWidth, AHeight: Single;
                             const AProgress: Single = 1.0);

implementation

{ ============================================================================ }
{ Internal helpers                                                              }
{ ============================================================================ }

{ Linearly interpolate between two TAlphaColor values }
function LerpColor(const A, B: TAlphaColor; const T: Single): TAlphaColor;
var
  AR, BR: TAlphaColorRec;
begin
  AR := TAlphaColorRec(A);
  BR := TAlphaColorRec(B);
  Result := MakeColor(
    Round(AR.R + (BR.R - AR.R) * T),
    Round(AR.G + (BR.G - AR.G) * T),
    Round(AR.B + (BR.B - AR.B) * T),
    Round(AR.A + (BR.A - AR.A) * T));
end;

{ Draw a single filled + stroked polygon from a point array }
procedure FillPolygon(ACanvas: TCanvas; const APts: array of TPointF;
                      AFillColor: TAlphaColor; AStrokeColor: TAlphaColor;
                      AStrokeThick: Single);
var
  Path: TPathData;
  i:    Integer;
begin
  if Length(APts) < 2 then Exit;
  Path := TPathData.Create;
  try
    Path.MoveTo(APts[0]);
    for i := 1 to High(APts) do
      Path.LineTo(APts[i]);
    Path.ClosePath;
    ACanvas.Fill.Kind  := TBrushKind.Solid;
    ACanvas.Fill.Color := AFillColor;
    ACanvas.FillPath(Path, 1.0);
    if AStrokeThick > 0 then
    begin
      ACanvas.Stroke.Kind      := TBrushKind.Solid;
      ACanvas.Stroke.Color     := AStrokeColor;
      ACanvas.Stroke.Thickness := AStrokeThick;
      ACanvas.DrawPath(Path, 1.0);
    end;
  finally
    Path.Free;
  end;
end;

{ ============================================================================ }
{ Layer 1 — Dark background                                                    }
{ ============================================================================ }
procedure DrawBackground(ACanvas: TCanvas; const W, H: Single);
begin
  { Deep dark navy-to-forest gradient approximated with two rects }
  ACanvas.Fill.Kind  := TBrushKind.Solid;
  ACanvas.Fill.Color := $FF040D0A;
  ACanvas.FillRect(TRectF.Create(0, 0, W, H), 0, 0, [], 1.0);

  { Subtle radial vignette — lighter patch upper-left }
  for var i := 8 downto 1 do
  begin
    var R  := W * 0.55 * (i / 8.0);
    var CX := W * 0.28;
    var CY := H * 0.38;
    ACanvas.Fill.Color := MakeColor(7, 22, 18, Round(18 * (1 - i / 8.0)));
    ACanvas.FillEllipse(TRectF.Create(CX - R, CY - R, CX + R, CY + R), 1.0);
  end;
end;

{ ============================================================================ }
{ Layer 2 — City block map illustration                                        }
{ ============================================================================ }
procedure DrawMapLayer(ACanvas: TCanvas; const W, H: Single);
const
  C_GridStroke  : TAlphaColor = $160D3028;   // very dim teal grid
  C_BlockFill   : TAlphaColor = $D90A2218;   // dark green blocks
  C_BlockStroke : TAlphaColor = $440D3028;
  C_ForestFill  : TAlphaColor = $F0081A0F;
  C_TreeFill    : TAlphaColor = $E00E2E14;
  C_NodeDot     : TAlphaColor = $3800D4D4;
  C_NodeLine    : TAlphaColor = $2400D4D4;
  C_PathColor   : TAlphaColor = $D000E5E5;
  C_PathVisited : TAlphaColor = $0F00D4D4;
var
  SX, SY: Single;   // scale factors from reference 680x382 canvas

  { Map a reference-canvas coordinate to actual canvas size }
  function MX(X: Single): Single; inline; begin Result := X / 680 * W; end;
  function MY(Y: Single): Single; inline; begin Result := Y / 382 * H; end;
  function MS(S: Single): Single; inline; begin Result := S / 680 * W; end;

  procedure Block(X, Y, BW, BH: Single);
  begin
    ACanvas.Fill.Color   := C_BlockFill;
    ACanvas.Stroke.Color := C_BlockStroke;
    ACanvas.Stroke.Thickness := 0.5;
    ACanvas.FillRect(TRectF.Create(MX(X), MY(Y), MX(X+BW), MY(Y+BH)), 2, 2, [], 0.85);
    ACanvas.DrawRect(TRectF.Create(MX(X), MY(Y), MX(X+BW), MY(Y+BH)), 2, 2, [], 0.5);
  end;

  procedure TreeDot(X, Y, R: Single);
  begin
    ACanvas.Fill.Color := C_TreeFill;
    ACanvas.FillEllipse(TRectF.Create(MX(X)-MS(R), MY(Y)-MS(R),
                                       MX(X)+MS(R), MY(Y)+MS(R)), 0.9);
  end;

begin
  ACanvas.Stroke.Kind := TBrushKind.Solid;
  ACanvas.Fill.Kind   := TBrushKind.Solid;

  { --- Grid lines --- }
  ACanvas.Stroke.Color     := C_GridStroke;
  ACanvas.Stroke.Thickness := 0.7;
  for var GY: Single in [70, 130, 190, 250, 310, 370] do
    ACanvas.DrawLine(TPointF.Create(0, MY(GY)), TPointF.Create(W, MY(GY)), 0.9);
  for var GX: Single in [70, 140, 210, 310, 410, 490, 570, 640] do
    ACanvas.DrawLine(TPointF.Create(MX(GX), 0), TPointF.Create(MX(GX), H), 0.9);

  { --- City blocks (left / right columns, avoid center forest zone) --- }
  Block(10, 10, 50, 50);  Block(80, 10, 50, 50);  Block(150, 10, 50, 35);
  Block(450,10, 50, 50);  Block(510,10, 50, 35);  Block(650,10, 25, 50);
  Block(10, 80, 50, 40);  Block(80, 80, 40, 40);
  Block(450,80, 50, 40);  Block(510,80, 50, 40);  Block(650,80, 25, 40);
  Block(10,140, 50, 40);  Block(80,140, 50, 40);
  Block(450,140,50, 40);  Block(510,140,40, 40);  Block(650,140,25, 40);
  Block(10,200, 50, 40);
  Block(450,200,50, 40);  Block(510,200,50, 40);  Block(650,200,25, 40);
  Block(10,260, 50, 40);  Block(80,260, 50, 40);
  Block(450,260,50, 40);  Block(510,260,50, 40);  Block(650,260,25, 40);
  Block(10,320, 50, 30);  Block(80,320, 40, 30);
  Block(450,320,50, 30);  Block(650,320,25, 30);

  { --- Forest / green zone --- }
  ACanvas.Fill.Color   := C_ForestFill;
  ACanvas.Stroke.Color := MakeColor($0C, $2A, $18, $60);
  ACanvas.Stroke.Thickness := 0.6;
  ACanvas.FillRect(TRectF.Create(MX(155), MY(130), MX(435), MY(370)), 4, 4, [], 0.95);
  ACanvas.DrawRect(TRectF.Create(MX(155), MY(130), MX(435), MY(370)), 4, 4, [], 0.6);

  { Tree canopy dots }
  TreeDot(195,160,9);  TreeDot(225,180,7);  TreeDot(260,158,10);
  TreeDot(295,175,8);  TreeDot(330,160,9);  TreeDot(365,178,7);
  TreeDot(400,155,9);  TreeDot(185,205,8);  TreeDot(220,220,9);
  TreeDot(255,208,7);  TreeDot(290,225,10); TreeDot(325,210,8);
  TreeDot(360,222,7);  TreeDot(395,205,9);  TreeDot(195,260,8);
  TreeDot(230,275,9);  TreeDot(265,262,7);  TreeDot(300,278,10);
  TreeDot(335,265,8);  TreeDot(370,275,7);  TreeDot(400,258,9);
  TreeDot(200,320,7);  TreeDot(235,335,9);  TreeDot(270,322,8);
  TreeDot(305,338,7);  TreeDot(340,325,9);  TreeDot(375,335,8);
  TreeDot(405,318,7);

  { --- Network node dots --- }
  ACanvas.Fill.Color := C_NodeDot;
  for var NodePt: TPointF in [
    TPointF.Create(MX(38),  MY(38)),
    TPointF.Create(MX(620), MY(28)),
    TPointF.Create(MX(645), MY(175)),
    TPointF.Create(MX(38),  MY(360)),
    TPointF.Create(MX(130), MY(365)),
    TPointF.Create(MX(565), MY(360))] do
    ACanvas.FillEllipse(TRectF.Create(NodePt.X-MS(2.5), NodePt.Y-MS(2.5),
                                       NodePt.X+MS(2.5), NodePt.Y+MS(2.5)), 1.0);

  { Network connector lines }
  ACanvas.Stroke.Color     := C_NodeLine;
  ACanvas.Stroke.Thickness := 0.45;
  ACanvas.DrawLine(TPointF.Create(MX(38), MY(38)),   TPointF.Create(MX(620), MY(28)),  0.14);
  ACanvas.DrawLine(TPointF.Create(MX(620),MY(28)),   TPointF.Create(MX(645), MY(175)), 0.14);
  ACanvas.DrawLine(TPointF.Create(MX(38), MY(360)),  TPointF.Create(MX(130), MY(365)), 0.14);
  ACanvas.DrawLine(TPointF.Create(MX(565),MY(360)),  TPointF.Create(MX(645), MY(175)), 0.14);
  ACanvas.DrawLine(TPointF.Create(MX(38), MY(38)),   TPointF.Create(MX(38),  MY(360)), 0.14);

  { --- Visited cell highlights --- }
  for var VR: TRectF in [
    TRectF.Create(MX(140),MY(190),MX(210),MY(250)),
    TRectF.Create(MX(210),MY(130),MX(280),MY(190)),
    TRectF.Create(MX(310),MY(130),MX(380),MY(190)),
    TRectF.Create(MX(410),MY(190),MX(480),MY(250)),
    TRectF.Create(MX(410),MY(250),MX(480),MY(310))] do
  begin
    ACanvas.Fill.Color := C_PathVisited;
    ACanvas.FillRect(VR, 2, 2, [], 1.0);
  end;

  { --- A* path polyline --- }
  var PathPts: array of TPointF := [
    TPointF.Create(MX(145), MY(355)),
    TPointF.Create(MX(145), MY(300)),
    TPointF.Create(MX(185), MY(240)),
    TPointF.Create(MX(255), MY(190)),
    TPointF.Create(MX(310), MY(155)),
    TPointF.Create(MX(415), MY(155)),
    TPointF.Create(MX(450), MY(215)),
    TPointF.Create(MX(450), MY(275)),
    TPointF.Create(MX(490), MY(325)),
    TPointF.Create(MX(555), MY(325))
  ];
  ACanvas.Stroke.Color     := C_PathColor;
  ACanvas.Stroke.Thickness := MS(2.8);
  ACanvas.Stroke.Join      := TStrokeJoin.Round;
  ACanvas.Stroke.Cap       := TStrokeCap.Round;
  var PathData := TPathData.Create;
  try
    PathData.MoveTo(PathPts[0]);
    for var i := 1 to High(PathPts) do
      PathData.LineTo(PathPts[i]);
    ACanvas.DrawPath(PathData, 0.82);
  finally
    PathData.Free;
  end;

  { --- Start / Finish markers --- }
  procedure DrawMarkerNode(CX, CY: Single; OuterColor, InnerFill: TAlphaColor;
                            Symbol: string; FontSz: Single);
  begin
    var R := MS(8.0);
    ACanvas.Fill.Color := OuterColor;
    ACanvas.FillEllipse(TRectF.Create(MX(CX)-R, MY(CY)-R, MX(CX)+R, MY(CY)+R), 0.9);
    ACanvas.Fill.Color := InnerFill;
    var RI := MS(4.5);
    ACanvas.FillEllipse(TRectF.Create(MX(CX)-RI, MY(CY)-RI, MX(CX)+RI, MY(CY)+RI), 1.0);
    ACanvas.Fill.Color      := OuterColor;
    ACanvas.Font.Family     := 'Orbitron';
    ACanvas.Font.Size       := FontSz;
    ACanvas.Font.Style      := [TFontStyle.fsBold];
    ACanvas.FillText(TRectF.Create(MX(CX)+R, MY(CY)-R, MX(CX)+R*3, MY(CY)+R),
                     Symbol, False, 0.85, [], TTextAlign.Leading);
  end;

  DrawMarkerNode(145, 355, $E500E5E5, $FF040D0A, 'S', MS(9));
  DrawMarkerNode(555, 325, $E50099FF, $FF040D0A, 'F', MS(9));

  { Waypoint dots }
  ACanvas.Fill.Color := MakeColor($00, $E5, $E5, $80);
  for var WP: TPointF in [
    TPointF.Create(MX(185),MY(240)), TPointF.Create(MX(255),MY(190)),
    TPointF.Create(MX(310),MY(155)), TPointF.Create(MX(415),MY(155)),
    TPointF.Create(MX(450),MY(215)), TPointF.Create(MX(450),MY(275)),
    TPointF.Create(MX(490),MY(325))] do
    ACanvas.FillEllipse(TRectF.Create(WP.X-MS(3.5), WP.Y-MS(3.5),
                                       WP.X+MS(3.5), WP.Y+MS(3.5)), 1.0);
end;

{ ============================================================================ }
{ Layer 3 — Crystal diamond logo                                               }
{ ============================================================================ }
procedure DrawDiamond(ACanvas: TCanvas; const CX, CY, Size: Single);
var
  Top, Rt, Bot, Lt: TPointF;
  Mid:              TPointF;
  InTop, InRt, InBot, InLt: TPointF;
  S, IS:            Single;
begin
  S  := Size;
  IS := S * 0.72;   // inner diamond scale

  Top := TPointF.Create(CX,    CY - S);
  Rt  := TPointF.Create(CX+S,  CY);
  Bot := TPointF.Create(CX,    CY + S);
  Lt  := TPointF.Create(CX-S,  CY);
  Mid := TPointF.Create(CX,    CY);

  InTop := TPointF.Create(CX,    CY - IS);
  InRt  := TPointF.Create(CX+IS, CY);
  InBot := TPointF.Create(CX,    CY + IS);
  InLt  := TPointF.Create(CX-IS, CY);

  { Shadow beam }
  FillPolygon(ACanvas, [Top, TPointF.Create(CX+S*0.22, CY), Bot, TPointF.Create(CX-S*0.22, CY)],
              MakeColor(0, 0, 0, 100), 0, 0);

  { Four facets with different alpha to simulate 3-D lighting }
  { Top-right facet — brightest }
  FillPolygon(ACanvas, [Top, Rt, Mid],  MakeColor($00,$C8,$C8, 46), 0, 0);
  { Bottom-right facet }
  FillPolygon(ACanvas, [Bot, Rt, Mid],  MakeColor($00,$55,$77, 56), 0, 0);
  { Top-left facet }
  FillPolygon(ACanvas, [Top, Lt, Mid],  MakeColor($00,$99,$99, 33), 0, 0);
  { Bottom-left facet — darkest }
  FillPolygon(ACanvas, [Bot, Lt, Mid],  MakeColor($00,$33,$55, 51), 0, 0);

  { Outer diamond stroke }
  FillPolygon(ACanvas, [Top, Rt, Bot, Lt],
              0, MakeColor($00,$D4,$D4, 230), 2.2);
  { Inner diamond stroke }
  FillPolygon(ACanvas, [InTop, InRt, InBot, InLt],
              0, MakeColor($00,$FF,$EE, 166), 1.2);

  { Top edge highlight }
  ACanvas.Stroke.Kind      := TBrushKind.Solid;
  ACanvas.Stroke.Color     := MakeColor($00,$FF,$FF, 179);
  ACanvas.Stroke.Thickness := 1.8;
  ACanvas.DrawLine(Top, Rt, 0.7);
  ACanvas.Stroke.Color     := MakeColor($00,$DD,$DD, 102);
  ACanvas.Stroke.Thickness := 0.9;
  ACanvas.DrawLine(Top, Lt, 0.4);
end;

{ ============================================================================ }
{ Layer 4 — Text overlay (logo, subtitle, progress, status)                    }
{ ============================================================================ }
procedure DrawTextOverlay(ACanvas: TCanvas; const W, H: Single;
                           const AProgress: Single);
const
  { Orbitron Bold — sci-fi segmented display style.
    Fallback chain keeps the technical feel if Orbitron is not installed. }
  C_FontCrystal   = 'Orbitron';
  C_FontCrystalFB = 'Consolas';     // fallback 1
  C_FontSub       = 'Rajdhani';
  C_FontSubFB     = 'Segoe UI';     // fallback 1
  C_FontSubFB2    = 'Arial Narrow'; // fallback 2

  C_ColorCrystal  : TAlphaColor = $F500E0FF;   // vivid cyan
  C_ColorCrystal2 : TAlphaColor = $F500AADD;   // deeper cyan (gradient end)
  C_ColorSubTitle : TAlphaColor = $CC7ECFCF;
  C_ColorStatus   : TAlphaColor = $994A9999;
  C_ColorCopy     : TAlphaColor = $801E4444;
  C_ColorBarBg    : TAlphaColor = $CC0D2A2A;
  C_ColorBarFill  : TAlphaColor = $F000D4FF;
  C_ColorBarFill2 : TAlphaColor = $F000FFEE;

var
  CX: Single;     // horizontal centre
  TopY: Single;   // top of content block
begin
  CX   := W / 2;
  TopY := H * 0.26;   // diamond starts at ~26% from top

  { ------------------------------------------------------------------ }
  { Diamond logo centred above text                                     }
  { ------------------------------------------------------------------ }
  DrawDiamond(ACanvas, CX, TopY + W * 0.062, W * 0.062);

  { ------------------------------------------------------------------ }
  { "CRYSTAL" logotype                                                  }
  { ------------------------------------------------------------------ }
  var LogoY := TopY + W * 0.145;
  var LogoSz := W * 0.052;   // ~36px at 680px reference width

  ACanvas.Font.Family := C_FontCrystal;
  ACanvas.Font.Size   := LogoSz;
  ACanvas.Font.Style  := [TFontStyle.fsBold];

  { Cyan colour — FMX does not support per-character gradient on FillText,
    so we layer two offset draws for a subtle glow shimmer effect:         }
  { Glow pass (slight offset, lower alpha) }
  ACanvas.Fill.Color := MakeColor($00, $FF, $FF, 30);
  ACanvas.FillText(TRectF.Create(2, LogoY + 2, W + 2, LogoY + LogoSz * 1.4),
                   'CRYSTAL', False, 1.0, [], TTextAlign.Center);
  { Main pass }
  ACanvas.Fill.Color := C_ColorCrystal;
  ACanvas.FillText(TRectF.Create(0, LogoY, W, LogoY + LogoSz * 1.4),
                   'CRYSTAL', False, 0.95, [], TTextAlign.Center);

  { ------------------------------------------------------------------ }
  { "PATH FINDING SYSTEM" subtitle                                      }
  { ------------------------------------------------------------------ }
  var SubY  := LogoY + LogoSz * 1.55;
  var SubSz := W * 0.016;

  ACanvas.Font.Family := C_FontSub;
  ACanvas.Font.Size   := SubSz;
  ACanvas.Font.Style  := [TFontStyle.fsBold];
  ACanvas.Fill.Color  := C_ColorSubTitle;
  ACanvas.FillText(TRectF.Create(0, SubY, W, SubY + SubSz * 1.6),
                   'PATH FINDING SYSTEM', False, 0.80, [], TTextAlign.Center);

  { ------------------------------------------------------------------ }
  { Progress bar                                                        }
  { ------------------------------------------------------------------ }
  var BarW   := W * 0.42;
  var BarH   := Max(3.0, H * 0.008);
  var BarX   := (W - BarW) / 2;
  var BarY   := SubY + SubSz * 2.4;

  { Track }
  ACanvas.Fill.Color := C_ColorBarBg;
  ACanvas.FillRect(TRectF.Create(BarX, BarY, BarX + BarW, BarY + BarH),
                   BarH / 2, BarH / 2, [], 0.8);

  { Fill — width driven by AProgress (0.0..1.0) }
  if AProgress > 0 then
  begin
    var FillW := BarW * EnsureRange(AProgress, 0, 1.0);
    { Gradient simulation: draw two overlapping rects }
    ACanvas.Fill.Color := C_ColorBarFill;
    ACanvas.FillRect(TRectF.Create(BarX, BarY, BarX + FillW * 0.5, BarY + BarH),
                     BarH / 2, BarH / 2, [], 0.9);
    ACanvas.Fill.Color := C_ColorBarFill2;
    ACanvas.FillRect(TRectF.Create(BarX + FillW * 0.4, BarY,
                                    BarX + FillW, BarY + BarH),
                     BarH / 2, BarH / 2, [], 0.9);
    { Shimmer dot at the leading edge }
    ACanvas.Fill.Color := MakeColor(255, 255, 255, 153);
    var DotR := BarH * 1.1;
    ACanvas.FillEllipse(TRectF.Create(BarX + FillW - DotR, BarY - DotR * 0.5,
                                       BarX + FillW + DotR, BarY + BarH + DotR * 0.5), 1.0);
  end;

  { ------------------------------------------------------------------ }
  { "System Ready." status text                                         }
  { ------------------------------------------------------------------ }
  var StY  := BarY + BarH + H * 0.025;
  var StSz := W * 0.014;

  ACanvas.Font.Family := C_FontSub;
  ACanvas.Font.Size   := StSz;
  ACanvas.Font.Style  := [];   // Light weight — no bold
  ACanvas.Fill.Color  := C_ColorStatus;
  ACanvas.FillText(TRectF.Create(0, StY, W, StY + StSz * 1.6),
                   'System Ready.', False, 0.75, [], TTextAlign.Center);

  { ------------------------------------------------------------------ }
  { Copyright line                                                      }
  { ------------------------------------------------------------------ }
  var CpY  := StY + StSz * 1.9;
  var CpSz := W * 0.011;

  ACanvas.Font.Family := C_FontSub;
  ACanvas.Font.Size   := CpSz;
  ACanvas.Font.Style  := [];
  ACanvas.Fill.Color  := C_ColorCopy;
  ACanvas.FillText(TRectF.Create(0, CpY, W, CpY + CpSz * 1.6),
                   'Copyright ' + Char(169) + ' 2026 Huicahan Kim',
                   False, 0.9, [], TTextAlign.Center);
end;

{ ============================================================================ }
{ Public entry point                                                            }
{ ============================================================================ }

procedure DrawCrystalSplash(ACanvas: TCanvas;
                             const AWidth, AHeight: Single;
                             const AProgress: Single = 1.0);
begin
  if not ACanvas.BeginScene then Exit;
  try
    { Layer 1: background }
    DrawBackground(ACanvas, AWidth, AHeight);

    { Layer 2: map illustration }
    DrawMapLayer(ACanvas, AWidth, AHeight);

    { Layer 3 & 4: diamond + text (drawn last — on top of everything) }
    DrawTextOverlay(ACanvas, AWidth, AHeight, AProgress);

  finally
    ACanvas.EndScene;
  end;
end;

end.
