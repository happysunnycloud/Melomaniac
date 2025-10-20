unit ClickListenerThreadUnit;

interface

uses
    System.SyncObjs
  , ThreadFactoryUnit
  ;

type
  TProcRef = reference to procedure (Sender: TObject);

  TClickListenerThread = class(TThreadExt)
  strict private
    FCriticalSection: TCriticalSection;

    FIsButtonUp: Boolean;

    FPressedProcRef: TProcRef;
    FClickedProcRef: TProcRef;
    FSender: TObject;

    function GetIsButtonUp: Boolean;
    procedure SetIsButtonUp(const AIsButtonUp: Boolean);
  protected
    procedure Execute(const AThread: TThreadExt); reintroduce; // override;
  public
    constructor Create(const AThreadFactory: TThreadFactory);
    destructor Destroy; override;

    procedure SetClickParams(
      const APressedProc: TProcRef;
      const AClickedProc: TProcRef;
      const ASender: TObject);

    property IsButtonUp: Boolean read GetIsButtonUp write SetIsButtonUp;
  end;

implementation

uses
    System.SysUtils
  ;

{ TClickListenerThread }

constructor TClickListenerThread.Create(
  const AThreadFactory: TThreadFactory);
begin
  FCriticalSection := TCriticalSection.Create;

  FIsButtonUp := false;

  FPressedProcRef := nil;
  FClickedProcRef := nil;

  FSender := nil;

  inherited Create(
    AThreadFactory,
    'TClickListenerThread',
    Execute);
end;

destructor TClickListenerThread.Destroy;
begin
  FreeAndNil(FCriticalSection);

  inherited;
end;

function TClickListenerThread.GetIsButtonUp: Boolean;
begin
  FCriticalSection.Enter;
  try
    Result := FIsButtonUp;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TClickListenerThread.SetIsButtonUp(const AIsButtonUp: Boolean);
begin
  FCriticalSection.Enter;
  try
    FIsButtonUp := AIsButtonUp;
    if FIsButtonUp then
      HoldThread
    else
      UnHoldThread;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TClickListenerThread.SetClickParams(
  const APressedProc: TProcRef;
  const AClickedProc: TProcRef;
  const ASender: TObject);
begin
  FPressedProcRef := APressedProc;
  FClickedProcRef := AClickedProc;
  FSender := ASender;

  IsButtonUp := false;
end;

procedure TClickListenerThread.Execute(const AThread: TThreadExt);
const
  HOLD_TIME = 200;
  SLEEP_TIME = 10;
var
  Countdown: Integer;
begin
  HoldThread;
  ExecHold;

  while not Terminated do
  begin
    Countdown := HOLD_TIME div SLEEP_TIME;
    while not Terminated and not IsButtonUp and (Countdown > 0) do
    begin
      Sleep(SLEEP_TIME);
      Dec(Countdown);
    end;

    if Terminated then
      Exit;

    if Countdown <= 0 then
    begin
      IsButtonUp := true;

      if Assigned(FPressedProcRef) then
        Queue(nil,
          procedure
          begin
            FPressedProcRef(FSender);

            FPressedProcRef := nil;
            FClickedProcRef := nil;
            FSender := nil;
          end);
    end
    else
    begin
      if Assigned(FClickedProcRef) then
        Queue(nil,
          procedure
          begin
            FClickedProcRef(FSender);

            FPressedProcRef := nil;
            FClickedProcRef := nil;
            FSender := nil;
          end);
    end;

    ExecHold;
  end;
end;

end.
