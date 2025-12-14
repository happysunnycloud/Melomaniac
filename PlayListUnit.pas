unit PlayListUnit;

interface

uses
    System.Generics.Collections
  , System.Classes
  , ThreadFactoryUnit
  , LockedListExtUnit
  , FileToolsUnit
  ;

const
  ALLOWED_EXTENSIONS: array[0..3] of String = ('mp3', 'ogg', 'flac', 'wav');

type
  TPlayListReloadedProRef = reference to procedure;

  TPlayItem = class
  strict private
    FTitle: String;
    FArtist: String;
    FAlbum: String;
    FYear: String;
    FDuration: Double; // в секундах
    FPath: String;
  public
    constructor Create;

    property Title: String read FTitle write FTitle;
    property Artist: String read FArtist  write FArtist;
    property Album: String read FAlbum write FAlbum;
    property Year: String read FYear write FYear;
    property Duration: Double read FDuration write FDuration;
    property Path: String read FPath write FPath;
  end;

  TPlayItemsList = TList<TPlayItem>;

  TPlayList = class(TLockedListExt<TPlayItem>)
  strict private
    FThreadFactory: TThreadFactory;
    FOnPlayListReloaded: TPlayListReloadedProRef;
    FCurrentIndex: Integer;

    function GetFirst: TPlayItem;
    function GetLast: TPlayItem;
    function GetNext: TPlayItem;
    function GetPrev: TPlayItem;
    function GetCurrent: TPlayItem;

    function GetFirstComposition: String;
    function GetPrevComposition: String;
    function GetNextComposition: String;
    function GetCurrentComposition: String;

    procedure OnAllThreadsAreDestroyed(Sender: TObject);

    procedure FreePlayItemsList(var APlayItemsList: TPlayItemsList);
  public
    constructor Create(const AThreadFactory: TThreadFactory);
    destructor Destroy; override;

    procedure Clear;
    procedure FreeItem(const APlayItem: TPlayItem);
    function IndexOf(const AFileName: String): Integer;

    procedure ReloadPlayListFromPath(
      const APath: String);
    procedure ReloadPlayListByFileNames(
      const AFileNames: TFileNames);
    procedure ReloadPlayListFromDB(
      const AMainPath: String);

    procedure SyncPlayLists(
      const APath: String);

    procedure SaveToDB;

    property OnPlayListReloaded: TPlayListReloadedProRef
      read FOnPlayListReloaded write FOnPlayListReloaded;

    property First: TPlayItem read GetFirst;
    property Last: TPlayItem read GetLast;
    property Next: TPlayItem read GetNext;
    property Prev: TPlayItem read GetPrev;
    property Current: TPlayItem read GetCurrent;
    property FirstComposition: String read GetFirstComposition;
    property PrevComposition: String read GetPrevComposition;
    property NextComposition: String read GetNextComposition;
    property CurrentComposition: String read GetCurrentComposition;
    property CurrentIndex: Integer read FCurrentIndex write FCurrentIndex;
  end;

implementation

uses
    System.SysUtils
  , System.Math
  , TAGReaderThreadUnit
  , ConstantsUnit
  , ToolsUnit
  ;

{ TPlayItem }

constructor TPlayItem.Create;
begin
  FTitle := '';
  FArtist := '';
  FAlbum := '';
  FYear := '';
  FDuration := 0;
  FPath := '';
end;

{ TPlayList }

constructor TPlayList.Create(const AThreadFactory: TThreadFactory);
begin
  inherited Create;

  FThreadFactory := AThreadFactory;
  FOnPlayListReloaded := nil;

  FCurrentIndex := 0;
end;

destructor TPlayList.Destroy;
begin
  Self.Clear;

  inherited;
end;

procedure TPlayList.Clear;
var
  PlayItemsList: TPlayItemsList;
begin
  PlayItemsList := LockList;
  try
    while PlayItemsList.Count > 0 do
    begin
      PlayItemsList.Items[0].Free;
      PlayItemsList.Delete(0);
    end;
  finally
    UnlockList;
  end;

  inherited Clear;
end;

procedure TPlayList.FreeItem(const APlayItem: TPlayItem);
var
  Index: Integer;
begin
  Index := IndexOf(APlayItem.Path);
  if Index = Pred(Self.Count) then
    CurrentIndex := 0;
  Remove(APlayItem);
  APlayItem.Free;
end;

function TPlayList.IndexOf(const AFileName: String): Integer;
var
  i: Integer;
begin
  Result := -1;

  i := Count;
  while i > 0 do
  begin
    Dec(i);

    if AFileName = Items[i].Path then
      Exit(i);
  end;
end;

procedure TPlayList.OnAllThreadsAreDestroyed(Sender: TObject);
begin
  TThread.ForceQueue(nil,
    procedure
    begin
      if Assigned(FOnPlayListReloaded) then
        FOnPlayListReloaded;
    end);
end;

procedure TPlayList.FreePlayItemsList(var APlayItemsList: TPlayItemsList);
begin
  while APlayItemsList.Count > 0 do
  begin
    APlayItemsList.Items[0].Free;
    APlayItemsList.Delete(0);
  end;

  FreeAndNil(APlayItemsList);
end;

procedure TPlayList.ReloadPlayListFromPath(const APath: String);
var
  FileNames: TFileNames;
begin
  SetLength(FileNames, 0);
  TFileTools.GetTreeOfFileNames(APath, ALLOWED_EXTENSIONS, FileNames);

  if Length(FileNames) > 0 then
    ReloadPlayListByFileNames(FileNames);
end;

procedure TPlayList.ReloadPlayListByFileNames(
  const AFileNames: TFileNames);
var
  FileNames: TFileNames absolute AFileNames;
  i: Integer;
  StartIndex: Integer;
  FinishIndex: Integer;
  FilesPerThread: Integer;
  FileCount: Integer;
begin
  Clear;

  FCurrentIndex := 0;

  // создаём потоки
  FileCount := Length(FileNames);
  if FileCount > PLAY_LIST_RELOAD_THREAD_COUNT then
  begin
    FilesPerThread := Ceil(FileCount / PLAY_LIST_RELOAD_THREAD_COUNT);
    for i := 0 to PLAY_LIST_RELOAD_THREAD_COUNT - 1 do
    begin
      StartIndex := i * FilesPerThread;
      FinishIndex := Min(StartIndex + FilesPerThread - 1, FileCount - 1);
      if StartIndex > FileCount then
        Break;

      TTAGReaderThread.Create(
        FThreadFactory,
        Self,
        FileNames,
        StartIndex,
        FinishIndex);
    end;
  end
  else
  begin
    TTAGReaderThread.Create(
      FThreadFactory,
      Self,
      FileNames,
      0,
      Pred(FileCount));
  end;

  FThreadFactory.OnAllThreadsAreDestroyed := OnAllThreadsAreDestroyed;
end;

procedure TPlayList.ReloadPlayListFromDB(
  const AMainPath: String);
var
  PlayItemsList: TPlayItemsList;
begin
  Clear;

  PlayItemsList := LockList;
  try
    TTools.SelectPlayItemsListFromDB(AMainPath, PlayItemsList);
  finally
    UnlockList;
  end;
end;

procedure TPlayList.SyncPlayLists(
  const APath: String);
var
  Path: String;
  DBPlayItemsList: TPlayItemsList;
  PathPlayItemsList: TPlayItemsList;
  ToAddFileNames: TFileNames;
  DBPlayItem: TPlayItem;
  PathPlayItem: TPlayItem;
  FileNames: TFileNames;
  FileName: String;
  i: Integer;
  IsFound: Boolean;
begin
  Path := APath;

  DBPlayItemsList := TPlayItemsList.Create;
  PathPlayItemsList := TPlayItemsList.Create;
  try
    TTools.SelectPlayItemsListFromDB(Path, DBPlayItemsList);

    SetLength(FileNames, 0);
    // Проверяем на пустой путь, если путь пуст, то пойдет поиск по всему диску
    // Нам не нужно искать по всему диску, только по конкретной папке
    if Length(Path) > 0 then
      TFileTools.GetTreeOfFileNames(Path, ALLOWED_EXTENSIONS, FileNames);
    for i := 0 to Pred(Length(FileNames)) do
    begin
      FileName := FileNames[i];
      PathPlayItem := TPlayItem.Create;
      PathPlayItem.Path := FileName;
      PathPlayItemsList.Add(PathPlayItem);
    end;

    for PathPlayItem in PathPlayItemsList do
    begin
      IsFound := false;

      for i := 0 to Pred(DBPlayItemsList.Count) do
      begin
        DBPlayItem := DBPlayItemsList[i];
        if PathPlayItem.Path = DBPlayItem.Path then
        begin
          DBPlayItemsList.Delete(i);
          FreeAndNil(DBPlayItem);

          IsFound := true;

          Break;
        end;
      end;

      if not IsFound then
        ToAddFileNames.Add(PathPlayItem.Path);
    end;

    if DBPlayItemsList.Count > 0 then
      TTools.DeletePlayItemsListFromDB(DBPlayItemsList);

    if Length(ToAddFileNames) > 0 then
      ReloadPlayListByFileNames(ToAddFileNames)
    else
      if Assigned(OnPlayListReloaded) then
        OnPlayListReloaded;

  finally
    FreePlayItemsList(PathPlayItemsList);
    FreePlayItemsList(DBPlayItemsList);
  end;
end;

procedure TPlayList.SaveToDB;
var
  PlayItemsList: TPlayItemsList;
begin
  PlayItemsList := LockList;
  try
    if PlayItemsList.Count = 0 then
      Exit;

    TTools.InsertPlayItemsListToDB(PlayItemsList);
  finally
    UnlockList;
  end;
end;

function TPlayList.GetFirst: TPlayItem;
begin
  Result := nil;

  if Self.Count = 0 then
    Exit;

  FCurrentIndex := 0;
  Result := Self.Items[FCurrentIndex];
end;

function TPlayList.GetLast: TPlayItem;
begin
  Result := nil;

  if Self.Count = 0 then
    Exit;

  FCurrentIndex := Self.Count - 1;
  Result := Self.Items[FCurrentIndex];
end;

function TPlayList.GetNext: TPlayItem;
begin
  Result := nil;

  if Self.Count = 0 then
    Exit;

  FCurrentIndex := FCurrentIndex + 1;
  if FCurrentIndex > Pred(Self.Count) then
    FCurrentIndex := 0;
  Result := Self.Items[FCurrentIndex];
end;

function TPlayList.GetPrev: TPlayItem;
begin
  Result := nil;

  if Self.Count = 0 then
    Exit;

  FCurrentIndex := FCurrentIndex - 1;
  if FCurrentIndex < 0 then
    FCurrentIndex := Pred(Self.Count);
  Result := Self.Items[FCurrentIndex];
end;

function TPlayList.GetCurrent: TPlayItem;
begin
  Result := nil;

  if Self.Count = 0 then
    Exit;

  Result := Self.Items[FCurrentIndex];
end;

function TPlayList.GetFirstComposition: String;
var
  PlayItem: TPlayItem;
begin
  Result := '';

  PlayItem := First;
  if Assigned(PlayItem) then
    Result := PlayItem.Path;
end;

function TPlayList.GetPrevComposition: String;
var
  PlayItem: TPlayItem;
begin
  Result := '';

  PlayItem := Prev;
  if Assigned(PlayItem) then
    Result := PlayItem.Path;
end;

function TPlayList.GetNextComposition: String;
var
  PlayItem: TPlayItem;
begin
  Result := '';

  PlayItem := Next;
  if Assigned(PlayItem) then
    Result := PlayItem.Path;
end;

function TPlayList.GetCurrentComposition: String;
var
  PlayItem: TPlayItem;
begin
  Result := '';

  PlayItem := Current;
  if Assigned(PlayItem) then
    Result := PlayItem.Path;
end;

end.
