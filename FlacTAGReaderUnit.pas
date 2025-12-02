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
    Duration: Double; // seconds, 0 = unknown
  end;

  TFlacReader = class
  public
    /// Read FLAC metadata (STREAMINFO + VORBIS_COMMENT). Does not read pictures.
    /// Raises exception on I/O / format errors.
    class function ReadFLAC(const AFileName: string): TFlacInfo; static;
  end;

implementation

const
  // --- Signature and sizes (no magic numbers in code) ---
  FLAC_SIGNATURE          = 'fLaC';
  FLAC_SIGNATURE_LEN      = Length(FLAC_SIGNATURE);   // 4
  META_HEADER_LEN         = 4;                        // 1 byte flags+type + 3 bytes length
  STREAMINFO_BLOCK_TYPE   = 0;                        // STREAMINFO block type per spec
  VORBIS_COMMENT_TYPE     = 4;                        // Vorbis comment block type per spec
  STREAMINFO_MIN_LEN      = 34;                       // STREAMINFO must be 34 bytes
  MAX_META_BLOCK_SIZE     = 16 * 1024 * 1024;        // sanity limit ~16MB for a block
  // When parsing vorbis comment, we trust lengths inside but validate against block length.

{ Helper routines placed as local functions inside implementation to keep public API small }

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

function ReadUInt24BEFromArray(const Buf: TBytes; Offset: Integer): Cardinal;
begin
  // Read 3 bytes big-endian from Buf at Offset
  if Offset + 2 >= Length(Buf) then
    raise EInOutError.Create('Buffer too small for ReadUInt24BEFromArray');
  Result := (Cardinal(Buf[Offset]) shl 16) or (Cardinal(Buf[Offset + 1]) shl 8) or Cardinal(Buf[Offset + 2]);
end;

function ReadLE32FromArray(const Buf: TBytes; Offset: Integer): Cardinal;
begin
  if Offset + 3 >= Length(Buf) then
    raise EInOutError.Create('Buffer too small for ReadLE32FromArray');
  Result := Cardinal(Buf[Offset]) or (Cardinal(Buf[Offset + 1]) shl 8) or
            (Cardinal(Buf[Offset + 2]) shl 16) or (Cardinal(Buf[Offset + 3]) shl 24);
end;

class function TFlacReader.ReadFLAC(const AFileName: string): TFlacInfo;
var
  FS: TFileStream;
  sigBuf: array[0..FLAC_SIGNATURE_LEN - 1] of Byte;
  metaHdr: array[0..META_HEADER_LEN - 1] of Byte;
  metaBlockType: Byte;
  metaBlockIsLast: Boolean;
  metaBlockLength: Cardinal;
  blockData: TBytes;
  // STREAMINFO fields
  streaminfoData: TBytes;
  sampleRate: Cardinal;
  totalSamples: UInt64;
  // Vorbis comment parsing
  readOffset: Integer;
  vendorLen: Cardinal;
  vendor: TBytes;
  commentsCount: Cardinal;
  i: Integer;
  commentLen: Cardinal;
  commentBytes: TBytes;
  commentStr: string;
  eqPos: Integer;
  key, val: string;
  // result
  Info: TFlacInfo;
begin
  // Initialize result with empty strings and zero duration
  Info.Title := '';
  Info.Artist := '';
  Info.Album := '';
  Info.Year := '';
  Info.Comment := '';
  Info.Genre := '';
  Info.Duration := 0.0;

  if not FileExists(AFileName) then
    raise Exception.CreateFmt('File not found: %s', [AFileName]);

  FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    // --- Read and validate signature "fLaC" ---
    if not ReadExactly(FS, sigBuf[0], FLAC_SIGNATURE_LEN) then
      raise EInOutError.Create('File too small to be FLAC');
    if not ((sigBuf[0] = Byte(Ord('f'))) and (sigBuf[1] = Byte(Ord('L'))) and
            (sigBuf[2] = Byte(Ord('a'))) and (sigBuf[3] = Byte(Ord('C')))) then
      raise Exception.Create('Not a FLAC file (missing "fLaC" signature)');

    // --- Iterate metadata blocks until last metadata block or EOF ---
    while True do
    begin
      // Read metadata header (1 byte flags/type + 3 bytes length)
      if not ReadExactly(FS, metaHdr[0], META_HEADER_LEN) then
        raise EInOutError.Create('Unexpected EOF while reading metadata header');

      metaBlockIsLast := (metaHdr[0] and $80) <> 0;
      metaBlockType := metaHdr[0] and $7F;
      // length is 24-bit big-endian in bytes 1..3
      metaBlockLength := (Cardinal(metaHdr[1]) shl 16) or (Cardinal(metaHdr[2]) shl 8) or Cardinal(metaHdr[3]);

      // Basic sanity checks for length
      if (metaBlockLength > MAX_META_BLOCK_SIZE) then
        raise Exception.CreateFmt('FLAC metadata block too large: %u', [metaBlockLength]);

      // Read block payload
      if metaBlockLength > 0 then
        blockData := ReadBytes(FS, metaBlockLength)
      else
        SetLength(blockData, 0);

      // --- Handle block types we care about ---
      if metaBlockType = STREAMINFO_BLOCK_TYPE then
      begin
        // STREAMINFO must be at least 34 bytes (spec says exactly 34 bytes)
        if Length(blockData) < STREAMINFO_MIN_LEN then
          raise Exception.Create('STREAMINFO block too small');

        // STREAMINFO fields are big-endian; we need sample rate (20 bits) and total samples (36 bits)
        // The layout: bytes 10..17 contain (sample_rate (20) | channels (3) | bits-per-sample (5) | total_samples (36))
        // We'll combine bytes[10..17] into a 64-bit value and extract bits.
        streaminfoData := blockData; // alias
        // build 64-bit from streaminfoData[10..17]
        var a8: UInt64 := 0;
        for i := 0 to 7 do
        begin
          a8 := (a8 shl 8) or UInt64(streaminfoData[10 + i]);
        end;

        // top 20 bits = sample_rate
        sampleRate := Cardinal((a8 shr 44) and $FFFFF);
        // total samples = lower 36 bits
        totalSamples := a8 and $FFFFFFFFF; // mask 36 bits

        if (sampleRate > 0) and (totalSamples > 0) then
          Info.Duration := totalSamples / sampleRate
        else
          Info.Duration := 0.0;
      end
      else if metaBlockType = VORBIS_COMMENT_TYPE then
      begin
        // Parse Vorbis Comment block (UTF-8 strings)
        // layout: 32-bit LE vendor_length; vendor_string; 32-bit LE user_comment_list_length;
        // for each comment: 32-bit LE length; UTF-8 bytes 'KEY=VALUE'
        readOffset := 0;
        // need at least 4 bytes for vendor length
        if Length(blockData) < 4 then
          raise Exception.Create('VORBIS_COMMENT block too small');

        vendorLen := ReadLE32FromArray(blockData, readOffset);
        Inc(readOffset, 4);

        if vendorLen > 0 then
        begin
          if readOffset + Integer(vendorLen) > Length(blockData) then
            raise Exception.Create('VORBIS_COMMENT vendor string truncated');
          SetLength(vendor, vendorLen);
          if vendorLen > 0 then
            Move(blockData[readOffset], vendor[0], vendorLen);
          Inc(readOffset, Integer(vendorLen));
        end
        else
          vendor := nil;

        if readOffset + 4 > Length(blockData) then
          raise Exception.Create('VORBIS_COMMENT truncated before comment count');

        commentsCount := ReadLE32FromArray(blockData, readOffset);
        Inc(readOffset, 4);

        for i := 0 to Integer(commentsCount) - 1 do
        begin
          if readOffset + 4 > Length(blockData) then
            raise Exception.Create('VORBIS_COMMENT truncated while reading comment length');

          commentLen := ReadLE32FromArray(blockData, readOffset);
          Inc(readOffset, 4);

          if (readOffset + Integer(commentLen)) > Length(blockData) then
            raise Exception.Create('VORBIS_COMMENT truncated comment data');

          if commentLen > 0 then
          begin
            SetLength(commentBytes, commentLen);
            Move(blockData[readOffset], commentBytes[0], commentLen);
            commentStr := TEncoding.UTF8.GetString(commentBytes);
          end
          else
            commentStr := '';

          Inc(readOffset, Integer(commentLen));

          // Parse "KEY=VALUE"
          eqPos := Pos('=', commentStr);
          if eqPos > 0 then
          begin
            key := UpperCase(Trim(Copy(commentStr, 1, eqPos - 1)));
            val := Trim(Copy(commentStr, eqPos + 1, MaxInt));
          end
          else
          begin
            key := UpperCase(Trim(commentStr));
            val := '';
          end;

          // Map common keys to fields
          if key = 'TITLE' then
            Info.Title := val
          else if key = 'ARTIST' then
            Info.Artist := val
          else if key = 'ALBUM' then
            Info.Album := val
          else if (key = 'DATE') or (key = 'YEAR') then
            Info.Year := val
          else if key = 'COMMENT' then
            Info.Comment := val
          else if key = 'GENRE' then
            Info.Genre := val
          // ignore other keys for now
        end;
      end
      else
      begin
        // ignore other block types (PICTURE, SEEKTABLE, CUESHEET, APPLICATION, etc.)
      end;

      // If this was last metadata block — stop
      if metaBlockIsLast then
        Break;
      // otherwise continue to next metadata block
    end;

    Result := Info;
  finally
    FS.Free;
  end;
end;

end.

