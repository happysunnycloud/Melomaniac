unit TAGReaderThreadUnit;

interface

uses
    System.Classes
  , ThreadFactoryUnit
  , PlayListUnit
  , FileToolsUnit
  ;

type
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
  , System.Generics.Collections
  , MP3TAGsReaderUnit
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
  MP3InfoList: TList<TMP3Info>;
  FileName: String;
  i: Integer;
  PlayItemsList: TPlayItemsList;
  PlayItem: TPlayItem;
begin
  MP3InfoList := TList<TMP3Info>.Create;
  try
    i := 0;
    while (not Terminated) and (i < Length(FFileNames)) do
    begin
      FileName := FFileNames[i];
      if TMP3Reader.IsMP3Strict(FileName) then
      begin
        MP3Info := TMP3Reader.ReadMP3(FileName);
        MP3InfoList.Add(MP3Info);
      end;

      Inc(i);
    end;

    if not Terminated then
    begin
      PlayItemsList := FPlayList.LockList;
      try
        i := 0;
        while i < MP3InfoList.Count do
        begin
          PlayItem := TPlayItem.Create;
          PlayItem.Title := MP3InfoList[i].Title;
          PlayItem.Artist := MP3InfoList[i].Artist;
          PlayItem.Album := MP3InfoList[i].Album;
          PlayItem.Year := MP3InfoList[i].Year;
          PlayItem.Duration := MP3InfoList[i].Duration;
          PlayItem.Path := MP3InfoList[i].FileName;

          PlayItemsList.Add(PlayItem);

          Inc(i);
        end;
      finally
        FPlayList.UnLockList;
      end;
    end;
  finally
    FreeAndNil(MP3InfoList);
  end;
end;

end.
