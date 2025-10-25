unit StateUnit;

interface

uses
    System.Generics.Collections
  , FMX.Media
  ;

type
  TPlayState = (psPlay = 1, psPause = 0, psStop = -1);

  TPaths = class (TList<String>)
  strict private
    // 0 - TopLeft
    // 1 - TopRigth
    // 2 - BottomLeft
    // 3 - BottomRight
  public
  end;

  TSetOfPaths = class (TList<TPaths>)
  strict private
  public
    destructor Destroy; override;
  end;

  TState = class
  strict private
    class var FMainPath: String;
    class var FLastMainPath: String;
    class var FVolume: Single;
    class var FLastVolume: Single;
    class var FCurrentTime: TMediaTime;
    class var FComposition: String;
    class var FCopyMode: Boolean;
    class var FMarkMode: Boolean;
    class var FDuplicateMode: Boolean;
    class var FVisualScheme: String;
    class var FSetOfPathsIndex: Integer;

    class var FSetOfPaths: TSetOfPaths;
  strict private
    class var FPlayState: TPlayState;
    class var FLastPlayState: TPlayState;

    class procedure SetPlayState(const APlayState: TPlayState); static;
  public
    class procedure Init;
    class procedure UnInit;

    class function SaveConfig: Boolean;
    class function LoadConfig: Boolean;

    class property PlayState: TPlayState
      read FPlayState write SetPlayState;
    class property LastPlayState: TPlayState
      read FLastPlayState write FLastPlayState;

    class property MainPath: String
      read FMainPath write FMainPath;
    class property LastMainPath: String
      read FLastMainPath write FLastMainPath;
    class property Volume: Single
      read FVolume write FVolume;
    class property LastVolume: Single
      read FLastVolume write FLastVolume;
    class property CurrentTime: TMediaTime
      read FCurrentTime write FCurrentTime;
    class property Composition: String
      read FComposition write FComposition;
    class property CopyMode: Boolean
      read FCopyMode write FCopyMode;
    class property MarkMode: Boolean
      read FMarkMode write FMarkMode;
    class property DuplicateMode: Boolean
      read FDuplicateMode write FDuplicateMode;
    class property VisualScheme: String
      read FVisualScheme write FVisualScheme;
    class property SetOfPathsIndex: Integer
      read FSetOfPathsIndex write FSetOfPathsIndex;
  end;

implementation

uses
    System.SysUtils
  , Xml.XMLIntf
  , Xml.XMLDoc
  ;

{ TSetOfPaths }

destructor TSetOfPaths.Destroy;
begin
  while Count > 0 do
  begin
    Items[0].Free;
    Delete(0);
  end;

  inherited;
end;

{ TState }

class procedure TState.Init;
var
  Paths: TPaths;
begin
  FPlayState := psStop;
  FLastPlayState := FPlayState;

  FMainPath := '';
  FLastMainPath := '';
  FVolume := 0.5;
  FLastVolume := 0.5;
  FCurrentTime := 0;
  FComposition := '';
  FCopyMode := false;
  FMarkMode := false;
  FDuplicateMode := false;
  FVisualScheme := '';
  FSetOfPathsIndex := 0;

  FSetOfPaths := TSetOfPaths.Create;
  LoadConfig;

  if FSetOfPaths.Count = 0 then
  begin
    Paths := TPaths.Create;
    Paths.Add('0');
    Paths.Add('1');
    Paths.Add('2');
    Paths.Add('3');
    FSetOfPaths.Add(Paths);
    Paths := TPaths.Create;
    Paths.Add('0');
    Paths.Add('1');
    Paths.Add('2');
    Paths.Add('3');
    FSetOfPaths.Add(Paths);
    Paths := TPaths.Create;
    Paths.Add('0');
    Paths.Add('1');
    Paths.Add('2');
    Paths.Add('3');
    FSetOfPaths.Add(Paths);
    Paths := TPaths.Create;
    Paths.Add('0');
    Paths.Add('1');
    Paths.Add('2');
    Paths.Add('3');
    FSetOfPaths.Add(Paths);
  end;
end;

class procedure TState.UnInit;
begin
  SaveConfig;

  FreeAndNil(FSetOfPaths);
end;

class procedure TState.SetPlayState(const APlayState: TPlayState);
begin
  FLastPlayState := FPlayState;
  FPlayState := APlayState;
end;

class function TState.SaveConfig: Boolean;
var
  XMLDoc: IXMLDocument;
  RootNode: IXMLNode;
  CommonNode: IXMLNode;
  SetsOfPathsNode: IXMLNode;
  SetOfPathsNode: IXMLNode;
  i, j: Integer;
  CongifFileName: String;
begin
  Result := false;

  XMLDoc    := TXMLDocument.Create(nil);
  XMLDoc.Active := true;
  XmlDoc.Encoding := 'utf-8';
  XMLDoc.Options := XMLDoc.Options + [doNodeAutoIndent] - [doAutoSave];

  RootNode  := XMLDoc.AddChild('Config');
  CommonNode := RootNode.AddChild('Common');

  CommonNode.AddChild('MainPath').Text := FMainPath;
  CommonNode.AddChild('LastMainPath').Text := FLastMainPath;
  CommonNode.AddChild('Volume').Text := FloatToStr(FVolume);
  CommonNode.AddChild('LastVolume').Text := FloatToStr(FLastVolume);
  CommonNode.AddChild('CurrentTime').Text := IntToStr(FCurrentTime);
  CommonNode.AddChild('Composition').Text := FComposition;
  CommonNode.AddChild('CopyMode').Text := BoolToStr(FCopyMode, true);
  CommonNode.AddChild('MarkMode').Text := BoolToStr(FMarkMode, true);;
  CommonNode.AddChild('DuplicateMode').Text := BoolToStr(FDuplicateMode, true);
  CommonNode.AddChild('VisualScheme').Text := FVisualScheme;
  CommonNode.AddChild('SetOfPathsIndex').Text := IntToStr(FSetOfPathsIndex);

  SetsOfPathsNode := RootNode.AddChild('SetsOfPaths');

  for i := 0 to Pred(FSetOfPaths.Count) do
  begin
    SetOfPathsNode := SetsOfPathsNode.AddChild('SetOfPaths' + IntToStr(i));
    for j := 0 to Pred(FSetOfPaths[i].Count) do
    begin
      SetOfPathsNode.AddChild('Path' + IntToStr(j)).Text := FSetOfPaths[i][j];
    end;
  end;

  CongifFileName := ExtractFilePath(ParamStr(0)) + 'Melomaniac.conf';
  try
    XMLDoc.SaveToFile(CongifFileName);
    Result := true;
  except
    raise Exception.
      CreateFmt('TState.SaveConfig -> Can not save "%s"', [CongifFileName]);
  end;

  Result := true;
end;

class function TState.LoadConfig: Boolean;
var
  XMLDoc: IXMLDocument;
  RootNode: IXMLNode;
  CommonNode: IXMLNode;
  SetsOfPathsNode: IXMLNode;
  SetOfPathsNode: IXMLNode;
  Paths: TPaths;
  ChildNode: IXMLNode;
  i, j: Integer;
  CongifFileName: String;
begin
  Result := false;

  CongifFileName := ExtractFilePath(ParamStr(0)) + 'Melomaniac.conf';

  if not FileExists(ExtractFilePath(ParamStr(0)) + 'Melomaniac.conf') then
  begin
    //при самом первом запуске приложения, после инсталляции файл может не существовать
    //это совершенно нормальная ситуация

    Exit;
  end;

  try
    XMLDoc := LoadXMLDocument(CongifFileName);
  except
    raise Exception.
      CreateFmt('TState.LoadConfig -> Can not load "%s"', [CongifFileName]);
  end;

  RootNode := XMLDoc.ChildNodes.FindNode('Config');
  if RootNode = nil then
  begin
    raise Exception.
      CreateFmt('TState.LoadConfig -> Root node is nil in "%s"', [CongifFileName]);
  end;

  CommonNode := RootNode.ChildNodes.FindNode('Common');
  if CommonNode = nil then
  begin
    raise Exception.
      CreateFmt('TState.LoadConfig -> Common node is nil in "%s"', [CongifFileName]);
  end;

  FMainPath := CommonNode.ChildNodes['MainPath'].Text;
  FLastMainPath := CommonNode.ChildNodes['MainPath'].Text;
  FVolume := StrToFloat(CommonNode.ChildNodes['Volume'].Text);
  FLastVolume := StrToFloat(CommonNode.ChildNodes['LastVolume'].Text);
  FCurrentTime := StrToInt(CommonNode.ChildNodes['CurrentTime'].Text);
  FComposition := CommonNode.ChildNodes['Composition'].Text;
  FCopyMode := StrToBool(CommonNode.ChildNodes['CopyMode'].Text);
  FMarkMode := StrToBool(CommonNode.ChildNodes['MarkMode'].Text);
  FDuplicateMode := StrToBool(CommonNode.ChildNodes['DuplicateMode'].Text);
  FVisualScheme := CommonNode.ChildNodes['VisualScheme'].Text;
  FSetOfPathsIndex := StrToInt(CommonNode.ChildNodes['SetOfPathsIndex'].Text);

  SetsOfPathsNode := RootNode.ChildNodes.FindNode('SetsOfPaths');
  for i := 0 to Pred(SetsOfPathsNode.ChildNodes.Count) do
  begin
//    FSetOfPaths := TSetOfPaths.Create;
    SetOfPathsNode := SetsOfPathsNode.ChildNodes[i];
    Paths := TPaths.Create;
    for j := 0 to Pred(SetOfPathsNode.ChildNodes.Count) do
      Paths.Add(SetOfPathsNode.ChildNodes[j].Text);

    FSetOfPaths.Add(Paths);
  end;

  Result := true;
end;

end.
