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
    PagesLayout: TLayout;
    PrevButton: TButton;
    NextButton: TButton;
    PagesLabel: TLabel;
    procedure NextButtonClick(Sender: TObject);
    procedure PrevButtonClick(Sender: TObject);
  private
    FStartPageIndex: Integer;
    FFinishPageIndex: Integer;
    FCurrentPageIndex: Integer;

    FPlayItemsList: TPlayItemsList;
    FOnPlayListItemClick: TNotifyEvent;
    FItemControlDict: TDictionary<String, TPlayListItemFrame>;

    procedure OnPlayListItemClickInternal(Sender: TObject);
    procedure SetFocusedItem(const APlayListItemFrame: TPlayListItemFrame);
    {$IFDEF ANDROID}
    procedure DoPlayListItemTap(Sender: TObject; const Point: TPointF);
    {$ENDIF}

     procedure BuildPage(const APageIndex: Integer); overload;
  public
    constructor Create(AOwner: TComponent); reintroduce;
    destructor Destroy; override;

    procedure AddItem(
      const AIndex: Integer;
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
    System.Math
  , ConstantsUnit
  , StringToolsUnit
  , FMX.SingleSoundUnit
  , FMX.ControlToolsUnit
  ;

const
  NON_FOCUSED_COLOR = $FFE0E0E0;
  FOCUSED_COLOR = $FFBCFF9E;
  PAGE_LENGTH = 10;

{ TPlayListFrame }

constructor TPlayListFrame.Create(AOwner: TComponent);
begin
  FItemControlDict := TDictionary<String, TPlayListItemFrame>.Create;
  FPlayItemsList := TPlayItemsList.Create;
  FOnPlayListItemClick := nil;

  FStartPageIndex := -1;
  FFinishPageIndex := -1;
  FCurrentPageIndex := -1;

  inherited Create(AOwner);
end;

destructor TPlayListFrame.Destroy;
begin
  FreeAndNil(FItemControlDict);
  FPlayItemsList.Clear;
  FreeAndNil(FPlayItemsList);

  inherited;
end;

procedure TPlayListFrame.NextButtonClick(Sender: TObject);
var
  CurrentPageIndex: Integer;
begin
  CurrentPageIndex := FCurrentPageIndex + 1;
  if CurrentPageIndex > FFinishPageIndex then
    Exit;

  FCurrentPageIndex := CurrentPageIndex;
  BuildPage(FCurrentPageIndex);
end;

procedure TPlayListFrame.OnPlayListItemClickInternal(Sender: TObject);
begin
  SetFocusedItem(TPlayListItemFrame(Sender));

  if Assigned(FOnPlayListItemClick) then
    FOnPlayListItemClick(Sender);
end;

procedure TPlayListFrame.PrevButtonClick(Sender: TObject);
var
  CurrentPageIndex: Integer;
begin
  CurrentPageIndex := FCurrentPageIndex - 1;
  if CurrentPageIndex < 0 then
    Exit;

  FCurrentPageIndex := CurrentPageIndex;

  BuildPage(FCurrentPageIndex);
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
  const AIndex: Integer;
  const APath: String;
  const ATitle: String;
  const AArtist: String;
  const AAlbum: String;
  const ADuration: String);
var
  PlayListItemFrame: TPlayListItemFrame;
begin
  PlayListItemFrame := TPlayListItemFrame.Create(PlayListScrollBox);
  FItemControlDict.Add(APath, PlayListItemFrame);
  PlayListItemFrame.CompositionPath := APath;
  PlayListItemFrame.Align := TAlignLayout.Bottom;
  PlayListItemFrame.Name := TStringTools.GenIdent('PlayListItemFrame', '_');
  PlayListItemFrame.Parent := PlayListScrollBox;
  PlayListItemFrame.PathLabel.Text := TStringTools.ExtractFileName(
    PlayListItemFrame.CompositionPath, REMOTE_PATH_SPLITTER);
  PlayListItemFrame.TitleLabel.Text := ATitle;
  PlayListItemFrame.ArtistLabel.Text := AArtist;
  PlayListItemFrame.AlbumLabel.Text := AAlbum;
  PlayListItemFrame.DurationLabel.Text :=
    TSingleSound.GetHumanTime(ADuration.ToInt64);
  PlayListItemFrame.NumberLabel.Text := (AIndex + 1).ToString;

  PlayListItemFrame.Align := TAlignLayout.Top;

  PlayListItemFrame.FocusFrameRectangle.Fill.Color := TAlphaColorRec.Crimson;
  PlayListItemFrame.FocusFrameRectangle.Visible := false;

  {$IFDEF MSWINDOWS}
  PlayListItemFrame.OnClick := OnPlayListItemClickInternal;
  {$ELSE IFDEF ANDROID}
  PlayListItemFrame.OnTap := DoPlayListItemTap;
  {$ENDIF}
end;

procedure TPlayListFrame.BuildPage(const APageIndex: Integer);
var
  StartIndex, FinishIndex: Integer;
  i: Integer;
  PlayItem: TPlayItem;
begin
  StartIndex := APageIndex * PAGE_LENGTH;

  if StartIndex >= (FPlayItemsList.Count - 1) then
    Exit;

  FItemControlDict.Clear;
  PlayListScrollBox.Clear;

  PagesLabel.Text := (APageIndex + 1).ToString + ' / ' +
    (FFinishPageIndex + 1).ToString;

  FinishIndex := Min(StartIndex + PAGE_LENGTH, FPlayItemsList.Count - 1);

  PlayListScrollBox.BeginUpdate;
  try
    for i := StartIndex to FinishIndex do
    begin
      PlayItem := FPlayItemsList[i];
      AddItem(
        i,
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

procedure TPlayListFrame.BuildPlayList;
begin
  FStartPageIndex := 0;
  FFinishPageIndex := FPlayItemsList.Count div PAGE_LENGTH;
  FCurrentPageIndex := 0;

  BuildPage(0);
end;

procedure TPlayListFrame.ScrollTo(const ACompositionPath: String);
var
  PlayListItemFrame: TPlayListItemFrame;
begin
  if not FItemControlDict.TryGetValue(ACompositionPath, PlayListItemFrame) then
    Exit;

  PlayListScrollBox.ScrollTo(PlayListItemFrame);

  SetFocusedItem(PlayListItemFrame);
end;

end.
