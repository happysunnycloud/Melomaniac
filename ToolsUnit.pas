unit ToolsUnit;

interface

uses
    FMX.Controls
  , StateUnit
  , MelomaniacUnit
  ;

type
  TTools = class
  strict private
  public
    class procedure RenderPlayState(const APlayState: TPlayState);
    class procedure RenderVolumeCaretPosition(const X: Single);
    class procedure ConnectGlowEffect(
      const AExceptControls: array of TControl);
  end;

implementation

uses
    FMX.Effects
  , PlayControllerUnit
  , ConstantsUnit
  , FMX.ControlToolsUnit
  ;

{ TTools }

class procedure TTools.RenderPlayState(const APlayState: TPlayState);
var
  MoveStep: Integer;
begin
  MoveStep := MOVE_CONTROLS_STEP;

  case APlayState of
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

class procedure TTools.RenderVolumeCaretPosition(const X: Single);
var
  VolumeCaret: TControl;
  VolumeControl: TControl;
  CurrentVolume: Single;
begin
  VolumeCaret := MainForm.VolumeCaretControl;
  VolumeControl := MainForm.VolumeControl;

  if (X >= 0) and (X <= VolumeControl.Width) then
    VolumeCaret.Position.X := X - (VolumeCaret.Width / 2)
  else
    Exit;

  CurrentVolume := (1 / VolumeControl.Width) * X;
  TPlayController.SingleSound.Volume := CurrentVolume;
end;

class procedure TTools.ConnectGlowEffect(
  const AExceptControls: array of TControl);
var
  ExceptControls: array of TControl;
  i: Integer;
begin
  SetLength(ExceptControls, Length(AExceptControls));
  for i := 0 to Pred(Length(AExceptControls)) do
  begin
    ExceptControls[i] := AExceptControls[i];
  end;

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

end.
