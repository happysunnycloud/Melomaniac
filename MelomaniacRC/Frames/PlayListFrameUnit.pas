unit PlayListFrameUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Controls.Presentation, FMX.Objects,
  CommonTypesUnit, {SafeQueueThread,}
  System.Generics.Collections,
  PlayListItemFrameUnit
  ;

type
  TPlayListFrame = class(TFrame)
    ButtonsLayout: TLayout;
    CloseButton: TButton;
    PlayListScrollBox: TScrollBox;
    BackgoundRectangle: TRectangle;
  private
//    FSafeQueueThreadSignal: ISafeQueueThreadSignal;
    FPlayItemsList: TPlayItemsList;
    FOnPlayListItemClick: TNotifyEvent;
    FItemControlDect: TDictionary<String, TPlayListItemFrame>;

    procedure OnPlayListItemClickInternal(Sender: TObject);
    procedure SetFocusedItem(const APlayListItemFrame: TPlayListItemFrame);
    {$IFDEF ANDROID}
    procedure DoPlayListItemTap(Sender: TObject; const Point: TPointF);
    {$ENDIF}
  public
    constructor Create(AOwner: TComponent); reintroduce;
    destructor Destroy; override;

    procedure AddItem(
      const APath: String;
      const ATitle: String;
      const AArtist: String;
      const AAlbum: String;
      const ADuration: String);

    procedure BuildPlayList;

    procedure ScrollTo(const ACompositionPath: String);

    property PlayItemsList: TPlayItemsList
      read FPlayItemsList write FPlayItemsList;

    property OnPlayListItemClick: TNotifyEvent
      read FOnPlayListItemClick write FOnPlayListItemClick;
  end;

implementation

{$R *.fmx}

uses
    StringToolsUnit
  , FMX.SingleSoundUnit
  , FMX.ControlToolsUnit
  ;

const
  NON_FOCUSED_COLOR = $FFE0E0E0;
  FOCUSED_COLOR = $FFBCFF9E;

{ TPlayListFrame }

constructor TPlayListFrame.Create(AOwner: TComponent);
begin
  FItemControlDect := TDictionary<String, TPlayListItemFrame>.Create;
  FPlayItemsList := TPlayItemsList.Create;
  FOnPlayListItemClick := nil;

  inherited Create(AOwner);
end;

destructor TPlayListFrame.Destroy;

begin
  FreeAndNil(FItemControlDect);
  FPlayItemsList.Clear;
  FreeAndNil(FPlayItemsList);

  inherited;
end;

procedure TPlayListFrame.OnPlayListItemClickInternal(Sender: TObject);
begin
  SetFocusedItem(TPlayListItemFrame(Sender));

  if Assigned(FOnPlayListItemClick) then
    FOnPlayListItemClick(Sender);
end;

procedure TPlayListFrame.SetFocusedItem(
  const APlayListItemFrame: TPlayListItemFrame);
begin
  PlayListScrollBox.EnumControls(
    function (AControl: TControl): TEnumControlsResult
    var
      PlayListItemFrame: TPlayListItemFrame;
    begin
      Result := TEnumControlsResult.Continue;

      if AControl is TPlayListItemFrame then
      begin
        PlayListItemFrame := TPlayListItemFrame(AControl);
        PlayListItemFrame.BackgroundRectangle.Fill.Color := NON_FOCUSED_COLOR;
      end;
    end);

  APlayListItemFrame.BackgroundRectangle.Fill.Color := FOCUSED_COLOR;
end;
{$IFDEF ANDROID}
procedure TPlayListFrame.DoPlayListItemTap(
  Sender: TObject; const Point: TPointF);
begin
  OnPlayListItemClickInternal(Sender);
end;
{$ENDIF}
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
  FItemControlDect.Add(APath, PlayListItemFrame);
  PlayListItemFrame.CompositionPath := APath;
  PlayListItemFrame.Align := TAlignLayout.Bottom;
  PlayListItemFrame.Name := TStringTools.GenIdent('PlayListItemFrame', '_');
  PlayListItemFrame.Parent := PlayListScrollBox;
  PlayListItemFrame.PathLabel.Text :=
    ExtractFileName(PlayListItemFrame.CompositionPath);
  PlayListItemFrame.TitleLabel.Text := ATitle;
  PlayListItemFrame.ArtistLabel.Text := AArtist;
  PlayListItemFrame.AlbumLabel.Text := AAlbum;
  PlayListItemFrame.DurationLabel.Text :=
    TSingleSound.GetHumanTime(ADuration.ToInt64);
  PlayListItemFrame.NumberLabel.Text :=
    PlayListScrollBox.Content.ControlsCount.ToString;

  PlayListItemFrame.Align := TAlignLayout.Top;

  PlayListItemFrame.FocusFrameRectangle.Fill.Color := TAlphaColorRec.Crimson;
  PlayListItemFrame.FocusFrameRectangle.Visible := false;

  {$IFDEF MSWINDOWS}
  PlayListItemFrame.OnClick := OnPlayListItemClickInternal;
  {$ELSE IFDEF ANDROID}
  PlayListItemFrame.OnTap := DoPlayListItemTap;
  {$ENDIF}
end;

procedure TPlayListFrame.BuildPlayList;
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

procedure TPlayListFrame.ScrollTo(const ACompositionPath: String);
var
  PlayListItemFrame: TPlayListItemFrame;
begin
  if not FItemControlDect.TryGetValue(ACompositionPath, PlayListItemFrame) then
    Exit;

  PlayListScrollBox.ScrollTo(PlayListItemFrame);

  SetFocusedItem(PlayListItemFrame);
end;

end.
