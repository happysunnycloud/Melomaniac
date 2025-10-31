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
  ;

type
  TPlayController = class
  strict private
    class var FSingleSound: TSingleSound;
    class var FTimelineTrackerThread: TTimelineTrackerThread;
    class var FPlayList: TPlayList;

    class procedure SetTime(const ATime: TMediaTime); static;
    class procedure SetVolume(const AVolume: Single); static;

    class procedure SetFirst;
    class procedure SetPrev;
    class procedure SetNext;
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
    class property Time: TMediaTime write SetTime;
    class property Volume: Single write SetVolume;
    class property TimelineTrackerThread: TTimelineTrackerThread read FTimelineTrackerThread;

    class procedure Play;
    class procedure Stop;
    class procedure Pause;
    class procedure Mute;
    class procedure Sound;
    class procedure BackwardRewind;
    class procedure ForwardRewind;
    class procedure BackwardRewindStep;
    class procedure ForwardRewindStep;
    class procedure StopRewind;
    class procedure First;
    class procedure Prev;
    class procedure Next;

    class procedure GetCurrentCompositonInfo(
      out ATitle: String;
      out APath: String);

    class procedure MountCurrentTime;
    class procedure MountVolume;
  end;

implementation

uses
    System.SysUtils
  , StateUnit
  , ToolsUnit
  , StringToolsUnit
  , MelomaniacUnit
  , VisualSchemeUnit
  , ConstantsUnit
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
    TPlayController.SingleSound,
    ATimelineCaret,
    ADurationBar,
    ACurrentTimeLabel);

  PlayListThreadFactory := AThreadFactoryRegistry.CreateThreadFactory;

  FPlayList := TPlayList.Create(PlayListThreadFactory);
end;

class procedure TPlayController.UnInit;
begin
  FreeAndNil(FPlayList);
  FreeAndNil(FSingleSound);
end;

class procedure TPlayController.SetTime(const ATime: TMediaTime);
var
  X: Single;
  CurrentTime: TMediaTime;
begin
  X := TTools.TimeToCaretPosition(ATime);
  TTools.RenderTimelineCaretPosition(X);

  CurrentTime := ATime;
  MainForm.CurrentTimeLabel.Text := TStringTools.GetHumanTime(CurrentTime, MediaTimeScale);
  FSingleSound.CurrentTime := CurrentTime;
  // Если каретку увели максимально вправо,
  // то CurrentTime становится равным Duration
  // и плеер автоматически останавливает воспроизведение
  // По этому проверяем текущий статус воспроизведения и запускаем если он psPlay
  if TState.PlayState = psPlay then
    FSingleSound.Play;
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
begin
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

class procedure TPlayController.Sound;
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
  TState.LastPlayState := TState.PlayState;
  Stop;
  SetFirst;
  if TState.LastPlayState = psPlay then
    Play;
end;

class procedure TPlayController.Prev;
begin
  TState.LastPlayState := TState.PlayState;
  Stop;
  SetPrev;
  if TState.LastPlayState = psPlay then
    Play;
end;

class procedure TPlayController.Next;
begin
  TState.LastPlayState := TState.PlayState;
  Stop;
  SetNext;
  if TState.LastPlayState = psPlay then
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

class procedure TPlayController.SetFirst;
begin
  FSingleSound.FileName := FPlayList.First.Path;
end;

class procedure TPlayController.SetPrev;
begin
  FSingleSound.FileName := FPlayList.Prev.Path;
end;

class procedure TPlayController.SetNext;
begin
  FSingleSound.FileName := FPlayList.Next.Path;
end;

class procedure TPlayController.MountCurrentTime;
var
  X: Single;
begin
  X := TTools.ReadCaretPosition(MainForm.TimeLineControl);
  Time := TTools.TimelineCaretPositionToTime(X);
end;

class procedure TPlayController.MountVolume;
var
  X: Single;
begin
  X := TTools.ReadCaretPosition(MainForm.VolumeControl);
  Volume := TTools.VolumeCaretPositionToVolume(X);
end;

end.
