unit ToolsUnit;

interface

uses
    Xml.XMLDoc
  , Xml.XMLIntf
  , FMX.Controls
  , ControlPanelFrameUnit
  , TypesUnit
  ;

type
  TTools = class
  strict private
  public
    class function OpenXML(const AConfigFileName: String): IXMLDocument;
    class function GetConfigFileName: String;
    class function GetCryptoKey: String;
    class procedure CreateConfigFile;
    class procedure LoadHosts(const AHostCallbackProc: THostCallbackProc);
    class procedure SaveHosts;
    class function BuildRCControl(
      const AOwner: TControl;
      const ARCIdent: String): TControlPanelFrame;
    class function ExtractFileName(const APath: String): String;
  end;

implementation

uses
    System.SysUtils
  , System.IOUtils
  , ConstantsUnit
  , FMX.Dialogs
  , FMX.Types
  , CommonConstantsUnit
  , AppManagerUnit
  ;

{ TTools }

class function TTools.OpenXML(const AConfigFileName: String): IXMLDocument;
var
  XMLDoc:               IXMLDocument;
  RootNode:             IXMLNode;
  GeneralSettingsNode:  IXMLNode;
  HostsNode:            IXMLNode;

  ConfigFileName: String;
begin
  Result := nil;

  ConfigFileName := AConfigFileName;

  if not FileExists(ConfigFileName) then
    raise Exception.CreateFmt('Config file "%s" not exists', [ConfigFileName]);

  try
    XMLDoc := LoadXMLDocument(ConfigFileName);
  except
    raise Exception.CreateFmt('Can not load %s', [ConfigFileName]);
  end;

  if not Assigned(XMLDoc) then
    raise Exception.CreateFmt('Error in config file "%s"', [ConfigFileName]);

  RootNode := IXMLDocument(XMLDoc).ChildNodes.FindNode('Config');
  if not Assigned(RootNode) then
    raise Exception.CreateFmt(
      'Node "Config" not found in file "%s"', [ConfigFileName]);

  GeneralSettingsNode := RootNode.ChildNodes.FindNode('General');
  if not Assigned(GeneralSettingsNode) then
    raise Exception.CreateFmt(
      'Node "General" not found in file "%s"', [ConfigFileName]);

  HostsNode := GeneralSettingsNode.ChildNodes.FindNode('Hosts');
  if not Assigned(HostsNode) then
    raise Exception.CreateFmt(
      'Node "Hosts" not found in file "%s"', [ConfigFileName]);

  XMLDoc.Active := true;

  Result := XMLDoc;
end;

class procedure TTools.CreateConfigFile;
var
  XMLDoc:               TXMLDocument;
  RootNode:             IXMLNode;
  GeneralSettingsNode:  IXMLNode;
  HostsNode:            IXMLNode;
begin
  XMLDoc    := TXMLDocument.Create(nil);
  XMLDoc.Active := true;
  XMLDoc.Options := XMLDoc.Options + [doNodeAutoIndent] - [doAutoSave];
  RootNode  := XMLDoc.AddChild('Config');
  GeneralSettingsNode := RootNode.AddChild('General');

  HostsNode := RootNode.AddChild('Hosts');

  XMLDoc.SaveToFile(GetConfigFileName);
end;

class function TTools.GetConfigFileName: String;
begin
  {$IFDEF ANDROID}
  Result :=
    System.IOUtils.TPath.GetDocumentsPath + FILE_PATH_SPLITTER + ConfigFileName;
  {$ELSE IF MSWINDOWS}
  Result :=
    ExtractFilePath(ParamStr(0)) + FILE_PATH_SPLITTER + ConfigFileName;
  {$ENDIF}
end;

class function TTools.GetCryptoKey: String;
var
  TF: TextFile;
  Key: String;
  FileName: String;
begin
  {$IFDEF ANDROID}
  FileName :=
    System.IOUtils.TPath.GetDocumentsPath +
    FILE_PATH_SPLITTER +
    CRYPTO_KEY_FILE_NAME;
  {$ELSE IF MSWINDOWS}
  FileName :=
    ExtractFilePath(ParamStr(0)) +
    FILE_PATH_SPLITTER +
    CRYPTO_KEY_FILE_NAME;
  {$ENDIF}

  if not FileExists(FileName) then
  begin
    ShowMessage('"CryptoKey" file not found');
    ShowMessage('The default key will be used');

    Exit;
  end;

  AssignFile(TF, FileName);
  {$I+}
  try
    Reset(TF);
    try
      Readln(TF, Key);
    finally
      CloseFile(TF);
    end;
  except
    raise Exception.CreateFmt('Error reading file "%s"', [FileName]);
  end;
  {$I-}

  Result := Trim(Key);
end;

class procedure TTools.SaveHosts;
var
  XMLDoc:               IXMLDocument;
  RootNode:             IXMLNode;
  GeneralSettingsNode:  IXMLNode;
  HostsNode:            IXMLNode;
  ChildNode:            IXMLNode;
begin
  XMLDoc    := TXMLDocument.Create(nil);
  XMLDoc.Active := true;
  XMLDoc.Encoding := 'utf-8';
  XMLDoc.Options := XMLDoc.Options + [doNodeAutoIndent] - [doAutoSave];

  if not Assigned(XMLDoc) then
    Exit;

  RootNode  := XMLDoc.AddChild('Config');
  GeneralSettingsNode := RootNode.AddChild('General');
  HostsNode := GeneralSettingsNode.AddChild('Hosts');

  AppManager.RCPool.EnumerateRCHosts(
    procedure (
      const AHostName: String;
      const AIP: String;
      const APort: Word;
      const APassword: String)
    begin
      ChildNode := HostsNode.AddChild('Host');
      ChildNode.AddChild('HostName').   Text := AHostName;
      ChildNode.AddChild('IP').         Text := AIP;
      ChildNode.AddChild('Port').       Text := IntToStr(APort);
      ChildNode.AddChild('Password').   Text := APassword;
    end);

  XMLDoc.SaveToFile(GetConfigFileName);
  ShowMessage('Config saved');
end;

class procedure TTools.LoadHosts(const AHostCallbackProc: THostCallbackProc);
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
  Password:               String;
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
  HostsNode := GeneralSettingsNode.ChildNodes.FindNode('Hosts');

  i := 0;
  while i < HostsNode.ChildNodes.Count do
  begin
    HostNode := HostsNode.ChildNodes[i];
    HostName := HostNode.ChildNodes['HostName'].Text;
    IP := HostNode.ChildNodes['IP'].Text;
    Port := Word(StrToInt(HostNode.ChildNodes['Port'].Text));
    Password := HostNode.ChildNodes['Password'].Text;

    AHostCallbackProc(HostName, IP, Port, Password);

    Inc(i);
  end;
end;

class function TTools.BuildRCControl(
  const AOwner: TControl;
  const ARCIdent: String): TControlPanelFrame;
var
  RCControlFrame: TControlPanelFrame;
begin
  RCControlFrame := TControlPanelFrame.Create(AOwner, ARCIdent);
  RCControlFrame.Parent := AOwner;
  RCControlFrame.Name := '';
  RCControlFrame.HostNameLabel.Text := 'Host name';
  RCControlFrame.CompositionNameLabel.Text := 'Composition';
  RCControlFrame.Align := TAlignLayout.Top;

  Result := RCControlFrame;
end;

class function TTools.ExtractFileName(const APath: String): String;
const
  DelimChars: array[0..1] of Char = ('\', '/');
var
  i: Integer;
  StartIndex: Integer;
begin
  Result := '';

  i := APath.Length;
  if i = 0 then
    Exit;

  StartIndex := 0;
  while i > 0 do
  begin
    if (APath[i] = DelimChars[0]) or (APath[i] = DelimChars[1]) then
    begin
      StartIndex := i;

      Break;
    end;

    Dec(i);
  end;

  if StartIndex <= 0 then
    Exit;

  Result := Copy(APath, StartIndex + 1, APath.Length);
end;

end.
