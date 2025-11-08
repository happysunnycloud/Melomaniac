unit PlayControllerUnit;

interface

uses
    FMX.Controls
  , FMX.Media
  , ThreadFactoryUnit
  , ThreadFactoryRegistryUnit
  , TimelineTrackerThreadUnit
  , PlayListUnit
  , FMX.SingleSoundUnit
  , StateUnit
  ;

type
  TPlayController = class
  strict private
    class var FSingleSound: TSingleSound;
    class var FTimelineTrackerThread: TTimelineTrackerThread;
    class var FPlayList: TPlayList;
    class var FPlayState: TPlayState;

    class procedure SetCurrentTime(const ACurrentTime: TMediaTime); static;
    class function GetCurrentTime: TMediaTime; static;
    class procedure SetVolume(const AVolume: Single); static;

    class function SetFirst: Boolean;
    class function SetPrev: Boolean;
    class function SetNext: Boolean;
    class function SetCurrent: Boolean;
  public
    class procedure Init(
      const AThreadFactory: TThreadFactory;
      const AThreadFactoryRegistry: TThreadFactoryRegistry;
      const ATimelineCaret: TControl;
      const ADurationBar: TControl;
      const ACurrentTimeLabel: TControl;
      const AInitializingPlayState: TPlayState);
    class procedure UnInit;

    class property SingleSound: TSingleSound read FSingleSound write FSingleSound;
    class property PlayList: TPlayList read FPlayList;
    class property CurrentTime: TMediaTime read GetCurrentTime write SetCurrentTime;
    class property Volume: Single write SetVolume;
    class property TimelineTrackerThread: TTimelineTrackerThread read FTimelineTrackerThread;
    class property PlayState: TPlayState read FPlayState;

    class procedure Play;
    class procedure Stop;
    class procedure Pause;
    class procedure Mute;
    class procedure UnMute;
    class procedure BackwardRewind;
    class procedure ForwardRewind;
    class procedure BackwardRewindStep;
    class procedure ForwardRewindStep;
    class procedure StopRewind;
    class procedure First;
    class procedure Prev;
    class procedure Next;
    class procedure Current(
      const APlayState: TPlayState;
      const ACurrentTime: TMediaTime);

    class procedure GetCurrentCompositonInfo(
      out ATitle: String;
      out APath: String);

    class procedure MountCurrentTime;
    class procedure MountVolume;
  end;

implementation

uses
    System.SysUtils
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
  const ACurrentTimeLabel: TControl;
  const AInitializingPlayState: TPlayState);
var
  PlayListThreadFactory: TThreadFactory;
begin
  FSingleSound := TSingleSound.Create;

  // FTimelineTrackerThread уничтожается через фабрику в которой зарегистрирован
  // Отдельно его уничтожать не нужно
  // Фабрика уничтожается при загрытии главного окна
  FTimelineTrackerThread := TTimelineTrackerThread.Create(
    AThreadFactory,
//    TPlayController.SingleSound,
    ATimelineCaret,
    ADurationBar,
    ACurrentTimeLabel);

  PlayListThreadFactory := AThreadFactoryRegistry.CreateThreadFactory;

  FPlayList := TPlayList.Create(PlayListThreadFactory);

  FPlayState := AInitializingPlayState;
end;

class procedure TPlayController.UnInit;
begin
  FreeAndNil(FPlayList);
  FreeAndNil(FSingleSound);
end;

class procedure TPlayController.SetCurrentTime(const ACurrentTime: TMediaTime);
var
  X: Single;
  CurrentTime: TMediaTime;
begin
  X := TTools.TimeToCaretPosition(ACurrentTime);
  TTools.RenderTimelineCaretPosition(X);

  CurrentTime := ACurrentTime;
  MainForm.CurrentTimeLabel.Text := TStringTools.GetHumanTime(CurrentTime, MediaTimeScale);
  FSingleSound.CurrentTime := CurrentTime;
  // Если каретку увели максимально вправо,
  // то CurrentTime становится равным Duration
  // и плеер автоматически останавливает воспроизведение
  // По этому проверяем текущий статус воспроизведения и запускаем если он psPlay
  if FPlayState = psPlay then
    FSingleSound.Play;
end;

class function TPlayController.GetCurrentTime: TMediaTime;
begin
  Result := FSingleSound.CurrentTime;
end;

class procedure TPlayController.SetVolume(const AVolume: Single);
var
  X: Single;
begin
  TState.LastVolume := TState.Volume;
  TState.Volume := AVolume;
  FSingleSound.Volume := TState.Volume;

  X := TTools.VolumeToVolumeCaretPosition(TState.Volume);
  TTools.RenderVolumeCaretPosition(X);

  if TState.Volume = 0 then
    TVisualScheme.AssignBitmap(MainForm.SoundControl, BITMAP_MUTE_IDENT)
  else
    TVisualScheme.AssignBitmap(MainForm.SoundControl, BITMAP_SOUND_IDENT);
end;

class procedure TPlayController.Play;
var
  LastPlayState: TPlayState;
  FileName: String;
begin
  FileName := FSingleSound.FileName;
  if FileName.IsEmpty then
    Exit;

  LastPlayState := FPlayState;

  FSingleSound.Play;
  FTimelineTrackerThread.UnHoldThread;
//  FTimelineTrackerThread.OnAfterHold := OnTimelineTrackerThreadAfterHoldHandler;

  FPlayState := psPlay;

  TState.PlayState := FPlayState;

  if LastPlayState = psPlay then
    Exit;

  TVisualScheme.AssignBitmap(MainForm.PlayControl, BITMAP_PLAY_IDENT);
  TTools.DisplayCurrentComposition;
  TTools.RenderPlayState(FPlayState);
end;

class procedure TPlayController.Stop;
var
  LastPlayState: TPlayState;
begin
  LastPlayState := FPlayState;

  FSingleSound.Stop;
  FTimelineTrackerThread.HoldThread;

  FPlayState := psStop;

  TState.PlayState := FPlayState;

  if LastPlayState = psStop then
    Exit;

  if LastPlayState = psPause then
    Exit;

  TVisualScheme.AssignBitmap(MainForm.PlayControl, BITMAP_PAUSE_IDENT);
  TTools.RenderPlayState(FPlayState);
end;

class procedure TPlayController.Pause;
var
  LastPlayState: TPlayState;
begin
  LastPlayState := FPlayState;

  FSingleSound.Pause;
  FTimelineTrackerThread.HoldThread;

  FPlayState := psPause;

  TState.PlayState := FPlayState;

  if LastPlayState = psPause then
    Exit;

  TVisualScheme.AssignBitmap(MainForm.PlayControl, BITMAP_PAUSE_IDENT);
  TTools.RenderPlayState(FPlayState);
end;

class procedure TPlayController.Mute;
begin
  TState.LastVolume := TState.Volume;
  Volume := 0;
end;

class procedure TPlayController.UnMute;
begin
  Volume := TState.LastVolume;
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

  case FPlayState of
    psPlay: Play;
    psPause: Pause;
    psStop: Stop;
  end;
end;

class procedure TPlayController.First;
var
  LastPlayState: TPlayState;
begin
  LastPlayState := FPlayState;
  Stop;
  SetFirst;
  if LastPlayState = psPlay then
    Play;
end;

class procedure TPlayController.Prev;
var
  LastPlayState: TPlayState;
begin
  LastPlayState := FPlayState;
  Stop;
  SetPrev;
  CurrentTime := 0;
  if LastPlayState = psPlay then
    Play;
end;

class procedure TPlayController.Next;
var
  LastPlayState: TPlayState;
begin
  LastPlayState := FPlayState;
  Stop;
  SetNext;
  CurrentTime := 0;
  if LastPlayState = psPlay then
    Play;
end;

class procedure TPlayController.Current(
  const APlayState: TPlayState;
  const ACurrentTime: TMediaTime);
begin
  Stop;
  SetCurrent;
  CurrentTime := ACurrentTime;
  if APlayState = psPlay then
    Play;
end;

class procedure TPlayController.GetCurrentCompositonInfo(
  out ATitle: String;
  out APath: String);
var
  PlayItem: TPlayItem;
begin
  ATitle := '';
  APath := '';

  PlayItem := FPlayList.Current;
  ATitle := PlayItem.Title;
  APath := PlayItem.Path;
end;

class function TPlayController.SetFirst: Boolean;
var
  Composition: String;
begin
  Result := false;

  Composition := FPlayList.FirstComposition;
  if Composition.IsEmpty then
    Exit;

  FSingleSound.FileName := Composition;
  Result := true;
end;

class function TPlayController.SetPrev: Boolean;
var
  Composition: String;
begin
  Result := false;

  Composition := FPlayList.PrevComposition;
  if Composition.IsEmpty then
    Exit;

  FSingleSound.FileName := Composition;
  Result := true;
end;

class function TPlayController.SetNext: Boolean;
var
  Composition: String;
begin
  Result := false;

  Composition := FPlayList.NextComposition;
  if Composition.IsEmpty then
    Exit;

  FSingleSound.FileName := Composition;
  Result := true;
end;

class function TPlayController.SetCurrent: Boolean;
var
  Composition: String;
begin
  Result := false;

  Composition := FPlayList.CurrentComposition;
  if Composition.IsEmpty then
    Exit;

  FSingleSound.FileName := Composition;
  Result := true;
end;

class procedure TPlayController.MountCurrentTime;
var
  X: Single;
begin
  X := TTools.ReadCaretPosition(MainForm.TimeLineControl);
  CurrentTime := TTools.TimelineCaretPositionToTime(X);
end;

class procedure TPlayController.MountVolume;
var
  X: Single;
begin
  X := TTools.ReadCaretPosition(MainForm.VolumeControl);
  Volume := TTools.VolumeCaretPositionToVolume(X);
end;

end.
