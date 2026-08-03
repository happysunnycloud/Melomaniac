unit Net.RequestHeaders;

interface

type
  TRequestHeader = (
    rqPlay = 0
  );

  TRequestHeaderHelper = record helper for TRequestHeader
  public
    function Code: Integer;
    function Ident: String;
    procedure FromInteger(const AVal: Integer);
  end;

implementation

uses
    System.SysUtils
  ;

{ TRequestHeaderHelper }

function TRequestHeaderHelper.Code: Integer;
begin
  Result := Integer(Self);
end;

function TRequestHeaderHelper.Ident: String;
begin
  case Self of
    rqPlay: Result := 'Play';
  end;
end;

procedure TRequestHeaderHelper.FromInteger(const AVal: Integer);
begin
  case AVal of
    Integer(rqPlay): Self := rqPlay;
  else
    raise Exception.Create('Invalid value');
  end;
end;

end.
