unit StateUnit;

interface

uses
    System.Generics.Collections
  , FMX.Media
  ;

type
  TPlayState = (psStop = -1, psPlay = 1, psPause = 0);
  TCopyMode = (cmNone = -1, cmCopy = 0, cmMove = 1);
  TLeafe = (liNone = -1, liTopLeft = 0, liTopRigth = 1, liBottomLeft = 2, liBottomRight = 3);

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
    class var FCopyMode: TCopyMode;
    class var FMarkMode: Boolean;
    class var FDuplicateMode: Boolean;
    class var FVisualScheme: String;
    class var FSetOfPathsIndex: Integer;
    class var FSetOfPaths: TSetOfPaths;
    class var FLeafe: TLeafe;
    class var FPlayState: TPlayState;
    // Выставляется в true, когда стартуем
    // Определяем как будет запускаться композиция
    // Если true, то с момента последнего останова
    // Если false, то с первого трека в плейлисте
    class var FIsAppStarting: Boolean;

//    class procedure SetSetOfPaths(const A)
  strict private
    class function GetSetOfPaths(const AIndex: Integer): TPaths; static;

    class procedure SetPlayState(const APlayState: TPlayState); static;
    class procedure SetSetOfPathsIndex(const ASetOfPathsIndex: Integer); static;
    class function GetIsAppStarting: Boolean; static;
  public
    class procedure Init;
    class procedure UnInit;

    class function SaveConfig: Boolean;
    class function LoadConfig: Boolean;

    class property PlayState: TPlayState
      read FPlayState write SetPlayState;
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
    class property CopyMode: TCopyMode
      read FCopyMode write FCopyMode;
    class property MarkMode: Boolean
      read FMarkMode write FMarkMode;
    class property DuplicateMode: Boolean
      read FDuplicateMode write FDuplicateMode;
    class property VisualScheme: String
      read FVisualScheme write FVisualScheme;
    class property SetOfPathsIndex: Integer
      read FSetOfPathsIndex write SetSetOfPathsIndex;
    class property SetOfPaths[const AIndex: Integer]: TPaths
      read GetSetOfPaths;
    class property Leafe: TLeafe read FLeafe write FLeafe;
    class property IsAppStarting: Boolean read GetIsAppStarting;
  end;

  TPlayStateHelper = record helper for TPlayState
  public
    function ToInt: Integer;
    procedure FromInt(const AVal: Integer);
  end;

  TCopyModeHelper = record helper for TCopyMode
  public
    function ToInt: Integer;
    procedure FromInt(const AVal: Integer);
  end;

  TLeafeHelper = record helper for TLeafe
  public
    function ToPath: String;
  end;

implementation

uses
    System.SysUtils
  , Xml.XMLIntf
  , Xml.XMLDoc
  , ToolsUnit
  , PlayControllerUnit
  ;

{ TPlayStateHelper }

function TPlayStateHelper.ToInt: Integer;
begin
  Result := Integer(Self);
end;

procedure TPlayStateHelper.FromInt(const AVal: Integer);
begin
  case AVal of
    -1: Self := psStop;
     0: Self := psPause;
     1: Self := psPlay;
  else
    raise Exception.
      CreateFmt('TPlayStateHelper.FromInt -> Unable to match value "%d"', [AVal]);
  end;
end;

{ TCopyModeHelper }


function TCopyModeHelper.ToInt: Integer;
begin
  Result := Integer(Self);
end;

procedure TCopyModeHelper.FromInt(const AVal: Integer);
begin
  case AVal of
    -1: Self := cmNone;
     0: Self := cmCopy;
     1: Self := cmMove;
  else
    raise Exception.
      CreateFmt('TCopyModeHelper.FromInt -> Unable to match value "%d"', [AVal]);
  end;
end;

{ TLeafeHelper }

function TLeafeHelper.ToPath: String;
begin
  Result := '';
  if Self < liTopLeft then
    Exit;

  Result :=
    TState.SetOfPaths[TState.SetOfPathsIndex].Items[Integer(Self)];
end;

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
  FMainPath := '';
  FLastMainPath := '';
  FVolume := 0.5;
  FLastVolume := 0.5;
  FCurrentTime := 0;
  FComposition := '';
  FCopyMode := cmNone;
  FMarkMode := false;
  FDuplicateMode := false;
  FVisualScheme := '';
  FSetOfPathsIndex := 0;
  FLeafe := liNone;
  FIsAppStarting := true;

  FSetOfPaths := TSetOfPaths.Create;
  LoadConfig;

  if FSetOfPaths.Count = 0 then
  begin
    Paths := TPaths.Create;
    Paths.Add('');
    Paths.Add('');
    Paths.Add('');
    Paths.Add('');
    FSetOfPaths.Add(Paths);
    Paths := TPaths.Create;
    Paths.Add('');
    Paths.Add('');
    Paths.Add('');
    Paths.Add('');
    FSetOfPaths.Add(Paths);
    Paths := TPaths.Create;
    Paths.Add('');
    Paths.Add('');
    Paths.Add('');
    Paths.Add('');
    FSetOfPaths.Add(Paths);
    Paths := TPaths.Create;
    Paths.Add('');
    Paths.Add('');
    Paths.Add('');
    Paths.Add('');
    FSetOfPaths.Add(Paths);
  end;
end;

class procedure TState.UnInit;
begin
  SaveConfig;

  FreeAndNil(FSetOfPaths);
end;

class function TState.GetSetOfPaths(const AIndex: Integer): TPaths;
begin
  if (AIndex < 0) or (AIndex > Pred(FSetOfPaths.Count)) then
    raise Exception.
      CreateFmt('TState.GetSetOfPaths -> Index "%d" out of range', [AIndex]);

  Result := FSetOfPaths.Items[AIndex];
end;

class procedure TState.SetPlayState(const APlayState: TPlayState);
begin
  FPlayState := APlayState;
end;

class procedure TState.SetSetOfPathsIndex(const ASetOfPathsIndex: Integer);
begin
  FSetOfPathsIndex := ASetOfPathsIndex;
  TTools.FillPaths(FSetOfPathsIndex);
  TPlayController.HeighlightSetOfPaths;
end;

class function TState.GetIsAppStarting: Boolean;
begin
  Result := FIsAppStarting;
  FIsAppStarting := false;
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
  XMLDoc    := TXMLDocument.Create(nil);
  XMLDoc.Active := true;
  XmlDoc.Encoding := 'utf-8';
  XMLDoc.Options := XMLDoc.Options + [doNodeAutoIndent] - [doAutoSave];

  RootNode  := XMLDoc.AddChild('Config');
  CommonNode := RootNode.AddChild('Common');

  CommonNode.AddChild('MainPath').Text := FMainPath;
  CommonNode.AddChild('LastMainPath').Text := FLastMainPath;
  CommonNode.AddChild('PlayState').Text := IntToStr(FPlayState.ToInt);
  CommonNode.AddChild('Volume').Text := FloatToStr(FVolume);
  CommonNode.AddChild('LastVolume').Text := FloatToStr(FLastVolume);
  CommonNode.AddChild('CurrentTime').Text := IntToStr(FCurrentTime);
  CommonNode.AddChild('Composition').Text := FComposition;
  CommonNode.AddChild('CopyMode').Text := IntToStr(FCopyMode.ToInt);
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
  i, j: Integer;
  CongifFileName: String;
  PlayStateStrVal: String;
  CopyModeStrVal: String;
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
  PlayStateStrVal := CommonNode.ChildNodes['PlayState'].Text;
  FPlayState.FromInt(StrToIntDef(PlayStateStrVal, psStop.ToInt));
  FLastMainPath := CommonNode.ChildNodes['MainPath'].Text;
  FVolume := StrToFloat(CommonNode.ChildNodes['Volume'].Text);
  FLastVolume := StrToFloat(CommonNode.ChildNodes['LastVolume'].Text);
  FCurrentTime := StrToInt(CommonNode.ChildNodes['CurrentTime'].Text);
  FComposition := CommonNode.ChildNodes['Composition'].Text;
  CopyModeStrVal := CommonNode.ChildNodes['CopyMode'].Text;
  FCopyMode.FromInt(StrToIntDef(CopyModeStrVal, cmNone.ToInt));
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
