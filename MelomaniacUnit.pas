unit MelomaniacUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
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
    procedure OpenFolderMenuItemOnClick(Sender: TObject);
    procedure FirstAfterPlayListReload;
    procedure CommonAfterPlayListReload;
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
  , PlayControllerUnit
  , MouseHandlersUnit
  , ClickListenerThreadUnit
  , StateUnit
  , VisualSchemeUnit
  , ToolsUnit
  , ConstantsUnit
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

procedure TMainForm.FirstAfterPlayListReload;
var
  PlayItemsList: TPlayItemsList;
  PlayItem: TPlayItem;
  CurrentIndex: Integer;
  PlayState: TPlayState;
begin
  TPlayController.PlayList.OnPlayListReloaded := CommonAfterPlayListReload;

  PlayState := TState.PlayState;

  PlayItemsList := TPlayController.PlayList.LockList;
  try
    for PlayItem in PlayItemsList do
    begin
      Memo1.Lines.Add(PlayItem.Path);
    end;
  finally
    TPlayController.PlayList.UnlockList;
  end;

  CurrentIndex := TPlayController.PlayList.IndexOf(TState.Composition);
  if CurrentIndex < 0 then
    Exit;

  TPlayController.PlayList.CurrentIndex := CurrentIndex;
  TPlayController.Current(PlayState, TState.CurrentTime);

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

procedure TMainForm.CommonAfterPlayListReload;
var
  PlayItemsList: TPlayItemsList;
  PlayItem: TPlayItem;
begin
  PlayItemsList := TPlayController.PlayList.LockList;
  try
    for PlayItem in PlayItemsList do
    begin
      Memo1.Lines.Add(PlayItem.Path);
    end;
  finally
    TPlayController.PlayList.UnlockList;
  end;

  TPlayController.First;
  TPlayController.CurrentTime := TState.CurrentTime;
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

procedure TMainForm.FormCreate(Sender: TObject);
var
  ClickListenerThread: TClickListenerThread;
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
  TThread.ForceQueue(nil,
    procedure
    begin
      TPlayController.HeighlightCopyMode;
    end);

  TTools.FillPaths(TState.SetOfPathsIndex);

  TVisualScheme.Init;
  TVisualScheme.Load(Self, 'Steampunk');

//  TPlayController.PlayList.ReloadPlayList('E:\Desktop\Music\Alternative\Collection\');
//  TPlayController.PlayList.ReloadPlayList('C:\000');
  if not TState.MainPath.IsEmpty then
  begin
    TPlayController.PlayList.ReloadPlayList(TState.MainPath);
    TPlayController.PlayList.OnPlayListReloaded := FirstAfterPlayListReload;
  end
  else
    TPlayController.PlayList.OnPlayListReloaded := CommonAfterPlayListReload;

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
    CopyModeControl,
    MoveModeControl
  ]);

//  TimelineControl.OnMouseUp := TMouseHandlers.OnMouseUpHandler;
//  VolumeControl.OnMouseUp := TMouseHandlers.OnMouseUpHandler;

  TTools.ConnectGlowEffect([TimelineControl, VolumeControl]);
  TTools.ConnectHeighlightGlowEffect([TimelineControl, VolumeControl]);

  PlayControl.BringToFront;

  BuilPopupMenus;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  TState.CurrentTime := TPlayController.CurrentTime;
  TState.Composition := TPlayController.PlayList.CurrentComposition;
  TState.MainPath := ExtractFileDir(TState.Composition);

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

procedure TMainForm.OpenFolderMenuItemOnClick(Sender: TObject);
begin
//  TPlayController.Stop;
  TState.CurrentTime := 0;
  TTools.ChooseMainFolder;
  TPlayController.PlayList.ReloadPlayList(TState.MainPath);
end;

end.
