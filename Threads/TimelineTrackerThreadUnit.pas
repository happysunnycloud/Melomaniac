unit TimelineTrackerThreadUnit;

interface

uses
    System.Classes
  , System.SyncObjs
  , FMX.Controls
  , ThreadFactoryUnit
  , FMX.SingleSoundUnit
  ;

type
  TTimelineTrackerThread = class(TThreadExt)
  strict private
    FCriticalSection: TCriticalSection;
    FTimelineCaret: TControl;
    FDurationBar: TControl;
    FCurrentTimeLabel: TControl;
    FRenderEvent: TEvent;

    procedure RenderCaret;
  protected
    procedure InnerExecute; override;
  public
    constructor Create(
      const AThreadFactory: TThreadFactory;
//      const ASingleSound: TSingleSound;
      const ATimelineCaret: TControl;
      const ADurationBar: TControl;
      const ACurrentTimeLabel: TControl); reintroduce;
    destructor Destroy; override;

    function BackwardRewind: Boolean;
    function ForwardRewind: Boolean;
  end;

implementation

uses
    System.SysUtils
  , System.Generics.Collections
  , FMX.StdCtrls
  , FMX.Media
  , MP3TAGsReaderUnit
  , PlayControllerUnit
  , ConstantsUnit
  ;

{ TTimelineTrackerThread }

constructor TTimelineTrackerThread.Create(
  const AThreadFactory: TThreadFactory;
//  const ASingleSound: TSingleSound;
  const ATimelineCaret: TControl;
  const ADurationBar: TControl;
  const ACurrentTimeLabel: TControl);
begin
  FCriticalSection := TCriticalSection.Create;

  //FSingleSound := ASingleSound;
  FTimelineCaret := ATimelineCaret;
  FDurationBar := ADurationBar;
  FCurrentTimeLabel := ACurrentTimeLabel;
  FRenderEvent := TEvent.Create(nil, false, false, '');

  inherited Create(
    AThreadFactory);

  OnSetTerminateProcRef := (
    procedure
    begin
      FRenderEvent.SetEvent;
    end);
end;

destructor TTimelineTrackerThread.Destroy;
begin
  FreeAndNil(FRenderEvent);
  FreeAndNil(FCriticalSection);

  inherited;
end;

function TTimelineTrackerThread.BackwardRewind: Boolean;
var
  NewTime: TMediaTime;
begin
  Result := true;

  NewTime := TPlayController.SingleSound.CurrentTime - (REWIND_TIME * MediaTimeScale);
  if NewTime >= 0 then
    TPlayController.SingleSound.CurrentTime := NewTime
  else
  begin
    TPlayController.SingleSound.CurrentTime := 0;

    Exit(false);
  end;

  RenderCaret;
end;

function TTimelineTrackerThread.ForwardRewind: Boolean;
var
  NewTime: TMediaTime;
begin
  Result := true;

  NewTime := TPlayController.SingleSound.CurrentTime + (REWIND_TIME * MediaTimeScale);
  if NewTime <= TPlayController.SingleSound.Duration then
    TPlayController.SingleSound.CurrentTime := NewTime
  else
    Exit(false);

  RenderCaret;
end;

procedure TTimelineTrackerThread.RenderCaret;
var
  Duration: Single;
  CurrentTime: TMediaTime;
begin
  CurrentTime := TPlayController.SingleSound.CurrentTime;
  Duration := TPlayController.SingleSound.Duration;

  if Duration = 0 then
    Duration := 1;

  Queue(
    procedure
    begin
      FTimelineCaret.Position.X :=
        (CurrentTime * (FDurationBar.Width / Duration)) - (FTimelineCaret.Width / 2);

      TLabel(FCurrentTimeLabel).Text :=
        TSingleSound.GetHumanTime(CurrentTime);

      FRenderEvent.SetEvent;
    end
  );
end;

procedure TTimelineTrackerThread.InnerExecute;
begin
  HoldThread;
  ExecHold;

  while not Terminated do
  begin
    while not Terminated and not IntentionHoldState do
    begin
      if TPlayController.SingleSound.Duration > 0 then
      begin
        if TPlayController.SingleSound.CurrentTime >= TPlayController.SingleSound.Duration then
        begin
          ForceQueue(nil,
            procedure
            begin
              // Без Stop зависает на выполнени Stop внутри Next
              TPlayController.SingleSound.Stop;
            end);

          ForceQueue(nil,
            procedure
            begin
              TPlayController.Next;
            end);

          HoldThread;

          Break;
        end;

        FRenderEvent.ResetEvent;
        RenderCaret;
        FRenderEvent.WaitFor(INFINITE);

        Sleep(400);
      end;
    end;

    ExecHold;
  end;
end;

end.
