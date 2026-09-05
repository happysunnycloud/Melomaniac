unit PoolUnit;

interface

uses
    System.Classes
  , System.Generics.Collections
  , FMX.Controls
  , FMX.Layouts
  , ControlPanelFrameUnit
  , Net.Client
  , Net.RequestHeaders
  , Net.Types
  , Net.Exceptions
  , CommonTypesUnit
  ;

type
  TMRC = class;
  TMRCList = TList<TMRC>;

  TGetPlayStateThread = class;

  TMRC = class
  strict private
    procedure RunRewind(const ARewindDirection: TRewindDirection);
  strict private
    FIdent: String;
    FListOwner: TMRCList;

    FHostName: String;
    FIP: String;
    FPort: Word;
    FRCControlFrame: TControlPanelFrame;
    FNetClient: TNetClient;

    FRewindDirection: TRewindDirection;
    FIsRewindActivated: Boolean;

    function GetIndex: Integer;
    function CheckIsRewindActivated: Boolean;

    procedure SendRequest(const ARequestHeader: TRequestHeader);

    procedure DoConnectButtonClick(Sender: TObject);
    procedure DoPlayButtonClick(Sender: TObject);
    procedure DoVolumeUpButtonClick(Sender: TObject);
    procedure DoVolumeDownButtonClick(Sender: TObject);
    procedure DoNextButtonClick(Sender: TObject);
    procedure DoPrevButtonClick(Sender: TObject);
    procedure DoNextNSecsButtonClick(Sender: TObject);
    procedure DoPrevNSecsButtonClick(Sender: TObject);

    procedure DoClientConnect;
    procedure DoClientAuthorized(const ACredential: TCredential);
    procedure DoClientDisconnect;
    procedure DoClientRead;
    procedure DoClientException(const AExceptionCode: TNetExceptionCode);

    procedure ConnectButtonHandlers;
    procedure DisconnectButtonHandlers;
  strict private
    FGetPlayStateThread: TGetPlayStateThread;

    procedure StartRequestPlayState(const ANetClient: TNetClient);
    procedure StopRequestPlayState;
  public
    constructor Create(
      const AListOwner: TMRCList;
      const AHostName: String;
      const AIP: String;
      const APort: Word;
      const AScrollBox: TScrollBox);
    destructor Destroy; override;

    property Ident: String read FIdent;
    property ListOwner: TMRCList read FListOwner;
    property HostName: String read FHostName write FHostName;
    property IP: String read FIP write FIP;
    property Port: Word read FPort write FPort;

    property RCControlFrame: TControlPanelFrame
      read FRCControlFrame write FRCControlFrame;
    property NetClient: TNetClient read FNetClient;

    property _Index: Integer read GetIndex;
  end;

  TMRCPool = class
  strict private
    FScrollBox: TScrollBox;
    FRCList: TMRCList;
    procedure LoadPool;
    function AddRC(
      const AHostName: String;
      const AIP: String;
      const APort: Word): TMRC;

    procedure Clear;
  public
    constructor Create(const AScrollBox: TScrollBox);
    destructor Destroy; override;

    procedure Refresh;
    function TryGetRC(const ARCIdent: String; var ARC: TMRC): Boolean;
  end;

  TGetPlayStateThread = class(TThread)
  strict private
    FNetClient: TNetClient;
  protected
    procedure Execute; override;
  public
    constructor Create(const ANetClient: TNetClient);
  end;

implementation

uses
    System.SysUtils
  , Xml.XMLIntf
  , ToolsUnit
  , FMX.Types
  , StringToolsUnit
  , RCFunctionManagerUnit
  , ConstantsUnit
//  , DebugUnit
  ;

{ TMRC }

constructor TMRC.Create(
  const AListOwner: TMRCList;
  const AHostName: String;
  const AIP: String;
  const APort: Word;
  const AScrollBox: TScrollBox);
begin
  if not Assigned(AListOwner) then
    raise Exception.Create('List owner is nil');

  FIdent := TStringTools.GenIdent('RCIdent','::');

  FListOwner := AListOwner;
  FHostName := AHostName;
  FIP := AIP;
  FPort := APort;
  FIsRewindActivated := false;
  FRewindDirection := rdNone;

  FGetPlayStateThread := nil;

  FRCControlFrame := TTools.BuildRCControl(AScrollBox, FIdent);
  FRCControlFrame.HostNameLabel.Text := FHostName;

  // Здесь назначаем обработку только для кнопки подключения
  FRCControlFrame.ConnectButton.OnClick := DoConnectButtonClick;
  // Остальные сбработчики назначаем через ConnectButtonHandlers
  // В событии DoClientConnect
  // Снимаем обработчики через DisconnectButtonHandlers
  // В событии DoClientAuthorized

  FNetClient := TNetClient.Create(FHostName, FIP, FPort);
  FNetClient.OnConnected := DoClientConnect;
  FNetClient.OnAuthorized := DoClientAuthorized;
  FNetClient.OnDisconnected := DoClientDisconnect;
  FNetClient.OnRead := DoClientRead;
  FNetClient.OnException := DoClientException;
end;

destructor TMRC.Destroy;
begin
  StopRequestPlayState;
  FreeAndNil(FNetClient);

  inherited;
end;

procedure TMRC.RunRewind(const ARewindDirection: TRewindDirection);
begin
  case ARewindDirection of
    rdForward:
    begin
      SendRequest(TRequestHeader.rqNextNSecs);
      Self.FRCControlFrame.NextNSecsButton.Text := FORWARD_REWIND_ON;
    end;
    rdBackward:
    begin
      SendRequest(TRequestHeader.rqPrevNSecs);
      Self.FRCControlFrame.PrevNSecsButton.Text := BACKWARD_REWIND_ON;
    end;
    rdNone:
    begin
      Exit;
    end;
  end;

  FRewindDirection := ARewindDirection;
end;

function TMRC.GetIndex: Integer;
begin
  Result := ListOwner.IndexOf(Self);

  if Result < 0 then
    raise Exception.Create('RC instance not found in list');
end;

function TMRC.CheckIsRewindActivated: Boolean;
begin

  Self.FRCControlFrame.NextNSecsButton.Text := FORWARD_REWIND_OFF;
  Self.FRCControlFrame.PrevNSecsButton.Text := BACKWARD_REWIND_OFF;

  Result := FRewindDirection <> rdNone;

  if Result then
  begin
    SendRequest(TRequestHeader.rqStopRewind);

    FRewindDirection := TRewindDirection.rdNone;
  end;
end;

procedure TMRC.SendRequest(const ARequestHeader: TRequestHeader);
begin
  if not FNetClient.IsConnected then
    Exit;

  TRCFunctionManager.SendRequest(FNetClient, ARequestHeader.Code);
end;

procedure TMRC.DoConnectButtonClick(Sender: TObject);
begin
  if not FNetClient.IsConnected then
  begin
    FNetClient.Connect;
    TRCFunctionManager.Connect(Self);
  end
  else
    FNetClient.Disconnect;
end;

procedure TMRC.DoPlayButtonClick(Sender: TObject);
begin
  CheckIsRewindActivated;

  SendRequest(TRequestHeader.rqPlay);
end;

procedure TMRC.DoVolumeUpButtonClick(Sender: TObject);
begin
  SendRequest(TRequestHeader.rqVolumeUp);
end;

procedure TMRC.DoVolumeDownButtonClick(Sender: TObject);
begin
  SendRequest(TRequestHeader.rqVolumeDown);
end;

procedure TMRC.DoNextButtonClick(Sender: TObject);
begin
  CheckIsRewindActivated;

  SendRequest(TRequestHeader.rqNext);
end;

procedure TMRC.DoPrevButtonClick(Sender: TObject);
begin
  CheckIsRewindActivated;

  SendRequest(TRequestHeader.rqPrev);
end;

procedure TMRC.DoNextNSecsButtonClick(Sender: TObject);
var
  RewindDirection: TRewindDirection;
begin
  RewindDirection := FRewindDirection;

  if not CheckIsRewindActivated then
  begin
    RunRewind(rdForward);
  end
  else
  begin
    if RewindDirection = TRewindDirection.rdBackward then
    begin
      RunRewind(rdForward);
    end;
  end;
end;

procedure TMRC.DoPrevNSecsButtonClick(Sender: TObject);
var
  RewindDirection: TRewindDirection;
begin
  RewindDirection := FRewindDirection;

  if not CheckIsRewindActivated then
  begin
    RunRewind(rdBackward);
  end
  else
  begin
    if RewindDirection = TRewindDirection.rdForward then
    begin
      RunRewind(rdBackward);
    end;
  end;
end;

procedure TMRC.DoClientConnect;
begin
  FIsRewindActivated := false;
  FRewindDirection := rdNone;
end;

procedure TMRC.DoClientAuthorized(const ACredential: TCredential);
begin
  TRCFunctionManager.ClientConnected(Self);
  StartRequestPlayState(FNetClient);

  ConnectButtonHandlers;
end;

procedure TMRC.DoClientDisconnect;
begin
  StopRequestPlayState;
  TRCFunctionManager.ClientDisconnected(Self);

  DisconnectButtonHandlers;
end;

procedure TMRC.DoClientRead;
begin
  TRCFunctionManager.ClientRead(Self);
end;

procedure TMRC.DoClientException(const AExceptionCode: TNetExceptionCode);
begin
  TRCFunctionManager.ClientException(Self);
end;

procedure TMRC.ConnectButtonHandlers;
begin
  FRCControlFrame.PlayButton.OnClick := DoPlayButtonClick;
  FRCControlFrame.VolumeUpButton.OnClick := DoVolumeUpButtonClick;
  FRCControlFrame.VolumeDownButton.OnClick := DoVolumeDownButtonClick;
  FRCControlFrame.NextButton.OnClick := DoNextButtonClick;
  FRCControlFrame.PrevButton.OnClick := DoPrevButtonClick;
  FRCControlFrame.NextNSecsButton.OnClick := DoNextNSecsButtonClick;
  FRCControlFrame.PrevNSecsButton.OnClick := DoPrevNSecsButtonClick;
end;

procedure TMRC.DisconnectButtonHandlers;
begin
  FRCControlFrame.PlayButton.OnClick := nil;
  FRCControlFrame.VolumeUpButton.OnClick := nil;
  FRCControlFrame.VolumeDownButton.OnClick := nil;
  FRCControlFrame.NextButton.OnClick := nil;
  FRCControlFrame.PrevButton.OnClick := nil;
  FRCControlFrame.NextNSecsButton.OnClick := nil;
  FRCControlFrame.PrevNSecsButton.OnClick := nil;

  FRCControlFrame.NextNSecsButton.Text := FORWARD_REWIND_OFF;
  FRCControlFrame.PrevNSecsButton.Text := BACKWARD_REWIND_OFF;
end;

procedure TMRC.StartRequestPlayState(
  const ANetClient: TNetClient);
begin
  FGetPlayStateThread := TGetPlayStateThread.Create(ANetClient);
end;

procedure TMRC.StopRequestPlayState;
begin
  if not Assigned(FGetPlayStateThread) then
    Exit;

  FGetPlayStateThread.Terminate;
  FGetPlayStateThread.WaitFor;
  FreeAndNil(FGetPlayStateThread);
end;

{ TMRCPool }

constructor TMRCPool.Create(const AScrollBox: TScrollBox);
begin
  FScrollBox := AScrollBox;
  FRCList := TMRCList.Create;

  TThread.ForceQueue(nil,
    procedure
    begin
      LoadPool;
    end);
end;

destructor TMRCPool.Destroy;
begin
  Clear;

  FreeAndNil(FRCList);

  inherited;
end;

function TMRCPool.AddRC(
  const AHostName: String;
  const AIP: String;
  const APort: Word): TMRC;
var
  RC: TMRC;
begin
  RC := TMRC.Create(FRCList, AHostName, AIP, APort, FScrollBox);
//  RC.RCControlFrame := BuildControl(RC, FScrollBox);
  FRCList.Add(RC);
  Result := RC;
end;

procedure TMRCPool.LoadPool;
var
  XMLDoc:                 IXMLDocument;
  RootNode:               IXMLNode;
  GeneralSettingsNode:    IXMLNode;
  HostsNode:              IXMLNode;
  HostNode:               IXMLNode;
  i:                      Word;
  HostName:               String;
  IP:                     String;
  Port:                   Word;
  RC:                     TMRC;
begin
  if not FileExists(TTools.GetConfigFileName) then
  begin
    // при самом первом запуске приложения, файл может не существовать
    // это совершенно нормальная ситуация

    TTools.CreateConfigFile;

    Exit;
  end;

  XMLDoc := TTools.OpenXML(TTools.GetConfigFileName);

  RootNode := IXMLDocument(XMLDoc).ChildNodes.FindNode('Config');
  GeneralSettingsNode := RootNode.ChildNodes.FindNode('General');
  HostsNode := RootNode.ChildNodes.FindNode('Hosts');

  FScrollBox.BeginUpdate;
  RC := nil;
  i := 0;
  while i < HostsNode.ChildNodes.Count do
  begin
    HostNode := HostsNode.ChildNodes[i];
    HostName := HostNode.ChildNodes['HostName'].Text;
    IP := HostNode.ChildNodes['IP'].Text;
    Port := Word(StrToInt(HostNode.ChildNodes['Port'].Text));

    RC := AddRC(HostName, IP, Port);

    if i < Pred(HostsNode.ChildNodes.Count) then
    begin
      RC.RCControlFrame.Height :=
        RC.RCControlFrame.Height - RC.RCControlFrame.ButtonSplitterRectangle.Height;
      RC.RCControlFrame.ButtonSplitterRectangle.Visible := false;
    end;

    Inc(i);
  end;

  FScrollBox.Height := 0;
  if Assigned(RC) then
    FScrollBox.Height := RC.RCControlFrame.Height * i;

  FScrollBox.EndUpdate;
end;

procedure TMRCPool.Clear;
begin
  while FRCList.Count > 0 do
  begin
    FRCList[0].RCControlFrame.Free;
    FRCList[0].Free;
    FRCList.Delete(0);
  end;
end;

procedure TMRCPool.Refresh;
begin
  Clear;

  LoadPool;
end;

function TMRCPool.TryGetRC(const ARCIdent: String; var ARC: TMRC): Boolean;
var
  RC: TMRC;
begin
  Result := false;
  ARC := nil;

  for RC in FRCList do
  begin
    if RC.Ident = ARCIdent then
    begin
      ARC := RC;

      Exit(true);
    end;
  end;
end;

{ TGetPlayStateThread }

constructor TGetPlayStateThread.Create(const ANetClient: TNetClient);
begin
  if not Assigned(ANetClient) then
    raise Exception.Create('ANetClient is nil');

  FNetClient := ANetClient;

  inherited Create(false);
end;

procedure TGetPlayStateThread.Execute;
var
  TimeOut: Integer;
  Count: Integer;
begin
  TimeOut := REQUEST_PLAY_STATE_TIME_INTERVAL div 100;
  while not Terminated do
  begin
    TRCFunctionManager.SendRequest(
      FNetClient,
      TRequestHeader.rqCurrentPlayState.Code);

    Count := 0;
    while (not Terminated) and (Count < Timeout) do
    begin
      Sleep(100);

      Inc(Count);
    end;
  end;
end;

end.
