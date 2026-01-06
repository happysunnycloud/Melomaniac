unit PlayListItemFrameUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Controls.Presentation, FMX.Objects;

type
  TPlayListItemFrame = class(TFrame)
    BaseLayout: TLayout;
    BackgroundRectangle: TRectangle;
    LeftLayout: TLayout;
    NumberLabel: TLabel;
    PathLabel: TLabel;
    ClientLayout: TLayout;
    TitleLabel: TLabel;
    ArtistLabel: TLabel;
    AlbumLabel: TLabel;
    FrameRectangle: TRectangle;
    RightLayout: TLayout;
    DurationLabel: TLabel;
    procedure BaseLayoutMouseEnter(Sender: TObject);
    procedure BaseLayoutMouseLeave(Sender: TObject);
  private
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

{$R *.fmx}

uses
    StringToolsUnit
  ;

{ TPlayListItemFrame }

procedure TPlayListItemFrame.BaseLayoutMouseEnter(Sender: TObject);
begin
  FrameRectangle.Visible := true;
end;

procedure TPlayListItemFrame.BaseLayoutMouseLeave(Sender: TObject);
begin
  FrameRectangle.Visible := false;
end;

constructor TPlayListItemFrame.Create(AOwner: TComponent);
begin
  inherited;

  Name := TStringTools.GenIdent('PlayListItemFrame');
  FrameRectangle.Stroke.Color := TAlphaColorRec.Limegreen;
  FrameRectangle.Visible := false;
end;

end.
