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
    FocusFrameRectangle: TRectangle;
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
  FocusFrameRectangle.Visible := true;
end;

procedure TPlayListItemFrame.BaseLayoutMouseLeave(Sender: TObject);
begin
  FocusFrameRectangle.Visible := false;
end;

constructor TPlayListItemFrame.Create(AOwner: TComponent);
begin
  inherited;

  Name := TStringTools.GenIdent('PlayListItemFrame');
  FocusFrameRectangle.Stroke.Color := TAlphaColorRec.Limegreen;
  FocusFrameRectangle.Visible := false;
end;

end.
