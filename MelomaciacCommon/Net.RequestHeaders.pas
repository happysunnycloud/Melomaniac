unit Net.RequestHeaders;

interface

type
  TRequestHeader = (
    rqPlay = 0,
    rqVolumeUp = 1,
    rqVolumeDown = 2,
    rqCurrentPlayState = 3,
    rqNext = 4,
    rqPrev = 5,
    rqNextNSecs = 6,
    rqPrevNSecs = 7,
    rqStopRewind = 8,

    rqGetTestString = 999
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
    rqVolumeUp: Result := 'VolumeUp';
    rqVolumeDown: Result := 'VolumeDown';
    rqCurrentPlayState: Result := 'CurrentPlayState';
    rqNext: Result := 'Next';
    rqPrev: Result := 'Prev';
    rqNextNSecs: Result := 'NextNSecs';
    rqPrevNSecs: Result := 'PrevNSecs';
    rqStopRewind: Result := 'StopRewind';

    rqGetTestString: Result := 'GetTestString';
  end;
end;

procedure TRequestHeaderHelper.FromInteger(const AVal: Integer);
begin
  case AVal of
    Integer(rqPlay): Self := rqPlay;
    Integer(rqVolumeUp): Self := rqVolumeUp;
    Integer(rqVolumeDown): Self := rqVolumeDown;
    Integer(rqCurrentPlayState): Self := rqCurrentPlayState;
    Integer(rqNext): Self := rqNext;
    Integer(rqPrev): Self := rqPrev;
    Integer(rqNextNSecs): Self := rqNextNSecs;
    Integer(rqPrevNSecs): Self := rqPrevNSecs;
    Integer(rqStopRewind): Self := rqStopRewind;

    Integer(rqGetTestString): Self := rqGetTestString;
  else
    raise Exception.Create('Invalid value');
  end;
end;

end.
