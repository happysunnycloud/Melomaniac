unit MP3TAGsReaderUnit;

{
  Юнит для чтения тегов музыкальных файлов (MP3).
  Поддерживает:
    - ID3v2 (2.2 / 2.3 / 2.4) - основные текстовые фреймы
    - ID3v1 (как резервный вариант, если ID3v2 не найден)

  Использование:
    var
      Info: TMP3Info;
    begin
      Info := TMP3Reader.ReadMP3('C:\Music\song.mp3');
      ShowMessage(Info.Title + ' - ' + Info.Artist);
    end;
}

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
    procedure Clear;
  end;

  TMP3Reader = class
  public
    class function ReadMP3(const FileName: string): TMP3Info;
  end;

implementation

{ ---------- Таблица жанров ID3v1 (используется, если у ID3v2 нет TCON,
             либо жанр задан в формате "(NN)") ---------- }
const
  ID3v1Genres: array[0..191] of string = (
    'Blues','Classic Rock','Country','Dance','Disco','Funk','Grunge',
    'Hip-Hop','Jazz','Metal','New Age','Oldies','Other','Pop','R&B','Rap',
    'Reggae','Rock','Techno','Industrial','Alternative','Ska',
    'Death Metal','Pranks','Soundtrack','Euro-Techno','Ambient',
    'Trip-Hop','Vocal','Jazz+Funk','Fusion','Trance','Classical',
    'Instrumental','Acid','House','Game','Sound Clip','Gospel','Noise',
    'AlternRock','Bass','Soul','Punk','Space','Meditative',
    'Instrumental Pop','Instrumental Rock','Ethnic','Gothic','Darkwave',
    'Techno-Industrial','Electronic','Pop-Folk','Eurodance','Dream',
    'Southern Rock','Comedy','Cult','Gangsta','Top 40','Christian Rap',
    'Pop/Funk','Jungle','Native American','Cabaret','New Wave',
    'Psychedelic','Rave','Showtunes','Trailer','Lo-Fi','Tribal',
    'Acid Punk','Acid Jazz','Polka','Retro','Musical','Rock & Roll',
    'Hard Rock','Folk','Folk-Rock','National Folk','Swing','Fast Fusion',
    'Bebob','Latin','Revival','Celtic','Bluegrass','Avantgarde',
    'Gothic Rock','Progressive Rock','Psychedelic Rock','Symphonic Rock',
    'Slow Rock','Big Band','Chorus','Easy Listening','Acoustic','Humour',
    'Speech','Chanson','Opera','Chamber Music','Sonata','Symphony',
    'Booty Bass','Primus','Porn Groove','Satire','Slow Jam','Club',
    'Tango','Samba','Folklore','Ballad','Power Ballad','Rhythmic Soul',
    'Freestyle','Duet','Punk Rock','Drum Solo','A Cappella','Euro-House',
    'Dance Hall','Goa','Drum & Bass','Club-House','Hardcore','Terror',
    'Indie','BritPop','Afro-Punk','Polsk Punk','Beat','Christian Gangsta',
    'Heavy Metal','Black Metal','Crossover','Contemporary Christian',
    'Christian Rock','Merengue','Salsa','Thrash Metal','Anime','JPop',
    'Synthpop','Abstract','Art Rock','Baroque','Bhangra','Big Beat',
    'Breakbeat','Chillout','Downtempo','Dub','EBM','Eclectic','Electro',
    'Electroclash','Emo','Experimental','Garage','Global','IDM',
    'Illbient','Industro-Goth','Jam Band','Krautrock','Leftfield',
    'Lounge','Math Rock','New Romantic','Nu-Breakz','Post-Punk',
    'Post-Rock','Psytrance','Shoegaze','Space Rock','Trop Rock',
    'World Music','Neoclassical','Audiobook','Audio Theatre',
    'Neue Deutsche Welle','Podcast','Indie Rock','G-Funk','Dubstep',
    'Garage Rock','Psybient'
  );

{ ---------- TMP3Info ---------- }

procedure TMP3Info.Clear;
begin
  Title   := '';
  Artist  := '';
  Album   := '';
  Year    := '';
  Comment := '';
  Genre   := '';
end;

{ ---------- Вспомогательные функции ---------- }

// Декодирует байтовую строку фрейма ID3v2 с учётом байта кодировки
// (0 = ISO-8859-1/ANSI, 1 = UTF-16 с BOM, 2 = UTF-16BE без BOM, 3 = UTF-8)
//
// TakeFirstValue: в ID3v2.4 текстовый фрейм может содержать НЕСКОЛЬКО
// значений, разделённых нулевым символом (#0) - например, "2019"#0"2019"
// при повторном/дублирующем значении, записанном некоторыми тегерами.
// Для полей типа Title/Artist/Album/Year/Genre нам нужно только первое
// значение. Для COMM (комментарий) вызывающий код обрабатывает структуру
// сам (там #0 отделяет короткое описание от текста) - там передаём False.
function DecodeID3v2Text(const Bytes: TBytes; TakeFirstValue: Boolean = True): string;
var
  Encoding: Byte;
  Data: TBytes;
  NullPos: Integer;
begin
  Result := '';
  if Length(Bytes) = 0 then
    Exit;

  Encoding := Bytes[0];
  Data := Copy(Bytes, 1, Length(Bytes) - 1);

  case Encoding of
    0: Result := TEncoding.ANSI.GetString(Data);
    1: // UTF-16 с BOM: порядок байт (LE/BE) задаётся самим BOM в данных,
       // а не фиксирован - TEncoding.Unicode в Delphi это всегда LE, поэтому
       // при обратном порядке (BOM = FE FF) его нужно декодировать как BE
       if (Length(Data) >= 2) and (Data[0] = $FE) and (Data[1] = $FF) then
         Result := TEncoding.BigEndianUnicode.GetString(Data)
       else
         Result := TEncoding.Unicode.GetString(Data); // BOM = FF FE, либо BOM отсутствует - LE по умолчанию
    2: Result := TEncoding.BigEndianUnicode.GetString(Data);
    3: Result := TEncoding.UTF8.GetString(Data);
  else
    Result := TEncoding.ANSI.GetString(Data);
  end;

  // Убираем BOM (U+FEFF), который TEncoding сам не отбрасывает - он лишь
  // декодирует эти байты как обычный символ и оставляет его в начале строки
  if (Result <> '') and (Result[1] = #$FEFF) then
    Delete(Result, 1, 1);

  if TakeFirstValue then
  begin
    NullPos := Pos(#0, Result);
    if NullPos > 0 then
      Result := Copy(Result, 1, NullPos - 1);
  end;

  // Убираем завершающие нулевые символы / пробелы
  Result := Result.TrimRight([#0, ' ']);
end;

// Преобразует жанр вида "(17)" или "17" (старый формат ID3v1 в фрейме TCON)
// в текстовое название, если это возможно
function ResolveGenre(const RawGenre: string): string;
var
  S: string;
  Code: Integer;
begin
  Result := RawGenre;
  S := RawGenre.Trim;

  if (S.Length > 2) and (S[1] = '(') and (S[S.Length] = ')') then
    S := Copy(S, 2, S.Length - 2);

  if TryStrToInt(S, Code) then
  begin
    if (Code >= Low(ID3v1Genres)) and (Code <= High(ID3v1Genres)) then
      Result := ID3v1Genres[Code];
  end;
end;

// Читает синхросейф-размер (используется в заголовке ID3v2, 7 бит на байт)
function ReadSyncSafeSize(B0, B1, B2, B3: Byte): Integer;
begin
  Result := (B0 and $7F) shl 21
          or (B1 and $7F) shl 14
          or (B2 and $7F) shl 7
          or (B3 and $7F);
end;

// Читает обычный 32-битный big-endian размер (используется в ID3v2.2 и
// иногда в некорректно записанных ID3v2.3 файлах)
function ReadPlainSize(B0, B1, B2, B3: Byte): Integer;
begin
  Result := (B0 shl 24) or (B1 shl 16) or (B2 shl 8) or B3;
end;

{ ---------- Чтение ID3v1 (последние 128 байт файла) ---------- }

function ReadID3v1(Stream: TStream; var Info: TMP3Info): Boolean;
var
  Buf: TBytes;
  Tag: string;
  GenreCode: Byte;
begin
  Result := False;
  if Stream.Size < 128 then
    Exit;

  SetLength(Buf, 128);
  Stream.Position := Stream.Size - 128;
  Stream.ReadBuffer(Buf[0], 128);

  Tag := TEncoding.ANSI.GetString(Buf, 0, 3);
  if Tag <> 'TAG' then
    Exit;

  Info.Title  := TEncoding.ANSI.GetString(Buf, 3, 30).TrimRight([#0, ' ']);
  Info.Artist := TEncoding.ANSI.GetString(Buf, 33, 30).TrimRight([#0, ' ']);
  Info.Album  := TEncoding.ANSI.GetString(Buf, 63, 30).TrimRight([#0, ' ']);
  Info.Year   := TEncoding.ANSI.GetString(Buf, 93, 4).TrimRight([#0, ' ']);
  Info.Comment:= TEncoding.ANSI.GetString(Buf, 97, 30).TrimRight([#0, ' ']);

  GenreCode := Buf[127];
  if GenreCode <= High(ID3v1Genres) then
    Info.Genre := ID3v1Genres[GenreCode]
  else
    Info.Genre := '';

  Result := True;
end;

{ ---------- Чтение ID3v2 ---------- }

function ReadID3v2(Stream: TStream; var Info: TMP3Info): Boolean;
var
  Header: array[0..9] of Byte;
  MajorVersion: Byte;
  Flags: Byte;
  TagSize: Integer;
  ExtHeaderSize: Integer;
  Pos, TagEnd: Int64;
  FrameID: string;
  FrameIDLen: Integer;
  FrameSize: Integer;
  FrameBytes: TBytes;
  IdBuf: TBytes;
  SizeBuf: array[0..3] of Byte;
  FlagBuf: array[0..1] of Byte;
  CommBytes: TBytes;
  SkipFrame: Boolean;
begin
  Result := False;

  if Stream.Size < 10 then
    Exit;

  Stream.Position := 0;
  Stream.ReadBuffer(Header, 10);

  if (Header[0] <> Ord('I')) or (Header[1] <> Ord('D')) or (Header[2] <> Ord('3')) then
    Exit; // ID3v2 отсутствует

  MajorVersion := Header[3];
  Flags := Header[5];
  TagSize := ReadSyncSafeSize(Header[6], Header[7], Header[8], Header[9]);

  Pos := 10;
  TagEnd := 10 + TagSize;

  // Пропускаем расширенный заголовок, если он есть (флаг бит 6)
  if (Flags and $40) <> 0 then
  begin
    Stream.Position := Pos;
    Stream.ReadBuffer(SizeBuf, 4);
    if MajorVersion >= 4 then
      ExtHeaderSize := ReadSyncSafeSize(SizeBuf[0], SizeBuf[1], SizeBuf[2], SizeBuf[3])
    else
      ExtHeaderSize := ReadPlainSize(SizeBuf[0], SizeBuf[1], SizeBuf[2], SizeBuf[3]);
    Inc(Pos, ExtHeaderSize);
  end;

  // Размер и структура ID заголовка фрейма отличаются в ID3v2.2 (3 байта ID, 3 байта размер)
  if MajorVersion = 2 then
    FrameIDLen := 3
  else
    FrameIDLen := 4;

  SetLength(IdBuf, FrameIDLen);
  while Pos < TagEnd - FrameIDLen do
  begin
    Stream.Position := Pos;
    Stream.ReadBuffer(IdBuf[0], FrameIDLen);

    // Если дошли до нулевых байт (padding) - заканчиваем
    if IdBuf[0] = 0 then
      Break;

    FrameID := TEncoding.ANSI.GetString(IdBuf, 0, FrameIDLen);
    Inc(Pos, FrameIDLen);

    if MajorVersion = 2 then
    begin
      Stream.Position := Pos;
      Stream.ReadBuffer(SizeBuf, 3);
      FrameSize := (SizeBuf[0] shl 16) or (SizeBuf[1] shl 8) or SizeBuf[2];
      Inc(Pos, 3);
      SkipFrame := False; // у ID3v2.2 нет флагов фрейма - сжатие/шифрование не предусмотрены
    end
    else
    begin
      Stream.Position := Pos;
      Stream.ReadBuffer(SizeBuf, 4);
      if MajorVersion >= 4 then
        FrameSize := ReadSyncSafeSize(SizeBuf[0], SizeBuf[1], SizeBuf[2], SizeBuf[3])
      else
        FrameSize := ReadPlainSize(SizeBuf[0], SizeBuf[1], SizeBuf[2], SizeBuf[3]);
      Inc(Pos, 4);

      Stream.Position := Pos;
      Stream.ReadBuffer(FlagBuf, 2);
      Inc(Pos, 2);

      if MajorVersion >= 4 then
        // ID3v2.4: второй байт флагов - бит 0x08 = Compression, 0x04 = Encryption
        SkipFrame := (FlagBuf[1] and $08 <> 0) or (FlagBuf[1] and $04 <> 0)
      else
        // ID3v2.3: второй байт флагов - бит 0x80 = Compression, 0x40 = Encryption
        SkipFrame := (FlagBuf[1] and $80 <> 0) or (FlagBuf[1] and $40 <> 0);
    end;

    if (FrameSize <= 0) or (Pos + FrameSize > Stream.Size) then
      Break;

    SetLength(FrameBytes, FrameSize);
    Stream.Position := Pos;
    Stream.ReadBuffer(FrameBytes[0], FrameSize);

    // Сжатые/зашифрованные фреймы не пытаемся декодировать как текст - просто пропускаем
    if not SkipFrame then
    begin
      // Сопоставление ID фреймов ID3v2.2 / v2.3+ с нужными полями
      if (FrameID = 'TIT2') or (FrameID = 'TT2') then
        Info.Title := DecodeID3v2Text(FrameBytes)
      else if (FrameID = 'TPE1') or (FrameID = 'TP1') then
        Info.Artist := DecodeID3v2Text(FrameBytes)
      else if (FrameID = 'TALB') or (FrameID = 'TAL') then
        Info.Album := DecodeID3v2Text(FrameBytes)
      else if (FrameID = 'TYER') or (FrameID = 'TDRC') or (FrameID = 'TYE') then
        Info.Year := DecodeID3v2Text(FrameBytes)
      else if (FrameID = 'TCON') or (FrameID = 'TCO') then
        Info.Genre := ResolveGenre(DecodeID3v2Text(FrameBytes))
      else if (FrameID = 'COMM') or (FrameID = 'COM') then
      begin
        // COMM: [encoding(1)][language(3)][short description\0][text]
        // Для простоты декодируем всё после языка, отбрасывая описание при возможности
        if Length(FrameBytes) > 4 then
        begin
          CommBytes := Copy(FrameBytes, 0, 1); // байт кодировки
          CommBytes := CommBytes + Copy(FrameBytes, 4, Length(FrameBytes) - 4);
          Info.Comment := DecodeID3v2Text(CommBytes, False);
        end;
      end;
    end;

    Inc(Pos, FrameSize);
    Result := True;
  end;
end;

{ ---------- TMP3Reader ---------- }

class function TMP3Reader.ReadMP3(const FileName: string): TMP3Info;
var
  Stream: TFileStream;
begin
  Result.Clear;

  if not FileExists(FileName) then
    raise Exception.CreateFmt('Файл не найден: %s', [FileName]);

  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    // ID3v2 - основной источник (обычно в начале файла).
    // ID3v1 используется только если ID3v2 в файле не найден вообще:
    // если ID3v2 найден, доверяем его данным как есть, включая пустые поля -
    // это не "мусор", а то, что реально записано в теге. Подмешивать сюда
    // ID3v1 небезопасно: там может быть устаревший/несвязанный тег (частая
    // ситуация после редактирования файла другим плеером), и он молча
    // подменит корректно пустое поле на неверные данные.
    if not ReadID3v2(Stream, Result) then
      ReadID3v1(Stream, Result);
  finally
    Stream.Free;
  end;
end;

end.
