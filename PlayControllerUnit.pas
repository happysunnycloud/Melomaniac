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

    class procedure PlayNext;
  end;

implementation

uses
    System.SysUtils
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

  // FTimelineTrackerThread уничтожаетс€ через фабрику в которой зарегистрирован
  // ќтдельно его уничтожать не нужно
  // ‘абрика уничтожаетс€ при загрытии главного окна
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

class procedure TPlayController.PlayNext;
begin
  Stop;
  FSingleSound.FileName := FPlayList.Next.Path;
  Play;
end;

end.
