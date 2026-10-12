{$DEFINE MOVE_TO_TRASH}
unit TAGReaderThreadUnit;

interface

uses
    System.Classes
  , System.SyncObjs
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
//  public
//    procedure Clear;
  end;

  TTAGInfoList = TList<TTAGInfo>;

  TTAGReaderThread = class(TThreadExt)
  strict private
    FDone: TEvent;
    FFileNames: TFileNames;
    FPlayList: TPlayList;
    //asd debug
    FMediaPlayer: TMedia;
    //asd debug
    FOnThreadIsDone: TNotifyEvent;
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

    property OnThreadIsDone: TNotifyEvent
      write FOnThreadIsDone;
  end;

implementation

uses
    System.SysUtils
  , System.IOUtils
  , AudioFormatDetectorUnit
  , MP3TAGsReaderUnit
  , FlacTAGReaderUnit
  , OGGTAGReaderUnit
  , WavTAGReaderUnit
//  , FMX.Media
  , FMX.MessageBox
  , CommonTypesUnit
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
//  Codec: TMedia;
begin
//  Tmp := TPath.Combine(TPath.GetTempPath, 'warmup_codec.wav');
//  WriteTinyWav(Tmp);
//  try
//    Codec := TMediaCodecManager.CreateFromFile(Tmp);
//    //CreateFromFile('C:\000\phoebe_cates_paradise.mp3');
//
//    FreeAndNil(Codec);
//  finally
//    TFile.Delete(Tmp);
//  end;
  Tmp := TPath.Combine(TPath.GetTempPath, 'warmup_codec.wav');
  WriteTinyWav(Tmp);
  try
    FMediaPlayer := TMediaCodecManager.CreateFromFile(Tmp);
    //CreateFromFile('C:\000\phoebe_cates_paradise.mp3');

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
begin
//  FMediaPlayer := TMediaCodecManager.CreateFromFile('C:\000\phoebe_cates_paradise.mp3');
//  FreeAndNil(FMediaPlayer);
  InitCodec;

  FDone := TEvent.Create(nil, true, false, '');

  FPlayList := APlayList;
  FFileNames.CopyRangeFrom(AFileNames, AStartIndex, AFinishIndex);

  inherited Create(
    AThreadFactory,
    '');
//    'TTAGReaderThread');

  OnAfterTerminatedSetProcRef :=
    procedure
    begin
      FDone.SetEvent;
    end;
end;

destructor TTAGReaderThread.Destroy;
begin
  FreeAndNil(FDone);

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
  try
    i := 0;
    while (not Terminated) and (i < Length(FFileNames)) do
    begin
      TAGInfo := Default(TTAGInfo);
      FileName := FFileNames[i];

      TFileTools.GetFileFootPrint(
        FileName,
        MD5,
        SHA256,
        FileSize);

      TAGInfo.FileName := FileName;
      TAGInfo.MD5 := MD5;
      TAGInfo.SHA256 := SHA256;
      TAGInfo.FileSize := FileSize;
      //asd debug здесь смотрим падение на 'E:\Hide\Music\Universe\Music for relax\Collection\pit-bull--krasivyy-zhenskiy-vokal.mp3'
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
//          TAGInfo.FileName := FileName;
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
//          TAGInfo.FileName := FileName;
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
//          TAGInfo.FileName := FileName;
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
//          TAGInfo.FileName := FileName;
          TAGInfoList.Add(TAGInfo);
        end
        else
        begin
          WarningMessage :=
            Format('ERROR: Unprocessable file format "%s" in file "%s"',
              [AudioFormat.ToStr, FileName]);
          TLogger.AddLog(WarningMessage);
          {$IFDEF MOVE_TO_TRASH}
          TFileTools.MoveFile(FileName, 'e:\TrashMP3\' + ExtractFileName(FileName), caRename);
          {$ELSE}
          TThread.Queue(nil,
            procedure
            begin
              TMessageBox.Show(WarningMessage);
            end);
          {$ENDIF}
        end;
      end;

      Inc(i);

      TLogger.AddLog(Format('File "%s" TAG processed', [TAGInfo.FileName]), MG);
    end;

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

        // Duration вычисляем через TMediaPlayer.Duration
        // Он поднимает нужный кодак и, тот высчитывает верный Duration
        // Считать в "ручную" - лепить химеру
        // MediaPlayer := TMedia.Create(PlayItem.Path);

        FMediaPlayer := TMediaCodecManager.CreateFromFile(PlayItem.Path);
        try
          try
            Duration := FMediaPlayer.Duration;
          except
            Duration := GetDurationBySync(PlayItem.Path);
            if Duration < 0 then
              TLogger.AddLog(Format('Unsupported file "%s"', [PlayItem.Path]), ER);
          end;
        finally
          FMediaPlayer.Free;
        end;

        if Duration > 0 then
        begin
          PlayItem.Duration := Duration;
          PlayItemsList.Add(PlayItem);
          TLogger.AddLog(Format('File "%s" duration processed', [PlayItem.Path]), MG);
        end;

        Inc(i);
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
    FreeAndNil(TAGInfoList);
  end;

  if Assigned(FOnThreadIsDone) then
    FOnThreadIsDone(nil);

  TDebug.ODS('Thread is done');
end;

//initialization
//  TTAGReaderThread.Init;

end.
