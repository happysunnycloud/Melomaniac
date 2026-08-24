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

  procedure _ResponseOkTo(
    const AResponse: TResponse;
    const AResponseHeader: TResponseHeader);
  var
    ResponseHeader: TResponseHeader;
    Response: TResponse;
  begin
    Response := AResponse;
    ResponseHeader := AResponseHeader;
    Response.AddDataCode(ResponseHeader.Code);
    Response.AddAsType(
      'Ok',
      varUString,
      ResponseHeader.Ident);
  end;

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
        _ResponseOkTo(Response, TResponseHeader.rsPlay);
      end;
      TRequestHeader.rqVolumeUp:
      begin
        TMainFormMouseClickManager.VolumeUp;
        _ResponseOkTo(Response, TResponseHeader.rsVolumeUp);
      end;
      TRequestHeader.rqVolumeDown:
      begin
        TMainFormMouseClickManager.VolumeDown;
        _ResponseOkTo(Response, TResponseHeader.rsVolumeDown);
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
        _ResponseOkTo(Response, TResponseHeader.rsNext);
      end;
      TRequestHeader.rqPrev:
      begin
        TMainFormMouseClickManager.PrevClicked;
        _ResponseOkTo(Response, TResponseHeader.rsPrev);
      end;
      TRequestHeader.rqNextNSecs:
      begin
        TMainFormMouseClickManager.NextNSecs;
        _ResponseOkTo(Response, TResponseHeader.rsNextNSecs);
      end;
      TRequestHeader.rqPrevNSecs:
      begin
        TMainFormMouseClickManager.PrevNSecs;
        _ResponseOkTo(Response, TResponseHeader.rsPrevNSecs);
      end;
      TRequestHeader.rqStopRewind:
      begin
        TMainFormMouseClickManager.StopRewind;
        _ResponseOkTo(Response, TResponseHeader.rsStopRewind);
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
