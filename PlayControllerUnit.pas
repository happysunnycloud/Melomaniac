unit PlayControllerUnit;

interface

uses
    FMX.Controls
  , ThreadFactoryUnit
  , TimelineTrackerThreadUnit
  , FMX.SingleSoundUnit
  ;

type
  TPlayController = class
  strict private
    class var FSingleSound: TSingleSound;
    class var FTimelineTrackerThread: TTimelineTrackerThread;
  public
    class procedure Init(
      const AThreadFactory: TThreadFactory;
      const ATimelineCaret: TControl;
      const ADurationBar: TControl;
      const ACurrentTimeLabel: TControl);
    class procedure UnInit;

    class property SingleSound: TSingleSound read FSingleSound;

    class procedure Play;
    class procedure Stop;
    class procedure Pause;
  end;

implementation

uses
    System.SysUtils
  ;

{ TPlayController }

class procedure TPlayController.Init(
  const AThreadFactory: TThreadFactory;
  const ATimelineCaret: TControl;
  const ADurationBar: TControl;
  const ACurrentTimeLabel: TControl);
begin
  FSingleSound := TSingleSound.Create;

  // FTimelineTrackerThread уничтожаетс€ через фабрику в которой зарегистрирован
  // ќтдельно его уничтожать не нужно
  // ‘абрика уничтожаетс€ при загрытии главного окна
  FTimelineTrackerThread := TTimelineTrackerThread.Create(
    AThreadFactory,
    TPlayController.SingleSound,
    ATimelineCaret,
    ADurationBar,
    ACurrentTimeLabel);
end;

class procedure TPlayController.UnInit;
begin
  FreeAndNil(FSingleSound);
end;

class procedure TPlayController.Play;
begin
  FSingleSound.Play;
  FTimelineTrackerThread.UnHoldThread;
end;

class procedure TPlayController.Stop;
begin
  FSingleSound.Stop;
  FTimelineTrackerThread.HoldThread;
end;

class procedure TPlayController.Pause;
begin
  FSingleSound.Pause;
  FTimelineTrackerThread.HoldThread;
end;

end.
