unit PlayListFormUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  System.Generics.Collections,
  FMX.FormExtUnit,
//  FMX.FormExt.Types,
  FMX.Theme,
  PlayListItemFrameUnit,
  PlayListUnit
  ;

type
  TPlayListForm = class(TFormExt)
    ScrollBox: TScrollBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FPathControlDict: TDictionary<String, TControl>;
    FOnItemClick: TProc<String>;
//    procedure OnPlayListItemFrameClickHandler(Sender: TObject);
  public
    function AddFrame(
      const APath: String;
      const ATitle: String;
      const AArtist: String;
      const AAlbum: String;
      const ADuration: String): TPlayListItemFrame;
    procedure DeleteFrame(const APath: String);
    procedure Clear;
    procedure Select(const APath: String);
    procedure ScrollToItem(const APath: String);

    function GetPath(Sender: TObject): String;

    procedure RenumerateItems;

    procedure Refresh(const APlayList: TPlayList);

    property OnItemClick: TProc<String> read FOnItemClick write FOnItemClick;
  end;

var
  PlayListForm: TPlayListForm;

implementation

{$R *.fmx}

uses
    FMX.ControlToolsUnit
  , StateUnit
  , FMX.SingleSoundUnit
  , PlayListFormMouseHandlersUnit
  ;

{ TPlayListForm }

function TPlayListForm.GetPath(Sender: TObject): String;
var
  Control: TControl;
  PlayListItemFrame: TPlayListItemFrame;
  Path: String;
begin
  Result := '';
  Control := Sender as TControl;
  PlayListItemFrame := TControlTools.FindParentFrame(Control) as TPlayListItemFrame;
  if Assigned(PlayListItemFrame) then
  begin
    Path := PlayListItemFrame.PathLabel.Text;
    Select(Path);

    Result := Path;
  end;
end;

procedure TPlayListForm.RenumerateItems;
var
  Control: TControl;
  PlayListItemFrame: TPlayListItemFrame;
  i: Integer;
begin
  if ScrollBox.Content.ControlsCount = 0 then
    Exit;

  i := 0;
  ScrollBox.BeginUpdate;
  try
    for Control in ScrollBox.Content.Controls do
    begin
      Inc(i);

      PlayListItemFrame := Control as TPlayListItemFrame;
      PlayListItemFrame.NumberLabel.Text := i.ToString;
    end;
  finally
    ScrollBox.EndUpdate;
  end;
end;

procedure TPlayListForm.Refresh(const APlayList: TPlayList);
var
  PlayList: TPlayList absolute APlayList;
  PlayItemsList: TPlayItemsList;
  PlayItem: TPlayItem;
begin
  Clear;

  ScrollBox.BeginUpdate;
  try
    PlayItemsList := PlayList.LockList;
    try
      for PlayItem in PlayItemsList do
      begin
        AddFrame(
          PlayItem.Path,
          PlayItem.Title,
          PlayItem.Artist,
          PlayItem.Album,
          TSingleSound.GetHumanTime(PlayItem.Duration));
      end;
    finally
      PlayList.UnLockList;
    end;
  finally
    ScrollBox.EndUpdate;
  end;

  PlayListForm.RenumerateItems;
end;

function TPlayListForm.AddFrame(
  const APath: String;
  const ATitle: String;
  const AArtist: String;
  const AAlbum: String;
  const ADuration: String): TPlayListItemFrame;
var
  PlayListItemFrame: TPlayListItemFrame;
begin
  PlayListItemFrame := TPlayListItemFrame.Create(ScrollBox);
  PlayListItemFrame.Parent := ScrollBox;
  PlayListItemFrame.Align := TAlignLayout.Top;
  PlayListItemFrame.Visible := True;

  PlayListItemFrame.NumberLabel.Text := '0';
  PlayListItemFrame.PathLabel.Text := APath;
  PlayListItemFrame.TitleLabel.Text := ATitle;
  PlayListItemFrame.ArtistLabel.Text := AArtist;
  PlayListItemFrame.AlbumLabel.Text := AAlbum;
  PlayListItemFrame.DurationLabel.Text := ADuration;

  TPlayListFormMouseHandlers.ConnectHandlers([
    PlayListItemFrame.BaseLayout
   ]);

  FPathControlDict.Add(APath, PlayListItemFrame);

  Result := PlayListItemFrame;
end;

procedure TPlayListForm.DeleteFrame(const APath: String);
var
  Control: TControl;
begin
  FPathControlDict.TryGetValue(APath, Control);

  if not Assigned(Control) then
    Exit;

  ScrollBox.BeginUpdate;
  try
    ScrollBox.Content.RemoveObject(Control);
    ScrollBox.RealignContent;
  finally
    ScrollBox.EndUpdate;
  end;

  Control.Free;

  RenumerateItems;
end;

procedure TPlayListForm.Clear;
var
  Control: TControl;
begin
  ScrollBox.BeginUpdate;
  try
    for Control in FPathControlDict.Values do
    begin
      ScrollBox.Content.RemoveObject(Control);

      Control.Free;
    end;
  finally
    ScrollBox.EndUpdate;
  end;

  FPathControlDict.Clear;
end;

procedure TPlayListForm.Select(const APath: String);
var
  PlayListItemFrame: TPlayListItemFrame;
  Control: TControl;
begin
  if ScrollBox.Content.ControlsCount = 0 then
    Exit;

  ScrollBox.BeginUpdate;
  try
    for Control in ScrollBox.Content.Controls do
    begin
      PlayListItemFrame := Control as TPlayListItemFrame;
      PlayListItemFrame.BackgroundRectangle.Fill.Color :=
        Theme.ItemSettings.BackgroundColor;
    end;
  finally
    ScrollBox.EndUpdate;
  end;

  FPathControlDict.TryGetValue(APath, Control);
  if not Assigned(Control) then
    Exit;

  PlayListItemFrame := Control as TPlayListItemFrame;
  PlayListItemFrame.BackgroundRectangle.Fill.Color :=
    Theme.ItemSettings.FocusedBackgroundColor
end;

procedure TPlayListForm.ScrollToItem(const APath: String);
var
  PlayListItemFrame: TPlayListItemFrame;
  Control: TControl;
  PointF: TPointF;
begin
  FPathControlDict.TryGetValue(APath, Control);
  if not Assigned(Control) then
    Exit;

  PlayListItemFrame := Control as TPlayListItemFrame;

  PointF.X := PlayListItemFrame.Position.X;
  PointF.Y := PlayListItemFrame.Position.Y;
  PointF := PlayListItemFrame.LocalToAbsolute(PointF);
  ScrollBox.ViewportPosition := PointF;
end;

procedure TPlayListForm.FormCreate(Sender: TObject);
begin
  FOnItemClick := nil;
  BorderFrame.Kind := TBorderFrameKind.bfkNoCaption;
  Self.Fill.Kind := TBrushKind.Solid;
  FPathControlDict := TDictionary<String, TControl>.Create;
  Theme.ItemSettings.OnApplyProcRef :=
    procedure (const AControl: TControl; const AItemSettings: TItemSettings)
    var
      PlayListItemFrame: TPlayListItemFrame;
    begin
      Self.Fill.Color := Theme.FormSettings.BackgroundColor;
      if not (AControl is TPlayListItemFrame) then
        Exit;

      PlayListItemFrame := AControl as TPlayListItemFrame;
      PlayListItemFrame.BackgroundRectangle.Fill.Color :=
        Theme.ItemSettings.BackgroundColor;
      PlayListItemFrame.FocusFrameRectangle.Stroke.Color :=
        Theme.ItemSettings.FocusFrameColor;

      PlayListItemFrame.NumberLabel.StyledSettings := [];
      PlayListItemFrame.PathLabel.StyledSettings := [];
      PlayListItemFrame.TitleLabel.StyledSettings := [];
      PlayListItemFrame.ArtistLabel.StyledSettings := [];
      PlayListItemFrame.AlbumLabel.StyledSettings := [];
      PlayListItemFrame.DurationLabel.StyledSettings := [];

      Theme.ItemSettings.CustomTextSettings.ApplyTo(PlayListItemFrame.NumberLabel);
      Theme.ItemSettings.CustomTextSettings.ApplyTo(PlayListItemFrame.PathLabel);
      Theme.ItemSettings.CustomTextSettings.ApplyTo(PlayListItemFrame.TitleLabel);
      Theme.ItemSettings.CustomTextSettings.ApplyTo(PlayListItemFrame.ArtistLabel);
      Theme.ItemSettings.CustomTextSettings.ApplyTo(PlayListItemFrame.AlbumLabel);
      Theme.ItemSettings.CustomTextSettings.ApplyTo(PlayListItemFrame.DurationLabel);

      PlayListItemFrame.DurationLabel.TextAlign := TTextAlign.Trailing;
    end;

//  Theme.OnApplyProcRef :=
//    procedure
//    var
//      PlayListItemFrame: TPlayListItemFrame;
//    begin
//      Self.Fill.Color := Theme.FormSettings.BackgroundColor;
//      ScrollBox.ControlsEnumerator(
//        procedure (const AControl: TControl)
//        begin
//          if not (AControl is TPlayListItemFrame) then
//            Exit;
//
//          PlayListItemFrame := AControl as TPlayListItemFrame;
//          PlayListItemFrame.BackgroundRectangle.Fill.Color :=
//            Theme.ItemSettings.ItemBackgroundColor;
//          PlayListItemFrame.FocusFrameRectangle.Stroke.Color :=
//            Theme.ItemSettings.FocusFrameColor;
//
//          PlayListItemFrame.NumberLabel.StyledSettings := [];
//          PlayListItemFrame.PathLabel.StyledSettings := [];
//          PlayListItemFrame.TitleLabel.StyledSettings := [];
//          PlayListItemFrame.ArtistLabel.StyledSettings := [];
//          PlayListItemFrame.AlbumLabel.StyledSettings := [];
//          PlayListItemFrame.DurationLabel.StyledSettings := [];
//
//          Theme.TextSettings.ApplyTo(PlayListItemFrame.NumberLabel);
//          Theme.TextSettings.ApplyTo(PlayListItemFrame.PathLabel);
//          Theme.TextSettings.ApplyTo(PlayListItemFrame.TitleLabel);
//          Theme.TextSettings.ApplyTo(PlayListItemFrame.ArtistLabel);
//          Theme.TextSettings.ApplyTo(PlayListItemFrame.AlbumLabel);
//          Theme.TextSettings.ApplyTo(PlayListItemFrame.DurationLabel);
//          PlayListItemFrame.DurationLabel.TextAlign := TTextAlign.Trailing;
//        end);
//    end;

  TState.PlayListFormPos.RestorePosition(Self);
end;

procedure TPlayListForm.FormDestroy(Sender: TObject);
begin
  TState.PlayListFormPos.SavePosition(Self);

  FreeAndNil(FPathControlDict);
end;

end.
