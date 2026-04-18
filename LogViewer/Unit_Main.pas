unit Unit_Main;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  FMX.Layouts,
  FMX.Platform.Win,
  Winapi.Windows,
  Winapi.Messages,
  Winapi.CommCtrl,
  FMX.Memo.Types,
  FMX.ScrollBox,
  FMX.Memo, FMX.ListBox,
  Unit_Logger;

type
  TForm_Main = class(TForm)
    Layout_ToolButtons: TLayout;
    Layout2: TLayout;
    StatusBar1: TStatusBar;
    StyleBook1: TStyleBook;
    Button_Save: TButton;
    Button_Help: TButton;
    Button3: TButton;
    SaveDialog1: TSaveDialog;
    Label_Date: TLabel;
    ListBox_Log: TListBox;
    procedure FormCreate(Sender: TObject);
    procedure Button_SaveClick(Sender: TObject);
    procedure Button_HelpClick(Sender: TObject);
  protected
  private
  end;

var
  Form_Main: TForm_Main;

implementation

{$R *.fmx}

procedure TForm_Main.FormCreate(Sender: TObject);
begin
  Caption := 'RealTimeLogViewer';
  Label_Date.Text := ' 🟢 Log Date/Time ' + FormatDateTime('[yy.mm.dd hh:nn:ss] ', Now);

  // Initialize logger with ListBox and current form
  TLogger.Init(ListBox_Log, Self);

  var hWnd := FormToHWND(Self);// = FmxHandleToHWND(Self.Handle);
  TLogger.Log('======================================================', 0);
  TLogger.Log('RealTimeLogViewer', 0);
  TLogger.Log(Format('Form HWND     : 0x%x',  [hWnd]), 0);
  TLogger.Log('======================================================', 0);
  TLogger.Log('', 0);
end;

procedure TForm_Main.Button_HelpClick(Sender: TObject);
begin
  var _index := Random(9);
  TLogger.Log(Format('Test %d',[_index]), _index);
end;

procedure TForm_Main.Button_SaveClick(Sender: TObject);
begin
  SaveDialog1.InitialDir := ParamStr(0);
  if SaveDialog1.Execute then
  begin
    ListBox_Log.Items.SaveToFile(SaveDialog1.FileName, TEncoding.UTF8);
  end;
end;

end.

