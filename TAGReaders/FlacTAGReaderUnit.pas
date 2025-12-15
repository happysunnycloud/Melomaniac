unit FlacTAGReaderUnit;

interface

uses
  System.SysUtils, System.Classes, System.Character;

type
  TFlacInfo = record
    Title: string;
    Artist: string;
    Album: string;
    Year: string;
    Comment: string;
    Genre: string;
  end;

  TFlacReader = class
  public
    // Read FLAC metadata (STREAMINFO + VORBIS_COMMENT). Does not read pictures.
    // Raises exception on I/O / format errors.
    class function ReadFLAC(const AFileName: string): TFlacInfo; static;
  end;

implementation

const
  FLAC_SIGNATURE          = 'fLaC';
  FLAC_SIGNATURE_LEN      = Length(FLAC_SIGNATURE);   // 4
  META_HEADER_LEN         = 4;
  STREAMINFO_BLOCK_TYPE   = 0;
  VORBIS_COMMENT_TYPE     = 4;
  STREAMINFO_MIN_LEN      = 34;
  MAX_META_BLOCK_SIZE     = 16 * 1024 * 1024;

{ Helper routines }

function ReadExactly(Stream: TStream; var Buffer; Count: NativeInt): Boolean;
var
  ReadBytes: NativeInt;
begin
  ReadBytes := Stream.Read(Buffer, Count);
  Result := ReadBytes = Count;
end;

function ReadBytes(Stream: TStream; Count: NativeInt): TBytes;
begin
  SetLength(Result, Count);
  if Count = 0 then Exit;
  if Stream.Read(Result[0], Count) <> Count then
    raise EInOutError.Create('Unexpected EOF while reading bytes');
end;

function ReadLE32FromArray(const Buf: TBytes; Offset: Integer): Cardinal;
begin
  if Offset + 3 >= Length(Buf) then
    raise EInOutError.Create('Buffer too small for ReadLE32FromArray');
  Result := Cardinal(Buf[Offset]) or (Cardinal(Buf[Offset + 1]) shl 8) or
            (Cardinal(Buf[Offset + 2]) shl 16) or (Cardinal(Buf[Offset + 3]) shl 24);
end;

{ TFlacReader }

class function TFlacReader.ReadFLAC(const AFileName: string): TFlacInfo;
var
  FS: TFileStream;
  Info: TFlacInfo;
  // другие переменные для чтения Vorbis Comment
  //sigBuf: array[0..FLAC_SIGNATURE_LEN-1] of Byte;
  metaHdr: array[0..META_HEADER_LEN-1] of Byte;
  metaBlockType: Byte;
  metaBlockIsLast: Boolean;
  metaBlockLength: Cardinal;
  blockData: TBytes;
  readOffset: Integer;
  vendorLen, commentsCount, i, commentLen: Cardinal;
  vendor, commentBytes: TBytes;
  commentStr: string;
  eqPos: Integer;
  key, val: string;
begin
  Info.Title := '';
  Info.Artist := '';
  Info.Album := '';
  Info.Year := '';
  Info.Comment := '';
  Info.Genre := '';

  if not FileExists(AFileName) then
    raise Exception.CreateFmt('File not found: %s', [AFileName]);

  FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    // --- Read metadata blocks for Vorbis comments ---
    FS.Position := FLAC_SIGNATURE_LEN;
    while True do
    begin
      if not ReadExactly(FS, metaHdr[0], META_HEADER_LEN) then Break;

      metaBlockIsLast := (metaHdr[0] and $80) <> 0;
      metaBlockType := metaHdr[0] and $7F;
      metaBlockLength := (Cardinal(metaHdr[1]) shl 16) or (Cardinal(metaHdr[2]) shl 8) or Cardinal(metaHdr[3]);

      if metaBlockLength > 0 then
        blockData := ReadBytes(FS, metaBlockLength)
      else
        SetLength(blockData, 0);

      if metaBlockType = VORBIS_COMMENT_TYPE then
      begin
        readOffset := 0;
        if Length(blockData) < 4 then Continue;

        vendorLen := ReadLE32FromArray(blockData, readOffset);
        Inc(readOffset, 4);

        if vendorLen > 0 then
        begin
          SetLength(vendor, vendorLen);
          Move(blockData[readOffset], vendor[0], vendorLen);
          Inc(readOffset, Integer(vendorLen));
        end;

        if readOffset + 4 > Length(blockData) then Continue;
        commentsCount := ReadLE32FromArray(blockData, readOffset);
        Inc(readOffset, 4);

        for i := 0 to Integer(commentsCount)-1 do
        begin
          commentLen := ReadLE32FromArray(blockData, readOffset);
          Inc(readOffset, 4);
          SetLength(commentBytes, commentLen);
          Move(blockData[readOffset], commentBytes[0], commentLen);
          commentStr := TEncoding.UTF8.GetString(commentBytes);
          Inc(readOffset, Integer(commentLen));

          eqPos := Pos('=', commentStr);
          if eqPos > 0 then
          begin
            key := UpperCase(Trim(Copy(commentStr, 1, eqPos-1)));
            val := Trim(Copy(commentStr, eqPos+1, MaxInt));
          end
          else
          begin
            key := UpperCase(Trim(commentStr));
            val := '';
          end;

          if key = 'TITLE' then Info.Title := val
          else if key = 'ARTIST' then Info.Artist := val
          else if key = 'ALBUM' then Info.Album := val
          else if (key = 'DATE') or (key = 'YEAR') then Info.Year := val
          else if key = 'COMMENT' then Info.Comment := val
          else if key = 'GENRE' then Info.Genre := val;
        end;
      end;

      if metaBlockIsLast then Break;
    end;

    Result := Info;
  finally
    FS.Free;
  end;
end;

end.

