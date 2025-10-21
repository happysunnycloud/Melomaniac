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
  public
    constructor Create(const AThreadFactory: TThreadFactory);
    destructor Destroy; override;

    procedure Clear;

    procedure ReloadPlayList(
      const ADir: String);

    property OnPlayListReloaded: TPlayListReloadedProRef
      read FOnPlayListReloaded write FOnPlayListReloaded;

    property First: TPlayItem read GetFirst;
    property Last: TPlayItem read GetLast;
    property Next: TPlayItem read GetNext;
    property Prev: TPlayItem read GetPrev;
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

procedure TPlayList.ReloadPlayList(const ADir: String);
var
  FileNames: TFileNames;
  i: Integer;
  StartIndex: Integer;
  FinishIndex: Integer;
  FilesPerThread: Integer;
  FileCount: Integer;
begin
  SetLength(FileNames, 0);
  TFileTools.GetTreeOfFileNames(ADir, '', FileNames);

  FCurrentIndex := 0;

  // создаём потоки
  FileCount := Length(FileNames);
  FilesPerThread := Ceil(FileCount / PLAY_LIST_RELOAD_THREAD_COUNT);
  for i := 0 to PLAY_LIST_RELOAD_THREAD_COUNT - 1 do
  begin
    StartIndex := i * FilesPerThread;
    FinishIndex := Min(StartIndex + FilesPerThread - 1, FileCount);
    if StartIndex > FileCount then
      Break;

    TTAGReaderThread.Create(
      FThreadFactory,
      Self,
      FileNames,
      StartIndex,
      FinishIndex);
  end;

  FThreadFactory.OnAllThreadsAreDestroyedProcRef :=
    procedure
    begin
      TThread.Queue(nil,
      procedure
      begin
        if Assigned(FOnPlayListReloaded) then
          FOnPlayListReloaded;
      end);
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

end.
