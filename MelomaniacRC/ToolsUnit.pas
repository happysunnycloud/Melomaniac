unit ToolsUnit;

interface

uses
    Xml.XMLDoc
  , Xml.XMLIntf
  , FMX.Controls
  , ControlPanelFrameUnit
  ;

type
  TTools = class
    class function  OpenXML(const AConfigFileName: String): IXMLDocument;
    class procedure DeleteHost(const AIndex: Integer);
    class procedure CreateConfigFile;
    class function  GetConfigFileName: String;
    class procedure SaveHost(
      const AHostName: String;
      const AIP: String;
      const APort: String;
      const AIndex: Integer);
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
  , StringToolsUnit
  , FMX.Dialogs
  , FMX.Types
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

  HostsNode := RootNode.ChildNodes.FindNode('Hosts');
  if not Assigned(HostsNode) then
    raise Exception.CreateFmt(
      'Node "Hosts" not found in file "%s"', [ConfigFileName]);

  XMLDoc.Active := true;

  Result := XMLDoc;
end;

class procedure TTools.DeleteHost(const AIndex: Integer);
var
  XMLDoc:               IXMLDocument;
  RootNode:             IXMLNode;
  GeneralSettingsNode:  IXMLNode;
  HostsNode:            IXMLNode;
begin
  XMLDoc := OpenXML(GetConfigFileName);

  if not Assigned(XMLDoc) then
    Exit;

  RootNode := XMLDoc.ChildNodes.FindNode('Config');
  GeneralSettingsNode := RootNode.ChildNodes.FindNode('General');
  HostsNode := RootNode.ChildNodes.FindNode('Hosts');

  HostsNode.ChildNodes.Delete(AIndex);
  XMLDoc.SaveToFile(GetConfigFileName);
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

class procedure TTools.SaveHost(
  const AHostName: String;
  const AIP: String;
  const APort: String;
  const AIndex: Integer);

  function _ValueExists(
    const AHostsNode: IXMLNode;
    const ANodeName: String;
    const AValue: String): Boolean;
  var
    HostsNode: IXMLNode absolute AHostsNode;
    Node: IXMLNode;
    ChildNode: IXMLNode;
    i: Word;
    Value: String;
  begin
    Result := false;

    Value := AValue;
    if Length(Value) = 0 then
      Exit;

    i := 0;
    while i < HostsNode.ChildNodes.Count do
    begin
      ChildNode := HostsNode.ChildNodes[i];
      Node := ChildNode.ChildNodes[ANodeName];
      if not Assigned(Node) then
        raise Exception.CreateFmt('Node "%s" not found', [ANodeName]);

      if Trim(Node.Text).ToUpper = Trim(Value).ToUpper then
        Exit(true);

      Inc(i);
    end;
  end;

var
  XMLDoc:               IXMLDocument;
  RootNode:             IXMLNode;
  GeneralSettingsNode:  IXMLNode;
  HostsNode:            IXMLNode;
  ChildNode:            IXMLNode;
  HostName:             String;
  IP:                   String;
  Port:                 Word;
begin
  XMLDoc := OpenXML(GetConfigFileName);
  if not Assigned(XMLDoc) then
    Exit;

  if (Length(Trim(AHostName)) = 0) and (Length(Trim(AIP)) = 0) then
  begin
    ShowMessage('The "Host name" or "IP" field can not be empty' );

    Exit;
  end;

  if Length(Trim(APort)) = 0 then
  begin
    ShowMessage('The "Port" field can not be empty' );

    Exit;
  end;

  if not TStringTools.IsContainsOnlyDigits(Trim(APort)) then
  begin
    ShowMessage('The "Port" field can only contain numbers' );

    Exit;
  end;

  if (Length(Trim(AIP)) > 0)
      and
      not TStringTools.IsIP4(Trim(AIP))
  then
  begin
    ShowMessage('The "IP" is incorrect' );

    Exit;
  end;

  HostName := Trim(AHostName);
  IP       := Trim(AIP);
  Port     := StrToInt(Trim(APort));

  if not ((Port > 0) and (Port < 65000)) then
  begin
    ShowMessage('The "Port" value out of range. Must be between 1 and 65K' );

    Exit;
  end;

  RootNode := XMLDoc.ChildNodes.FindNode('Config');
  GeneralSettingsNode := RootNode.ChildNodes.FindNode('General');
  HostsNode := RootNode.ChildNodes.FindNode('Hosts');

  if AIndex < 0 then
  begin
    if _ValueExists(HostsNode, 'HostName', HostName) then
    begin
      ShowMessage(Format('Then host name "%s" exists', [HostName]));

      Exit;
    end;

    if _ValueExists(HostsNode, 'IP', IP) then
    begin
      ShowMessage(Format('Then IP "%s" exists', [IP]));

      Exit;
    end;

    ChildNode := HostsNode.AddChild('Host');
    ChildNode.AddChild('HostName').   Text := HostName;
    ChildNode.AddChild('IP').         Text := IP;
    ChildNode.AddChild('Port').       Text := IntToStr(Port);
  end
  else
  begin
    ChildNode := HostsNode.ChildNodes[AIndex];
    ChildNode.ChildNodes.FindNode('HostName').Text := HostName;
    ChildNode.ChildNodes.FindNode('IP').      Text := IP;
    ChildNode.ChildNodes.FindNode('Port').    Text := IntToStr(Port);
  end;

  XMLDoc.SaveToFile(GetConfigFileName);
  ShowMessage('Config saved');
end;

class function TTools.BuildRCControl(
  const AOwner: TControl;
  const ARCIdent: String): TControlPanelFrame;

  function RCControlFrameCount: Word;
  var
    i, j: Word;
  begin
    i := 0;
    j := 0;
    while i < AOwner.ComponentCount do
    begin
      if AOwner.Components[i] is TControlPanelFrame then
        Inc(j);

      Inc(i);
    end;

    Result := j;
  end;

var
  RCControlFrame: TControlPanelFrame;
  YPosition:      Single;
begin
  YPosition := RCControlFrameCount;
  RCControlFrame := TControlPanelFrame.Create(AOwner, ARCIdent);
  RCControlFrame.Name := '';
  RCControlFrame.HostNameLabel.Text := 'Host name';
  RCControlFrame.CompositionNameLabel.Text := 'Composition';
  RCControlFrame.Position.Y := YPosition * RCControlFrame.Height;
  RCControlFrame.Align := TAlignLayout.Top;

  AOwner.AddObject(RCControlFrame);

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
