unit Net.ResponseHeaders;

interface

type
  TResponseHeader = (
    rsPlay = 0,
    rsVolumeUp = 1,
    rsVolumeDown = 2,
    rsCurrentPlayState = 3,
    rsNext = 4,
    rsPrev = 5,
    rsNextNSecs = 6,
    rsPrevNSecs = 7,
    rsStopRewind = 8,

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
    rsNext: Result := 'Next';
    rsPrev: Result := 'Prev';
    rsCurrentPlayState: Result := 'CurrentPlayState';
    rsNextNSecs: Result := 'NextNSecs';
    rsPrevNSecs: Result := 'PrevNSecs';
    rsStopRewind: Result := 'StopRewind';

    rsGetTestString: Result := 'GetTestString';
  end;
end;

procedure TResponseHeaderHelper.FromInteger(const AVal: Integer);
begin
  case AVal of
    Integer(rsPlay): Self := rsPlay;
    Integer(rsVolumeUp): Self := rsVolumeUp;
    Integer(rsVolumeDown): Self := rsVolumeDown;
    Integer(rsNext): Self := rsNext;
    Integer(rsPrev): Self := rsPrev;
    Integer(rsCurrentPlayState): Self := rsCurrentPlayState;
    Integer(rsNextNSecs): Self := rsNextNSecs;
    Integer(rsPrevNSecs): Self := rsPrevNSecs;
    Integer(rsStopRewind): Self := rsStopRewind;

    Integer(rsGetTestString): Self := rsGetTestString;
  else
    raise Exception.Create('Invalid value');
  end;
end;

end.
