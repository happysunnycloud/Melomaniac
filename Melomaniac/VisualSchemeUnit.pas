unit VisualSchemeUnit;

interface

uses
    FMX.Controls
  , FMX.Layouts
  , FMX.MultiResBitmapsUnit
  , FMX.FormExtUnit
  , FMX.HintUnit
  , FMX.PopupMenuExt
  , BitmapStorageUnit
  ;

const
  PACKED_IMAGES_FILE = 'Images.pck';
  PACKER_SETTINGS_FILE = 'Settings.thm';

type
  TVisualScheme = class
  strict private
    class var FMultiResBitmaps: TMultiResBitmaps;
    class var FBitmapStorage: TBitmapStorage;
    class var FThemeNames: TArray<String>;

    class function GetSchemeFilesPath: String;
    class function GetSchemeFileName(const ASchemeName: String): String;
  public
    class procedure Init;
    class procedure UnInit;

    class procedure LoadForMainForm(
      const AForm: TFormExt;
      const ASchemeName: String;
      const APlayControl: TControl;
      const ACustomHint: TCustomHint;
      const ALeafePopupMenu: TPopupMenuExt;
      const AMainPopupMenu: TPopupMenuExt;
      const ATrayPopupMenuExt: TPopupMenuExt);
    class procedure LoadForPlayListForm(
      const AForm: TFormExt;
      const ASchemeName: String;
      const AScrollBox: TScrollBox);
    class procedure LoadForSetPasswordForm(
      const ASchemeName: String);
    class procedure AssignBitmap(
      const AControl: TControl;
      const ABitMapIdent: String);

    class property BitmapStorage: TBitmapStorage read FBitmapStorage;
    class property ThemeNames: TArray<String> read FThemeNames;
  end;

implementation

uses
    System.SysUtils
  , System.Classes
  , FMX.MultiResBitmapExtractorUnit
  , ParamsExtractorUnit
  , FMX.ControlToolsUnit
  , FMX.Graphics
  , FMX.Objects
  , ParamsExtUnit
  , ConstantsUnit
  , StateUnit
  , FileToolsUnit
  , PlayListItemFrameUnit
  , SetPasswordFormUnit
  , FMX.Types
  , System.UITypes
  , CommonTypesUnit
  ;

{ TVisualScheme }

class procedure TVisualScheme.Init;
var
  FileNameList: TStringList;
  FileName: String;
  i: Integer;
begin
  FMultiResBitmaps := TMultiResBitmaps.Create;
  FBitmapStorage := TBitmapStorage.Create;

  FileNameList := TStringList.Create;
  try
    TFileTools.GetFileNameList(GetSchemeFilesPath, [THEME_FILE_EXT], FileNameList);
    SetLength(FThemeNames, FileNameList.Count);
    i := 0;
    for FileName in FileNameList do
    begin
      FThemeNames[i] :=
        StringReplace(
          ExtractFileName(FileName),
          '.' + THEME_FILE_EXT, '',
          [rfReplaceAll, rfIgnoreCase]);

      Inc(i);
    end;
  finally
    FreeAndNil(FileNameList);
  end;
end;

class procedure TVisualScheme.UnInit;
begin
  FreeAndNil(FMultiResBitmaps);
  FreeAndNil(FBitmapStorage);
end;

class function TVisualScheme.GetSchemeFilesPath: String;
var
  RootName: String;
begin
  RootName := 'Themes';
  Result := Format('%s', [RootName]);
end;

class function TVisualScheme.GetSchemeFileName(
  const ASchemeName: String): String;
var
  Path: String;
begin
  Path := GetSchemeFilesPath;
  Result := Concat(Path, PATH_SPLITTER, ASchemeName, '.mth');

  if not FileExists(Result) then
    raise Exception.
      CreateFmt('TVisualScheme.GetSchemeFileName -> File "%s" not exists',
      [Result]);
end;

class procedure TVisualScheme.LoadForMainForm(
  const AForm: TFormExt;
  const ASchemeName: String;
  const APlayControl: TControl;
  const ACustomHint: TCustomHint;
  const ALeafePopupMenu: TPopupMenuExt;
  const AMainPopupMenu: TPopupMenuExt;
  const ATrayPopupMenuExt: TPopupMenuExt);
var
  ResBitmapList: TResBitmapList;
  BitmapExt: TBitmapExt;
  SourceBitmap: TBitmap;
  Params: TParamsExt;
  SchemeFileName: String;
  PlayControl: TCircle;
begin
  if not (APlayControl is TCircle) then
    raise Exception.Create('TVisualScheme.Load -> ' +
      'APlayControl is not TCircle class');

  PlayControl := APlayControl as TCircle;

  SchemeFileName := GetSchemeFileName(ASchemeName);

  Params := TParamsExt.Create;
  try
    TParamsExtractor.ExtractToParams(
      SchemeFileName,
      PACKER_SETTINGS_FILE,
      Params);

     AForm.Theme.ParamsToSettings(Params);
  finally
    FreeAndNil(Params);
  end;

  TMultiResBitmapExtractor.Extract(
    SchemeFileName,
    PACKED_IMAGES_FILE,
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

  AForm.Theme.CommonSettings.Container := AForm;
  AForm.Theme.CommonSettings.OnApplyProcRef :=
    procedure (const AControl: TControl; const ACommonSettings: TCommonSettings)
    begin
      ACommonSettings.CustomTextSettings.ApplyTo(AControl);
    end;

  ACustomHint.Theme.CopyFrom(AForm.Theme.HintTheme);
  ALeafePopupMenu.Theme.CopyFrom(AForm.Theme.PopUpMenuTheme);
  AMainPopupMenu.Theme.CopyFrom(AForm.Theme.PopUpMenuTheme);
  ATrayPopupMenuExt.Theme.CopyFrom(AForm.Theme.PopUpMenuTheme);

  AForm.Theme.Apply;

  if TState.PlayState = psPlay then
    TVisualScheme.AssignBitmap(PlayControl, FUNC_IDENT_PLAY)
  else
    TVisualScheme.AssignBitmap(PlayControl, FUNC_IDENT_PAUSE);

  TState.VisualScheme := ASchemeName;
end;

class procedure TVisualScheme.LoadForPlayListForm(
  const AForm: TFormExt;
  const ASchemeName: String;
  const AScrollBox: TScrollBox);
var
  Params: TParamsExt;
  SchemeFileName: String;
begin
  SchemeFileName := GetSchemeFileName(ASchemeName);

  Params := TParamsExt.Create;
  try
    TParamsExtractor.ExtractToParams(
      SchemeFileName,
      PACKER_SETTINGS_FILE,
      Params);

     AForm.Theme.ParamsToSettings(Params);
  finally
    FreeAndNil(Params);
  end;

  AForm.Theme.ItemSettings.Container := AScrollBox;
  AForm.Theme.ItemSettings.OnApplyProcRef :=
    procedure (const AControl: TControl; const AItemSettings: TItemSettings)
    var
      PlayListItemFrame: TPlayListItemFrame;
    begin
      if not (AControl is TPlayListItemFrame) then
        Exit;

      PlayListItemFrame := AControl as TPlayListItemFrame;
      PlayListItemFrame.BackgroundRectangle.Fill.Color :=
        AItemSettings.NormalBackgroundColor;
      PlayListItemFrame.FocusFrameRectangle.Stroke.Color :=
        AItemSettings.FocusFrameColor;

      PlayListItemFrame.NumberLabel.StyledSettings := [];
      PlayListItemFrame.PathLabel.StyledSettings := [];
      PlayListItemFrame.TitleLabel.StyledSettings := [];
      PlayListItemFrame.ArtistLabel.StyledSettings := [];
      PlayListItemFrame.AlbumLabel.StyledSettings := [];
      PlayListItemFrame.DurationLabel.StyledSettings := [];

      AItemSettings.CustomTextSettings.ApplyTo(PlayListItemFrame.NumberLabel);
      AItemSettings.CustomTextSettings.ApplyTo(PlayListItemFrame.PathLabel);
      AItemSettings.CustomTextSettings.ApplyTo(PlayListItemFrame.TitleLabel);
      AItemSettings.CustomTextSettings.ApplyTo(PlayListItemFrame.ArtistLabel);
      AItemSettings.CustomTextSettings.ApplyTo(PlayListItemFrame.AlbumLabel);
      AItemSettings.CustomTextSettings.ApplyTo(PlayListItemFrame.DurationLabel);

      PlayListItemFrame.DurationLabel.TextAlign := TTextAlign.Trailing;
    end;

  AForm.Theme.FormSettings.Container := AForm;
  AForm.Theme.Apply;
  AForm.BorderFrame.Kind := TBorderFrameKind.bfkNoCaption;

//  TState.VisualScheme := ASchemeName;
end;

class procedure TVisualScheme.LoadForSetPasswordForm(
  const ASchemeName: String);
var
  Params: TParamsExt;
  SchemeFileName: String;
begin
  SchemeFileName := GetSchemeFileName(ASchemeName);

  Params := TParamsExt.Create;
  try
    TParamsExtractor.ExtractToParams(
      SchemeFileName,
      PACKER_SETTINGS_FILE,
      Params);

    SetPasswordForm.Theme.ParamsToSettings(Params);
  finally
    FreeAndNil(Params);
  end;

  SetPasswordForm.PasswordLabel.StyledSettings := [];
  SetPasswordForm.RetryPasswordLabel.StyledSettings := [];

  SetPasswordForm.Theme.CommonSettings.CustomTextSettings.ApplyTo(
    SetPasswordForm.PasswordLabel);
  SetPasswordForm.Theme.CommonSettings.CustomTextSettings.ApplyTo(
    SetPasswordForm.RetryPasswordLabel);

  SetPasswordForm.Theme.FormSettings.Container := SetPasswordForm;
  SetPasswordForm.Theme.Apply;

  SetPasswordForm.OnFormStateLoaded := (
    procedure(ATFormExt: TFormExt)
    begin
      SetPasswordForm.BorderFrame.Kind := TBorderFrameKind.bfkNone;
    end);
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
