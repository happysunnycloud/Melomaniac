unit BitmapStorageUnit;

interface

uses
    System.Generics.Collections
  , FMX.Graphics
  , FMX.MultiResBitmapsUnit
  ;

type
  TBitmapStorage = class(TDictionary<String, TBitmapExt>)
  strict private
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
    System.SysUtils
  , ConstantsUnit
  ;

{ TBitmapStorage }

constructor TBitmapStorage.Create;
var
  BitmapExt: TBitmapExt;
begin
  inherited;

  BitmapExt := TBitmapExt.Create;
  BitmapExt.Ident := BITMAP_PLAY_IDENT;
  TryAdd(BitmapExt.Ident, BitmapExt);

  BitmapExt := TBitmapExt.Create;
  BitmapExt.Ident := BITMAP_PAUSE_IDENT;
  TryAdd(BitmapExt.Ident, BitmapExt);

  BitmapExt := TBitmapExt.Create;
  BitmapExt.Ident := BITMAP_SOUND_IDENT;
  TryAdd(BitmapExt.Ident, BitmapExt);

  BitmapExt := TBitmapExt.Create;
  BitmapExt.Ident := BITMAP_MUTE_IDENT;
  TryAdd(BitmapExt.Ident, BitmapExt);
end;

destructor TBitmapStorage.Destroy;
var
  BitmapExt: TBitmapExt;
begin
  for BitmapExt in Values do
  begin
     FreeAndNil(BitmapExt);
  end;

  inherited;
end;

end.

