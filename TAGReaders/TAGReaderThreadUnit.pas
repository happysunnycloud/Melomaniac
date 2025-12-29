unit TAGReaderThreadUnit;

interface

uses
    System.Classes
  , System.Generics.Collections
  , ThreadFactoryUnit
  , PlayListUnit
  , FileToolsUnit
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
  end;

  TTAGInfoList = TList<TTAGInfo>;

  TTAGReaderThread = class(TThreadExt)
  strict private
    FFileNames: TFileNames;
    FPlayList: TPlayList;
  protected
    procedure Execute(const AThread: TThreadExt); reintroduce; // override;
  public
    constructor Create(
      const AThreadFactory: TThreadFactory;
      const APlayList: TPlayList;
      const AFileNames: TFileNames;
      const AStartIndex: Integer;
      const AFinishIndex: Integer); reintroduce;
  end;

implementation

uses
    System.SysUtils
  , AudioFormatDetectorUnit
  , MP3TAGsReaderUnit
  , FlacTAGReaderUnit
  , OGGTAGReaderUnit
  , WavTAGReaderUnit
  , FMX.Media
  ;

{ TTAGReaderThread }

constructor TTAGReaderThread.Create(
  const AThreadFactory: TThreadFactory;
  const APlayList: TPlayList;
  const AFileNames: TFileNames;
  const AStartIndex: Integer;
  const AFinishIndex: Integer);
begin
  FPlayList := APlayList;
  FFileNames.CopyRangeFrom(AFileNames, AStartIndex, AFinishIndex);

  inherited Create(
    AThreadFactory,
    'TTAGReaderThread',
    Execute);
end;

procedure TTAGReaderThread.Execute;
var
  MP3Info: TMP3Info;
  OGGInfo: TOGGInfo;
  FlacInfo: TFlacInfo;
  WAVInfo: TWAVInfo;
  TAGInfo: TTAGInfo;
  TAGInfoList: TTAGInfoList;
  FileName: String;
  i: Integer;
  PlayItemsList: TPlayItemsList;
  PlayItem: TPlayItem;
  AudioFormat: TAudioFormat;
  MediaPlayer: TMedia;
begin
  TAGInfoList := TTAGInfoList.Create;
  try
    i := 0;
    while (not Terminated) and (i < Length(FFileNames)) do
    begin
      FileName := FFileNames[i];
      AudioFormat := DetectAudioFormat(FileName);
      case AudioFormat of
        TAudioFormat.afMP3:
        begin
          MP3Info := TMP3Reader.ReadMP3(FileName);
          TAGInfo.Title := MP3Info.Title;
          TAGInfo.Artist := MP3Info.Artist;
          TAGInfo.Album := MP3Info.Album;
          TAGInfo.Year := MP3Info.Year;
          TAGInfo.Comment := MP3Info.Comment;
          TAGInfo.Genre := MP3Info.Genre;
          TAGInfo.FileName := FileName;
          TAGInfoList.Add(TAGInfo);
        end;
        TAudioFormat.afOGG:
        begin
          OGGInfo := TOGGReader.ReadOGG(FileName);
          TAGInfo.Title := OGGInfo.Title;
          TAGInfo.Artist := OGGInfo.Artist;
          TAGInfo.Album := OGGInfo.Album;
          TAGInfo.Year := OGGInfo.Year;
          TAGInfo.Comment := OGGInfo.Comment;
          TAGInfo.Genre := OGGInfo.Genre;
          TAGInfo.FileName := FileName;
          TAGInfoList.Add(TAGInfo);
        end;
        TAudioFormat.afFLAC:
        begin
          FlacInfo := TFlacReader.ReadFLAC(FileName);
          TAGInfo.Title := FlacInfo.Title;
          TAGInfo.Artist := FlacInfo.Artist;
          TAGInfo.Album := FlacInfo.Album;
          TAGInfo.Year := FlacInfo.Year;
          TAGInfo.Comment := FlacInfo.Comment;
          TAGInfo.Genre := FlacInfo.Genre;
          TAGInfo.FileName := FileName;
          TAGInfoList.Add(TAGInfo);
        end;
        TAudioFormat.afWAV:
        begin
          WAVInfo := TWAVReader.ReadWAV(FileName);
          TAGInfo.Title := WAVInfo.Title;
          TAGInfo.Artist := WAVInfo.Artist;
          TAGInfo.Album := WAVInfo.Album;
          TAGInfo.Year := WAVInfo.Year;
          TAGInfo.Comment := WAVInfo.Comment;
          TAGInfo.Genre := WAVInfo.Genre;
          TAGInfo.FileName := FileName;
          TAGInfoList.Add(TAGInfo);
        end
        else
        begin
          raise Exception.
            CreateFmt('Unprocessable file format "%s"', [AudioFormat.ToStr]);
        end;
      end;

      Inc(i);
    end;

    if not Terminated then
    begin
      PlayItemsList := FPlayList.LockList;
      try
        i := 0;
        while i < TAGInfoList.Count do
        begin
          PlayItem := TPlayItem.Create;
          PlayItem.Title := TAGInfoList[i].Title;
          PlayItem.Artist := TAGInfoList[i].Artist;
          PlayItem.Album := TAGInfoList[i].Album;
          PlayItem.Year := TAGInfoList[i].Year;
          PlayItem.Path := TAGInfoList[i].FileName;
          // Duration вычисляем через TMediaPlayer.Duration
          // Он поднимает нужный кодак и, тот высчитывает верный Duration
          // Считать в "ручную" - лепить химеру
          //MediaPlayer := TMedia.Create(PlayItem.Path);
          Synchronize(
            procedure
            begin
              MediaPlayer := TMediaCodecManager.CreateFromFile(PlayItem.Path);
              try
                PlayItem.Duration := MediaPlayer.Duration;
              finally
                MediaPlayer.Free;
              end;
            end);

//          Synchronize(
//            procedure
//            begin
//              MediaPlayer.Clear;
//              MediaPlayer.FileName := PlayItem.Path;
//              PlayItem.Duration := MediaPlayer.Duration;
//            end);

          PlayItemsList.Add(PlayItem);

          Inc(i);
        end;
      finally
        FPlayList.UnLockList;
      end;
    end;
  finally
    FreeAndNil(TAGInfoList);
//    FreeAndNil(MediaPlayer);
  end;
end;

end.
