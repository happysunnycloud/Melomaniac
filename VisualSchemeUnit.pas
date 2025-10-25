unit VisualSchemeUnit;

interface

uses
    FMX.Controls
  , FMX.MultiResBitmapsUnit
  , FMX.FormExtUnit
  , BitmapStorageUnit
  ;

type
  TVisualScheme = class
  strict private
    class var FMultiResBitmaps: TMultiResBitmaps;
    class var FBitmapStorage: TBitmapStorage;

    class function GetSchemeFileName(const ASchemeName: String): String;
  public
    class procedure Init;
    class procedure UnInit;

    class procedure Load(const AForm: TFormExt; const ASchemeName: String);
    class procedure AssignBitmap(
      const AControl: TControl;
      const ABitMapIdent: String);

    class property BitmapStorage: TBitmapStorage read FBitmapStorage;
  end;

implementation

uses
    System.SysUtils
  , FMX.MultiResBitmapExtractorUnit
  , FMX.ControlToolsUnit
  , FMX.Graphics
  , FMX.Objects
  , ConstantsUnit
  ;

{ TVisualScheme }

class procedure TVisualScheme.Init;
begin
  FMultiResBitmaps := TMultiResBitmaps.Create;
  FBitmapStorage := TBitmapStorage.Create;
end;

class procedure TVisualScheme.UnInit;
begin
  FreeAndNil(FMultiResBitmaps);
  FreeAndNil(FBitmapStorage);
end;

class function TVisualScheme.GetSchemeFileName(
  const ASchemeName: String): String;
var
  RootName: String;
begin
  RootName := 'PCKs';
  {$IFDEF DEBUG}
  Result := Format('..\..\%s', [RootName]);
  {$ELSE}
  Result := Format('%s', [RootName]);
  {$ENDIF}
  Result := Concat(Result, '\', ASchemeName, '.pck');

  if not FileExists(Result) then
    raise Exception.
      CreateFmt('TVisualScheme.GetSchemeFileName -> File "%s" not exists',
      [Result]);
end;

class procedure TVisualScheme.Load(
  const AForm: TFormExt;
  const ASchemeName: String);
var
  ResBitmapList: TResBitmapList;
  BitmapExt: TBitmapExt;
  SourceBitmap: TBitmap;
begin
  TMultiResBitmapExtractor.Extract(
    GetSchemeFileName(ASchemeName),
    FMultiResBitmaps);

  ResBitmapList := FMultiResBitmaps.FindResBitmapListByIdent('');

  TControlTools.ControlEnumerator(AForm,
    procedure (const AControl: TControl)
    var
      ControlName: String;
      Bitmap: TBitmap;
    begin
      ControlName :=
        StringReplace(AControl.Name, CONTROL_NAME_TAIL, '', [rfReplaceAll, rfIgnoreCase]);

      Bitmap := ResBitmapList.FindBitmapByIden(ControlName);
      if not Assigned(Bitmap) then
        Exit;

      if AControl is TRectangle then
        TRectangle(AControl).Fill.Bitmap.Bitmap.Assign(Bitmap);
    end
  );

  for BitmapExt in FBitmapStorage.Values do
  begin
    SourceBitmap := ResBitmapList.FindBitmapByIden(BitmapExt.Ident);

    if not Assigned(SourceBitmap) then
      Continue;

    BitmapExt.Assign(SourceBitmap);
  end;
end;

class procedure TVisualScheme.AssignBitmap(
  const AControl: TControl;
  const ABitMapIdent: String);
var
  PropertyIdent: String;
  BitMapExt: TBitmapExt;
begin
  PropertyIdent := TProperties.Fill;
  if not TControlTools.HasProperty(AControl, PropertyIdent) then
    raise Exception.
      CreateFmt('TVisualScheme.AssignBitmap -> AControl "%s" has not "%s" property',
      [AControl.Name, TProperties.Fill]);

  FBitmapStorage.TryGetValue(ABitMapIdent, BitMapExt);

  TShape(AControl).Fill.Bitmap.Bitmap.Assign(TBitmap(BitMapExt));
end;


end.
