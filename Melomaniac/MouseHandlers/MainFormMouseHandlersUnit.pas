unit MainFormMouseHandlersUnit;

interface

uses
    System.UITypes
  , System.Classes
  , FMX.Controls
  , BaseMouseHandlersUnit
  ;

type
  TMainFormMouseHandlers = class(TBaseMouseHandlers)
  strict private
//    class procedure PlayClicked(Sender: TObject);
//    class procedure PrevClicked(Sender: TObject);
//    class procedure NextClicked(Sender: TObject);
//
//    class procedure SoundClicked(Sender: TObject);
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

//    class procedure OnMouseEnter(Sender: TObject);
    class procedure OnMouseLeaveHandler(Sender: TObject);

    class procedure ConnectHandlers(const AControls: array of TControl); override;
  end;

  TMainFormMouseClickManager = class
  public
    class procedure PlayClicked;
    class procedure PrevClicked;
    class procedure NextClicked;
    class procedure SoundClicked;

    class procedure VolumeUp;
    class procedure VolumeDown;
  end;

implementation

uses
    MelomaniacUnit
  , PlayControllerUnit
  , StateUnit
  , CommonTypesUnit
  ;

{ TMainFormMouseHandlers }

//class procedure TMainFormMouseHandlers.PlayClicked(Sender: TObject);
//begin
//  if (TState.PlayState = psPause) or
//     (TState.PlayState = psStop)
//  then
//  begin
//    TPlayController.Play;
//  end
//  else
//  if TState.PlayState = psPlay then
//  begin
//    TPlayController.Pause;
//  end;
//end;

//class procedure TMainFormMouseHandlers.PrevClicked(Sender: TObject);
//begin
//  TPlayController.Prev;
//end;

//class procedure TMainFormMouseHandlers.NextClicked(Sender: TObject);
//begin
//  TPlayController.Next;
//end;

//class procedure TMainFormMouseHandlers.SoundClicked(Sender: TObject);
//begin
//  if TPlayController.Volume > 0 then
//    TPlayController.Mute
//  else
//    TPlayController.UnMute;
//end;

class procedure TMainFormMouseHandlers.OnMouseDownHandler(
  Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
var
  Control: TControl;
begin
  inherited;

  Control := Sender as TControl;

  if Control = MainForm.TimelineCaretControl then
  begin
    TPlayController.TimelineTrackerThread.HoldThread;
  end
  else
  if Control = MainForm.PrevNSecondsControl then
    TPlayController.BackwardRewind
  else
  if Control = MainForm.NextNSecondsControl then
    TPlayController.ForwardRewind;
end;

class procedure TMainFormMouseHandlers.OnMouseMoveHandler(
  Sender: TObject; Shift: TShiftState;
  X, Y: Single);
var
  Control: TControl;
begin
  inherited;

  if not IsPressed then
    Exit;

  Control := Sender as TControl;

  if IsControlIn(Control,
    [
      MainForm.PrevNSecondsControl,
      MainForm.NextNSecondsControl
    ])
  then
    Exit;

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
      MainForm.InfoPanelTitleLabel,
      MainForm.InfoPanelPathLabel,
      MainForm.TopLeftControlLabel,
      MainForm.TopRightControlLabel,
      MainForm.BottomLeftControlLabel,
      MainForm.BottomRightControlLabel,
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
    MoveVector := Control.LocalToAbsoluteVector(MoveVector);

    if Assigned(Control.ParentControl) then
      MoveVector := Control.ParentControl.AbsoluteToLocalVector(MoveVector);

    MainForm.Left := MainForm.Left + Round(MoveVector.X);
    MainForm.Top := MainForm.Top + Round(MoveVector.Y);
  end;
end;

class procedure TMainFormMouseHandlers.OnMouseUpHandler(
  Sender: TObject;
  Button: TMouseButton;
  Shift: TShiftState;
  X, Y: Single);
var
  Control: TControl;
begin
  inherited;

  Control := Sender as TControl;

  if IsControlIn(Control,
  [
    MainForm.TimelineCaretControl
  ])
  then
  begin
    TPlayController.MountCurrentTime;
    if TState.PlayState = psPlay then
      TPlayController.TimelineTrackerThread.UnHoldThread;

    Exit;
  end
  else
  if PressedAndMoved then
    if not IsControlIn(Control,
      [
        MainForm.MarkModeControl,
        MainForm.CopyModeControl,
        MainForm.MoveModeControl,
        MainForm.DuplicateModeControl,
        MainForm.SetOfPathsNumber1Control,
        MainForm.SetOfPathsNumber2Control,
        MainForm.SetOfPathsNumber3Control,
        MainForm.SetOfPathsNumber4Control,
        MainForm.TimelineControl,
        MainForm.VolumeControl,
        MainForm.PrevNSecondsControl,
        MainForm.NextNSecondsControl,
        MainForm.SoundControl
      ]) then
    Exit;

  if Button = TMouseButton.mbLeft then
  begin
    if IsControlIn(Control,
      [
        MainForm.PlayControl
      ])
    then
    begin
      TMainFormMouseClickManager.PlayClicked;
    end
    else
    if Control = MainForm.PrevTrackControl then
    begin
      TMainFormMouseClickManager.PrevClicked;
    end
    else
    if Control = MainForm.NextTrackControl then
    begin
      TMainFormMouseClickManager.NextClicked;
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
    if IsControlIn(Control,
      [
        MainForm.PrevNSecondsControl,
        MainForm.NextNSecondsControl
      ])
    then
    begin
      TPlayController.StopRewind;
    end
    else
    if Control = MainForm.SoundControl then
    begin
      TMainFormMouseClickManager.SoundClicked;
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
        TState.CopyMode := cmCopy
      else
        TState.CopyMode := cmNone;

      TPlayController.HeighlightCopyMode;
    end
    else
    if Control = MainForm.MoveModeControl then
    begin
      if TState.CopyMode <> cmMove then
        TState.CopyMode := cmMove
      else
        TState.CopyMode := cmNone;

      TPlayController.HeighlightCopyMode;
    end
    else
    if Control = MainForm.DuplicateModeControl then
    begin
      if TState.DuplicateMode then
        TState.DuplicateMode := false
      else
        TState.DuplicateMode := true;

      TPlayController.HeighlightDuplicateMode;
      TPlayController.PlayList.ReloadPlayListFromDB(
        TState.MainPath,
        TState.DuplicateMode);

      TPlayController.RefreshPlayListForm;
      if TPlayController.PlayList.Count = 0 then
        Exit;

      TPlayController.PlayOf(TPlayController.PlayList.FirstComposition);
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
      TPlayController.LeafeClicked(Sender);
    end
    else
    if IsControlIn(Control,
      [
        MainForm.SetOfPathsNumber1Control,
        MainForm.SetOfPathsNumber2Control,
        MainForm.SetOfPathsNumber3Control,
        MainForm.SetOfPathsNumber4Control
      ])
    then
    begin
      TPlayController.SetOfPathClicked(Sender);
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

//class procedure TMouseHandlers.OnMouseEnter(Sender: TObject);
//var
//  Control: TControl;
//begin
//  if not Assigned(Sender) then
//    Exit;
//
//  Control := Sender as TControl;
//
//  if Control = MainForm.CopyModeControl then
//  begin
//
//  end
//  else
//  if Control = MainForm.MoveModeControl then
//  begin
//
//  end;
//end;

class procedure TMainFormMouseHandlers.OnMouseLeaveHandler(Sender: TObject);
var
  Control: TControl;
begin
  inherited;

  Control := Sender as TControl;

  if IsControlIn(Control,
    [
      MainForm.NextNSecondsControl,
      MainForm.PrevNSecondsControl
    ])
  then
  begin
    TPlayController.StopRewind;
  end
end;

class procedure TMainFormMouseHandlers.ConnectHandlers(const AControls: array of TControl);
var
  Control: TControl;
begin
  for Control in AControls do
  begin
    Control.OnMouseDown := TMainFormMouseHandlers.OnMouseDownHandler;
    Control.OnMouseMove := TMainFormMouseHandlers.OnMouseMoveHandler;
    Control.OnMouseUp := TMainFormMouseHandlers.OnMouseUpHandler;

//    Control.OnMouseEnter := TMouseHandlers.OnMouseEnter;
    Control.OnMouseLeave := TMainFormMouseHandlers.OnMouseLeaveHandler;
  end;
end;

{ TMainFormMouseClickManager }

class procedure TMainFormMouseClickManager.PlayClicked;
begin
  if (TState.PlayState = psPause) or
     (TState.PlayState = psStop)
  then
  begin
    TPlayController.Play;
  end
  else
  if TState.PlayState = psPlay then
  begin
    TPlayController.Pause;
  end;
end;

class procedure TMainFormMouseClickManager.PrevClicked;
begin
  TPlayController.Prev;
end;

class procedure TMainFormMouseClickManager.NextClicked;
begin
  TPlayController.Next;
end;

class procedure TMainFormMouseClickManager.SoundClicked;
begin
  if TPlayController.Volume > 0 then
    TPlayController.Mute
  else
    TPlayController.UnMute;
end;

class procedure TMainFormMouseClickManager.VolumeUp;
begin
  TPlayController.VolumeUp;
end;

class procedure TMainFormMouseClickManager.VolumeDown;
begin
  TPlayController.VolumeDown;
end;


end.
