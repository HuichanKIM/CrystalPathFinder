unit Unit_Main;

{ **************************************************************************** }
{ Crystal Path Finder - High Performance Version for Delphi 13 Florence        }
{ Optimized with Binary Heap, Minimal Memory Allocation and Parallel Safety    }
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
    PaintBox_Map: TPaintBox;
    Button_Reset: TButton;
    ActionList1: TActionList;
    Action_Screenshot: TAction;
    Action_Analysis: TAction;
    Action_LoadMap: TAction;
    Action_Highleght: TAction;
    Action_Options: TAction;
    Action_ResetMap: TAction;
    ComboBox_Kind: TComboBox;
    CheckBoox_Parallel: TCheckBox;
    CheckBox_Calcurate: TCheckBox;
    CheckBox_CellWeight: TCheckBox;
    CheckBox_SmoothLine: TCheckBox;
    CheckBox_Analysis: TCheckBox;
    TrackBar_Weight: TTrackBar;
    TrackBar_TileSize: TTrackBar;
    TrackBar_CellWeight: TTrackBar;
    Label_Performance: TLabel;
    Label_WeightScale: TLabel;
    Layout_Buttons: TLayout;
    StyleBook1: TStyleBook;
    StatusBar_Map: TStatusBar;
    Label_Simbol: TLabel;
    Label_SInfos: TLabel;
    MultiView_Options: TMultiView;
    MultiView_Background: TRectangle;
    Button_Options: TButton;
    Button_LoadMap: TButton;
    Button_DefaultParams: TButton;
    Button_Heighlight: TButton;
    Label_ViewPos: TLabel;
    OpenDialog_Map: TOpenDialog;
    Label_Grids: TLabel;
    Label_Zoom: TLabel;
    Label_GridCellSize: TLabel;
    Label2: TLabel;
    Label3: TLabel;
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
    procedure TrackBar_WeightTracking(Sender: TObject);
    procedure TrackBar_TileSizeTracking(Sender: TObject);
    procedure TrackBar_CellWeightChange(Sender: TObject);
    procedure Button_HeighlightMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure Button_HeighlightMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure Action_ScreenshotExecute(Sender: TObject);
    procedure Action_AnalysisExecute(Sender: TObject);
    procedure ActionList1Update(Action: TBasicAction; var Handled: Boolean);
    procedure Action_LoadMapExecute(Sender: TObject);
    procedure Action_ResetMapExecute(Sender: TObject);
    procedure Label_TitleClick(Sender: TObject);
    procedure Button_DefaultParamsClick(Sender: TObject);
    procedure TrackBar_TileSizeChange(Sender: TObject);
  private
    FTileMap: TTileMap;
    FCurrentPath: TTileMapPath;
    FBackgroundBitmap: TBitmap;
    FViewOffset: TPointF;
    FCellSize: Single;
    FSetCellSize: Single;
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

    FCurrentWeight: Byte;
    FCurrentWightFlag: Byte;
    FCurrGridX: Integer;
    FCurrGridY: Integer;

    procedure InitializeGrid(const ADefault: Boolean = False);
    procedure UpdatePath(const AUpdateStatus: Boolean = False);

    function ScreenToGridF(AX, AY: Single): TPoint;
    procedure ScreenToGridP(const AScreenPos: TPointF; out AGX, AGY: Integer);
    function GridToScreenF(const AGridPos: TPoint): TPointF;
    procedure GridToScreenP(const AGX, AGY: Integer; out AScreenPos: TPointF);
    function HexCellCenter(const AGX, AGY: Integer): TPointF;
    function HexCellAt(const AScreenPos: TPointF): TPoint;

    procedure AnalyzeHeightMap;
    procedure CenterMap(const AInitFlag: Boolean = False);
    procedure ConstrainViewOffset;
    procedure AutoCropImage(ABitmap: TBitmap);
    procedure CalculateWeightsFromImage(const ADefault: Boolean = False);
    procedure AdjustMarkersToViewport;
    procedure HexMapPixelSize(out AWidth, AHeight: Single);
    procedure DrawTiles(ACanvas: TCanvas);
    procedure DrawTilesEx(ACanvas: TCanvas);
    procedure DrawGrid(ACanvas: TCanvas);
    procedure DrawGridEx(ACanvas: TCanvas);
    procedure DrawMarker(ACanvas: TCanvas; const AGridPos: TPoint; const AColor1, AColor2: TAlphaColor; const ASymbol: string);  overload;
    procedure DrawMarker(ACanvas: TCanvas; const APosFlag: Integer; const AGridPos: TPoint); overload;
    procedure DrawSmoothPath(ACanvas: TCanvas; const ASmoothFlag: Boolean = False);

    function IsInGrid(AGX, AGY: Integer): Boolean;
    function IsPathValid: Boolean;
    function GetWeightColor(const AWeight: Byte): TAlphaColor;
    procedure SetCellWeight(const AGridPos: TPoint; Value: Byte);
    procedure SetZoomRatio(const Value: Single);
    procedure SetSetCellSize(const Value: Single);

    procedure UpdateStatusLabel();
    procedure SaveScreenshot(const ADialogFlag: Boolean = False);
    procedure ShowToastAlert(const AMsg: string);
    procedure AnimationFinishedEvent(Sender: TObject);
    procedure SetupMultiViewPopup;

    procedure LoadIniOptions;
    procedure SaveIniOptions;
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
  System.IniFiles,
  FMX.Ani;


{$R *.fmx}

const
  C_CellSizeDefault = 32.0;
  C_CaptionTitle    = 'Crystal Path Finder - Copyright '+ Char(169)+' 2026 Huicahan Kim';

const
  C_Sqrt3_2 = 0.8660254037844387;                                               // sqrt(3) / 2  — exact to 16 digits


{ TFormMain ------------------------------------------------------------------ }

procedure TFormMain.FormCreate(Sender: TObject);
begin
  Self.Caption :=       C_CaptionTitle;

  FIsHighlightMode :=   False;
  FLockMapFlag :=       True;                                                   // Lock Update PaintBox_Map.RePaint ...
  FWeightMultiplier :=  0.5;
  FCurrentWightFlag :=  0;
  FDefaultBackColor :=  $FF16253D;
  FResizeClearFlag :=   False;

  FStartPos :=          TPoint.Create(10, 10);
  FFinishPos :=         TPoint.Create(110, 110);
  FCellSize :=          C_CellSizeDefault;
  FViewOffset :=        TPointF.Create(100, 100);

  FDragMode :=          TDragMode.None;
  FBackgroundBitmap :=  TBitmap.Create;

  CheckBox_Analysis.IsChecked :=  False;
  CheckBox_Calcurate.IsChecked := True;
  Label_Performance.Visible :=    False;
  CheckBoox_Parallel.IsChecked := True;

  with ComboBox_Kind do
  begin
    OnChange := nil;
    items.Clear;
    Items.Add('Square');
    Items.Add('Diagonal');
    Items.Add('DiagonalEx');
    Items.Add('Hexagonal');
    ItemIndex := 1;
    OnChange  := ComboBox_KindChange;
  end;

  TrackBar_Weight.Value := 5;
  Label_WeightScale.Text := Format('Map Weight Scale %.2f', [TrackBar_Weight.Value / 10]);
  FSetCellSize := C_CellSizeDefault;
  TrackBar_TileSize.Value := C_CellSizeDefault;
  FZoomRatio := 1.0;

  LoadIniOptions();
  SetupMultiViewPopup;

  { Create initial small map to be resized in InitializeGrid }
  FTileMap := TTileMap.Create(10, 10, TTileMapKind.mkDiagonal);
  // ------------------------------------------------------------------------ //
  InitializeGrid(False);
  // ------------------------------------------------------------------------ //
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  SaveIniOptions();
  FCurrentPath.Free;
  FTileMap.Free;
  if Assigned(FBackgroundBitmap) then FBackgroundBitmap.Free;
end;

procedure TFormMain.LoadIniOptions();
begin
  var _IniConfig: TMemIniFile := TMemIniFile.create(ChangeFileExt(ParamStr(0), '.ini'));
  if Assigned(_IniConfig) then
  with _IniConfig do
  try
    CheckBox_Analysis.IsChecked    := ReadBool   ('UIOptions',   'Analysis',     False);
    CheckBox_Calcurate.IsChecked   := ReadBool   ('UIOptions',   'Calcurate',    True);
    CheckBoox_Parallel.IsChecked   := ReadBool   ('UIOptions',   'Parallelfor',  True);
    CheckBox_CellWeight.IsChecked  := ReadBool   ('UIOptions',   'Cellweight',   False);
    CheckBox_SmoothLine.IsChecked  := ReadBool   ('UIOptions',   'Soothline',    False);

    TrackBar_Weight.Value          := ReadFloat  ('MapParams',   'SetWeight',    5.0);
    TrackBar_TileSize.Value        := ReadFloat  ('MapParams',   'Tilesize',     C_CellSizeDefault);
    TrackBar_CellWeight.Value      := ReadFloat  ('MapParams',   'CellWeight',   100.0);

    ComboBox_Kind.ItemIndex        := ReadInteger('MapParams',   'MapKind',      1);
  finally
    Free;
  end;
end;

procedure TFormMain.SaveIniOptions();
begin
  var _IniConfig: TMemIniFile := TMemIniFile.create(ChangeFileExt(ParamStr(0), '.ini'));
  if Assigned(_IniConfig) then
  with _IniConfig do
  try
    WriteBool   ('UIOptions',    'Analysis',      CheckBox_Analysis.IsChecked);
    WriteBool   ('UIOptions',    'Calcurate',     CheckBox_Calcurate.IsChecked);
    WriteBool   ('UIOptions',    'Parallelfor',   CheckBoox_Parallel.IsChecked);
    WriteBool   ('UIOptions',    'Cellweight',    CheckBox_CellWeight.IsChecked);
    WriteBool   ('UIOptions',    'Soothline',     CheckBox_SmoothLine.IsChecked);

    WriteFloat  ('MapParams',    'SetWeight',     TrackBar_Weight.Value);
    WriteFloat  ('MapParams',    'Tilesize',      TrackBar_TileSize.Value);
    WriteFloat  ('MapParams',    'CellWeight',    TrackBar_CellWeight.Value);

    WriteInteger('MapParams',    'MapKind',       ComboBox_Kind.ItemIndex);
  finally
    UpdateFile;
    Free;
  end;
end;

procedure TFormMain.FormResize(Sender: TObject);
begin
  if FLockMapFlag then Exit;

  if FTileMap <> nil then
  begin
    CenterMap;
  end;
  // ------------------------------------------------------------------------ //
  PaintBox_Map.Repaint;
  // ------------------------------------------------------------------------ //
end;

procedure TFormMain.SetupMultiViewPopup;
begin
  with MultiView_Options do
  begin
    Mode := TMultiViewMode.Popover;
    PopoverOptions.PopupHeight := 480;
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
      var _DeltaXY := TPointF.Zero;
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
  end;
end;

procedure TFormMain.SetCellWeight(const AGridPos: TPoint; Value: Byte);
begin
  if (FTileMap <> nil) and (AGridPos.X >= 0) and (AGridPos.X < FTileMap.Width) and
                           (AGridPos.Y >= 0) and (AGridPos.Y < FTileMap.Height) then
  begin
    var _Idx := AGridPos.Y * FTileMap.Width + AGridPos.X;
    FWeights[_Idx] := Value;
  end;
end;

procedure TFormMain.SetSetCellSize(const Value: Single);
begin
  if FSetCellSize <> Value then
  begin
    FSetCellSize := Value;
  end;
end;

function TFormMain.GetWeightColor(const AWeight: Byte): TAlphaColor;
begin
  Result := MakeAlphaColor(TAlphaColors.Greenyellow, 40);
  { Visualize colors according to the brightness concentration
    Red with higher weights and Yellow/Green with lower weights }
  if AWeight > 180 then Result := MakeAlphaColor(TAlphaColors.Red, 130) else
  if AWeight > 120 then Result := MakeAlphaColor(TAlphaColors.Orange, 100) else
  if AWeight > 60  then Result := MakeAlphaColor(TAlphaColors.Yellow, 70);
end;

function TFormMain.IsPathValid: Boolean;
begin
  Result := (FCurrentPath.Count > 0);
end;

procedure TFormMain.ConstrainViewOffset;
begin
  if (FTileMap = nil) then Exit;

  var _MapWidth :=   FTileMap.Width *  FCellSize;
  var _MapHeight :=  FTileMap.Height * FCellSize;
  if FTileMap.Kind = TTileMapKind.mkHexagonal then
  begin
    { Real hex pixel dimensions }
    _MapWidth :=  (FTileMap.Width  - 1) * FCellSize * 0.75 + FCellSize;
    _MapHeight := (FTileMap.Height + 0.5) * FCellSize * C_Sqrt3_2;
  end;

  if _MapWidth <= PaintBox_Map.Width then
    FViewOffset.X := (PaintBox_Map.Width - _MapWidth) / 2                           // If it's smaller than the screen, center
  else
    FViewOffset.X := EnsureRange(FViewOffset.X, PaintBox_Map.Width - _MapWidth, 0); // Larger than the screen, limit the margin

  if _MapHeight <= PaintBox_Map.Height then
    FViewOffset.Y := (PaintBox_Map.Height - _MapHeight) / 2                          // If it's smaller than the screen, center
  else
    FViewOffset.Y := EnsureRange(FViewOffset.Y, PaintBox_Map.Height - _MapHeight, 0);// Larger than the screen, limit the margin
end;

procedure TFormMain.HexMapPixelSize(out AWidth, AHeight: Single);
begin
  if FTileMap.Kind = TTileMapKind.mkHexagonal then
    begin
      AWidth :=  (FTileMap.Width  - 1) *   FCellSize * 0.75 + FCellSize;
      AHeight := (FTileMap.Height + 0.5) * FCellSize * C_Sqrt3_2;
    end
  else
    begin
      AWidth :=  FTileMap.Width  * FCellSize;
      AHeight := FTileMap.Height * FCellSize;
    end;
end;

procedure TFormMain.CenterMap(const AInitFlag: Boolean = False);
begin
  if FTileMap = nil then Exit;

  var _MapWidth: Single :=  0;
  var _MapHeight: Single := 0;
  HexMapPixelSize(_MapWidth, _MapHeight);

  FViewOffset.X := (PaintBox_Map.Width  - _MapWidth) / 2;
  FViewOffset.Y := (PaintBox_Map.Height - _MapHeight) / 2;
  if AInitFlag then
    ConstrainViewOffset;
end;

{ ============================================================================ }
{  Replace AdjustMarkersToViewport                                             }
{                                                                              }
{  Original computed start/finish from the screen corners using ScreenToGridF. }
{  For hex, the corners need hex-aware conversion and the centre calculation   }
{  is the same (it works on grid coordinates, which are now correct).          }
{ ============================================================================ }
procedure TFormMain.AdjustMarkersToViewport;
begin
  if (FTileMap = nil) or (FCellSize <= 0) then Exit;

  var _FirstVisCol: Integer := 0;
  var _LastVisCol:  Integer := 0;
  var _FirstVisRow: Integer := 0;
  var _LastVisRow:  Integer := 0;
  if FTileMap.Kind = TTileMapKind.mkHexagonal then
    begin
      { Find which columns and rows are actually on screen by scanning
        the grid boundaries rather than reverse-projecting screen corners }
      var _ColStep := FCellSize * 0.75;
      var _HexH    := FCellSize * C_Sqrt3_2;

      { Leftmost column whose centre is >= screen left }
      _FirstVisCol := Max(0, Trunc((0 - FViewOffset.X - FCellSize) / _ColStep));

      { Rightmost column whose centre is <= screen right }
      _LastVisCol :=  Min(FTileMap.Width - 1, Trunc((PaintBox_Map.Width - FViewOffset.X) / _ColStep) + 1);

      { Top-most row }
      _FirstVisRow := Max(0, Trunc((0 - FViewOffset.Y - _HexH) / _HexH));

      { Bottom-most row }
      _LastVisRow :=  Min(FTileMap.Height - 1, Trunc((PaintBox_Map.Height - FViewOffset.Y) / _HexH) + 1);

      { Clamp to full grid if calculation yields inverted range }
      if _FirstVisCol > _LastVisCol then
        begin
          _FirstVisCol := 0;
          _LastVisCol := FTileMap.Width - 1;
        end;
      if _FirstVisRow > _LastVisRow then
        begin
          _FirstVisRow := 0;
          _LastVisRow := FTileMap.Height - 1;
        end;
    end
  else
    begin
      { Square grid — original calculation }
      var _GridStart := ScreenToGridF(0, 0);
      var _GridEnd :=   ScreenToGridF(PaintBox_Map.Width, PaintBox_Map.Height);
      _FirstVisCol :=   EnsureRange(_GridStart.X, 0, FTileMap.Width  - 1);
      _FirstVisRow :=   EnsureRange(_GridStart.Y, 0, FTileMap.Height - 1);
      _LastVisCol  :=   EnsureRange(_GridEnd.X, 0,   FTileMap.Width  - 1);
      _LastVisRow  :=   EnsureRange(_GridEnd.Y, 0,   FTileMap.Height - 1);
    end;

  var _MidRow := (_FirstVisRow + _LastVisRow) div 2;
  var _SpanX  := _LastVisCol - _FirstVisCol;

  FStartPos  := Point(Max(_FirstVisCol, _FirstVisCol + _SpanX div 4),     _MidRow);
  FFinishPos := Point(Min(_LastVisCol,  _FirstVisCol + _SpanX * 3 div 4), _MidRow);
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
  if ADefault then _CellSize := TrackBar_TileSize.Value;
  FSetCellSize := _CellSize;

  { Calculate grid dimensions based on current PaintBox size }
  var _TileWidth :=  Max(5, Trunc(PaintBox_Map.Width /  FSetCellSize));
  var _TileHeight := Max(5, Trunc(PaintBox_Map.Height / FSetCellSize));

  if not FLockMapFlag and Assigned(FBackgroundBitmap) then
  begin
    if FTileMap.Kind = TTileMapKind.mkHexagonal then   {Deprecating ... }
      begin
        _TileWidth  := Max(10, Trunc(FBackgroundBitmap.Width  / (FSetCellSize * 0.75)));
        _TileHeight := Max(10, Trunc(FBackgroundBitmap.Height / (FSetCellSize * C_Sqrt3_2)));
      end
    else
      begin
       _TileWidth :=  Max(10, Trunc(FBackgroundBitmap.Width /  FSetCellSize));
       _TileHeight := Max(10, Trunc(FBackgroundBitmap.Height / FSetCellSize));
      end;
  end;


  SetLength(FWeights, _TileWidth * _TileHeight);
  FillChar(FWeights[0], Length(FWeights) * SizeOf(Byte), 0);
  // Create New TileMap  ---------------------------------------------------- //
  var _tilemapkind := TTileMapKind(ComboBox_Kind.ItemIndex);
  if FLockMapFlag then  _tilemapkind := TTileMapKind.mkDiagonal;

  FreeAndNil(FTileMap);
  FTileMap := TTileMap.Create(_TileWidth, _TileHeight, _tilemapkind);
  FillChar(FTileMap.Data^, _TileWidth * _TileHeight, 0);
  // ------------------------------------------------------------------------ //

  MultiView_Background.Enabled := not FLockMapFlag;

  if FLockMapFlag then Exit;

  FCurrentPath.Free;
  FStartPos :=  TPoint.Create(Trunc(_TileWidth * 0.1), Trunc(_TileHeight * 0.5));
  FFinishPos := TPoint.Create(Trunc(_TileWidth * 0.9), Trunc(_TileHeight * 0.5));
  if CheckBox_Calcurate.IsChecked then
    CalculateWeightsFromImage;

  FCellSize := FSetCellSize;
  // ---------------------------------------------------------------------- //
  AnalyzeHeightMap;
  CenterMap;
  AdjustMarkersToViewport;
  UpdatePath(True);
  // ---------------------------------------------------------------------- //

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

  procedure ClassifyPixel(R, G, B: Byte; out AWeight: Byte; out AWall: Boolean); inline;
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
begin
  if FBackgroundBitmap.IsEmpty then Exit;
  if (FTileMap = nil) or (FTileMap.Width = 0) then Exit;

  SetLength(FWeights, FTileMap.Width * FTileMap.Height);
  FillChar(FWeights[0], Length(FWeights) * SizeOf(Byte), 0);

  var _StepX := FBackgroundBitmap.Width  / FTileMap.Width;
  var _StepY := FBackgroundBitmap.Height / FTileMap.Height;

  FWeightMultiplier := TrackBar_Weight.Value / 10.0;
  if FWeightMultiplier <= 0 then FWeightMultiplier := 1.0;

  var _Data: TBitmapData;
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

    { 1-Pass statistics }
    var _TotalSamples  := 0;
    var _SumV: Double  := 0;      // Accumulated brightness (V) across all samples
    var _MeanV: Single := 0;      // Mean brightness of the entire image
    var _SumS: Double  := 0;      // Accumulated saturation (S) across all samples
    var _MeanS: Single := 0;      // Mean saturation of the entire image

    var _Rec: TAlphaColorRec;
    var _H, _S, _V: Single;

    for var _py := 0 to FBackgroundBitmap.Height - 1 do
    begin
      if _py mod 4 <> 0 then Continue;
      for var _px := 0 to FBackgroundBitmap.Width - 1 do
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
    var _WallThresh: Single := EnsureRange(             // Fraction of wall-pixels per cell to trigger wall
      0.55                                              // Base threshold
      - (_MeanV - 0.40) * 0.30                          // Brighter image -> stricter (lower)
      + (_MeanS - 0.15) * 0.25,                         // Higher saturation -> looser (higher)
      0.35, 0.65);

    { ====================================================================== }
    { 2-Pass: Per-cell pixel classification -> weight + wall decision        }
    { ====================================================================== }
    var _Idx: Integer :=         0;
    var _PixW: Byte :=           0;
    var _IsWall: Boolean :=      False;
    { Per-cell accumulators }
    var _WeightSum: Int64 :=     0;
    var _WallVotes: Integer :=   0;
    var _PixelCount: Integer :=  0;
    { Adaptive threshold }
    var _FinalWeight: Integer := 0;
    for var _GridY := 0 to FTileMap.Height - 1 do
      for var _GridX := 0 to FTileMap.Width - 1 do
      begin
        _WeightSum  := 0;
        _WallVotes  := 0;
        _PixelCount := 0;

        for var _py := Max(0, Trunc(_GridY * _StepY))
                to Min(FBackgroundBitmap.Height - 1,
                       Trunc((_GridY + 1) * _StepY) - 1) do
          for var _px := Max(0, Trunc(_GridX * _StepX))
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

function TFormMain.IsInGrid(AGX, AGY: Integer): Boolean;
begin
  Result := (AGX >= 0) and (AGX < FTileMap.Width) and (AGY >= 0) and (AGY < FTileMap.Height);
end;

procedure TFormMain.UpdatePath(const AUpdateStatus: Boolean = False);
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
  if AUpdateStatus then UpdateStatusLabel();
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

{ ============================================================================ }
{  HexCenterF                                                                  }
{  Returns the screen-space centre (TPointF) of grid cell (GX, GY) for         }
{  flat-top hexagons with even-column offset.                                  }
{                                                                              }
{  Parameters:                                                                 }
{    GX, GY      — grid column and row (0-based)                               }
{    ACellSize   — flat-to-flat diameter of one hexagon (= FCellSize)          }
{    AViewOffset — current pan offset (= FViewOffset)                          }
{ ============================================================================ }
function HexCenterF(const GX, GY: Integer;
                    const ACellSize: Single;
                    const AViewOffset: TPointF): TPointF;
begin
  var _HexH     := ACellSize * C_Sqrt3_2;
  var _ColStep  := ACellSize * 0.75;
  var _OddColOffset := IfThen(Odd(GX), _HexH * 0.5, 0);

  Result.X := AViewOffset.X + GX * _ColStep + ACellSize * 0.5;
  Result.Y := AViewOffset.Y + GY * _HexH + _OddColOffset + _HexH * 0.5;
end;

{ ============================================================================ }
{  HexCorners                                                                  }
{  Returns the 6 vertex positions of a flat-top hexagon centred at ACentre.    }
{  Vertices are ordered 0..5 clockwise starting from the rightmost point.      }
{                                                                              }
{  Flat-top vertex angles (degrees): 0, 60, 120, 180, 240, 300                 }
{ ============================================================================ }
procedure HexCorners(const ACentre: TPointF;
                     const ACellSize: Single;
                     out   ACorners: array of TPointF);
begin
  { Circumradius (centre to vertex) of a flat-top hex                   }
  { = CellSize / 2  when CellSize is the flat-to-flat (short) diameter  }
  { = CellSize / sqrt(3)  for point-to-point (long) diameter            }
  { Here CellSize is flat-to-flat, so circumradius = CellSize / sqrt(3) }
  var Radius := ACellSize / 1.7320508;   // 1/sqrt(3)
  var AngleRad: Single := 0;

  for var _i := 0 to 5 do
  begin
    AngleRad     := (Pi / 3.0) * _i;   // 0°, 60°, 120°, 180°, 240°, 300°
    ACorners[_i]  := PointF(ACentre.X + Radius * Cos(AngleRad),
                            ACentre.Y + Radius * Sin(AngleRad));
  end;
end;

{ ============================================================================ }
{  DrawHex                                                                     }
{  Draws one hexagon (stroke only, or fill+stroke) at the given grid cell.     }
{ ============================================================================ }
procedure DrawHex(ACanvas: TCanvas;
                  const ACentre: TPointF;
                  const ACellSize: Single;
                  AFillColor: TAlphaColor;
                  AStrokeColor: TAlphaColor;
                  AStrokeThick: Single;
                  ADoFill: Boolean);
var
  Corners: array[0..5] of TPointF;
begin
  HexCorners(ACentre, ACellSize, Corners);

  var _Path := TPathData.Create;
  try
    _Path.MoveTo(Corners[0]);
    _Path.LineTo(Corners[1]);
    _Path.LineTo(Corners[2]);
    _Path.LineTo(Corners[3]);
    _Path.LineTo(Corners[4]);
    _Path.LineTo(Corners[5]);
    _Path.ClosePath;

    if ADoFill then
    begin
      ACanvas.Fill.Kind  := TBrushKind.Solid;
      ACanvas.Fill.Color := AFillColor;
      ACanvas.FillPath(_Path, 1.0);
    end;

    ACanvas.Stroke.Kind      := TBrushKind.Solid;
    ACanvas.Stroke.Color     := AStrokeColor;
    ACanvas.Stroke.Thickness := AStrokeThick;
    ACanvas.DrawPath(_Path, 1.0);
  finally
    _Path.Free;
  end;
end;

{ Returns the screen-space centre of hex cell (GX, GY). }
{ Flat-top orientation, even-column offset.              }
function TFormMain.HexCellCenter(const AGX, AGY: Integer): TPointF;
begin
  var _HexH    := FCellSize * C_Sqrt3_2;
  var _ColStep := FCellSize * 0.75;
  var _OddOff  := IfThen(Odd(AGX), _HexH * 0.5, 0.0);
  Result.X := FViewOffset.X + AGX * _ColStep + FCellSize * 0.5;
  Result.Y := FViewOffset.Y + AGY * _HexH + _OddOff + _HexH * 0.5;
end;

{ Returns the grid cell (GX,GY) that contains screen point AScreenPos.       }
{ Tests a 3×3 neighbourhood and picks the nearest hex centre.                }
function TFormMain.HexCellAt(const AScreenPos: TPointF): TPoint;
begin
  Result := TPoint.Zero;
  if (FTileMap = nil) or (FCellSize <= 0) then Exit;
  
  var _HexH      := FCellSize * C_Sqrt3_2;
  var _ColStep   := FCellSize * 0.75;

  { Raw estimate — may be negative or beyond grid bounds, that is fine }
  var _ApproxCol := Trunc((AScreenPos.X - FViewOffset.X) / _ColStep);
  var _ApproxRow := Trunc((AScreenPos.Y - FViewOffset.Y) / _HexH);
  { Clamp only to keep the search seed inside a window that lets us test
    neighbours without going absurdly far out of range }
  _ApproxCol := EnsureRange(_ApproxCol, -1, FTileMap.Width);
  _ApproxRow := EnsureRange(_ApproxRow, -1, FTileMap.Height);
      
  var _BestDist  := MaxSingle;
  var _BestCol   := EnsureRange(_ApproxCol, 0, FTileMap.Width  - 1);
  var _BestRow   := EnsureRange(_ApproxRow, 0, FTileMap.Height - 1);

  var _Dist: Single     := 0;
  var _TestCol: Integer := 0;
  var _TestRow: Integer := 0;
  var _Centre := TPointF.Zero;
  { 7×7 neighbourhood guarantees we catch the correct cell even at edges
    and across the odd-column vertical offset boundary }
  for var _DC := -3 to 3 do
    for var _DR := -3 to 3 do
    begin
      _TestCol := _ApproxCol + _DC;
      _TestRow := _ApproxRow + _DR;
      if (_TestCol < 0) or (_TestCol >= FTileMap.Width)  then Continue;
      if (_TestRow < 0) or (_TestRow >= FTileMap.Height) then Continue;
      _Centre := HexCellCenter(_TestCol, _TestRow);
      _Dist   := Sqr(AScreenPos.X - _Centre.X) + Sqr(AScreenPos.Y - _Centre.Y);
      if _Dist < _BestDist then
      begin
        _BestDist := _Dist;
        _BestCol  := _TestCol;
        _BestRow  := _TestRow;
      end;
    end;

  Result := TPoint.Create(_BestCol, _BestRow);
end;

{ ---- ScreenToGridF -------------------------------------------------------- }
{ Original used pure division: Floor((X - OffsetX) / CellSize)                }
{ New: delegates to HexCellAt when in hex mode.                               }
function TFormMain.ScreenToGridF(AX, AY: Single): TPoint;
begin
  if (FTileMap = nil) or (FCellSize <= 0) then Exit(TPoint.Zero);

  if FTileMap.Kind = TTileMapKind.mkHexagonal then
    Result := HexCellAt(PointF(AX, AY))
  else
    Result := TPoint.Create(Floor((AX - FViewOffset.X) / FCellSize),
                            Floor((AY - FViewOffset.Y) / FCellSize));
end;

{ ---- ScreenToGridP -------------------------------------------------------- }
{ Used by MouseDown and MouseMove to get (GX, GY) from raw mouse coords.      }
procedure TFormMain.ScreenToGridP(const AScreenPos: TPointF; out AGX, AGY: Integer);
begin
  if FTileMap.Kind = TTileMapKind.mkHexagonal then
    begin
      var _GP := HexCellAt(AScreenPos);
      AGX := _GP.X;
      AGY := _GP.Y;
    end
  else
    begin
      AGX := Trunc((AScreenPos.X - FViewOffset.X) / FCellSize);
      AGY := Trunc((AScreenPos.Y - FViewOffset.Y) / FCellSize);
    end;
end;


{ ---- GridToScreenF -------------------------------------------------------- }
{ Used by DrawMarker and DrawSmoothPath to convert a grid cell to the         }
{ screen point that should be used as the cell's visual centre.               }
{ For hex: returns the true hex centre (not the top-left corner).             }
{ For square: returns the cell centre (adds half CellSize, matching original) }
function TFormMain.GridToScreenF(const AGridPos: TPoint): TPointF;
begin
  if (FTileMap = nil) or (FCellSize <= 0) then Exit(PointF(0, 0));

  if FTileMap.Kind = TTileMapKind.mkHexagonal then
    Result := HexCellCenter(AGridPos.X, AGridPos.Y)
  else
    Result := PointF(AGridPos.X * FCellSize + FViewOffset.X + FCellSize / 2,
                     AGridPos.Y * FCellSize + FViewOffset.Y + FCellSize / 2);
end;

{ ---- GridToScreenP -------------------------------------------------------- }
{ Used by DrawGrid and other routines that need the top-left corner of a      }
{ cell rather than the centre.                                                }
{ For hex: returns the hex centre (there is no meaningful "top-left corner"). }
{ For square: unchanged — returns the top-left corner of the square cell.     }
procedure TFormMain.GridToScreenP(const AGX, AGY: Integer; out AScreenPos: TPointF);
begin
  if FTileMap.Kind = TTileMapKind.mkHexagonal then
    AScreenPos := HexCellCenter(AGX, AGY)
  else
    begin
      AScreenPos.X := AGX * FCellSize + FViewOffset.X;
      AScreenPos.Y := AGY * FCellSize + FViewOffset.Y;
    end;
end;


procedure TFormMain.DrawTiles(ACanvas: TCanvas);
begin
  // Set Viewport Rectangle
  var _Idx: Integer := 0;
  var _ScreenPos := TPointF.Zero;
  var _ViewRect :=  RectF(0, 0, PaintBox_MAp.Width, PaintBox_Map.Height);
  var _R: TRectF := RectF(0,0,0,0);
  var _DummyRect := RectF(0,0,0,0);
  var _Val: Byte := 0;
  for var _y := 0 to FTileMap.Height - 1 do
    for var _x := 0 to FTileMap.Width - 1 do
    begin
      _Idx := _y * FTileMap.Width + _x;
      _Val := (FTileMap.Data + _Idx)^;

      GridToScreenP(_x, _y, _ScreenPos);
      _R := RectF(_ScreenPos.X, _ScreenPos.Y, _ScreenPos.X + FCellSize, _ScreenPos.Y + FCellSize);

      // Standard intersection check using IntersectRect from System.Types
      if not IntersectRect(_DummyRect, _ViewRect, _R) then Continue;

      if _Val = 1 then
        begin
          ACanvas.Fill.Color := MakeColor(TAlphaColors.Black, 150);
          ACanvas.FillRect(_R, 0, 0, [], 1.0);
        end
      else if FWeights[_Idx] > 50 then //10 then
        begin
          ACanvas.Fill.Color := GetWeightColor(FWeights[_Idx]);
          ACanvas.FillRect(_R, 0, 0, [], 1);
        end;
    end;
end;


{ ============================================================================ }
{  DrawTilesEx                                                                 }
{  Drop-in replacement for DrawTiles.                                          }
{  Renders wall cells and weighted cells in the correct hex or square shape.   }
{ ============================================================================ }
procedure TFormMain.DrawTilesEx(ACanvas: TCanvas);
begin
  if FTileMap = nil then Exit;

  { Square tiles — identical to original DrawTiles }
  if FTileMap.Kind <> TTileMapKind.mkHexagonal then
  begin
    DrawTiles(ACanvas);
    Exit;
  end;

  { --- Hexagonal tiles --- }
  var _ViewRect := RectF(0, 0, PaintBox_Map.Width, PaintBox_Map.Height);
  var _HexH := FCellSize * C_Sqrt3_2;
  var _Idx: Integer := 0;
  var _Val: Byte := 0;
  var _Centre := TPointF.Zero;

  for var _GY := 0 to FTileMap.Height - 1 do
    for var _GX := 0 to FTileMap.Width - 1 do
    begin
      _Idx := _GY * FTileMap.Width + _GX;
      _Val := (FTileMap.Data + _Idx)^;

      _Centre := HexCenterF(_GX, _GY, FCellSize, FViewOffset);

      { Viewport cull }
      if (_Centre.X + FCellSize < _ViewRect.Left)  or
         (_Centre.X - FCellSize > _ViewRect.Right) or
         (_Centre.Y + _HexH      < _ViewRect.Top)   or
         (_Centre.Y - _HexH      > _ViewRect.Bottom) then Continue;

      if _Val = 1 then
        begin
          { Wall cell — solid dark fill }
          DrawHex(ACanvas, _Centre, FCellSize * 0.97,
                  MakeColor(TAlphaColors.Black, 150),
                  MakeColor(TAlphaColors.Black, 80),
                  0.4, True);
        end else
      if FWeights[_Idx] > 50 then
        begin
          { Weighted cell — colour matches GetWeightColor }
          DrawHex(ACanvas, _Centre, FCellSize * 0.97,
                  GetWeightColor(FWeights[_Idx]),
                  MakeColor(TAlphaColors.Black, 30),
                  0.3, True);
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
    ACanvas.DrawLine(PointF(FViewOffset.X + _i * FCellSize, FViewOffset.Y),
                     PointF(FViewOffset.X + _i * FCellSize, FViewOffset.Y + FTileMap.Height * FCellSize), 1.0);

  for var _j := 0 to FTileMap.Height do
    ACanvas.DrawLine(PointF(FViewOffset.X, FViewOffset.Y + _j * FCellSize),
                     PointF(FViewOffset.X + FTileMap.Width * FCellSize, FViewOffset.Y + _j * FCellSize), 1.0);
end;

{ ============================================================================ }
{  DrawGridEx                                                                  }
{  Drop-in replacement for DrawGrid.                                           }
{  Draws the appropriate grid style depending on FTileMap.Kind:                }
{    mkHexagonal → flat-top hex grid                                           }
{    all others  → original square grid (identical to DrawGrid)                }
{ ============================================================================ }
procedure TFormMain.DrawGridEx(ACanvas: TCanvas);
begin
  if FTileMap = nil then Exit;

  { Square grid — unchanged from original }
  if FTileMap.Kind <> TTileMapKind.mkHexagonal then
  begin
    DrawGrid(ACanvas);                                                          // call the existing method as-is
    Exit;
  end;

  { --- Hexagonal grid --- }
  if FCellSize < 6 then Exit;                                                   // too small to draw meaningfully

  var _HexH    := FCellSize * C_Sqrt3_2;
  var _ColStep := FCellSize * 0.75;

  { Visible viewport — skip hexagons entirely outside the screen }
  var _ViewRect := RectF(0, 0, PaintBox_Map.Width, PaintBox_Map.Height);

  { Estimate the first and last visible columns/rows to avoid iterating
    over the whole grid when the user has panned / zoomed. }
  var _FirstCol := Max(0, Trunc((_ViewRect.Left - FViewOffset.X) / _ColStep) - 1);
  var _LastCol  := Min(FTileMap.Width - 1, Trunc((_ViewRect.Right - FViewOffset.X) / _ColStep) + 1);
  var _FirstRow := Max(0, Trunc((_ViewRect.Top - FViewOffset.Y) / _HexH) - 1);
  var _LastRow  := Min(FTileMap.Height - 1, Trunc((_ViewRect.Bottom - FViewOffset.Y) / _HexH) + 2);
  var _Centre   := TPointF.Zero;
  ACanvas.Stroke.Dash := TStrokeDash.Solid;

  for var _GX := _FirstCol to _LastCol do
    for var _GY := _FirstRow to _LastRow do
    begin
      _Centre := HexCenterF(_GX, _GY, FCellSize, FViewOffset);

      { Quick bounding-circle cull: if the _Centre is more than CellSize   }
      { away from the viewport, the hex is certainly not visible.          }
      if (_Centre.X + FCellSize < _ViewRect.Left)  or
         (_Centre.X - FCellSize > _ViewRect.Right) or
         (_Centre.Y + _HexH      < _ViewRect.Top)   or
         (_Centre.Y - _HexH      > _ViewRect.Bottom) then Continue;

      DrawHex(ACanvas, _Centre, FCellSize,
              0,                                      { fill — none here }
              MakeColor(TAlphaColors.Lightgray, 40),  { stroke colour    }
              0.5,                                    { stroke width     }
              False);                                 { stroke only      }
    end;
end;


// Draw Map and PAth Analysis ----------------------------------------------- //

procedure TFormMain.PaintBox_MapPaint(Sender: TObject; Canvas: TCanvas);
begin
  if FTileMap = nil then Exit;

  if FLockMapFlag then
  begin
    if FBackgroundBitmap.IsEmpty then
      begin
        if Assigned(Form_Resources) then
          FBackgroundBitmap.Assign(Form_Resources.Image_Logo.Bitmap)
        else
          Exit;
      end;
    AutoCropImage(FBackgroundBitmap);
    CenterMap(True);
    //GetViewOffset();
    var _BgOpacity :=   IfThen(FIsHighlightMode, 0.3, 1.0);
    var _MapWidthPx :=  FTileMap.Width *  FCellSize;
    var _MapHeightPx := FTileMap.Height * FCellSize;
    var _DestRect :=    TRectF.Create(FViewOffset.x, FViewOffset.y, FViewOffset.x + _MapWidthPx, FViewOffset.y + _MapHeightPx);

    Canvas.DrawBitmap(FBackgroundBitmap, FBackgroundBitmap.BoundsF, _DestRect, _BgOpacity);

    Exit;
  end;

  var _MapWidth: Single :=  0;
  var _MapHeight: Single := 0;
  HexMapPixelSize(_MapWidth, _MapHeight);

  if Canvas.BeginScene then
  try
    var _State: TCanvasSaveState := Canvas.SaveState;
    try
      Canvas.IntersectClipRect(PaintBox_Map.LocalRect);
      Canvas.Clear(FDefaultBackColor);

      var _BgOpacity := IfThen(FIsHighlightMode, 0.3, 1.0);
      if not FBackgroundBitmap.IsEmpty then
      begin
        HexMapPixelSize(_MapWidth, _MapHeight);
        var _MapRect := RectF(FViewOffset.X, FViewOffset.Y, FViewOffset.X + _MapWidth, FViewOffset.Y + _MapHeight);
        Canvas.DrawBitmap(FBackgroundBitmap, FBackgroundBitmap.BoundsF, _MapRect, _BgOpacity);
      end;

      if FIsHighlightMode or CheckBox_Analysis.IsChecked then
        DrawTilesEx(Canvas);

      DrawGridEx(Canvas);

      if IsPathValid then
        DrawSmoothPath(Canvas, CheckBox_SmoothLine.IsChecked);

      DrawMarker(Canvas, 0, FStartPos);
      DrawMarker(Canvas, 1, FFinishPos);
    finally
      Canvas.RestoreState(_State);  
    end;
  finally
    Canvas.EndScene;
  end;

  UpdateStatusLabel();  
end;

// -------------------------------------------------------------------------- //

procedure TFormMain.DrawMarker(ACanvas: TCanvas; const APosFlag: Integer; const AGridPos: TPoint);
begin
  var _SPos :=  GridToScreenF(AGridPos);
  var _MSize := Max(14, FCellSize * 1.3);
  var _R :=     RectF(_SPos.X - _MSize/2, _SPos.Y - _MSize/2, _SPos.X + _MSize/2, _SPos.Y + _MSize/2);

  if APosFlag = 0
    then ACanvas.DrawBitmap(R_PosIconS, R_PosIconRectF, _R,  1.0, True)
    else ACanvas.DrawBitmap(R_PosIconF, R_PosIconRectF, _R,  1.0, True)
end;

procedure TFormMain.DrawMarker(ACanvas: TCanvas; const AGridPos: TPoint; const AColor1, AColor2: TAlphaColor; const ASymbol: string);
begin
  var _SPos :=  GridToScreenF(AGridPos);
  var _MSize := Max(14, FCellSize * 0.85);
  var _Rect :=  RectF(_SPos.X - _MSize/2, _SPos.Y - _MSize/2, _SPos.X + _MSize/2, _SPos.Y + _MSize/2);

  ACanvas.DrawBitmap(R_PosIconS, R_PosIconRectF, _Rect,  1.0, True);

  ACanvas.Fill.Color := AColor1;
  ACanvas.FillEllipse(_Rect, 1.0);
  ACanvas.Stroke.Color := AColor2;
  ACanvas.Stroke.Thickness := 3;
  ACanvas.DrawEllipse(_Rect, 1.0);

  { Symbol Text }
  if FCellSize > 10 then
  begin
    ACanvas.Fill.Color := AColor2;
    ACanvas.Font.Size :=  Max(7, _MSize * 0.5);
    ACanvas.FillText(_Rect, ASymbol, False, 1.0, [], TTextAlign.Center, TTextAlign.Center);
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
          _Mid := PointF((_P1.X + _P2.X) / 2, (_P1.Y + _P2.Y) / 2);     // Calculate the midpoint of two adjacent points and use them as control points for the curve
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
      end;
    end;
end;

{ Mouse Control Setion ... }

procedure TFormMain.PaintBox_MapMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  GX, GY: Integer;
begin
  if FLockMapFlag then Exit;

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

  UpdateStatusLabel();  
end;

procedure TFormMain.PaintBox_MapMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  if FLockMapFlag then Exit;

  var _NewPos := PointF(X, Y);
  var _GX: Integer := 0;
  var _GY: Integer := 0;
  ScreenToGridP(_NewPos, _GX, _GY);

  var _Idx := _GY * FTileMap.Width + _GX;
  FCurrentWeight := FWeights[_Idx];
  FCurrentWightFlag := (FTileMap.Data + _Idx)^;
  FCurrGridX := _GX;
  FCurrGridY := _GY;

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
  UpdateStatusLabel();
end;

procedure TFormMain.PaintBox_MapMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  PaintBox_Map.Cursor := TCursor(crDefault);
  FDragMode := TDragMode.None;
end;

procedure TFormMain.PaintBox_MapMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
begin
  if FLockMapFlag then Exit;

  var _OldCellSize := FCellSize;
  if WheelDelta > 0 then FCellSize := Min(FCellSize * 1.1, 400)
                    else FCellSize := Max(FCellSize * 0.9, 0.5);

  FCellSize := EnsureRange(FCellSize, 1.0, 200.0);
  if _OldCellSize <> FCellSize then
  begin
    FViewOffset.X := FLastMousePos.X - (FLastMousePos.X - FViewOffset.X) * (FCellSize / _OldCellSize);
    FViewOffset.Y := FLastMousePos.Y - (FLastMousePos.Y - FViewOffset.Y) * (FCellSize / _OldCellSize);
    ConstrainViewOffset;                                                        // Restrict it from leaving the screen even when zoomed in
    PaintBox_Map.Repaint;
  end;
  
  UpdateStatusLabel();
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

procedure TFormMain.Button_DefaultParamsClick(Sender: TObject);
begin
  FLockMapFlag := True;

  CheckBox_Analysis.IsChecked    := False;
  CheckBox_Calcurate.IsChecked   := True;
  CheckBoox_Parallel.IsChecked   := True;
  CheckBox_CellWeight.IsChecked  := False;
  CheckBox_SmoothLine.IsChecked  := False;

  TrackBar_Weight.Value          := 5.0;
  TrackBar_TileSize.Value        := C_CellSizeDefault;
  TrackBar_CellWeight.Value      := 100.0;

  ComboBox_Kind.ItemIndex        := 1;

  FLockMapFlag := False;
  InitializeGrid(True);
end;

procedure TFormMain.UpdateStatusLabel();
begin
  FZoomRatio := FCellSize / FSetCellSize;
  Label_Zoom.Text :=        Format('Zoom: %.0f%%  ', [FZoomRatio*100]);
  Label_ViewPos.Text :=     Format('Grid : %dx%d | Cell Size : %d | Cell Weight: %d [%d]', [FCurrGridX, FCurrGridY, Round(FCellSize),  FCurrentWeight, FCurrentWightFlag]);
  Label_Grids.Text :=       Format('[ Grids ] %d x %d | Map Weight %.2f', [FTileMap.Width, FTileMap.Height, FWeightMultiplier]);
  Label_SInfos.Text :=      Format('Nodes: %d | Distance: %.1f', [FCurrentPath.Count, FCurrentPath.Distance]);
  Label_Performance.Text := Format('Performance: %d ms | Offset: (%.0f, %.0f)', [FPerformanceTick, FViewOffset.X, FViewOffset.Y]);
end;

procedure TFormMain.ComboBox_KindChange(Sender: TObject);
begin
  if FLockMapFlag then Exit;
  InitializeGrid(True);
end;

procedure TFormMain.TrackBar_CellWeightChange(Sender: TObject);
begin
  TrackBar_CellWeight.Hint := 'Cell Weight - '+IntToStr(Trunc(TrackBar_CellWeight.Value));
  CheckBox_CellWeight.Text := 'Cell-W '+IntToStr(Trunc(TrackBar_CellWeight.Value));
end;

procedure TFormMain.TrackBar_TileSizeChange(Sender: TObject);
begin
  Label_GridCellSize.Text := 'Grid -Cell size (20 - 64) : '+Trunc(FSetCellSize).ToString;
end;

procedure TFormMain.TrackBar_TileSizeTracking(Sender: TObject);
begin
  if FLockMapFlag then Exit;
  FSetCellSize := TrackBar_TileSize.Value;
  InitializeGrid(True);
end;

procedure TFormMain.TrackBar_WeightTracking(Sender: TObject);
begin
  if FLockMapFlag then Exit;

  FWeightMultiplier := TrackBar_Weight.Value / 10;
  Label_WeightScale.Text := Format('Map Weight Scale %.2f', [FWeightMultiplier]);

  AnalyzeHeightMap;
  UpdatePath(True);
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
  CenterMap;
  AdjustMarkersToViewport;
  UpdatePath(True);
end;

procedure TFormMain.AnimationFinishedEvent(Sender: TObject);
begin
  if Assigned(Alert_Container) then
    FreeAndNil(Alert_Container);
end;

end.
