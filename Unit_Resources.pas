unit Unit_Resources;

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
  FMX.Objects, FMX.Layouts, FMX.StdCtrls, FMX.Edit, FMX.Controls.Presentation;

type
  TForm_Resources = class(TForm)
    Image_PosIcon_S: TImage;
    Image_PosIcon_F: TImage;
    Image_Logo0: TImage;
    Image1: TImage;
    Path1: TPath;
    Image_Logo1: TImage;
    Layout_InputQuery: TLayout;
    Rectangle1: TRectangle;
    Label1: TLabel;
    Label2: TLabel;
    Edit1: TEdit;
    Button1: TButton;
    Button2: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form_Resources: TForm_Resources;
  R_PosIconS, R_PosIconF: TBitmap;
  R_PosIconRectF: TRectF;

implementation

uses
  Unit_Main;

{$R *.fmx}

procedure TForm_Resources.FormCreate(Sender: TObject);
begin
  R_PosIconS := TBitmap.Create(Image_PosIcon_S.Bitmap.Width, Image_PosIcon_S.Bitmap.Height);
  R_PosIconS.Assign(Image_PosIcon_S.Bitmap);

  R_PosIconF := TBitmap.Create(Image_PosIcon_F.Bitmap.Width, Image_PosIcon_F.Bitmap.Height);
  R_PosIconF.Assign(Image_PosIcon_F.Bitmap);

  R_PosIconRectF := RectF(0,0, R_PosIconS.Width, R_PosIconS.Height);
end;

procedure TForm_Resources.FormDestroy(Sender: TObject);
begin
  R_PosIconS.Free;
  R_PosIconF.Free;
end;

end.
