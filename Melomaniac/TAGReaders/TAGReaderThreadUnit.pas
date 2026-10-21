{.$DEFINE MOVE_TO_TRASH}
unit TAGReaderThreadUnit;

interface

uses
    System.Classes
  , System.SyncObjs
  , System.SysUtils
  , System.Generics.Collections
  , ThreadFactoryUnit
  , PlayListUnit
  , FileToolsUnit
  , FMX.Media
  ;

type
  TTAGInfo = record
    Title: String;
    Artist: String;
    Album: String;
    Year: String;
    Comment: String;
    Genre: String;
    FileName: String;
    MD5: String;
    SHA256: String;
    FileSize: Int64;
  end;

  TTAGInfoList = TList<TTAGInfo>;

  TTAGReaderThread = class(TThreadExt)
  strict private
    FDone: TEvent;
    FFileNames: TFileNames;
    FPlayList: TPlayList;
    FCodacInitiator: TMedia;
    FMediaPlayer: TMedia;
    FOnThreadIsDone: TNotifyEvent;
    FOnHeaderRedProgressQuantProcRef: TProc;
    FOnProgressQuantProcRef: TProc;
    FLock: TObject;
  strict private
    procedure WriteTinyWav(const AFileName: string);
    procedure WarmUpMediaCodec;   // вызвать один раз в главном потоке

    function GetDurationBySync(const APath: String): Int64;
  protected
    procedure InnerExecute; override;
  public
    constructor Create(
      const AThreadFactory: TThreadFactory;
      const APlayList: TPlayList;
      const AFileNames: TFileNames;
      const AStartIndex: Integer;
      const AFinishIndex: Integer); reintroduce;
    destructor Destroy; override;

    procedure InitCodec;

    property OnHeaderRedProgressQuantProcRef: TProc
      read FOnHeaderRedProgressQuantProcRef write FOnHeaderRedProgressQuantProcRef;
    property OnProgressQuantProcRef: TProc
      read FOnProgressQuantProcRef write FOnProgressQuantProcRef;
  end;

implementation

uses
    System.UITypes
  , System.IOUtils
  , AudioFormatDetectorUnit
  , MP3TAGsReaderUnit
  , FlacTAGReaderUnit
  , OGGTAGReaderUnit
  , WavTAGReaderUnit
  , FMX.MessageBox
  , CommonTypesUnit
  , ToolsUnit
  , AddLogUnit
  , DebugUnit
  ;

//{ TTAGInfo }
//
//procedure TTAGInfo.Clear;
//begin
//  Title := '';
//  Artist := '';
//  Album := '';
//  Year := '';
//  Comment := '';
//  Genre := '';
//  FileName := '';
//  MD5 := '';
//  SHA256 := '';
//  FileSize := 0;
//end;

{ TTAGReaderThread }

procedure TTAGReaderThread.WriteTinyWav(const AFileName: string);
const
  Rate = 8000; Samples = 800;   // 0.1 с тишины, 8 бит, моно
var
  FS: TFileStream;
  DataSize, RiffSize: Cardinal;
  Fmt: Cardinal;
  W: Word;
  D: Cardinal;
  B: Byte;
  I: Integer;
begin
  FS := TFileStream.Create(AFileName, fmCreate);
  try
    DataSize := Samples;
    RiffSize := 36 + DataSize;
    FS.WriteBuffer(AnsiString('RIFF')[1], 4);
    FS.WriteBuffer(RiffSize, 4);
    FS.WriteBuffer(AnsiString('WAVEfmt ')[1], 8);
    Fmt := 16;     FS.WriteBuffer(Fmt, 4);
    W := 1;        FS.WriteBuffer(W, 2);    // PCM
    W := 1;        FS.WriteBuffer(W, 2);    // каналы
    D := Rate;     FS.WriteBuffer(D, 4);
    D := Rate;     FS.WriteBuffer(D, 4);    // byte rate
    W := 1;        FS.WriteBuffer(W, 2);    // block align
    W := 8;        FS.WriteBuffer(W, 2);    // bits
    FS.WriteBuffer(AnsiString('data')[1], 4);
    FS.WriteBuffer(DataSize, 4);
    B := $80;
    for I := 1 to Samples do FS.WriteBuffer(B, 1);
  finally
    FS.Free;
  end;
end;

procedure TTAGReaderThread.WarmUpMediaCodec;   // вызвать один раз в главном потоке
var
  Tmp: string;
begin
  Tmp := TPath.Combine(TPath.GetTempPath, 'warmup_codec.wav');
  WriteTinyWav(Tmp);
  try
    FMediaPlayer := TMediaCodecManager.CreateFromFile(Tmp);

    FreeAndNil(FMediaPlayer);
  finally
    TFile.Delete(Tmp);
  end;
end;

procedure TTAGReaderThread.InitCodec;
begin
  WarmUpMediaCodec;
end;

constructor TTAGReaderThread.Create(
  const AThreadFactory: TThreadFactory;
  const APlayList: TPlayList;
  const AFileNames: TFileNames;
  const AStartIndex: Integer;
  const AFinishIndex: Integer);
var
  Tmp: string;
begin
  FLock := TObject.Create;

  FOnHeaderRedProgressQuantProcRef := nil;
  FOnProgressQuantProcRef := nil;

  Tmp := TPath.Combine(TPath.GetTempPath, 'warmup_codec.wav');
  WriteTinyWav(Tmp);
  try
    Synchronize(
      procedure
      begin
        FCodacInitiator := TMediaCodecManager.CreateFromFile(Tmp);
      end);
  finally
    TFile.Delete(Tmp);
  end;

  FDone := TEvent.Create(nil, true, false, '');

  FPlayList := APlayList;
  FFileNames.CopyRangeFrom(AFileNames, AStartIndex, AFinishIndex);

  inherited Create(
    AThreadFactory,
    '',
    true);

  OnAfterTerminatedSetProcRef :=
    procedure
    begin
      FDone.SetEvent;
    end;
end;

destructor TTAGReaderThread.Destroy;
begin
  FreeAndNil(FDone);
  Synchronize(
    procedure
    begin
      FreeAndNil(FCodacInitiator);
    end);

  FreeAndNil(FLock);

  inherited;
end;

function TTAGReaderThread.GetDurationBySync(const APath: String): Int64;
var
  Duration: Int64;
begin
  FDone.ResetEvent;

  Queue(nil,
    procedure
    begin
      FMediaPlayer := TMediaCodecManager.CreateFromFile(APath);
      try
        try
          Duration := FMediaPlayer.Duration;
        except
          on e: Exception do
            Duration := -1;
        end;
      finally
        FMediaPlayer.Free;
      end;

      FDone.SetEvent;
    end);

  FDone.WaitFor(INFINITE);

  Result := Duration;
end;

procedure TTAGReaderThread.InnerExecute;
var
  TAGInfo: TTAGInfo;
  TAGInfoList: TTAGInfoList;
  MP3Info: TMP3Info;
  OGGInfo: TOGGInfo;
  FlacInfo: TFlacInfo;
  WAVInfo: TWAVInfo;
  FileName: String;
  i: Integer;
  PlayItemsList: TPlayItemsList;
  DestPlayItemsList: TPlayItemsList;
  PlayItem: TPlayItem;
  AudioFormat: TAudioFormat;
  Duration: Int64;
  MD5: String;
  SHA256: String;
  FileSize: Int64;
  WarningMessage: String;
begin
  TAGInfoList := TTAGInfoList.Create;
  HoldThread;
  try
    i := 0;
    while (not Terminated) and (i < Length(FFileNames)) do
    begin
      TAGInfo := Default(TTAGInfo);
      FileName := FFileNames[i];

      TFileTools.GetFileFootPrint(
        FileName,
        MD5{out},
        SHA256{out},
        FileSize{out});

      TAGInfo.FileName := FileName;
      TAGInfo.MD5 := MD5;
      TAGInfo.SHA256 := SHA256;
      TAGInfo.FileSize := FileSize;
      AudioFormat := DetectAudioFormat(FileName);
      case AudioFormat of
        TAudioFormat.afMP3:
        begin
          MP3Info := Default(TMP3Info);
          MP3Info := TMP3Reader.ReadMP3(FileName);
          TAGInfo.Title := MP3Info.Title;
          TAGInfo.Artist := MP3Info.Artist;
          TAGInfo.Album := MP3Info.Album;
          TAGInfo.Year := MP3Info.Year;
          TAGInfo.Comment := MP3Info.Comment;
          TAGInfo.Genre := MP3Info.Genre;
          TAGInfoList.Add(TAGInfo);
        end;
        TAudioFormat.afOGG:
        begin
          OGGInfo := Default(TOGGInfo);
          OGGInfo := TOGGReader.ReadOGG(FileName);
          TAGInfo.Title := OGGInfo.Title;
          TAGInfo.Artist := OGGInfo.Artist;
          TAGInfo.Album := OGGInfo.Album;
          TAGInfo.Year := OGGInfo.Year;
          TAGInfo.Comment := OGGInfo.Comment;
          TAGInfo.Genre := OGGInfo.Genre;
          TAGInfoList.Add(TAGInfo);
        end;
        TAudioFormat.afFLAC:
        begin
          FlacInfo := Default(TFlacInfo);
          FlacInfo := TFlacReader.ReadFLAC(FileName);
          TAGInfo.Title := FlacInfo.Title;
          TAGInfo.Artist := FlacInfo.Artist;
          TAGInfo.Album := FlacInfo.Album;
          TAGInfo.Year := FlacInfo.Year;
          TAGInfo.Comment := FlacInfo.Comment;
          TAGInfo.Genre := FlacInfo.Genre;
          TAGInfoList.Add(TAGInfo);
        end;
        TAudioFormat.afWAV:
        begin
          WAVInfo := Default(TWAVInfo);
          WAVInfo := TWAVReader.ReadWAV(FileName);
          TAGInfo.Title := WAVInfo.Title;
          TAGInfo.Artist := WAVInfo.Artist;
          TAGInfo.Album := WAVInfo.Album;
          TAGInfo.Year := WAVInfo.Year;
          TAGInfo.Comment := WAVInfo.Comment;
          TAGInfo.Genre := WAVInfo.Genre;
          TAGInfoList.Add(TAGInfo);
        end
        else
        begin
          WarningMessage :=
            Format('ERROR: Unprocessable file format "%s" in file "%s"',
              [AudioFormat.ToStr, FileName]);
          TLogger.AddLog(WarningMessage);
          Synchronize(
            procedure
            begin
              TMessageBox.ShowOkCancel(
                Format(
                  WarningMessage + #10#10 +
                  'Move "%s" file to "Trash" folder', [FileName]),
                  'Attention',
                procedure (const AModalResult: TModalResult)
                begin
                  if AModalResult = mrOk then
                    TTools.MoveToTrash(FileName);
                end);
            end);
//          {$IFDEF MOVE_TO_TRASH}
//          TFileTools.MoveFile(FileName, 'e:\TrashMP3\' + ExtractFileName(FileName), caRename);
//          {$ELSE}
//          TThread.Queue(nil,
//            procedure
//            begin
//              TMessageBox.Show(WarningMessage);
//            end);
//          {$ENDIF}
        end;
      end;

      Inc(i);

      TLogger.AddLog(Format('File "%s" TAG processed', [TAGInfo.FileName]), MG);

      if Assigned(FOnHeaderRedProgressQuantProcRef) then
        FOnHeaderRedProgressQuantProcRef;
    end;

    ExecHold;

    PlayItemsList := TPlayItemsList.Create;
    try
      i := 0;
      while (i < TAGInfoList.Count) and (not Terminated) do
      begin
        PlayItem := TPlayItem.Create;
        PlayItem.Title := TAGInfoList[i].Title;
        PlayItem.Artist := TAGInfoList[i].Artist;
        PlayItem.Album := TAGInfoList[i].Album;
        PlayItem.Year := TAGInfoList[i].Year;
        PlayItem.Path := TAGInfoList[i].FileName;
        PlayItem.MD5 := TAGInfoList[i].MD5;
        PlayItem.SHA256 := TAGInfoList[i].SHA256;
        PlayItem.FileSize := TAGInfoList[i].FileSize;

        TMonitor.Enter(FLock);
        try
          Duration := 0;
          try
//            TLogger.AddLog(Format('Start duration cacl to "%s"', [PlayItem.Path]));
            // Duration вычисляем через TMediaPlayer.Duration
            // Он поднимает нужный кодак и, тот высчитывает верный Duration
            // Считать в "ручную" - лепить химеру
            // TMediaCodecManager.CreateFromFile необходим монопольный вызов
            // По этому используем TMonitor
            try
              FMediaPlayer := TMediaCodecManager.CreateFromFile(PlayItem.Path);
            except
              on e: Exception do
              begin
                TLogger.AddLog(Format('Error: "%s". Try calc duration via sync mode to "%s"',
                  [e.Message, PlayItem.Path]), ER);
                Duration := GetDurationBySync(PlayItem.Path);
              end;
            end;
            Duration := FMediaPlayer.Duration;
//            TLogger.AddLog(Format('Finish duration cacl to "%s"', [PlayItem.Path]));
          finally
            if Duration > 0 then
            begin
              PlayItem.Duration := Duration;
              PlayItemsList.Add(PlayItem);
              TLogger.AddLog(Format('File "%s" duration processed', [PlayItem.Path]), MG);
            end;

            FreeAndNil(FMediaPlayer);
          end;
        finally
          TMonitor.Exit(FLock);
        end;

        Inc(i);

        if Assigned(FOnProgressQuantProcRef) then
        begin
          TThread.Queue(nil,
            procedure
            begin
              FOnProgressQuantProcRef;
            end);
        end;
      end;

      DestPlayItemsList := FPlayList.LockList;
      try
        DestPlayItemsList.AddRange(PlayItemsList);
      finally
        FPlayList.UnLockList;
      end;
    finally
      FreeAndNil(PlayItemsList);
    end;

  finally
    UnHoldThread;
    FreeAndNil(TAGInfoList);
  end;

  if Assigned(FOnThreadIsDone) then
    FOnThreadIsDone(nil);
end;

end.
