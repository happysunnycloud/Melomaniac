unit PoolUnit;

interface

uses
    System.Generics.Collections
  , FMX.Controls
  , FMX.Layouts
  , ControlPanelFrameUnit
  , Net.Client
  , Net.RequestHeaders
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

//    fRefreshInfoThread: TMRCRefreshInfoThread;

    function GetIndex: Integer;

    procedure SendRequest(const ARequestHeader: TRequestHeader);

    procedure DoConnectButtonClick(Sender: TObject);
    procedure DoPlayButtonClick(Sender: TObject);
    procedure DoVolumeUpButtonClick(Sender: TObject);
    procedure DoVolumeDownButtonClick(Sender: TObject);

    procedure DoClientConnect;
    procedure DoClientDisconnect;
    procedure DoClientRead;

//    procedure OnNextButtonClick(Sender: TObject);
//    procedure OnPrevButtonClick(Sender: TObject);
//    procedure OnVolumeDownButtonClick(Sender: TObject);
//    procedure OnVolumeUpButtonClick(Sender: TObject);

//    procedure OnMenuClick(Sender: TObject);
//    procedure OnClientRead(ADataMemoryStream: TMemoryStream);
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

//    property UClient:           TUClient              read fUClient         write fUClient;
  end;

  TMRCPool = class
  strict private
    FScrollBox: TScrollBox;
    FRCList: TMRCList;

    //function GetRC(AIndex: Word): TMelomaniacRC;
//    function GetCount: Word;

    procedure LoadPool;

//    function BuildControl(
//      const ARC: TMRC;
//      const AOwner: TControl): TControlPanelFrame;

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

    //property RC[AIndex: Word]: TMelomaniacRC read GetRC;
//    property Count: Word read GetCount;
//    function IndexOf(const AMelomaniacRC: TMelomaniacRC): Integer;
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

  FRCControlFrame := TTools.BuildRCControl(AScrollBox, FIdent);
  FRCControlFrame.HostNameLabel.Text := FHostName;
  FRCControlFrame.ConnectButton.OnClick := DoConnectButtonClick;
  FRCControlFrame.PlayButton.OnClick := DoPlayButtonClick;
  FRCControlFrame.VolumeUpButton.OnClick := DoVolumeUpButtonClick;
  FRCControlFrame.VolumeDownButton.OnClick := DoVolumeDownButtonClick;

  FNetClient := TNetClient.Create(FHostName, FIP, FPort);
  FNetClient.OnConnected := DoClientConnect;
  FNetClient.OnDisconnected := DoClientDisconnect;
  FNetClient.OnRead := DoClientRead;
end;

destructor TMRC.Destroy;
begin
  FreeAndNil(FNetClient);

  inherited;
end;

function TMRC.GetIndex: Integer;
begin
  Result := ListOwner.IndexOf(Self);

  if Result < 0 then
    raise Exception.Create('RC instance not found in list');
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

procedure TMRC.DoClientConnect;
begin
  TRCFunctionManager.ClientConnected(Self);
end;

procedure TMRC.DoClientDisconnect;
begin
  TRCFunctionManager.ClientDisconnected(Self);
end;

procedure TMRC.DoClientRead;
begin
  TRCFunctionManager.ClientRead(Self);
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

//function TMRCPool.BuildControl(
//  const ARC: TMRC;
//  const AOwner: TControl): TControlPanelFrame;
//
//  function RCControlFrameCount: Word;
//  var
//    i, j: Word;
//  begin
//    i := 0;
//    j := 0;
//    while i < AOwner.ComponentCount do
//    begin
//      if AOwner.Components[i] is TControlPanelFrame then
//        Inc(j);
//
//      Inc(i);
//    end;
//
//    Result := j;
//  end;
//
//var
//  RCControlFrame: TControlPanelFrame;
//  YPosition:      Single;
//begin
//  YPosition := RCControlFrameCount;
//  RCControlFrame := TControlPanelFrame.Create(AOwner, ARC.Ident);
//  RCControlFrame.Name := '';
//  RCControlFrame.HostNameLabel.Text := ARC.HostName;
//  RCControlFrame.CompositionNameLabel.Text := 'Composition';
//  RCControlFrame.Position.Y := YPosition * RCControlFrame.Height;
//  RCControlFrame.Align := TAlignLayout.Top;
//
//  ARC.RCControlFrame := RCControlFrame;
//  AOwner.AddObject(RCControlFrame);
//
//  Result := RCControlFrame;
//end;

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
//
//    RC.RCControlFrame.PlayButton.OnClick :=
//      RC.OnPlayButtonClick;
//
//    RC.RCControlFrame.NextButton.OnClick :=
//      RC.OnNextButtonClick;
//
//    RC.RCControlFrame.PrevButton.OnClick :=
//      RC.OnPrevButtonClick;
//
//    RC.RCControlFrame.VolumeDownButton.OnClick :=
//      RC.OnVolumeDownButtonClick;
//
//    RC.RCControlFrame.VolumeUpButton.OnClick :=
//      RC.OnVolumeUpButtonClick;
//
//    RC.RCControlFrame.MenuLabel.OnClick :=
//      RC.OnMenuClick;
//
//    RC.UClient.OnConnected :=
//      RC.OnClientConnect;
//
//    RC.UClient.OnDisconnected :=
//      RC.OnClientDisconnect;
//
//    RC.UClient.OnRead :=
//      RC.OnClientRead;


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
