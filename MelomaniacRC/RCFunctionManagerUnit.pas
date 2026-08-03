unit RCFunctionManagerUnit;

interface

uses
    PoolUnit
  , Net.Client

  ;

type
  TRCFunctionManager = class
  strict private
  public
    class procedure Connect(const ARC: TMRC);
    class procedure ClientConnected(const ARC: TMRC);
    class procedure ClientDisconnected(const ARC: TMRC);

    class procedure SendRequest(
      const ANetClient: TNetClient;
      const ARequestCode: Integer);

    class procedure ClientRead(const ARC: TMRC);
  end;

implementation

uses
    System.UITypes
  , System.SysUtils
  , FMX.Dialogs
  , Net.Types
  , Net.RequestHeaders
  , Net.ResponseHeaders
  ;

{ TRCFunctionManager }

class procedure TRCFunctionManager.Connect(const ARC: TMRC);
begin
  ARC.NetClient.Connect;
end;

class procedure TRCFunctionManager.ClientConnected(const ARC: TMRC);
begin
  ARC.RCControlFrame.ConnectButton.Fill.Color := TAlphaColorRec.Greenyellow;
end;

class procedure TRCFunctionManager.ClientDisconnected(const ARC: TMRC);
begin
  ARC.RCControlFrame.ConnectButton.Fill.Color := TAlphaColorRec.Lavender;
end;

class procedure TRCFunctionManager.SendRequest(
  const ANetClient: TNetClient;
  const ARequestCode: Integer);
var
  Request: TRequest;
begin
  Request := TRequest.Create;
  try
    Request.AddDataCode(ARequestCode);
    ANetClient.AddToStack(Request);
  finally
    FreeAndNil(Request);
  end;
end;

class procedure TRCFunctionManager.ClientRead(const ARC: TMRC);
var
  Response: TResponse;
  ResponseHeader: TResponseHeader;
  Str: String;
  PlayButtonText: String;
begin
  Response := TResponse.Create;
  try
    if not ARC.NetClient.ResponseStack.TryPop(Response) then
      Exit;

    ResponseHeader.FromInteger(Response.GetDataCode);
    case ResponseHeader of
      rsPlay:
      begin
        Response.Get<String>(Str, ResponseHeader.Ident);

        PlayButtonText := ARC.RCControlFrame.PlayButton.Text;
        if (PlayButtonText = 'Stop') or (PlayButtonText = 'Pause') then
          ARC.RCControlFrame.PlayButton.Text := 'Play'
        else
        if ARC.RCControlFrame.PlayButton.Text = 'Play' then
          ARC.RCControlFrame.PlayButton.Text := 'Pause'
      end;
      rsVolumeUp:
      begin

      end;
      rsVolumeDown:
      begin

      end;
    end;
  finally
    FreeAndNil(Response);
  end;
end;


end.
