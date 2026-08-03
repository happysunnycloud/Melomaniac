unit AudioFormatDetectorUnit;

interface

uses
  System.SysUtils, System.Classes;

type
  TAudioFormat = (
    afUnknown,
    afMP3,
    afOGG,
    afFLAC,
    afWAV,
    afAIFF,
    afAAC,
    afM4A,
    afWMA,
    afAMR
  );

  TAudioFormatHelper = record helper for TAudioFormat
  public
    function ToStr: String;
  end;

function DetectAudioFormat(const FileName: String): TAudioFormat;

implementation

{ TAudioFormatHelper }

function TAudioFormatHelper.ToStr: String;
begin
  case Self of
    afUnknown: Result := 'Unknown';
    afMP3: Result := 'MP3';
    afOGG: Result := 'OGG';
    afFLAC: Result := 'FLAC';
    afWAV: Result := 'WAV';
    afAIFF: Result := 'AIFF';
    afAAC: Result := 'AAC';
    afM4A: Result := 'M4A';
    afWMA: Result := 'WMA';
    afAMR: Result := 'AMR';
    else
      Result := 'Fault';
  end;
end;

function ReadBytes(const FS: TFileStream; Count: Integer): TBytes;
begin
  SetLength(Result, Count);
  if FS.Read(Result[0], Count) <> Count then
    SetLength(Result, 0);
end;

function IsMP3(const FS: TFileStream): Boolean;
var
  B: TBytes;
  P: Int64;
  Header: array[0..3] of Byte;
  BitrateIndex, SampIndex, LayerBits: Integer;
  FramesFound: Integer;
begin
  Result := False;
  FramesFound := 0;
  // Пропускаем ID3v2
  FS.Position := 0;
  B := ReadBytes(FS, 10);
  if (Length(B) = 10) and (B[0] = Ord('I')) and (B[1] = Ord('D')) and (B[2] = Ord('3')) then
  begin
    // sync-safe размер
    P :=
      (B[6] shl 21) or
      (B[7] shl 14) or
      (B[8] shl 7)  or
       B[9];
    FS.Position := 10 + P;
  end
  else
    FS.Position := 0;
  // Ищем MPEG фреймы
  while FS.Position < FS.Size - 4 do
  begin
    if FS.Read(Header, 4) <> 4 then Break;
    if (Header[0] = $FF) and ((Header[1] and $E0) = $E0) then
    begin
      LayerBits := (Header[1] shr 1) and $03;
      if LayerBits <> 1 then
      begin
        FS.Position := FS.Position - 3;
        Continue;
      end;
      BitrateIndex := (Header[2] shr 4) and $0F;
      SampIndex := (Header[2] shr 2) and $03;
      if (BitrateIndex in [1..14]) and (SampIndex <= 2) then
      begin
        Inc(FramesFound);
        if FramesFound >= 3 then
          Exit(True);
        // простой шаг вперёд — MPEG фрейм ≈ 417–1441 байт
        FS.Position := FS.Position + 300;
        Continue;
      end;
    end;
    FS.Position := FS.Position - 3;
  end;
end;

function DetectAudioFormat(const FileName: String): TAudioFormat;
var
  FS: TFileStream;
  B: TBytes;
begin
  Result := afUnknown;

  if not FileExists(FileName) then
    Exit;

  FS := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    B := ReadBytes(FS, 12);
    if Length(B) < 4 then Exit;
    // ---------------- WAV (RIFF/WAVE) ----------------
    if (B[0] = Ord('R')) and (B[1] = Ord('I')) and (B[2] = Ord('F')) and (B[3] = Ord('F')) and
       (B[8] = Ord('W')) and (B[9] = Ord('A')) and (B[10] = Ord('V')) and (B[11] = Ord('E')) then
      Exit(afWAV);
    // ---------------- AIFF ----------------
    if (B[0] = Ord('F')) and (B[1] = Ord('O')) and (B[2] = Ord('R')) and (B[3] = Ord('M')) and
       (B[8] = Ord('A')) and (B[9] = Ord('I')) and (B[10] = Ord('F')) and (B[11] = Ord('F')) then
      Exit(afAIFF);
    // ---------------- FLAC ----------------
    if (B[0] = Ord('f')) and (B[1] = Ord('L')) and (B[2] = Ord('a')) and (B[3] = Ord('C')) then
      Exit(afFLAC);
    // ---------------- OGG ----------------
    if (B[0] = Ord('O')) and (B[1] = Ord('g')) and (B[2] = Ord('g')) and (B[3] = Ord('S')) then
      Exit(afOGG);
    // ---------------- MP4/M4A ----------------
    // Байт 4 может быть размером бокса
    if (B[4] = Ord('f')) and (B[5] = Ord('t')) and (B[6] = Ord('y')) and (B[7] = Ord('p')) then
      Exit(afM4A);
    // ---------------- WMA (ASF) ----------------
    if (B[0] = $30) and (B[1] = $26) and (B[2] = $B2) and (B[3] = $75) then
      Exit(afWMA);
    // ---------------- AMR ----------------
    if (B[0] = $23) and (B[1] = $21) and (B[2] = $41) and (B[3] = $4D) and (B[4] = $52) then
      Exit(afAMR);
    // ---------------- AAC (ADTS) ----------------
    if (B[0] = $FF) and ((B[1] and $F6) = $F0) then
      Exit(afAAC);
    // ---------------- MP3 (строгая проверка) ----------------
    FS.Position := 0;
    if IsMP3(FS) then
      Exit(afMP3);
  finally
    FS.Free;
  end;
end;

end.

