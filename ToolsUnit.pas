unit ToolsUnit;

interface

uses
    FMX.Controls
  , FMX.Media
  , StateUnit
  , MelomaniacUnit
  , System.UITypes
  , DBAccessUnit
  , PlayListUnit
  ;

const
  SQL_TEMPLATES_PATH = '..\..\SQLTemplates\';

type
  TTools = class
  strict private
    class var FDBAccess: TDBAccess;
    class var FCurrentRenderPlayState: TPlayState;

    class procedure SetLeafePath(
      const AControl: TControl;
      const ADestPath: String);

    class function PathIndexByLeafControl(const AControl: TControl): Integer;
    class property DBAccess: TDBAccess read FDBAccess;
  public
    class procedure Init;
    class procedure UnInit;

    class procedure RenderPlayState(const APlayState: TPlayState);
    class procedure RenderTimelineCaretPosition(const AX: Single);
    class procedure RenderVolumeCaretPosition(const AX: Single);
    class function ReadCaretPosition(const AControl: TControl): Single;
    class function TimelineCaretPositionToTime(const AX: Single): TMediaTime;
    class function TimeToCaretPosition(const ATime: TMediaTime): Single;
    class function VolumeCaretPositionToVolume(const AX: Single): Single;
    class function VolumeToVolumeCaretPosition(const AVolume: Single): Single;
    class procedure DisplayCurrentComposition;
    class procedure ConnectGlowEffect(
      const AExceptControls: array of TControl);
    class procedure ConnectHeighlightGlowEffect(
      const AExceptControls: array of TControl;
      const AColor: TAlphaColor;
      const AName: String);
    class procedure ChooseDestinationPath(const AControl: TControl);
    class procedure ChooseMainFolder;

    class procedure DisplayLeafPath(const AControl: TControl; const APath: String);
    class function LeafeControlByPathIndex(const APathIndex: Integer): TControl;
    class function LeafeToControl(const ALeafe: TLeafe): TControl;
    class function ControlToLeafe(const AControl: TControl): TLeafe;
    class function SetOfPathsIndexToControl(const ASetOfPathsIndex: Integer): TControl;
    class function ControlToSetOfPathsIndex(const AControl: TControl): Integer;
    class procedure SetLeafeEmptyPath(const AControl: TControl);
    class procedure FillPaths(const ASetOfPathIndex: Integer);
    class procedure GlowEffectActivated(
      const AGlowEffectName: String;
      const AControl: TControl;
      const AActivated: Boolean);
    class procedure CreateHeighlightFailThread(const AControl: TControl);
    class function CopyComposition(
      const APathFrom: String; const APathTo: String): Boolean;
    class function MoveComposition(
      const APathFrom: String; const APathTo: String): Boolean;

    class function IsMouseOverControl(
      const AControl: TControl): Boolean;

    class function CheckPath(const APath: String): Boolean;
    class procedure InsertPlayItemsListToDB(
      const APlayItemsList: TPlayItemsList);
    class procedure DeletePlayItemsListFromDB(
      const APlayItemsList: TPlayItemsList);
    class procedure SelectPlayItemsListFromDB(
      const AMainPath: String;
      const APlayItemsList: TPlayItemsList);
  end;

implementation

uses
    System.SysUtils
  , System.Classes
  , System.Types
  , Winapi.Windows
  , FMX.StdCtrls
  , FMX.Effects
  , FMX.Dialogs
  , FMX.Graphics
  , FMX.Objects
  , PlayControllerUnit
  , ConstantsUnit
  , FMX.ControlToolsUnit
  , FileToolsUnit
  , ThreadFactoryUnit
  , SQLTemplatesUnit
  ;

{ TTools }

class procedure TTools.Init;
  procedure _CheckAndCreateDb(const ADBFileName: String);
  var
    DBFileName: String;
    DBFile: TFileStream;
  begin
    DBFileName := ADBFileName;
    if not FileExists(DBFileName) then
    begin
      try
        try
          DBFile := TFileStream.Create(DBFileName, fmCreate);
        except
          raise;
        end;
      finally
        FreeAndNil(DBFile);
      end;
    end;
  end;

var
  DBFileName: String;
begin
  FCurrentRenderPlayState := psStop;

  DBFileName := 'Catalog.db';
  try
    _CheckAndCreateDb(DBFileName);
  except
    on e: Exception do
      raise Exception.CreateFmt('Fatal error: Can`t create "%s"', [DBFileName]);
  end;

  FDBAccess :=
    TDBAccess.Create(DBFileName, SQL_TEMPLATES_PATH, TTemplatesKind.tkPath);
  FDBAccess.CreateCatalogTable;
end;

class procedure TTools.UnInit;
begin
  FreeAndNil(FDBAccess);
end;

class procedure TTools.RenderPlayState(const APlayState: TPlayState);
var
  MoveStep: Integer;
begin
  if FCurrentRenderPlayState = APlayState then
    Exit;

  FCurrentRenderPlayState := APlayState;

  MoveStep := MOVE_CONTROLS_STEP;

  case FCurrentRenderPlayState of
    psPlay: MoveStep := MoveStep;
    psPause,
    psStop: MoveStep := MoveStep * -1;
  end;

  MainForm.PrevTrackControl.Position.X :=
    MainForm.PrevTrackControl.Position.X - MoveStep * 2;
  MainForm.PrevNSecondsControl.Position.X :=
    MainForm.PrevNSecondsControl.Position.X - MoveStep;

  MainForm.NextTrackControl.Position.X :=
    MainForm.NextTrackControl.Position.X + MoveStep * 2;
  MainForm.NextNSecondsControl.Position.X :=
    MainForm.NextNSecondsControl.Position.X + MoveStep;

  MainForm.TopLeftControl.Position.X :=
    MainForm.TopLeftControl.Position.X - MoveStep;
  MainForm.TopLeftControl.Position.Y :=
    MainForm.TopLeftControl.Position.Y - MoveStep;

  MainForm.TopRightControl.Position.X    :=
    MainForm.TopRightControl.Position.X + MoveStep;
  MainForm.TopRightControl.Position.Y    :=
    MainForm.TopRightControl.Position.Y - MoveStep;

  MainForm.BottomLeftControl.Position.X  :=
    MainForm.BottomLeftControl.Position.X  - MoveStep;
  MainForm.BottomLeftControl.Position.Y  :=
    MainForm.BottomLeftControl.Position.Y  + MoveStep;

  MainForm.BottomRightControl.Position.X :=
    MainForm.BottomRightControl.Position.X + MoveStep;
  MainForm.BottomRightControl.Position.Y :=
    MainForm.BottomRightControl.Position.Y + MoveStep;

  MainForm.TopControlsLayout.Position.Y :=
    MainForm.TopControlsLayout.Position.Y - MoveStep;
  MainForm.BottomControlsLayout.Position.Y :=
    MainForm.BottomControlsLayout.Position.Y + MoveStep;
end;

class procedure TTools.RenderTimelineCaretPosition(const AX: Single);
var
  X: Single;
begin
  X := AX;
  MainForm.TimelineCaretControl.Position.X := X;
end;

class procedure TTools.RenderVolumeCaretPosition(const AX: Single);
var
  X: Single;
begin
  X := AX;
  MainForm.VolumeCaretControl.Position.X := X;
end;

class function TTools.ReadCaretPosition(const AControl: TControl): Single;
var
  ScreenPoint: TPoint;
  FormPoint: TPointF;
  ClientPoint: TPointF;
  PointF: TPointF;
  X: Single;
begin
  GetCursorPos(ScreenPoint);
  PointF := TPointF.Create(ScreenPoint);
  FormPoint := MainForm.ScreenToClient(PointF);
  ClientPoint := AControl.AbsoluteToLocal(FormPoint);

  X := ClientPoint.X;
  if X < 0 then
    Result := 0
  else
  if X > AControl.Width then
    Result := AControl.Width
  else
    Result := X;
end;

class function TTools.TimelineCaretPositionToTime(const AX: Single): TMediaTime;
var
  X: Single;
  TimelineControl: TControl;
begin
  Result := 0;

  X := AX;
  TimelineControl := MainForm.TimelineControl;
  if (X < 0) or (X > TimelineControl.Width) then
    Exit;

  Result :=
    Round((TPlayController.SingleSound.Duration / TimelineControl.Width) * X);
end;

class function TTools.TimeToCaretPosition(const ATime: TMediaTime): Single;
var
  X: Single;
begin
  Result := 0 - (MainForm.TimelineCaretControl.Width / 2);
  if TPlayController.SingleSound.Duration = 0 then
    Exit;

  X := (ATime * (MainForm.TimelineControl.Width / TPlayController.SingleSound.Duration)) -
    (MainForm.TimelineCaretControl.Width / 2);
  Result := X;
end;

class function TTools.VolumeCaretPositionToVolume(const AX: Single): Single;
var
  X: Single;
  VolumeControl: TControl;
begin
  Result := 0;

  X := AX;
  VolumeControl := MainForm.VolumeControl;
  if (X < 0) or (X > VolumeControl.Width) then
    Exit;

  Result := (1 / VolumeControl.Width) * X;
end;

class function TTools.VolumeToVolumeCaretPosition(const AVolume: Single): Single;
var
  X: Single;
begin
  X := (AVolume * MainForm.VolumeControl.Width) -
    (MainForm.VolumeCaretControl.Width / 2);
  Result := X;
end;

class procedure TTools.DisplayCurrentComposition;
var
  Title: String;
  Path: String;
begin
  TPlayController.GetCurrentCompositonInfo(Title, Path);
  MainForm.InfoPanelTitleLabel.Text := Title;
  MainForm.InfoPanelPathLabel.Text := Path;
end;

class procedure TTools.ConnectGlowEffect(
  const AExceptControls: array of TControl);
var
  ExceptControls: array of TControl;
  i: Integer;
begin
  SetLength(ExceptControls, Length(AExceptControls));
  for i := 0 to Pred(Length(AExceptControls)) do
    ExceptControls[i] := AExceptControls[i];

  TControlTools.ControlEnumerator(MainForm,
    procedure (const AControl: TControl)

      function _IsExceptedControl(const AControl: TControl): Boolean;
      var
        i: Integer;
      begin
        Result := false;
        for i := 0 to Pred(Length(ExceptControls)) do
        begin
          if ExceptControls[i] = AControl then
            Exit(true);
        end;
      end;

    var
      GlowEffect: TInnerGlowEffect;
    begin
      if _IsExceptedControl(AControl) then
        Exit;

      GlowEffect := TInnerGlowEffect.Create(AControl);
      GlowEffect.Parent := AControl;
      GlowEffect.Opacity := 1;
      GlowEffect.Softness := 1;
      GlowEffect.Enabled := false;
      GlowEffect.Trigger := 'IsMouseOver=true';
      GlowEffect.Name := GLOW_EFFECT_IDENT;
    end
  );
end;

class procedure TTools.ConnectHeighlightGlowEffect(
  const AExceptControls: array of TControl;
  const AColor: TAlphaColor;
  const AName: String);
var
  ExceptControls: array of TControl;
  i: Integer;
begin
  SetLength(ExceptControls, Length(AExceptControls));
  for i := 0 to Pred(Length(AExceptControls)) do
    ExceptControls[i] := AExceptControls[i];

  TControlTools.ControlEnumerator(MainForm,
    procedure (const AControl: TControl)

      function _IsExceptedControl(const AControl: TControl): Boolean;
      var
        i: Integer;
      begin
        Result := false;
        for i := 0 to Pred(Length(ExceptControls)) do
        begin
          if ExceptControls[i] = AControl then
            Exit(true);
        end;
      end;

    var
      GlowEffect: TInnerGlowEffect;
    begin
      if _IsExceptedControl(AControl) then
        Exit;

      GlowEffect := TInnerGlowEffect.Create(AControl);
      GlowEffect.Parent := AControl;
      GlowEffect.Opacity := 1;
      GlowEffect.Softness := 0.5;
      GlowEffect.Enabled := false;
      GlowEffect.GlowColor := AColor;
      GlowEffect.Name := AName;
    end
  );
end;

class procedure TTools.DisplayLeafPath(
  const AControl: TControl;
  const APath: String);
var
  Component: TComponent;
  LeafeControlLabel: TLabel;
begin
  Component :=
    TControlTools.FindControl(AControl, Concat(AControl.Name, 'Label'));
  if not Assigned(Component) then
     raise Exception.
      Create('TTools.SetDestinationPath -> LeafeControlLabel is nil');

  LeafeControlLabel := Component as TLabel;
  LeafeControlLabel.Text := APath;
end;

class function TTools.LeafeControlByPathIndex(const APathIndex: Integer): TControl;
begin
  Result := nil;

  if APathIndex = 0 then
    Result := MainForm.TopLeftControl
  else
  if APathIndex = 1 then
    Result := MainForm.TopRightControl
  else
  if APathIndex = 2 then
    Result := MainForm.BottomLeftControl
  else
  if APathIndex = 3 then
    Result := MainForm.BottomRightControl;
end;

class function TTools.PathIndexByLeafControl(const AControl: TControl): Integer;
begin
  Result := -1;
  if AControl = MainForm.TopLeftControl then
    Result := 0
  else
  if AControl = MainForm.TopRightControl then
    Result := 1
  else
  if AControl = MainForm.BottomLeftControl then
    Result := 2
  else
  if AControl = MainForm.BottomRightControl then
    Result := 3;

  if Result = -1 then
    raise Exception.
      CreateFmt('TTools.PathIndexByLeafeControl -> AControl "%s" not found',
        [AControl.Name]);
end;

class function TTools.LeafeToControl(const ALeafe: TLeafe): TControl;
begin
  Result := nil;
  case TState.Leafe of
    liTopLeft:
    begin
      Result := MainForm.TopLeftControl;
    end;
    liTopRigth:
    begin
      Result := MainForm.TopRightControl;
    end;
    liBottomLeft:
    begin
      Result := MainForm.BottomLeftControl;
    end;
    liBottomRight:
    begin
      Result := MainForm.BottomRightControl;
    end;
  end;
end;

class function TTools.ControlToLeafe(const AControl: TControl): TLeafe;
begin
  Result := TLeafe.liNone;
  if AControl = MainForm.TopLeftControl then
    Result := TLeafe.liTopLeft
  else
  if AControl = MainForm.TopRightControl then
    Result := TLeafe.liTopRigth
  else
  if AControl = MainForm.BottomLeftControl then
    Result := TLeafe.liBottomLeft
  else
  if AControl = MainForm.BottomRightControl then
    Result := TLeafe.liBottomRight;
end;

class function TTools.SetOfPathsIndexToControl(const ASetOfPathsIndex: Integer): TControl;
begin
  Result := nil;

  case ASetOfPathsIndex of
    0:
      Result := MainForm.SetOfPathsNumber1Control;
    1:
      Result := MainForm.SetOfPathsNumber2Control;
    2:
      Result := MainForm.SetOfPathsNumber3Control;
    3:
      Result := MainForm.SetOfPathsNumber4Control;
  end;
end;

class function TTools.ControlToSetOfPathsIndex(const AControl: TControl): Integer;
begin
  Result := 0;

  if AControl = MainForm.SetOfPathsNumber1Control then
    Result := 0
  else
  if AControl = MainForm.SetOfPathsNumber2Control then
    Result := 1
  else
  if AControl = MainForm.SetOfPathsNumber3Control then
    Result := 2
  else
  if AControl = MainForm.SetOfPathsNumber4Control then
    Result := 3;
end;

class procedure TTools.SetLeafePath(
  const AControl: TControl;
  const ADestPath: String);
var
  LeafeControl: TControl;
  PathIndex: Integer;
begin
  LeafeControl := AControl as TControl;
  PathIndex := PathIndexByLeafControl(LeafeControl);
  TState.SetOfPaths[TState.SetOfPathsIndex][PathIndex] := ADestPath;
  DisplayLeafPath(LeafeControl, ADestPath);
end;

class procedure TTools.ChooseDestinationPath(const AControl: TControl);
var
  DestPath: String;
begin
  if not Assigned(AControl) then
    raise Exception.
      Create('TTools.SetDestinationPath -> AControl in nil');

  SelectDirectory('Choose folder:', '', DestPath);

  if DestPath.IsEmpty then
    Exit;

  SetLeafePath(AControl, DestPath);
end;

class procedure TTools.SetLeafeEmptyPath(const AControl: TControl);
begin
  if not Assigned(AControl) then
    raise Exception.
      Create('TTools.SetLeafeEmptyPath -> AControl in nil');

  SetLeafePath(AControl, '');
end;

class procedure TTools.ChooseMainFolder;
var
  Path: String;
begin
  SelectDirectory('Choose folder:', '', Path);

  if Path.IsEmpty then
    Exit;

  TState.MainPath := Concat(Path, PATH_SPLITTER);
end;

class procedure TTools.FillPaths(const ASetOfPathIndex: Integer);
var
  Paths: TPaths;
  PathIndex: Integer;
  Path: String;
begin
  Paths := TState.SetOfPaths[ASetOfPathIndex];
  for PathIndex := 0 to 3 do
  begin
    Path := Paths[PathIndex];
    DisplayLeafPath(LeafeControlByPathIndex(PathIndex), Path);
  end;
end;

class procedure TTools.GlowEffectActivated(
  const AGlowEffectName: String;
  const AControl: TControl;
  const AActivated: Boolean);
begin
  TControlTools.ComponentEnumerator(
    AControl,
    procedure (const AInnerComponent: TComponent; var ABreak: Boolean)
    var
      GlowEffect: TInnerGlowEffect;
    begin
      if AInnerComponent.Name = AGlowEffectName then
      begin
        GlowEffect := TInnerGlowEffect(AInnerComponent);
        GlowEffect.Enabled := AActivated;
        GlowEffect.UpdateParentEffects;

        ABreak := true;
      end;
    end
  );
end;

class procedure TTools.CreateHeighlightFailThread(const AControl: TControl);
begin
  MainForm.ThreadFactory.CreateFreeOnTerminateThread(
    'HeighlightFailThread',
    procedure (const AThread: TThreadExt)
    var
      Control: TControl;
      Count: Integer;
    begin
      Control := AControl;
      Count := 20;

      AThread.Queue(nil,
        procedure
        begin
          TTools.GlowEffectActivated(
            FAIL_HEIGHLIGTH_GLOW_EFFECT_IDENT,
            Control,
            true);
        end
      );

      while (Count > 0) and not AThread.Terminated do
      begin
        Dec(Count);

        Sleep(100);
      end;

      AThread.Queue(nil,
        procedure
        begin
          TTools.GlowEffectActivated(
            FAIL_HEIGHLIGTH_GLOW_EFFECT_IDENT,
            Control,
            false);
        end
      );
    end
  );
end;

class function TTools.CopyComposition(
  const APathFrom: String; const APathTo: String): Boolean;
var
  FileName: String;
  PathTo: String;
begin
  Result := false;
  FileName := ExtractFileName(APathFrom);
  PathTo := Concat(APathTo, PATH_SPLITTER, FileName);
  if TFileTools.CopyFile(APathFrom, PathTo, TCopyFileAction.caRename) = crOk then
    Result := true;
end;

class function TTools.MoveComposition(
  const APathFrom: String; const APathTo: String): Boolean;
var
  FileName: String;
  PathTo: String;
begin
  Result := false;
  FileName := ExtractFileName(APathFrom);
  PathTo := Concat(APathTo, PATH_SPLITTER, FileName);
  if TFileTools.MoveFile(APathFrom, PathTo, TCopyFileAction.caRename) = crOk then
    Result := true;
end;

class function TTools.IsMouseOverControl(
  const AControl: TControl): Boolean;
var
  MousePoint: TPoint;
  LocalMousePoint: TPointF;
  RectF: TRectF;
  BitMapData: TBitMapData;
  GetBitMapResult: Boolean;
  Control: TControl;
begin
  Result := false;

  if AControl = nil then
    Exit;

  Control := AControl;

  GetCursorPos(MousePoint);

  LocalMousePoint := TPointF.Create(MousePoint);
  LocalMousePoint := MainForm.ScreenToClient(LocalMousePoint);
  LocalMousePoint := AControl.AbsoluteToLocal(LocalMousePoint);

  RectF  := TRectF.Create(MainForm.ClientToScreen(Control.LocalToAbsolute(Control.ClipRect.TopLeft)),
                          MainForm.ClientToScreen(Control.LocalToAbsolute(Control.ClipRect.BottomRight)));

  if not RectF.IsEmpty then
    if RectF.Contains(MousePoint) then
    begin
      GetBitMapResult := false;

      if Control is TShape then
        GetBitMapResult :=
          TShape(Control).Fill.Bitmap.Bitmap.Map(TMapAccess.Read, BitMapData);

      if GetBitMapResult then
        if BitMapData.
          GetPixel(Trunc(localMousePoint.X), Trunc(localMousePoint.Y)) <> 0
        then
          Result := true;
    end;
end;

class function TTools.CheckPath(const APath: String): Boolean;
begin
  Result := DBAccess.CheckPath(APath);
end;

class procedure TTools.InsertPlayItemsListToDB(
  const APlayItemsList: TPlayItemsList);
begin
  FDBAccess.InsertIntoCatalogTable(APlayItemsList);
end;

class procedure TTools.DeletePlayItemsListFromDB(
  const APlayItemsList: TPlayItemsList);
begin
  FDBAccess.DeleteFromCatalogTable(APlayItemsList);
end;

class procedure TTools.SelectPlayItemsListFromDB(
  const AMainPath: String;
  const APlayItemsList: TPlayItemsList);
begin
  FDBAccess.SelectFromCatalogTable(AMainPath, APlayItemsList);
end;

initialization
  TTools.Init;

finalization
  TTools.UnInit;

end.
