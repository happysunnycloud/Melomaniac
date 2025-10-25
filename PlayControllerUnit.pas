unit PlayControllerUnit;

interface

uses
    FMX.Controls
  , ThreadFactoryUnit
  , ThreadFactoryRegistryUnit
  , TimelineTrackerThreadUnit
  , PlayListUnit
  , FMX.SingleSoundUnit
  ;

type
  TPlayController = class
  strict private
    class var FSingleSound: TSingleSound;
    class var FTimelineTrackerThread: TTimelineTrackerThread;
    class var FPlayList: TPlayList;

    class function GetVolume: Single; static;
    class procedure SetVolume(const AValume: Single); static;

    class procedure SetPrev;
    class procedure SetNext;
  public
    class procedure Init(
      const AThreadFactory: TThreadFactory;
      const AThreadFactoryRegistry: TThreadFactoryRegistry;
      const ATimelineCaret: TControl;
      const ADurationBar: TControl;
      const ACurrentTimeLabel: TControl);
    class procedure UnInit;

    class property SingleSound: TSingleSound read FSingleSound write FSingleSound;
    class property PlayList: TPlayList read FPlayList;
    class property Volume: Single read GetVolume write SetVolume;

    class procedure Play;
    class procedure Stop;
    class procedure Pause;
    class procedure Mute;
    class procedure Sound;
    class procedure BackwardRewind;
    class procedure ForwardRewind;
    class procedure BackwardRewindStep;
    class procedure ForwardRewindStep;
    class procedure StopRewind;
    class procedure Prev;
    class procedure Next;

    class procedure CurrentTimeByX(const AX: Single);
    class procedure VolumeByX(const AX: Single);
  end;

implementation

uses
    System.SysUtils
  , FMX.Media
  , StateUnit
  , ToolsUnit
  , StringToolsUnit
  , MelomaniacUnit
  , VisualSchemeUnit
  , ConstantsUnit
  ;

{ TPlayController }

class procedure TPlayController.Init(
  const AThreadFactory: TThreadFactory;
  const AThreadFactoryRegistry: TThreadFactoryRegistry;
  const ATimelineCaret: TControl;
  const ADurationBar: TControl;
  const ACurrentTimeLabel: TControl);
var
  PlayListThreadFactory: TThreadFactory;
begin
  FSingleSound := TSingleSound.Create;

  // FTimelineTrackerThread уничтожается через фабрику в которой зарегистрирован
  // Отдельно его уничтожать не нужно
  // Фабрика уничтожается при загрытии главного окна
  FTimelineTrackerThread := TTimelineTrackerThread.Create(
    AThreadFactory,
    TPlayController.SingleSound,
    ATimelineCaret,
    ADurationBar,
    ACurrentTimeLabel);

  PlayListThreadFactory := AThreadFactoryRegistry.CreateThreadFactory;

  FPlayList := TPlayList.Create(PlayListThreadFactory);
end;

class procedure TPlayController.UnInit;
begin
  FreeAndNil(FPlayList);
  FreeAndNil(FSingleSound);
end;

class function TPlayController.GetVolume: Single;
begin
  Result := FSingleSound.Volume;
  if FSingleSound.Volume > 0 then
    TVisualScheme.AssignBitmap(MainForm.SoundControl, BITMAP_SOUND_IDENT);
end;

class procedure TPlayController.SetVolume(const AValume: Single);
var
  X: Single;
begin
  FSingleSound.Volume := AValume;

  X := FSingleSound.Volume * MainForm.VolumeControl.Width;
  TTools.RenderVolumeCaretPosition(X);
  if FSingleSound.Volume = 0 then
    TVisualScheme.AssignBitmap(MainForm.SoundControl, BITMAP_MUTE_IDENT);
end;

class procedure TPlayController.Play;
begin
  if TState.PlayState = psPlay then
    Exit;

  FSingleSound.Play;
  FTimelineTrackerThread.UnHoldThread;

  TState.PlayState := psPlay;
  TVisualScheme.AssignBitmap(MainForm.PlayControl, BITMAP_PLAY_IDENT);
  TTools.RenderPlayState(TState.PlayState);
end;

class procedure TPlayController.Stop;
begin
  if TState.PlayState = psStop then
    Exit;

  FSingleSound.Stop;
  FTimelineTrackerThread.HoldThread;

  TState.PlayState := psStop;
  TVisualScheme.AssignBitmap(MainForm.PlayControl, BITMAP_PAUSE_IDENT);
  TTools.RenderPlayState(TState.PlayState);
end;

class procedure TPlayController.Pause;
begin
  if TState.PlayState = psPause then
    Exit;

  FSingleSound.Pause;
  FTimelineTrackerThread.HoldThread;

  TState.PlayState := psPause;
  TVisualScheme.AssignBitmap(MainForm.PlayControl, BITMAP_PAUSE_IDENT);
  TTools.RenderPlayState(TState.PlayState);
end;

class procedure TPlayController.Mute;
begin
  FSingleSound.Mute;
  TVisualScheme.AssignBitmap(MainForm.SoundControl, BITMAP_MUTE_IDENT);
  TTools.RenderVolumeCaretPosition(0);
end;

class procedure TPlayController.Sound;
var
  X: Single;
begin
  FSingleSound.Sound;

  TVisualScheme.AssignBitmap(MainForm.SoundControl, BITMAP_SOUND_IDENT);
  X := FSingleSound.Volume * MainForm.VolumeControl.Width;
  TTools.RenderVolumeCaretPosition(X);
end;

class procedure TPlayController.BackwardRewind;
begin
  FTimelineTrackerThread.RewindDirection := rdBackward;
  FTimelineTrackerThread.UnHoldThread;
end;

class procedure TPlayController.ForwardRewind;
begin
  FTimelineTrackerThread.RewindDirection := rdForward;
  FTimelineTrackerThread.UnHoldThread;
end;

class procedure TPlayController.BackwardRewindStep;
begin
  FTimelineTrackerThread.BackwardRewind;
end;

class procedure TPlayController.ForwardRewindStep;
begin
  FTimelineTrackerThread.ForwardRewind;
end;

class procedure TPlayController.StopRewind;
begin
  FTimelineTrackerThread.RewindDirection := rdNone;

  case TState.PlayState of
    psPlay: Play;
    psPause: Pause;
    psStop: Stop;
  end;
end;

class procedure TPlayController.Prev;
var
  _Volume: Single;
begin
  _Volume := Volume;
  TState.LastPlayState := TState.PlayState;
  Stop;
  SetPrev;
  if TState.LastPlayState = psPlay then
  begin
    Volume := _Volume;
    Play;
  end;
end;

class procedure TPlayController.Next;
var
  _Volume: Single;
begin
  _Volume := Volume;
  TState.LastPlayState := TState.PlayState;
  Stop;
  SetNext;
  if TState.LastPlayState = psPlay then
  begin
    Volume := _Volume;
    Play;
  end;
end;

class procedure TPlayController.SetPrev;
begin
  FSingleSound.FileName := FPlayList.Prev.Path;
end;

class procedure TPlayController.SetNext;
begin
  FSingleSound.FileName := FPlayList.Next.Path;
end;

class procedure TPlayController.CurrentTimeByX(const AX: Single);
var
  TimelineCaret: TControl;
  Timeline: TControl;
  Duration: TMediaTime;
  CurrentTime: TMediaTime;
  X: Single;
begin
  X := AX;

  TimelineCaret := MainForm.TimelineCaretControl;
  Timeline := MainForm.TimelineControl;

  Duration := FSingleSound.Duration;
  if Duration = 0 then
    Duration := 1;

  if (X >= 0) and (X <= Timeline.Width) then
    TimelineCaret.Position.X := X - (TimelineCaret.Width / 2)
  else
    Exit;

  CurrentTime := Round((Duration / Timeline.Width) * X);
  MainForm.CurrentTimeLabel.Text := TStringTools.GetHumanTime(CurrentTime, MediaTimeScale);
  FSingleSound.CurrentTime := CurrentTime;
end;

class procedure TPlayController.VolumeByX(const AX: Single);
var
  VolumeCaret: TControl;
  VolumeControl: TControl;
  X: Single;
begin
  X := AX;

  VolumeCaret := MainForm.VolumeCaretControl;
  VolumeControl := MainForm.VolumeControl;

  if (X >= 0) and (X <= VolumeControl.Width) then
    VolumeCaret.Position.X := X - (VolumeCaret.Width / 2)
  else
    Exit;

  Volume := (1 / VolumeControl.Width) * X;
end;


end.
