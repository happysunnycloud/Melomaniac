unit TimelineTrackerThreadUnit;

interface

uses
    System.SyncObjs
  , FMX.Controls
  , ThreadFactoryUnit
  , FMX.SingleSoundUnit
  ;

type
  TRewindDirection = (rdNone = 0, rdForward = 1, rdBackward = 2);

  TTimelineTrackerThread = class(TThreadExt)
  strict private
    FCriticalSection: TCriticalSection;
    FSingleSound: TSingleSound;
    FTimelineCaret: TControl;
    FDurationBar: TControl;
    FCurrentTimeLabel: TControl;
    FRewindDirection: TRewindDirection;

    procedure RenderCaret;

    function GetRewindDirection: TRewindDirection;
    procedure SetRewindDirection(const ARewindDirection: TRewindDirection);
  protected
    procedure Execute(const AThread: TThreadExt); reintroduce; // override;
  public
    constructor Create(
      const AThreadFactory: TThreadFactory;
      const ASingleSound: TSingleSound;
      const ATimelineCaret: TControl;
      const ADurationBar: TControl;
      const ACurrentTimeLabel: TControl); reintroduce;
    destructor Destroy; override;

    function BackwardRewind: Boolean;
    function ForwardRewind: Boolean;

    property RewindDirection: TRewindDirection
      read GetRewindDirection write SetRewindDirection;
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
  , PlayControllerUnit
  , ConstantsUnit
  ;

{ TTimelineTrackerThread }

constructor TTimelineTrackerThread.Create(
  const AThreadFactory: TThreadFactory;
  const ASingleSound: TSingleSound;
  const ATimelineCaret: TControl;
  const ADurationBar: TControl;
  const ACurrentTimeLabel: TControl);
begin
  FCriticalSection := TCriticalSection.Create;

  FSingleSound := ASingleSound;
  FTimelineCaret := ATimelineCaret;
  FDurationBar := ADurationBar;
  FCurrentTimeLabel := ACurrentTimeLabel;
  FRewindDirection := rdNone;

  inherited Create(
    AThreadFactory,
    'TTimelineTrackerThread',
    Execute,
    false);
end;

destructor TTimelineTrackerThread.Destroy;
begin
  FreeAndNil(FCriticalSection);

  inherited;
end;

function TTimelineTrackerThread.BackwardRewind: Boolean;
var
  NewTime: TMediaTime;
begin
  Result := true;

  NewTime := FSingleSound.CurrentTime - (REWIND_TIME * MediaTimeScale);
  if NewTime >= 0 then
    FSingleSound.CurrentTime := NewTime
  else
  begin
    FSingleSound.CurrentTime := 0;

    Exit(false);
  end;

  RenderCaret;
end;

function TTimelineTrackerThread.ForwardRewind: Boolean;
var
  NewTime: TMediaTime;
begin
  Result := true;

  NewTime := FSingleSound.CurrentTime + (REWIND_TIME * MediaTimeScale);
  if NewTime <= FSingleSound.Duration then
    FSingleSound.CurrentTime := NewTime
  else
    Exit(false);

  RenderCaret;
end;

function TTimelineTrackerThread.GetRewindDirection: TRewindDirection;
begin
  FCriticalSection.Enter;
  try
    Result := FRewindDirection;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TTimelineTrackerThread.SetRewindDirection(
  const ARewindDirection: TRewindDirection);
begin
  FCriticalSection.Enter;
  try
    FRewindDirection := ARewindDirection;
  finally
    FCriticalSection.Leave;
  end;
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
        Queue(nil,
          procedure
          begin
            TPlayController.Next;
          end);
      end
      else
      begin
        if RewindDirection <> rdNone then
        begin
          while not Terminated and (RewindDirection <> rdNone) do
          begin
            if RewindDirection = rdBackward then
            begin
              if not BackwardRewind then
                Break;
            end
            else
            if RewindDirection = rdForward then
            begin
              if not ForwardRewind then
                Break;
            end;

            RenderCaret;

            Sleep(100);
          end;
        end;
      end;

      RenderCaret;

      Sleep(400);
    end;

    ExecHold;
  end;
end;

end.
