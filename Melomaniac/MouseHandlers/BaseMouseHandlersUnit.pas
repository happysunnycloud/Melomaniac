unit BaseMouseHandlersUnit;

interface

uses
    System.UITypes
  , System.Classes
  , System.Types
  , System.Math.Vectors
  , FMX.Controls
  ;

type
  TBaseMouseHandlers = class
  strict private
    class var FIsPressed: Boolean;
    class var FStartPos: TPointF;
    class var FPressedAndMoved: Boolean;
    class var FMoveVector: TVector;
  protected
    class function IsControlIn(
      const AControl: TControl;
      const AControls: array of TControl): Boolean;

    class procedure Pressed(Sender: TObject);
    class procedure UnPressed(Sender: TObject);

    class property IsPressed: Boolean read FIsPressed write FIsPressed;
    class property StartPos: TPointF read FStartPos write FStartPos;
    class property PressedAndMoved: Boolean read FPressedAndMoved write FPressedAndMoved;
    class property MoveVector: TVector read FMoveVector write FMoveVector;
  public
    class procedure OnMouseDownHandler(
      Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single); virtual;

    class procedure OnMouseMoveHandler(
      Sender: TObject; Shift: TShiftState;
      X, Y: Single); virtual;

    class procedure OnMouseUpHandler(
      Sender: TObject;
      Button: TMouseButton;
      Shift: TShiftState;
      X, Y: Single); virtual;

//    class procedure OnMouseEnter(Sender: TObject);
    class procedure OnMouseLeaveHandler(Sender: TObject);

    class procedure ConnectHandlers(const AControls: array of TControl); virtual; abstract;

    class procedure Init;
  end;

implementation

{ TBaseMouseHandlers }

class procedure TBaseMouseHandlers.Init;
begin
  FIsPressed := false;
  FStartPos := TPointF.Create(0, 0);

  FPressedAndMoved := false;

  FMoveVector := Default(TVector);
end;

class function TBaseMouseHandlers.IsControlIn(
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

class procedure TBaseMouseHandlers.Pressed(Sender: TObject);
begin
  IsPressed := true;
end;

class procedure TBaseMouseHandlers.UnPressed(Sender: TObject);
begin
  IsPressed := false;
end;

class procedure TBaseMouseHandlers.OnMouseDownHandler(
  Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
var
  Control: TControl;
begin
  PressedAndMoved := false;

  if not Assigned(Sender) then
    Exit;

  Control := Sender as TControl;

  Pressed(Control);
  StartPos := TPointF.Create(X, Y);
  TControl(Control).AutoCapture := true;
end;

class procedure TBaseMouseHandlers.OnMouseMoveHandler(
  Sender: TObject;
  Shift: TShiftState;
  X, Y: Single);
begin
  MoveVector := TVector.Create(X - StartPos.X, Y - StartPos.Y, 0);

  PressedAndMoved := MoveVector.Length > 0;
end;

class procedure TBaseMouseHandlers.OnMouseUpHandler(
  Sender: TObject;
  Button: TMouseButton;
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
end;

//class procedure TBaseMouseHandlers.OnMouseEnter(Sender: TObject);
//var
//  Control: TControl;
//begin
//  if not Assigned(Sender) then
//    Exit;
//
//  Control := Sender as TControl;
//end;

class procedure TBaseMouseHandlers.OnMouseLeaveHandler(Sender: TObject);
var
  Control: TControl;
begin
  if not Assigned(Sender) then
    Exit;

  Control := Sender as TControl;

  UnPressed(Control);
  TControl(Control).AutoCapture := false;
end;

//class procedure TBaseMouseHandlers.ConnectHandlers(const AControls: array of TControl);
//var
//  Control: TControl;
//begin
//  for Control in AControls do
//  begin
//    Control.OnMouseDown := TBaseMouseHandlers.OnMouseDownHandler;
//    Control.OnMouseMove := TBaseMouseHandlers.OnMouseMoveHandler;
//    Control.OnMouseUp := TBaseMouseHandlers.OnMouseUpHandler;
//
////    Control.OnMouseEnter := TBaseMouseHandlers.OnMouseEnter;
//    Control.OnMouseLeave := TBaseMouseHandlers.OnMouseLeaveHandler;
//  end;
//end;

initialization
  TBaseMouseHandlers.Init;

end.
