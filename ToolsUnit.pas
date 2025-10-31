unit ToolsUnit;

interface

uses
    FMX.Controls
  , FMX.Media
  , StateUnit
  , MelomaniacUnit
  ;

type
  TTools = class
  strict private
    class var FCurrentRenderPlayState: TPlayState;
  public
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
    class procedure ChooseDestinationPath(const AControl: TControl);

    class function GetLeafPath(const AControl: TControl): String;
    class procedure DisplayLeafPath(const AControl: TControl; const APath: String);
    class function LeafeControlByPathIndex(const APathIndex: Integer): TControl;
    class function PathIndexByLeafControl(const AControl: TControl): Integer;

    class procedure FillPaths(const ASetOfPathIndex: Integer);

    class procedure Init;
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
  , PlayControllerUnit
  , ConstantsUnit
  , FMX.ControlToolsUnit
  ;

{ TTools }

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
    end
  );
end;

class function TTools.GetLeafPath(const AControl: TControl): String;
var
  PathIndex: Integer;
begin
  PathIndex := 0;
  if AControl = MainForm.TopLeftControl then
    PathIndex := 0
  else
  if AControl = MainForm.TopRightControl then
    PathIndex := 1
  else
  if AControl = MainForm.BottomLeftControlLabel then
    PathIndex := 2
  else
  if AControl = MainForm.BottomRightControlLabel then
    PathIndex := 3;

  Result := TState.SetOfPaths[TState.SetOfPathsIndex][PathIndex];
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

class procedure TTools.ChooseDestinationPath(const AControl: TControl);
var
  DestPath: String;
  LeafeControl: TControl;
  PathIndex: Integer;
begin
  if not Assigned(AControl) then
    raise Exception.
      Create('TTools.SetDestinationPath -> AControl in nil');

  SelectDirectory('Choose folder:', '', DestPath);

  if DestPath.IsEmpty then
    Exit;

  LeafeControl := AControl as TControl;
  PathIndex := PathIndexByLeafControl(LeafeControl);
  TState.SetOfPaths[TState.SetOfPathsIndex][PathIndex] := DestPath;
  DisplayLeafPath(LeafeControl, DestPath);
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

class procedure TTools.Init;
begin
  FCurrentRenderPlayState := psStop;
end;

initialization
  TTools.Init;


end.
