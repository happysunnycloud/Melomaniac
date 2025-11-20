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

    class procedure SoundClicked(Sender: TObject);

    class procedure BackwardRewindClicked(Sender: TObject);
    class procedure ForwardRewindClicked(Sender: TObject);

    class procedure BackwardRewindPressed(Sender: TObject);
    class procedure ForwardRewindPressed(Sender: TObject);
    class procedure StopRewind(Sender: TObject);

//    class function IsMouseOverControl(fControl: TControl): Boolean;
  public
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

    class procedure OnMouseEnter(Sender: TObject);

    class procedure OnMouseLeave(Sender: TObject);

    class procedure ConnectHandlers(const AControls: array of TControl);

   class procedure Init(
      const AClickListenerThread: TClickListenerThread);
  end;

implementation

uses
    System.SysUtils
  , System.Math.Vectors
  , FMX.Forms
  , MelomaniacUnit
  , PlayControllerUnit
  , StateUnit
//  , Winapi.Windows
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
  if (TPlayController.PlayState = psPause) or
     (TPlayController.PlayState = psStop)
  then
  begin
    TPlayController.Play;
  end
  else
  if TPlayController.PlayState = psPlay then
  begin
    TPlayController.Pause;
  end;
end;

class procedure TMouseHandlers.PrevClicked(Sender: TObject);
begin
  TPlayController.Prev;
end;

class procedure TMouseHandlers.NextClicked(Sender: TObject);
begin
  TPlayController.Next;
end;

class procedure TMouseHandlers.SoundClicked(Sender: TObject);
begin
  if TPlayController.SingleSound.Volume > 0 then
    TPlayController.Mute
  else
    TPlayController.UnMute;
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
    if IsControlIn(Control,
      [
        MainForm.PlayControl
      ])
    then
    begin
      FClickListenerThread.SetClickParams(
        PlayClicked,
        Sender);
    end
    else
    if Control = MainForm.TimelineCaretControl then
    begin
      TPlayController.TimelineTrackerThread.HoldThread;
    end
    else
    if Control = MainForm.TopLeftControl then
    begin
      FClickListenerThread.SetClickParams(
        nil,
        Sender);
    end
    else
    if Control = MainForm.TopRightControl then
    begin
      FClickListenerThread.SetClickParams(
        nil,
        Sender);
    end
    else
    if Control = MainForm.BottomLeftControl then
    begin
      FClickListenerThread.SetClickParams(
        nil,
        Sender);
    end
    else
    if Control = MainForm.BottomRightControl then
    begin
      FClickListenerThread.SetClickParams(
        nil,
        Sender);
    end
    else
    if Control = MainForm.PrevTrackControl then
    begin
      FClickListenerThread.SetClickParams(
        PrevClicked,
        Sender);
    end
    else
    if Control = MainForm.NextTrackControl then
    begin
      FClickListenerThread.SetClickParams(
        NextClicked,
        Sender);
    end
    else
    if Control = MainForm.PrevNSecondsControl then
    begin
      FClickListenerThread.SetClickParams(
        BackwardRewindClicked,
        BackwardRewindPressed,
        Sender);
    end
    else
    if Control = MainForm.NextNSecondsControl then
    begin
      FClickListenerThread.SetClickParams(
        ForwardRewindClicked,
        ForwardRewindPressed,
        Sender);
    end
    else
    if Control = MainForm.SoundControl then
    begin
      SoundClicked(Sender);
    end
    else
    if Control = MainForm.InfoPanelControl then
    begin
      FClickListenerThread.SetClickParams(
        nil,
        Sender);
    end;
  end
  else
  if Button = TMouseButton.mbRight then
  begin
    if IsControlIn(Control,
      [
        MainForm.TopLeftControl,
        MainForm.TopRightControl,
        MainForm.BottomLeftControl,
        MainForm.BottomRightControl
      ])
    then
    begin
      MainForm.LeafePopupMenu.Open(Control);
    end
    else
    begin
      if Control = MainForm.PlayControl then
      begin
        MainForm.MainPopupMenu.Open(nil);
      end;
    end;
  end;
end;

class procedure TMouseHandlers.OnMouseMoveHandler(
  Sender: TObject; Shift: TShiftState;
  X, Y: Single);
var
  MoveVector: TVector;
  Control: TControl;
begin
  if not Assigned(Sender) then
    Exit;

  if not FIsPressed then
    Exit;

  Control := Sender as TControl;

  if Control = MainForm.TimelineCaretControl then
  begin
    TPlayController.MountCurrentTime;
  end
  else
  if Control = MainForm.VolumeCaretControl then
  begin
    TPlayController.MountVolume;
  end
  else
  if IsControlIn(Control,
    [
      MainForm.PlayControl,
      MainForm.TopLeftControl,
      MainForm.TopRightControl,
      MainForm.BottomLeftControl,
      MainForm.BottomRightControl,
      MainForm.PrevTrackControl,
      MainForm.NextTrackControl,
      MainForm.InfoPanelControl
    ])
  then
  begin
    MoveVector := TVector.Create(X - FStartPos.X, Y - FStartPos.Y, 0);
    MoveVector := Control.LocalToAbsoluteVector(MoveVector);

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

  FClickListenerThread.IsButtonUp := true;

  if Button = TMouseButton.mbLeft then
  begin
    if Control = MainForm.TimelineCaretControl then
    begin
      if TPlayController.PlayState = psPlay then
        TPlayController.TimelineTrackerThread.UnHoldThread;
    end
    else
    if Control = MainForm.TimelineControl then
    begin
      TPlayController.MountCurrentTime;
    end
    else
    if Control = MainForm.VolumeControl then
    begin
      TPlayController.MountVolume;
    end
    else
  //  if IsControlIn(Control,
  //    [
  //      MainForm.PlayControl,
  //      MainForm.TopLeftControl,
  //      MainForm.TopRightControl,
  //      MainForm.BottomLeftControl,
  //      MainForm.BottomRightControl,
  //      MainForm.PrevTrackControl,
  //      MainForm.NextTrackControl,
  //      MainForm.InfoPanelControl
  //    ])
  //  then
  //  begin
  ////    FClickListenerThread.IsButtonUp := true;
  //  end
  //  else
    if IsControlIn(Control,
      [
        MainForm.PrevNSecondsControl,
        MainForm.NextNSecondsControl
      ])
    then
    begin
  //    FClickListenerThread.IsButtonUp := true;
      StopRewind(Sender);
    end
    else
    if Control = MainForm.MarkModeControl then
    begin
      if TState.MarkMode then
        TState.MarkMode := false
      else
        TState.MarkMode := true;

      TPlayController.HeighlightMarkMode;
    end
    else
    if Control = MainForm.CopyModeControl then
    begin
      if TState.CopyMode <> cmCopy then
      begin
        TState.CopyMode := cmCopy;
      end
      else
      begin
        TState.CopyMode := cmNone
      end;
      TPlayController.HeighlightCopyMode;
    end
    else
    if Control = MainForm.MoveModeControl then
    begin
      if TState.CopyMode <> cmMove then
      begin
        TState.CopyMode := cmMove;
      end
      else
      begin
        TState.CopyMode := cmNone
      end;
      TPlayController.HeighlightCopyMode;
    end
    else
    if IsControlIn(Control,
      [
        MainForm.TopLeftControl,
        MainForm.TopRightControl,
        MainForm.BottomLeftControl,
        MainForm.BottomRightControl
      ])
    then
    begin
      TPlayController.LeafeClicked(Control);
    end
  end;
end;

class procedure TMouseHandlers.OnMouseEnter(Sender: TObject);
var
  Control: TControl;
begin
  if not Assigned(Sender) then
    Exit;

  Control := Sender as TControl;

  if Control = MainForm.CopyModeControl then
  begin

  end
  else
  if Control = MainForm.MoveModeControl then
  begin

  end;
end;

class procedure TMouseHandlers.OnMouseLeave(Sender: TObject);
var
  Control: TControl;
begin
  if not Assigned(Sender) then
    Exit;

  Control := Sender as TControl;

  if Control = MainForm.CopyModeControl then
  begin

  end
  else
  if Control = MainForm.MoveModeControl then
  begin

  end;
end;

class procedure TMouseHandlers.ConnectHandlers(const AControls: array of TControl);
var
  Control: TControl;
begin
  for Control in AControls do
  begin
    Control.OnMouseDown := TMouseHandlers.OnMouseDownHandler;
    Control.OnMouseMove := TMouseHandlers.OnMouseMoveHandler;
    Control.OnMouseUp := TMouseHandlers.OnMouseUpHandler;

    Control.OnMouseEnter := TMouseHandlers.OnMouseEnter;
    Control.OnMouseLeave := TMouseHandlers.OnMouseLeave;
  end;
end;

//class function TMouseHandlers.IsMouseOverControl(fControl: TControl): Boolean;
//var
//  mousePoint: TPoint;
//  localizedMousePoint: TPointF;
//  RectF: TRectF;
//  BitMapData: TBitMapData;
//  bGetBitMapResult: Boolean;
//begin
//  MainForm.Memo1.Lines.Insert(0, fControl.Name);
//  MainForm.Memo1.ScrollToTop;
//
//  Result := false;
//
//  if fControl = nil then
//    Exit;
//
//  GetCursorPos(mousePoint);
//
//  localizedMousePoint := TPointF.Create(mousePoint);
//  localizedMousePoint := MainForm.ScreenToClient(localizedMousePoint);
//  localizedMousePoint := fControl.AbsoluteToLocal(localizedMousePoint);
//
//  RectF  := TRectF.Create(MainForm.ClientToScreen(fControl.LocalToAbsolute(fControl.ClipRect.TopLeft)),
//                          MainForm.ClientToScreen(fControl.LocalToAbsolute(fControl.ClipRect.BottomRight)));
//
//  if not RectF.IsEmpty then
//    if RectF.Contains(mousePoint) then
//    begin
//      bGetBitMapResult := false;
//
//      if fControl is TShape then
//        bGetBitMapResult := TShape(fControl).Fill.Bitmap.Bitmap.Map(TMapAccess.Read, BitMapData);
//
//      if bGetBitMapResult then
//        if BitMapData.GetPixel(Trunc(localizedMousePoint.X), Trunc(localizedMousePoint.Y)) <> 0 then
//          Result := true;
//    end;
//end;

end.
