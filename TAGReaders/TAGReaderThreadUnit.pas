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
    MD5: String;
    SHA256: String;
    FileSize: Int64;
//  public
//    procedure Clear;
  end;

  TTAGInfoList = TList<TTAGInfo>;

  TTAGReaderThread = class(TThreadExt)
  strict private
    FFileNames: TFileNames;
    FPlayList: TPlayList;
  protected
    procedure InnerExecute; override;
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
    'TTAGReaderThread');
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
  PlayItem: TPlayItem;
  AudioFormat: TAudioFormat;
  MediaPlayer: TMedia;
  MD5: String;
  SHA256: String;
  FileSize: Int64;
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
          raise Exception.
            CreateFmt('Unprocessable file format "%s"', [AudioFormat.ToStr]);
        end;
      end;

      Inc(i);
    end;

    PlayItemsList := FPlayList.LockList;
    try
      i := 0;
      while (i < TAGInfoList.Count) and not Terminated do
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
        //MediaPlayer := TMedia.Create(PlayItem.Path);
        { TODO : Избавиться от Synchronize, перейти на TEvent }
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

        PlayItemsList.Add(PlayItem);

        Inc(i);
      end;
    finally
      FPlayList.UnLockList;
    end;
  finally
    FreeAndNil(TAGInfoList);
  end;
end;

end.
