unit TimelineTrackerThreadUnit;

interface

uses
    FMX.Controls
  , ThreadFactoryUnit
  , FMX.SingleSoundUnit
  ;

type
  TTimelineTrackerThread = class(TThreadExt)
  strict private
    FSingleSound: TSingleSound;
    FTimelineCaret: TControl;
    FDurationBar: TControl;
    FCurrentTimeLabel: TControl;

    procedure RenderCaret;
  protected
    procedure Execute(const AThread: TThreadExt); reintroduce; // override;
  public
    constructor Create(
      const AThreadFactory: TThreadFactory;
      const ASingleSound: TSingleSound;
      const ATimelineCaret: TControl;
      const ADurationBar: TControl;
      const ACurrentTimeLabel: TControl); reintroduce;
  end;

implementation

uses
    System.Classes
  , System.SysUtils
  , System.Generics.Collections
  , FMX.StdCtrls
  , FMX.Media
  , MP3TAGsReaderUnit
  , StringToolsUnit
  ;

{ TTimelineTrackerThread }

constructor TTimelineTrackerThread.Create(
  const AThreadFactory: TThreadFactory;
  const ASingleSound: TSingleSound;
  const ATimelineCaret: TControl;
  const ADurationBar: TControl;
  const ACurrentTimeLabel: TControl);
begin
  FSingleSound := ASingleSound;
  FTimelineCaret := ATimelineCaret;
  FDurationBar := ADurationBar;
  FCurrentTimeLabel := ACurrentTimeLabel;

  inherited Create(
    AThreadFactory,
    'TTimelineTrackerThread',
    Execute,
    false);
end;

procedure TTimelineTrackerThread.RenderCaret;
var
  Duration: Single;
  CurrentTime: TMediaTime;
begin
  CurrentTime := FSingleSound.CurrentTime;
  Duration := FSingleSound.Duration;

  if Duration = 0 then
    Duration := 1;

  Queue(
    procedure
    begin
      FTimelineCaret.Position.X :=
        (CurrentTime * (FDurationBar.Width / Duration)) - (FTimelineCaret.Width / 2);

      TLabel(FCurrentTimeLabel).Text :=
        TStringTools.GetHumanTime(CurrentTime, MediaTimeScale);
    end
  );
end;

procedure TTimelineTrackerThread.Execute;
begin
  HoldThread;
  ExecHold;

  while not Terminated do
  begin
    while not Terminated and not IntentionHoldState do
    begin
      if FSingleSound.CurrentTime >= FSingleSound.Duration then
      begin

      end
      else
        RenderCaret;

      Sleep(400);
    end;

    ExecHold;
  end;
end;

end.
