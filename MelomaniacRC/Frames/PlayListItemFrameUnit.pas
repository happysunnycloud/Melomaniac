unit PlayListItemFrameUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, FMX.Objects;

type
  TPlayListItemFrame = class(TFrame)
    ClientLayout: TLayout;
    PathLabel: TLabel;
    TitleLabel: TLabel;
    LeftLayout: TLayout;
    RightLayout: TLayout;
    ArtistLabel: TLabel;
    AlbumLabel: TLabel;
    NumberLabel: TLabel;
    DurationLabel: TLabel;
    BackgroundRectangle: TRectangle;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.fmx}

end.
