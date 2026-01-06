unit PlayControllerUnit;

interface

uses
    FMX.Controls
  , FMX.Media
  , ThreadFactoryUnit
  , ThreadFactoryRegistryUnit
  , TimelineTrackerThreadUnit
  , PlayListUnit
  , FMX.SingleSoundUnit
  , StateUnit
  ;

type
  TPlayController = class
  strict private
    class var FSingleSound: TSingleSound;
    class var FTimelineTrackerThread: TTimelineTrackerThread;
    class var FPlayList: TPlayList;

    class procedure SetCurrentTime(const ACurrentTime: TMediaTime); static;
    class function GetCurrentTime: TMediaTime; static;
    class procedure SetVolume(const AVolume: Single); static;

    class function SetPlayItem(const APlayItem: TPlayItem): Boolean;
    class function SetFirst: Boolean;
    class function SetPrev: Boolean;
    class function SetNext: Boolean;
    class function SetCurrent: Boolean;

    class procedure OffHeighlight(const AControlsArray: array of TControl);
  public
    class procedure Init(
      const AThreadFactory: TThreadFactory;
      const AThreadFactoryRegistry: TThreadFactoryRegistry;
      const ATimelineCaret: TControl;
      const ADurationBar: TControl;
      const ACurrentTimeLabel: TControl);
    class procedure UnInit;

    class property SingleSound: TSingleSound read FSingleSound write FSingleSound;
    class property PlayList: TPlayList read FPlayList;
    class property CurrentTime: TMediaTime read GetCurrentTime write SetCurrentTime;
    class property Volume: Single write SetVolume;
    class property TimelineTrackerThread: TTimelineTrackerThread read FTimelineTrackerThread;

    class procedure Play;
    class procedure Stop;
    class procedure Pause;
    class procedure Mute;
    class procedure UnMute;
    class procedure BackwardRewind;
    class procedure ForwardRewind;
    class procedure BackwardRewindStep;
    class procedure ForwardRewindStep;
    class procedure StopRewind;
    class procedure First;
    class procedure Prev;
    class procedure Next;
    class procedure Current(
      const APlayState: TPlayState;
      const ACurrentTime: TMediaTime);

    class procedure GetCurrentCompositonInfo(
      out ATitle: String;
      out APath: String);

    class procedure MountCurrentTime;
    class procedure MountVolume;

    class procedure HeighlightCopyMode;
    class procedure HeighlightMarkMode;
    class procedure HeighlightLeafe;
    class procedure HeighlightFail(const AControl: TControl);
    class procedure HeighlightSetOfPaths;
    class procedure LeafeClicked(Sender: TObject);
    class procedure SetOfPathClicked(Sender: TObject);

    class procedure CopyThenNext;
  end;

implementation

uses
    System.SysUtils
  , ToolsUnit
  , StringToolsUnit
  , MelomaniacUnit
  , VisualSchemeUnit
  , ConstantsUnit
  , HeighlightFailThreadUnit
  ;

{ TPlayController }

class procedure TPlayController.Init(
  const AThreadFactory: TThreadFactory;
  const AThreadFactoryRegistry: TThreadFactoryRegistry;
  const ATimelineCaret: TControl;
  const ADurationBar: TControl;
  const ACurrentTimeLabel: TControl);
var
  PlayListThreadFactory: TThreadFactory;
begin
  FSingleSound := TSingleSound.Create;

  // FTimelineTrackerThread уничтожается через фабрику в которой зарегистрирован
  // Отдельно его уничтожать не нужно
  // Фабрика уничтожается при загрытии главного окна
  FTimelineTrackerThread := TTimelineTrackerThread.Create(
    AThreadFactory,
//    TPlayController.SingleSound,
    ATimelineCaret,
    ADurationBar,
    ACurrentTimeLabel);

  PlayListThreadFactory := AThreadFactoryRegistry.CreateThreadFactory;
  PlayListThreadFactory.ThreadFactoryName := 'PlayListThreadFactory';

  FPlayList := TPlayList.Create(PlayListThreadFactory);
end;

class procedure TPlayController.UnInit;
begin
  FreeAndNil(FPlayList);
  FreeAndNil(FSingleSound);
end;

class procedure TPlayController.SetCurrentTime(const ACurrentTime: TMediaTime);
var
  X: Single;
  CurrentTime: TMediaTime;
begin
  X := TTools.TimeToCaretPosition(ACurrentTime);
  TTools.RenderTimelineCaretPosition(X);

  CurrentTime := ACurrentTime;
  MainForm.CurrentTimeLabel.Text := TStringTools.GetHumanTime(CurrentTime, MediaTimeScale);
  FSingleSound.CurrentTime := CurrentTime;
  // Если каретку увели максимально вправо,
  // то CurrentTime становится равным Duration
  // и плеер автоматически останавливает воспроизведение
  // По этому проверяем текущий статус воспроизведения и запускаем если он psPlay
  if TState.PlayState = psPlay then
    FSingleSound.Play;
end;

class function TPlayController.GetCurrentTime: TMediaTime;
begin
  Result := FSingleSound.CurrentTime;
end;

class procedure TPlayController.SetVolume(const AVolume: Single);
var
  X: Single;
begin
  TState.LastVolume := TState.Volume;
  TState.Volume := AVolume;
  FSingleSound.Volume := TState.Volume;

  X := TTools.VolumeToVolumeCaretPosition(TState.Volume);
  TTools.RenderVolumeCaretPosition(X);

  if TState.Volume = 0 then
    TVisualScheme.AssignBitmap(MainForm.SoundControl, BITMAP_MUTE_IDENT)
  else
    TVisualScheme.AssignBitmap(MainForm.SoundControl, BITMAP_SOUND_IDENT);
end;

class procedure TPlayController.Play;
var
  LastPlayState: TPlayState;
  FileName: String;
begin
  if TPlayController.PlayList.Count = 0 then
  begin
    HeighlightFail(MainForm.PlayControl);

    Exit;
  end;

  FileName := FSingleSound.FileName;
  if FileName.IsEmpty then
    Exit;

  LastPlayState := TState.PlayState;

  FSingleSound.Play;
  FTimelineTrackerThread.UnHoldThread;

  TState.PlayState := psPlay;

  if LastPlayState = psPlay then
    Exit;

  TVisualScheme.AssignBitmap(MainForm.PlayControl, BITMAP_PLAY_IDENT);
  TTools.DisplayCurrentComposition;
  TTools.RenderPlayState(TState.PlayState);
end;

class procedure TPlayController.Stop;
var
  LastPlayState: TPlayState;
begin
  LastPlayState := TState.PlayState;

  FSingleSound.Stop;
  FTimelineTrackerThread.HoldThread;

  TState.PlayState := psStop;

  if LastPlayState = psStop then
    Exit;

  if LastPlayState = psPause then
    Exit;

  TVisualScheme.AssignBitmap(MainForm.PlayControl, BITMAP_PAUSE_IDENT);
  TTools.RenderPlayState(TState.PlayState);
end;

class procedure TPlayController.Pause;
var
  LastPlayState: TPlayState;
begin
  LastPlayState := TState.PlayState;

  FSingleSound.Pause;
  FTimelineTrackerThread.HoldThread;

  TState.PlayState := psPause;

  if LastPlayState = psPause then
    Exit;

  TVisualScheme.AssignBitmap(MainForm.PlayControl, BITMAP_PAUSE_IDENT);
  TTools.RenderPlayState(TState.PlayState);
end;

class procedure TPlayController.Mute;
begin
  TState.LastVolume := TState.Volume;
  Volume := 0;
end;

class procedure TPlayController.UnMute;
begin
  Volume := TState.LastVolume;
end;

class procedure TPlayController.BackwardRewind;
begin
  FTimelineTrackerThread.RewindDirection := rdBackward;
  FTimelineTrackerThread.UnHoldThread;
end;

class procedure TPlayController.ForwardRewind;
begin
  FTimelineTrackerThread.RewindDirection := rdForward;
  FTimelineTrackerThread.UnHoldThread;
end;

class procedure TPlayController.BackwardRewindStep;
begin
  FTimelineTrackerThread.BackwardRewind;
end;

class procedure TPlayController.ForwardRewindStep;
begin
  FTimelineTrackerThread.ForwardRewind;
end;

class procedure TPlayController.StopRewind;
begin
  FTimelineTrackerThread.RewindDirection := rdNone;

  case TState.PlayState of
    psPlay: Play;
    psPause: Pause;
    psStop: Stop;
  end;
end;

class procedure TPlayController.First;
begin
  Stop;
  SetFirst;
  Play;
end;

class procedure TPlayController.Prev;
var
  LastPlayState: TPlayState;
begin
  LastPlayState := TState.PlayState;
  Stop;
  SetPrev;
  CurrentTime := 0;
  if LastPlayState = psPlay then
    Play;
end;

class procedure TPlayController.Next;
var
  LastPlayState: TPlayState;
begin
  LastPlayState := TState.PlayState;
  Stop;
  CopyThenNext;
  CurrentTime := 0;
  if LastPlayState = psPlay then
    Play;
end;

class procedure TPlayController.Current(
  const APlayState: TPlayState;
  const ACurrentTime: TMediaTime);
begin
  Stop;
  SetCurrent;
  CurrentTime := ACurrentTime;
  if APlayState = psPlay then
    Play;
end;

class procedure TPlayController.GetCurrentCompositonInfo(
  out ATitle: String;
  out APath: String);
var
  PlayItem: TPlayItem;
begin
  ATitle := '';
  APath := '';

  PlayItem := FPlayList.Current;
  ATitle := PlayItem.Title;
  APath := PlayItem.Path;
end;

class function TPlayController.SetPlayItem(const APlayItem: TPlayItem): Boolean;
var
  PlayItem: TPlayItem;
begin
  Result := false;

  PlayItem :=  APlayItem;
  if not Assigned(PlayItem) then
    Exit;

  FSingleSound.FileName := PlayItem.Path;
  MainForm.DurationLabel.Text :=
    TStringTools.GetHumanTime(PlayItem.Duration, MediaTimeScale);

  Result := true;
end;

class function TPlayController.SetFirst: Boolean;
begin
  Result := SetPlayItem(FPlayList.First);
end;

class function TPlayController.SetPrev: Boolean;
begin
  Result := SetPlayItem(FPlayList.Prev);
end;

class function TPlayController.SetNext: Boolean;
begin
  Result := SetPlayItem(FPlayList.Next);
end;

class function TPlayController.SetCurrent: Boolean;
begin
  Result := SetPlayItem(FPlayList.Current);
end;

class procedure TPlayController.MountCurrentTime;
var
  X: Single;
begin
  X := TTools.ReadCaretPosition(MainForm.TimeLineControl);
  CurrentTime := TTools.TimelineCaretPositionToTime(X);
end;

class procedure TPlayController.MountVolume;
var
  X: Single;
begin
  X := TTools.ReadCaretPosition(MainForm.VolumeControl);
  Volume := TTools.VolumeCaretPositionToVolume(X);
end;

class procedure TPlayController.OffHeighlight(const AControlsArray: array of TControl);
var
  i: Integer;
begin
  for i := 0 to Pred(Length(AControlsArray)) do
  begin
    TTools.GlowEffectActivated(
      HEIGHLIGTH_GLOW_EFFECT_IDENT,
      AControlsArray[i],
      false);
  end;
end;

class procedure TPlayController.HeighlightMarkMode;
begin
  TTools.GlowEffectActivated(
    HEIGHLIGTH_GLOW_EFFECT_IDENT,
    MainForm.MarkModeControl,
    TState.MarkMode);
end;

class procedure TPlayController.HeighlightCopyMode;
begin
  if TState.CopyMode = cmCopy then
  begin
    TTools.GlowEffectActivated(
      HEIGHLIGTH_GLOW_EFFECT_IDENT,
      MainForm.CopyModeControl,
      true);
    TTools.GlowEffectActivated(
      HEIGHLIGTH_GLOW_EFFECT_IDENT,
      MainForm.MoveModeControl,
      false);
  end
  else
  if TState.CopyMode = cmMove then
  begin
    TTools.GlowEffectActivated(
      HEIGHLIGTH_GLOW_EFFECT_IDENT,
      MainForm.CopyModeControl,
      false);
    TTools.GlowEffectActivated(
      HEIGHLIGTH_GLOW_EFFECT_IDENT,
      MainForm.MoveModeControl,
      true);
  end
  else
  if TState.CopyMode = cmNone then
  begin
    TTools.GlowEffectActivated(
      HEIGHLIGTH_GLOW_EFFECT_IDENT,
      MainForm.CopyModeControl,
      false);
    TTools.GlowEffectActivated(
      HEIGHLIGTH_GLOW_EFFECT_IDENT,
      MainForm.MoveModeControl,
      false)
  end;
end;

class procedure TPlayController.HeighlightLeafe;

  procedure _HeighlightOff(const AControlsArray: array of TControl);
  var
    i: Integer;
  begin
    for i := 0 to Pred(Length(AControlsArray)) do
    begin
      TTools.GlowEffectActivated(
        HEIGHLIGTH_GLOW_EFFECT_IDENT,
        AControlsArray[i],
        false);
    end;
  end;

var
  LeafeControl: TControl;
begin
  _HeighlightOff([
    MainForm.TopLeftControl,
    MainForm.TopRightControl,
    MainForm.BottomLeftControl,
    MainForm.BottomRightControl
  ]);

  LeafeControl := TTools.LeafeToControl(TState.Leafe);
  if Assigned(LeafeControl) then
    TTools.GlowEffectActivated(
      HEIGHLIGTH_GLOW_EFFECT_IDENT,
      LeafeControl,
      true);
end;

class procedure TPlayController.HeighlightFail(const AControl: TControl);
var
  ThreadName: String;
  Thread: TThreadExt;
  HeighlightFailThread: THeighlightFailThread;
begin
  ThreadName := Concat('THeighlightFailThread', AControl.Name);
  Thread := MainForm.ThreadFactory.FindThread(ThreadName);

  if Assigned(Thread) then
  begin
    HeighlightFailThread := Thread as THeighlightFailThread;
    if not HeighlightFailThread.Terminated then
    begin
      HeighlightFailThread.OnAfterDestroyProcRef :=
        procedure
        begin
          THeighlightFailThread.Create(
            MainForm.ThreadFactory,
            ThreadName,
            AControl);
        end;
      HeighlightFailThread.Terminate;
      HeighlightFailThread.UnHoldThread;
    end;
  end
  else
    THeighlightFailThread.Create(
      MainForm.ThreadFactory,
      ThreadName,
      AControl);
end;

class procedure TPlayController.HeighlightSetOfPaths;
var
  SetOfPathsControl: TControl;
begin
  OffHeighlight([
    MainForm.SetOfPathsNumber1Control,
    MainForm.SetOfPathsNumber2Control,
    MainForm.SetOfPathsNumber3Control,
    MainForm.SetOfPathsNumber4Control
  ]);

  SetOfPathsControl := TTools.SetOfPathsIndexToControl(TState.SetOfPathsIndex);
  if Assigned(SetOfPathsControl) then
    TTools.GlowEffectActivated(
      HEIGHLIGTH_GLOW_EFFECT_IDENT,
      SetOfPathsControl,
      true);
end;

class procedure TPlayController.LeafeClicked(Sender: TObject);
var
  Control: TControl;
  Leafe: TLeafe;
begin
  Control := Sender as TControl;

  if TState.CopyMode = TCopyMode.cmNone then
  begin
    HeighlightFail(Control);

    Exit;
  end;

  Leafe := TTools.ControlToLeafe(Control);
  if Leafe = TLeafe.liNone then
    Exit;

  if Leafe.ToPath.IsEmpty then
  begin
    HeighlightFail(Control);

    Exit;
  end;

  if Leafe = TState.Leafe then
    TState.Leafe := liNone
  else
    TState.Leafe := Leafe;

  HeighlightLeafe;

  if not TState.MarkMode then
    TPlayController.Next;
end;

class procedure TPlayController.SetOfPathClicked(Sender: TObject);
var
  Control: TControl;
begin
  Control := Sender as TControl;

  TState.SetOfPathsIndex := TTools.ControlToSetOfPathsIndex(Control);
end;

class procedure TPlayController.CopyThenNext;
var
  Path: String;
begin
  if TState.Leafe = liNone then
  begin
    SetNext;

    Exit;
  end;

  Path := TState.Leafe.ToPath;
  if TState.CopyMode = cmCopy then
  begin
    if TTools.CopyComposition(FPlayList.CurrentComposition, Path) then
      SetCurrent;
  end
  else
  if TState.CopyMode = cmMove then
  begin
    if TTools.MoveComposition(FPlayList.CurrentComposition, Path) then
    begin
      FPlayList.FreeItem(FPlayList.Current);
      SetNext;
    end;
  end;

  TState.Leafe := liNone;
  HeighlightLeafe;
end;

end.
