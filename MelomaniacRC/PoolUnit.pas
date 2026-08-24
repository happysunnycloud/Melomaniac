unit PoolUnit;

interface

uses
    System.Generics.Collections
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

  TMRC = class
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
      read FRCControlFrame write fRCControlFrame;
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

implementation

uses
    System.Classes
  , System.SysUtils
  , Xml.XMLIntf
  , ToolsUnit
  , FMX.Types
  , StringToolsUnit
  , RCFunctionManagerUnit
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

  FRCControlFrame := TTools.BuildRCControl(AScrollBox, FIdent);
  FRCControlFrame.HostNameLabel.Text := FHostName;
  FRCControlFrame.ConnectButton.OnClick := DoConnectButtonClick;
  FRCControlFrame.PlayButton.OnClick := DoPlayButtonClick;
  FRCControlFrame.VolumeUpButton.OnClick := DoVolumeUpButtonClick;
  FRCControlFrame.VolumeDownButton.OnClick := DoVolumeDownButtonClick;
  FRCControlFrame.NextButton.OnClick := DoNextButtonClick;
  FRCControlFrame.PrevButton.OnClick := DoPrevButtonClick;
  FRCControlFrame.NextNSecsButton.OnClick := DoNextNSecsButtonClick;
  FRCControlFrame.PrevNSecsButton.OnClick := DoPrevNSecsButtonClick;

  FNetClient := TNetClient.Create(FHostName, FIP, FPort);
  FNetClient.OnConnected := DoClientConnect;
  FNetClient.OnAuthorized := DoClientAuthorized;
  FNetClient.OnDisconnected := DoClientDisconnect;
  FNetClient.OnRead := DoClientRead;
  FNetClient.OnException := DoClientException;
end;

destructor TMRC.Destroy;
begin
  TRCFunctionManager.StopRequestPlayState;
  FreeAndNil(FNetClient);

  inherited;
end;

function TMRC.GetIndex: Integer;
begin
  Result := ListOwner.IndexOf(Self);

  if Result < 0 then
    raise Exception.Create('RC instance not found in list');
end;

function TMRC.CheckIsRewindActivated: Boolean;
begin
  Result := FRewindDirection <> rdNone;

  if Result then
  begin
    SendRequest(TRequestHeader.rqStopRewind);

    FRewindDirection := TRewindDirection.rdNone;
  end;
end;

procedure TMRC.SendRequest(const ARequestHeader: TRequestHeader);
begin
  if not NetClient.IsConnected then
    Exit;

  TRCFunctionManager.SendRequest(NetClient, ARequestHeader.Code);
end;

procedure TMRC.DoConnectButtonClick(Sender: TObject);
begin
  if not FNetClient.IsConnected then
    TRCFunctionManager.Connect(Self)
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
    SendRequest(TRequestHeader.rqNextNSecs);

    FRewindDirection := TRewindDirection.rdForward;
  end
  else
  begin
    if RewindDirection = TRewindDirection.rdBackward then
    begin
      SendRequest(TRequestHeader.rqNextNSecs);

      FRewindDirection := TRewindDirection.rdForward;
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
    SendRequest(TRequestHeader.rqPrevNSecs);

    FRewindDirection := TRewindDirection.rdBackward;
  end
  else
  begin
    if RewindDirection = TRewindDirection.rdForward then
    begin
      SendRequest(TRequestHeader.rqPrevNSecs);

      FRewindDirection := TRewindDirection.rdBackward;
    end;
  end;
end;

procedure TMRC.DoClientConnect;
begin
  FIsRewindActivated := false;
  FRewindDirection := rdNone;

  TRCFunctionManager.ClientConnected(Self);
end;

procedure TMRC.DoClientAuthorized(const ACredential: TCredential);
begin
  TRCFunctionManager.ClientAuthorized(Self);
end;

procedure TMRC.DoClientDisconnect;
begin
  TRCFunctionManager.ClientDisconnected(Self);
end;

procedure TMRC.DoClientRead;
begin
  TRCFunctionManager.ClientRead(Self);
end;

procedure TMRC.DoClientException(const AExceptionCode: TNetExceptionCode);
begin
  TRCFunctionManager.ClientException(Self);
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

end.
