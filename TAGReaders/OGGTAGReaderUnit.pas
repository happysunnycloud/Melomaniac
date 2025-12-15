unit OGGTAGReaderUnit;

interface
uses
  System.SysUtils,
  System.Classes;
type
  TOGGInfo = record
    Title: string;
    Artist: string;
    Album: string;
    Year: string;
    Comment: string;
    Genre: string;      // VorbisComment (string by spec)
  end;
  TOGGReader = class
  public
    class function ReadOGG(const FileName: string): TOGGInfo;
  end;
implementation
type
  TOGGPageHeader = packed record
    Capture: array[0..3] of AnsiChar; // "OggS"
    Version: Byte;
    HeaderType: Byte;
    GranulePos: Int64;
    Serial: Cardinal;
    SeqNo: Cardinal;
    CRC: Cardinal;
    SegCount: Byte;
  end;
{ ============================================================
  Low level helpers
============================================================ }
function ReadPageHeader(Stream: TStream; var H: TOGGPageHeader): Boolean;
begin
  Result := False;
  if Stream.Read(H, SizeOf(H)) <> SizeOf(H) then Exit;
  if (H.Capture[0] <> 'O') or (H.Capture[1] <> 'g') or
     (H.Capture[2] <> 'g') or (H.Capture[3] <> 'S') then Exit;
  Result := True;
end;
function ReadSegments(Stream: TStream; Count: Integer; out Data: TBytes): Integer;
var
  Segs: TBytes;
  i, Total: Integer;
begin
  Total := 0;
  SetLength(Segs, Count);
  Stream.ReadBuffer(Segs[0], Count);
  for i := 0 to Count - 1 do
    Inc(Total, Segs[i]);
  SetLength(Data, Total);
  if Total > 0 then
    Stream.ReadBuffer(Data[0], Total);
  Result := Total;
end;
function MatchAscii(const Buf: TBytes; const S: AnsiString; Offset: Integer): Boolean;
var
  i: Integer;
begin
  Result := False;
  if Offset + Length(S) > Length(Buf) then Exit;
  for i := 1 to Length(S) do
    if Buf[Offset + i - 1] <> Ord(S[i]) then Exit;
  Result := True;
end;
{ ============================================================
  VorbisComment (Vorbis / Opus / Theora / Ogg-FLAC)
============================================================ }
procedure ParseVorbisComment(const Packet: TBytes; var Info: TOGGInfo);
var
  p, VendorLen, Count, L, Eq: Integer;
  Key, Val, S: string;
  tmp: Cardinal;
  Data: TBytes;
begin
  p := -1;
  for L := 0 to Length(Packet) - 6 do
    if MatchAscii(Packet, 'vorbis', L) then
    begin
      p := L + 6;
      Break;
    end;
  if p < 0 then Exit;
  tmp := PCardinal(@Packet[p])^;
  VendorLen := tmp;
  Inc(p, 4 + VendorLen);
  tmp := PCardinal(@Packet[p])^;
  Count := tmp;
  Inc(p, 4);
  while (Count > 0) and (p + 4 <= Length(Packet)) do
  begin
    L := PCardinal(@Packet[p])^;
    Inc(p, 4);
    if p + L > Length(Packet) then Break;
    SetLength(Data, L);
    Move(Packet[p], Data[0], L);
    S := TEncoding.UTF8.GetString(Data);
    Inc(p, L);
    Eq := Pos('=', S);
    if Eq > 0 then
    begin
      Key := UpperCase(Copy(S, 1, Eq - 1));
      Val := Copy(S, Eq + 1, MaxInt);
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
{ ============================================================
  Public API
============================================================ }
class function TOGGReader.ReadOGG(const FileName: string): TOGGInfo;
var
  FS: TFileStream;
  H: TOGGPageHeader;
  Packet: TBytes;
begin
  FillChar(Result, SizeOf(Result), 0);
  if not FileExists(FileName) then Exit;
  FS := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
//    Result.Duration := GetOGGDuration(FS);
    FS.Position := 0;
    while FS.Position < FS.Size do
    begin
      if not ReadPageHeader(FS, H) then Break;
      ReadSegments(FS, H.SegCount, Packet);
      ParseVorbisComment(Packet, Result);
    end;
  finally
    FS.Free;
  end;
end;
end.

