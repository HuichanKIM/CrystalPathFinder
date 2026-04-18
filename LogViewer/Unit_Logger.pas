unit Unit_Logger;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.UIConsts,
  SYstem.Classes,
  FMX.ListBox,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  Winapi.Windows,
  Winapi.Messages,
  FMX.Platform.Win;

type
  TLogger = class
  private
    class var
      FListBox: TListBox;
    class var
      FOldWndProc: Pointer;
    class function NewWndProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall; static;
  public
    class procedure Init(const AListBox: TListBox; const AForm: TForm);
    class procedure Log(const Msg: string; const Level: Integer);
  end;

implementation

uses
  SYstem.Math,
  System.Threading;

const
  C_Imojis: array [0..9] of string = ('', '🌟', '🔔', '🚩', '🔍', '🚀', '📦', '❌', '✔', '❓');

class function TLogger.NewWndProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin
  if uMsg = WM_COPYDATA then
  begin
    var _cds := PCopyDataStruct(lParam);
    var _s   := PChar(_cds.lpData);
    Log(_s, _cds.dwData); // dwData used as log level or variable value
    Result := 1;

    Exit;
  end;

  // Default message handling
  Result := CallWindowProc(FOldWndProc, hWnd, uMsg, wParam, lParam);
end;

class procedure TLogger.Init(const AListBox: TListBox; const AForm: TForm);
begin
  FListBox := AListBox;
  // Hook window procedure to intercept WM_COPYDATA
  FOldWndProc := Pointer(SetWindowLongPtr(FormToHWND(AForm), GWLP_WNDPROC, LONG_PTR(@NewWndProc)));
end;


class procedure TLogger.Log(const Msg: string; const Level: Integer);
const
  SCROLL_TOLERANCE = 10; // a slight margin of error
begin
  if not Assigned(FListBox) then Exit;

  var _Level := EnsureRange(Level, 0, 9);
  var _time  := FormatDateTime('yy.mm.dd hh:nn:ss', Now);
  var _Item: TListBoxItem := TListBoxItem.Create(FListBox);
  _Item.Text := Format('%s - %s [%d] %s', [_time, C_Imojis[_Level], _Level, Msg]);

  case _Level of
    0: _Item.StyleLookup := 'INFOItemStyle';   // White text style
    1: _Item.StyleLookup := 'WARNItemStyle';   // Orange text style
    2: _Item.StyleLookup := 'ERRORItemStyle';  // Red text style
  else
    _Item.StyleLookup := 'INFOItemStyle';      // Fallback
  end;

  var _ShouldScroll := (FListBox.Count > 0) and
                       (FListBox.ViewportPosition.Y >=
                       (FListBox.ContentBounds.Height - FListBox.Height - SCROLL_TOLERANCE));

  FListBox.BeginUpdate;
  try
    FListBox.AddObject(_Item);//.InsertObject(0, _Item);
  finally
    FListBox.EndUpdate;
  end;

  if _ShouldScroll then
  begin
    var _CapturedItem := _Item;
    var _CapturedList := FListBox;
    TThread.Queue(nil, procedure
    begin
      _CapturedList.RecalcSize;
      _CapturedList.ScrollToItem(_CapturedItem);
    end);
  end;
end;

end.

