unit MelomaniacUnit;

interface

uses
  System.SysUtils, System.Types, {System.UITypes,} System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.SingleSoundUnit, FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls,
  FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, FMX.Objects,
  FMX.FormExtUnit,
  FMX.PopupMenuExt,
  PlayListUnit, FMX.Ani, FMX.Effects
  , FMX.HintUnit
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
    procedure FormDestroy(Sender: TObject);
    procedure CloseControlClick(Sender: TObject);
    procedure ChangeViewControlClick(Sender: TObject);
  private
    FLeafePopupMenu: TPopupMenuExt;
    FMainPopupMenu: TPopupMenuExt;
    FCustomHint: TCustomHint;
    procedure BuildPopupMenus;
    procedure ChooseDestinationMenuItemOnClick(Sender: TObject);
    procedure SetEmptyPathMenuItemOnClick(Sender: TObject);
    procedure GotoThisPathMenuItemOnClick(Sender: TObject);
    procedure OpenFolderMenuItemOnClick(Sender: TObject);
    procedure OnAfterSyncPlayList;
    procedure StartPlay;
  public
    property LeafePopupMenu: TPopupMenuExt read FLeafePopupMenu;
    property MainPopupMenu: TPopupMenuExt read FMainPopupMenu;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

uses
    System.Generics.Collections
  , System.UITypes
  , PlayControllerUnit
  , MainFormMouseHandlersUnit
  , PlayListFormMouseHandlersUnit
  , PlayListItemFrameUnit
  , StateUnit
  , VisualSchemeUnit
  , ToolsUnit
  , ConstantsUnit
  , PlayListFormUnit
  , PopupMenuExt.Item
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
    TPlayController.Volume := 0;
  end
  else
  begin
    TPlayController.Volume := TState.Volume;
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

procedure TMainForm.FormCreate(Sender: TObject);
var
  MainPath: String;
begin
  ReportMemoryLeaksOnShutdown := true;

  try
    TState.Init;

    TPlayController.Init(
      ThreadFactory,
      ThreadFactoryRegistry,
      TimelineCaretControl,
      TimelineControl,
      CurrentTimeLabel);

    TVisualScheme.Init;
    TVisualScheme.Load(Self, 'Steampunk');

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

    BuildPopupMenus;

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

    FCustomHint := TCustomHint.Create(Self);
    FCustomHint.Theme.CopyFrom(Theme.HintTheme);

    TState.MainFormPos.RestorePosition(Self);
  except
    on e: Exception do
      raise Exception.Create(e.Message);
  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  TState.CurrentTime := TPlayController.CurrentTime;
  TState.Composition := TPlayController.PlayList.CurrentComposition;
  TState.MainPath := ExtractFilePath(TState.Composition);

  TState.MainFormPos.SavePosition(Self);

  FreeAndNil(FCustomHint);

  TPlayController.UnInit;
  TVisualScheme.UnInit;
  TState.UnInit;
end;

procedure TMainForm.BuildPopupMenus;
var
  MenuItem: TItem;
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
      Self.Top + Self.Height + 30);
    PlayListForm.Width := _IfThenElse(
      PlayListForm.Width,
      0,
      Self.Width);
    PlayListForm.Left := _IfThenElse(
      PlayListForm.Left,
      0,
      Self.Left);

    PlayListForm.Theme.FormSettings.BorderFrameColor := $FFFFB800;
    PlayListForm.Theme.FormSettings.Container := PlayListForm;
    PlayListForm.Theme.ItemSettings.BackgroundColor := $FFC55F00;
    PlayListForm.Theme.ItemSettings.Container := PlayListForm.ScrollBox;
    PlayListForm.Theme.ItemSettings.FocusedBackgroundColor := $FF994A00;
    PlayListForm.Theme.ItemSettings.FocusFrameColor := $FFFF9921;
    PlayListForm.Theme.ItemSettings.CustomTextSettings.Assign(
      InfoPanelTitleLabel.TextSettings);
    PlayListForm.Theme.FormSettings.Apply;
    PlayListForm.Show;
    PlayListForm.Theme.ItemSettings.Apply;

    TPlayController.RefreshPlayListForm;
  end
  else
  begin
    PlayListForm.Close;
    PlayListForm := nil;
  end;
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

end.
