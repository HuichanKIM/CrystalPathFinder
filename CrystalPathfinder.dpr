program CrystalPathfinder;

{ **************************************************************************** }
{ Crystal Path Finder - High Performance Version for Delphi 13 Florence        }
{ Optimized with Binary Heap, Minimal Memory Allocation and Parallel Safety    }
{ **************************************************************************** }

uses
  FastMM4,
  System.StartUpCopy,
  FMX.Types,
  FMX.Forms,
  uCommons in 'uCommons.pas',
  uCrystalPathFinding in 'uCrystalPathFinding.pas',
  uWeightStackManager in 'uWeightStackManager.pas',
  Unit_Main in 'Unit_Main.pas' {FormMain},
  Unit_Resources in 'Unit_Resources.pas' {Form_Resources},
  Unit_FrameNavi in 'Unit_FrameNavi.pas' {Frame_Navigator: TFrame},
  Unit_Histogram in 'Unit_Histogram.pas' {Frame_Histogram: TFrame};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.CreateForm(TForm_Resources, Form_Resources);
  Application.Run;
end.
