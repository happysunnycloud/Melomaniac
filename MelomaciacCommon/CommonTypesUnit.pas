unit CommonTypesUnit;

interface

type
  TPlayState = (psStop, psPlay, psPause);

  TCurrentPlayState = class
  strict private
    FCurrentTime: Int64;
    FDuration: Int64;
    FComposition: String;
    FVolume: Single;
    FPlayState: TPlayState;
  public
    property CurrentTime: Int64 read FCurrentTime write FCurrentTime;
    property Duration: Int64 read FDuration write FDuration;
    property Composition: String read FComposition write FComposition;
    property Volume: Single read FVolume write FVolume;
    property PlayState: TPlayState read FPlayState write FPlayState;
  end;

  TPlayStateHelper = record helper for TPlayState
  public
    function ToInt: Integer;
    function ToStr: String;
  end;

implementation

uses
    System.SysUtils
  ;

{ TPlayStateHelper }

function TPlayStateHelper.ToInt: Integer;
begin
  Result := Integer(Self);
end;

function TPlayStateHelper.ToStr: String;
begin
  case Self of
    psStop: Result := 'Stop';
    psPlay: Result := 'Play';
    psPause: Result := 'Pause';
  else
    raise Exception.Create('Unknown type');
  end;
end;


end.
