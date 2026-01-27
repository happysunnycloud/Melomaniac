unit HeighlightFailThreadUnit;

interface

uses
    System.Classes
  , System.SyncObjs
  , FMX.Controls
  , ThreadFactoryUnit
  ;

type
  TAfterDestroyProcRef = reference to procedure;

  THeighlightFailThread = class(TThreadExt)
  strict private
    FCriticalSection: TCriticalSection;
    FControl: TControl;
    FOnAfterDestroyProcRef: TAfterDestroyProcRef;

    procedure SetAfterDestroyProcRef(
      const AAfterDestroyProcRef: TAfterDestroyProcRef);
  protected
    procedure InnerExecute; override;
  public
    constructor Create(
      const AThreadFactory: TThreadFactory;
      const AThreadName: String;
      const AControl: TControl); reintroduce;

    destructor Destroy; override;

    property OnAfterDestroyProcRef: TAfterDestroyProcRef
      write SetAfterDestroyProcRef;
  end;

implementation

uses
    System.SysUtils
  , System.Generics.Collections
  , FMX.StdCtrls
  , ToolsUnit
  , ConstantsUnit
  ;

{ THeighlightFailThread }

constructor THeighlightFailThread.Create(
  const AThreadFactory: TThreadFactory;
  const AThreadName: String;
  const AControl: TControl);
begin
  FCriticalSection := TCriticalSection.Create;
  FControl := AControl;
  FOnAfterDestroyProcRef := nil;

  FreeOnTerminate := true;

  inherited Create(
    AThreadFactory,
    AThreadName);
end;

destructor THeighlightFailThread.Destroy;
var
  _OnAfterDestroyProcRef: TAfterDestroyProcRef;
begin
  FreeAndNil(FCriticalSection);

  inherited;

  if Assigned(FOnAfterDestroyProcRef) then
  begin
    _OnAfterDestroyProcRef := FOnAfterDestroyProcRef;
    TThread.ForceQueue(nil,
      procedure
      begin
        _OnAfterDestroyProcRef;
      end);
  end;
end;

procedure THeighlightFailThread.SetAfterDestroyProcRef(
  const AAfterDestroyProcRef: TAfterDestroyProcRef);
begin
  FCriticalSection.Enter;
  try
    FOnAfterDestroyProcRef := AAfterDestroyProcRef;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure THeighlightFailThread.InnerExecute;
var
  Control: TControl;
  Count: Integer;
begin
  Control := FControl;
  Count := 20;

  Queue(nil,
    procedure
    begin
      TTools.GlowEffectActivated(
        GLOW_EFFECT_IDENT,
        Control,
        false);

      TTools.GlowEffectActivated(
        HEIGHLIGTH_GLOW_EFFECT_IDENT,
        Control,
        false);

      TTools.GlowEffectActivated(
        FAIL_HEIGHLIGTH_GLOW_EFFECT_IDENT,
        Control,
        true);
    end
  );

  while (Count > 0) and not Terminated do
  begin
    Dec(Count);

    Sleep(100);
  end;

  Queue(nil,
    procedure
    begin
      TTools.GlowEffectActivated(
        FAIL_HEIGHLIGTH_GLOW_EFFECT_IDENT,
        Control,
        false);

      if TTools.IsMouseOverControl(Control) then
        TTools.GlowEffectActivated(
          GLOW_EFFECT_IDENT,
          Control,
          true);
    end
  );

  if not Terminated then
  begin
    HoldThread;
    ExecHold;
  end;
end;


end.
