program LogViewer;

uses
  System.StartUpCopy,
  FMX.Forms,
  Unit_Main in 'Unit_Main.pas' {Form_Main};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm_Main, Form_Main);
  Application.Run;
end.
