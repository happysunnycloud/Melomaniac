unit MP3TAGsReaderUnit;

interface

uses
  System.SysUtils, System.Classes;

type
  TMP3Info = record
    Title: string;
    Artist: string;
    Album: string;
    Year: string;
    Comment: string;
    Genre: Byte;
    Duration: Double; // в секундах
//    FileName: String;
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

    Info.Genre := Tag[127];
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

{-------------------- Duration с поддержкой VBR (XING/VBRI) --------------------}

function GetMP3Duration(const Stream: TFileStream): Double;
type
  TMPEGVersion = (mvMPEG25, mvMPEG2, mvMPEG1);
var
  Header: array[0..3] of Byte;
  FrameOffset: Int64;
  VersionBits, LayerBits, BitRateIndex, SampleRateIndex: Integer;
  Version: TMPEGVersion;
  BitRate, SampleRate: Integer;
  XingPos: Int64;
  XingHeader: array[0..3] of Byte;
  Frames: Cardinal;
begin
  Result := 0;
  FrameOffset := 0;
  while FrameOffset < Stream.Size - 4 do
  begin
    Stream.Position := FrameOffset;
    if Stream.Read(Header, 4) <> 4 then Exit;
    if (Header[0] = $FF) and ((Header[1] and $E0) = $E0) then
    begin
      VersionBits := (Header[1] shr 3) and $03;
      case VersionBits of
        0: Version := mvMPEG25;
        2: Version := mvMPEG2;
        3: Version := mvMPEG1;
      else
        Inc(FrameOffset);
        Continue;
      end;
      LayerBits := (Header[1] shr 1) and $03;
      if LayerBits <> 1 then
      begin
        Inc(FrameOffset);
        Continue;
      end;
      BitRateIndex := (Header[2] shr 4) and $0F;
      SampleRateIndex := (Header[2] shr 2) and $03;
      if (BitRateIndex = 0) or (BitRateIndex = 15) or (SampleRateIndex > 2) then
      begin
        Inc(FrameOffset);
        Continue;
      end;

      if Version = mvMPEG1 then
      begin
        BitRate := MPEG1_L3_BitRates[BitRateIndex] * 1000;
        SampleRate := MPEG1_SampleRates[SampleRateIndex];
      end
      else
      begin
        BitRate := MPEG2_L3_BitRates[BitRateIndex] * 1000;
        SampleRate := MPEG2_SampleRates[SampleRateIndex];
      end;

      // Проверка XING/Info (VBR)
      XingPos := Stream.Position + 4;
      Stream.Position := XingPos;
      if Stream.Read(XingHeader, 4) = 4 then
      begin
        if ((XingHeader[0] = Ord('X')) and (XingHeader[1] = Ord('i')) and
            (XingHeader[2] = Ord('n')) and (XingHeader[3] = Ord('g'))) or
           ((XingHeader[0] = Ord('I')) and (XingHeader[1] = Ord('n')) and
            (XingHeader[2] = Ord('f')) and (XingHeader[3] = Ord('o'))) then
        begin
          if Stream.Read(Frames, 4) = 4 then
          begin
            Frames := ((Frames and $FF) shl 24) or
                      (((Frames shr 8) and $FF) shl 16) or
                      (((Frames shr 16) and $FF) shl 8) or
                      ((Frames shr 24) and $FF);
            if Frames > 0 then
            begin
              Result := Frames * 1152 / SampleRate;
              Exit;
            end;
          end;
        end;
      end;

      // CBR fallback
      Result := (Stream.Size - FrameOffset) * 8 / BitRate;
      Exit;
    end;
    Inc(FrameOffset);
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
    Result.Duration := GetMP3Duration(FS);
//    Result.FileName := FileName;
  finally
    FS.Free;
  end;
end;

end.
