unit MelomaniacUnit;

interface

uses
  System.SysUtils, System.Types, {System.UITypes,} System.Classes, System.Variants,
  System.UITypes,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.SingleSoundUnit, FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls,
  FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, FMX.Objects,
  FMX.FormExtUnit,
  FMX.PopupMenuExt,
  PlayListUnit, FMX.Ani, FMX.Effects
  , PopupMenuExt.Item
  , FMX.HintUnit
  , Net.Server
  ;

type
  TMainForm = class(TFormExt)
    CurrentTimeLabel: TLabel;
    TopLeftControl: TRectangle;
    TopRightControl: TRectangle;
    BottomLeftControl: TRectangle;
    BottomRightControl: TRectangle;
    PrevNSecondsControl: TRectangle;
    PrevTrackControl: TRectangle;
    NextNSecondsControl: TRectangle;
    NextTrackControl: TRectangle;
    TopControlsLayout: TLayout;
    ChangeViewControl: TRectangle;
    MoveModeControl: TRectangle;
    CopyModeControl: TRectangle;
    MarkModeControl: TRectangle;
    DuplicateModeControl: TRectangle;
    SetOfPathsNumber1Control: TRectangle;
    SetOfPathsNumber2Control: TRectangle;
    SetOfPathsNumber3Control: TRectangle;
    SetOfPathsNumber4Control: TRectangle;
    CloseControl: TRectangle;
    RolldownControl: TRectangle;
    BackToLastMainPathControl: TRectangle;
    BottomControlsLayout: TLayout;
    InfoPanelControl: TRectangle;
    TimeLineControl: TRectangle;
    TimelineCaretControl: TRectangle;
    VolumeControl: TRectangle;
    VolumeCaretControl: TRectangle;
    SoundControl: TRectangle;
    PlayControl: TCircle;
    TopRightControlLabel: TLabel;
    TopLeftControlLabel: TLabel;
    BottomLeftControlLabel: TLabel;
    BottomRightControlLabel: TLabel;
    InfoPanelPathLabel: TLabel;
    InfoPanelTitleLabel: TLabel;
    DurationLabel: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure CloseControlClick(Sender: TObject);
    procedure ChangeViewControlClick(Sender: TObject);
    procedure RolldownControlClick(Sender: TObject);
    procedure VolumeControlMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; var Handled: Boolean);
    procedure TimeLineControlMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; var Handled: Boolean);
    procedure FormDestroy(Sender: TObject);
  private
    FLeafePopupMenu: TPopupMenuExt;
    FMainPopupMenu: TPopupMenuExt;
    FCustomHint: TCustomHint;
    FTrayPopupMenuExt: TPopupMenuExt;
    FTrayMenuItemPlay: TItem;
    FTrayMenuItemPause: TItem;
    FTrayMenuItemMute: TItem;
    FTrayMenuItemUnMute: TItem;

    FNetServer: TNetServer;

    procedure Init;

    procedure BuildPopupMenus;
    procedure BuildTrayPopupMenu;
    procedure ChooseDestinationMenuItemOnClick(Sender: TObject);
    procedure SetEmptyPathMenuItemOnClick(Sender: TObject);
    procedure GotoThisPathMenuItemOnClick(Sender: TObject);
    procedure OpenFolderMenuItemOnClick(Sender: TObject);
    procedure ThemeMenuItemOnClick(Sender: TObject);
    procedure OnAfterSyncPlayList;
    procedure StartPlay;
    procedure TrayMenuItemPlayOnClickHandler(Sender: TObject);
    procedure TrayMenuItemPauseOnClickHandler(Sender: TObject);
    procedure TrayMenuItemNextOnClickHandler(Sender: TObject);
    procedure TrayMenuItemPrevOnClickHandler(Sender: TObject);
    procedure OnCloseTrayItemHandler(Sender: TObject);
    procedure TrayIconMouseRightButtonDownHandler(
      Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
  public
    property LeafePopupMenu: TPopupMenuExt read FLeafePopupMenu;
    property MainPopupMenu: TPopupMenuExt read FMainPopupMenu;
    property TrayMenuItemPlay: TItem read FTrayMenuItemPlay;
    property TrayMenuItemPause: TItem read FTrayMenuItemPause;
    property TrayMenuItemMute: TItem read FTrayMenuItemMute;
    property TrayMenuItemUnMute: TItem read FTrayMenuItemUnMute;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

uses
    System.Generics.Collections
  , PlayControllerUnit
  , MainFormMouseHandlersUnit
  , PlayListFormMouseHandlersUnit
  , PlayListItemFrameUnit
  , StateUnit
  , VisualSchemeUnit
  , ToolsUnit
  , ConstantsUnit
  , PlayListFormUnit
  , FMX.ControlToolsUnit
  , FMX.Media
  ;

procedure TMainForm.CloseControlClick(Sender: TObject);
begin
  TThread.ForceQueue(nil,
    procedure
    begin
      Close;
    end
  );
end;

procedure TMainForm.StartPlay;
var
  CurrentIndex: Integer;
  PlayState: TPlayState;
begin
  if TState.IsAppStarting then
  begin
    PlayState := TState.PlayState;

    CurrentIndex := TPlayController.PlayList.IndexOf(TState.Composition);
    if CurrentIndex < 0 then
      Exit;

    TPlayController.PlayList.CurrentIndex := CurrentIndex;
    TPlayController.Current(PlayState, TState.CurrentTime);
  end
  else
  begin
    TPlayController.First;
    TPlayController.CurrentTime := TState.CurrentTime;
  end;

  if TState.Volume = 0 then
  begin
    TPlayController.Volume := TState.LastVolume;
//    TPlayController.Volume := 0;
    TPlayController.Mute;
  end
  else
  begin
    TPlayController.Volume := TState.Volume;
    TPlayController.UnMute;
//    TPlayController.Volume := TState.Volume;
  end;
end;

procedure TMainForm.OnAfterSyncPlayList;
var
  MainPath: String;
begin
  TPlayController.PlayList.SaveToDB;

  MainPath := TState.MainPath;
  TPlayController.PlayList.ReloadPlayListFromDB(MainPath, TState.DuplicateMode);
  TPlayController.RefreshPlayListForm;

  StartPlay;
end;

procedure TMainForm.Init;
var
  MainPath: String;
  VisualScheme: String;
begin
  try
    TTools.Init;
    TState.Init;

    // К главной форме не применяется тема формы Self.ApplyFormTheme
    BorderFrame.Kind := TBorderFrameKind.bfkNone;

    TPlayController.Init(
      ThreadFactory,
      ThreadFactoryRegistry,
      TimelineCaretControl,
      TimelineControl,
      CurrentTimeLabel);

    TVisualScheme.Init;
    VisualScheme := TState.VisualScheme;
    if VisualScheme.IsEmpty then
      VisualScheme := 'Steampunk';
    TVisualScheme.LoadForMainForm(Self, VisualScheme, PlayControl);

    FTrayMenuItemPlay := nil;
    FTrayMenuItemPause := nil;
    FTrayMenuItemMute := nil;
    FTrayMenuItemUnMute := nil;

    BuildTrayPopupMenu;
    BuildPopupMenus;

    MainPath := TState.MainPath;
    TPlayController.PlayList.OnPlayListReloaded := OnAfterSyncPlayList;
    TPlayController.PlayList.SyncPlayLists(MainPath);

    TMainFormMouseHandlers.ConnectHandlers([
      InfoPanelTitleLabel,
      InfoPanelPathLabel,
      TopLeftControlLabel,
      TopRightControlLabel,
      BottomLeftControlLabel,
      BottomRightControlLabel,
      PlayControl,
      TimelineCaretControl,
      TopLeftControl,
      TopRightControl,
      BottomLeftControl,
      BottomRightControl,
      SoundControl,
      PrevTrackControl,
      NextTrackControl,
      PrevNSecondsControl,
      NextNSecondsControl,
      VolumeCaretControl,
      InfoPanelControl,
      TimelineControl,
      VolumeControl,
      MarkModeControl,
      CopyModeControl,
      MoveModeControl,
      DuplicateModeControl,
      SetOfPathsNumber1Control,
      SetOfPathsNumber2Control,
      SetOfPathsNumber3Control,
      SetOfPathsNumber4Control
    ]);

    TTools.ConnectGlowEffect([
      TimelineControl,
      VolumeControl,
      InfoPanelTitleLabel,
      InfoPanelPathLabel,
      TopLeftControlLabel,
      TopRightControlLabel,
      BottomLeftControlLabel,
      BottomRightControlLabel
      ]);
    TTools.ConnectHeighlightGlowEffect([
      TimelineControl,
      VolumeControl,
      InfoPanelTitleLabel,
      InfoPanelPathLabel,
      TopLeftControlLabel,
      TopRightControlLabel,
      BottomLeftControlLabel,
      BottomRightControlLabel
      ],
      TAlphaColorRec.Limegreen,
      HEIGHLIGTH_GLOW_EFFECT_IDENT);
    TTools.ConnectHeighlightGlowEffect([
      TimelineControl,
      VolumeControl,
      InfoPanelTitleLabel,
      InfoPanelPathLabel,
      TopLeftControlLabel,
      TopRightControlLabel,
      BottomLeftControlLabel,
      BottomRightControlLabel
      ],
      TAlphaColorRec.Red,
      FAIL_HEIGHLIGTH_GLOW_EFFECT_IDENT);

    TPlayController.HeighlightMarkMode;
    TPlayController.HeighlightCopyMode;
    TPlayController.HeighlightDuplicateMode;
    TState.SetOfPathsIndex := TState.SetOfPathsIndex;

    PlayControl.BringToFront;

    TTools.OnMouseEnterHook(InfoPanelTitleLabel, InfoPanelControl);
    TTools.OnMouseEnterHook(InfoPanelPathLabel, InfoPanelControl);
    TTools.OnMouseEnterHook(TopLeftControlLabel, TopLeftControl);
    TTools.OnMouseEnterHook(TopRightControlLabel, TopRightControl);
    TTools.OnMouseEnterHook(BottomLeftControlLabel, BottomLeftControl);
    TTools.OnMouseEnterHook(BottomRightControlLabel, BottomRightControl);

    TTools.OnMouseLeaveHook(InfoPanelTitleLabel, InfoPanelControl);
    TTools.OnMouseLeaveHook(InfoPanelPathLabel, InfoPanelControl);
    TTools.OnMouseLeaveHook(TopLeftControlLabel, TopLeftControl);
    TTools.OnMouseLeaveHook(TopRightControlLabel, TopRightControl);
    TTools.OnMouseLeaveHook(BottomLeftControlLabel, BottomLeftControl);
    TTools.OnMouseLeaveHook(BottomRightControlLabel, BottomRightControl);

//    TState.MainFormPos.RestorePosition(Self);

    TrayIconMouseRightButtonDown := TrayIconMouseRightButtonDownHandler;

    FCustomHint := TCustomHint.Create(Self);
    FCustomHint.Theme.CopyFrom(Theme.HintTheme);

    FNetServer := TNetServer.Create(1081);
    FNetServer.Active := true;
  except
    on e: Exception do
    begin
      raise Exception.Create(e.Message);
    end;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  ReportMemoryLeaksOnShutdown := true;

  TThread.ForceQueue(nil,
    procedure
    begin
      Init;
    end);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  TState.CurrentTime := TPlayController.CurrentTime;
  TState.Composition := TPlayController.PlayList.CurrentComposition;
  TState.MainPath := ExtractFilePath(TState.Composition);

  TTools.UnInit;

  FreeAndNil(FCustomHint);

  FNetServer.Active := false;
  FreeAndNil(FNetServer);

  TPlayController.UnInit;
  TVisualScheme.UnInit;
  TState.UnInit;
end;

procedure TMainForm.TrayMenuItemPlayOnClickHandler(Sender: TObject);
begin
  TPlayController.Play;
end;

procedure TMainForm.TrayMenuItemPauseOnClickHandler(Sender: TObject);
begin
  TPlayController.Pause;
end;

procedure TMainForm.TrayMenuItemNextOnClickHandler(Sender: TObject);
begin
  TPlayController.Next;
end;

procedure TMainForm.TrayMenuItemPrevOnClickHandler(Sender: TObject);
begin
  TPlayController.Prev;
end;

procedure TMainForm.OnCloseTrayItemHandler(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.TrayIconMouseRightButtonDownHandler(
  Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  TControlTools.GetCurPos(X, Y);

  FTrayPopupMenuExt.Open(X, Y);
end;

procedure TMainForm.BuildPopupMenus;
var
  MenuItem: TItem;
  MenuItemTheme: TItem;
  ThemeName: String;
begin
  FLeafePopupMenu := TPopupMenuExt.Create(Self);
  FLeafePopupMenu.Theme.CopyFrom(Self.Theme.PopUpMenuTheme);

  MenuItem := TItem.Create;
  MenuItem.Text := 'Choose destination';
  MenuItem.OnClick := ChooseDestinationMenuItemOnClick;
  FLeafePopupMenu.Add(MenuItem);

  MenuItem := TItem.Create;
  MenuItem.Text := 'Set empty path';
  MenuItem.OnClick := SetEmptyPathMenuItemOnClick;
  FLeafePopupMenu.Add(MenuItem);

  MenuItem := TItem.Create;
  MenuItem.Text := 'Go to this path';
  MenuItem.OnClick := GotoThisPathMenuItemOnClick;
  FLeafePopupMenu.Add(MenuItem);

  FMainPopupMenu := TPopupMenuExt.Create(Self);
  FMainPopupMenu.Theme.CopyFrom(Self.Theme.PopUpMenuTheme);

  MenuItem := TItem.Create;
  MenuItem.Text := 'Open folder';
  MenuItem.OnClick := OpenFolderMenuItemOnClick;
  FMainPopupMenu.Add(MenuItem);

  MenuItemTheme := TItem.Create;
  MenuItemTheme.Text := 'Theme';
  FMainPopupMenu.Add(MenuItemTheme);

  for ThemeName in TVisualScheme.ThemeNames do
  begin
    MenuItem := TItem.Create;
    MenuItem.Parent := MenuItemTheme;
    MenuItem.Text := ThemeName;
    MenuItem.OnClick := ThemeMenuItemOnClick;
    FMainPopupMenu.Add(MenuItem);
  end;
end;

procedure TMainForm.BuildTrayPopupMenu;
var
  MenuItem: TItem;
begin
  FTrayPopupMenuExt := TPopupMenuExt.Create(Self);
  FTrayPopupMenuExt.Theme.CopyFrom(Theme.PopUpMenuTheme);

  FTrayMenuItemPlay := TItem.Create;
  FTrayMenuItemPlay.Text := FUNC_IDENT_PLAY;
  FTrayMenuItemPlay.OnClick := TrayMenuItemPlayOnClickHandler;
  FTrayPopupMenuExt.Add(FTrayMenuItemPlay);

  FTrayMenuItemPause := TItem.Create;
  FTrayMenuItemPause.Text := FUNC_IDENT_PAUSE;
  FTrayMenuItemPause.OnClick := TrayMenuItemPauseOnClickHandler;
  FTrayPopupMenuExt.Add(FTrayMenuItemPause);

  MenuItem := TItem.Create;
  MenuItem.Text := '-';
  FTrayPopupMenuExt.Add(MenuItem);

  MenuItem := TItem.Create;
  MenuItem.Text := FUNC_IDENT_NEXT;
  MenuItem.OnClick := TrayMenuItemNextOnClickHandler;
  FTrayPopupMenuExt.Add(MenuItem);

  MenuItem := TItem.Create;
  MenuItem.Text := FUNC_IDENT_PREV;
  MenuItem.OnClick := TrayMenuItemPrevOnClickHandler;
  FTrayPopupMenuExt.Add(MenuItem);

  MenuItem := TItem.Create;
  MenuItem.Text := '-';
  FTrayPopupMenuExt.Add(MenuItem);

  FTrayMenuItemMute := TItem.Create;
  FTrayMenuItemMute.Text := FUNC_IDENT_MUTE;
  FTrayMenuItemMute.OnClickProcRef :=
    procedure
    begin
      TPlayController.Mute
    end;
  FTrayPopupMenuExt.Add(FTrayMenuItemMute);

  FTrayMenuItemUnMute := TItem.Create;
  FTrayMenuItemUnMute.Text := FUNC_IDENT_UNMUTE;
  FTrayMenuItemUnMute.OnClickProcRef :=
    procedure
    begin
      TPlayController.UnMute;
    end;
  FTrayPopupMenuExt.Add(FTrayMenuItemUnMute);

  MenuItem := TItem.Create;
  MenuItem.Text := '-';
  FTrayPopupMenuExt.Add(MenuItem);

  MenuItem := TItem.Create;
  MenuItem.Text := FUNC_IDENT_CLOSE;
  MenuItem.OnClick := OnCloseTrayItemHandler;
  FTrayPopupMenuExt.Add(MenuItem);
end;

procedure TMainForm.ChangeViewControlClick(Sender: TObject);

  function _IfThenElse(
    const AVlue: Integer;
    const AIfValue: Integer;
    const AThenValue: Integer): Integer;
  begin
    Result := AVlue;
    if AVlue = AIfValue then
      Result := AThenValue;
  end;

begin
  if not Assigned(PlayListForm) then
  begin
    PlayListForm := TPlayListForm.Create(nil);

    PlayListForm.Top := _IfThenElse(
      PlayListForm.Top,
      0,
      Self.Top + Self.Height + 5);
    PlayListForm.Width := _IfThenElse(
      PlayListForm.Width,
      0,
      Self.Width);
    PlayListForm.Left := _IfThenElse(
      PlayListForm.Left,
      0,
      Self.Left + Round(Self.PrevTrackControl.Position.X));

    TVisualScheme.LoadForPlayList(
      PlayListForm,
      TState.VisualScheme,
      PlayListForm.ScrollBox);

    PlayListForm.Show;

    TPlayController.RefreshPlayListForm;
  end
  else
    PlayListForm.Close;

  TPlayController.HeighlightChangeView;
end;

procedure TMainForm.ChooseDestinationMenuItemOnClick(Sender: TObject);
begin
  TTools.ChooseDestinationPath(TControl(FLeafePopupMenu.CallingObject));
end;

procedure TMainForm.SetEmptyPathMenuItemOnClick(Sender: TObject);
begin
  TTools.SetLeafeEmptyPath(TControl(FLeafePopupMenu.CallingObject));
end;

procedure TMainForm.GotoThisPathMenuItemOnClick(Sender: TObject);
var
  MainPath: String;
begin
  MainPath := TTools.LeafePath(TControl(FLeafePopupMenu.CallingObject));
  if MainPath.IsEmpty then
    Exit;

  TState.MainPath := MainPath;

  TPlayController.Stop;
  TPlayController.PlayList.Clear;

  TState.CurrentTime := 0;

  TPlayController.PlayList.OnPlayListReloaded := OnAfterSyncPlayList;
  TPlayController.PlayList.SyncPlayLists(TState.MainPath);
end;

procedure TMainForm.OpenFolderMenuItemOnClick(Sender: TObject);
var
  MainPath: String;
begin
  MainPath := TTools.ChooseMainFolder;
  if MainPath.IsEmpty then
    Exit;

  TState.MainPath := MainPath;

  TPlayController.Stop;
  TPlayController.PlayList.Clear;

  TState.CurrentTime := 0;

  TPlayController.PlayList.OnPlayListReloaded := OnAfterSyncPlayList;
  TPlayController.PlayList.SyncPlayLists(TState.MainPath);
end;

procedure TMainForm.RolldownControlClick(Sender: TObject);
begin
  Self.Rolldown;
end;

procedure TMainForm.ThemeMenuItemOnClick(Sender: TObject);
var
  MenuItem: TItem;
  SchemeName: String;
begin
  MenuItem := Sender as TItem;
  SchemeName := MenuItem.Text;
  TVisualScheme.LoadForMainForm(Self, SchemeName, PlayControl);
  if Assigned(PlayListForm) then
    TVisualScheme.LoadForPlayList(PlayListForm, SchemeName, PlayListForm.ScrollBox);
end;

procedure TMainForm.TimeLineControlMouseWheel(Sender: TObject;
  Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
var
  Val: TMediaTime;
  Step: Integer;
  Duration: TMediaTime;
begin
  Duration := TPlayController.Duration;
  Step := MediaTimeScale * 2;
  if WheelDelta < 0 then
  begin
    Val := TPlayController.CurrentTime - Step;
    if Val >= 0 then
      TPlayController.CurrentTime := Val
    else
      TPlayController.CurrentTime := 0;
  end
  else
  begin
    Val := TPlayController.CurrentTime + Step;
    if Val <= Duration then
      TPlayController.CurrentTime := Val
    else
      TPlayController.CurrentTime := Duration;
  end;
end;

procedure TMainForm.VolumeControlMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; var Handled: Boolean);
begin
  if WheelDelta < 0 then
    TPlayController.VolumeDown
  else
    TPlayController.VolumeUp;
end;

end.
