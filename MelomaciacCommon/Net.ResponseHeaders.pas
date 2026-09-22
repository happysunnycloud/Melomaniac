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
    rsGetPlayList = 9,
    rsSetCurrentComposition = 10,

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
    rsGetPlayList: Result := 'GetPlayList';
    rsSetCurrentComposition: Result := 'SetCurrentComposition';

    rsGetTestString: Result := 'GetTestString';
  end;
end;

procedure TResponseHeaderHelper.FromInteger(const AVal: Integer);
begin
  case AVal of
    Integer(rsPlay),
    Integer(rsVolumeUp),
    Integer(rsVolumeDown),
    Integer(rsNext),
    Integer(rsPrev),
    Integer(rsCurrentPlayState),
    Integer(rsNextNSecs),
    Integer(rsPrevNSecs),
    Integer(rsStopRewind),
    Integer(rsGetPlayList),
    Integer(rsSetCurrentComposition),
    //
    Integer(rsGetTestString):
      Self := TResponseHeader(AVal);
  else
    raise Exception.Create('Invalid value');
  end;
end;

end.
