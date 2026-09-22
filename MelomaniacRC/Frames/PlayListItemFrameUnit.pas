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
    FocusFrameRectangle: TRectangle;
    procedure FrameMouseEnter(Sender: TObject);
    procedure FrameMouseLeave(Sender: TObject);
  private
    FCompositionPath: String;
  public
    property CompositionPath: String
      read FCompositionPath write FCompositionPath;
  end;

implementation

{$R *.fmx}

procedure TPlayListItemFrame.FrameMouseEnter(Sender: TObject);
begin
  FocusFrameRectangle.Visible := true;
//  BackgroundRectangle.Fill.Color := TAlphaColorRec.Limegreen;
end;

procedure TPlayListItemFrame.FrameMouseLeave(Sender: TObject);
begin
  FocusFrameRectangle.Visible := false;
//  BackgroundRectangle.Fill.Color := $FFE0E0E0;
end;

end.
