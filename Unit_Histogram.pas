unit Unit_Histogram;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Graphics,
  FMX.Controls,
  FMX.Forms,
  FMX.Dialogs,
  FMX.StdCtrls,
  FMX.Controls.Presentation,
  FMX.Objects,
  FMX.Layouts;

type
  TFrame_Histogram = class(TFrame)
    Layout_Histogram: TLayout;
    PaintBox_Histogram: TPaintBox;
    Rectangle_Histogram: TRectangle;
    Label1: TLabel;
    procedure PaintBox_HistogramPaint(Sender: TObject; Canvas: TCanvas);
  private
    FBitmapBuffer: TBitmap;
    FLocaRect: TRectF;
    FMaxCount: Integer;
    FWallCount: Integer;
    FRoadCount: Integer;
    FTotal: Integer;
    FHisto: array[0..255] of Integer;
    FHistoBackup: array[0..255] of Integer;
    procedure DrawHistogram(ABitmap: TBitmap);
  public
    destructor Destroy; override;
    procedure UpdateHistogram(const AWeights: TArray<Byte>);
  end;

implementation

uses
  System.Math,
  uCommons;

{$R *.fmx}

const
  C_HistW    = 280;    // Total histogram width  (px)
  C_HistH    = 80;     // Bar area height        (px)
  C_PadX     = 14;     // Left/right inner padding
  C_PadY     = 5;      // Top/bottom inner padding
  C_BarGap   = 1;      // Gap between bars
  C_LabelH   = 14;     // Space below bars for x-axis labels
  C_PanelH   = C_HistH + C_PadY * 2 + C_LabelH;      // 80 + 10 * 2 + 14 = 114
  C_PanelW   = C_HistW + C_PadX * 2;                 // 280 + 14 * 2 = 308
  C_CornerR  = 10;
  C_BgAlpha  = 200;    // Panel background opacity  (0=transparent, 255=opaque)
  C_BarAlpha = 255;    // Bar opacity


{ TFrame1 }

procedure TFrame_Histogram.UpdateHistogram(const AWeights: TArray<Byte>);
begin
  if FBitmapBuffer = nil then
    FBitmapBuffer := TBitmap.Create;
  FBitmapBuffer.SetSize(Trunc(PaintBox_Histogram.Width), Trunc(PaintBox_Histogram.Height));
  FLocaRect := PaintBox_Histogram.LocalRect;

  if (Length(AWeights) = 0) then Exit;

  FMaxCount  := 1;
  FWallCount := 0;
  FRoadCount := 0;
  FTotal     := Length(AWeights);

  FillChar(FHisto, SizeOf(FHisto), 0);
  for var _Wgt in AWeights do
  begin
    Inc(FHisto[_Wgt]);
    if _Wgt = 255 then Inc(FWallCount);
    if _Wgt <= 15 then Inc(FRoadCount);
  end;

  if AreStaticArraysEqual(FHisto, FHistoBackup, SizeOf(FHistoBackup)) then
  begin
    PaintBox_Histogram.Repaint;
    Exit;
  end;

  System.Move(FHisto, FHistoBackup, SizeOf(FHisto));

  for var _i := 0 to 254 do                                                     // Exclude 255 (wall) from scale
    if FHisto[_i] > FMaxCount then FMaxCount := FHisto[_i];

  DrawHistogram(FBitmapBuffer);
end;

destructor TFrame_Histogram.Destroy;
begin
  if Assigned(FBitmapBuffer) then
  FBitmapBuffer.Free;
  inherited;
end;

{ ============================================================================ }
{  DrawWeightHistogram                                                         }
{  Draws a semi-transparent weight distribution histogram overlay              }
{  at the bottom-center of PaintBox_Map.                                       }
{ ============================================================================ }

procedure TFrame_Histogram.DrawHistogram(ABitmap: TBitmap);
begin
  if not ABitmap.Canvas.BeginScene() then Exit;

  with ABitmap do
  try
    Canvas.Clear($AA16253D);
    { 1. Draw bars (0~254) --------------------------------------------------- }
    var _BarW  := (C_HistW - C_BarGap * 254) / 255;
    var _Color := MakeAlphaColor(TAlphaColorRec.White, C_BarAlpha);
    var _BarH: Single := 0;
    var _BarX: Single := 0;
    var _BarY: Single := 0;
    for var _j := 0 to 254 do
    begin
      if FHisto[_j] = 0 then Continue;

      _BarH := (FHisto[_j] / FMaxCount) * C_HistH;
      _BarX := C_PadX + _j * (_BarW + C_BarGap);
      _BarY := C_PadY + C_HistH - _BarH + 2;

      Canvas.Fill.Color := _Color;
      Canvas.FillRect(RectF(_BarX, _BarY, _BarX + _BarW, C_PadY + C_HistH + 2), 0, 0, [], 1.0);
    end;

    { 2. Wall bar (255) — shown separately, far right, dark red -------------- }
    if FHisto[255] > 0 then
    begin
      _BarH := Min((FHisto[255] / FMaxCount) * C_HistH, C_HistH);
      _BarX := C_PadX + 254 * (_BarW + C_BarGap) + 2;
      _BarY := C_PadY + C_HistH - _BarH + 2;
      Canvas.Fill.Color := MakeAlphaColor(180, 30, 30, C_BarAlpha);
      Canvas.FillRect(RectF(_BarX, _BarY, _BarX + _BarW + 1, C_PadY + C_HistH + 2), 0, 0, [], 1.0);
    end;

    { 3. X-axis tick labels  0 / 64 / 128 / 192 / 255 ------------------------ }
    Canvas.Fill.Color := MakeAlphaColor(160, 160, 160, 200);
    Canvas.Font.Size  := 7.5;
    for var _k := 0 to 4 do
    begin
      var _val  := _k * 64; if _val > 255 then _val := 255;
      var _tx   := C_PadX + _val * (_BarW + C_BarGap);
      var _tyR  := RectF(_tx - 12, C_PadY + C_HistH + 3, _tx + 12, C_PanelH - 1);
      Canvas.FillText(_tyR, IntToStr(_val), False, 1.0, [], TTextAlign.Center);
    end;

    { 4. Stats overlay (Road% / Wall%) --------------------------------------- }
    var _RoadPct := Round(FRoadCount / FTotal * 100);
    var _WallPct := Round(FWallCount / FTotal * 100);
    var _StatsR  := RectF(C_PadX, 10, C_PanelW - C_PadX, 18);

    Canvas.Font.Size  := 7.5;
    Canvas.Fill.Color := MakeAlphaColor(80, 220, 80, 200);
    Canvas.FillText(_StatsR, Format('Road %d%%', [_RoadPct]), False, 1.0, [], TTextAlign.Leading);
    Canvas.FillText(_StatsR, Format('Wall %d%%', [_WallPct]), False, 1.0, [], TTextAlign.Trailing);
  finally
    Canvas.EndScene;
  end;

  PaintBox_Histogram.Repaint;
end;

procedure TFrame_Histogram.PaintBox_HistogramPaint(Sender: TObject; Canvas: TCanvas);
begin
  Canvas.DrawBitmap(FBitmapBuffer, FLocaRect, FLocaRect, 1.0);
end;

end.

