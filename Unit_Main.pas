unit Unit_Main;

{ **************************************************************************** }
{ Crystal Path Finder - High Performance Version for Delphi 13 Florence        }
{ Optimized with Binary Heap, Minimal Memory Allocation and Parallel Safety    }
{ ---------------------------------------------------------------------------- }
{                                                                              }
{ This is inspired by https://github.com/d-mozulyov/CrystalPathFinding         }
{ **************************************************************************** }

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  System.UIConsts,
  System.Diagnostics,
  System.Threading,
  System.Actions,
  FMX.ActnList,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  FMX.StdCtrls,
  FMX.Controls.Presentation,
  FMX.Layouts,
  FMX.ListBox,
  FMX.Objects,
  FMX.Edit,
  FMX.MultiView,
  FMX.Filter.Effects,
  FMX.EditBox,
  FMX.SpinBox,
  FMX.NumberBox,
  //
  CrystalPathFinding_ex;

type
  { Enum to manage mouse interaction states including custom weight painting }
  TDragMode = (None, StartPoint, FinishPoint, PanMap, EditWeight);

  TFormMain = class(TForm)
    LayoutRoot: TLayout;
    LayoutHeader: TLayout;
    Label_Title: TLabel;
    Button_Reset: TButton;
    ComboBox_Kind: TComboBox;
    CheckBoox_Parallel: TCheckBox;
    Label_Performance: TLabel;
    PaintBox_Map: TPaintBox;
    Label_WeightScale: TLabel;
    Layout_Buttons: TLayout;
    TrackBar_Weight: TTrackBar;
    StyleBook1: TStyleBook;
    StatusBar_Map: TStatusBar;
    Label_Simbol: TLabel;
    Label_SInfos: TLabel;
    mvOptions: TMultiView;
    MultiView_Background: TRectangle;
    Button_Options: TButton;
    Label_ViewPos: TLabel;
    Button_LoadMap: TButton;
    OpenDialog_Map: TOpenDialog;
    ActionList1: TActionList;
    Action_Screenshot: TAction;
    Button_Heighlight: TButton;
    CheckBox_FitToScreen: TCheckBox;
    CheckBox_SmoothLine: TCheckBox;
    CheckBox_Analysis: TCheckBox;
    Label_Grids: TLabel;
    Label_Zoom: TLabel;
    Action_Analysis: TAction;
    Label_GridCellSize: TLabel;
    TrackBar_Tilesize: TTrackBar;
    Action_LoadMap: TAction;
    Action_Highleght: TAction;
    Action_Options: TAction;
    Action_ResetMap: TAction;
    Label2: TLabel;
    Label3: TLabel;
    CheckBox_Calcurate: TCheckBox;
    CheckBox_CellWeight: TCheckBox;
    TrackBar_CellWeight: TTrackBar;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
    procedure PaintBox_MapMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure PaintBox_MapMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure PaintBox_MapPaint(Sender: TObject; Canvas: TCanvas);
    procedure PaintBox_MapMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure PaintBox_MapMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
    procedure ComboBox_KindChange(Sender: TObject);
    procedure CheckBox_FitToScreenChange(Sender: TObject);
    procedure TrackBar_WeightTracking(Sender: TObject);
    procedure TrackBar_TilesizeTracking(Sender: TObject);
    procedure Button_HeighlightMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure Button_HeighlightMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure Action_ScreenshotExecute(Sender: TObject);
    procedure Action_AnalysisExecute(Sender: TObject);
    procedure ActionList1Update(Action: TBasicAction; var Handled: Boolean);
    procedure Action_LoadMapExecute(Sender: TObject);
    procedure Action_ResetMapExecute(Sender: TObject);
    procedure Label_TitleClick(Sender: TObject);
    procedure TrackBar_CellWeightChange(Sender: TObject);
  private
    FTileMap: TTileMap;
    FCurrentPath: TTileMapPath;
    FBackgroundBitmap: TBitmap;
    FViewOffset: TPointF;
    FCellSize: Single;
    FStartPos: TPoint;
    FFinishPos: TPoint;
    FWeights: TArray<Byte>;
    FWeightMultiplier: Single;
    FDragMode: TDragMode;
    FLastMousePos: TPointF;
    FIsHighlightMode: Boolean;

    FDefaultBackColor: TAlphaColor;
    FLockMapFlag: Boolean;
    FDefaultMap: TImage;
    FZoomRatio: Single;
    FIsDrawingWall: Boolean;
    FResizeClearFlag: Boolean;
    FPerformanceTick: Cardinal;

    FPosIcon_S: TBitmap;
    FPosIcon_F: TBitmap;
    FCurrentWeight: Byte;
    FCurrentWightFlag: Byte;
    FCurrGridX: Integer;
    FCurrGridY: Integer;

    FSetCellSize: Single;
    procedure InitializeGrid(const ADefault: Boolean = False);
    procedure UpdatePath;
    procedure AdjustMarkersToViewport;
    function ScreenToGridF(X, Y: Single): TPoint;
    procedure ScreenToGridP(const AScreenPos: TPointF; out AGX, AGY: Integer);
    function GridToScreenF(const GridPos: TPoint): TPointF;
    procedure GridToScreenP(const AGX, AGY: Integer; out AScreenPos: TPointF);

    procedure AnalyzeHeightMap;                                                 { Analysis Logic in Height Map Style }
    procedure AnalyzeHeightMap_ex;
    procedure FitToScreen;
    procedure CenterMap;
    procedure ConstrainViewOffset;

    function IsInGrid(GX, GY: Integer): Boolean;
    procedure CalculateWeightsFromImage(const ADefault: Boolean = False);
    procedure DrawTiles(Canvas: TCanvas);
    procedure DrawGrid(ACanvas: TCanvas);
    procedure DrawMarker(Canvas: TCanvas; const GridPos: TPoint; const Color1, Color2: TAlphaColor; const Symbol: string);  overload;
    procedure DrawMarker(Canvas: TCanvas; const APosFlag: Integer; const GridPos: TPoint); overload;
    procedure DrawSmoothPath(ACanvas: TCanvas; const ASmoothFlag: Boolean = False);

    procedure AutoCropImage(ABitmap: TBitmap);
    function IsPathValid: Boolean;
    function GetWeightColor(Weight: Byte): TAlphaColor;
    procedure SetCellWeight(const GridPos: TPoint; Value: Byte);
    procedure SetZoomRatio(const Value: Single);

    procedure UpdateStatusLabel(const AFlag: Integer; const AParams: Boolean = True);
    procedure SaveScreenshot(const ADialogFlag: Boolean = False);
    procedure ShowToastAlert(const AMsg: string);
    procedure AnimationFinishedEvent(Sender: TObject);
    procedure SetupMultiViewPopup;
    procedure SetSetCellSize(const Value: Single);
  public
    property ZoomRatio: Single    read FZoomRatio    write SetZoomRatio;
    property SetCellSize: Single  read FSetCellSize  write SetSetCellSize;
  end;

var
  FormMain: TFormMain;

implementation

uses
  uCommons,
  Unit_Resources,
  System.Math,
  System.IOUtils,
  System.Math.Vectors,
  FMX.Ani;


{$R *.fmx}

const
  C_CellSizeDefault = 32.0;
  C_CaptionTitle    = 'Crystal Path Finder - Copyright '+ Char(169)+' 2026 Huicahan Kim';

{ TFormMain ------------------------------------------------------------------ }

procedure TFormMain.FormCreate(Sender: TObject);
begin
  Self.Caption :=       C_CaptionTitle;

  FIsHighlightMode :=   False;
  FLockMapFlag :=       True;
  FWeightMultiplier :=  0.5;
  FCurrentWightFlag :=  0;
  FDefaultBackColor :=  $FF16253D;
  FResizeClearFlag :=   False;

  FStartPos :=          TPoint.Create(10, 10);
  FFinishPos :=         TPoint.Create(110, 110);
  FCellSize :=          6.0;  {  ... }
  FViewOffset :=        TPointF.Create(100, 100);

  FCellSize :=          C_CellSizeDefault;
  FDragMode :=          TDragMode.None;
  FBackgroundBitmap :=  TBitmap.Create;

  CheckBox_Analysis.IsChecked :=  False;
  CheckBox_Calcurate.IsChecked := True;
  Label_Performance.Visible :=    False;

  FViewOffset := TPointF.Create(0, 0);
  with ComboBox_Kind do
  begin
    OnChange := nil;
    items.Clear;
    Items.Add('Square');
    Items.Add('Diagonal');
    Items.Add('Hexagonal');
    ItemIndex := 1;
    OnChange  := ComboBox_KindChange;
  end;

  TrackBar_Weight.Value := 5;
  Label_WeightScale.Text := Format('Map Weight Scale %.2f', [TrackBar_Weight.Value / 10]);
  FSetCellSize := C_CellSizeDefault;
  TrackBar_Tilesize.Value := C_CellSizeDefault;
  FZoomRatio := 1.0;
  CheckBox_FitToScreen.IsChecked := False;
  SetupMultiViewPopup;

  { Create initial small map to be resized in InitializeGrid }
  FTileMap := TTileMap.Create(10, 10, TTileMapKind.mkDiagonal);
  // ------------------------------------------------------------------------ //
  InitializeGrid(False);
  // ------------------------------------------------------------------------ //
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  FCurrentPath.Free;
  FTileMap.Free;
  FBackgroundBitmap.Free;
end;

procedure TFormMain.FormResize(Sender: TObject);
begin
  if FLockMapFlag then Exit;

  if FTileMap <> nil then
  begin
    FitToScreen;
    CenterMap;
  end;
  // ------------------------------------------------------------------------ //
  PaintBox_Map.Repaint;
  // ------------------------------------------------------------------------ //
end;

procedure TFormMain.SetupMultiViewPopup;
begin
  with mvOptions do
  begin
    Mode := TMultiViewMode.Popover;
    PopoverOptions.PopupHeight := 450;
    MasterButton := Button_Options;
    TargetControl := nil;

    Width := 225;
  end;

  with MultiView_Background do
  begin
    Stroke.Kind := TBrushKind.Solid;
    XRadius := 10;
    YRadius := 10;

    Enabled := not FLockMapFlag;
  end;
end;

procedure TFormMain.SetZoomRatio(const Value: Single);
begin
  if FZoomRatio <> Value then
  begin
    FZoomRatio := Value;
    UpdateStatusLabel(0);
  end;
end;

procedure TFormMain.Label_TitleClick(Sender: TObject);
begin
  Label_Performance.Visible := not Label_Performance.Visible;
end;

procedure TFormMain.FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
const
  _MoveStep = 20.0; // Arrow key movement sensitivity (pixels)
begin
  if FLockMapFlag then Exit;

  var _effectflag: Boolean := False;

  if ssCtrl in Shift then
    begin
      if CheckBox_Analysis.IsChecked then
        begin
          var _newvalue := TrackBar_Weight.Value;
          case Key of
            vkUp:    begin _newvalue := EnsureRange(_newvalue + 1, 1, 10); TrackBar_Weight.Value := _newvalue; _effectflag := True; end;
            vkDown:  begin _newvalue := EnsureRange(_newvalue - 1, 1, 10); TrackBar_Weight.Value := _newvalue; _effectflag := True; end;
          end;
        end
      else
        begin
          var _dummy: Boolean := True;
          var _wheeldelta: Integer := 1;
          case Key of
            vkUp:    begin _wheeldelta := 1;  PaintBox_MapMouseWheel(Self, [], _wheeldelta, _dummy); _effectflag := True; end;
            vkDown:  begin _wheeldelta := -1; PaintBox_MapMouseWheel(Self, [], _wheeldelta, _dummy); _effectflag := True; end;
          end;
        end;
    end
  else
    begin
      var _DeltaXY: TPointF := PointF(0, 0);
      case Key of
        vkLeft:  begin _DeltaXY := PointF(-_MoveStep, 0);   FViewOffset := FViewOffset + _DeltaXY; _effectflag := True; end;
        vkUp:    begin _DeltaXY := PointF(0, -_MoveStep);   FViewOffset := FViewOffset + _DeltaXY; _effectflag := True; end;
        vkRight: begin _DeltaXY := PointF(_MoveStep,  0);   FViewOffset := FViewOffset + _DeltaXY; _effectflag := True; end;
        vkDown:  begin _DeltaXY := PointF(0,  _MoveStep);   FViewOffset := FViewOffset + _DeltaXY; _effectflag := True; end;
      end;
    end;

  Key := 0;

  if _effectflag then
  begin
    FLastMousePos := FViewOffset;
    // ------------------------------------------------------------------------ //
    PaintBox_Map.Repaint;
    // ------------------------------------------------------------------------ //
    UpdateStatusLabel(0);
  end;
end;

procedure TFormMain.ConstrainViewOffset;
begin
  if (FTileMap = nil) then Exit;

  var _MapW := FTileMap.Width * FCellSize;
  var _MapH := FTileMap.Height * FCellSize;

  if _MapW <= PaintBox_Map.Width then
    FViewOffset.X := (PaintBox_Map.Width - _MapW) / 2                           // If it's smaller than the screen, center
  else
    FViewOffset.X := EnsureRange(FViewOffset.X, PaintBox_Map.Width - _MapW, 0); // Larger than the screen, limit the margin

  if _MapH <= PaintBox_Map.Height then
    FViewOffset.Y := (PaintBox_Map.Height - _MapH) / 2                          // If it's smaller than the screen, center
  else
    FViewOffset.Y := EnsureRange(FViewOffset.Y, PaintBox_Map.Height - _MapH, 0);// Larger than the screen, limit the margin
end;

procedure TFormMain.CenterMap;
begin
  if FTileMap = nil then Exit;

  var _MapDisplayWidth :=  FTileMap.Width *  FCellSize;
  var _MapDisplayHeight := FTileMap.Height * FCellSize;

  FViewOffset.X := (PaintBox_Map.Width -  _MapDisplayWidth) / 2;
  FViewOffset.Y := (PaintBox_Map.Height - _MapDisplayHeight) / 2;

  ConstrainViewOffset; // Check once more ...
end;

procedure TFormMain.AdjustMarkersToViewport;
begin
  if (FTileMap = nil) or (FCellSize <= 0) then Exit;

  var _GStart := ScreenToGridF(0, 0);
  var _GEnd :=   ScreenToGridF(PaintBox_Map.Width, PaintBox_Map.Height);

  _GStart.X := EnsureRange(_GStart.X, 0, FTileMap.Width - 1);
  _GStart.Y := EnsureRange(_GStart.Y, 0, FTileMap.Height - 1);
  _GEnd.X :=   EnsureRange(_GEnd.X,   0, FTileMap.Width - 1);
  _GEnd.Y :=   EnsureRange(_GEnd.Y,   0, FTileMap.Height - 1);

  var _CenterX := (_GStart.X + _GEnd.X) div 2;
  var _CenterY := (_GStart.Y + _GEnd.Y) div 2;

  FStartPos :=  TPoint.Create(Max(_GStart.X, _CenterX - (_GEnd.X - _GStart.X) div 4), _CenterY);
  FFinishPos := TPoint.Create(Min(_GEnd.X,   _CenterX + (_GEnd.X - _GStart.X) div 4), _CenterY);
end;

procedure TFormMain.FitToScreen;
begin
  if (FTileMap = nil) or (PaintBox_Map.Width <= 0) then Exit;

  if CheckBox_FitToScreen.IsChecked then
    begin
      var _Ratio_W :=  (PaintBox_Map.Width * 0.95) /  FTileMap.Width;
      var _Ratio_H :=  (PaintBox_Map.Height * 0.95) / FTileMap.Height;
      FCellSize := Min(_Ratio_W, _Ratio_H);

    end
  else
    FCellSize := FSetCellSize;

  FCellSize := EnsureRange(FCellSize, 0.5, 500.0);
end;

procedure TFormMain.AutoCropImage(ABitmap: TBitmap);
begin
  if ABitmap.IsEmpty then Exit;

  var _MinX := ABitmap.Width;
  var _MinY := ABitmap.Height;
  var _MaxX := 0;
  var _MaxY := 0;
  var _IsFound := False;

  var _rgbcolor:= MakeColor(0,0,0);
  var _Pixel :=   MakeColor(255,255,255);
  var _Data: TBitmapData;
  if ABitmap.Map(TMapAccess.Read, _Data) then
  try
    var _H, _S, _L: Single;
    for var _y := 0 to ABitmap.Height - 1 do
      for var _x := 0 to ABitmap.Width - 1 do
        begin
          _Pixel := _Data.GetPixel(_x, _y);
          _rgbcolor := MakeColor(TAlphaColorRec(_Pixel).R, TAlphaColorRec(_Pixel).G, TAlphaColorRec(_Pixel).B);
          System.UIConsts.RGBtoHSL(_rgbcolor, _H, _S, _L);
          if (_L < 0.98) and (_L > 0.02) and (_S > 0.01) then
          begin
            if _x < _MinX then _MinX := _x;
            if _x > _MaxX then _MaxX := _x;
            if _y < _MinY then _MinY := _y;
            if _y > _MaxY then _MaxY := _y;
            _IsFound := True;
          end;
        end;
  finally
    ABitmap.Unmap(_Data);
  end;

  if _IsFound and ((_MinX > 0) or (_MinY > 0) or (_MaxX < ABitmap.Width - 1) or (_MaxY < ABitmap.Height - 1)) then
  begin
    var _TempBmp := TBitmap.Create;
    try
      _TempBmp.SetSize(_MaxX - _MinX + 1, _MaxY - _MinY + 1);
      _TempBmp.CopyFromBitmap(ABitmap, TRect.Create(_MinX, _MinY, _MaxX + 1, _MaxY + 1), 0, 0);
      ABitmap.Assign(_TempBmp);
    finally
      _TempBmp.Free;
    end;
  end;
end;

procedure TFormMain.InitializeGrid(const ADefault: Boolean = False);
begin
  var _CellSize := FSetCellSize;
  if ADefault then
     _CellSize := TrackBar_Tilesize.Value;
  FSetCellSize := _CellSize;
  { Calculate grid dimensions based on current PaintBox size }
  var _TileWidth :=  Max(5, Trunc(PaintBox_Map.Width /  FSetCellSize));
  var _TileHeight := Max(5, Trunc(PaintBox_Map.Height / FSetCellSize));

  if not FBackgroundBitmap.IsEmpty then
  begin
    AutoCropImage(FBackgroundBitmap);
    _TileWidth :=  Max(10, Trunc(FBackgroundBitmap.Width /  FSetCellSize));
    _TileHeight := Max(10, Trunc(FBackgroundBitmap.Height / FSetCellSize));
  end;

  FCurrentPath.Free;
  SetLength(FWeights, _TileWidth * _TileHeight);
  FillChar(FWeights[0], Length(FWeights) * SizeOf(Byte), 0);

  FreeAndNil(FTileMap);
  FTileMap := TTileMap.Create(_TileWidth, _TileHeight, TTileMapKind(ComboBox_Kind.ItemIndex));
  FillChar(FTileMap.Data^, _TileWidth * _TileHeight, 0);

  FStartPos :=  TPoint.Create(Trunc(_TileWidth * 0.1), Trunc(_TileHeight * 0.5));
  FFinishPos := TPoint.Create(Trunc(_TileWidth * 0.9), Trunc(_TileHeight * 0.5));

  if (not FBackgroundBitmap.IsEmpty) and CheckBox_Calcurate.IsChecked then
    CalculateWeightsFromImage;

  // ------------------------------------------------------------------------ //
  AnalyzeHeightMap;
  FitToScreen;
  CenterMap;
  AdjustMarkersToViewport;
  UpdatePath;
  // ------------------------------------------------------------------------ //

  MultiView_Background.Enabled := not FLockMapFlag;
end;

function TFormMain.GetWeightColor(Weight: Byte): TAlphaColor;
begin
  //Result := MakeColor(255, 150, 0, Min(Weight, 130));
  // 밝기 농도(Weight)에 따라 색상 가시화    // 가중치가 높을수록 붉은색, 낮을수록 노란/초록색 계열로 표현
  if Weight > 180 then Result := MakeAlphaColor(TAlphaColors.Red, 130) else
  if Weight > 120 then Result := MakeAlphaColor(TAlphaColors.Orange, 100) else
  if Weight > 60  then Result := MakeAlphaColor(TAlphaColors.Yellow, 70)
                  else Result := MakeAlphaColor(TAlphaColors.Greenyellow, 40);
end;

function TFormMain.IsPathValid: Boolean;
begin
  Result := (FCurrentPath.Count > 0);
end;

  { ---- Classify a Single Pixel into a Terrain Type ------------------------- }
  { Returns:                                                                   }
  {   AWeight : Pathfinding cost (0 = free passage, 255 = impassable wall)     }
  {   AWall   : True means the cell is completely impassable                   }
  { -------------------------------------------------------------------------- }
  { Common patterns observed in Google satellite imagery:                      }
  {   - Dense tree canopy shade: greenish hue but low V                        }
  {     -> previously misclassified as wall by the old code                    }
  {   - Urban roads: mid-range V, near-zero S -> achromatic gray               }
  {   - Building rooftops: varied hue, high V                                  }

 procedure ClassifyPixel(R, G, B: Byte;
                           out AWeight: Byte; out AWall: Boolean); inline;
  var
    H, S, V: Single;
  begin
    RGBToHSV(R, G, B, H, S, V);

    { 1. Deep shadow / tunnel / no-data -> wall                                }
    {    V < 0.10 is nearly black; building shadows in Google Maps fall here   }
    {    However, if S is slightly elevated it could be dense vegetation,      }
    {    so S is also checked before marking as wall                           }
    if (V < 0.10) and (S < 0.20) then
    begin
      AWall := True; AWeight := 255; Exit;
    end;

    { 2. Water body (river, lake, reservoir) -> wall                           }
    {    Blue hue range with noticeable saturation                             }
    if (H >= 170) and (H <= 245) and (S > 0.22) and (V > 0.12) then
    begin
      AWall := True; AWeight := 255; Exit;
    end;

    { 3. Road / paved surface -> Weight 0~15 (strongly preferred by pathfinder)}
    {    Achromatic (low S) + mid-range V -> asphalt / concrete                }
    {    V range extended to 0.20~0.80 to include shaded road sections         }
    if (S < 0.16) and (V >= 0.20) and (V <= 0.80) then
    begin
      AWall := False;
      { Slight cost gradient by road brightness: bright road = 0, dark = 15  }
      AWeight := Trunc(Max(0.0, (0.45 - V)) * 30.0);
      Exit;
    end;

    { 4. Bright building rooftop / parking lot -> Weight 25                    }
    {    Low S and high V: concrete surfaces, flat rooftops                    }
    if (S < 0.22) and (V > 0.75) then
    begin
      AWall := False; AWeight := 25; Exit;
    end;

    { 5. Vegetation / forest / park -> Weight 50~180 (passable, high cost)     }
    {    [KEY FIX] KEY FIX: vegetation is no longer classified as a wall       }
    {    H 75~165 (yellow-green to cyan-green), S > 0.15                       }
    {    Even with low V (dense canopy shade) it is treated as vegetation,     }
    {    which resolves the misclassification present in the original code     }
    if (H >= 75) and (H <= 165) and (S > 0.15) then
    begin
      AWall := False;
      { Higher S (denser forest) and lower V (deeper shade) raise the cost    }
      AWeight := EnsureRange(Trunc(50 + S * 100 + (0.6 - V) * 60), 50, 180);
      Exit;
    end;

    { 6. Bare soil / unpaved path / farmland -> Weight 30~100                  }
    {    Earthy / ochre hue range                                              }
    if (H >= 18) and (H <= 58) and (S > 0.14) and (V > 0.22) then
    begin
      AWall := False;
      AWeight := EnsureRange(Trunc(30 + (1.0 - V) * 70), 30, 100);
      Exit;
    end;

    { 7. Building facade / general urban area (fallback)                       }
    AWall   := False;
    AWeight := EnsureRange(Trunc((1.0 - V) * 80 + S * 50), 0, 200);
  end;

procedure TFormMain.AnalyzeHeightMap;
var
  _StepX, _StepY:  Single;
  _Data:           TBitmapData;
  _GridX, _GridY:  Integer;
  _px, _py, _Idx:  Integer;
  _Rec:            TAlphaColorRec;
  _PixW:           Byte;
  _IsWall:         Boolean;

  { Per-cell accumulators }
  _WeightSum:      Int64;
  _WallVotes:      Integer;
  _PixelCount:     Integer;

  { 1-Pass statistics }
  _TotalSamples:   Integer;
  _SumV:           Double;     // Accumulated brightness (V) across all samples
  _MeanV:          Single;     // Mean brightness of the entire image
  _SumS:           Double;     // Accumulated saturation (S) across all samples
  _MeanS:          Single;     // Mean saturation of the entire image

  { Adaptive threshold }
  _WallThresh:     Single;     // Fraction of wall-pixels per cell to trigger wall
  _H, _S, _V:      Single;
  _FinalWeight:    Integer;
begin
  if FBackgroundBitmap.IsEmpty then Exit;
  if (FTileMap = nil) or (FTileMap.Width = 0) then Exit;

  SetLength(FWeights, FTileMap.Width * FTileMap.Height);
  FillChar(FWeights[0], Length(FWeights) * SizeOf(Byte), 0);

  _StepX := FBackgroundBitmap.Width  / FTileMap.Width;
  _StepY := FBackgroundBitmap.Height / FTileMap.Height;

  FWeightMultiplier := TrackBar_Weight.Value / 10.0;
  if FWeightMultiplier <= 0 then FWeightMultiplier := 1.0;

  if not FBackgroundBitmap.Map(TMapAccess.Read, _Data) then Exit;
  try

    { ====================================================================== }
    { 1-Pass: Compute mean Value (V) and Saturation (S) over the image       }
    {                                                                        }
    { Purpose: Adapt the wall-detection threshold to the overall             }
    {          brightness and saturation level of each loaded image,         }
    {          so the same logic works well across different maps            }
    {                                                                        }
    { Performance: Every 4th pixel sampled -> reads only 6.25% of all pixels }
    { ====================================================================== }
    _TotalSamples := 0;
    _SumV         := 0;
    _SumS         := 0;

    for _py := 0 to FBackgroundBitmap.Height - 1 do
    begin
      if _py mod 4 <> 0 then Continue;
      for _px := 0 to FBackgroundBitmap.Width - 1 do
      begin
        if _px mod 4 <> 0 then Continue;
        _Rec := TAlphaColorRec(_Data.GetPixel(_px, _py));
        RGBToHSV(_Rec.R, _Rec.G, _Rec.B, _H, _S, _V);
        _SumV := _SumV + _V;
        _SumS := _SumS + _S;
        Inc(_TotalSamples);
      end;
    end;

    if _TotalSamples > 0 then
      begin
        _MeanV := _SumV / _TotalSamples;
        _MeanS := _SumS / _TotalSamples;
      end
    else
      begin
        _MeanV := 0.45;     // Neutral fallback if sampling fails
        _MeanS := 0.20;
      end;

    { --- Adaptive Wall Detection Threshold Calculation -------------------- }
    {                                                                        }
    { Logic:                                                                 }
    {   Darker image overall  (low MeanV)  -> loosen threshold               }
    {   Higher saturation overall (high MeanS) -> lots of vegetation         }
    {                                         -> loosen threshold            }
    {                                                                        }
    { Effect: Prevents entire forests from becoming walls on                 }
    {         mountain-heavy maps                                            }
    {                                                                        }
    { Range: 0.35 (strict / fewer walls) ~ 0.65 (loose / more walls)         }
    _WallThresh := EnsureRange(
      0.55                               // Base threshold
      - (_MeanV - 0.40) * 0.30           // Brighter image -> stricter (lower)
      + (_MeanS - 0.15) * 0.25,          // Higher saturation -> looser (higher)
      0.35, 0.65);

    { ====================================================================== }
    { 2-Pass: Per-cell pixel classification -> weight + wall decision        }
    { ====================================================================== }
    for _GridY := 0 to FTileMap.Height - 1 do
      for _GridX := 0 to FTileMap.Width - 1 do
      begin
        _WeightSum  := 0;
        _WallVotes  := 0;
        _PixelCount := 0;

        for _py := Max(0, Trunc(_GridY * _StepY))
                to Min(FBackgroundBitmap.Height - 1,
                       Trunc((_GridY + 1) * _StepY) - 1) do
          for _px := Max(0, Trunc(_GridX * _StepX))
                  to Min(FBackgroundBitmap.Width - 1,
                         Trunc((_GridX + 1) * _StepX) - 1) do
          begin
            _Rec := TAlphaColorRec(_Data.GetPixel(_px, _py));
            ClassifyPixel(_Rec.R, _Rec.G, _Rec.B, _PixW, _IsWall);
            if _IsWall then Inc(_WallVotes);
            _WeightSum := _WeightSum + _PixW;
            Inc(_PixelCount);
          end;

        if _PixelCount = 0 then Continue;
        _Idx := _GridY * FTileMap.Width + _GridX;

        { --- Wall Decision ------------------------------------------------ }
        {                                                                    }
        { A cell is marked as a wall only when the fraction of wall-pixels   }
        { meets or exceeds _WallThresh.                                      }
        { This means a few tree-shadow pixels mixed into a road cell will    }
        { NOT turn that road cell into a wall.                               }
        if (_WallVotes / _PixelCount) >= _WallThresh then
          begin
            (FTileMap.Data + _Idx)^ := 1;    // Mark as wall
            FWeights[_Idx]          := 255;
          end
        else
          begin
            (FTileMap.Data + _Idx)^ := 0;    // Passable cell

            { Apply mean weight scaled by the Weight slider multiplier         }
            _FinalWeight := Trunc((_WeightSum / _PixelCount) * FWeightMultiplier);
            FWeights[_Idx] := EnsureRange(_FinalWeight, 0, 254);
          end;
      end;

  finally
    FBackgroundBitmap.Unmap(_Data);
  end;
end;

procedure TFormMain.AnalyzeHeightMap_ex;
begin
  if FBackgroundBitmap.IsEmpty then Exit;

  SetLength(FWeights, FTileMap.Width * FTileMap.Height);

  var _StepX := FBackgroundBitmap.Width / FTileMap.Width;
  var _StepY := FBackgroundBitmap.Height / FTileMap.Height;

  // Adjust sensitivity through slider values (recommended values between 0.5 and 5.0)
  FWeightMultiplier := TrackBar_Weight.Value / 10.0;
  if FWeightMultiplier <= 0 then FWeightMultiplier := 1.0;

  var _Data: TBitmapData;
  if FBackgroundBitmap.Map(TMapAccess.Read, _Data) then
  try
    var _PixelColor := TAlphaColors.Black;
    var _Luminance: Byte :=      0;
    var _Idx: Integer :=         0;
    var _SumL: Int64 :=          0;
    var _PixelCount: Integer :=  0;
    var _FinalWeight: Integer := 0;
    for var _GridY := 0 to FTileMap.Height - 1 do
      for var _GridX := 0 to FTileMap.Width - 1 do
      begin
        _SumL := 0;
        _PixelCount := 0;

        // Peripheral pixel sampling (with simple blur effect)
        for var _y := Max(0, Trunc(_GridY * _StepY)) to Min(FBackgroundBitmap.Height-1, Trunc((_GridY+1)*_StepY)-1) do
          for var _x := Max(0, Trunc(_GridX * _StepX)) to Min(FBackgroundBitmap.Width-1, Trunc((_GridX+1)*_StepX)-1) do
          begin
            _PixelColor := _Data.GetPixel(_x, _y);
            // Gray scale conversion
            _Luminance := Trunc(
              (TAlphaColorRec(_PixelColor).R * 0.299) +
              (TAlphaColorRec(_PixelColor).G * 0.587) +
              (TAlphaColorRec(_PixelColor).B * 0.114)
            );
            _SumL := _SumL + _Luminance;
            Inc(_PixelCount);
          end;

        _Idx := _GridY * FTileMap.Width + _GridX;
        if _PixelCount > 0 then
        begin
          _Luminance := Trunc(_SumL / _PixelCount);

          // Weight calculation: The darker it is, the higher the altitude or the more obstacles it is determined
          _FinalWeight := Trunc((255 - _Luminance) * FWeightMultiplier);
          FWeights[_Idx] := EnsureRange(_FinalWeight, 0, 255);

          // Absolute Obstacle (wall) setting according to threshold
          // If the weight is too high, it is considered a wall that cannot be passed at all
          if FWeights[_Idx] > 220 then
            (FTileMap.Data + _Idx)^ := 1
          else
            (FTileMap.Data + _Idx)^ := 0;
        end;
      end;
  finally
    FBackgroundBitmap.Unmap(_Data);
  end;
end;

procedure TFormMain.SetCellWeight(const GridPos: TPoint; Value: Byte);
begin
  if (FTileMap <> nil) and (GridPos.X >= 0) and (GridPos.X < FTileMap.Width) and
                           (GridPos.Y >= 0) and (GridPos.Y < FTileMap.Height) then
  begin
    var _Idx := GridPos.Y * FTileMap.Width + GridPos.X;
    FWeights[_Idx] := Value;
  end;
end;

procedure TFormMain.SetSetCellSize(const Value: Single);
begin
  if FSetCellSize <> Value then
  begin
    FSetCellSize := Value;
    UpdateStatusLabel(0);
  end;
end;

procedure TFormMain.UpdatePath;
begin
  if (FTileMap = nil) or (not IsInGrid(FStartPos.X, FStartPos.Y)) or (not IsInGrid(FFinishPos.X, FFinishPos.Y)) then Exit;

  FCurrentPath.Free;
  var _Stopwatch := TStopwatch.StartNew;
  if CheckBoox_Parallel.IsChecked then
    FCurrentPath := FTileMap.FindPathParallel(FStartPos, FFinishPos, @FWeights[0])
  else
    FCurrentPath := FTileMap.FindPath(FStartPos, FFinishPos, @FWeights[0]);
  _Stopwatch.Stop;

  FPerformanceTick := _Stopwatch.ElapsedMilliseconds;
  // ------------------------------------------------------------------------ //
  PaintBox_Map.Repaint;
  // ------------------------------------------------------------------------ //
  UpdateStatusLabel(2, IsPathValid);
end;

procedure TFormMain.ScreenToGridP(const AScreenPos: TPointF; out AGX, AGY: Integer);
begin
  AGX := Trunc((AScreenPos.X - FViewOffset.X) / FCellSize);
  AGY := Trunc((AScreenPos.Y - FViewOffset.Y) / FCellSize);
end;

procedure TFormMain.GridToScreenP(const AGX, AGY: Integer; out AScreenPos: TPointF);
begin
  AScreenPos.X := AGX * FCellSize + FViewOffset.X;
  AScreenPos.Y := AGY * FCellSize + FViewOffset.Y;
end;

function TFormMain.ScreenToGridF(X, Y: Single): TPoint;
begin
  if (FTileMap = nil) or (FCellSize <= 0) then Exit(TPoint.Zero);

  Result := TPoint.Create(Floor((X - FViewOffset.X) / FCellSize),
                          Floor((Y - FViewOffset.Y) / FCellSize));
end;

function TFormMain.GridToScreenF(const GridPos: TPoint): TPointF;
begin
  if (FTileMap = nil) or (FCellSize <= 0) then Exit(TPoint.Zero);

  Result := TPointF.Create(GridPos.X * FCellSize + FViewOffset.X + FCellSize/2,
                           GridPos.Y * FCellSize + FViewOffset.Y + FCellSize/2);
end;

{ Drawing .................................................................... }


{
  REFERENCE: Terrain Analysis & Weight Calculation Logic
  -----------------------------------------------------
  This method converts image visual data into pathfinding cost (Weight).

  1. HSV Model Usage:
     - Hue (H): Used for categorical terrain detection (e.g., Blue=Water/Wall, Green=Forest).
     - Saturation (S): Used for intensity of terrain (Higher saturation in green = denser forest).
     - Value (V): Used for accessibility (Darker areas are treated as obstacles or difficult paths).

  2. Weight Scale (0-255):
     - 0: Flat ground (Standard cost).
     - 1-100: Rough terrain (Added cost).
     - Wall (Data=1): Infinite cost (Unpassable).

  3. Sensivity Tuning:
     - To make the path prefer roads more: Increase weight for non-road colors.
     - To ignore colors: Set FWeights[Idx] to 0 for specific Hue ranges.
}

procedure TFormMain.CalculateWeightsFromImage(const ADefault: Boolean = False);
begin
  if FBackgroundBitmap.IsEmpty then Exit;

  var _StepX := FBackgroundBitmap.Width / FTileMap.Width;
  var _StepY := FBackgroundBitmap.Height / FTileMap.Height;
  var _Data: TBitmapData;
  if FBackgroundBitmap.Map(TMapAccess.Read, _Data) then
  try
    var _PixelColor :=   MakeColor(0,0,0);
    var _H: Single :=    0;
    var _S: Single :=    0;
    var _L: Single :=    0;
    var _Idx: Integer := 0;
    var _PixelCount, _ObstacleCount, _WaterCount, _RoadCount: Integer;

    for var _GridY := 0 to FTileMap.Height - 1 do
      for var _GridX := 0 to FTileMap.Width - 1 do
      begin
        _ObstacleCount := 0; _WaterCount := 0; _RoadCount := 0; _PixelCount := 0;
        for var _y := Max(0, Trunc(_GridY * _StepY)) to Min(FBackgroundBitmap.Height-1, Trunc((_GridY+1)*_StepY)-1) do
          for var _x := Max(0, Trunc(_GridX * _StepX)) to Min(FBackgroundBitmap.Width-1, Trunc((_GridX+1)*_StepX)-1) do
          begin
            _PixelColor := _Data.GetPixel(_x, _y);
            System.UIConsts.RGBtoHSL(_PixelColor, _H, _S, _L);
            if (_L > 0.85) and (_S < 0.15) then Inc(_ObstacleCount);
            if (_L < 0.2) then Inc(_WaterCount);
            if (_L > 0.4) and (_L < 0.7) and (_S < 0.2) then Inc(_RoadCount);
            Inc(_PixelCount);
          end;

        _Idx := _GridY * FTileMap.Width + _GridX;
        if _PixelCount > 0 then
        begin
          if ((_ObstacleCount + _WaterCount) / _PixelCount > 0.45) then
          begin
            (FTileMap.Data + _Idx)^ := 1;
            FWeights[_Idx] := 255;
          end
          else begin
            (FTileMap.Data + _Idx)^ := 0;
            if (_RoadCount / _PixelCount > 0.3) then FWeights[_Idx] := 0
            else FWeights[_Idx] := Trunc(Max(0, (0.8 - _L) * 40));
          end;
        end;
      end;
  finally
    FBackgroundBitmap.Unmap(_Data);
  end;
end;

procedure TFormMain.DrawTiles(Canvas: TCanvas);
var
  _Idx: Integer;
  _ScreenPos: TPointF;
  _R, _DummyRect: TRectF;
  _Val: Byte;
begin
  // Set Viewport Rectangle
  var _ViewRect := TRectF.Create(0, 0, PaintBox_MAp.Width, PaintBox_Map.Height);

  for var _y := 0 to FTileMap.Height - 1 do
    for var _x := 0 to FTileMap.Width - 1 do
    begin
      _Idx := _y * FTileMap.Width + _x;
      _Val := (FTileMap.Data + _Idx)^;

      GridToScreenP(_x, _y, _ScreenPos);
      _R := TRectF.Create(_ScreenPos.X, _ScreenPos.Y, _ScreenPos.X + FCellSize, _ScreenPos.Y + FCellSize);

      // Standard intersection check using IntersectRect from System.Types
      if not IntersectRect(_DummyRect, _ViewRect, _R) then Continue;

      if _Val = 1 then
      begin
        Canvas.Fill.Color := MakeColor(TAlphaColors.Black, 150);
        Canvas.FillRect(_R, 0, 0, [], 1.0);
      end
      else if FWeights[_Idx] > 50 then //10 then
      begin
        Canvas.Fill.Color := GetWeightColor(FWeights[_Idx]);
        Canvas.FillRect(_R, 0, 0, [], 1);
      end;
    end;
end;

procedure TFormMain.DrawGrid(ACanvas: TCanvas);
begin
  if FCellSize < 4 then Exit;

  ACanvas.Stroke.Dash :=  TStrokeDash.Dot;
  ACanvas.Stroke.Color := MakeColor(TAlphaColors.Lightgray, 40);
  ACanvas.Stroke.Thickness := 0.5;

  for var _i := 0 to FTileMap.Width do
    ACanvas.DrawLine(TPointF.Create(FViewOffset.X + _i * FCellSize, FViewOffset.Y),
                     TPointF.Create(FViewOffset.X + _i * FCellSize, FViewOffset.Y + FTileMap.Height * FCellSize), 1.0);

  for var _i := 0 to FTileMap.Height do
    ACanvas.DrawLine(TPointF.Create(FViewOffset.X, FViewOffset.Y + _i * FCellSize),
                     TPointF.Create(FViewOffset.X + FTileMap.Width * FCellSize, FViewOffset.Y + _i * FCellSize), 1.0);
end;

// Draw Map and PAth Analysis ----------------------------------------------- //

procedure TFormMain.PaintBox_MapPaint(Sender: TObject; Canvas: TCanvas);
begin
  if FLockMapFlag then
  begin
    if FBackgroundBitmap.IsEmpty then
      begin
        if Assigned(Form_Resources) then
          FBackgroundBitmap.Assign(Form_Resources.Image_Logo.Bitmap)
        else
          Exit;
      end;
    var _BgOpacity :=   IfThen(FIsHighlightMode, 0.3, 1.0);
    var _MapWidthPx :=  FTileMap.Width *  FCellSize;
    var _MapHeightPx := FTileMap.Height * FCellSize;
    var _DestRect :=    TRectF.Create(FViewOffset.x, FViewOffset.y, FViewOffset.x + _MapWidthPx, FViewOffset.y + _MapHeightPx);

    AutoCropImage(FBackgroundBitmap);

    Canvas.BeginScene;
    Canvas.DrawBitmap(FBackgroundBitmap, FBackgroundBitmap.BoundsF, _DestRect, _BgOpacity);
    Canvas.EndScene;

    CenterMap;
    FitToScreen;

    Exit;
  end;

  if FTileMap = nil then Exit;

  var _State: TCanvasSaveState := Canvas.SaveState;
  if Canvas.BeginScene then
  try
    Canvas.IntersectClipRect(PaintBox_Map.LocalRect);
    Canvas.Clear(FDefaultBackColor);
    var _BgOpacity :=   IfThen(FIsHighlightMode, 0.3, 1.0);
    var _MapWidthPx :=  FTileMap.Width *  FCellSize;
    var _MapHeightPx := FTileMap.Height * FCellSize;

    if not FBackgroundBitmap.IsEmpty then
    begin
      var _MapRect := TRectF.Create(FViewOffset.x, FViewOffset.y, FViewOffset.x + _MapWidthPx, FViewOffset.y + _MapHeightPx);
      Canvas.DrawBitmap(FBackgroundBitmap, FBackgroundBitmap.BoundsF, _MapRect, _BgOpacity);
    end;

    DrawGrid(Canvas);

    if FIsHighlightMode or CheckBox_Analysis.IsChecked then
      DrawTiles(Canvas);

    if IsPathValid then
      DrawSmoothPath(Canvas, CheckBox_SmoothLine.IsChecked);

    DrawMarker(Canvas, 0, FStartPos);
    DrawMarker(Canvas, 1, FFinishPos);
  finally
    Canvas.EndScene;
  end;

  Canvas.RestoreState(_State);
  UpdateStatusLabel(0);
end;

// -------------------------------------------------------------------------- //

procedure TFormMain.DrawMarker(Canvas: TCanvas; const APosFlag: Integer; const GridPos: TPoint);
begin
  var _SPos := GridToScreenF(GridPos);
  var _MSize := Max(14, FCellSize * 1.3);
  var _R := TRectF.Create(_SPos.X - _MSize/2, _SPos.Y - _MSize/2, _SPos.X + _MSize/2, _SPos.Y + _MSize/2);

  if APosFlag = 0
    then Canvas.DrawBitmap(R_PosIconS, R_PosIconRectF, _R,  1.0, True)
    else Canvas.DrawBitmap(R_PosIconF, R_PosIconRectF, _R,  1.0, True)
end;

procedure TFormMain.DrawMarker(Canvas: TCanvas; const GridPos: TPoint; const Color1, Color2: TAlphaColor; const Symbol: string);
begin
  var _SPos := GridToScreenF(GridPos);
  var _MSize := Max(14, FCellSize * 0.85);
  var _R := TRectF.Create(_SPos.X - _MSize/2, _SPos.Y - _MSize/2, _SPos.X + _MSize/2, _SPos.Y + _MSize/2);

  Canvas.DrawBitmap(R_PosIconS, R_PosIconRectF, _R,  1.0, True);

  Canvas.Fill.Color := Color1;
  Canvas.FillEllipse(_R, 1.0);
  Canvas.Stroke.Color := Color2;
  Canvas.Stroke.Thickness := 3;
  Canvas.DrawEllipse(_R, 1.0);

  { Symbol Text }
  if FCellSize > 10 then
  begin
    Canvas.Fill.Color := Color2;
    Canvas.Font.Size :=  Max(7, _MSize * 0.5);
    Canvas.FillText(_R, Symbol, False, 1.0, [], TTextAlign.Center, TTextAlign.Center);
  end;
end;

{
  Key method for drawing smooth curved paths using TPathData
  1. Create a TPathData instance.
  2. Set the starting point to MoveTo.
  3. It traverses the points of all paths and applies Spline interpolation.
  4. Here, we use simple and effective Quadratic Bezier interpolation.
}

procedure TFormMain.DrawSmoothPath(ACanvas: TCanvas; const ASmoothFlag: Boolean = False);
begin
  if (FCurrentPath.Count < 2) then Exit;

  if ASmoothFlag then
    begin
      var _PathData := TPathData.Create;
      try
        var _P0 := GridToScreenF(FCurrentPath.Points[0]);                       // 1. Set the starting point (centre of the first node)
        var _P1, _P2, _Mid: TPointF;
        _PathData.MoveTo(_P0);
        for var _i := 1 to FCurrentPath.Count - 2 do                            // 2. Path Interpolation Loop
        begin
          _P1 :=  GridToScreenF(FCurrentPath.Points[_i]);
          _P2 :=  GridToScreenF(FCurrentPath.Points[_i + 1]);
          _Mid := TPointF.Create((_P1.X + _P2.X) / 2, (_P1.Y + _P2.Y) / 2);     // Calculate the midpoint of two adjacent points and use them as control points for the curve
          _PathData.QuadCurveTo(_P1, _Mid);                                     // Curve from the current position to the midpoint (P1 becomes the control point)
        end;
        _PathData.LineTo(GridToScreenF(FCurrentPath.Points[FCurrentPath.Count - 1]));                    // 3. Last point connection

        ACanvas.Stroke.Dash :=      TStrokeDash.Solid;
        ACanvas.Stroke.Color :=     IfThen(FIsHighlightMode, TAlphaColors.Cyan, TAlphaColors.Yellow);    // 4. Draw a route to Canvas
        ACanvas.Stroke.Thickness := Max(3, FCellSize / 8);//4);
        ACanvas.Stroke.Cap :=       TStrokeCap.Round;
        ACanvas.Stroke.Join :=      TStrokeJoin.Round;

        ACanvas.DrawPath(_PathData, 1.0);
      finally
        _PathData.Free;
      end;
    end
  else
    begin
      ACanvas.Stroke.Dash :=  TStrokeDash.Solid;
      ACanvas.Stroke.Color := IfThen(FIsHighlightMode, TAlphaColors.Cyan, TAlphaColors.Yellow);
      ACanvas.Stroke.Thickness := Max(2, FCellSize * 0.2);
      ACanvas.Stroke.Cap := TStrokeCap.Round;
      for var _i := 0 to FCurrentPath.Count - 2 do
      begin
        var _P1 := GridToScreenF(FCurrentPath.Points[_i]);
        var _P2 := GridToScreenF(FCurrentPath.Points[_i+1]);
        ACanvas.DrawLine(_P1, _P2, 1.0);
        //ACanvas.DrawLine(_P1 + PointF(FCellSize/2, FCellSize/2), _P2 + PointF(FCellSize/2, FCellSize/2), 1.0);
      end;
    end;
end;


function TFormMain.IsInGrid(GX, GY: Integer): Boolean;
begin
  Result := (GX >= 0) and (GX < FTileMap.Width) and (GY >= 0) and (GY < FTileMap.Height);
end;


{ Mouse Control Setion ... }

procedure TFormMain.PaintBox_MapMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  GX, GY: Integer;
begin
  FLastMousePos := PointF(X, Y);
  ScreenToGridP(FLastMousePos, GX, GY);

  var _Idx := GY * FTileMap.Width + GX;
  FCurrentWeight :=     FWeights[_Idx];
  FCurrentWightFlag := (FTileMap.Data + _Idx)^;

  if Button = TMouseButton.mbLeft then
    begin
      if (GX = FStartPos.X) and (GY = FStartPos.Y) then
        FDragMode := TDragMode.StartPoint else
      if (GX = FFinishPos.X) and (GY = FFinishPos.Y) then
        FDragMode := TDragMode.FinishPoint
      else
        FDragMode := TDragMode.PanMap;
    end else
  if Button = TMouseButton.mbRight then
    begin
      FDragMode := TDragMode.EditWeight;
      var _ws: string := 'Change Weight -> 0';
      if IsInGrid(GX, GY) then
      begin
        if FCurrentWeight > 0 then
          begin
            var _val: Byte := Trunc(TrackBar_CellWeight.Value);
            (FTileMap.Data + _Idx)^ := 0;
            if (ssShift in Shift)
              then FWeights[_Idx] := IIF.CastBool<Byte>(CheckBox_CellWeight.IsChecked, _val, 0)
              else FWeights[_Idx] := 0;
          end
        else
          begin
            (FTileMap.Data + _Idx)^ := 1;
            FWeights[_Idx] := 255;
            _ws := 'Change Weight -> 255';
          end;

        UpdatePath;
        ShowToastAlert( _ws);
      end;
    end;
end;

procedure TFormMain.PaintBox_MapMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  _GX, _GY: Integer;
begin
  var _NewPos := PointF(X, Y);
  ScreenToGridP(_NewPos, _GX, _GY);

  var _Idx := _GY * FTileMap.Width + _GX;
  FCurrentWeight := FWeights[_Idx];
  FCurrentWightFlag := (FTileMap.Data + _Idx)^;
  FCurrGridX := _GX;
  FCurrGridY := _GY;
  UpdateStatusLabel(0);

  case FDragMode of
    TDragMode.StartPoint:
      if IsInGrid(_GX, _GY) then
      begin
        PaintBox_Map.Cursor := TCursor(crHandPoint);
        FStartPos := TPoint.Create(_GX, _GY);
        UpdatePath;
      end;
    TDragMode.FinishPoint:
      if IsInGrid(_GX, _GY) then
      begin
        PaintBox_Map.Cursor := TCursor(crHandPoint);
        FFinishPos := TPoint.Create(_GX, _GY);
        UpdatePath;
      end;
    TDragMode.PanMap:
      begin
        PaintBox_Map.Cursor := TCursor(crDrag);
        FViewOffset := FViewOffset + (_NewPos - FLastMousePos);
        ConstrainViewOffset;                                                    // Apply restrictions on movement
        CheckBox_FitToScreen.IsChecked := False;
      end;
    TDragMode.EditWeight:
      if IsInGrid(_GX, _GY) then
      begin
        if (ssShift in Shift) then begin (FTileMap.Data + _Idx)^ := 1; FWeights[_Idx] := 255; end else
        if (ssAlt in Shift)   then begin (FTileMap.Data + _Idx)^ := 0; FWeights[_Idx] := 0;   end;
        FCurrentWightFlag := (FTileMap.Data + _Idx)^;
        UpdatePath;
      end;
  end;

  FLastMousePos := _NewPos;
  // ------------------------------------------------------------------------ //
  PaintBox_Map.Repaint;
  // ------------------------------------------------------------------------ //
end;

procedure TFormMain.PaintBox_MapMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  PaintBox_Map.Cursor := TCursor(crDefault);
  FDragMode := TDragMode.None;
end;

procedure TFormMain.PaintBox_MapMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
begin
  var _OldCellSize := FCellSize;
  if WheelDelta > 0 then FCellSize := Min(FCellSize * 1.1, 400)
                    else FCellSize := Max(FCellSize * 0.9, 0.5);

  FCellSize := EnsureRange(FCellSize, 1.0, 200.0);
  if _OldCellSize <> FCellSize then
  begin
    FViewOffset.X := FLastMousePos.X - (FLastMousePos.X - FViewOffset.X) * (FCellSize / _OldCellSize);
    FViewOffset.Y := FLastMousePos.Y - (FLastMousePos.Y - FViewOffset.Y) * (FCellSize / _OldCellSize);
    ConstrainViewOffset;                                                        // Restrict it from leaving the screen even when zoomed in
    CheckBox_FitToScreen.IsChecked := False;
    PaintBox_Map.Repaint;
    UpdateStatusLabel(0);
  end;

  Handled := True;
end;

procedure TFormMain.Button_HeighlightMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if FLockMapFlag then Exit;

  FIsHighlightMode := True;
  // ------------------------------------------------------------------------ //
  PaintBox_Map.Repaint;
  // ------------------------------------------------------------------------ //
end;

procedure TFormMain.Button_HeighlightMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if FLockMapFlag then Exit;

  FIsHighlightMode := False;
  PaintBox_Map.Repaint;
end;

procedure TFormMain.UpdateStatusLabel(const AFlag: Integer; const AParams: Boolean = True);
begin
  FZoomRatio := FCellSize / FSetCellSize;
  Label_Zoom.Text    := Format('Zoom: %.0f%%  ', [ZoomRatio*100]);
  Label_ViewPos.Text := Format('Grid : %dx%d | Cell Weight: %d [%d]', [FCurrGridX, FCurrGridY, FCurrentWeight, FCurrentWightFlag]);
  Label_Grids.Text :=  Format('[ Grids ] %d x %d | Map Weight %.2f', [FTileMap.Width, FTileMap.Height, FWeightMultiplier]);
  Label_SInfos.Text := Format('Nodes: %d | Distance: %.1f', [FCurrentPath.Count, FCurrentPath.Distance]);
  if AParams then Label_Performance.Text := Format('Performance: %d ms | Offset: (%.0f, %.0f)', [FPerformanceTick, FViewOffset.X, FViewOffset.Y])
             else Label_Performance.Text := 'No path found';
end;

procedure TFormMain.ComboBox_KindChange(Sender: TObject);
begin
  if FLockMapFlag then Exit;
  InitializeGrid(True);
end;

procedure TFormMain.CheckBox_FitToScreenChange(Sender: TObject);
begin
  if FLockMapFlag then Exit;

  AnalyzeHeightMap;
  UpdatePath;
end;


procedure TFormMain.TrackBar_CellWeightChange(Sender: TObject);
begin
  TrackBar_CellWeight.Hint := 'Cell Weight - '+IntToStr(Trunc(TrackBar_CellWeight.Value));
  CheckBox_CellWeight.Text := 'Cell-W '+IntToStr(Trunc(TrackBar_CellWeight.Value));
end;

procedure TFormMain.TrackBar_TilesizeTracking(Sender: TObject);
begin
  if FLockMapFlag then Exit;
  FSetCellSize := TrackBar_Tilesize.Value;
  InitializeGrid(True);
end;

procedure TFormMain.TrackBar_WeightTracking(Sender: TObject);
begin
  if FLockMapFlag then Exit;

  FWeightMultiplier := TrackBar_Weight.Value / 10;
  Label_WeightScale.Text := Format('Map Weight Scale %.2f', [FWeightMultiplier]);

  AnalyzeHeightMap;
  UpdatePath;
end;

// Extra Method ------------------------------------------------------------- //

procedure TFormMain.SaveScreenshot(const ADialogFlag: Boolean = False);
begin
  var _Snapenflag: Boolean := False;
  var _SaveFile := '';
  if ADialogFlag then
    begin
      var _SaveDialog := TSaveDialog.Create(nil);
      try
        _SaveDialog.Filter := 'PNG Image|*.png';
        _SaveDialog.DefaultExt := 'png';
        _SaveDialog.FileName := Format('Snapshot_%s.png', [FormatDateTime('yyyyMMdd_hhmmss', Now)]);
        _Snapenflag := _SaveDialog.Execute;
        _SaveFile := _SaveDialog.FileName;
      finally
        _SaveDialog.Free;
      end;
    end
  else
    begin
      var _SaveParth := ExtractFilePath(ParamStr(0));
      _SaveFile := Format('Snapshot_%s.png', [FormatDateTime('yyyyMMdd_hhmmss', Now)]);
      _SaveFile := IncludeTrailingPathDelimiter(_SaveParth) + _SaveFile;
      _Snapenflag := True;
    end;

  if _Snapenflag and (_SaveFile > ' ') then
    begin
      TTask.Run(
      procedure
      begin
        var _ScreenShot := PaintBox_Map.MakeScreenshot;
        try
          _ScreenShot.SaveToFile(_SaveFile);
          if FileExists(_SaveFile) then
            TThread.Queue(nil,
              procedure
              begin
                ShowToastAlert('Saved a Snapshot');
              end);
        finally
          _ScreenShot.Free;
        end;
      end);
    end;
end;

var
  Alert_Container: TRectangle;

procedure TFormMain.ShowToastAlert(const AMsg: string);
begin
  // Create a container for the toast at the bottom left
  Alert_Container := TRectangle.Create(Self);
  with Alert_Container do
  begin
    Parent :=      Self;
    Align :=       TAlignLayout.None;
    Fill.Color :=  claBlack;
    Stroke.Kind := TBrushKind.None;
    XRadius :=     8;
    YRadius :=     8;
    Width :=       120;
    Height :=      30;
    Opacity :=     0; // Start invisible for animation

    // Position: Bottom Left with 20px margin
    Position.X := 10;
    Position.Y := Self.ClientHeight - Height - 42;
    Anchors := [TAnchorKind.akLeft, TAnchorKind.akBottom];
  end;

  // Add Label for text
  var _Label := TLabel.Create(Alert_Container);
  with _Label do
  begin
    Parent :=    Alert_Container;
    Align :=     TAlignLayout.Client;
    TextAlign := TTextAlign.Center;
    StyledSettings := [TStyledSetting.Family, TStyledSetting.Size];
    TextSettings.FontColor := TAlphaColorRec.White;
    Text := AMsg;
  end;

  // Animation 1: Fade In
  TAnimator.AnimateFloat(Alert_Container, 'Opacity', 0.5, 0.3);

  // Animation 2: Fade Out after 2 seconds delay
  var _Anim := TFloatAnimation.Create(Alert_Container);
  with  _Anim do
  begin
    Parent :=       Alert_Container;
    PropertyName := 'Opacity';
    StartValue :=   1.0;
    StopValue :=    0.0;
    Duration :=     0.5;
    Delay :=        2.0; // Wait 2 seconds before disappearing
    OnFinish :=     AnimationFinishedEvent;

    Start;
  end;
end;

procedure TFormMain.Action_ScreenshotExecute(Sender: TObject);
begin
  SaveScreenshot();
end;

procedure TFormMain.ActionList1Update(Action: TBasicAction; var Handled: Boolean);
begin
  MultiView_Background.Enabled := not FLockMapFlag;
  Action_Highleght.Enabled :=     not FLockMapFlag;
  Button_Heighlight.Enabled :=    not FLockMapFlag;
  Action_Options.Enabled :=       not FLockMapFlag;
  Action_ResetMap.Enabled :=      not FLockMapFlag;
  StatusBar_Map.Visible :=        not FLockMapFlag;
  TrackBar_CellWeight.Enabled :=  CheckBox_CellWeight.IsChecked;
end;

procedure TFormMain.Action_AnalysisExecute(Sender: TObject);
begin
  CheckBox_Analysis.IsChecked := not CheckBox_Analysis.IsChecked;
  // ------------------------------------------------------------------------ //
  PaintBox_Map.Repaint;
  // ------------------------------------------------------------------------ //
end;

procedure TFormMain.Action_LoadMapExecute(Sender: TObject);
begin
  if OpenDialog_Map.Execute then
  begin
    FLockMapFlag := False;
    FBackgroundBitmap.LoadFromFile(OpenDialog_Map.FileName);
    InitializeGrid(True);
  end;
end;

procedure TFormMain.Action_ResetMapExecute(Sender: TObject);
begin
  InitializeGrid(True);
  Exit;

  { Reserved ... }
  FitToScreen;
  CenterMap;
  AdjustMarkersToViewport;
  UpdatePath;
end;

procedure TFormMain.AnimationFinishedEvent(Sender: TObject);
begin
  if Assigned(Alert_Container) then
    FreeAndNil(Alert_Container);
end;

end.
