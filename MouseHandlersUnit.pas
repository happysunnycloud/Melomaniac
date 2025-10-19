unit MouseHandlersUnit;

interface

uses
    System.UITypes
  , System.Classes
  , System.Types
  , FMX.Types
  ;

type
  TMouseHandlers = class
  strict private
    class var FIsPressed: Boolean;
    class var FStartPos: TPointF;
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

   class procedure Init;
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

class procedure TMouseHandlers.Init;
begin
  FIsPressed := false;
  FStartPos := TPointF.Create(0, 0);
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

  if Button = TMouseButton.mbLeft then
  begin
    if Sender = MainForm.TimelineCaret then
    begin
      MainForm.TimelineCaret.AutoCapture := true;
      FIsPressed := true;
      FStartPos := TPointF.Create(X, Y);
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
begin
  if not Assigned(Sender) then
    Exit;

  if Sender = MainForm.TimelineCaret then
  begin
    if FIsPressed then
    begin
      TimelineCaret := MainForm.TimelineCaret;

      // Вычисляем локальное смещение относительно первоначальной позиции
      MoveVector := TVector.Create(X - FStartPos.X, 0, 0);
      NewPointF := TimelineCaret.Position.Point + TPointF(MoveVector);

      SetTimelineCaretPosition(NewPointF.X + (TimelineCaret.Width / 2));
    end;
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

  if Sender = MainForm.TimelineCaret then
  begin
    MainForm.TimelineCaret.AutoCapture := false;
    FIsPressed := false;
  end;
  if Sender = MainForm.DurationBar then
  begin
    SetTimelineCaretPosition(X);
  end;
end;

end.
