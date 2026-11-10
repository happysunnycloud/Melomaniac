unit CommonTypesUnit;

interface

uses
    System.Generics.Collections
  ;

type
  TPlayState = (psStop, psPlay, psPause);
  TRewindDirection = (rdNone, rdForward, rdBackward);

  TPlayItem = class
  strict private
    FTitle: String;
    FArtist: String;
    FAlbum: String;
    FYear: String;
    FDuration: Int64; // в секундах
    FPath: String;
    FMD5: String;
    FSHA256: String;
    FFileSize: Int64;
  public
    constructor Create;

    property Title: String read FTitle write FTitle;
    property Artist: String read FArtist  write FArtist;
    property Album: String read FAlbum write FAlbum;
    property Year: String read FYear write FYear;
    property Duration: Int64 read FDuration write FDuration;
    property Path: String read FPath write FPath;
    property MD5: String read FMD5 write FMD5;
    property SHA256: String read FSHA256 write FSHA256;
    property FileSize: Int64 read FFileSize write FFileSize;
  end;


  // Не делаем класс, расширяем хэлпер TPlayItemsListHelper
  TPlayItemsList = TList<TPlayItem>;

  TCurrentPlayState = class
  strict private
    FCurrentTime: Int64;
    FDuration: Int64;
    FComposition: String;
    FVolume: Single;
    FPlayState: TPlayState;
    FRewindDirection: TRewindDirection;
  public
    property CurrentTime: Int64 read FCurrentTime write FCurrentTime;
    property Duration: Int64 read FDuration write FDuration;
    property Composition: String read FComposition write FComposition;
    property Volume: Single read FVolume write FVolume;
    property PlayState: TPlayState read FPlayState write FPlayState;
    property RewindDirection: TRewindDirection
      read FRewindDirection write FRewindDirection;
  end;

  TPlayStateHelper = record helper for TPlayState
  public
    function ToInt: Integer;
    function ToStr: String;
  end;

  TPlayItemsListHelper = class helper for TPlayItemsList
  public
    procedure Clear;
    function IndexOfComposition(const ACompositionPath: String): Integer;
  end;

implementation

uses
    System.SysUtils
  ;

{ TPlayItem }

constructor TPlayItem.Create;
begin
  FTitle := '';
  FArtist := '';
  FAlbum := '';
  FYear := '';
  FDuration := 0;
  FPath := '';
  FMD5 := '';
  FSHA256 := '';
  FFileSize := 0;
end;

{ TPlayItemsListHelper }

procedure TPlayItemsListHelper.Clear;
begin
  while Self.Count > 0 do
  begin
    Self[0].Free;
    Delete(0);
  end;
end;

function TPlayItemsListHelper.IndexOfComposition(
  const ACompositionPath: String): Integer;
var
  PlayItem: TPlayItem;
begin
  Result := -1;

  for PlayItem in Self do
  begin
    if PlayItem.Path = ACompositionPath then
    begin
      Exit(IndexOf(PlayItem));
    end;
  end;
end;

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
