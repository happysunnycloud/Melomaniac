unit PlayControllerUnit;

interface

uses
    FMX.Controls
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
  public
    class procedure Init(
      const AThreadFactory: TThreadFactory;
      const AThreadFactoryRegistry: TThreadFactoryRegistry;
      const ATimelineCaret: TControl;
      const ADurationBar: TControl;
      const ACurrentTimeLabel: TControl);
    class procedure UnInit;

    class property SingleSound: TSingleSound read FSingleSound;
    class property PlayList: TPlayList read FPlayList;

    class procedure Play;
    class procedure Stop;
    class procedure Pause;
    class procedure BackwardRewind;
    class procedure ForwardRewind;
    class procedure BackwardRewindStep;
    class procedure ForwardRewindStep;
    class procedure StopRewind;

    class procedure SetPrev;
    class procedure SetNext;
  end;

implementation

uses
    System.SysUtils
  , StateUnit
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

class procedure TPlayController.Play;
begin
  FSingleSound.Play;
  FTimelineTrackerThread.UnHoldThread;

  TState.PlayState := psPlay;
end;

class procedure TPlayController.Stop;
begin
  FSingleSound.Stop;
  FTimelineTrackerThread.HoldThread;

  TState.PlayState := psStop;
end;

class procedure TPlayController.Pause;
begin
  FSingleSound.Pause;
  FTimelineTrackerThread.HoldThread;

  TState.PlayState := psPause;
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

class procedure TPlayController.SetPrev;
begin
  FSingleSound.FileName := FPlayList.Prev.Path;
end;

class procedure TPlayController.SetNext;
begin
  FSingleSound.FileName := FPlayList.Next.Path;
end;

end.
