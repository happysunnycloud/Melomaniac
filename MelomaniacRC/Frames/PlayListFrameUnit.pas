unit PlayListFrameUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Controls.Presentation, FMX.Objects,
  CommonTypesUnit, SafeQueueThread;

type
  TPlayListFrame = class(TFrame)
    ButtonsLayout: TLayout;
    CloseButton: TButton;
    PlayListScrollBox: TScrollBox;
    BackgoundRectangle: TRectangle;
  private
    FSafeQueueThreadSignal: ISafeQueueThreadSignal;
    FPlayItemsList: TPlayItemsList;
  public
    constructor Create(AOwner: TComponent); reintroduce;
    destructor Destroy; override;

    procedure AddItem(
      const APath: String;
      const ATitle: String;
      const AArtist: String;
      const AAlbum: String;
      const ADuration: String);

    procedure BuilPlayList;

    property PlayItemsList: TPlayItemsList
      read FPlayItemsList write FPlayItemsList;
  end;

implementation

{$R *.fmx}

uses
    PlayListItemFrameUnit
  , StringToolsUnit
  ;

{ TPlayListFrame }

constructor TPlayListFrame.Create(AOwner: TComponent);
begin
  FSafeQueueThreadSignal := TSafeQueueThreadSignal.Create;
  FPlayItemsList := TPlayItemsList.Create;

  inherited Create(AOwner);
end;

destructor TPlayListFrame.Destroy;

begin
  FSafeQueueThreadSignal.Deactivate;
  FPlayItemsList.Clear;
  FreeAndNil(FPlayItemsList);

  inherited;
end;

procedure TPlayListFrame.AddItem(
  const APath: String;
  const ATitle: String;
  const AArtist: String;
  const AAlbum: String;
  const ADuration: String);
var
  PlayListItemFrame: TPlayListItemFrame;
begin
  PlayListItemFrame := TPlayListItemFrame.Create(PlayListScrollBox);
  PlayListItemFrame.Align := TAlignLayout.Bottom;
  PlayListItemFrame.Name := TStringTools.GenIdent('PlayListItemFrame', '_');
  PlayListItemFrame.Parent := PlayListScrollBox;
  PlayListItemFrame.PathLabel.Text := APath;
  PlayListItemFrame.TitleLabel.Text := ATitle;

  PlayListItemFrame.ArtistLabel.Text := AArtist;
  PlayListItemFrame.AlbumLabel.Text := AAlbum;
  PlayListItemFrame.DurationLabel.Text := ADuration;

  PlayListItemFrame.NumberLabel.Text :=
    PlayListScrollBox.Content.ControlsCount.ToString;

  PlayListItemFrame.Align := TAlignLayout.Top;
end;

procedure TPlayListFrame.BuilPlayList;
var
  PlayItem: TPlayItem;
begin
  PlayListScrollBox.BeginUpdate;
  try
    for PlayItem in FPlayItemsList do
    begin
      AddItem(
        PlayItem.Path,
        PlayItem.Title,
        PlayItem.Artist,
        PlayItem.Album,
        PlayItem.Duration.ToString);
    end;
  finally
    PlayListScrollBox.EndUpdate;
  end;
end;

end.
