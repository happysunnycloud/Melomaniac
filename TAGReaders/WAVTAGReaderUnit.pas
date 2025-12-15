unit WavTAGReaderUnit;

interface

uses
  System.Classes, System.SysUtils;

type
  TWavInfo = record
    Title: string;
    Artist: string;
    Album: string;
    Year: string;
    Comment: string;
    Genre: string;
  end;

  TWavReader = class
  private
    const
      CChunkHeaderSize = 8; // 4 bytes ID + 4 bytes Size

      CID_RIFF = 'RIFF';
      CID_WAVE = 'WAVE';
      CID_FMT  = 'fmt ';
      CID_DATA = 'data';
      CID_LIST = 'LIST';
      CID_INFO = 'INFO';

    class function ReadChunkID(const S: TStream): string;
    class function ReadUInt32(const S: TStream): Cardinal;
//    class function ReadUInt16(const S: TStream): Word;
    class procedure ParseINFOChunk(S: TStream; ChunkSize: Cardinal; var Info: TWavInfo);
  public
    class function ReadWAV(const FileName: string): TWavInfo;
  end;

implementation

class function TWavReader.ReadChunkID(const S: TStream): string;
var
  Buf: array[0..3] of AnsiChar;
begin
  if S.Read(Buf, 4) <> 4 then
    raise Exception.Create('Unexpected end of file while reading chunk ID');
  Result := string(Buf);
end;

class function TWavReader.ReadUInt32(const S: TStream): Cardinal;
begin
  if S.Read(Result, 4) <> 4 then
    raise Exception.Create('Unexpected end of file while reading UInt32');
end;

//class function TWavReader.ReadUInt16(const S: TStream): Word;
//begin
//  if S.Read(Result, 2) <> 2 then
//    raise Exception.Create('Unexpected end of file while reading UInt16');
//end;

class procedure TWavReader.ParseINFOChunk(S: TStream; ChunkSize: Cardinal; var Info: TWavInfo);
var
  EndPos: Int64;
  SubID: string;
  SubSize: Cardinal;
  Buffer: TBytes;
  Txt: string;
begin
  EndPos := S.Position + ChunkSize;

  while S.Position + CChunkHeaderSize <= EndPos do
  begin
    SubID := ReadChunkID(S);
    SubSize := ReadUInt32(S);

    if SubSize > 0 then
    begin
      SetLength(Buffer, SubSize);
      S.Read(Buffer[0], SubSize);
      Txt := string(AnsiString(PAnsiChar(@Buffer[0])));
    end
    else
      Txt := '';

    if SubID = 'INAM' then Info.Title   := Txt else
    if SubID = 'IART' then Info.Artist  := Txt else
    if SubID = 'IPRD' then Info.Album   := Txt else
    if SubID = 'ICRD' then Info.Year    := Txt else
    if SubID = 'ICMT' then Info.Comment := Txt else
    if SubID = 'IGNR' then Info.Genre   := Txt;

    // выравнивание по слову (WAV специфика)
    if (SubSize mod 2) = 1 then
      S.Position := S.Position + 1;
  end;

  S.Position := EndPos;
end;

class function TWavReader.ReadWAV(const FileName: string): TWavInfo;
var
  FS: TFileStream;
  ChunkID: string;
  ChunkSize: Cardinal;
begin
  Result.Title   := '';
  Result.Artist  := '';
  Result.Album   := '';
  Result.Year    := '';
  Result.Comment := '';
  Result.Genre   := '';

  FS := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    // --- RIFF ---
    if ReadChunkID(FS) <> CID_RIFF then
      raise Exception.Create('Not a RIFF file');

    ReadUInt32(FS); // file size (not needed)

    if ReadChunkID(FS) <> CID_WAVE then
      raise Exception.Create('Not a WAVE file');

    // --- Iterate WAV chunks ---

    while FS.Position < FS.Size do
    begin
      ChunkID := ReadChunkID(FS);
      ChunkSize := ReadUInt32(FS);

      if ChunkID = CID_FMT then
      begin
        // пропустить возможные расширенные данные
        if ChunkSize > 16 then
          FS.Position := FS.Position + (ChunkSize - 16);
      end
      else if ChunkID = CID_DATA then
      begin
        FS.Position := FS.Position + ChunkSize;
      end
      else if (ChunkID = CID_LIST) then
      begin
        var ListType := ReadChunkID(FS); // должно быть 'INFO'
        if ListType = CID_INFO then
          ParseINFOChunk(FS, ChunkSize - 4, Result)
        else
          FS.Position := FS.Position + (ChunkSize - 4);
      end
      else
      begin
        FS.Position := FS.Position + ChunkSize;
      end;

      // align
      if (ChunkSize mod 2) = 1 then
        FS.Position := FS.Position + 1;
    end;

  finally
    FS.Free;
  end;
end;

end.

