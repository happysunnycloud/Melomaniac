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
  ResponseHeader: TResponseHeader;
begin
  RequestHeader.FromInteger(ARequest.GetDataCode);

  Response := TResponse.Create;
  try
    case RequestHeader of
      TRequestHeader.rqPlay:
      begin
        TMainFormMouseClickManager.PlayClicked;
        ResponseHeader := TResponseHeader.rsPlay;
        Response.AddDataCode(ResponseHeader.Code);
        Response.AddAsType(
          'Ok',
          varUString,
          ResponseHeader.Ident);
      end;
      TRequestHeader.rqVolumeUp:
      begin
        TMainFormMouseClickManager.VolumeUp;
        ResponseHeader := TResponseHeader.rsVolumeUp;
        Response.AddDataCode(ResponseHeader.Code);
        Response.AddAsType(
          'Ok',
          varUString,
          ResponseHeader.Ident);
      end;
      TRequestHeader.rqVolumeDown:
      begin
        TMainFormMouseClickManager.VolumeDown;
        ResponseHeader := TResponseHeader.rsVolumeDown;
        Response.AddDataCode(ResponseHeader.Code);
        Response.AddAsType(
          'Ok',
          varUString,
          ResponseHeader.Ident);
      end;
      TRequestHeader.rqCurrentPlayState:
      begin
        ResponseHeader := TResponseHeader.rsCurrentPlayState;
        Response.AddDataCode(ResponseHeader.Code);
        TUserRequestJobsUnit.GetCurrentPlayState(Response);
      end;
      TRequestHeader.rqNext:
      begin
        TMainFormMouseClickManager.NextClicked;
        ResponseHeader := TResponseHeader.rsNext;
        Response.AddDataCode(ResponseHeader.Code);
        Response.AddAsType(
          'Ok',
          varUString,
          ResponseHeader.Ident);
      end;
      TRequestHeader.rqPrev:
      begin
        TMainFormMouseClickManager.PrevClicked;
        ResponseHeader := TResponseHeader.rsPrev;
        Response.AddDataCode(ResponseHeader.Code);
        Response.AddAsType(
          'Ok',
          varUString,
          ResponseHeader.Ident);
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
