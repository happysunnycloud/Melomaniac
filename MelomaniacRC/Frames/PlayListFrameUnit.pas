unit PlayListFrameUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Controls.Presentation, FMX.Objects,
  CommonTypesUnit, {SafeQueueThread,}
  System.Generics.Collections,
  PlayListItemFrameUnit, FMX.Edit
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
    FilterLayout: TLayout;
    FilterEdit: TEdit;
    ClearButton: TButton;
    procedure NextButtonClick(Sender: TObject);
    procedure PrevButtonClick(Sender: TObject);
    procedure FilterEditKeyUp(Sender: TObject; var Key: Word;
      var KeyChar: WideChar; Shift: TShiftState);
    procedure ClearButtonClick(Sender: TObject);
  private
    FStartPageIndex: Integer;
    FFinishPageIndex: Integer;
    FCurrentPageIndex: Integer;

    FPlayItemsList: TPlayItemsList;
    FFilteredPlayItemsList: TPlayItemsList;
    FOnPlayListItemClick: TNotifyEvent;
    FItemControlDict: TDictionary<String, TPlayListItemFrame>;

    FCurrentCompositonPath: String;

    procedure OnPlayListItemClickInternal(Sender: TObject);
    procedure SetFocusedItem(const APlayListItemFrame: TPlayListItemFrame);
    {$IFDEF ANDROID}
    procedure DoPlayListItemTap(Sender: TObject; const Point: TPointF);
    {$ENDIF}

     function GetPlayItemsList: TPlayItemsList;

     procedure BuildPage(const APageIndex: Integer);
     procedure ScrollTo(const ACompositionPath: String);
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

    procedure BuildPlayList(const ACompositonPath: String);

    procedure HighlightComposition(const ACompositionPath: String);

    property PlayItemsList: TPlayItemsList
      read GetPlayItemsList;

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

procedure TPlayListFrame.ClearButtonClick(Sender: TObject);
begin
  FilterEdit.Text := '';

  HighlightComposition(FCurrentCompositonPath);
end;

constructor TPlayListFrame.Create(AOwner: TComponent);
begin
  FItemControlDict := TDictionary<String, TPlayListItemFrame>.Create;
  FPlayItemsList := TPlayItemsList.Create;
  FFilteredPlayItemsList := TPlayItemsList.Create;
  FOnPlayListItemClick := nil;

  FStartPageIndex := -1;
  FFinishPageIndex := -1;
  FCurrentPageIndex := -1;

  FCurrentCompositonPath := '';

  inherited Create(AOwner);
end;

destructor TPlayListFrame.Destroy;
begin
  FreeAndNil(FItemControlDict);
  FPlayItemsList.Clear;
  FreeAndNil(FPlayItemsList);
  FreeAndNil(FFilteredPlayItemsList);

  inherited;
end;

procedure TPlayListFrame.FilterEditKeyUp(Sender: TObject; var Key: Word;
  var KeyChar: WideChar; Shift: TShiftState);
var
  PlayItem: TPlayItem;
  SubStr: String;
begin
  if not FilterEdit.Text.IsEmpty then
  begin
    SubStr := Trim(FilterEdit.Text).ToUpper;
    FFilteredPlayItemsList.DeleteRange(0, FFilteredPlayItemsList.Count);
    for PlayItem in FPlayItemsList do
    begin
      if Pos(SubStr, PlayItem.Path.ToUpper) > 0 then
        FFilteredPlayItemsList.Add(PlayItem);
    end;

    BuildPage(0);
  end
  else
    ClearButton.OnClick(nil);
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

procedure TPlayListFrame.NextButtonClick(Sender: TObject);
var
  CurrentPageIndex: Integer;
begin
  CurrentPageIndex := FCurrentPageIndex + 1;
  if CurrentPageIndex > FFinishPageIndex then
    Exit;

  BuildPage(CurrentPageIndex);
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

  if not Assigned(APlayListItemFrame) then
    Exit;

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

function TPlayListFrame.GetPlayItemsList: TPlayItemsList;
begin
  Result := FPlayItemsList;
  if not FilterEdit.Text.IsEmpty then
    Result := FFilteredPlayItemsList;
end;

procedure TPlayListFrame.BuildPage(const APageIndex: Integer);
var
  StartIndex, FinishIndex: Integer;
  i: Integer;
  PlayItem: TPlayItem;
begin
  FItemControlDict.Clear;
  PlayListScrollBox.Clear;

  FCurrentPageIndex := APageIndex;

  StartIndex := FCurrentPageIndex * PAGE_LENGTH;

  if StartIndex > (PlayItemsList.Count - 1) then
    Exit;

  PagesLabel.Text := (FCurrentPageIndex + 1).ToString + ' / ' +
    (FFinishPageIndex + 1).ToString;

  FinishIndex := Min(StartIndex + PAGE_LENGTH - 1, PlayItemsList.Count - 1);

  PlayListScrollBox.BeginUpdate;
  try
    for i := StartIndex to FinishIndex do
    begin
      PlayItem := PlayItemsList[i];
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

  ScrollTo(FCurrentCompositonPath);
end;

procedure TPlayListFrame.BuildPlayList(const ACompositonPath: String);
begin
  FStartPageIndex := 0;
  FFinishPageIndex := FPlayItemsList.Count div PAGE_LENGTH;
  FCurrentPageIndex := 0;

  HighlightComposition(ACompositonPath);
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

procedure TPlayListFrame.HighlightComposition(
  const ACompositionPath: String);
var
  Index: Integer;
  PageIndex: Integer;
begin
  FCurrentCompositonPath := ACompositionPath;

  Index := PlayItemsList.IndexOfComposition(FCurrentCompositonPath);
  if Index < 0 then
  begin
    SetFocusedItem(nil);
//    raise Exception.Create('Composition not found');
  end;

  PageIndex := 0;
  if Index > 0 then
    PageIndex := Index div PAGE_LENGTH;

  BuildPage(PageIndex);
end;

end.
