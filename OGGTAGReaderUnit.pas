unit OGGTAGReaderUnit;

interface

uses
  System.SysUtils, System.Classes, System.Types;

type
  TOGGInfo = record
    Title: string;
    Artist: string;
    Album: string;
    Year: string;
    Comment: string;
    Genre: string;    // changed to string (correct for VorbisComment)
    Duration: Double; // seconds
  end;

  TOGGReader = class
  public
    class function ReadOGG(const FileName: string): TOGGInfo;
  end;

implementation

type
  TOGGPageHeader = packed record
    Capture: array[0..3] of AnsiChar;   // "OggS"
    Version: Byte;
    HeaderType: Byte;
    GranulePos: Int64;
    BitstreamSerial: Cardinal;
    PageSeq: Cardinal;
    Checksum: Cardinal;
    SegCount: Byte;
  end;

{ Utility: read page header                                                   }
function ReadPageHeader(Stream: TStream; var H: TOGGPageHeader): Boolean;
var
  n: Integer;
begin
  Result := False;
  n := Stream.Read(H, SizeOf(TOGGPageHeader));
  if n <> SizeOf(TOGGPageHeader) then Exit;
  if (H.Capture[0] <> 'O') or (H.Capture[1] <> 'g') or (H.Capture[2] <> 'g') or (H.Capture[3] <> 'S') then Exit;
  Result := True;
end;

{ Helper: safe match bytes in a packet against ASCII/Ansi signature             }
function MatchAsciiAt(const Packet: TBytes; const Sig: AnsiString; Offset: Integer): Boolean;
var
  j, L: Integer;
begin
  Result := False;
  L := Length(Sig);
  if (Offset < 0) then Exit;
  if (Length(Packet) - Offset) < L then Exit;
  for j := 1 to L do
    if Integer(Packet[Offset + j - 1]) <> Ord(AnsiChar(Sig[j])) then Exit;
  Result := True;
end;

{ Detect codec by scanning a single packet (safe, deterministic)               }
function DetectCodecFromPacket(const Packet: TBytes): string;
var
  i, L: Integer;
begin
  Result := '';
  L := Length(Packet);
  if L = 0 then Exit;
  // Opus
  if (L >= 8) and MatchAsciiAt(Packet, 'OpusHead', 0) then
  begin
    Result := 'opus';
    Exit;
  end;
  // FLAC-in-OGG: 'fLaC' at offset 0
  if (L >= 4) and MatchAsciiAt(Packet, 'fLaC', 0) then
  begin
    Result := 'flac';
    Exit;
  end;
  // Vorbis: token 'vorbis' usually at offset 1 for ID, or later for comments
  for i := 0 to L - 6 do
    if MatchAsciiAt(Packet, 'vorbis', i) then
    begin
      Result := 'vorbis';
      Exit;
    end;
  // Theora: token 'theora'
  for i := 0 to L - 6 do
    if MatchAsciiAt(Packet, 'theora', i) then
    begin
      Result := 'theora';
      Exit;
    end;
end;

{ Parse VorbisComment directly from a Packet buffer (works for Vorbis/Opus/Theora/ogg-flac containing VorbisComment) }
procedure ParseVorbisCommentFromPacket(const Packet: TBytes; var Info: TOGGInfo);
var
  PacketLen: Integer;
  p: Integer;
  VendorLen, Count, L: Cardinal;
  CommentBytes: TBytes;
  S, Key, Val: string;
  eqpos: Integer;
  tmp32: Cardinal;
  // local copy to avoid repeated UTF8 conversion until needed
begin
  PacketLen := Length(Packet);
  if PacketLen < 7 then Exit;
  // find 'vorbis' token start
  p := -1;
  for L := 0 to PacketLen - 6 do
    if MatchAsciiAt(Packet, 'vorbis', L) then
    begin
      p := L + 6; // position just after 'vorbis'
      Break;
    end;
  if p = -1 then
    Exit;
  // Need at least 4 bytes vendor length
  if (p + 4) > PacketLen then Exit;
  tmp32 := Cardinal(Packet[p]) or (Cardinal(Packet[p+1]) shl 8) or (Cardinal(Packet[p+2]) shl 16) or (Cardinal(Packet[p+3]) shl 24);
  VendorLen := tmp32;
  Inc(p, 4 + Integer(VendorLen));
  if (p + 4) > PacketLen then Exit;
  tmp32 := Cardinal(Packet[p]) or (Cardinal(Packet[p+1]) shl 8) or (Cardinal(Packet[p+2]) shl 16) or (Cardinal(Packet[p+3]) shl 24);
  Count := tmp32;
  Inc(p, 4);
  while (Count > 0) and (p + 4 <= PacketLen) do
  begin
    tmp32 := Cardinal(Packet[p]) or (Cardinal(Packet[p+1]) shl 8) or (Cardinal(Packet[p+2]) shl 16) or (Cardinal(Packet[p+3]) shl 24);
    L := tmp32;
    Inc(p, 4);
    if p + Integer(L) > PacketLen then Break;
    if L > 0 then
    begin
      SetLength(CommentBytes, L);
      Move(Packet[p], CommentBytes[0], L);
      S := TEncoding.UTF8.GetString(CommentBytes);
    end
    else
      S := '';
    Inc(p, Integer(L));
    eqpos := Pos('=', S);
    if eqpos > 0 then
    begin
      Key := UpperCase(Trim(Copy(S, 1, eqpos-1)));
      Val := Trim(Copy(S, eqpos+1, MaxInt));
      if Key = 'TITLE' then Info.Title := Val else
      if Key = 'ARTIST' then Info.Artist := Val else
      if Key = 'ALBUM' then Info.Album := Val else
      if (Key = 'DATE') or (Key = 'YEAR') then Info.Year := Val else
      if Key = 'COMMENT' then Info.Comment := Val else
      if Key = 'GENRE' then Info.Genre := Val;
    end;
    Dec(Count);
  end;
end;

{ Parse Vorbis identification header for sample rate (packet-based)          }
function ParseVorbisSampleRateFromPacket(const Packet: TBytes): Integer;
var
  P: Integer;
  PacketLen: Integer;
begin
  Result := 0;
  PacketLen := Length(Packet);
  if PacketLen < 16 then Exit;
  // identification header: packet[0]=1, packet[1..6]='vorbis'
  // sample_rate is little-endian 32-bit at offset 12 (0-based)
  P := 12;
  if (P + 3) >= PacketLen then Exit;
  Result := Integer(Cardinal(Packet[P]) or (Cardinal(Packet[P+1]) shl 8) or (Cardinal(Packet[P+2]) shl 16) or (Cardinal(Packet[P+3]) shl 24));
end;

{ Parse Opus pre-skip                                                          }
function ParseOpusPreSkipFromPacket(const Packet: TBytes): Integer;
begin
  Result := 0;
  if Length(Packet) < 12 then Exit;
  if not MatchAsciiAt(Packet, 'OpusHead', 0) then Exit;
  // preskip is uint16 little-endian at offset 10
  Result := Packet[10] or (Packet[11] shl 8);
end;

{ Parse Theora identification header (extract FRN, FRD, granuleshift)         }
type
  TBitReader = record
    Bytes: TBytes;
    BytePos: Integer;
    BitPos: Integer;
    procedure Init(const AData: TBytes; AOffset: Integer);
    function ReadBits(Count: Integer; out Ok: Boolean): UInt64;
    function BitsAvailable: Int64;
  end;

procedure TBitReader.Init(const AData: TBytes; AOffset: Integer);
begin
  Bytes := nil;
  if (AOffset < 0) or (AOffset >= Length(AData)) then
  begin
    BytePos := 0;
    BitPos := 0;
    Exit;
  end;
  SetLength(Bytes, Length(AData) - AOffset);
  if Length(Bytes) > 0 then
    Move(AData[AOffset], Bytes[0], Length(Bytes));
  BytePos := 0;
  BitPos := 0;
end;

function TBitReader.BitsAvailable: Int64;
begin
  Result := (Length(Bytes) - BytePos) * 8 - BitPos;
end;

function TBitReader.ReadBits(Count: Integer; out Ok: Boolean): UInt64;
var
  avail, c, take: Integer;
  res: UInt64;
  b: Byte;
begin
  Ok := False;
  Result := 0;
  if (Count <= 0) or (Count > 64) then Exit;
  avail := BitsAvailable;
  if avail < Count then Exit;
  res := 0;
  while Count > 0 do
  begin
    if BytePos >= Length(Bytes) then Exit;
    b := Bytes[BytePos];
    c := 8 - BitPos;
    take := c;
    if take > Count then take := Count;
    b := (b shl BitPos) and $FF;
    b := b shr (8 - take);
    Dec(Count, take);
    res := (res shl take) or b;
    Inc(BitPos, take);
    if BitPos >= 8 then
    begin
      BitPos := 0;
      Inc(BytePos);
    end;
  end;
  Ok := True;
  Result := res;
end;

procedure ParseTheoraIDHeaderFromPacket(const Packet: TBytes; out FRN, FRD: UInt32; out GranuleShift: Integer);
var
  StartOff: Integer;
  br: TBitReader;
  ok: Boolean;
  tmp64: UInt64;
  i: Integer;
begin
  FRN := 0;
  FRD := 0;
  GranuleShift := 0;
  StartOff := -1;
  for i := 0 to Length(Packet)-6 do
    if MatchAsciiAt(Packet, 'theora', i) then
    begin
      StartOff := i;
      Break;
    end;
  if StartOff < 0 then Exit;
  br.Init(Packet, StartOff + 6);
  // read three version bytes
  br.ReadBits(8, ok); if not ok then Exit;
  br.ReadBits(8, ok); if not ok then Exit;
  br.ReadBits(8, ok); if not ok then Exit;
  // skip fields until FRN/FRD per spec
  br.ReadBits(16, ok); if not ok then Exit; // FMBW
  br.ReadBits(16, ok); if not ok then Exit; // FMBH
  br.ReadBits(32, ok); if not ok then Exit; // NSBS
  br.ReadBits(36, ok); if not ok then Exit; // NBS
  br.ReadBits(32, ok); if not ok then Exit; // NMBS
  br.ReadBits(20, ok); if not ok then Exit; // PICW
  br.ReadBits(20, ok); if not ok then Exit; // PICH
  br.ReadBits(8, ok);  if not ok then Exit; // PICX
  br.ReadBits(8, ok);  if not ok then Exit; // PICY
  tmp64 := br.ReadBits(32, ok); if not ok then Exit; FRN := UInt32(tmp64);
  tmp64 := br.ReadBits(32, ok); if not ok then Exit; FRD := UInt32(tmp64);
  br.ReadBits(24, ok); if not ok then Exit; // PARN
  br.ReadBits(24, ok); if not ok then Exit; // PARD
  br.ReadBits(8, ok);  if not ok then Exit; // CS
  br.ReadBits(2, ok);  if not ok then Exit; // PF
  br.ReadBits(24, ok); if not ok then Exit; // NOMBR
  br.ReadBits(6, ok);  if not ok then Exit; // QUAL
  tmp64 := br.ReadBits(5, ok);  if not ok then Exit; // KFGSHIFT
  GranuleShift := Integer(tmp64);
end;

{ Parse FLAC STREAMINFO inside OggFlac packet (get sample rate & total samples) }
procedure ParseFlacStreamInfoFromPacket(const Packet: TBytes; out SampleRate: Integer; out TotalSamples: Int64);
var
  pktlen: Integer;
  p: Integer;
  metaType: Integer;
  metaLen: Integer;
  B: TBytes;
begin
  SampleRate := 0;
  TotalSamples := 0;
  pktlen := Length(Packet);
  if pktlen < 4 then Exit; // need 'fLaC'
  p := 4; // metadata blocks start after 'fLaC'
  while p + 4 <= pktlen do
  begin
    metaType := Packet[p] and $7F;
    metaLen := (Packet[p+1] shl 16) or (Packet[p+2] shl 8) or (Packet[p+3]);
    Inc(p, 4);
    if (p + metaLen > pktlen) then Exit;
    if metaType = 0 then
    begin
      if metaLen < 34 then Exit;
      SetLength(B, 34);
      Move(Packet[p], B[0], 34);
      // sample rate: 20 bits starting at B[10]..B[12]
      SampleRate := (Integer(B[10]) shl 12) or (Integer(B[11]) shl 4) or (Integer(B[12]) shr 4);
      // total samples: 36 bits: low 4 bits of B[12] and B[13..16]
      TotalSamples := (Int64(B[12] and $0F) shl 32) or (Int64(B[13]) shl 24) or (Int64(B[14]) shl 16) or (Int64(B[15]) shl 8) or Int64(B[16]);
      Exit;
    end
    else
      Inc(p, metaLen);
    if (Packet[p-4] and $80) <> 0 then Break; // last-metadata-block flag set
  end;
end;

{ Theora frame index from granule pos                                         }
function TheoraFrameIndexFromGranulePos(GranulePos: UInt64; GranuleShift: Integer): UInt64;
var
  mask, upper, lower: UInt64;
begin
  if GranuleShift < 0 then GranuleShift := 0;
  if GranuleShift > 63 then GranuleShift := 63;
  mask := (UInt64(1) shl GranuleShift) - 1;
  upper := GranulePos shr GranuleShift;
  lower := GranulePos and mask;
  Result := upper + lower;
end;

{ Main: ReadOGG                                                               }
class function TOGGReader.ReadOGG(const FileName: string): TOGGInfo;
var
  FS: TFileStream;
  H: TOGGPageHeader;
  SegSizes: TBytes;
  TotalSegSize: Integer;
  Packet: TBytes;
  i: Integer;
  Codec: string;
  // local codec-specific values (kept local per your request)
  VorbisSampleRate: Integer;
  OpusPreSkip: Integer;
  TheoraFRN, TheoraFRD: UInt32;
  TheoraGranuleShift: Integer;
  FlacSampleRate: Integer;
  FlacTotalSamples: Int64;
  // last granule positions
  LastVorbisGranule: Int64;
  LastOpusGranule: Int64;
  LastTheoraGranule: Int64;
  LastFlacGranule: Int64;
  tmpAscii: string;
begin
  FillChar(Result, SizeOf(Result), 0);
  VorbisSampleRate := 0;
  OpusPreSkip := 0;
  TheoraFRN := 0; TheoraFRD := 0; TheoraGranuleShift := 0;
  FlacSampleRate := 0; FlacTotalSamples := 0;
  LastVorbisGranule := -1;
  LastOpusGranule := -1;
  LastTheoraGranule := -1;
  LastFlacGranule := -1;
  Codec := '';
  if not FileExists(FileName) then Exit;
  FS := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    while FS.Position < FS.Size do
    begin
      if not ReadPageHeader(FS, H) then Break;
      // read segment table
      SetLength(SegSizes, H.SegCount);
      if H.SegCount > 0 then
        FS.Read(SegSizes[0], H.SegCount);
      TotalSegSize := 0;
      for i := 0 to High(SegSizes) do
        Inc(TotalSegSize, SegSizes[i]);
      // read packet bytes
      SetLength(Packet, TotalSegSize);
      if TotalSegSize > 0 then
        FS.Read(Packet[0], TotalSegSize);
      // update last granule heuristics
      if H.GranulePos >= 0 then
      begin
        if Codec = '' then
        begin
          LastVorbisGranule := H.GranulePos;
          LastOpusGranule := H.GranulePos;
          LastTheoraGranule := H.GranulePos;
          LastFlacGranule := H.GranulePos;
        end
        else
        begin
          if Codec = 'vorbis' then LastVorbisGranule := H.GranulePos;
          if Codec = 'opus' then LastOpusGranule := H.GranulePos;
          if Codec = 'theora' then LastTheoraGranule := H.GranulePos;
          if Codec = 'flac' then LastFlacGranule := H.GranulePos;
        end;
      end;
      // if codec unknown, try detect from this packet
      if Codec = '' then
      begin
        Codec := DetectCodecFromPacket(Packet);
        if Codec = 'vorbis' then
        begin
          if (Length(Packet) > 0) and (Packet[0] = 1) then
            VorbisSampleRate := ParseVorbisSampleRateFromPacket(Packet);
        end
        else if Codec = 'opus' then
        begin
          OpusPreSkip := ParseOpusPreSkipFromPacket(Packet);
        end
        else if Codec = 'theora' then
        begin
          ParseTheoraIDHeaderFromPacket(Packet, TheoraFRN, TheoraFRD, TheoraGranuleShift);
        end
        else if Codec = 'flac' then
        begin
          ParseFlacStreamInfoFromPacket(Packet, FlacSampleRate, FlacTotalSamples);
        end;
        Continue; // next page
      end;
      // Try parse comments (VorbisComment / OpusTags / Theora comment / Ogg-FLAC VorbisComment)
      if Length(Packet) > 0 then
      begin
        // quick ASCII view for searching tokens
        tmpAscii := TEncoding.ASCII.GetString(Packet);
        // OpusTags
        if (Length(Packet) >= 8) and MatchAsciiAt(Packet, 'OpusTags', 0) then
          ParseVorbisCommentFromPacket(Packet, Result)
        else if Pos('vorbis', tmpAscii) > 0 then
          ParseVorbisCommentFromPacket(Packet, Result)
        else
        begin
          // For Ogg-FLAC the VorbisComment may be inside the fLaC packet - still attempt parse
          if Codec = 'flac' then
            ParseVorbisCommentFromPacket(Packet, Result)
          else if Codec = 'theora' then
            ParseVorbisCommentFromPacket(Packet, Result);
        end;
      end;
    end; // while FS.Position < FS.Size
    // compute duration based on detected codec
    if Codec = 'vorbis' then
    begin
      if (VorbisSampleRate > 0) and (LastVorbisGranule >= 0) then
        Result.Duration := LastVorbisGranule / VorbisSampleRate
      else if LastVorbisGranule >= 0 then
        Result.Duration := LastVorbisGranule / 44100;
    end
    else if Codec = 'opus' then
    begin
      if LastOpusGranule < 0 then
        Result.Duration := 0
      else if LastOpusGranule > OpusPreSkip then
        Result.Duration := (LastOpusGranule - OpusPreSkip) / 48000
      else
        Result.Duration := LastOpusGranule / 48000;
    end
    else if Codec = 'theora' then
    begin
      if (TheoraFRN <> 0) and (TheoraFRD <> 0) and (LastTheoraGranule >= 0) then
        Result.Duration := (TheoraFrameIndexFromGranulePos(UInt64(LastTheoraGranule), TheoraGranuleShift) * TheoraFRD) / TheoraFRN
      else
        Result.Duration := 0;
    end
    else if Codec = 'flac' then
    begin
      if (FlacSampleRate > 0) and (FlacTotalSamples > 0) then
        Result.Duration := FlacTotalSamples / FlacSampleRate
      else if LastFlacGranule > 0 then
        Result.Duration := LastFlacGranule / 44100
      else
        Result.Duration := 0;
    end
    else
    begin
      // unknown codec fallback attempt
      if LastVorbisGranule >= 0 then
        Result.Duration := LastVorbisGranule / 44100
      else
        Result.Duration := 0;
    end;
  finally
    FS.Free;
  end;
end;

end.

