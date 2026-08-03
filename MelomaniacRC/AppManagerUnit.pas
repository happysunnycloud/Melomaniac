unit AppManagerUnit;

interface

uses
    FMX.Layouts
  , PoolUnit
  ;

type
  TAppManager = class
  strict private
    FRCPool: TMRCPool;
  public
    constructor Create;
    destructor Destroy; override;

    property RCPool: TMRCPool read FRCPool;

    procedure CreateRCPool(const AScrollBox: TScrollBox);
  end;

var
  AppManager: TAppManager;

implementation

uses
    System.SysUtils
  ;

{ TAppManager }

constructor TAppManager.Create;
begin
  FRCPool := nil;
end;

destructor TAppManager.Destroy;
begin
  FreeAndNil(FRCPool);
end;

procedure TAppManager.CreateRCPool(const AScrollBox: TScrollBox);
begin
  if not Assigned(AScrollBox) then
    raise Exception.Create('ScrollBox is nil');

  FRCPool := TMRCPool.Create(AScrollBox);
end;

end.
