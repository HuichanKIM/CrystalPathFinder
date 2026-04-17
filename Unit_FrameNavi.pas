unit Unit_FrameNavi;

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
  FMX.Objects,
  FMX.Layouts,
  FMX.Controls.Presentation;

type
  TFrame_Navigator = class(TFrame)
    Layout_Navigator: TLayout;
    Rectangle_Navigator: TRectangle;
    Image_Navigator: TImage;
    Rectangle_Navi: TRectangle;
    Label1: TLabel;
    procedure Rectangle_NaviMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure Rectangle_NaviMouseLeave(Sender: TObject);
    procedure Rectangle_NaviMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure Rectangle_NaviMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
  private
    FNaviBitmap: TBitmap;
    FNaviPoint: TPointF;
    FNaviViewRect: TRectF;
    FNaviDragging: Boolean;
    FNaviZoom: Single;
    FNaviFlag: Integer;
    procedure SetNaviBitmap(const Value: TBitmap);
    procedure SetNaviFlag(const Value: Integer);
    procedure SetNaviViewRect(const Value: TRectF);
    procedure SetNaviZoom(const Value: Single);
    procedure UpdateNaviRect;
  public
    property NaviBitmap: TBitmap  read FNaviBitmap    write SetNaviBitmap;
    property NaviViewRect: TRectF read FNaviViewRect  write SetNaviViewRect;
    property NaviZoom: Single     read FNaviZoom      write SetNaviZoom;
    property NaviFlag: Integer    read FNaviFlag      write SetNaviFlag;
  end;

implementation

uses
  System.Math,
  Unit_Main;

{$R *.fmx}

procedure TFrame_Navigator.SetNaviBitmap(const Value: TBitmap);
begin
  FNaviBitmap := Value;
  if not Assigned(FNaviBitmap) or FNaviBitmap.IsEmpty then Exit;

  // Create thumbnails to match the size of Image_Navigator while maintaining proportions
  var _IW  := Image_Navigator.Width;
  var _IH  := Image_Navigator.Height;
  var _BW  := FNaviBitmap.Width;
  var _BH  := FNaviBitmap.Height;
  if (_BW <= 0) or (_BH <= 0) then Exit;

  // Reduce ratio retention (not to exceed Image_Navigator)
  var _Scale  := Min(_IW / _BW, _IH / _BH);
  var _ThumbW := Max(1, Trunc(_BW * _Scale));
  var _ThumbH := Max(1, Trunc(_BH * _Scale));

  var _Thumb  := FNaviBitmap.CreateThumbnail(_ThumbW, _ThumbH);
  try
    Image_Navigator.Bitmap.Assign(_Thumb);
  finally
    _Thumb.Free;
  end;
end;

{ Key: Draw a Viewport Square over Navigator  -------------------------------- }
// Update the viewport rectangle with each Zoom change
procedure TFrame_Navigator.UpdateNaviRect;
begin
  if not Assigned(FNaviBitmap) or FNaviBitmap.IsEmpty then Exit;
  if FNaviZoom <= 0 then Exit;

  var _ThumbW := Image_Navigator.Bitmap.Width;
  var _ThumbH := Image_Navigator.Bitmap.Height;
  var _BW     := FNaviBitmap.Width;
  var _BH     := FNaviBitmap.Height;
  if (_ThumbW <= 0) or (_ThumbH <= 0) then Exit;

  var _ScaleX := _ThumbW / _BW;
  var _ScaleY := _ThumbH / _BH;

  // Converting Viewport Square to Thumbnail Pixel Coordinates -------------- //
  var _VR := TRectF.Create(0,0,0,0);
  _VR.Left   := FNaviViewRect.Left   * _ScaleX;
  _VR.Top    := FNaviViewRect.Top    * _ScaleY;
  _VR.Right  := FNaviViewRect.Right  * _ScaleX;
  _VR.Bottom := FNaviViewRect.Bottom * _ScaleY;

  // Clamping into the thumbnail area --------------------------------------- //
  _VR.Left   := EnsureRange(_VR.Left,   0, _ThumbW);
  _VR.Top    := EnsureRange(_VR.Top,    0, _ThumbH);
  _VR.Right  := EnsureRange(_VR.Right,  0, _ThumbW);
  _VR.Bottom := EnsureRange(_VR.Bottom, 0, _ThumbH);

  if _VR.Right  <= _VR.Left  then _VR.Right  := _VR.Left  + 4;
  if _VR.Bottom <= _VR.Top   then _VR.Bottom := _VR.Top   + 4;

  // Rectangle_Navi is Descendent of Image_Navigator  ----------------------- //
  // Position = Image_Navigator Local Coordinates
  // The image behind the WrapMode= Center is rendered in the center of the control
  // Offset correction by thumbnail and Image_Navigator size difference
  var _OffX := (Image_Navigator.Width  - _ThumbW) / 2;
  var _OffY := (Image_Navigator.Height - _ThumbH) / 2;
  _OffX := Max(0, _OffX);
  _OffY := Max(0, _OffY);

  with Rectangle_Navi do
  begin
    Position.X := _OffX + _VR.Left;
    Position.Y := _OffY + _VR.Top;
    Width      := _VR.Width;
    Height     := _VR.Height;
  end;
end;

// Convert local (Rectangle_Navi) coordinates
// to Image_Navigator coordinate system and store them
procedure TFrame_Navigator.Rectangle_NaviMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if Button = TMouseButton.mbLeft then
  begin
    FNaviDragging := True;
    FNaviPoint := TPointF.Create(Rectangle_Navi.Position.X + X, Rectangle_Navi.Position.Y + Y);
  end;
end;

procedure TFrame_Navigator.Rectangle_NaviMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  if not FNaviDragging then Exit;
  if not Assigned(FNaviBitmap) or FNaviBitmap.IsEmpty then Exit;

  var _CurPos := TPointF.Create(Rectangle_Navi.Position.X + X, Rectangle_Navi.Position.Y + Y);
  var _Delta  := _CurPos - FNaviPoint;
  FNaviPoint  := _CurPos;

  var _ThumbW := Image_Navigator.Bitmap.Width;
  var _ThumbH := Image_Navigator.Bitmap.Height;
  var _BW     := FNaviBitmap.Width;
  var _BH     := FNaviBitmap.Height;
  if (_ThumbW <= 0) or (_ThumbH <= 0) then Exit;

  // Thumbnail pixel movement ¡æ Bitmap pixel movement
  var _DX := _Delta.X * (_BW / _ThumbW);
  var _DY := _Delta.Y * (_BH / _ThumbH);

  FormMain.MoveViewOffset(-_DX, -_DY);
end;

procedure TFrame_Navigator.Rectangle_NaviMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  FNaviDragging := False;
end;

procedure TFrame_Navigator.Rectangle_NaviMouseLeave(Sender: TObject);
begin
  FNaviDragging := False;
end;

procedure TFrame_Navigator.SetNaviFlag(const Value: Integer);
begin
  FNaviFlag := Value;
  // To DO ...
end;

procedure TFrame_Navigator.SetNaviViewRect(const Value: TRectF);
begin
  FNaviViewRect := Value;
  UpdateNaviRect;
end;

procedure TFrame_Navigator.SetNaviZoom(const Value: Single);
begin
  FNaviZoom := Value;
  UpdateNaviRect;
end;

end.

