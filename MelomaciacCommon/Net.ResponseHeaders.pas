unit Net.ResponseHeaders;

interface

type
  TResponseHeader = (
    rsPlay = 0,
    rsVolumeUp = 1,
    rsVolumeDown = 2,

    rsGetTestString = 999
  );

  TResponseHeaderHelper = record helper for TResponseHeader
  public
    function Code: Integer;
    function Ident: String;
    procedure FromInteger(const AVal: Integer);
  end;

implementation

uses
    System.SysUtils
  ;

{ TResponseHeaderHelper }

function TResponseHeaderHelper.Code: Integer;
begin
  Result := Integer(Self);
end;

function TResponseHeaderHelper.Ident: String;
begin
  case Self of
    rsPlay: Result := 'Play';
    rsVolumeUp: Result := 'VolumeUp';
    rsVolumeDown: Result := 'VolumeDown';

    rsGetTestString: Result := 'GetTestString';
  end;
end;

procedure TResponseHeaderHelper.FromInteger(const AVal: Integer);
begin
  case AVal of
    Integer(rsPlay): Self := rsPlay;
    Integer(rsVolumeUp): Self := rsVolumeUp;
    Integer(rsVolumeDown): Self := rsVolumeDown;

    Integer(rsGetTestString): Self := rsGetTestString;
  else
    raise Exception.Create('Invalid value');
  end;
end;

end.
