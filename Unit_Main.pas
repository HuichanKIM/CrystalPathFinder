unit Unit_Main;

{ **************************************************************************** }
{ Crystal Path Finder - High Performance Version for Delphi 13 Florence        }
{ Optimized with Binary Heap, Minimal Memory Allocation and Parallel Safety    }
{ **************************************************************************** }

interface

{$INLINE AUTO}

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
  System.Generics.Collections,
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
  FMX.Memo.Types,
  FMX.ScrollBox,
  FMX.Memo,
  FMX.Effects,
  FMX.Colors,
  //
  uWeightStackManager,
  CrystalPathFinding_ex, FMX.Menus;


type
  THexCube = record
    X, Y, Z: Integer;
  end;

type
  TUndoBackup = record
    FWeights: TBytes;
    FMapData: TBytes;
    IsAvailable: Boolean;
    procedure Capture(const ACurrentWeights: TBytes; const ACurrentMap: PByte; AMapSize: Integer);
    procedure Restore(var ATargetWeights: TBytes; const ATargetMap: PByte);
  end;

type
  TInputCloseEvent = reference to procedure(const AResult: string; AConfirmed: Boolean);

type
  { Enum to manage mouse interaction states including custom weight painting }
  TDragMode = (None, StartPoint, FinishPoint, PanMap, EditWeight);
  TMapCategory = (mcDefault=0, mcMegacity, mcCity, mcCountry, mcMountains, mcOthers);

  TFormMain = class(TForm)
    PaintBox_Map: TPaintBox;
    StyleBook1: TStyleBook;
    LayoutRoot: TLayout;
    LayoutHeader: TLayout;
    Layout_Buttons: TLayout;
    Layout_Filters: TLayout;
    ActionList1: TActionList;
    Action_Screenshot: TAction;
    Action_Analysis: TAction;
    Action_LoadMap: TAction;
    Action_Highleght: TAction;
    Action_Options: TAction;
    Action_ResetMap: TAction;
    Action_FIlterBuilds: TAction;
    Action_CustomColor: TAction;
    Action_ShowGrids: TAction;
    Action_Help: TAction;
    Action_ScreenCap: TAction;
    Action_CenterMap: TAction;
    Action_SmoothLine: TAction;
    Action_CustomWeight: TAction;
    ComboBox_Kind: TComboBox;
    CheckBox_AddTerrain: TCheckBox;
    CheckBox_WeightCell: TCheckBox;
    CheckBox_SmoothLine: TCheckBox;
    CheckBox_Weights: TCheckBox;
    CheckBox_ShowGrid: TCheckBox;
    CheckBox_HeatMap: TCheckBox;
    CheckBox_CustomColor: TCheckBox;
    CheckBox_FilterBD: TCheckBox;
    TrackBar_Weight: TTrackBar;
    TrackBar_TileSize: TTrackBar;
    TrackBar_CellWeight: TTrackBar;
    TrackBar_WallFactor: TTrackBar;
    Label_Title: TLabel;
    Label_Performance: TLabel;
    Label_WeightScale: TLabel;
    Label_Simbol: TLabel;
    Label_SInfos: TLabel;
    Label_ViewPos: TLabel;
    Label_Grids: TLabel;
    Label_Zoom: TLabel;
    Label_PathTileSize: TLabel;
    Label_WallOffset: TLabel;
    StatusBar_Map: TStatusBar;
    MultiView_Options: TMultiView;
    Rectangle_Options: TRectangle;
    OpenDialog_Map: TOpenDialog;
    Button_Options: TButton;
    Button_LoadMap: TButton;
    Button_DefaultParams: TButton;
    Button_Heighlight: TButton;
    Button_Shortkeys: TButton;
    Button_Reset: TButton;
    Rectangle_Yellow: TRectangle;
    Rectangle_White: TRectangle;
    Rectangle_Blue: TRectangle;
    Rectangle_Red: TRectangle;
    Rectangle_PathColors: TRectangle;
    Rectangle_CustomColor1: TRectangle;
    Rectangle_Custom: TRectangle;
    Rectangle_CustomWeight2: TRectangle;
    Rectangle_Green: TRectangle;
    Rectangle_GridCOlor: TRectangle;
    RadioButton_Filter0: TRadioButton;
    RadioButton_Filter1: TRadioButton;
    Path_Compass: TPath;
    ColorComboBox_Grid: TColorComboBox;
    ShadowEffect1: TShadowEffect;
    Layout_CuatomWeight2: TLayout;
    Label2: TLabel;
    Label1: TLabel;
    Line1: TLine;
    Line2: TLine;
    Text_CustomWeight2: TText;
    Text2: TText;
    Line3: TLine;
    Rectangle_CustomWeight: TRectangle;
    ListBox_CustomWeights: TListBox;
    Button_DeleteWeight: TButton;
    Layout_cwButtons: TLayout;
    ComboBox_CustomWeight: TComboBox;
    Label3: TLabel;
    Button_Close: TButton;
    Button_AllWeights: TButton;
    Button_ApplyWeights: TButton;
    Label4: TLabel;
    Layout_Combo: TLayout;
    Button_ChangeName: TButton;
    Layout_WeightGroup: TLayout;
    Button__CustomWeights: TButton;
    Layout_CustomWeight: TLayout;
    Layout_InputQuery: TLayout;
    Rectangle1: TRectangle;
    Label5: TLabel;
    Label6: TLabel;
    { Stack of Weights Manager }
    Edit_InputName: TEdit;
    Button_IQ_OK: TButton;
    Button_IQ_Cancel: TButton;
    Layout_Category: TLayout;
    ComboBox_Category: TComboBox;
    Button_Category: TButton;
    PopupMenu_Custom: TPopupMenu;
    pm_ChangeName: TMenuItem;
    pm_ApplyToMap: TMenuItem;
    pm_Delete: TMenuItem;
    pm_ApplyToAll: TMenuItem;
    pm_SaveToFile: TMenuItem;
    pm_LoadFromFile: TMenuItem;
    Action_CustomApplayToMap: TAction;
    Action_CustomDelete: TAction;
    Action_CustonRename: TAction;
    Action_CustomApplyToAll: TAction;
    Action_CustomRefreshCat: TAction;
    SaveDialog_Custom: TSaveDialog;
    OpenDialog_Custom: TOpenDialog;
    MenuItem1: TMenuItem;
    Layout_CustomCat: TLayout;
    Layout_CustomValues: TLayout;
    Label7: TLabel;
    Rectangle_CustomValue: TRectangle;
    Text_CustomValue: TText;
    Label_TargetValues: TLabel;
    MenuItem2: TMenuItem;
    pm_Refresh: TMenuItem;
    Action_RestoreWeights: TAction;
    Button1: TButton;
    Label_CustomChanged: TLabel;
    Layout1: TLayout;
    TrackBar_CustomOffset: TTrackBar;
    Label_CustomOffset: TLabel;
    Label_CustomOffsetVal: TLabel;
    ShadowEffect2: TShadowEffect;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
    procedure Action_ScreenshotExecute(Sender: TObject);
    procedure Action_AnalysisExecute(Sender: TObject);
    procedure ActionList1Update(Action: TBasicAction; var Handled: Boolean);
    procedure Action_LoadMapExecute(Sender: TObject);
    procedure Action_ResetMapExecute(Sender: TObject);
    procedure Action_ShowGridsExecute(Sender: TObject);
    procedure Action_HelpExecute(Sender: TObject);
    procedure Action_CenterMapExecute(Sender: TObject);
    procedure Action_FIlterBuildsExecute(Sender: TObject);
    procedure Action_CustomColorExecute(Sender: TObject);
    procedure Action_ScreenCapExecute(Sender: TObject);
    procedure Action_OptionsExecute(Sender: TObject);
    procedure Action_SmoothLineExecute(Sender: TObject);
    procedure Action_CustomWeightExecute(Sender: TObject);
    procedure PaintBox_MapMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure PaintBox_MapMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure PaintBox_MapPaint(Sender: TObject; Canvas: TCanvas);
    procedure PaintBox_MapMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure PaintBox_MapMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
    procedure TrackBar_WeightTracking(Sender: TObject);
    procedure TrackBar_TileSizeTracking(Sender: TObject);
    procedure TrackBar_CellWeightChange(Sender: TObject);
    procedure TrackBar_TileSizeChange(Sender: TObject);
    procedure TrackBar_WallFactorChange(Sender: TObject);
    procedure ComboBox_KindChange(Sender: TObject);
    procedure ColorComboBox_GridChange(Sender: TObject);
    procedure CheckBox_WeightsChange(Sender: TObject);
    procedure CheckBox_FilterBDChange(Sender: TObject);
    procedure CheckBox_CustomColorChange(Sender: TObject);
    procedure Button_HeighlightMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure Button_HeighlightMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure Button_ShortkeysClick(Sender: TObject);
    procedure Button_DefaultParamsClick(Sender: TObject);
    procedure Label_TitleClick(Sender: TObject);
    procedure Rectangle_YellowClick(Sender: TObject);
    procedure RadioButton_Filter0Change(Sender: TObject);
    { Stack of Weights Manager }
    procedure MultiView_OptionsShown(Sender: TObject);
    procedure ComboBox_CustomWeightChange(Sender: TObject);
    procedure Button_CloseClick(Sender: TObject);
    procedure MultiView_WeightsShown(Sender: TObject);
    procedure Button_IQ_CancelClick(Sender: TObject);
    procedure Button_IQ_OKClick(Sender: TObject);
    procedure ComboBox_CategoryChange(Sender: TObject);
    procedure pm_ApplyToMapClick(Sender: TObject);
    procedure pm_ChangeNameClick(Sender: TObject);
    procedure pm_DeleteClick(Sender: TObject);
    procedure pm_ApplyToAllClick(Sender: TObject);
    procedure pm_SaveToFileClick(Sender: TObject);
    procedure pm_LoadFromFileClick(Sender: TObject);
    procedure Action_CustomApplayToMapExecute(Sender: TObject);
    procedure Action_CustomDeleteExecute(Sender: TObject);
    procedure Action_CustonRenameExecute(Sender: TObject);
    procedure Action_CustomApplyToAllExecute(Sender: TObject);
    procedure Action_CustomRefreshCatExecute(Sender: TObject);
    procedure pm_RefreshClick(Sender: TObject);
    procedure Action_RestoreWeightsExecute(Sender: TObject);
    procedure TrackBar_CustomOffsetChange(Sender: TObject);
  private
    FPathFinder: TTileMap;
    FMapWeights: TArray<Byte>;
    FCurrentPath: TTileMapPath;
    FBackupPath: TTileMapPath;
    FBackgroundBitmap: TBitmap;
    FTileMapkind: TTileMapKind;
    FMapCategory: TMapCategory;

    FViewOffset: TPointF;
    FCellSize: Single;
    FSetCellSize: Single;
    FStartPos: TPoint;
    FFinishPos: TPoint;

    FLockMapFlag: Boolean;
    FLockUpdate: Boolean;
    FWallDefineVal: Integer;
    FWeightMultiplier: Single;
    FDragMode: TDragMode;
    FLastMousePos: TPointF;
    FIsHighlightMode: Boolean;
    FBackup: TUndoBackup;
    FDefaultBackColor: TAlphaColor;
    FPathColor: TAlphaColor;
    FDefaultMap: TImage;
    FZoomRatio: Single;
    FIsDrawingWall: Boolean;
    FPathPending: Boolean;
    FPathDirty:   Boolean;

    FResizeClearFlag: Boolean;
    FPerformanceTick: Cardinal;
    FGridStrokeThick: Single;
    FCurrentWeight: Byte;
    FCurrentWightFlag: Byte;
    FCurrGridX: Integer;
    FCurrGridY: Integer;
    FFilterIndex: Integer;
    FCustomColor: TAlphaColor;
    FCustomColorFlag: Boolean;

    FFirstTileFlag: Boolean;
    FunnyFlag: Integer;
    { Stack of Weights Manager }
    FWeightStackManager: TWeightStackManager;
    FStackFileName: string;
    FQuery_Container: TLayout;
    FQuery_Mode: Integer;
    FCustomOffSet: Integer;

    procedure LoadIniOptions;
    procedure SaveIniOptions;

    procedure InitializeDrawPath(const ADefault: Boolean = False);
    procedure UpdatePath(const AUpdateStatus: Boolean = False);

    function ScreenToGridF(const AX, AY: Single): TPoint;
    procedure ScreenToGridP(const AScreenPos: TPointF; out AGX, AGY: Integer);
    function GridToScreenF(const AGridPos: TPoint): TPointF;
    procedure GridToScreenP(const AGX, AGY: Integer; out AScreenPos: TPointF);
    function HexCellCenter(const AGX, AGY: Integer): TPointF;
    function HexCellAt(const AScreenPos: TPointF): TPoint;
    procedure AnalyzeHeightMap(const AClassifyFlag: Integer = 0);
    procedure CenterMap(const AInitFlag: Boolean = False);
    procedure ConstrainViewOffset;
    procedure AutoCropImage(ABitmap: TBitmap);
    procedure CalculateWeightsFromImage(const ADefault: Boolean = False);
    procedure AdjustMarkersToViewport;
    procedure HexMapPixelSize(out AWidth, AHeight: Single);

    procedure DrawLogo(const ACanvas: TCanvas);
    procedure DrawTiles(ACanvas: TCanvas);
    procedure DrawTilesEx(ACanvas: TCanvas);
    procedure DrawGrid(ACanvas: TCanvas);
    procedure DrawGridEx(ACanvas: TCanvas);
    procedure DrawMarker(ACanvas: TCanvas; const AGridPos: TPoint; const AColor1, AColor2: TAlphaColor; const ASymbol: string);  overload;
    procedure DrawMarker(ACanvas: TCanvas; const APosFlag: Integer; const AGridPos: TPoint); overload;
    procedure DrawSmoothPath(ACanvas: TCanvas; const ASmoothFlag: Boolean = False);
    procedure DrawHeatmap(Canvas: TCanvas);

    procedure ApplyTerrainCustomization(const AFlag: Integer; const AStackName: string; const AWeight: Byte; const AValue: Integer = 0);
    procedure RefineWallGrid;
    procedure RefineWallGrid_hex;
    function IsHexLinePassable(const AP1, AP2: TPoint): Boolean;
    procedure OptimizeRoute(ATileMapPath:TTileMapPath);
    function GetHexLine(AHex, BHex: THexCube): TList<THexCube>;
    function CubeRound(fX, fY, fZ: Double): THexCube;
    function IsInGrid(AGX, AGY: Integer): Boolean;
    function IsPathValid: Boolean;

    procedure SetCellWeight(const AGridPos: TPoint; Value: Byte);
    procedure SetZoomRatio(const Value: Single);
    procedure SetSetCellSize(const Value: Single);
    procedure UpdateStatusLabel();
    procedure SaveScreenshot(const ADialogFlag: Boolean = False);
    procedure AnimationFinishedEvent(Sender: TObject);

    procedure SetupMultiViewOptionsPopup;
    procedure SetupMultiViewWeightsPopup;

    procedure SetPathColorControl(const AFlag: Integer; const ARepaint: Boolean = True);
    procedure ApplyTerrainTraining(const AGX, AGY: Integer);
    procedure SetCustomColorFlag(const Value: Boolean);
    procedure SetCustomColor(const Value: TAlphaColor);
    procedure ShowToastAlert(const AMsg: string);
    procedure SetWallDefineVal(const Value: Integer);
    procedure BackupCurrentPath;
    { Stack of Weights Manager }
    procedure RefreshStackManager(const AFlag: Integer = 0; const AName: string = '');
    procedure HideCustomWeight(const AFlag: Integer);
    procedure SetMapCategory(const Value: TMapCategory);
  public
    property MapCategory: TMapCategory  read FMapCategory       write SetMapCategory;
    property WallDefineVal: Integer     read FWallDefineVal     write SetWallDefineVal;
    property ZoomRatio: Single          read FZoomRatio         write SetZoomRatio;
    property SetCellSize: Single        read FSetCellSize       write SetSetCellSize;
    property CustomColor: TAlphaColor   read FCustomColor       write SetCustomColor;
    property CustomColorFlag: Boolean   read FCustomColorFlag   write SetCustomColorFlag;
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
  System.SyncObjs,
  FMX.Platform,
  FMX.DialogService,
  FMX.Ani,
  FMX.Utils;


{$R *.fmx}

const
  C_CaptionTitle = 'Crystal Path Finder - Copyright '+ Char(169)+' 2026 Huicahan Kim';

const
  C_CellSizeDefault = 32.0;
  C_ColStep         = 0.75;
  C_HALF            = 0.5;
  C_SQRT3_2_MAX     = 0.86602540378443864676;                                   // sqrt(3) / 2  — exact to 16 digits
  C_SQRT2_MAX       = 1.41421356237309504880;
  C_INV_SQRT3       = 0.57735026918962576451;                                   // 1 / Sqrt(3)
  C_PathColors: array [0..4] of TAlphaColor = (
                  TAlphaColorRec.Yellow, TAlphaColorRec.White,TAlphaColorRec.Blue,
                  TAlphaColorRec.Red,TAlphaColorRec.Green);

  C_Category: array [TMapCategory] of string = ('Default', 'MegaCity', 'City','Country','Mountains','Others');
  C_CatJson:  array [TMapCategory] of string = ('cpf_stack.json', 'MegaCity.json', 'City.json','Country.json','Mountains.json','Others.json');

var
  V_GWeightColorTable1: array [0..255] of TAlphaColor;
  V_GWeightColorTable2: array [0..255] of TAlphaColor;

const
  C_HEX_OFFSETS: array [0..1, 0..5, 0..1] of ShortInt = (
    ((0,-1), (0,1), (-1,0), (1,0), (-1,-1), (1,-1)),   // Even Column
    ((0,-1), (0,1), (-1,0), (1,0), (-1,1),  (1,1))     // Odd Column
  );

procedure InitWeightColorTable1;
begin
  for var _i := 0 to 255 do
  begin
    if _i > 180 then V_GWeightColorTable1[_i] := MakeAlphaColor(TAlphaColors.Red,          130) else
    if _i > 120 then V_GWeightColorTable1[_i] := MakeAlphaColor(TAlphaColors.Orange,       100) else
    if _i > 60  then V_GWeightColorTable1[_i] := MakeAlphaColor(TAlphaColors.Yellow,       70)
                else V_GWeightColorTable1[_i] := MakeAlphaColor(TAlphaColors.Greenyellow,  40);
  end;

  { Blue (0) -> Green (85) -> Yellow (170) -> Red (255) Heatmap Color}
  for var _j := 0 to 255 do
  begin
    if _j < 128
      then V_GWeightColorTable2[_j] := System.UIConsts.MakeColor(0, _j * 2, 255 - (_j * 2), 120)
      else V_GWeightColorTable2[_j] := System.UIConsts.MakeColor((_j - 128) * 2, 255 - ((_j - 128) * 2), 0, 120);
  end;
end;

{ TUndoBackup - FWeights, FPathFinder }

{ Copy() - When to copy the entire dynamic array safely and use it independently,
           Can use Copy() without a factor.}
procedure TUndoBackup.Capture(const ACurrentWeights: TBytes; const ACurrentMap: PByte; AMapSize: Integer);
begin
  FWeights := Copy(ACurrentWeights);
  SetLength(FMapData, AMapSize);
  if AMapSize > 0 then Move(ACurrentMap^, FMapData[0], AMapSize);

  IsAvailable := True;
end;

procedure TUndoBackup.Restore(var ATargetWeights: TBytes; const ATargetMap: PByte);
begin
  if not IsAvailable then Exit;

  ATargetWeights := Copy(FWeights);
  if Length(FMapData) > 0 then Move(FMapData[0], ATargetMap^, Length(FMapData));
  IsAvailable := False;
end;


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
  FFinishPos :=         TPoint.Create(180, 180);
  FCellSize :=          C_CellSizeDefault;
  FViewOffset :=        TPointF.Create(100, 100);

  FDragMode :=          TDragMode.None;
  FBackgroundBitmap :=  TBitmap.Create;

  FFirstTileFlag :=                 True;
  FunnyFlag :=                      0;
  CheckBox_Weights.IsChecked :=     False;
  CheckBox_AddTerrain.IsChecked :=  True;
  Label_Performance.Visible :=      False;
  CheckBox_ShowGrid.IsChecked :=    True;
  Text_CustomWeight2.Visible :=     False;
  Path_Compass.Visible :=           False;
  Button_LoadMap.Default :=         True;

  Layout_WeightGroup.Visible :=     False;
  Layout_CustomWeight.Visible :=    False;
  Layout_InputQuery.Visible :=      False;

  FPathColor := TAlphaColors.Yellow;

  with ComboBox_Kind do
  begin
    OnChange := nil;
    items.Clear;
    Items.Add('Square');
    Items.Add('Diagonal');
    Items.Add('DiagonalEx');
    Items.Add('Hexagonal');
    ItemIndex := 3;                                                             {  = Default Map Kind = Hexagonal }
    OnChange  := ComboBox_KindChange;
  end;

  with ComboBox_Category do
  begin
    OnChange := nil;
    items.Clear;
    for var _c := Low(C_Category) to High(C_Category) do
      Items.Add(C_Category[_c]);
    ItemIndex := 0;                                                             {  = Default Map Kind = Hexagonal }
    OnChange  := ComboBox_CategoryChange;
  end;

  FTileMapkind := TTileMapKind(3);

  FCustomOffSet := 10;
  FQuery_Mode := 0;
  TrackBar_Weight.Value := 50;
  Label_WeightScale.Text := Format('📍 Default Weight Scale %.2f', [TrackBar_Weight.Value / 100]);
  Label_PathTileSize.Text := '🏁 MAP Tile Size (Default) : '+Trunc(C_CellSizeDefault).ToString;
  FSetCellSize := C_CellSizeDefault;
  TrackBar_TileSize.Value := C_CellSizeDefault;
  FZoomRatio := 1.0;
  FGridStrokeThick := 0.8;
  FFilterIndex := 0;
  FWallDefineVal := 3;

  FMapCategory := TMapCategory.mcDefault;
  // ------------------------------------------------------------------------ //
  LoadIniOptions();
  // ------------------------------------------------------------------------ //
  ComboBox_Category.ItemIndex := Ord(FMapCategory);
  FStackFileName := ExtractFilePath(ParamStr(0))+C_CatJson[FMapCategory];
  FWeightStackManager := TWeightStackManager.Create(C_Category[FMapCategory], FStackFileName);
  TrackBar_CustomOffset.Value := FCustomOffSet;

  SetupMultiViewOptionsPopup;
  SetupMultiViewWeightsPopup;
  InitWeightColorTable1;

  { Create initial small map to be resized in InitializeGrid }
  // ------------------------------------------------------------------------ //
  FPathFinder := TTileMap.Create(10, 10, TTileMapKind.mkDiagonal);
  InitializeDrawPath(False);
  // ------------------------------------------------------------------------ //
end;

procedure TFormMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  PaintBox_Map.OnPaint := nil;
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  SaveIniOptions();
  FWeightStackManager.Free;
  FCurrentPath.Release;
  FBackupPath.Release;
  FPathFinder.Free;
  FBackgroundBitmap.Free;
end;

procedure TFormMain.LoadIniOptions();
begin
  var _IniConfig: TMemIniFile := TMemIniFile.create(ChangeFileExt(ParamStr(0), '.ini'));
  var _ColorStr1: string := AlphaColorToString(TAlphaColors.Yellow);            // = 'Yellow'
  var _ColorStr2: string := AlphaColorToString(TAlphaColors.Lightgray);         // = 'LightGray'

  if Assigned(_IniConfig) then
  with _IniConfig do
  try
    FFirstTileFlag                 := ReadBool   ('Management',  'FirstTime',       True);
    FunnyFlag                      := ReadInteger('Management',  'Funnyflag',       0);
    CheckBox_Weights.IsChecked     := ReadBool   ('UIOptions',   'Analysis',        False);
    CheckBox_AddTerrain.IsChecked  := ReadBool   ('UIOptions',   'Calcurate',       True);
    CheckBox_WeightCell.IsChecked  := ReadBool   ('UIOptions',   'Cellweight',      False);
    CheckBox_SmoothLine.IsChecked  := ReadBool   ('UIOptions',   'Soothline',       False);
    CheckBox_ShowGrid.IsChecked    := ReadBool   ('UIOptions',   'ShowGrid',        True);
                  _ColorStr2       := ReadString ('UIOptions',   'PathColor',       _ColorStr1);
    FPathColor                     := StringToAlphaColor(_ColorStr2);
                  _ColorStr2       := ReadString ('UIOptions',   'GridColor',       _ColorStr2);
    ColorComboBox_Grid.Color       := StringToAlphaColor(_ColorStr2);
    FGridStrokeThick               := ReadFloat  ('UIOptions',   'GridStrokeWidth', 0.8);
                  var _catindex    := ReadInteger('MapParams',   'MapCategory',     0);
    FMapCategory := TMapCategory(_catindex);
    TrackBar_Weight.Value          := ReadFloat  ('MapParams',   'SetWeight',       50.0);
    TrackBar_CustomOffset.Value    := ReadInteger('MapParams',   'CustomOffset',    10);      // Update -> FCustomOffSet
    TrackBar_TileSize.Value        := ReadFloat  ('MapParams',   'Tilesize',        C_CellSizeDefault);
    TrackBar_CellWeight.Value      := ReadFloat  ('MapParams',   'CellWeight',      255);
    FWallDefineVal                 := ReadInteger('MapParams',   'WallDefine',      3);
    TrackBar_WallFactor.Value      := FWallDefineVal;
    ComboBox_Kind.ItemIndex        := ReadInteger('MapParams',   'MapKind',         3);
  finally
    Free;
  end;
end;

procedure TFormMain.SaveIniOptions();
begin
  var _IniConfig: TMemIniFile := TMemIniFile.create(ChangeFileExt(ParamStr(0), '.ini'));
  var _ColorStr1: string := AlphaColorToString(FPathColor);
  var _ColorStr2: string := AlphaColorToString(ColorComboBox_Grid.Color);
  FunnyFlag := (FunnyFlag + 1) mod 2;
  if Assigned(_IniConfig) then
  with _IniConfig do
  try
    WriteBool   ('Management',   'FirstTime',       FFirstTileFlag);
    WriteInteger('Management',   'Funnyflag',       FunnyFlag);
    WriteBool   ('UIOptions',    'Analysis',        CheckBox_Weights.IsChecked);
    WriteBool   ('UIOptions',    'Calcurate',       CheckBox_AddTerrain.IsChecked);
    WriteBool   ('UIOptions',    'Cellweight',      CheckBox_WeightCell.IsChecked);
    WriteBool   ('UIOptions',    'Soothline',       CheckBox_SmoothLine.IsChecked);
    WriteBool   ('UIOptions',    'ShowGrid',        CheckBox_ShowGrid.IsChecked);
    WriteString ('UIOptions',    'PathColor',       _ColorStr1);
    WriteString ('UIOptions',    'GridColor',       _ColorStr2);
    WriteFloat  ('UIOptions',    'GridStrokeWidth', FGridStrokeThick);
    WriteInteger('MapParams',    'MapCategory',     Ord(FMapCategory));
    WriteFloat  ('MapParams',    'SetWeight',       TrackBar_Weight.Value);
    WriteInteger('MapParams',    'CustomOffset',    FCustomOffSet);
    WriteFloat  ('MapParams',    'Tilesize',        TrackBar_TileSize.Value);
    WriteFloat  ('MapParams',    'CellWeight',      TrackBar_CellWeight.Value);
    WriteInteger('MapParams',    'WallDefine',      FWallDefineVal);
    WriteInteger('MapParams',    'MapKind',         ComboBox_Kind.ItemIndex);
  finally
    UpdateFile;
    Free;
  end;
end;

procedure TFormMain.FormResize(Sender: TObject);
begin
  if FLockMapFlag then Exit;

  if FPathFinder <> nil then CenterMap;
  // ------------------------------------------------------------------------ //
  PaintBox_Map.Repaint;
  // ------------------------------------------------------------------------ //
end;

procedure TFormMain.SetupMultiViewOptionsPopup;
begin
  with MultiView_Options do
  begin
    Mode := TMultiViewMode.Popover;
    PopoverOptions.PopupHeight := 620;
    MasterButton := Button_Options;
    TargetControl := nil;
    Opacity := 0.8;
    Width := 225;
  end;

  with Rectangle_Options do
  begin
    Stroke.Kind := TBrushKind.Solid;
    XRadius := 10;
    YRadius := 10;

    Enabled := True;
  end;
end;

procedure TFormMain.SetupMultiViewWeightsPopup;
begin
end;

procedure TFormMain.SetWallDefineVal(const Value: Integer);
begin
  if FWallDefineVal <> Value then
  begin
    FWallDefineVal := Value;
  end;
end;

procedure TFormMain.MultiView_OptionsShown(Sender: TObject);
begin
  HideCustomWeight(0);
  CheckBox_CustomColor.OnChange :=  nil;
  CheckBox_CustomColor.IsChecked := CustomColorFlag;
  CheckBox_CustomColor.OnChange :=  CheckBox_CustomColorChange;
end;

procedure TFormMain.MultiView_WeightsShown(Sender: TObject);
begin
  RefreshStackManager(0);
end;

procedure TFormMain.SetZoomRatio(const Value: Single);
begin
  if FZoomRatio <> Value then
  begin
    FZoomRatio := Value;
    //
  end;
end;

procedure TFormMain.Label_TitleClick(Sender: TObject);
begin
  if FLockMapFlag then Exit;
  Label_Performance.Visible := not Label_Performance.Visible;
end;

procedure TFormMain.FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  if FLockMapFlag then Exit;

  if (Key = vkEscape) then
  begin
    if Layout_InputQuery.Visible then
      begin
        Layout_InputQuery.Visible := False;   Key := 0; Exit;
      end;
    if MultiView_Options.IsShowed then
      begin
        MultiView_Options.HideMaster;         Key := 0; Exit;
      end;
    if Layout_CustomWeight.Visible then
      begin
        Layout_CustomWeight.Visible := False; Key := 0; Exit;
      end;
    if FBackup.IsAvailable then
    begin
      FBackup.Restore(FMapWeights, FPathFinder.Data);

      ShowToastAlert('Restored to Backup');
      UpdatePath(True);
      Key := 0; Exit;
    end;
  end;

  if not Layout_CustomWeight.Visible then                                       // for prepare Edit mode of CustomWeights ...
  begin
    if KeyChar = 'a' then Action_AnalysisExecute(Self) else
    if KeyChar = 'b' then Action_CenterMapExecute(Self) else
    if KeyChar = 'f' then Action_FIlterBuildsExecute(Self) else
    if KeyChar = 'g' then Action_ShowGridsExecute(Self) else
    if KeyChar = 'h' then Action_HelpExecute(Self) else
    if KeyChar = 'm' then Action_LoadMapExecute(Self) else
    if KeyChar = 'o' then Action_OptionsExecute(Self) else
    if KeyChar = 'q' then Action_SmoothLineExecute(Self) else
    if KeyChar = 'r' then Action_ResetMapExecute(Self) else
    if KeyChar = 's' then Action_ScreenshotExecute(Self) else
    if KeyChar = 'w' then Action_CustomWeightExecute(Self) else
    if KeyChar = ' ' then Action_CustomColorExecute(Self);
  end;

  var _effectflag: Boolean := False;
  if ssCtrl in Shift then
    begin
      if CheckBox_Weights.IsChecked then
        begin
          var _newvalue := TrackBar_Weight.Value;
          case Key of
            vkUp:    begin _newvalue := EnsureRange(_newvalue + 10, 1, 100); TrackBar_Weight.Value := _newvalue; _effectflag := True; end;
            vkDown:  begin _newvalue := EnsureRange(_newvalue - 10, 1, 100); TrackBar_Weight.Value := _newvalue; _effectflag := True; end;
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
      const _MoveStep = 20.0;                                                   // Arrow key movement sensitivity (pixels)
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
    // ---------------------------------------------------------------------- //
    PaintBox_Map.Repaint;
    // ---------------------------------------------------------------------- //
  end;
end;

procedure TFormMain.SetCellWeight(const AGridPos: TPoint; Value: Byte);
begin
  if (FPathFinder <> nil) and (AGridPos.X >= 0) and (AGridPos.X < FPathFinder.Columns) and
                              (AGridPos.Y >= 0) and (AGridPos.Y < FPathFinder.Rows) then
  begin
    var _Idx := AGridPos.Y * FPathFinder.Columns + AGridPos.X;
    FMapWeights[_Idx] := Value;
    PaintBox_Map.Repaint;
  end;
end;

procedure TFormMain.SetCustomColor(const Value: TAlphaColor);
begin
  FCustomColor := Value;
  Rectangle_CustomColor1.Fill.Color := Value;
end;

procedure TFormMain.SetCustomColorFlag(const Value: Boolean);
begin
  FCustomColorFlag := Value;
  Text_CustomWeight2.Visible := Value;
  MultiView_Options.HideMaster;
end;

procedure TFormMain.SetSetCellSize(const Value: Single);
begin
  if FSetCellSize <> Value then
  begin
    FSetCellSize := Value;
    PaintBox_Map.Repaint;
  end;
end;

procedure TFormMain.CheckBox_WeightsChange(Sender: TObject);
begin
  if FLockUpdate then Exit;
  PaintBox_Map.Repaint;
end;

procedure TFormMain.CheckBox_CustomColorChange(Sender: TObject);
begin
  if FLockUpdate then Exit;
  CustomColorFlag := CheckBox_CustomColor.IsChecked;
end;

procedure TFormMain.CheckBox_FilterBDChange(Sender: TObject);
begin
  if FLockUpdate then Exit;
  AnalyzeHeightMap(FFilterIndex);
  UpdatePath();
end;

{ Draw Map Methods ----------------------------------------------------------- }

procedure TFormMain.CenterMap(const AInitFlag: Boolean = False);
begin
  if FPathFinder = nil then Exit;

  var _MapWidth, _MapHeight: Single;
  HexMapPixelSize(_MapWidth, _MapHeight);

  if (_MapWidth <= 0) or (_MapHeight <= 0) then Exit;

  if not FLockMapFlag then
  begin
    var ScaleX := PaintBox_Map.Width / _MapWidth;
    var ScaleY := PaintBox_Map.Height / _MapHeight;
    var _FillScale := Max(ScaleX, ScaleY);
    FCellSize := FCellSize * _FillScale;
    HexMapPixelSize(_MapWidth, _MapHeight);
  end;

  FViewOffset.X := (PaintBox_Map.Width  - _MapWidth) /  2;
  FViewOffset.Y := (PaintBox_Map.Height - _MapHeight) / 2;

  ConstrainViewOffset;
end;

procedure TFormMain.HexMapPixelSize(out AWidth, AHeight: Single);
begin
  if FPathFinder.Kind = TTileMapKind.mkHexagonal then
    begin
      var _Width: Double  := (Double(FPathFinder.Columns) - 1) * Double(FCellSize) * C_ColStep + Double(FCellSize);
      var _Height: Double := (Double(FPathFinder.Rows) + 0.5)  * Double(FCellSize) * C_SQRT3_2_MAX;

      AWidth  := Single(_Width);
      AHeight := Single(_Height);
    end
  else
    begin
      AWidth  := FPathFinder.Columns * FCellSize;
      AHeight := FPathFinder.Rows *    FCellSize;
    end;
end;

procedure TFormMain.ConstrainViewOffset;
begin
  if (FPathFinder = nil) then Exit;

  var _MapWidth :=   FPathFinder.Columns * FCellSize;
  var _MapHeight :=  FPathFinder.Rows *    FCellSize;
  if FPathFinder.Kind = TTileMapKind.mkHexagonal then
  begin
    _MapWidth :=  (FPathFinder.Columns  - 1) * FCellSize * C_ColStep + FCellSize;
    _MapHeight := (FPathFinder.Rows + 0.5) *   FCellSize * C_SQRT3_2_MAX;
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

procedure TFormMain.AdjustMarkersToViewport;
begin
  if (FPathFinder = nil) or (FCellSize <= 0) then Exit;

  var _FirstVisCol: Integer := 0;
  var _LastVisCol:  Integer := 0;
  var _FirstVisRow: Integer := 0;
  var _LastVisRow:  Integer := 0;
  if FPathFinder.Kind = TTileMapKind.mkHexagonal then
    begin
      { Find which columns and rows are actually on screen by scanning
        the grid boundaries rather than reverse-projecting screen corners }
      var _ColStep := FCellSize * C_ColStep;
      var _HexH    := FCellSize * C_SQRT3_2_MAX;

      { Leftmost column whose centre is >= screen left }
      _FirstVisCol := Max(0, Trunc((0 - FViewOffset.X - FCellSize) / _ColStep));
      { Rightmost column whose centre is <= screen right }
      _LastVisCol :=  Min(FPathFinder.Columns - 1, Trunc((PaintBox_Map.Width - FViewOffset.X) / _ColStep) + 1);
      { Top-most row }
      _FirstVisRow := Max(0, Trunc((0 - FViewOffset.Y - _HexH) / _HexH));
      { Bottom-most row }
      _LastVisRow :=  Min(FPathFinder.Rows - 1, Trunc((PaintBox_Map.Height - FViewOffset.Y) / _HexH) + 1);
      { Clamp to full grid if calculation yields inverted range }
      if _FirstVisCol > _LastVisCol then
        begin
          _FirstVisCol := 0;
          _LastVisCol := FPathFinder.Columns - 1;
        end;
      if _FirstVisRow > _LastVisRow then
        begin
          _FirstVisRow := 0;
          _LastVisRow := FPathFinder.Rows - 1;
        end;
    end
  else
    begin
      { Square grid — original calculation }
      var _GridStart := ScreenToGridF(0, 0);
      var _GridEnd :=   ScreenToGridF(PaintBox_Map.Width, PaintBox_Map.Height);
      _FirstVisCol :=   EnsureRange(_GridStart.X, 0, FPathFinder.Columns  - 1);
      _FirstVisRow :=   EnsureRange(_GridStart.Y, 0, FPathFinder.Rows - 1);
      _LastVisCol  :=   EnsureRange(_GridEnd.X, 0,   FPathFinder.Columns  - 1);
      _LastVisRow  :=   EnsureRange(_GridEnd.Y, 0,   FPathFinder.Rows - 1);
    end;

  var _MidRow := (_FirstVisRow + _LastVisRow) div 2;
  var _SpanX  :=  _LastVisCol -  _FirstVisCol;

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
  var _Pixel: TAlphaColorRec;
  var _Data: TBitmapData;
  var _Scan: PAlphaColorRecArray;
  if ABitmap.Map(TMapAccess.Read, _Data) then
  try
    var _H, _S, _L: Single;
    for var _y := 0 to ABitmap.Height - 1 do
    begin
      _Scan := _Data.GetScanline(_y);
      for var _x := 0 to ABitmap.Width - 1 do
      begin
        _Pixel := _Scan^[_x];
        System.UIConsts.RGBtoHSL(TAlphaColor(_Pixel), _H, _S, _L);
        if (_L < 0.98) and (_L > 0.02) and (_S > 0.01) then
        begin
          if _x < _MinX then _MinX := _x;
          if _x > _MaxX then _MaxX := _x;
          if _y < _MinY then _MinY := _y;
          if _y > _MaxY then _MaxY := _y;

          _IsFound := True;
        end;
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

procedure TFormMain.InitializeDrawPath(const ADefault: Boolean = False);
begin
  var _CellSize := FSetCellSize;
  if ADefault then _CellSize := TrackBar_TileSize.Value;
  FSetCellSize := _CellSize;

  { Calculate grid dimensions based on current PaintBox size }
  var _TileWidth :=  Max(5, Trunc(PaintBox_Map.Width /  FSetCellSize));
  var _TileHeight := Max(5, Trunc(PaintBox_Map.Height / FSetCellSize));

  if not FLockMapFlag and Assigned(FBackgroundBitmap) then
  begin
    if FPathFinder.Kind = TTileMapKind.mkHexagonal then
      begin
        _TileWidth  := Max(10, Trunc(FBackgroundBitmap.Width  / (FSetCellSize * C_ColStep)));
        _TileHeight := Max(10, Trunc(FBackgroundBitmap.Height / (FSetCellSize * C_SQRT3_2_MAX)));
      end
    else
      begin
        _TileWidth  := Max(10, Trunc(FBackgroundBitmap.Width  / FSetCellSize));
        _TileHeight := Max(10, Trunc(FBackgroundBitmap.Height / FSetCellSize));
      end;
  end;

  SetLength(FMapWeights, _TileWidth * _TileHeight);
  FillChar(FMapWeights[0], Length(FMapWeights) * SizeOf(Byte), 0);

  { Create New TileMap ---------------------------------------------------- }
  FTileMapkind := TTileMapKind(ComboBox_Kind.ItemIndex);
  if FLockMapFlag then FTileMapkind := TTileMapKind.mkDiagonal;

  CheckBox_HeatMap.OnChange := nil;
  if FTileMapkind = TTileMapKind.mkHexagonal then
    CheckBox_HeatMap.IsChecked := False;
  CheckBox_HeatMap.OnChange := CheckBox_WeightsChange;

  { Important: Free previous instances first ------------------------------ }
  FreeAndNil(FPathFinder);
  FPathFinder := TTileMap.Create(_TileWidth, _TileHeight, FTileMapkind);
  // --------------------------------------------------------------------- //
  Rectangle_Options.Enabled := not FLockMapFlag;
  Rectangle_CustomWeight.Enabled := not FLockMapFlag;

  if FLockMapFlag then Exit;

  { Set default start and finish positions }
  FStartPos  := TPoint.Create(Trunc(_TileWidth * 0.1), Trunc(_TileHeight * 0.5));
  FFinishPos := TPoint.Create(Trunc(_TileWidth * 0.9), Trunc(_TileHeight * 0.5));

  if CheckBox_AddTerrain.IsChecked then
    CalculateWeightsFromImage;

  FCellSize := FSetCellSize;

  { Analyze terrain and update path }
  AnalyzeHeightMap(FFilterIndex);
  CenterMap;
  AdjustMarkersToViewport;
  UpdatePath(True);
end;

  { ---- Classify a Single Pixel into a Terrain Type ------------------------- }

  procedure ClassifyPixel(R, G, B: Byte; out AWeight: Byte; out AWall: Boolean); inline;
  var
    _H, _S, _V: Single;
  begin
    RGBToHSV(R, G, B, _H, _S, _V);

    { 1. Deep shadow / tunnel / no-data -> wall                                }
    {    _V < 0.10 is nearly black; building shadows in Google Maps fall here  }
    {    However, if _S is slightly elevated it could be dense vegetation,     }
    {    so _S is also checked before marking as wall                          }
    if (_V < 0.10) and (_S < 0.20) then
    begin
      AWall := True; AWeight := 255; Exit;
    end;

    { 2. Water body (river, lake, reservoir) -> wall                           }
    {    Blue hue range with noticeable saturation                             }
    if (_H >= 170) and (_H <= 245) and (_S > 0.22) and (_V > 0.12) then
    begin
      AWall := True; AWeight := 255; Exit;
    end;

    { 3. Road / paved surface -> Weight 0~15 (strongly preferred by pathfinder)}
    {    Achromatic (low _S) + mid-range _V -> asphalt / concrete              }
    {    _V range extended to 0.20~0.80 to include shaded road sections        }
    if (_S < 0.16) and (_V >= 0.20) and (_V <= 0.80) then
    begin
      AWall := False;
      { Slight cost gradient by road brightness: bright road = 0, dark = 15  }
      AWeight := Trunc(Max(0.0, (0.45 - _V)) * 30.0);
      Exit;
    end;

    { 4. Bright building rooftop / parking lot -> Weight 25                    }
    {    Low _S and high _V: concrete surfaces, flat rooftops                  }
    if (_S < 0.22) and (_V > C_ColStep) then
    begin
      AWall := False; AWeight := 25; Exit;
    end;

    { 5. Vegetation / forest / park -> Weight 50~180 (passable, high cost)     }
    {    [KEY FIX] KEY FIX: vegetation is no longer classified as a wall       }
    {    _H 75~165 (yellow-green to cyan-green), _S > 0.15                     }
    {    Even with low _V (dense canopy shade) it is treated as vegetation,    }
    {    which resolves the misclassification present in the original code     }
    if (_H >= 75) and (_H <= 165) and (_S > 0.15) then
    begin
      AWall := False;
      { Higher _S (denser forest) and lower _V (deeper shade) raise the cost   }
      AWeight := EnsureRange(Trunc(50 + _S * 100 + (0.6 - _V) * 60), 50, 180);
      Exit;
    end;

    { 6. Bare soil / unpaved path / farmland -> Weight 30~100                  }
    {    Earthy / ochre hue range                                              }
    if (_H >= 18) and (_H <= 58) and (_S > 0.14) and (_V > 0.22) then
    begin
      AWall := False;
      AWeight := EnsureRange(Trunc(30 + (1.0 - _V) * 70), 30, 100);
      Exit;
    end;

    { 7. Building facade / general urban area (fallback)                       }
    AWall   := False;
    AWeight := EnsureRange(Trunc((1.0 - _V) * 80 + _S * 50), 0, 200);
  end;

  procedure ClassifyPixel_Buildings0(R, G, B: Byte; out AWeight: Byte; out AWall: Boolean); inline;
  var
    _H, _S, _V: Single;
  begin
    RGBToHSV(R, G, B, _H, _S, _V);

    if (_V < 0.10) and (_S < 0.20) then
    begin
      AWall := True;   AWeight := 255; Exit;
    end;

    if (_H >= 170) and (_H <= 245) and (_S > 0.22) and (_V > 0.12) then
    begin
      AWall := True;   AWeight := 255; Exit;
    end;

    if ( (_H <= 25) or (_H >= 345) ) and (_S > 0.20) and (_V > 0.35) then
    begin
      AWall := False;  AWeight := Trunc(Max(0.0, (0.45 - _V)) * 30.0); Exit;
    end;

    // Building ...
    if (_S < 0.20) and (_V > 0.65) then
    begin
      AWall := True;   AWeight := 255; Exit;
    end;

    if (_H >= 75) and (_H <= 165) and (_S > 0.15) then
    begin
      AWall := False;  AWeight := EnsureRange(Trunc(80 + _S * 100 + (0.6 - _V) * 60), 50, 200); Exit;
    end;

    if (_H >= 18) and (_H <= 58) and (_S > 0.14) and (_V > 0.22) then
    begin
      AWall := False;  AWeight := EnsureRange(Trunc(30 + (1.0 - _V) * 70), 30, 100); Exit;
    end;

    AWall   := False;
    AWeight := EnsureRange(Trunc((1.0 - _V) * 80 + _S * 50), 0, 200);
  end;

  procedure ClassifyPixel_Buildings1(R, G, B: Byte; out AWeight: Byte; out AWall: Boolean); inline;
  var
    _H, _S, _V: Single;
  begin
    RGBToHSV(R, G, B, _H, _S, _V);

    { 1. Very Dark Area (Shadow, etc.) -> Wall }
    if (_V < 0.10) and (_S < 0.20) then
    begin
      AWall := True;  AWeight := 255; Exit;
    end;

    { 2. Water (blue) -> Wall }
    if (_H >= 170) and (_H <= 245) and (_S > 0.22) and (_V > 0.12) then
    begin
      AWall := True;  AWeight := 255; Exit;
    end;

    { 3. [Amendment] Red roof/building decision }
    { Red is usually a roof in the city center,
      so it is modified to be a wall (True) rather than a false }
    if ( (_H <= 25) or (_H >= 345) ) and (_S > 0.15) and (_V > 0.30) then
    begin
      { If you have to use a certain red line as a path,
        you have to set the saturation very high, but
        Red roofs on common satellite maps are safe to see through walls. }
      AWall := True;  AWeight := 255; Exit;
    end;

    { 4. Bright achromatic (Grey/White Roof) -> Wall }
    if (_S < 0.20) and (_V > 0.60) then                                         // Slightly lower the _V threshold from 0.65 to 0.60
    begin
      AWall := True;  AWeight := 255; Exit;
    end;

    { 5. Green (full, wood) -> Passable }
    if (_H >= 75) and (_H <= 165) and (_S > 0.15) then
    begin
      AWall := False; AWeight := EnsureRange(Trunc(80 + _S * 100 + (0.6 - _V) * 60), 50, 200); Exit;
    end;

    { 6. Soil, mud -> Passable }
    if (_H >= 18) and (_H <= 58) and (_S > 0.14) and (_V > 0.22) then
    begin
      AWall := False; AWeight := EnsureRange(Trunc(30 + (1.0 - _V) * 70), 30, 100); Exit;
    end;

    { 7. Default value (general ground such as road) }
    AWall   := False;
    AWeight := EnsureRange(Trunc((1.0 - _V) * 80 + _S * 50), 0, 200);
  end;

procedure TFormMain.AnalyzeHeightMap(const AClassifyFlag: Integer);
type
  TClassifyProc = procedure(R, G, B: Byte; out AWeight: Byte; out AWall: Boolean);
begin
  if FBackgroundBitmap.IsEmpty or (FPathFinder = nil) then Exit;

  SetLength(FMapWeights, FPathFinder.Columns * FPathFinder.Rows);
  FillChar(FMapWeights[0], Length(FMapWeights) * SizeOf(Byte), 0);

  var _StepX := FBackgroundBitmap.Width /  FPathFinder.Columns;
  var _StepY := FBackgroundBitmap.Height / FPathFinder.Rows;

  FWeightMultiplier := TrackBar_Weight.Value / 100.0;
  if FWeightMultiplier <= 0 then FWeightMultiplier := 1.0;

  var _ClassifyProc: TClassifyProc;
  if CheckBox_FilterBD.IsChecked then
    begin
      if AClassifyFlag = 0
        then _ClassifyProc := ClassifyPixel_Buildings0
        else _ClassifyProc := ClassifyPixel_Buildings1;
    end
  else
    _ClassifyProc := ClassifyPixel;

  var _Data: TBitmapData;
  if not FBackgroundBitmap.Map(TMapAccess.Read, _Data) then Exit;
  try
    { 1-Pass statistics }
    var _TotalSamples  := 0;
    var _SumV: Double  := 0;                                                    // Accumulated brightness (V) across all samples
    var _SumS: Double  := 0;                                                    // Accumulated saturation (S) across all samples
    var _Rec: TAlphaColorRec;
    var _H, _S, _V: Single;
    var _Scan: PAlphaColorRecArray;
    for var _py := 0 to FBackgroundBitmap.Height - 1 do
    begin
      if _py mod 4 <> 0 then Continue;
      _Scan := _Data.GetScanline(_py);
      for var _px := 0 to FBackgroundBitmap.Width - 1 do
      begin
        if _px mod 4 <> 0 then Continue;
        _Rec := _Scan^[_px];
        RGBToHSV(_Rec.R, _Rec.G, _Rec.B, _H, _S, _V);
        _SumV := _SumV + _V;
        _SumS := _SumS + _S;
        Inc(_TotalSamples);
      end;
    end;

    var _MeanV: Single := IfThen(_TotalSamples > 0, _SumV / _TotalSamples, 0.45);
    var _MeanS: Single := IfThen(_TotalSamples > 0, _SumS / _TotalSamples, 0.20);

    { Adaptive Wall Threshold }
    var _WallThresh: Single := EnsureRange(0.55 - (_MeanV - 0.40) * 0.30 + (_MeanS - 0.15) * 0.25, 0.35, 0.65);
    var _mapPtr: PByte := FPathFinder.Data;
    var _wgtPtr: PByte := @FMapWeights[0];

    TParallel.For(0, FPathFinder.Rows - 1, procedure(Row: Integer)
    var
      _WeightSum : array of Int64;
      _WallVotes : array of Integer;
      _PixelCount: array of Integer;
      _PixW: Byte; _IsWall: Boolean;
      _RecColor: TAlphaColorRec;
      _Scan: PAlphaColorRecArray;
      _Idx, _FinalWeight: Integer;
    begin
      SetLength(_WeightSum,  FPathFinder.Columns);
      SetLength(_WallVotes,  FPathFinder.Columns);
      SetLength(_PixelCount, FPathFinder.Columns);

      for var _py := Max(0, Trunc(Row * _StepY)) to
            Min(FBackgroundBitmap.Height - 1, Trunc((Row + 1) * _StepY) - 1) do
      begin
        _Scan := _Data.GetScanline(_py);
        for var _Col := 0 to FPathFinder.Columns - 1 do
          for var _px := Max(0, Trunc(_Col * _StepX)) to
                Min(FBackgroundBitmap.Width - 1, Trunc((_Col + 1) * _StepX) - 1) do
          begin
            _RecColor := _Scan^[_px];
            _ClassifyProc(_RecColor.R, _RecColor.G, _RecColor.B, _PixW, _IsWall);;

            if _IsWall then Inc(_WallVotes[_Col]);
            _WeightSum[_Col]  := _WeightSum[_Col] + _PixW;
            Inc(_PixelCount[_Col]);
          end;
      end;

      for var _Col := 0 to FPathFinder.Columns - 1 do
      begin
        if _PixelCount[_Col] = 0 then Continue;
        _Idx := Row * FPathFinder.Columns + _Col;

        if (_WallVotes[_Col] / _PixelCount[_Col]) >= _WallThresh then
          begin
            (_mapPtr + _Idx)^ := 1;
            (_wgtPtr + _Idx)^ := 255;
          end
        else
          begin
            _FinalWeight := Trunc((_WeightSum[_Col] / _PixelCount[_Col]) * FWeightMultiplier);
            (_mapPtr + _Idx)^ := 0;
            (_wgtPtr + _Idx)^ := EnsureRange(_FinalWeight, 0, 254);
          end;
      end;
    end);
  finally
    FBackgroundBitmap.Unmap(_Data);
  end;

  if CheckBox_FilterBD.IsChecked then
    RefineWallGrid;
end;

{ The state of not touching anyone to FPathFinder.Data, FMapWeights !!! }

procedure TFormMain.ApplyTerrainTraining(const AGX, AGY: Integer);
begin
  if FBackgroundBitmap.IsEmpty or (FPathFinder = nil) then Exit;

  var _Data: TBitmapData;
  if not FBackgroundBitmap.Map(TMapAccess.Read, _Data) then Exit;
  try
    const _TolH = 15.0;
    const _TolS = 0.20;
    const _TolV = 0.25;

    var _StepX: Double := Double(FBackgroundBitmap.Width) /  FPathFinder.Columns;
    var _StepY: Double := Double(FBackgroundBitmap.Height) / FPathFinder.Rows;
    var _RefPX := Trunc(AGX * _StepX);
    var _RefPY := Trunc(AGY * _StepY);
    var _ColorRec := PAlphaColorRecArray(_Data.GetScanline(_RefPY))^[_RefPX];

    var _TargetH, _TargetS, _TargetV: Single;
    RGBToHSV(_ColorRec.R, _ColorRec.G, _ColorRec.B, _TargetH, _TargetS, _TargetV);

    var _mapPtr: PByte := FPathFinder.Data;
    var _wgtPtr: PByte := @FMapWeights[0];

    TParallel.For(0, FPathFinder.Rows - 1, procedure(Row: Integer)
    var
      _H, _S, _V: Single;
      _Scan: PAlphaColorRecArray;
      _Idx: Integer;
      _DiffH: Single;
      _px: Integer;
      _PX_Start, _PX_End: Integer;
    begin
      var _PY_Start := Trunc(Row * _StepY);
      var _PY_End   := Trunc((Row + 1) * _StepY) - 1;

      for var _py := Max(0, _PY_Start) to Min(FBackgroundBitmap.Height - 1, _PY_End) do
      begin
        _Scan := _Data.GetScanline(_py);

        for var _Col := 0 to FPathFinder.Columns - 1 do
        begin
          _PX_Start := Trunc(_Col * _StepX);
          _PX_End   := Trunc((_Col + 1) * _StepX) - 1;

          _px := (_PX_Start + _PX_End) div 2;
          var _RecColor := _Scan^[_px];

          RGBToHSV(_RecColor.R, _RecColor.G, _RecColor.B, _H, _S, _V);

          _DiffH := Abs(_H - _TargetH);
          if _DiffH > 180 then _DiffH := 360 - _DiffH;

          _Idx := Row * FPathFinder.Columns + _Col;

          if (_DiffH < _TolH) and (Abs(_S - _TargetS) < _TolS) and (Abs(_V - _TargetV) < _TolV) then
            begin
              (_mapPtr + _Idx)^ := 0;   // Buildings
              (_wgtPtr + _Idx)^ := 0;
            end
          else
            begin
              (_mapPtr + _Idx)^ := 1;   // Wall
              (_wgtPtr + _Idx)^ := 255;
            end;
        end;
      end;
    end);
  finally
    FBackgroundBitmap.Unmap(_Data);
  end;

  RefineWallGrid;
  UpdatePath(True);
end;

procedure TFormMain.RefineWallGrid;
begin
  if FPathFinder.Kind = TTileMapKind.mkHexagonal then
  begin
    RefineWallGrid_hex;
    Exit;
  end;

  var _mapRows := FPathFInder.Rows;
  var _mapCols := FPathFInder.Columns;
  var _mapPtr: PByte := FPathFinder.Data;                                       // Read only
  var _wgtPtr: PByte := @FMapWeights[0];

  TParallel.For(1, _mapRows -2, procedure(Row: Integer)
  var
    _nx, _ny, _Idx: Integer;
    _WallCount: Integer;
  begin
    for var _Col := 1 to _mapCols - 2 do
    begin
      _Idx := Row * _mapCols + _Col;

      if (_mapPtr + _Idx)^ = 0 then                                             // = if _srcPtr[_Idx] = 0 then
      begin
        _WallCount := 0;

        { 8-way neighbor cell inspection ? }
        for _ny := -1 to 1 do
          for _nx := -1 to 1 do
          begin
            if (_nx = 0) and (_ny = 0) then Continue;
            if (_mapPtr + (Row + _ny) * _mapCols + (_Col + _nx))^ = 1 then
              Inc(_WallCount);
          end;
        { Setting threshold: If more than 4 out of 8 compartments are walls,
          this is also considered to be the interior of the building }
        if _WallCount >= FWallDefineVal then
        begin
          (_mapPtr + _Idx)^ := 1;
          (_wgtPtr + _Idx)^ := 255;
        end;
      end;
    end;
  end);
end;

procedure TFormMain.RefineWallGrid_hex;
begin
  var _mapRows := FPathFinder.Rows;
  var _mapCols := FPathFinder.Columns;
  var _mapPtr: PByte := FPathFinder.Data;
  var _wgtPtr: PByte := @FMapWeights[0];

  TParallel.For(1, _mapRows - 2, procedure(Row: Integer)
  var
    _Idx, _WallCount: Integer;
    _nx, _ny: Integer;
    _colParity: Integer;
  begin
    for var _Col := 1 to _mapCols - 2 do
    begin
      _Idx := Row * _mapCols + _Col;

      if (_mapPtr + _idx)^ = 0 then
      begin
        _WallCount := 0;
        _colParity := _Col and 1;

        for var _neighbor := 0 to 5 do
        begin
          _nx := _Col + C_HEX_OFFSETS[_colParity, _neighbor, 0];
          _ny := Row  + C_HEX_OFFSETS[_colParity, _neighbor, 1];

          if (_mapPtr + _ny * _mapCols + _nx)^ = 1 then
            Inc(_WallCount);
        end;

        if _WallCount >= FWallDefineVal then
        begin
          (_mapPtr + _idx)^ := 1;
          (_wgtPtr + _Idx)^ := 255;
        end;
      end;
    end;
  end);
end;

function TFormMain.IsInGrid(AGX, AGY: Integer): Boolean;
begin
  Result := (AGX >= 0) and (AGX < FPathFInder.Columns) and (AGY >= 0) and (AGY < FPathFInder.Rows);
end;

procedure TFormMain.UpdatePath(const AUpdateStatus: Boolean = False);
begin
  if (FPathFinder = nil) or
     (not IsInGrid(FStartPos.X, FStartPos.Y)) or
     (not IsInGrid(FFinishPos.X, FFinishPos.Y)) then Exit;

  if FPathPending then
  begin
    FPathDirty := True;
    Exit;
  end;

  FPathPending := True;
  FPathDirty   := False;

  var _StartPos  := FStartPos;
  var _FinishPos := FFinishPos;

  TTask.Run(procedure
  var
    _NewPath: TTileMapPath;
    _Stopwatch: TStopwatch;
  begin
    _Stopwatch := TStopwatch.StartNew;
    _NewPath := FPathFinder.FindPath(_StartPos, _FinishPos, @FMapWeights[0]);
    _Stopwatch.Stop;

    TThread.Queue(nil,
      procedure
      begin
        // ------------------------------------------------------------------ //
        FCurrentPath.Release;
        FCurrentPath     := _NewPath;
        // ------------------------------------------------------------------ //
        FPerformanceTick := _Stopwatch.ElapsedMilliseconds;
        FPathPending     := False;

        if FPathDirty then
          UpdatePath(AUpdateStatus)
        else
          begin
            PaintBox_Map.Repaint;
            if AUpdateStatus then
              UpdateStatusLabel();
          end;
      end);
  end);
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

{ To DO - Distinguish between cities, mountains, and plains ------------------ }

procedure TFormMain.CalculateWeightsFromImage(const ADefault: Boolean = False);
begin
  if FBackgroundBitmap.IsEmpty then Exit;

  var _Data: TBitmapData;
  if FBackgroundBitmap.Map(TMapAccess.Read, _Data) then
  try
    var _StepX :=     FBackgroundBitmap.Width /  FPathFInder.Columns;
    var _StepY :=     FBackgroundBitmap.Height / FPathFInder.Rows;
    var _mapCols :=   FPathFInder.Columns;
    var _mapRows :=   FPathFInder.Rows;

    var _mapPtr: PByte := FPathFinder.Data;
    var _wgtPtr: PByte := @FMapWeights[0];

    TParallel.For(0, _mapRows-1, procedure(Row : Integer)
    var
      _PixelColor: TAlphaColorRec;
      _H, _S, _L: Single;
      _Idx: Integer;
      _Scan: PAlphaColorRecArray;
      _PixelCount, _ObstacleCount, _WaterCount, _RoadCount: array of Integer;
    begin
      SetLength(_PixelCount,    _mapCols);
      SetLength(_ObstacleCount, _mapCols);
      SetLength(_WaterCount,    _mapCols);
      SetLength(_RoadCount,     _mapCols);

      var _SumL: array of Double;
      SetLength(_SumL, _mapCols);

      for var _py := Max(0, Trunc(Row * _StepY)) to Min(FBackgroundBitmap.Height-1, Trunc((Row+1)*_StepY)-1) do
      begin
        _Scan := _Data.GetScanline(_py);
        for var _col := 0 to _mapCols - 1 do
          for var _px := Max(0, Trunc(_col * _StepX)) to Min(FBackgroundBitmap.Width - 1, Trunc((_col + 1) * _StepX) - 1) do
          begin
            _PixelColor := _Scan^[_px];
            System.UIConsts.RGBtoHSL(TAlphaColor(_PixelColor), _H, _S, _L);

            if (_L > 0.85) and (_S < 0.15) then Inc(_ObstacleCount[_col]);
            if (_L < 0.20)                 then Inc(_WaterCount[_col]);
            if (_L > 0.40) and (_L < 0.70) and (_S < 0.20) then Inc(_RoadCount[_col]);

            _SumL[_col] := _SumL[_col] + _L;
            Inc(_PixelCount[_col]);
          end;
      end;

      for var _col := 0 to _mapCols - 1 do
      begin
        _Idx := Row * _mapCols + _col;
        if _PixelCount[_col] <= 0 then Continue;

        if ((_ObstacleCount[_col] + _WaterCount[_col]) / _PixelCount[_col] > 0.45) then
          begin
            (_mapPtr + _Idx)^ := 1;
            (_wgtPtr + _Idx)^ := 255;
          end
        else
          begin
            var _AvgL := _SumL[_col] / _PixelCount[_col];
            (_mapPtr + _Idx)^ := 0;
            if (_RoadCount[_col] / _PixelCount[_col] > 0.3)
              then (_wgtPtr + _Idx)^ := 0
              else (_wgtPtr + _Idx)^ := Trunc(Max(0, (0.8 - _AvgL) * 40));
          end;
      end;
    end);
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
  var _HexH     := ACellSize * C_SQRT3_2_MAX;
  var _ColStep  := ACellSize * C_ColStep;
  var _OddColOffset := IfThen(Odd(GX), _HexH * 0.5, 0);

  Result.X := AViewOffset.X + Single(GX) * _ColStep + ACellSize * 0.5;
  Result.Y := AViewOffset.Y + Single(GY) * _HexH + _OddColOffset + _HexH * 0.5;
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
  var Radius := Double(ACellSize) * C_INV_SQRT3;
  var AngleRad: Double := 0;

  for var _i := 0 to 5 do
  begin
    AngleRad     := (Pi / 3.0) * _i;                                            // 0°, 60°, 120°, 180°, 240°, 300°
    ACorners[_i] := PointF(ACentre.X + Single(Radius * Cos(AngleRad)),
                           ACentre.Y + Single(Radius * Sin(AngleRad)));
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
  Corners: TPolygon;
begin
  SetLength(Corners, 6);
  HexCorners(ACentre, ACellSize, Corners);
  with ACanvas do
  begin
    if ADoFill then
    begin
      Fill.Color := AFillColor;
      FillPolygon(Corners, 0.5);
    end;
    Stroke.Dash :=      TStrokeDash.Dot;
    Stroke.Kind :=      TBrushKind.Solid;
    Stroke.Color :=     AStrokeColor;
    Stroke.Thickness := AStrokeThick;
    DrawPolygon(Corners, 0.5);
  end;
end;

{ Returns the screen-space centre of hex cell (GX, GY). }
{ Flat-top orientation, even-column offset.              }
function TFormMain.HexCellCenter(const AGX, AGY: Integer): TPointF;
begin
  var _HexH    := FCellSize * C_SQRT3_2_MAX;
  var _ColStep := FCellSize * C_ColStep;
  var _OddOff  := IfThen(Odd(AGX), _HexH * 0.5, 0.0);
  Result.X := FViewOffset.X + AGX * _ColStep + FCellSize * 0.5;
  Result.Y := FViewOffset.Y + AGY * _HexH + _OddOff + _HexH * 0.5;
end;

{ Returns the grid cell (GX,GY) that contains screen point AScreenPos.       }
{ Tests a 3×3 neighbourhood and picks the nearest hex centre.                }
function TFormMain.HexCellAt(const AScreenPos: TPointF): TPoint;
begin
  Result := TPoint.Zero;
  if (FPathFinder = nil) or (FCellSize <= 0) then Exit;

  var _HexH    := FCellSize * C_SQRT3_2_MAX;
  var _ColStep := FCellSize * C_ColStep;

  { Raw estimate — may be negative or beyond grid bounds, that is fine }
  var _ApproxCol := Trunc((AScreenPos.X - FViewOffset.X) / _ColStep);
  var _ApproxRow := Trunc((AScreenPos.Y - FViewOffset.Y) / _HexH);
  { Clamp only to keep the search seed inside a window that lets us test
    neighbours without going absurdly far out of range }
  _ApproxCol := EnsureRange(_ApproxCol, -1, FPathFInder.Columns);
  _ApproxRow := EnsureRange(_ApproxRow, -1, FPathFInder.Rows);

  var _BestDist  := MaxSingle;
  var _BestCol   := EnsureRange(_ApproxCol, 0, FPathFInder.Columns  - 1);
  var _BestRow   := EnsureRange(_ApproxRow, 0, FPathFInder.Rows - 1);

  var _Dist: Single     := 0;
  var _TestCol: Integer := 0;
  var _TestRow: Integer := 0;
  var _Centre := TPointF.Zero;
  { 7×7 neighbourhood guarantees we catch the correct cell even at edges
    and across the odd-column vertical offset boundary }
  for var _dCol := -3 to 3 do
    for var _dRow := -3 to 3 do
    begin
      _TestCol := _ApproxCol + _dCol;
      _TestRow := _ApproxRow + _dRow;
      if (_TestCol < 0) or (_TestCol >= FPathFInder.Columns)  then Continue;
      if (_TestRow < 0) or (_TestRow >= FPathFInder.Rows)     then Continue;
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
function TFormMain.ScreenToGridF(const AX, AY: Single): TPoint;
begin
  if (FPathFinder = nil) or (FCellSize <= 0) then Exit(TPoint.Zero);

  if FPathFinder.Kind = TTileMapKind.mkHexagonal then
    Result := HexCellAt(PointF(AX, AY))
  else
    Result := TPoint.Create(Floor((AX - FViewOffset.X) / FCellSize),
                            Floor((AY - FViewOffset.Y) / FCellSize));
end;

{ ---- ScreenToGridP -------------------------------------------------------- }
{ Used by MouseDown and MouseMove to get (GX, GY) from raw mouse coords.      }
procedure TFormMain.ScreenToGridP(const AScreenPos: TPointF; out AGX, AGY: Integer);
begin
  if FPathFinder.Kind = TTileMapKind.mkHexagonal then
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
  if (FPathFinder = nil) or (FCellSize <= 0) then Exit(PointF(0, 0));

  if FPathFinder.Kind = TTileMapKind.mkHexagonal then
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
  if FPathFinder.Kind = TTileMapKind.mkHexagonal then
    AScreenPos := HexCellCenter(AGX, AGY)
  else
    begin
      AScreenPos.X := AGX * FCellSize + FViewOffset.X;
      AScreenPos.Y := AGY * FCellSize + FViewOffset.Y;
    end;
end;

procedure TFormMain.DrawTiles(ACanvas: TCanvas);
begin
  if CheckBox_HeatMap.IsChecked then
  begin
    DrawHeatmap(Canvas);
    Exit;
  end;

  // Set Viewport Rectangle
  var _Idx := 0;
  var _ScreenPos := TPointF.Zero;
  var _R: TRectF := RectF(0,0,0,0);
  var _Val: Byte := 0;
  var _FirstCol  := Max(0, Floor(-FViewOffset.X / FCellSize));
  var _LastCol   := Min(FPathFInder.Columns-1, Ceil((PaintBox_Map.Width - FViewOffset.X) / FCellSize));
  var _FirstRow  := Max(0, Floor(-FViewOffset.Y / FCellSize));
  var _LastRow   := Min(FPathFInder.Rows-1, Ceil((PaintBox_Map.Height - FViewOffset.Y) / FCellSize));

  for var _row := _FirstRow to _LastRow do
    for var _col := _FirstCol to _LastCol do
    begin
      _Idx := _row * FPathFInder.Columns + _col;
      _Val := (FPathFinder.Data + _Idx)^;
      GridToScreenP(_col, _row, _ScreenPos);
      _R := RectF(_ScreenPos.X, _ScreenPos.Y, _ScreenPos.X + FCellSize, _ScreenPos.Y + FCellSize);

      if _Val = 1 then
        begin
          ACanvas.Fill.Color := MakeColor(TAlphaColors.Black, 150);
          ACanvas.FillRect(_R, 0, 0, [], 0.6);
        end
      else if FMapWeights[_Idx] > 10 then
        begin
          ACanvas.Fill.Color := V_GWeightColorTable1[FMapWeights[_Idx]];
          ACanvas.FillRect(_R, 0, 0, [], 0.6);
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
  if FPathFinder = nil then Exit;

  { Square tiles — identical to original DrawTiles }
  if FPathFinder.Kind <> TTileMapKind.mkHexagonal then
  begin
    DrawTiles(ACanvas);
    Exit;
  end;

  { --- Hexagonal tiles --- }
  var _ViewRect :=  RectF(0, 0, PaintBox_Map.Width, PaintBox_Map.Height);
  var _HexH :=      FCellSize * C_SQRT3_2_MAX;
  var _ColStep :=   FCellSize * C_ColStep;
  var _Idx :=       0;
  var _Val: Byte := 0;
  var _Centre :=    TPointF.Zero;

  { 1. Use Floor/Ceil to get a wider range when calculating the index (plus margin +2) }
  var _FirstCol := Max(0, Floor(-FViewOffset.X / _ColStep) - 1);
  var _LastCol  := Min(FPathFInder.Columns - 1, Ceil((PaintBox_Map.Width - FViewOffset.X) / _ColStep) + 1);
  { Hex has odd columns down, so the Row range must be wider up and down to not be cut off }
  var _FirstRow := Max(0, Floor(-FViewOffset.Y / _HexH) - 2);
  var _LastRow  := Min(FPathFInder.Rows - 1, Ceil((PaintBox_Map.Height - FViewOffset.Y) / _HexH) + 2);

  for var _gRow := _FirstRow to _LastRow do                                     // It's not from 0 to Height, but only visible rows!
    for var _gCol := _FirstCol to _LastCol do                                   // It's not from 0 to WIDTH, but only the visible ten!
    begin
      _Idx := _gRow * FPathFInder.Columns + _gCol;
      if (_Idx < 0) or (_Idx >= Length(FMapWeights)) then Continue;             //  safety

      _Val := (FPathFinder.Data + _Idx)^;
      if (_Val = 1) or (FMapWeights[_Idx] > 50) then                            // Illustrated only when wall (1) or weight is present
      begin
        _Centre := HexCenterF(_gCol, _gRow, FCellSize, FViewOffset);

        if _Val = 1
          then DrawHex(ACanvas, _Centre, FCellSize, MakeColor(TAlphaColors.Black, 150), MakeColor(TAlphaColors.Black, 80), FGridStrokeThick,     True)
          else DrawHex(ACanvas, _Centre, FCellSize, FMapWeights[FMapWeights[_Idx]],     MakeColor(TAlphaColors.Black, 30), FGridStrokeThick-0.1, True);
      end;
    end;
end;

procedure TFormMain.DrawGrid(ACanvas: TCanvas);
begin
  if FCellSize < 4 then Exit;

  with ACanvas do
  begin
    Stroke.Dash :=      TStrokeDash.Dot;
    Stroke.Color :=     MakeColor(ColorComboBox_Grid.Color, 80);
    Stroke.Thickness := FGridStrokeThick;
  end;

  for var _col := 0 to FPathFInder.Columns -1 do
    ACanvas.DrawLine(PointF(FViewOffset.X + _col * FCellSize, FViewOffset.Y),
                     PointF(FViewOffset.X + _col * FCellSize, FViewOffset.Y + FPathFInder.Rows * FCellSize), 1.0);

  for var _row := 0 to FPathFInder.Rows - 1 do
    ACanvas.DrawLine(PointF(FViewOffset.X, FViewOffset.Y + _row * FCellSize),
                     PointF(FViewOffset.X + FPathFInder.Columns * FCellSize, FViewOffset.Y + _row * FCellSize), 1.0);
end;

{ ============================================================================ }
{  DrawGridEx                                                                  }
{  Drop-in replacement for DrawGrid.                                           }
{  Draws the appropriate grid style depending on FPathFinder.Kind:             }
{    mkHexagonal → flat-top hex grid                                           }
{    all others  → original square grid (identical to DrawGrid)                }
{ ============================================================================ }
procedure TFormMain.DrawGridEx(ACanvas: TCanvas);
begin
  if FPathFinder = nil then Exit;

  { Square grid — unchanged from original }
  if FPathFinder.Kind <> TTileMapKind.mkHexagonal then
  begin
    DrawGrid(ACanvas);                                                          // call the existing method as-is
    Exit;
  end;

  { --- Hexagonal grid --- }
  if FCellSize < 6 then Exit;                                                   // too small to draw meaningfully

  var _HexH    := FCellSize * C_SQRT3_2_MAX;
  var _ColStep := FCellSize * C_ColStep;

  { Visible viewport — skip hexagons entirely outside the screen }
  var _ViewRect := RectF(0, 0, PaintBox_Map.Width, PaintBox_Map.Height);

  { Estimate the first and last visible columns/rows to avoid iterating
    over the whole grid when the user has panned / zoomed. }
  var _FirstCol := Max(0, Trunc((_ViewRect.Left - FViewOffset.X) / _ColStep) - 1);
  var _LastCol  := Min(FPathFInder.Columns - 1, Trunc((_ViewRect.Right - FViewOffset.X) / _ColStep) + 1);
  var _FirstRow := Max(0, Trunc((_ViewRect.Top - FViewOffset.Y) / _HexH) - 1);
  var _LastRow  := Min(FPathFInder.Rows - 1, Trunc((_ViewRect.Bottom - FViewOffset.Y) / _HexH) + 2);
  var _Centre   := TPointF.Zero;
  ACanvas.Stroke.Dash := TStrokeDash.Solid;

  for var _gCol := _FirstCol to _LastCol do
    for var _gRow := _FirstRow to _LastRow do
    begin
      _Centre := HexCenterF(_gCol, _gRow, FCellSize, FViewOffset);

      { Quick bounding-circle cull: if the _Centre is more than CellSize   }
      { away from the viewport, the hex is certainly not visible.          }
      if (_Centre.X + FCellSize < _ViewRect.Left)  or
         (_Centre.X - FCellSize > _ViewRect.Right) or
         (_Centre.Y + _HexH     < _ViewRect.Top)   or
         (_Centre.Y - _HexH     > _ViewRect.Bottom) then Continue;

      DrawHex(ACanvas, _Centre, FCellSize,
              0,                                       { fill — none here }
              MakeColor(ColorComboBox_Grid.Color, 80), { stroke colour    }
              FGridStrokeThick,                        { stroke width     }
              False);                                  { stroke only      }
    end;
end;

{ ============================================================================ }
{  Draw Logo                                                                   }
{ ============================================================================ }

procedure TFormMain.DrawLogo(const ACanvas: TCanvas);
begin
  if FBackgroundBitmap.IsEmpty then
    begin
      if Assigned(Form_Resources) then
        begin
          if FunnyFlag = 0
            then FBackgroundBitmap.Assign(Form_Resources.Image_Logo0.Bitmap)
            else FBackgroundBitmap.Assign(Form_Resources.Image_Logo1.Bitmap);
        end
      else
        Exit;
    end;
  AutoCropImage(FBackgroundBitmap);
  CenterMap(True);
  var _BgOpacity :=   IfThen(FIsHighlightMode, 0.3, 1.0);
  var _MapWidthPx :=  FPathFInder.Columns *  FSetCellSize;
  var _MapHeightPx := FPathFInder.Rows *     FSetCellSize;
  var _DestRect :=    TRectF.Create(FViewOffset.x, FViewOffset.y, FViewOffset.x + _MapWidthPx, FViewOffset.y + _MapHeightPx);

  ACanvas.DrawBitmap(FBackgroundBitmap, FBackgroundBitmap.BoundsF, _DestRect, _BgOpacity);
end;

procedure TFormMain.DrawHeatmap(Canvas: TCanvas);
var
  _StartX, _StartY, _EndX, _EndY: Integer;
begin
  ScreenToGridP(PointF(0, 0), _StartX, _StartY);
  ScreenToGridP(PointF(PaintBox_Map.Width, PaintBox_Map.Height), _EndX, _EndY);

  _StartX := Max(0, _StartX);
  _StartY := Max(0, _StartY);
  _EndX   := Min(FPathFInder.Columns - 1, _EndX);
  _EndY   := Min(FPathFInder.Rows - 1,    _EndY);

  var _SPos: TPointF:= TPoint.Zero;
  var _Rect: TRectF := TRectF.Create(0,0,0,0);
  var _Wght: Byte := 0;
  for var _gRow := _StartY to _EndY do
    for var _gCol := _StartX to _EndX do
    begin
      _Wght := FMapWeights[_gRow * FPathFInder.Columns + _gCol];
      if _Wght > 10 then
      begin
        GridToScreenP(_gCol, _gRow, _SPos);
        _Rect := TRectF.Create(_SPos.X, _SPos.Y, _SPos.X + FCellSize, _SPos.Y + FCellSize);
        Canvas.Fill.Color := V_GWeightColorTable2[_Wght];
        Canvas.FillRect(_Rect, 0, 0, [], 1.0);
      end;
    end;
end;

{ ============================================================================ }
{  Draw Map  / PaintBox_MapPaint                                               }
{ ============================================================================ }

procedure TFormMain.PaintBox_MapPaint(Sender: TObject; Canvas: TCanvas);
begin
  if FPathFinder = nil then Exit;

  if FLockMapFlag then begin DrawLogo(Canvas); Exit; end;
  if FLockUpdate then Exit;

  if FCellSize < 10 then Exit;

  var _State: TCanvasSaveState := Canvas.SaveState;
  try
    Canvas.IntersectClipRect(PaintBox_Map.LocalRect);
    Canvas.Clear(FDefaultBackColor);

    if not FBackgroundBitmap.IsEmpty then
    begin
      var _BgOpacity := IfThen(FIsHighlightMode, 0.3, 1.0);
      var _MapWidth: Single :=  0;
      var _MapHeight: Single := 0;
      HexMapPixelSize(_MapWidth, _MapHeight);
      var _MapRect := RectF(FViewOffset.X, FViewOffset.Y,
                            FViewOffset.X + _MapWidth,
                            FViewOffset.Y + _MapHeight);
      Canvas.DrawBitmap(FBackgroundBitmap, FBackgroundBitmap.BoundsF, _MapRect, _BgOpacity);
    end;

    if FIsHighlightMode or CheckBox_Weights.IsChecked then
      DrawTilesEx(Canvas);

    if CheckBox_ShowGrid.IsChecked then
      DrawGridEx(Canvas);

    if IsPathValid then
      DrawSmoothPath(Canvas, CheckBox_SmoothLine.IsChecked);

    DrawMarker(Canvas, 0, FStartPos);
    DrawMarker(Canvas, 1, FFinishPos);
  finally
    Canvas.RestoreState(_State);
  end;
end;

procedure TFormMain.BackupCurrentPath();
begin
  { Backup and Free FCurrentPatth }
  if FCurrentPath.Count > 0 then
  begin
    FBackupPath:= FCurrentPath.Clone;
  end;
end;

function TFormMain.IsPathValid: Boolean;
begin
  Result := (FCurrentPath.Count > 2);
end;

procedure TFormMain.SetPathColorControl(const AFlag: Integer; const ARepaint: Boolean = True);
begin
  FPathColor := C_PathColors[AFlag];
  Rectangle_Yellow.Opacity := IfThen(AFlag =0, 1.0, 0.5);
  Rectangle_White.Opacity :=  IfThen(AFlag =1, 1.0, 0.5);
  Rectangle_Blue.Opacity :=   IfThen(AFlag =2, 1.0, 0.5);
  Rectangle_Red.Opacity :=    IfThen(AFlag =3, 1.0, 0.5);
  Rectangle_Green.Opacity :=  IfThen(AFlag =4, 1.0, 0.5);

  if FLockUpdate then Exit;
  if ARepaint then PaintBox_Map.Repaint;
end;

procedure TFormMain.RadioButton_Filter0Change(Sender: TObject);
begin
  FFilterIndex := TRadioButton(Sender).Tag;
  if CheckBox_FilterBD.IsChecked then
  begin
    AnalyzeHeightMap(FFilterIndex);
    UpdatePath();
  end;
end;

procedure TFormMain.Rectangle_YellowClick(Sender: TObject);
begin
  SetPathColorControl(TRectangle(Sender).Tag);
end;

// -------------------------------------------------------------------------- //

procedure TFormMain.DrawMarker(ACanvas: TCanvas; const APosFlag: Integer; const AGridPos: TPoint);
begin
  var _SPos :=  GridToScreenF(AGridPos);
  var _MSize := Max(10, FCellSize * 1.5);
  var _Rect :=  RectF(_SPos.X - _MSize/2, _SPos.Y - _MSize/2, _SPos.X + _MSize/2, _SPos.Y + _MSize/2);

  if APosFlag = 0
    then ACanvas.DrawBitmap(R_PosIconS, R_PosIconRectF, _Rect,  1.0, True)
    else ACanvas.DrawBitmap(R_PosIconF, R_PosIconRectF, _Rect,  1.0, True)
end;

procedure TFormMain.DrawMarker(ACanvas: TCanvas; const AGridPos: TPoint; const AColor1, AColor2: TAlphaColor; const ASymbol: string);
begin
  var _SPos :=  GridToScreenF(AGridPos);
  var _MSize := Max(14, FCellSize * 0.85);
  var _Rect :=  RectF(_SPos.X - _MSize/2, _SPos.Y - _MSize/2, _SPos.X + _MSize/2, _SPos.Y + _MSize/2);

  with ACanvas do
  begin
    DrawBitmap(R_PosIconS, R_PosIconRectF, _Rect,  1.0, True);

    Fill.Color := AColor1;
    FillEllipse(_Rect, 1.0);
    Stroke.Color := AColor2;
    Stroke.Thickness := 3;
    DrawEllipse(_Rect, 1.0);
  end;

  { Symbol Text }
  if FCellSize > 10 then
  with ACanvas do
  begin
    Fill.Color := AColor2;
    Font.Size :=  Max(10, _MSize * 0.5);
    FillText(_Rect, ASymbol, False, 1.0, [], TTextAlign.Center, TTextAlign.Center);
  end;
end;

{ Draw Path by   // Linear Interpolation ------------------------------------- }

function OffsetToCube(Col, Row: Integer): THexCube;
begin
  Result.X := Col;
  Result.Z := Row - (Col - (Col and 1)) div 2;
  Result.Y := -Result.X - Result.Z;
end;

function CubeToOffset(Cube: THexCube): TPoint;
begin
  Result.X := Cube.X;
  Result.Y := Cube.Z + (Cube.X - (Cube.X and 1)) div 2;
end;

function TFormMain.CubeRound(fX, fY, fZ: Double): THexCube;
begin
  var _rx := Round(fX);
  var _ry := Round(fY);
  var _rz := Round(fZ);

  var _dx := Abs(_rx - fX);
  var _dy := Abs(_ry - fY);
  var _dz := Abs(_rz - fZ);

  if (_dx > _dy) and (_dx > _dz) then _rx := -_ry - _rz else
  if (_dy > _dz)                 then _ry := -_rx - _rz
                                 else _rz := -_rx - _ry;

  Result.X := _rx;
  Result.Y := _ry;
  Result.Z := _rz;
end;

function TFormMain.GetHexLine(AHex, BHex: THexCube): TList<THexCube>;
begin
  Result := TList<THexCube>.Create;

  var _Dist := (Abs(AHex.X - BHex.X) + Abs(AHex.Y - BHex.Y) + Abs(AHex.Z - BHex.Z)) div 2;
  var Step: Double := 0;
  for var _i := 0 to _Dist do
  begin
    if _Dist = 0 then Step := 0 else Step := _i / _Dist;
    Result.Add(CubeRound(AHex.X + (BHex.X - AHex.X) * Step,
                         AHex.Y + (BHex.Y - AHex.Y) * Step,
                         AHex.Z + (BHex.Z - AHex.Z) * Step
                         ));
  end;
end;

function TFormMain.IsHexLinePassable(const AP1, AP2: TPoint): Boolean;
begin
  Result := True;

  var _StartCube := OffsetToCube(AP1.X, AP1.Y);
  var _EndCube   := OffsetToCube(AP2.X, AP2.Y);
  var  _CheckPt  := TPoint.Zero;
  var _HexLine   := GetHexLine(_StartCube, _EndCube);
  var _Idx       := 0;
  try
    for var _Hex: THexCube in _HexLine do
    begin
      _CheckPt := CubeToOffset(_Hex);

      if (_CheckPt.X < 0) or (_CheckPt.X >= FPathFInder.Columns) or
         (_CheckPt.Y < 0) or (_CheckPt.Y >= FPathFInder.Rows) then Continue;

      _Idx := _CheckPt.Y * FPathFInder.Columns + _CheckPt.X;
      if (FPathFinder.Data + _Idx)^ = 1 then
      begin
        Result := False;
        Break;
      end;
    end;
  finally
    _HexLine.Free;
  end;
end;

procedure TFormMain.OptimizeRoute(ATileMapPath: TTileMapPath);
begin
  if (ATileMapPath.Count < 3) then Exit;

  var _StartIdx := 0;
  var _P1 := TPoint.Zero;
  var _P3 := TPoint.Zero;
  while _StartIdx < ATileMapPath.Count - 2 do
  begin
    _P1 := ATileMapPath.Points[_StartIdx];
    _P3 := ATileMapPath.Points[_StartIdx + 2];

    if IsHexLinePassable(_P1, _P3) then
      begin
        if _StartIdx + 2 < ATileMapPath.Count then
        begin // = Delete
          Move(ATileMapPath.Points[_StartIdx + 2], ATileMapPath.Points[_StartIdx + 1],
              (ATileMapPath.Count - (_StartIdx + 2)) * SizeOf(TPoint));
        end;
        ATileMapPath.Count := ATileMapPath.Count - 1;
      end
    else
      begin
        Inc(_StartIdx);
      end;
  end;
end;

procedure TFormMain.DrawSmoothPath(ACanvas: TCanvas; const ASmoothFlag: Boolean = False);
begin
  if (FCurrentPath.Count < 2) then Exit;

  if ASmoothFlag then
    begin
      // -------------------------------------------------------------------  //
      OptimizeRoute(FCurrentPath);
      // -------------------------------------------------------------------  //
      var _PathData := TPathData.Create;
      try
        var _P0 := GridToScreenF(FCurrentPath.Points[0]);                       // 1. Set the starting point (centre of the first node)
        var _P1, _P2, _Mid: TPointF;
        _PathData.MoveTo(_P0);
        for var _i := 1 to FCurrentPath.Count - 2 do                            // 2. Path Interpolation Loop
        begin
          _P1 :=  GridToScreenF(FCurrentPath.Points[_i]);
          _P2 :=  GridToScreenF(FCurrentPath.Points[_i + 1]);
          _Mid := PointF((_P1.X + _P2.X) / 2, (_P1.Y + _P2.Y) / 2);             // Calculate the midpoint of two adjacent points and use them as control points for the curve
          _PathData.QuadCurveTo(_P1, _Mid);                                     // Curve from the current position to the midpoint (P1 becomes the control point)
        end;                                                                    // 3. Last point connection
        _PathData.LineTo(GridToScreenF(FCurrentPath.Points[FCurrentPath.Count - 1]));

        with ACanvas do
        begin
          Stroke.Dash :=      TStrokeDash.Solid;
          Stroke.Color :=     IfThen(FIsHighlightMode, TAlphaColors.Cyan, FPathColor);
          Stroke.Color :=     System.UIConsts.MakeColor(Stroke.Color, 0.6);
          Stroke.Thickness := Max(5, FCellSize * 0.3);
          Stroke.Cap :=       TStrokeCap.Round;
          Stroke.Join :=      TStrokeJoin.Round;

          DrawPath(_PathData, 1.0);
        end;
      finally
        _PathData.Free;
      end;
    end
  else
    begin
      var _ViewRect := PaintBox_Map.LocalRect;
      _ViewRect.Inflate(FCellSize, FCellSize);

      with ACanvas do
      begin
        Stroke.Dash :=      TStrokeDash.Solid;
        Stroke.Color :=     IfThen(FIsHighlightMode, TAlphaColors.Cyan, FPathColor);
        Stroke.Color :=     System.UIConsts.MakeColor(Stroke.Color, 0.6);
        Stroke.Thickness := Max(5, FCellSize * 0.3);
        Stroke.Cap :=       TStrokeCap.Round;
      end;

      for var _i := 0 to FCurrentPath.Count - 2 do
      begin
        var _P1 := GridToScreenF(FCurrentPath.Points[_i]);
        var _P2 := GridToScreenF(FCurrentPath.Points[_i+1]);
        if _ViewRect.Contains(_P1) or _ViewRect.Contains(_P2) then
          ACanvas.DrawLine(_P1, _P2, 1.0);
      end;
    end;
end;

{ Mouse Control Setion ------------------------------------------------------- }
procedure TFormMain.HideCustomWeight(const  AFlag: Integer);
begin
  Layout_CustomWeight.Visible := False;
end;

procedure TFormMain.PaintBox_MapMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if FLockMapFlag then Exit;

  HideCustomWeight(0);

  var _GX, _GY: Integer;
  FLastMousePos := PointF(X, Y);
  ScreenToGridP(FLastMousePos, _GX, _GY);

  var _Idx := _GY * FPathFInder.Columns + _GX;
  FCurrentWeight :=     FMapWeights[_Idx];
  FCurrentWightFlag := (FPathFinder.Data + _Idx)^;

  if CustomColorFlag then
  begin
    var _Value:Integer := IfThen(Button = TMouseButton.mbLeft, 0, 1);
    ApplyTerrainCustomization(0, '', FCurrentWeight, _Value);

    Exit;
  end;

  if Button = TMouseButton.mbLeft then
    begin
      if (_GX = FStartPos.X) and (_GY = FStartPos.Y) then
        FDragMode := TDragMode.StartPoint else
      if (_GX = FFinishPos.X) and (_GY = FFinishPos.Y) then
        FDragMode := TDragMode.FinishPoint
      else
        FDragMode := TDragMode.PanMap;
    end else
  if Button = TMouseButton.mbRight then
    begin
      FDragMode := TDragMode.EditWeight;
      var _ws: string := 'Change Weight -> 0';
      if IsInGrid(_GX, _GY) then
      begin
        if FCurrentWeight > 0 then
          begin
            var _val: Byte := Trunc(TrackBar_CellWeight.Value);
            (FPathFinder.Data + _Idx)^ := 0;
            if (ssShift in Shift)
              then FMapWeights[_Idx] := IIF.CastBool<Byte>(CheckBox_WeightCell.IsChecked, _val, 0)
              else FMapWeights[_Idx] := 0;
          end
        else
          begin
            (FPathFinder.Data + _Idx)^ := 1;
            FMapWeights[_Idx] := 255;
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
  if CustomColorFlag then Exit;

  var _NewPos := PointF(X, Y);
  var _GX: Integer := 0;
  var _GY: Integer := 0;
  ScreenToGridP(_NewPos, _GX, _GY);

  var _Idx := _GY * FPathFInder.Columns + _GX;
  FCurrentWeight := FMapWeights[_Idx];
  FCurrentWightFlag := (FPathFinder.Data + _Idx)^;
  FCurrGridX := _GX;
  FCurrGridY := _GY;

  var _IsRefreshing: Boolean := False;

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
        ConstrainViewOffset;
        _IsRefreshing :=True;
        end;
    TDragMode.EditWeight:
      if IsInGrid(_GX, _GY) then
      begin
        if (ssShift in Shift) then begin (FPathFinder.Data + _Idx)^ := 1; FMapWeights[_Idx] := 255; end else
        if (ssAlt in Shift)   then begin (FPathFinder.Data + _Idx)^ := 0; FMapWeights[_Idx] := 0;   end;
        FCurrentWightFlag := (FPathFinder.Data + _Idx)^;
        UpdatePath;
      end;
  end;

  FLastMousePos := _NewPos;
  // ------------------------------------------------------------------------ //
  if _IsRefreshing then PaintBox_Map.Repaint;
  // ------------------------------------------------------------------------ //
  UpdateStatusLabel();
end;

procedure TFormMain.PaintBox_MapMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  CustomColorFlag := False;                                                     // ???
  PaintBox_Map.Cursor := TCursor(crDefault);
  FDragMode := TDragMode.None;
end;

procedure TFormMain.PaintBox_MapMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
begin
  if FLockMapFlag then Exit;

  var _OldCellSize := FCellSize;
  if WheelDelta > 0 then FCellSize := Min(FCellSize * 1.1, 400)
                    else FCellSize := Max(FCellSize * 0.9, 0.5);

  if FCellSize < 10 then
  begin
    FCellSize := _OldCellSize;
    Exit;
  end;

  FCellSize := EnsureRange(FCellSize, 1.0, 400.0);
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

procedure TFormMain.UpdateStatusLabel();
begin
  if FPathFinder = nil then Exit;

  FZoomRatio := FCellSize / FSetCellSize;
  Label_Zoom.Text :=        Format('🔍 Zoom: %.0f%%  ', [FZoomRatio*100]);
  Label_ViewPos.Text :=     Format('👉 Grid (%d,%d) | Cell Size : %d | 💧 Cell Weight: %d [%d]', [FCurrGridX, FCurrGridY, Round(FCellSize),  FCurrentWeight, FCurrentWightFlag]);
  Label_Grids.Text :=       Format('🏁 Grids %d x %d | Map Weight %.2f', [FPathFInder.Columns, FPathFInder.Rows, FWeightMultiplier]);
  Label_SInfos.Text :=      Format('🧩 Nodes: %d | Distance: %.1f', [FCurrentPath.Count, FCurrentPath.Distance]);

  if Label_Performance.Visible then
  Label_Performance.Text := Format('✨ Performance: %d ms | PoolCount %d MapSize %d MaxNodes %d Nodes: %d | Offset: (%.0f, %.0f)',
                                   [FPerformanceTick, FPathFinder.PoolCount, FPathFinder.MapSize, FPathFinder.MaxNodes, FCurrentPath.Count, FViewOffset.X, FViewOffset.Y]);
end;

{ ToolBar -------------------------------------------------------------------- }

procedure TFormMain.Button_HeighlightMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if FLockMapFlag then Exit;

  HideCustomWeight(0);
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

procedure TFormMain.Button_ShortkeysClick(Sender: TObject);
begin
  ShowFixedMsg('Help', '');
end;

procedure TFormMain.Button_DefaultParamsClick(Sender: TObject);
begin
  FLockUpdate := True;

  CheckBox_Weights.IsChecked     := False;
  CheckBox_AddTerrain.IsChecked  := True;
  CheckBox_WeightCell.IsChecked  := False;
  CheckBox_SmoothLine.IsChecked  := False;
  CheckBox_ShowGrid.IsChecked    := True;
  CheckBox_FilterBD.IsChecked    := False;

  TrackBar_Weight.Value          := 50.0;
  TrackBar_TileSize.Value        := C_CellSizeDefault;
  TrackBar_CellWeight.Value      := 255;
  TrackBar_WallFactor.Value      := 3;
  WallDefineVal                  := 3;
  ComboBox_Kind.ItemIndex        := 3;
  FTileMapkind                   := TTileMapKind(3);

  TrackBar_CustomOffset.Value    := 10;                                         //Update -> FCustomOffSet
  SetPathColorControl(0, False);

  Label_PathTileSize.Text := '🏁 MAP Tile Size (Default) : '+Trunc(C_CellSizeDefault).ToString;
  FLockUpdate := False;
;
  Action_ResetMapExecute(Self);
end;

procedure TFormMain.ColorComboBox_GridChange(Sender: TObject);
begin
  if FLockUpdate then Exit;
  PaintBox_Map.Repaint;
end;

procedure TFormMain.ComboBox_KindChange(Sender: TObject);
begin
  if FLockUpdate then Exit;
  FTileMapkind := TTileMapKind(ComboBox_Kind.ItemIndex);
  InitializeDrawPath(True);
end;

procedure TFormMain.TrackBar_WallFactorChange(Sender: TObject);
begin
  if FLockUpdate then Exit;
  WallDefineVal := Round(TrackBar_WallFactor.Value);
  Label_WallOffset.Text := '🗺 WALL-Factor '+ WallDefineVal.ToString;
end;

procedure TFormMain.TrackBar_CellWeightChange(Sender: TObject);
begin
  TrackBar_CellWeight.Hint := 'Cell Weight - '+IntToStr(Trunc(TrackBar_CellWeight.Value));
  CheckBox_WeightCell.Text := 'Cell-W '+IntToStr(Trunc(TrackBar_CellWeight.Value));
end;

procedure TFormMain.TrackBar_TileSizeChange(Sender: TObject);
begin
  if FLockUpdate then Exit;
  PaintBox_Map.Repaint;
  Label_PathTileSize.Text := '🏁 MAP Tile Size (Default) : '+Trunc(FSetCellSize).ToString;
end;

procedure TFormMain.TrackBar_TileSizeTracking(Sender: TObject);
begin
  if FLockUpdate then Exit;
  FSetCellSize := TrackBar_TileSize.Value;
  InitializeDrawPath(True);
end;

procedure TFormMain.TrackBar_WeightTracking(Sender: TObject);
begin
  if FLockUpdate then Exit;

  FWeightMultiplier := TrackBar_Weight.Value / 100;
  Label_WeightScale.Text := Format('📍 Default Weight Scale %.2f', [FWeightMultiplier]);

  AnalyzeHeightMap(FFilterIndex);
  UpdatePath(True);
end;

{ Extra Method --------------------------------------------------------------- }

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
        _SaveDialog.FileName := Format('Snapshot_%s.png', [FormatDateTime('yymmdd_hhnnss', Now)]);
        _Snapenflag := _SaveDialog.Execute;
        _SaveFile := _SaveDialog.FileName;
      finally
        _SaveDialog.Free;
      end;
    end
  else
    begin
      var _SaveParth := ExtractFilePath(ParamStr(0));
      _SaveFile := Format('Snapshot_%s.png', [FormatDateTime('yymmdd_hhnnss', Now)]);
      _SaveFile := IncludeTrailingPathDelimiter(_SaveParth) + _SaveFile;
      _Snapenflag := True;
    end;

  if _Snapenflag and (_SaveFile > ' ') then
    begin
      TTask.Run(procedure
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
  { Create a container for the toast at the bottom left }
  Alert_Container := TRectangle.Create(Self);
  with Alert_Container do
  begin
    Parent :=      Self;
    Align :=       TAlignLayout.None;
    Fill.Color :=  TAlphaColors.Black;
    Stroke.Kind := TBrushKind.None;
    XRadius :=     8;
    YRadius :=     8;
    Width :=       200;
    Height :=      30;
    Opacity :=     0; // Start invisible for animation

    Position.X := 10;
    Position.Y := Self.ClientHeight - Height - 42;
    Anchors := [TAnchorKind.akLeft, TAnchorKind.akBottom];
  end;

  { Add Label for text }
  var _Label := TLabel.Create(Alert_Container);
  with _Label do
  begin
    Parent :=    Alert_Container;
    Align :=     TAlignLayout.Client;
    TextAlign := TTextAlign.Center;
    StyledSettings := [TStyledSetting.Family, TStyledSetting.Size];
    TextSettings.FontColor := TAlphaColorRec.White;
    Text := '🔔 '+AMsg;
  end;

  { Animation 1: Fade In }
  TAnimator.AnimateFloat(Alert_Container, 'Opacity', 0.5, 0.3);

  { Animation 2: Fade Out after 2 seconds delay }
  var _Anim := TFloatAnimation.Create(Alert_Container);
  with  _Anim do
  begin
    Parent :=       Alert_Container;
    PropertyName := 'Opacity';
    StartValue :=   1.0;
    StopValue :=    0.0;
    Duration :=     0.5;
    Delay :=        3.0;                                                        // Wait 2 seconds before disappearing
    OnFinish :=     AnimationFinishedEvent;

    Start;
  end;
end;

{The Members of ActionList  -------------------------------------------------- }

procedure TFormMain.AnimationFinishedEvent(Sender: TObject);
begin
  if Assigned(Alert_Container) then
    FreeAndNil(Alert_Container);
end;

procedure TFormMain.Action_ScreenCapExecute(Sender: TObject);
begin
  var _SavePath := ExtractFilePath(ParamStr(0)) +
                   Format('ScreenSnap_%s.png', [FormatDateTime('yymmddhhnnss', Now)]);
  TThread.ForceQueue(nil,
    procedure
    begin
      CaptureCleanWorkArea(_SavePath);
      if FileExists(_SavePath) then
      ShowToastAlert('Saved a Screen Capture');
    end, 100);
end;

procedure TFormMain.Action_ScreenshotExecute(Sender: TObject);
begin
  SaveScreenshot();
end;

procedure TFormMain.Action_ShowGridsExecute(Sender: TObject);
begin
  CheckBox_ShowGrid.IsChecked := not CheckBox_ShowGrid.IsChecked;
  PaintBox_Map.Repaint;
end;

procedure TFormMain.Action_SmoothLineExecute(Sender: TObject);
begin
  CheckBox_SmoothLine.IsChecked := not CheckBox_SmoothLine.IsChecked;
end;

procedure TFormMain.ActionList1Update(Action: TBasicAction; var Handled: Boolean);
begin
  Rectangle_Options.Enabled :=        not FLockMapFlag;
  Rectangle_CustomWeight.Enabled :=   not FLockMapFlag;
  Action_Highleght.Enabled :=         not FLockMapFlag;
  Button_Heighlight.Enabled :=        not FLockMapFlag;
  Action_Options.Enabled :=           not FLockMapFlag;
  Action_ResetMap.Enabled :=          not FLockMapFlag;
  Action_CustomWeight.Enabled :=      not FLockMapFlag;
  Action_RestoreWeights.Enabled :=    FBackup.IsAvailable;
  Action_CustomApplyToAll.Enabled :=  False;                                    // Reserved ...
  Layout_WeightGroup.Visible :=       not FLockMapFlag;
  StatusBar_Map.Visible :=            not FLockMapFlag;
  TrackBar_CellWeight.Enabled :=      CheckBox_WeightCell.IsChecked;
  Action_CustomApplayToMap.Enabled := ListBox_CustomWeights.Items.Count > 0;

  with CheckBox_HeatMap do
  begin
    OnChange  := nil;
    IsChecked := IsChecked and (FPathFinder.Kind <> TTileMapKind.mkHexagonal);
    OnChange  := CheckBox_WeightsChange;
    Enabled   := (FPathFinder <> nil) and (FPathFinder.Kind <> TTileMapKind.mkHexagonal);
  end;
end;

procedure TFormMain.Action_AnalysisExecute(Sender: TObject);
begin
  CheckBox_Weights.IsChecked := not CheckBox_Weights.IsChecked;
  // ------------------------------------------------------------------------ //
  PaintBox_Map.Repaint;
  // ------------------------------------------------------------------------ //
end;

procedure TFormMain.Action_CenterMapExecute(Sender: TObject);
begin
  if FPathFinder <> nil then
  begin
    CenterMap;
    PaintBox_Map.Repaint;
  end;
end;

procedure TFormMain.Action_CustomColorExecute(Sender: TObject);
begin
  CustomColorFlag := not FCustomColorFlag;
end;

procedure TFormMain.Action_FIlterBuildsExecute(Sender: TObject);
begin
  CheckBox_FilterBD.IsChecked := not CheckBox_FilterBD.IsChecked;
end;

procedure TFormMain.Action_HelpExecute(Sender: TObject);
begin
  ShowFixedMsg('Help', '');
end;

procedure TFormMain.Action_LoadMapExecute(Sender: TObject);
begin
  HideCustomWeight(0);

  if FFirstTileFlag then
  begin
    FFirstTileFlag := False;
    Action_HelpExecute(self);
  end;

  OpenDialog_Map.InitialDir :=  ParamStr(0);
  OpenDialog_Map.Filter :=      TBitmapCodecManager.GetFilterString;
  OpenDialog_Map.FilterIndex := 1;
  if OpenDialog_Map.Execute then
  begin
    FLockMapFlag := False;                                                      // Only UnLockFlag / Exclusive ....
    FBackgroundBitmap.LoadFromFile(OpenDialog_Map.FileName);
    InitializeDrawPath(True);
    Path_Compass.Visible :=  True;
  end;
end;

procedure TFormMain.Action_OptionsExecute(Sender: TObject);
begin
  if MultiView_Options.IsShowed
    then MultiView_Options.HideMaster
    else MultiView_Options.ShowMaster;
end;

procedure TFormMain.Action_ResetMapExecute(Sender: TObject);
begin
  HideCustomWeight(0);
  InitializeDrawPath(True);
end;

{ ApplyTerrainCustomization / Stack Manager for Custom Weight   -------------- }

procedure TFormMain.TrackBar_CustomOffsetChange(Sender: TObject);
begin
  FCustomOffSet := Trunc(TrackBar_CustomOffset.Value);
  Label_CustomOffsetVal.Text := Format('%d', [FCustomOffSet]);
end;

procedure TFormMain.ApplyTerrainCustomization(const AFlag: Integer; const AStackName: string; const AWeight: Byte; const AValue: Integer = 0);
begin
  if FBackgroundBitmap.IsEmpty or (FPathFInder = nil) then Exit;
  if (AFlag = 1) and (not FWeightStackManager.IsStackValid(AStackName)) then Exit;

  { Backup ... }
  FBackup.Capture(FMapWeights, FPathFinder.Data, FPathFinder.Columns * FPathFinder.Rows);
  FLockMapFlag := True;

  var _applycount       := 0;
  var _applyvalue: Byte := IfThen(AValue=0, 0, 255);
      _applyvalue       := IIF.CastBool<Byte>(CheckBox_WeightCell.IsChecked, Byte(Trunc(TrackBar_CellWeight.Value)), _applyvalue);
  var _applykey: Byte   := IfThen(AValue=0, 0, 1);
  var _mapPtr: PByte    := FPathFinder.Data;
  var _wgtPtr: PByte    := @FMapWeights[0];

  var _stackarray: TArray<Byte>;
  //const _offset: Byte = 10;   kkk
  var _low: Byte :=  Max(0,   AWeight - FCustomOffSet);
  var _high: Byte := Min(255, AWeight + FCustomOffSet);
  // Add to Stack ----------------------------------------------------------- //
  if AFlag = 0
    then FWeightStackManager.PushToStackUsr_seq(AStackName, _low, _high, _applyvalue)
    else FWeightStackManager.GetFromCurrent_seq(AStackName, _low, _high, _applyvalue);
  // ------------------------------------------------------------------------ //
  TParallel.For(0, FPathFinder.Rows -1, procedure(Row: Integer)
  var
    _Idx: Integer;
    _weight: Byte;
  begin
    for var _x := 0 to FPathFinder.Columns - 1 do
    begin
      _Idx :=    Row * FPathFinder.Columns + _x;
      _weight := (_wgtPtr + _Idx)^;

      if (_weight >= _low) and (_weight <= _high) then
      begin
        TInterlocked.Increment(_applycount);
        (_mapPtr + _Idx)^ := Byte(_applykey);
        (_wgtPtr + _Idx)^ := _applyvalue;
      end;
    end;
  end);

  CustomColorFlag := False;
  FLockMapFlag := False;
  if _applycount > 0 then
  begin
    Label_CustomChanged.Text := Format('(✔ %d )', [_applycount]);
    UpdatePath(True);
  end;
end;

procedure TFormMain.Action_CustomWeightExecute(Sender: TObject);
begin
  var _pos: TPointF := Button__CustomWeights.LocalToAbsolute(PointF(Button__CustomWeights.Width / 2 , Button__CustomWeights.Height));
  Layout_CustomWeight.Position.X := _pos.X - (Layout_CustomWeight.Width / 2);
  Layout_CustomWeight.Position.Y := _pos.Y + 2;
  Layout_CustomWeight.Height := 220;
  Layout_CustomWeight.Visible := not Layout_CustomWeight.Visible;

  if Layout_CustomWeight.Visible then
  RefreshStackManager(0);
end;

procedure TFormMain.Action_RestoreWeightsExecute(Sender: TObject);
begin
  if FBackup.IsAvailable then
  begin
    FBackup.Restore(FMapWeights, FPathFinder.Data);

    ShowToastAlert('Restored to Backup');
    UpdatePath(True);
  end;
end;

procedure TFormMain.SetMapCategory(const Value: TMapCategory);
begin
  if FMapCategory <> Value then
  begin
    ComboBox_CustomWeight.Clear;
    ListBox_CustomWeights.Items.Clear;

    FMapCategory := Value;
    FStackFileName := ExtractFilePath(ParamStr(0))+C_CatJson[Value];

    try
      var _NewManager := TWeightStackManager.Create(C_Category[Value], FStackFileName);
      FreeAndNil(FWeightStackManager);
      FWeightStackManager := _NewManager;
    except
      on E: Exception do
      begin
        ShowMessage('Failed to create new category: ' + E.Message);
        Exit;
      end;
    end;

    if FileExists(FStackFileName) then
    begin
      FWeightStackManager.LoadFromFile(FStackFileName);
      RefreshStackManager(5);
    end;
  end;
end;

procedure TFormMain.ComboBox_CategoryChange(Sender: TObject);
begin
  var _index := ComboBox_Category.ItemIndex;
  if _index >= 0 then
  begin
    var _category: TMapCategory := FMapCategory;
    var _catfile: string := C_CatJson[TMapCategory(_index)];
    if TMapCategory(_index) <> _category then
    begin
      MapCategory := TMapCategory(_index);
    end;
  end;
end;

procedure TFormMain.ComboBox_CustomWeightChange(Sender: TObject);
begin
  if ComboBox_CustomWeight.ItemIndex >= 0 then
  begin
    var _name := ComboBox_CustomWeight.Items[ComboBox_CustomWeight.ItemIndex];
    Button_ApplyWeights.Enabled := FWeightStackManager.IsStackValid(_name);
    if not Button_ApplyWeights.Enabled then Exit;

    ListBox_CustomWeights.Items.Clear;
    var _Stack := FWeightStackManager.GetStack(_name);
    Text_CustomValue.Text := IntToStr(_Stack.Key);
    Label_TargetValues.Text := Format('Target Values (%d) : ', [_Stack.Count]);

    var _Array := _Stack.ToArray;
    if Length(_Array) > 0 then
      begin
        with ListBox_CustomWeights do
        for var _value in _Array do
          Items.Add(IntToStr(_value));
      end
    else
      ListBox_CustomWeights.Items.Clear;
  end;
end;

procedure TFormMain.RefreshStackManager(const AFlag: Integer = 0; const AName: string = '');
begin
  ComboBox_CustomWeight.Clear;
  for var _name in FWeightStackManager.GetNames do
  begin
    ComboBox_CustomWeight.Items.Add(_name);
  end;

  var _index := ComboBox_CustomWeight.Items.IndexOf(FWeightStackManager.CurrentName);
  if AName <> '' then
    _index := ComboBox_CustomWeight.Items.IndexOf(AName);
  if _index >= 0 then
    begin
      ComboBox_CustomWeight.ItemIndex := _index;                                // Update ListBox_CustomWeights.Items
    end
  else
    begin
      if ComboBox_CustomWeight.Items.Count > 0 then
      ComboBox_CustomWeight.ItemIndex := 0;                                     // Update ListBox_CustomWeights.Items
    end;
end;

procedure TFormMain.Action_CustomApplayToMapExecute(Sender: TObject);
begin
  var _stackname := '';
  var _index := ComboBox_CustomWeight.ItemIndex;
  if (_index >= 0) and (ListBox_CustomWeights.Items.Count > 0) then
  begin
    CustomColorFlag := False;
    _stackname := ComboBox_CustomWeight.Items[_index];
    var _Key := FWeightStackManager.GetStackKey(_stackname);
    ApplyTerrainCustomization(1, _stackname, FCurrentWeight, _Key);
    //Layout_CustomWeight.Visible := False;
  end;
end;

procedure TFormMain.Action_CustonRenameExecute(Sender: TObject);
begin
  if ComboBox_CustomWeight.ItemIndex >= 0 then
  begin
    var _oname := ComboBox_CustomWeight.Items[ComboBox_CustomWeight.ItemIndex];

    Edit_InputName.Text := _oname;
    with Layout_InputQuery do
    begin
      Position.X := Layout_CustomWeight.Position.X - Layout_InputQuery.Width + Layout_Category.Width;//  25;
      Position.Y := Layout_CustomWeight.Position.Y + 30;

      Visible := True;
      BringToFront;
    end;
  end;
end;

procedure TFormMain.Button_IQ_CancelClick(Sender: TObject);
begin
  Layout_InputQuery.SendToBack;
  Layout_InputQuery.Visible := False;
end;

procedure TFormMain.Button_IQ_OKClick(Sender: TObject);
begin
  var _old := ComboBox_CustomWeight.Items[ComboBox_CustomWeight.ItemIndex];
  var _new := Edit_InputName.Text;

  if _new <> '' then
  begin
    if Trim(LowerCase(_new)) = Trim(LowerCase(_old)) then
      begin
        ShowMessage('Warning - Same Name.');
        Exit;
      end;
    if FWeightStackManager.ChangeStackName(_old, _new) then
      begin
        RefreshStackManager(3, _new);
        ShowToastAlert(Format('%s > %s', [_old, _new]));
      end
    else
      ShowMessage('Failed to Change Name.');
  end;

  Layout_InputQuery.SendToBack;
  Layout_InputQuery.Visible := False;
end;

procedure TFormMain.Action_CustomRefreshCatExecute(Sender: TObject);
begin
  //
end;

procedure TFormMain.Action_CustomApplyToAllExecute(Sender: TObject);
begin
  //
end;

procedure TFormMain.Action_CustomDeleteExecute(Sender: TObject);
begin
  var _index := ComboBox_CustomWeight.ItemIndex;
  if _index < 0 then Exit;

  var _stackname := ComboBox_CustomWeight.Items[_index];
  FWeightStackManager.RemoveStack(_stackname);
  RefreshStackManager(1);
end;

procedure TFormMain.Button_CloseClick(Sender: TObject);
begin
  Layout_CustomWeight.Visible := False;
end;

procedure TFormMain.pm_ApplyToAllClick(Sender: TObject);
begin
  Action_CustomApplyToAllExecute(Self);
end;

procedure TFormMain.pm_ApplyToMapClick(Sender: TObject);
begin
  Action_CustomApplayToMapExecute(Self);
end;

procedure TFormMain.pm_ChangeNameClick(Sender: TObject);
begin
  Action_CustonRenameExecute(Self);
end;

procedure TFormMain.pm_DeleteClick(Sender: TObject);
begin
  Action_CustomDeleteExecute(Self);
end;

procedure TFormMain.pm_LoadFromFileClick(Sender: TObject);
begin
  OpenDialog_Custom.InitialDir := ParamStr(0);
  OpenDialog_Custom.FileName :=   ExtractFileName(FStackFileName);
  if OpenDialog_Custom.Execute then
  begin
    FWeightStackManager.LoadFromFile(OpenDialog_Custom.FileName);
    RefreshStackManager(4);
    ShowToastAlert('Category -'+ ExtractFileName(OpenDialog_Custom.FileName) );
  end;
end;

procedure TFormMain.pm_RefreshClick(Sender: TObject);
begin
  RefreshStackManager(6);
end;

procedure TFormMain.pm_SaveToFileClick(Sender: TObject);
begin
  SaveDialog_Custom.InitialDir:= ParamStr(0);
  SaveDialog_Custom.FileName :=  ExtractFileName(FStackFileName);
  if SaveDialog_Custom.Execute then
  begin
    FWeightStackManager.SaveToFile(SaveDialog_Custom.FileName);
    if FileExists(SaveDialog_Custom.FileName) then
      ShowToastAlert('Category -' + ExtractFileName(SaveDialog_Custom.FileName) );
  end;
end;

end.
