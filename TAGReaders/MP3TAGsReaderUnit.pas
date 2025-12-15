unit MP3TAGsReaderUnit;

interface

uses
  System.SysUtils, System.Classes;

type
  TMP3Info = record
    Title: String;
    Artist: String;
    Album: String;
    Year: String;
    Comment: String;
    Genre: String;
  end;

  TMP3Reader = class
  public
    class function ReadMP3(const FileName: string): TMP3Info;
  end;

implementation

const
  MPEG1_L3_BitRates: array[1..14] of Integer = (32,40,48,56,64,80,96,112,128,160,192,224,256,320);
  MPEG2_L3_BitRates: array[1..14] of Integer = (8,16,24,32,40,48,56,64,80,96,112,128,144,160);
  MPEG1_SampleRates: array[0..2] of Integer = (44100,48000,32000);
  MPEG2_SampleRates: array[0..2] of Integer = (22050,24000,16000);

  ID3v1Genres: array[0..125] of string = (
    'Blues','Classic Rock','Country','Dance','Disco','Funk','Grunge','Hip-Hop',
    'Jazz','Metal','New Age','Oldies','Other','Pop','R&B','Rap','Reggae','Rock',
    'Techno','Industrial','Alternative','Ska','Death Metal','Pranks','Soundtrack',
    'Euro-Techno','Ambient','Trip-Hop','Vocal','Jazz+Funk','Fusion','Trance','Classical',
    'Instrumental','Acid','House','Game','Sound Clip','Gospel','Noise','AlternRock',
    'Bass','Soul','Punk','Space','Meditative','Instrumental Pop','Instrumental Rock',
    'Ethnic','Gothic','Darkwave','Techno-Industrial','Electronic','Pop-Folk','Eurodance',
    'Dream','Southern Rock','Comedy','Cult','Gangsta','Top 40','Christian Rap','Pop/Funk',
    'Jungle','Native American','Cabaret','New Wave','Psychadelic','Rave','Showtunes','Trailer',
    'Lo-Fi','Tribal','Acid Punk','Acid Jazz','Polka','Retro','Musical','Rock & Roll',
    'Hard Rock','Folk','Folk-Rock','National Folk','Swing','Fast Fusion','Bebob','Latin',
    'Revival','Celtic','Bluegrass','Avantgarde','Gothic Rock','Progressive Rock','Psychedelic Rock',
    'Symphonic Rock','Slow Rock','Big Band','Chorus','Easy Listening','Acoustic','Humour','Speech',
    'Chanson','Opera','Chamber Music','Sonata','Symphony','Booty Bass','Primus','Porn Groove','Satire',
    'Slow Jam','Club','Tango','Samba','Folklore','Ballad','Power Ballad','Rhythmic Soul','Freestyle',
    'Duet','Punk Rock','Drum Solo','Acapella','Euro-House','Dance Hall'
  );

{-------------------- Вспомогательные функции --------------------}

// Преобразуем 4 синкфэйв-байта в Integer (ID3v2 size)
function SyncSafeToInt(const Bytes: TBytes): Integer;
begin
  if Length(Bytes) <> 4 then Exit(0);
  Result := (Bytes[0] shl 21) or (Bytes[1] shl 14) or (Bytes[2] shl 7) or Bytes[3];
end;

// Декодируем текст из фрейма с учётом кодировки
function DecodeText(const FrameData: TBytes): string;
var
  Encoding: Byte;
  TextBytes: TBytes;
begin
  Result := '';
  if Length(FrameData) = 0 then Exit;
  Encoding := FrameData[0];
  SetLength(TextBytes, Length(FrameData)-1);
  if Length(TextBytes) > 0 then
    Move(FrameData[1], TextBytes[0], Length(TextBytes));
  case Encoding of
    0: Result := TEncoding.ANSI.GetString(TextBytes);            // Latin1
    1: Result := TEncoding.Unicode.GetString(TextBytes);         // UTF-16 with BOM
    2: Result := TEncoding.BigEndianUnicode.GetString(TextBytes);// UTF-16BE
    3: Result := TEncoding.UTF8.GetString(TextBytes);            // UTF-8
  else
    Result := TEncoding.ANSI.GetString(TextBytes);
  end;
  Result := Trim(Result);
end;

{-------------------- ID3v1 --------------------}

procedure ReadID3v1(Stream: TFileStream; var Info: TMP3Info);
var
  Tag: array[0..127] of Byte;
  Buffer: TBytes;
  GenreIndex: Integer;
begin
  if Stream.Size < 128 then Exit;
  Stream.Position := Stream.Size - 128;
  if Stream.Read(Tag, 128) <> 128 then Exit;

  if (Tag[0] = Ord('T')) and (Tag[1] = Ord('A')) and (Tag[2] = Ord('G')) then
  begin
    SetLength(Buffer, 30);
    Move(Tag[3], Buffer[0], 30);
    Info.Title := Trim(TEncoding.ANSI.GetString(Buffer));

    Move(Tag[33], Buffer[0], 30);
    Info.Artist := Trim(TEncoding.ANSI.GetString(Buffer));

    Move(Tag[63], Buffer[0], 30);
    Info.Album := Trim(TEncoding.ANSI.GetString(Buffer));

    SetLength(Buffer, 4);
    Move(Tag[93], Buffer[0], 4);
    Info.Year := Trim(TEncoding.ANSI.GetString(Buffer));

    SetLength(Buffer, 30);
    Move(Tag[97], Buffer[0], 30);
    Info.Comment := Trim(TEncoding.ANSI.GetString(Buffer));

    GenreIndex := Tag[127];
    if (GenreIndex >= Low(ID3v1Genres)) and (GenreIndex <= High(ID3v1Genres)) then
      Info.Genre := ID3v1Genres[GenreIndex]
    else
      Info.Genre := 'Unknown';
  end;
end;

{-------------------- ID3v2 --------------------}

procedure ReadID3v2(Stream: TFileStream; var Info: TMP3Info);
var
  Header: array[0..9] of Byte;
  Version: Byte;
  Flags: Byte;
  Size: Integer;
  Data: TBytes;
  Pos: Integer;
  FrameID: string;
  FrameSize: Integer;
  FrameData: TBytes;
  Buffer: TBytes;
  ExtendedHeaderSize: Integer;
begin
  Stream.Position := 0;

  if Stream.Read(Header, 10) <> 10 then Exit;
  if not ((Header[0] = Ord('I')) and (Header[1] = Ord('D')) and (Header[2] = Ord('3'))) then Exit;

  Version := Header[3];
  Flags := Header[5];
  SetLength(Buffer, 4);
  Move(Header[6], Buffer[0], 4);
  Size := SyncSafeToInt(Buffer);
  // Проверка Extended Header
  ExtendedHeaderSize := 0;
  if (Flags and $40) <> 0 then // Extended header present
  begin
    Stream.Position := 10;
    if Stream.Read(Buffer, 4) = 4 then
      ExtendedHeaderSize := SyncSafeToInt(Buffer);
  end;

  SetLength(Data, Size);
  Stream.Position := 10 + ExtendedHeaderSize;
  if Stream.Read(Data[0], Size - ExtendedHeaderSize) <> Size - ExtendedHeaderSize then Exit;
  Pos := 0;
  while Pos < Length(Data) do
  begin
    if Version = 2 then
    begin
      if Pos + 6 > Length(Data) then Break;
      SetLength(Buffer, 3);
      Move(Data[Pos], Buffer[0], 3);
      FrameID := TEncoding.ANSI.GetString(Buffer);
      FrameSize := (Data[Pos+3] shl 16) or (Data[Pos+4] shl 8) or Data[Pos+5];
      Inc(Pos, 6);
    end
    else
    begin
      if Pos + 10 > Length(Data) then Break;
      SetLength(Buffer, 4);
      Move(Data[Pos], Buffer[0], 4);
      FrameID := TEncoding.ANSI.GetString(Buffer);
      FrameSize := (Data[Pos+4] shl 24) or (Data[Pos+5] shl 16) or (Data[Pos+6] shl 8) or Data[Pos+7];
      Inc(Pos, 10);
    end;
    if (FrameSize <= 0) or (Pos + FrameSize > Length(Data)) then Break;
    SetLength(FrameData, FrameSize);
    Move(Data[Pos], FrameData[0], FrameSize);
    if (FrameID = 'TIT2') or (FrameID = 'TT2') then
      Info.Title := DecodeText(FrameData)
    else if (FrameID = 'TPE1') or (FrameID = 'TP1') then
      Info.Artist := DecodeText(FrameData)
    else if (FrameID = 'TALB') or (FrameID = 'TAL') then
      Info.Album := DecodeText(FrameData)
    else if (FrameID = 'TYER') or (FrameID = 'TYE') or (FrameID = 'TDRC') then
      Info.Year := DecodeText(FrameData)
    else if (FrameID = 'COMM') or (FrameID = 'COM') then
      Info.Comment := DecodeText(FrameData);
    Inc(Pos, FrameSize);
  end;
end;

{-------------------- TMP3Reader --------------------}

class function TMP3Reader.ReadMP3(const FileName: string): TMP3Info;
var
  FS: TFileStream;
begin
  if not FileExists(FileName) then
    raise Exception.Create('Файл не найден: ' + FileName);
  FS := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    ReadID3v2(FS, Result);
    ReadID3v1(FS, Result);
  finally
    FS.Free;
  end;
end;

end.
