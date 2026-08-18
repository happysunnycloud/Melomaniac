{
  Пользовательский модуль
  Здесь прописываются методы-реакции на запросы клиента
  Типы запросов объявляются в модуле Net.RequestHeaders
}

unit Net.UserRequestJobThread;

interface

uses
    IdContext
  , Net.JobThread
  , Net.Types
  ;

type
  TNetUserRequestJobThread = class (TNetJobThread)
  strict private

  protected
    procedure DoJob(const ARequest: TRequest); override; final;
  public
  end;

implementation

uses
    System.SysUtils
  , Net.RequestHeaders
  , Net.ResponseHeaders
  , MainFormMouseHandlersUnit
  , PlayControllerUnit
  , CommonTypesUnit
  , UserRequestJobsUnit
  ;

{ TNetUserRequestJobThread }

procedure TNetUserRequestJobThread.DoJob(const ARequest: TRequest);
var
  Response: TResponse;
  RequestHeader: TRequestHeader;
begin
  RequestHeader.FromInteger(ARequest.GetDataCode);

  Response := TResponse.Create;
  try
    case RequestHeader of
      TRequestHeader.rqPlay:
      begin
        TMainFormMouseClickManager.PlayClicked;
        Response.AddDataCode(TResponseHeader.rsPlay.Code);
        Response.AddAsType(
          'Ok',
          varUString,
          TResponseHeader.rsPlay.Ident);
      end;
      TRequestHeader.rqVolumeUp:
      begin
        TMainFormMouseClickManager.VolumeUp;
        Response.AddDataCode(TResponseHeader.rsVolumeUp.Code);
        Response.AddAsType(
          'Ok',
          varUString,
          TResponseHeader.rsVolumeUp.Ident);
      end;
      TRequestHeader.rqVolumeDown:
      begin
        TMainFormMouseClickManager.VolumeDown;
        Response.AddDataCode(TResponseHeader.rsVolumeDown.Code);
        Response.AddAsType(
          'Ok',
          varUString,
          TResponseHeader.rsVolumeDown.Ident);
      end;
      TRequestHeader.rqCurrentPlayState:
      begin
        Response.AddDataCode(TResponseHeader.rsCurrentPlayState.Code);
        TUserRequestJobsUnit.GetCurrentPlayState(Response);
      end;

      TRequestHeader.rqGetTestString:
      begin
        Response.AddDataCode(TResponseHeader.rsGetTestString.Code);
        Response.AddAsType(
          'This is a test string',
          varUString,
          TResponseHeader.rsGetTestString.Ident);
      end;
    end;

    if Assigned(FOnJobIsDone) then
      FOnJobIsDone(FContext, Response);
  finally
    FreeAndNil(Response);
  end;
end;

end.
