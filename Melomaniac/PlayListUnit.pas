unit PlayListUnit;

interface

uses
    System.Generics.Collections
  , System.Classes
  {TODO: проверить и убрать}
  , ThreadFactoryUnit
  , LockedListExtUnit
  , FileToolsUnit
  , CommonTypesUnit
  , TypesUnit
  ;

const
  ALLOWED_EXTENSIONS: array[0..3] of String = ('mp3', 'ogg', 'flac', 'wav');

type
  TPlayListSynchronizedProcRef = reference to procedure;

  TPlayList = class(TLockedListExt<TPlayItem>)
  strict private
//    FTAGReaderThreadFactory: TPlayListThreadFactory;
    FOnPlayListSynchronized: TPlayListSynchronizedProcRef;
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
  strict private
//    FTotalSyncThreadCount: Integer;
//    FDoneSyncThreadCount: Integer;
//    FTotalSyncFileCount: Integer;
//    FDoneSyncFileCount: Integer;
    //procedure DoTAGReaderThreadTerminate(Sender: TObject);
//    procedure DoHeaderReadProgressQuant;
//    procedure DoProgressQuant;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    procedure FreeItem(const APlayItem: TPlayItem);
    function IndexOf(const APath: String): Integer;

    procedure ReloadPlayListFromPath(
      const APath: String);
    procedure ReloadPlayListByFileNames(
      const AFileNames: TFileNames);
    procedure ReloadPlayListFromDB(
      const AMainPath: String;
      const ADuplicateMode: Boolean);
    procedure BreakReloadPlayListByFileNames;

    procedure SyncPlayLists(
      const APath: String);
    procedure RestartSyncPlayList(const APath: String);

    procedure SaveToDB;

    property OnPlayListSynchronized: TPlayListSynchronizedProcRef
      read FOnPlayListSynchronized write FOnPlayListSynchronized;

//    property TAGReaderThreadFactory: TPlayListThreadFactory
//      read FTAGReaderThreadFactory write FTAGReaderThreadFactory;

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

  TPlayListSyncManager = class
  strict private
    class var
      FTAGReaderThreadFactory: TPlayListThreadFactory;
      FLock: TObject;
      FTotalSyncThreadCount: Integer;
      FDoneSyncThreadCount: Integer;
      FTotalSyncFileCount: Integer;
      FDoneSyncFileCount: Integer;
  public
    class procedure Init;
    class procedure UnInit;

    class procedure DoHeaderReadProgressQuant; static;
    class procedure DoDurationCalculateProgressQuant; static;

    class property TAGReaderThreadFactory: TPlayListThreadFactory
      read FTAGReaderThreadFactory write FTAGReaderThreadFactory;
    class property TotalSyncThreadCount: Integer
      read FTotalSyncThreadCount write FTotalSyncThreadCount;
    class property DoneSyncThreadCount: Integer
      read FDoneSyncThreadCount write FDoneSyncThreadCount;
    class property TotalSyncFileCount: Integer
      read FTotalSyncFileCount write FTotalSyncFileCount;
    class property DoneSyncFileCount: Integer
      read FDoneSyncFileCount write FDoneSyncFileCount;
  end;

implementation

uses
    System.SysUtils
  , System.Math
  , System.SyncObjs
  , TAGReaderThreadUnit
  , ConstantsUnit
  , ToolsUnit
  , FMX.MessageBox
  , AddLogUnit
  , DebugUnit
  //asd debug
  , FMX.Dialogs
  //asd debug
  ;

{ TPlayList }

constructor TPlayList.Create;
begin
  inherited Create;

//  FTAGReaderThreadFactory := ATAGReaderThreadFactory;
  FOnPlayListSynchronized := nil;

  FCurrentIndex := 0;

//  FTotalSyncThreadCount := 0;
//  FDoneSyncThreadCount := 0;
//  FTotalSyncFileCount := 0;
//  FDoneSyncFileCount := 0;
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

function TPlayList.IndexOf(const APath: String): Integer;
var
  i: Integer;
begin
  Result := -1;

  i := Count;
  while i > 0 do
  begin
    Dec(i);

    if APath = Items[i].Path then
      Exit(i);
  end;
end;

procedure TPlayList.OnAllThreadsAreDestroyed(Sender: TObject);
begin
  TPlayListSyncManager.TAGReaderThreadFactory.IsSyncPlayListStarted := false;
  TPlayListSyncManager.TAGReaderThreadFactory.IsSyncPlayListReStarted := false;
  if TPlayListSyncManager.TAGReaderThreadFactory.IsSyncPlayListReStarted then
  begin
    SyncPlayLists(TPlayListSyncManager.TAGReaderThreadFactory.Path);
  end
  else
  begin
    if Assigned(FOnPlayListSynchronized) then
    begin
      FOnPlayListSynchronized;
    end;
  end;
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

//procedure TPlayList.DoTAGReaderThreadTerminate(Sender: TObject);
//var
//  Percent: Integer;
//  Msg: String;
//begin
//  TDebug.ODS('TAGReaderThread terminated');
//  TMonitor.Enter(Self);
//  try
//    Inc(FDoneSyncThreadCount);
//
//    Percent := Round((100 * FDoneSyncThreadCount) / FTotalSyncThreadCount);
//    Msg := 'File catalog being compiled' + #10 + Percent.ToString + '% complete';
//    TTools.ChangeMessageForPleaseWaitMessageBox(Msg);
//  finally
//    TMonitor.Exit(Self);
//  end;
//end;

//procedure TPlayList.DoHeaderReadProgressQuant;
//var
//  Percent: Integer;
//  Msg: String;
//begin
//  TMonitor.Enter(Self);
//  try
//    Inc(FDoneSyncFileCount, 1);
//
//    Percent := Round((100 * FDoneSyncFileCount) / FTotalSyncFileCount);
//
//    Msg := 'Reading headers' + #10 + Percent.ToString + '% complete';
//    TTools.ChangeMessageForPleaseWaitMessageBox(Msg);
//
//    if FDoneSyncFileCount >= FTotalSyncFileCount then
//    begin
//      FDoneSyncFileCount := 0;
//
//      TPlayListSyncManager.TAGReaderThreadFactory.EnumerateThreads(
//        procedure (const AThread: TThreadExt; var ABreak: Boolean)
//        begin
//          AThread.UnHoldThread;
//        end);
//    end;
//  finally
//    TMonitor.Exit(Self);
//  end;
//end;

//procedure TPlayList.DoProgressQuant;
//var
//  Percent: Integer;
//  Msg: String;
//begin
//  TMonitor.Enter(Self);
//  try
//    Inc(FDoneSyncFileCount, 1);
//
//    Percent := Round((100 * FDoneSyncFileCount) / FTotalSyncFileCount);
//    Msg := 'Calculation of duration' + #10 + Percent.ToString + '% complete';
//    TTools.ChangeMessageForPleaseWaitMessageBox(Msg);
//  finally
//    TMonitor.Exit(Self);
//  end;
//end;

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
  TAGReaderThread: TTAGReaderThread;
  ThreadList: TList<TTAGReaderThread>;
//  DoneEvent: TEvent;
begin
  TPlayListSyncManager.TAGReaderThreadFactory.IsNeedToSaveToDB := true;

  Clear;

  FCurrentIndex := 0;

  // Создаём потоки
  FileCount := Length(FileNames);
  TPlayListSyncManager.TotalSyncFileCount := FileCount;
  TPlayListSyncManager.DoneSyncFileCount := 0;
  if FileCount > 10 then
  begin
    FilesPerThread := Ceil(FileCount / PLAY_LIST_RELOAD_THREAD_COUNT);
//    FTotalSyncThreadCount := Ceil(FileCount / FilesPerThread);
    ThreadList := TList<TTAGReaderThread>.Create;
//    DoneEvent := TEvent.Create(nil, true, false, '');
    try
      i := 0;
      while true do
      begin
        StartIndex := i * FilesPerThread;
        FinishIndex := Min(StartIndex + FilesPerThread - 1 , FileCount - 1);
        if StartIndex >= FileCount then
          Break;

        TAGReaderThread := TTAGReaderThread.Create(
          TPlayListSyncManager.TAGReaderThreadFactory,
          Self,
          FileNames,
          StartIndex,
          FinishIndex);
//        TAGReaderThread.OnTerminate := DoTAGReaderThreadTerminate;
        TAGReaderThread.OnHeaderRedProgressQuantProcRef :=
          TPlayListSyncManager.DoHeaderReadProgressQuant;
        TAGReaderThread.OnProgressQuantProcRef :=
          TPlayListSyncManager.DoDurationCalculateProgressQuant;

        ThreadList.Add(TAGReaderThread);

        Inc(i);
      end;

//      DoneEvent.ResetEvent;
      for TAGReaderThread in ThreadList do
      begin
        Sleep(1000);

        TAGReaderThread.Start;
      end;
    finally
//      FreeAndNil(DoneEvent);
      FreeAndNil(ThreadList);
    end;
  end
  else
  begin
    TPlayListSyncManager.TotalSyncThreadCount := 1;

    TAGReaderThread := TTAGReaderThread.Create(
      TPlayListSyncManager.TAGReaderThreadFactory,
      Self,
      FileNames,
      0,
      Pred(FileCount));
      //TAGReaderThread.OnTerminate := DoTAGReaderThreadTerminate;
      TAGReaderThread.OnHeaderRedProgressQuantProcRef :=
        TPlayListSyncManager.DoHeaderReadProgressQuant;
      TAGReaderThread.OnProgressQuantProcRef :=
        TPlayListSyncManager.DoDurationCalculateProgressQuant;

    TAGReaderThread.Start;
  end;

  TPlayListSyncManager.DoneSyncThreadCount := 0;
  TPlayListSyncManager.TAGReaderThreadFactory.OnAllThreadsAreDestroyed :=
    OnAllThreadsAreDestroyed;
end;

procedure TPlayList.ReloadPlayListFromDB(
  const AMainPath: String;
  const ADuplicateMode: Boolean);
var
  PlayItemsList: TPlayItemsList;
begin
  Clear;

  PlayItemsList := LockList;
  try
    TTools.SelectPlayItemsListFromDB(AMainPath, PlayItemsList, ADuplicateMode);
  finally
    UnlockList;
  end;
end;

procedure TPlayList.BreakReloadPlayListByFileNames;
begin
  TPlayListSyncManager.TAGReaderThreadFactory.IsNeedToSaveToDB := false;
  TPlayListSyncManager.TAGReaderThreadFactory.TerminateAllThreads;
end;

procedure TPlayList.SyncPlayLists(
  const APath: String);
begin
  TPlayListSyncManager.TAGReaderThreadFactory.IsNeedToSaveToDB := false;
  TPlayListSyncManager.TAGReaderThreadFactory.Path := APath;
  if TPlayListSyncManager.TAGReaderThreadFactory.IsSyncPlayListStarted then
  begin
    TPlayListSyncManager.TAGReaderThreadFactory.IsSyncPlayListReStarted := true;
    BreakReloadPlayListByFileNames;

    Exit;
  end;

  TPlayListSyncManager.TAGReaderThreadFactory.IsSyncPlayListStarted := true;

  TTools.HidePleaseWaitMessageBox;

  RestartSyncPlayList(APath);
end;

procedure TPlayList.RestartSyncPlayList(const APath: String);
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
  MessageBoxForm: TMessageBoxForm;
begin
  Path := APath;

  DBPlayItemsList := TPlayItemsList.Create;
  PathPlayItemsList := TPlayItemsList.Create;
  try
    TTools.SelectPlayItemsListFromDB(Path, DBPlayItemsList, false);

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
    begin
      MessageBoxForm := TTools.ShowPleaseWaitMessageBox;
      MessageBoxForm.OnFirstTimePaintProcRef :=
        procedure
        begin
          ReloadPlayListByFileNames(ToAddFileNames);
        end;
    end
    else
    if Assigned(FOnPlayListSynchronized) then
    begin
      FOnPlayListSynchronized;
      TPlayListSyncManager.TAGReaderThreadFactory.IsSyncPlayListStarted := false;
      TPlayListSyncManager.TAGReaderThreadFactory.IsSyncPlayListReStarted := false;
    end;
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

{ TPlayListSyncManager }

class procedure TPlayListSyncManager.Init;
begin
  FTAGReaderThreadFactory := TPlayListThreadFactory.Create;

  FLock := TObject.Create;      // объект для TMonitor

  FTotalSyncThreadCount := 0;
  FDoneSyncThreadCount := 0;
  FTotalSyncFileCount := 0;
  FDoneSyncFileCount := 0;
end;

class procedure TPlayListSyncManager.UnInit;
begin
  FreeAndNil(FLock);
  FreeAndNil(FTAGReaderThreadFactory);
end;

class procedure TPlayListSyncManager.DoHeaderReadProgressQuant;
var
  Percent: Integer;
  Msg: String;
begin
  TMonitor.Enter(FLock);
  try
    Inc(FDoneSyncFileCount, 1);

    Percent := Round((100 * FDoneSyncFileCount) / FTotalSyncFileCount);

    Msg := 'Reading headers' + #10 + Percent.ToString + '% complete';
    TTools.ChangeMessageForPleaseWaitMessageBox(Msg);

    if FDoneSyncFileCount >= FTotalSyncFileCount then
    begin
      FDoneSyncFileCount := 0;

      FTAGReaderThreadFactory.EnumerateThreads(
        procedure (const AThread: TThreadExt; var ABreak: Boolean)
        begin
          AThread.UnHoldThread;
        end);
    end;
  finally
    TMonitor.Exit(FLock);
  end;
end;

class procedure TPlayListSyncManager.DoDurationCalculateProgressQuant;
var
  Percent: Integer;
  Msg: String;
begin
  TMonitor.Enter(FLock);
  try
    Inc(FDoneSyncFileCount, 1);

    Percent := Round((100 * FDoneSyncFileCount) / FTotalSyncFileCount);
    Msg := 'Calculation of duration' + #10 + Percent.ToString + '% complete';
    TTools.ChangeMessageForPleaseWaitMessageBox(Msg);
  finally
    TMonitor.Exit(FLock);
  end;
end;

initialization
  TPlayListSyncManager.Init;

finalization
  TPlayListSyncManager.UnInit;

end.

