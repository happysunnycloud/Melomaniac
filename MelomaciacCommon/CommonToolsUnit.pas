unit CommonToolsUnit;

interface

type
  TCommonTools = class
  public
    class function CheckCorrectPort(const APort: String): Boolean;
  end;

implementation

uses
    System.SysUtils
  , FMX.Dialogs
  , StringToolsUnit
  ;

{ TCommonTools }

class function TCommonTools.CheckCorrectPort(const APort: String): Boolean;
var
  Port: Word;
begin
  Result := false;

  if Length(Trim(APort)) = 0 then
  begin
    ShowMessage('The "Port" field can not be empty' );

    Exit;
  end;

  if not TStringTools.IsContainsOnlyDigits(APort) then
  begin
    ShowMessage('The "Port" field can only contain numbers' );

    Exit;
  end;

  Port := Word(Trim(APort).ToInteger);

  if not ((Port > 0) and (Port < 65000)) then
  begin
    ShowMessage('The "Port" value out of range. Must be between 1 and 65K' );

    Exit;
  end;

  Result := true;
end;

end.
