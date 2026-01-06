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

    FClickedProcRef: TProcRef;
    FPressedProcRef: TProcRef;
    FSender: TObject;

    function GetIsButtonUp: Boolean;
    procedure SetIsButtonUp(const AIsButtonUp: Boolean);

    function GetClickedProcRef: TProcRef;
    procedure SetClickedProcRef(const AProcRef: TProcRef);

    function GetPressedProcRef: TProcRef;
    procedure SetPressedProcRef(const AProcRef: TProcRef);

    function GetSender: TObject;
    procedure SetSender(const ASender: TObject);
  protected
    procedure Execute(const AThread: TThreadExt); reintroduce; // override;
  public
    constructor Create(const AThreadFactory: TThreadFactory);
    destructor Destroy; override;

    procedure SetClickParams(
      const AClickedProc: TProcRef;
      const ASender: TObject); overload;

    procedure SetClickParams(
      const AClickedProc: TProcRef;
      const APressedProc: TProcRef;
      const ASender: TObject); overload;

    property IsButtonUp: Boolean read GetIsButtonUp write SetIsButtonUp;

    property ClickedProcRef: TProcRef
      read GetClickedProcRef write SetClickedProcRef;
    property PressedProcRef: TProcRef
      read GetPressedProcRef write SetPressedProcRef;
    property Sender: TObject
      read GetSender write SetSender;
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

  FClickedProcRef := nil;
  FPressedProcRef := nil;
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
    if not FIsButtonUp then
      UnHoldThread;
  finally
    FCriticalSection.Leave;
  end;
end;

function TClickListenerThread.GetClickedProcRef: TProcRef;
begin
  FCriticalSection.Enter;
  try
    Result := FClickedProcRef;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TClickListenerThread.SetClickedProcRef(const AProcRef: TProcRef);
begin
  FCriticalSection.Enter;
  try
    FClickedProcRef := AProcRef
  finally
    FCriticalSection.Leave;
  end;
end;

function TClickListenerThread.GetPressedProcRef: TProcRef;
begin
  FCriticalSection.Enter;
  try
    Result := FPressedProcRef;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TClickListenerThread.SetPressedProcRef(const AProcRef: TProcRef);
begin
  FCriticalSection.Enter;
  try
    FPressedProcRef := AProcRef
  finally
    FCriticalSection.Leave;
  end;
end;

function TClickListenerThread.GetSender: TObject;
begin
  FCriticalSection.Enter;
  try
    Result := FSender;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TClickListenerThread.SetSender(const ASender: TObject);
begin
  FCriticalSection.Enter;
  try
    FSender := ASender;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TClickListenerThread.SetClickParams(
  const AClickedProc: TProcRef;
  const ASender: TObject);
begin
  FClickedProcRef := AClickedProc;
  FPressedProcRef := nil;
  FSender := ASender;

  IsButtonUp := false;
end;

procedure TClickListenerThread.SetClickParams(
  const AClickedProc: TProcRef;
  const APressedProc: TProcRef;
  const ASender: TObject);
begin
  FClickedProcRef := AClickedProc;
  FPressedProcRef := APressedProc;
  FSender := ASender;

  IsButtonUp := false;
end;

procedure TClickListenerThread.Execute(const AThread: TThreadExt);
const
  HOLD_TIME = 200;
  SLEEP_TIME = 10;
var
  Countdown: Integer;
  ClickedProcRef: TProcRef;
  PressedProcRef: TProcRef;
  Sender: TObject;
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

    HoldThread;

    if Terminated then
      Exit;

    if Countdown <= 0 then
    begin
      Sender := Self.Sender;
      PressedProcRef := Self.PressedProcRef;
      if Assigned(PressedProcRef) then
      begin
        ForceQueue(nil,
          procedure
          begin
            PressedProcRef(Sender);
          end);
      end;
    end
    else
    begin
      Sender := Self.Sender;
      ClickedProcRef := Self.ClickedProcRef;
      if Assigned(ClickedProcRef) then
      begin
        ForceQueue(nil,
          procedure
          begin
            ClickedProcRef(Sender);
          end);
      end;
    end;

    if Terminated then
      Exit;

    ExecHold;
  end;
end;

end.
