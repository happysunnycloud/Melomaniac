unit PlayListUnit;

interface

uses
    System.Generics.Collections
  , System.Classes
  , ThreadFactoryUnit
  , LockedListExtUnit
  ;

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
  public
    constructor Create(const AThreadFactory: TThreadFactory);
    destructor Destroy; override;

    procedure Clear;
    procedure FreeItem(const APlayItem: TPlayItem);
    function IndexOf(const AFileName: String): Integer;

    procedure ReloadPlayList(
      const ADir: String);

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
  , FileToolsUnit
  , TAGReaderThreadUnit
  , ConstantsUnit
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
begin
  while Count > 0 do
  begin
    Items[0].Free;
    Delete(0);
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

procedure TPlayList.ReloadPlayList(const ADir: String);
var
  FileNames: TFileNames;
  i: Integer;
  StartIndex: Integer;
  FinishIndex: Integer;
  FilesPerThread: Integer;
  FileCount: Integer;
begin
  Clear;

  SetLength(FileNames, 0);
  TFileTools.GetTreeOfFileNames(ADir, 'mp3', FileNames);

  FCurrentIndex := 0;

  // создаём потоки
  FileCount := Length(FileNames);
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

  FThreadFactory.OnAllThreadsAreDestroyed := OnAllThreadsAreDestroyed;
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
