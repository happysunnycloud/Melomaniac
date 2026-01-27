unit PlayListFormMouseHandlersUnit;

interface

uses
    System.UITypes
  , System.Classes
  , FMX.Controls
  , BaseMouseHandlersUnit
  ;

type
  TPlayListFormMouseHandlers = class(TBaseMouseHandlers)
  strict private
  public
    class procedure OnMouseDownHandler(
      Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single); override;

    class procedure OnMouseMoveHandler(
      Sender: TObject; Shift: TShiftState;
      X, Y: Single); override;

    class procedure OnMouseUpHandler(
      Sender: TObject;
      Button: TMouseButton;
      Shift: TShiftState;
      X, Y: Single); override;

    class procedure ConnectHandlers(const AControls: array of TControl); override;
  end;

implementation

uses
    FMX.Layouts
  , PlayListFormUnit
  , PlayControllerUnit
  ;

{ TPlayListFormMouseHandlers }

class procedure TPlayListFormMouseHandlers.OnMouseDownHandler(
  Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  inherited;

//  Control := Sender as TControl;
//  Layout := Control as TLayout;
end;

class procedure TPlayListFormMouseHandlers.OnMouseMoveHandler(
  Sender: TObject; Shift: TShiftState;
  X, Y: Single);
var
  Control: TControl;
begin
  inherited;

  if not IsPressed then
    Exit;

  Control := Sender as TControl;

  MoveVector := Control.LocalToAbsoluteVector(MoveVector);

  if Assigned(Control.ParentControl) then
    MoveVector := Control.ParentControl.AbsoluteToLocalVector(MoveVector);

  PlayListForm.Left := PlayListForm.Left + Round(MoveVector.X);
  PlayListForm.Top := PlayListForm.Top + Round(MoveVector.Y);
end;

class procedure TPlayListFormMouseHandlers.OnMouseUpHandler(
  Sender: TObject;
  Button: TMouseButton;
  Shift: TShiftState;
  X, Y: Single);
var
  Control: TControl;
  Path: String;
begin
  inherited;

  Control := Sender as TControl;

  if PressedAndMoved then
    Exit;

  Path := PlayListForm.GetPath(Control);
  TPlayController.PlayOf(Path);
end;

class procedure TPlayListFormMouseHandlers.ConnectHandlers(const AControls: array of TControl);
var
  Control: TControl;
begin
  for Control in AControls do
  begin
    Control.OnMouseDown := TPlayListFormMouseHandlers.OnMouseDownHandler;
    Control.OnMouseMove := TPlayListFormMouseHandlers.OnMouseMoveHandler;
    Control.OnMouseUp := TPlayListFormMouseHandlers.OnMouseUpHandler;
  end;
end;

end.
