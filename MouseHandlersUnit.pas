unit MouseHandlersUnit;

interface

uses
    System.UITypes
  , System.Classes
  , System.Types
  , FMX.Types
  , ClickListenerThreadUnit
  ;

type
  TMouseHandlers = class
  strict private
    class var FIsPressed: Boolean;
    class var FStartPos: TPointF;
    class var FClickListenerThread: TClickListenerThread;

    class procedure Pressed(Sender: TObject);
    class procedure UnPressed(Sender: TObject);
    class procedure Clicked(Sender: TObject);
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
  , FMX.Controls
  , FMX.Media
  , MelomaniacUnit
  , PlayControllerUnit
  , FMX.SingleSoundUnit
  , StringToolsUnit
  ;

class procedure TMouseHandlers.Init(
  const AClickListenerThread: TClickListenerThread);
begin
  FClickListenerThread := AClickListenerThread;

  FIsPressed := false;
  FStartPos := TPointF.Create(0, 0);
end;

class procedure TMouseHandlers.Pressed(Sender: TObject);
begin
  FIsPressed := true;
end;

class procedure TMouseHandlers.UnPressed(Sender: TObject);
begin
  FIsPressed := false;
end;

class procedure TMouseHandlers.Clicked(Sender: TObject);
begin
  UnPressed(Sender);
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
begin
  if not Assigned(Sender) then
    Exit;

  Pressed(Sender);
  FStartPos := TPointF.Create(X, Y);
  TControl(Sender).AutoCapture := true;

  if Button = TMouseButton.mbLeft then
  begin
    if Sender = MainForm.TimelineCaret then
    begin
    end
    else
    if Sender = MainForm.PlayButton then
    begin
      FClickListenerThread.SetClickParams(
        Pressed,
        Clicked,
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

  if Sender = MainForm.TimelineCaret then
  begin
    TimelineCaret := MainForm.TimelineCaret;

    // Вычисляем локальное смещение относительно первоначальной позиции
    MoveVector := TVector.Create(X - FStartPos.X, 0, 0);
    NewPointF := TimelineCaret.Position.Point + TPointF(MoveVector);

    SetTimelineCaretPosition(NewPointF.X + (TimelineCaret.Width / 2));
  end
  else
  if Sender = MainForm.PlayButton then
  begin
    Control := TControl(Sender);

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
begin
  if not Assigned(Sender) then
    Exit;

  UnPressed(Sender);
  TControl(Sender).AutoCapture := false;

  if Sender = MainForm.TimelineCaret then
  begin
  end
  else
  if Sender = MainForm.DurationBar then
  begin
    SetTimelineCaretPosition(X);
  end
  else
  if Sender = MainForm.PlayButton then
  begin
    FClickListenerThread.IsButtonUp := true;
  end;
end;

end.
