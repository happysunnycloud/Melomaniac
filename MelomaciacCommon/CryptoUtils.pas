unit CryptoUtils;

{
  Юнит содержит:
    1. EncryptString  — шифрование строки (XOR + Base64)
       DecryptString  — обратная операция (расшифровка)
    2. GetStringHash   — получение SHA-256 хэша строки (в hex-виде)

  ВАЖНО:
    XOR-шифрование с Base64-кодированием — простой обратимый способ
    "спрятать" строку (например, конфиг, пароль в файле настроек и т.п.).
    Это НЕ криптостойкий алгоритм в смысле современных стандартов.
    Если нужна серьёзная защита (пароли, платёжные данные и т.п.),
    используйте настоящий AES, например через библиотеку DCPcrypt2
    или Windows CryptoAPI (Winapi.Wincrypt).
}

interface

uses
  System.SysUtils,
  System.Hash,
  System.NetEncoding;

const
  // Ключ шифрования по умолчанию.
  // Обязательно замените на свой перед использованием в проекте!
  DEFAULT_CRYPTO_KEY = 'Ch@ngeMe-Secret-Key-2026';

type
  TCryptoUtils = class
  strict private
    class function XORTransform(const AInput, AKey: string): TBytes;
  public
    /// <summary>Шифрует строку ключом по умолчанию. Результат — Base64.</summary>
    class function EncryptString(const AInput: string): string; overload;

    /// <summary>Шифрует строку заданным ключом. Результат — Base64.</summary>
    class function EncryptString(const AInput, AKey: string): string; overload;

    /// <summary>Расшифровывает строку, полученную EncryptString, ключом по умолчанию.</summary>
    class function DecryptString(const AInput: string): string; overload;

    /// <summary>Расшифровывает строку, полученную EncryptString, заданным ключом.</summary>
    class function DecryptString(const AInput, AKey: string): string; overload;

    /// <summary>Возвращает SHA-256 хэш строки в шестнадцатеричном виде.</summary>
    class function GetStringHash(const AInput: string): string;
  end;

implementation

{ TCryptoUtils }

{ Побайтовое XOR-преобразование строки относительно ключа }
class function TCryptoUtils.XORTransform(const AInput, AKey: string): TBytes;
var
  InputBytes, KeyBytes: TBytes;
  I, KeyLen: Integer;
begin
  if AKey = '' then
    raise Exception.Create('Ключ шифрования не может быть пустым');

  InputBytes := TEncoding.UTF8.GetBytes(AInput);
  KeyBytes := TEncoding.UTF8.GetBytes(AKey);
  KeyLen := Length(KeyBytes);

  SetLength(Result, Length(InputBytes));
  for I := 0 to High(InputBytes) do
    Result[I] := InputBytes[I] xor KeyBytes[I mod KeyLen];
end;

class function TCryptoUtils.EncryptString(const AInput, AKey: string): string;
var
  XoredBytes: TBytes;
begin
  XoredBytes := XORTransform(AInput, AKey);
  Result := TNetEncoding.Base64.EncodeBytesToString(XoredBytes);
end;

class function TCryptoUtils.EncryptString(const AInput: string): string;
begin
  Result := EncryptString(AInput, DEFAULT_CRYPTO_KEY);
end;

class function TCryptoUtils.DecryptString(const AInput, AKey: string): string;
var
  DecodedBytes: TBytes;
  XoredBack: TBytes;
  KeyBytes: TBytes;
  I, KeyLen: Integer;
begin
  if AKey = '' then
    raise Exception.Create('Ключ шифрования не может быть пустым');

  DecodedBytes := TNetEncoding.Base64.DecodeStringToBytes(AInput);
  KeyBytes := TEncoding.UTF8.GetBytes(AKey);
  KeyLen := Length(KeyBytes);

  SetLength(XoredBack, Length(DecodedBytes));
  for I := 0 to High(DecodedBytes) do
    XoredBack[I] := DecodedBytes[I] xor KeyBytes[I mod KeyLen];

  Result := TEncoding.UTF8.GetString(XoredBack);
end;

class function TCryptoUtils.DecryptString(const AInput: string): string;
begin
  Result := DecryptString(AInput, DEFAULT_CRYPTO_KEY);
end;

class function TCryptoUtils.GetStringHash(const AInput: string): string;
begin
  Result := THashSHA2.GetHashString(AInput, THashSHA2.TSHA2Version.SHA256);
end;

end.
