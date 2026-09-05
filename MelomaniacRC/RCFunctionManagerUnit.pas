unit RCFunctionManagerUnit;

interface

uses
    System.Classes
  , PoolUnit
  , Net.Client
  , SafeQueueThread
  ;

const
  REQUEST_PLAY_STATE_TIME_INTERVAL = 1000;

type
  TRCFunctionManager = class
  strict private
    class var FSafeQueueThreadSignal: ISafeQueueThreadSignal;
  public
    class procedure Connect(const ARC: TMRC);
    class procedure ClientConnected(const ARC: TMRC);
    class procedure ClientDisconnected(const ARC: TMRC);
    class procedure ClientException(const ARC: TMRC);

    class procedure SendRequest(
      const ANetClient: TNetClient;
      const ARequestCode: Integer);

    class procedure ClientRead(const ARC: TMRC);

    class procedure ClassInit;
    class procedure ClassUninit;
  end;

implementation

uses
    System.UITypes
  , System.SysUtils
  , FMX.Dialogs
  , Net.Types
  , Net.RequestHeaders
  , Net.ResponseHeaders
  , CommonTypesUnit
  , ParamsExtUnit
  , FMX.SingleSoundUnit
  , ToolsUnit
  ;

{ TRCFunctionManager }

class procedure TRCFunctionManager.ClassInit;
begin
  FSafeQueueThreadSignal := TSafeQueueThreadSignal.Create;
end;

class procedure TRCFunctionManager.ClassUninit;
begin
  FSafeQueueThreadSignal.Deactivate;
end;

class procedure TRCFunctionManager.Connect(const ARC: TMRC);
begin
  ARC.RCControlFrame.ConnectButton.Fill.Color := TAlphaColorRec.Yellow;
end;

class procedure TRCFunctionManager.ClientConnected(const ARC: TMRC);
begin
  ARC.RCControlFrame.ConnectButton.Fill.Color := TAlphaColorRec.Greenyellow;
end;

class procedure TRCFunctionManager.ClientDisconnected(const ARC: TMRC);
begin
  ARC.RCControlFrame.ConnectButton.Fill.Color := TAlphaColorRec.Lavender;
end;

class procedure TRCFunctionManager.ClientException(const ARC: TMRC);
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
  CurrentPlayState: TCurrentPlayState;
  DataParams: TParamsExt;
  Composition: String;
  PlayState: String;
  Duration: String;
  CurrentTime: String;
  VolumePercentage: String;
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
        // Void
      end;
      rsVolumeDown:
      begin
        // Void
      end;
      rsNext:
      begin
        // Void
      end;
      rsPrev:
      begin
        // Void
      end;
      rsCurrentPlayState:
      begin
        DataParams := TParamsExt.Create;
        CurrentPlayState := TCurrentPlayState.Create;
        try
          DataParams.CopyFrom(Response, 1, Response.Length);
          DataParams.ToObject(CurrentPlayState);

          Composition := TTools.ExtractFileName(CurrentPlayState.Composition);
          PlayState := CurrentPlayState.PlayState.ToStr;
          Duration := TSingleSound.GetHumanTime(CurrentPlayState.Duration);
          CurrentTime := TSingleSound.GetHumanTime(CurrentPlayState.CurrentTime);
          VolumePercentage := Round(100 * CurrentPlayState.Volume).ToString + ' %';
          TSafeQueueThread.SafeForceQueue(FSafeQueueThreadSignal,
            procedure
            begin
              ARC.RCControlFrame.CompositionNameLabel.Text := Composition;
              ARC.RCControlFrame.PlayButton.Text := PlayState;
              ARC.RCControlFrame.CompositionTimeTotalLabel.Text := Duration;
              ARC.RCControlFrame.CompositionTimeCurrentLabel.Text := CurrentTime;
              ARC.RCControlFrame.VolumeLabel.Text := VolumePercentage;
            end);
        finally
          FreeAndNil(DataParams);
          FreeAndNil(CurrentPlayState);
        end;
      end;
    end;
  finally
    FreeAndNil(Response);
  end;
end;

initialization
  TRCFunctionManager.ClassInit;

finalization
  TRCFunctionManager.ClassUninit;
end.
