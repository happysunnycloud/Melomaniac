unit AppManagerUnit;

interface

uses
    FMX.Layouts
  , FMX.Forms
  , PoolUnit
  ;

type
  TAppManager = class
  strict private
    class var FRCScrollBox: TScrollBox;
    class var FMainContentLayout: TLayout;
  strict private
    FRCPool: TMRCPool;
  public
    constructor Create;
    destructor Destroy; override;

    procedure CreateRCPool;

    property RCPool: TMRCPool
      read FRCPool;
  public
    class property RCScrollBox: TScrollBox
      read FRCScrollBox write FRCScrollBox;
    class property MainContentLayout: TLayout
      read FMainContentLayout write FMainContentLayout;
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

procedure TAppManager.CreateRCPool;
begin
  FRCPool := TMRCPool.Create;
end;

end.
