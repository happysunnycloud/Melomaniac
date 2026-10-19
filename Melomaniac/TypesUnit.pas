unit TypesUnit;

interface

uses
    System.SyncObjs
  , ThreadFactoryUnit
  ;

type
  TPlayListThreadFactory = class(TThreadFactory)
  strict private
//    FCriticalSection: TCriticalSection;
    FPath: String;
    FSyncPlayListStarted: Integer;
    FSyncPlayListReStarted: Integer;
    FNeenToSaveToDB: Integer;

    function GetPath: String;
    function GetIsSyncPlayListStarted: Boolean;
    function GetIsSyncPlayListReStarted: Boolean;
    function GetIsNeedToSaveToDB: Boolean;

    procedure SetPath(const AVal: String);
    procedure SetIsSyncPlayListStarted(const AVal: Boolean);
    procedure SetIsSyncPlayListReStarted(const AVal: Boolean);
    procedure SetISNeedToSaveToDB(const AVal: Boolean);
  public
    constructor Create(const AUnregProc: TUnregFromThreadFactoryProc); override;
    destructor Destroy; override;

    property Path: String
      read GetPath write SetPath;
    property IsSyncPlayListStarted: Boolean
      read GetIsSyncPlayListStarted write SetIsSyncPlayListStarted;
    property IsSyncPlayListReStarted: Boolean
      read GetIsSyncPlayListReStarted write SetIsSyncPlayListReStarted;
    property IsNeedToSaveToDB: Boolean
      read GetIsNeedToSaveToDB write SetIsNeedToSaveToDB;
  end;

implementation

uses
    System.SysUtils
  ;

{ TPlayListThreadFactory }

constructor TPlayListThreadFactory.Create(
  const AUnregProc: TUnregFromThreadFactoryProc);
begin
//  FCriticalSection := TCriticalSection.Create;

  FPath := '';

  FSyncPlayListStarted := 0;
  FSyncPlayListReStarted := 0;

  FNeenToSaveToDB := 0;

  inherited Create(AUnregProc);
end;

destructor TPlayListThreadFactory.Destroy;
begin
//  FreeAndNil(FCriticalSection);

  inherited;
end;

function TPlayListThreadFactory.GetPath: String;
begin
  CriticalSection.Enter;
  try
    Result := FPath;
  finally
    FreeAndNil(CriticalSection);
  end;
end;

function TPlayListThreadFactory.GetIsSyncPlayListStarted: Boolean;
begin
  Result := TInterlocked.CompareExchange(FSyncPlayListStarted, 1, 1) = 1;
end;

function TPlayListThreadFactory.GetIsSyncPlayListReStarted: Boolean;
begin
  Result := TInterlocked.CompareExchange(FSyncPlayListReStarted, 1, 1) = 1;
end;

function TPlayListThreadFactory.GetIsNeedToSaveToDB: Boolean;
begin
  Result := TInterlocked.CompareExchange(FNeenToSaveToDB, 1, 1) = 1;
end;

procedure TPlayListThreadFactory.SetPath(const AVal: String);
begin
  CriticalSection.Enter;
  try
    FPath := AVal;
  finally
    CriticalSection.Leave;
  end;
end;

procedure TPlayListThreadFactory.SetIsSyncPlayListStarted(
  const AVal: Boolean);
begin
  if AVal then
    TInterlocked.Exchange(FSyncPlayListStarted, 1)
  else
    TInterlocked.Exchange(FSyncPlayListStarted, 0)
end;

procedure TPlayListThreadFactory.SetIsSyncPlayListReStarted(
  const AVal: Boolean);
begin
  if AVal then
    TInterlocked.Exchange(FSyncPlayListReStarted, 1)
  else
    TInterlocked.Exchange(FSyncPlayListReStarted, 0)
end;

procedure TPlayListThreadFactory.SetISNeedToSaveToDB(const AVal: Boolean);
begin
  if AVal then
    TInterlocked.Exchange(FNeenToSaveToDB, 1)
  else
    TInterlocked.Exchange(FNeenToSaveToDB, 0)
end;


end.
