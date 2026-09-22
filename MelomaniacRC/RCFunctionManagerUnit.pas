unit RCFunctionManagerUnit;

interface

uses
    System.Classes
  , PoolUnit
  , Net.Client
  , SafeQueueThread
  , ParamsExtUnit
  ;

const
  REQUEST_PLAY_STATE_TIME_INTERVAL = 1000;

type
  // OnClientRead обрабатывается в главном потоке,
  // дополнительно синхронизировать не нужно
  TRCFunctionManager = class
  strict private
  public
    class procedure Connect(const ARC: TMRC);
    class procedure ClientConnected(const ARC: TMRC);
    class procedure ClientDisconnected(const ARC: TMRC);
    class procedure ClientException(const ARC: TMRC);

    class procedure SendRequest(
      const ANetClient: TNetClient;
      const ARequestCode: Integer); overload;
    class procedure SendRequest(
      const ANetClient: TNetClient;
      const ARequestCode: Integer;
      const AParams: TParamsExt); overload;

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
  , CommonTypesUnit
  , FMX.SingleSoundUnit
  , ToolsUnit
  ;

{ TRCFunctionManager }

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

class procedure TRCFunctionManager.SendRequest(
  const ANetClient: TNetClient;
  const ARequestCode: Integer;
  const AParams: TParamsExt);
var
  Request: TRequest;
begin
  Request := TRequest.Create;
  try
    Request.AddDataCode(ARequestCode);
    Request.AddFrom(AParams);
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
  CurrentCompositonPath: String;
  MustScroll: Boolean;
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
        if not (Assigned(ARC) and Assigned(ARC.RCControlFrame)) then
          Exit;

        DataParams := TParamsExt.Create;
        CurrentPlayState := TCurrentPlayState.Create;
        try
          DataParams.CopyFrom(Response, 1, Response.Length);
          DataParams.ToObject(CurrentPlayState);

          MustScroll := not (ARC.CurrentCompositonPath = CurrentPlayState.Composition);
          CurrentCompositonPath := CurrentPlayState.Composition;
          Composition := TTools.ExtractFileName(CurrentCompositonPath);
          PlayState := CurrentPlayState.PlayState.ToStr;
          Duration := TSingleSound.GetHumanTime(CurrentPlayState.Duration);
          CurrentTime := TSingleSound.GetHumanTime(CurrentPlayState.CurrentTime);
          VolumePercentage := Round(100 * CurrentPlayState.Volume).ToString + ' %';

          ARC.CurrentCompositonPath := CurrentCompositonPath;
          ARC.RCControlFrame.CompositionNameLabel.Text := Composition;
          ARC.RCControlFrame.PlayButton.Text := PlayState;
          ARC.RCControlFrame.CompositionTimeTotalLabel.Text := Duration;
          ARC.RCControlFrame.CompositionTimeCurrentLabel.Text := CurrentTime;
          ARC.RCControlFrame.VolumeLabel.Text := VolumePercentage;

          if MustScroll then
            ARC.ScrollByCurrentCompositonPath;
        finally
          FreeAndNil(DataParams);
          FreeAndNil(CurrentPlayState);
        end;
      end;
      rsGetPlayList:
      begin
        if not (Assigned(ARC) and Assigned(ARC.PlayListFrame)) then
          Exit;

        DataParams := TParamsExt.Create;
        try
          DataParams.CopyFrom(Response, 1, Response.Length);
          DataParams.ToObjectList<TPlayItem>(
            ARC.PlayListFrame.PlayItemsList, 'PlayItemsList');
          ARC.PlayListFrame.BuildPlayList;

          ARC.ScrollByCurrentCompositonPath;
        finally
          FreeAndNil(DataParams);
        end;
      end;
    end;
  finally
    FreeAndNil(Response);
  end;
end;

end.
