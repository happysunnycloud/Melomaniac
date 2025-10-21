unit MouseHandlersUnit;

interface

uses
    System.UITypes
  , System.Classes
  , System.Types
  , FMX.Controls
  , FMX.Types
  , ClickListenerThreadUnit
  ;

type
  TMouseHandlers = class
  strict private
    class var FIsPressed: Boolean;
    class var FStartPos: TPointF;
    class var FClickListenerThread: TClickListenerThread;

    class function IsControlIn(
      const AControl: TControl;
      const AControls: array of TControl): Boolean;

    class procedure Pressed(Sender: TObject);
    class procedure UnPressed(Sender: TObject);

    class procedure PlayClicked(Sender: TObject);
    class procedure PrevClicked(Sender: TObject);
    class procedure NextClicked(Sender: TObject);

    class procedure BackwardRewindClicked(Sender: TObject);
    class procedure ForwardRewindClicked(Sender: TObject);

    class procedure BackwardRewindPressed(Sender: TObject);
    class procedure ForwardRewindPressed(Sender: TObject);
    class procedure StopRewind(Sender: TObject);
  public
    class procedure SetTimelineCaretPosition(const X: Single);

    class procedure OnMouseDownHandler(
      Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);

    class procedure OnMouseMoveHandler(
      Sender: TObject; Shift: TShiftState;
      X, Y: Single);

    class procedure OnMouseUpHandler(
      Sender: TObject; Button:
      TMouseButton;
      Shift: TShiftState;
      X, Y: Single);

   class procedure Init(
      const AClickListenerThread: TClickListenerThread);
  end;

//procedure OnMouseUpHandler(
//  Sender: TObject; Button: TMouseButton;
//  Shift: TShiftState; X, Y: Single);

implementation

uses
    System.SysUtils
  , System.Math.Vectors
  , FMX.Media
  , MelomaniacUnit
  , PlayControllerUnit
  , FMX.SingleSoundUnit
  , StringToolsUnit
  , StateUnit
  , ConstantsUnit
  ;

{ TMouseHandlers }

class procedure TMouseHandlers.Init(
  const AClickListenerThread: TClickListenerThread);
begin
  FClickListenerThread := AClickListenerThread;

  FIsPressed := false;
  FStartPos := TPointF.Create(0, 0);
end;

class function TMouseHandlers.IsControlIn(
  const AControl: TControl;
  const AControls: array of TControl): Boolean;
var
  i: Integer;
begin
  Result := false;
  for i := 0 to Pred(Length(AControls)) do
  begin
    if AControl = AControls[i] then
    begin
      Exit(true);
    end;
  end;
end;

class procedure TMouseHandlers.Pressed(Sender: TObject);
begin
  FIsPressed := true;
end;

class procedure TMouseHandlers.UnPressed(Sender: TObject);
begin
  FIsPressed := false;
end;

class procedure TMouseHandlers.PlayClicked(Sender: TObject);
begin
  if (TState.PlayState = psPause) or
     (TState.PlayState = psStop)
  then
  begin
    TPlayController.Play;
    TState.PlayState := psPlay;
    MainForm.PlayButton.Text := 'Pause';
  end
  else
  if TState.PlayState = psPlay then
  begin
    TPlayController.Pause;
    TState.PlayState := psPause;
    MainForm.PlayButton.Text := 'Play';
  end
end;

class procedure TMouseHandlers.PrevClicked(Sender: TObject);
begin
  TState.LastPlayState := TState.PlayState;
  TPlayController.Stop;
  TPlayController.SetPrev;
  if TState.LastPlayState = psPlay then
    TPlayController.Play;
end;

class procedure TMouseHandlers.NextClicked(Sender: TObject);
begin
  TState.LastPlayState := TState.PlayState;
  TPlayController.Stop;
  TPlayController.SetNext;
  if TState.LastPlayState = psPlay then
    TPlayController.Play;
end;

class procedure TMouseHandlers.BackwardRewindClicked(Sender: TObject);
begin
  TPlayController.BackwardRewindStep;
end;

class procedure TMouseHandlers.ForwardRewindClicked(Sender: TObject);
begin
  TPlayController.ForwardRewindStep;
end;

class procedure TMouseHandlers.BackwardRewindPressed(Sender: TObject);
begin
  TPlayController.BackwardRewind;
end;

class procedure TMouseHandlers.ForwardRewindPressed(Sender: TObject);
begin
  TPlayController.ForwardRewind;
end;

class procedure TMouseHandlers.StopRewind(Sender: TObject);
begin
  TPlayController.StopRewind;
end;

class procedure TMouseHandlers.SetTimelineCaretPosition(const X: Single);
var
  TimelineCaret: TControl;
  DurationBar: TControl;
  Duration: TMediaTime;
  CurrentTime: TMediaTime;
begin
  TimelineCaret := MainForm.TimelineCaret;
  DurationBar := MainForm.DurationBar;

  Duration := TPlayController.SingleSound.Duration;
  if Duration = 0 then
    Duration := 1;

  if (X >= 0) and (X <= DurationBar.Width) then
    TimelineCaret.Position.X := X - (TimelineCaret.Width / 2)
  else
    Exit;

  CurrentTime := Round((Duration / DurationBar.Width) * X);
  MainForm.CurrentTimeLabel.Text := TStringTools.GetHumanTime(CurrentTime, MediaTimeScale);
  TPlayController.SingleSound.CurrentTime := CurrentTime;
end;

class procedure TMouseHandlers.OnMouseDownHandler(
  Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
var
  Control: TControl;
begin
  if not Assigned(Sender) then
    Exit;

  Control := Sender as TControl;

  Pressed(Control);
  FStartPos := TPointF.Create(X, Y);
  TControl(Control).AutoCapture := true;

  if Button = TMouseButton.mbLeft then
  begin
    if Control = MainForm.TimelineCaret then
    begin
    end
    else
    if Control = MainForm.PlayButton then
    begin
      FClickListenerThread.SetClickParams(
        PlayClicked,
        Sender);
    end
    else
    if Control = MainForm.PrevButton then
    begin
      FClickListenerThread.SetClickParams(
        PrevClicked,
        Sender);
    end
    else
    if Control = MainForm.NextButton then
    begin
      FClickListenerThread.SetClickParams(
        NextClicked,
        Sender);
    end
    else
    if Control = MainForm.BackwardRewindButton then
    begin
      FClickListenerThread.SetClickParams(
        BackwardRewindClicked,
        BackwardRewindPressed,
        Sender);
    end
    else
    if Control = MainForm.ForwardRewindButton then
    begin
      FClickListenerThread.SetClickParams(
        ForwardRewindClicked,
        ForwardRewindPressed,
        Sender);
    end;
  end;
end;

class procedure TMouseHandlers.OnMouseMoveHandler(
  Sender: TObject; Shift: TShiftState;
  X, Y: Single);
var
  MoveVector: TVector;
  NewPointF: TPointF;
  TimelineCaret: TControl;
  Control: TControl;
begin
  if not Assigned(Sender) then
    Exit;

  if not FIsPressed then
    Exit;

  Control := Sender as TControl;

  if Control = MainForm.TimelineCaret then
  begin
    TimelineCaret := MainForm.TimelineCaret;

    // Вычисляем локальное смещение относительно первоначальной позиции
    MoveVector := TVector.Create(X - FStartPos.X, 0, 0);
    NewPointF := TimelineCaret.Position.Point + TPointF(MoveVector);

    SetTimelineCaretPosition(NewPointF.X + (TimelineCaret.Width / 2));
  end
  else
  if IsControlIn(Control,
    [
      MainForm.PlayButton,
      MainForm.PrevButton,
      MainForm.NextButton
    ])
  then
  begin
    MoveVector  := TVector.Create(X - FStartPos.X, Y - FStartPos.Y, 0);
    MoveVector  := Control.LocalToAbsoluteVector(MoveVector);

    if Assigned(Control.ParentControl) then
      MoveVector := Control.ParentControl.AbsoluteToLocalVector(MoveVector);

    MainForm.Left := MainForm.Left + Round(MoveVector.X);
    MainForm.Top := MainForm.Top + Round(MoveVector.Y);
  end;
end;

class procedure TMouseHandlers.OnMouseUpHandler(
  Sender: TObject; Button:
  TMouseButton;
  Shift: TShiftState;
  X, Y: Single);
var
  Control: TControl;
begin
  if not Assigned(Sender) then
    Exit;

  Control := Sender as TControl;

  UnPressed(Control);
  TControl(Control).AutoCapture := false;

  if Control = MainForm.TimelineCaret then
  begin
  end
  else
  if Control = MainForm.DurationBar then
  begin
    SetTimelineCaretPosition(X);
  end
  else
  if IsControlIn(Control,
    [
      MainForm.PlayButton,
      MainForm.PrevButton,
      MainForm.NextButton
    ])
  then
  begin
    FClickListenerThread.IsButtonUp := true;
  end
  else
  if IsControlIn(Control,
    [
      MainForm.BackwardRewindButton,
      MainForm.ForwardRewindButton
    ])
  then
  begin
    FClickListenerThread.IsButtonUp := true;
    StopRewind(Sender);
  end

end;

end.
