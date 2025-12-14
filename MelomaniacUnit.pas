unit MelomaniacUnit;

interface

uses
  System.SysUtils, System.Types, {System.UITypes,} System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.SingleSoundUnit, FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls,
  FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, FMX.Objects,
  FMX.FormExtUnit,
  FMX.PopupMenuExtUnit,
  PlayListUnit, FMX.Ani, FMX.Effects
  ;

type
  TMainForm = class(TFormExt)
    Memo1: TMemo;
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
    LockerLayout: TLayout;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure CloseControlClick(Sender: TObject);
  private
    FLeafePopupMenu: TPopupMenuExt;
    FMainPopupMenu: TPopupMenuExt;
    procedure BuilPopupMenus;
    procedure ChooseDestinationMenuItemOnClick(Sender: TObject);
    procedure SetEmptyPathMenuItemOnClick(Sender: TObject);
    procedure OpenFolderMenuItemOnClick(Sender: TObject);
    procedure OnAfterPlayListReloadFromPath;
    procedure OnAfterSyncPlayList;
    procedure StartPlay;
//    procedure StartPlayWhenAppStarted;
//    procedure StartPlayFromBeginPlayList;
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
  , MouseHandlersUnit
  , ClickListenerThreadUnit
  , StateUnit
  , VisualSchemeUnit
  , ToolsUnit
  , ConstantsUnit
//  , ThreadFactoryUnit
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
  PlayItemsList: TPlayItemsList;
  PlayItem: TPlayItem;
  CurrentIndex: Integer;
  PlayState: TPlayState;
begin
//  if TPlayController.PlayList.Count = 0 then
//    Exit;

  PlayItemsList := TPlayController.PlayList.LockList;
  try
    Memo1.Lines.Clear;
    for PlayItem in PlayItemsList do
    begin
      Memo1.Lines.Add(PlayItem.Path);
    end;
  finally
    TPlayController.PlayList.UnlockList;
  end;

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

//procedure TMainForm.StartPlayWhenAppStarted;
//var
//  PlayItemsList: TPlayItemsList;
//  PlayItem: TPlayItem;
//  CurrentIndex: Integer;
//  PlayState: TPlayState;
//begin
//  if TPlayController.PlayList.Count = 0 then
//    Exit;
//
//  PlayState := TState.PlayState;
//
//  PlayItemsList := TPlayController.PlayList.LockList;
//  try
//    for PlayItem in PlayItemsList do
//    begin
//      Memo1.Lines.Add(PlayItem.Path);
//    end;
//  finally
//    TPlayController.PlayList.UnlockList;
//  end;
//
//  CurrentIndex := TPlayController.PlayList.IndexOf(TState.Composition);
//  if CurrentIndex < 0 then
//    Exit;
//
//  TPlayController.PlayList.CurrentIndex := CurrentIndex;
//  TPlayController.Current(PlayState, TState.CurrentTime);
//
//  if TState.Volume = 0 then
//  begin
//    TPlayController.Volume := TState.LastVolume;
//    TPlayController.Volume := 0;
//  end
//  else
//  begin
//    TPlayController.Volume := TState.Volume;
//  end;
//end;

//procedure TMainForm.StartPlayFromBeginPlayList;
//var
//  PlayItemsList: TPlayItemsList;
//  PlayItem: TPlayItem;
//begin
//  if TPlayController.PlayList.Count = 0 then
//    Exit;
//
//  PlayItemsList := TPlayController.PlayList.LockList;
//  try
//    for PlayItem in PlayItemsList do
//    begin
//      Memo1.Lines.Add(PlayItem.Path);
//    end;
//  finally
//    TPlayController.PlayList.UnlockList;
//  end;
//
//  TPlayController.First;
//  TPlayController.CurrentTime := TState.CurrentTime;
//  if TState.Volume = 0 then
//  begin
//    TPlayController.Volume := TState.LastVolume;
//    TPlayController.Volume := 0;
//  end
//  else
//  begin
//    TPlayController.Volume := TState.Volume;
//  end;
//end;

procedure TMainForm.OnAfterPlayListReloadFromPath;
begin
  TPlayController.PlayList.SaveToDB;

  StartPlay;
end;

procedure TMainForm.OnAfterSyncPlayList;
var
  MainPath: String;
begin
  TPlayController.PlayList.SaveToDB;

  MainPath := TState.MainPath;
  TPlayController.PlayList.ReloadPlayListFromDB(MainPath);

  StartPlay;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  ClickListenerThread: TClickListenerThread;
  MainPath: String;
begin
  ReportMemoryLeaksOnShutdown := true;

  TState.Init;

  TPlayController.Init(
    ThreadFactory,
    ThreadFactoryRegistry,
    TimelineCaretControl,
    TimelineControl,
    CurrentTimeLabel,
    TState.PlayState);

  TVisualScheme.Init;
  TVisualScheme.Load(Self, 'Steampunk');

  MainPath := TState.MainPath;
//  if not MainPath.IsEmpty then
  begin
    TPlayController.PlayList.OnPlayListReloaded := OnAfterSyncPlayList;
    TPlayController.PlayList.SyncPlayLists(MainPath);
  end;

//  if not MainPath.IsEmpty then
//  begin
//    if TTools.CheckPath(MainPath) then
//    begin
//      TPlayController.PlayList.OnPlayListReloaded := OnAfterSyncPlayList;
//      TPlayController.PlayList.SyncPlayLists(MainPath);
//    end
//    else
//    begin
//      TPlayController.PlayList.OnPlayListReloaded := OnAfterPlayListReloadFromPath;
//      TPlayController.PlayList.ReloadPlayListFromPath(MainPath);
//    end
//  end;

  ClickListenerThread := TClickListenerThread.Create(ThreadFactory);
  TMouseHandlers.Init(ClickListenerThread);

  TMouseHandlers.ConnectHandlers([
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
    SetOfPathsNumber1Control,
    SetOfPathsNumber2Control,
    SetOfPathsNumber3Control,
    SetOfPathsNumber4Control
  ]);

  TTools.ConnectGlowEffect([TimelineControl, VolumeControl]);
  TTools.ConnectHeighlightGlowEffect(
    [TimelineControl, VolumeControl],
    TAlphaColorRec.Limegreen,
    HEIGHLIGTH_GLOW_EFFECT_IDENT);
  TTools.ConnectHeighlightGlowEffect(
    [TimelineControl, VolumeControl],
    TAlphaColorRec.Red,
    FAIL_HEIGHLIGTH_GLOW_EFFECT_IDENT);

//  TThread.ForceQueue(nil,
//    procedure
//    begin
//      TPlayController.HeighlightMarkMode;
//      TPlayController.HeighlightCopyMode;
//    end);

  TPlayController.HeighlightMarkMode;
  TPlayController.HeighlightCopyMode;
  TState.SetOfPathsIndex := TState.SetOfPathsIndex;
//  TPlayController.HeighlightSetOfPaths;

  PlayControl.BringToFront;

  BuilPopupMenus;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  TState.CurrentTime := TPlayController.CurrentTime;
  TState.Composition := TPlayController.PlayList.CurrentComposition;
  TState.MainPath := ExtractFilePath(TState.Composition);

  TPlayController.UnInit;
  TVisualScheme.UnInit;
  TState.UnInit;
end;

procedure TMainForm.BuilPopupMenus;
var
  MenuItem: TItem;
begin
  FLeafePopupMenu := TPopupMenuExt.Create(Self);
//  TState.MenuTheme.CopyTo(FSettingsPopupMenuExt.Theme);

  MenuItem := TItem.Create;
  MenuItem.Text := 'Choose destination';
  MenuItem.OnClick := ChooseDestinationMenuItemOnClick;
  FLeafePopupMenu.Add(MenuItem);

  MenuItem := TItem.Create;
  MenuItem.Text := 'Set empty path';
  MenuItem.OnClick := SetEmptyPathMenuItemOnClick;
  FLeafePopupMenu.Add(MenuItem);

  FMainPopupMenu := TPopupMenuExt.Create(Self);
//  TState.MenuTheme.CopyTo(FSettingsPopupMenuExt.Theme);

  MenuItem := TItem.Create;
  MenuItem.Text := 'Open folder';
  MenuItem.OnClick := OpenFolderMenuItemOnClick;
  FMainPopupMenu.Add(MenuItem);
end;

procedure TMainForm.ChooseDestinationMenuItemOnClick(Sender: TObject);
begin
  TTools.ChooseDestinationPath(TControl(FLeafePopupMenu.CallingObject));
end;

procedure TMainForm.SetEmptyPathMenuItemOnClick(Sender: TObject);
begin
  TTools.SetLeafeEmptyPath(TControl(FLeafePopupMenu.CallingObject));
end;

procedure TMainForm.OpenFolderMenuItemOnClick(Sender: TObject);
var
  MainPath: String;
//  PlayState: TPlayState;
begin
//  PlayState := TState.PlayState;
  TPlayController.Stop;
  TPlayController.PlayList.Clear;

  TState.CurrentTime := 0;
  TTools.ChooseMainFolder;

//  TState.PlayState := psPlay;
  MainPath := TState.MainPath;
  TPlayController.PlayList.OnPlayListReloaded := OnAfterSyncPlayList;
  TPlayController.PlayList.SyncPlayLists(MainPath);

//  if TTools.CheckPath(MainPath) then
//  begin
//    TPlayController.PlayList.OnPlayListReloaded := OnAfterSyncPlayList;
//    TPlayController.PlayList.SyncPlayLists(MainPath);
//  end
//  else
//  begin
//    TPlayController.PlayList.OnPlayListReloaded := OnAfterPlayListReloadFromPath;
//    TPlayController.PlayList.ReloadPlayListFromPath(MainPath);
//  end;
end;

end.
