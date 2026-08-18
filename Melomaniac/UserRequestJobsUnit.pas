unit UserRequestJobsUnit;

interface

uses
    ParamsExtUnit
  ;

type
  TUserRequestJobsUnit = class
  public
    class procedure GetCurrentPlayState(const AResponseHeader: TParamsExt);
  end;

implementation

uses
    System.SysUtils
  , CommonTypesUnit
  , PlayControllerUnit
  , StateUnit
  ;

{ TUserRequestJobsUnit }

class procedure TUserRequestJobsUnit.GetCurrentPlayState(
  const AResponseHeader: TParamsExt);
var
  Response: TParamsExt;
  CurrentPlayState: TCurrentPlayState;
begin
  Response := TParamsExt.Create;
  CurrentPlayState := TCurrentPlayState.Create;
  try
    CurrentPlayState.CurrentTime := TPlayController.CurrentTime;
    CurrentPlayState.Duration := TPlayController.Duration;
    CurrentPlayState.Composition := TPlayController.PlayList.CurrentComposition;
    CurrentPlayState.Volume := TPlayController.Volume;
    CurrentPlayState.PlayState := TState.PlayState;
    Response.FromObject(CurrentPlayState);
    AResponseHeader.AddFrom(Response);
  finally
    FreeAndNil(CurrentPlayState);
    FreeAndNil(Response);
  end;
end;

end.
