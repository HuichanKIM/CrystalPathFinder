program CrystalPathfinder;

{ **************************************************************************** }
{ Crystal Path Finder - High Performance Version for Delphi 13 Florence        }
{ Optimized with Binary Heap, Minimal Memory Allocation and Parallel Safety    }
{ ---------------------------------------------------------------------------- }
{                                                                              }
{ This is inspired by https://github.com/d-mozulyov/CrystalPathFinding         }
{ **************************************************************************** }

uses
  FastMM4,
  System.StartUpCopy,
  FMX.Forms,
  uCommons in 'uCommons.pas',
  CrystalPathFinding_ex in 'CrystalPathFinding_ex.pas',
  Unit_Main in 'Unit_Main.pas' {FormMain},
  Unit_Resources in 'Unit_Resources.pas' {Form_Resources};


{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.CreateForm(TForm_Resources, Form_Resources);
  Application.Run;
end.
