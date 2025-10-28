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

//    class function GetVolume: Single; static;
    class procedure SetVolume(const AVolume: Single); static;

    class procedure SetFirst;
    class procedure SetPrev;
    class procedure SetNext;

//    class procedure SetFileName(const AFileName: String); static;
//    class function GetFileName: String; static;

//    class function GetCurrentCompositon: TPlayItem; static;
  public
    class procedure Init(
      const AThreadFactory: TThreadFactory;
      const AThreadFactoryRegistry: TThreadFactoryRegistry;
      const ATimelineCaret: TControl;
      const ADurationBar: TControl;
      const ACurrentTimeLabel: TControl);
    class procedure UnInit;

    class property SingleSound: TSingleSound read FSingleSound write FSingleSound;
//    class property FileName: String read GetFileName write SetFileName;
    class property PlayList: TPlayList read FPlayList;
    class property Volume: Single {read GetVolume} write SetVolume;
//    class property CurrentCompositon: TPlayItem read GetCurrentCompositon;

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
    class procedure First;
    class procedure Prev;
    class procedure Next;

    class procedure GetCurrentCompositonInfo(
      out ATitle: String;
      out APath: String);

    class procedure CurrentTimeByX(const AX: Single);
//    class procedure VolumeByX(const AX: Single);
//    class procedure XByVolume(const AVolume: Single);
    class procedure MountVolume;
  end;

implementation

uses
    System.SysUtils
//asd
  , System.Math
//asd
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

//class function TPlayControlle.GetVolume: Single;
//begin
//  Result := FSingleSound.Volume;
//
//  if FSingleSound.Volume > 0 then
//    TVisualScheme.AssignBitmap(MainForm.SoundControl, BITMAP_SOUND_IDENT);
//end;

class procedure TPlayController.SetVolume(const AVolume: Single);
var
  X: Single;
begin
  TState.LastVolume := TState.Volume;
  TState.Volume := AVolume;
  FSingleSound.Volume := TState.Volume;

  X := TTools.VolumeToVolumeCaretPosition(TState.Volume);
  TTools.RenderVolumeCaretPosition(X);
  //XByVolume(TState.Volume);

  if TState.Volume = 0 then
    TVisualScheme.AssignBitmap(MainForm.SoundControl, BITMAP_MUTE_IDENT)
  else
    TVisualScheme.AssignBitmap(MainForm.SoundControl, BITMAP_SOUND_IDENT);
end;

class procedure TPlayController.Play;
begin
  if TState.PlayState = psPlay then
    Exit;

  FSingleSound.Play;
  FTimelineTrackerThread.UnHoldThread;

  TState.PlayState := psPlay;
  TVisualScheme.AssignBitmap(MainForm.PlayControl, BITMAP_PLAY_IDENT);
  TTools.DisplayCurrentComposition;
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
  TState.LastVolume := TState.Volume;
  Volume := 0;
//  FSingleSound.Mute;
//  TVisualScheme.AssignBitmap(MainForm.SoundControl, BITMAP_MUTE_IDENT);
//  TTools.RenderVolumeCaretPosition(0);
end;

class procedure TPlayController.Sound;
begin
  Volume := TState.LastVolume;
//  FSingleSound.Sound;
//
//  TVisualScheme.AssignBitmap(MainForm.SoundControl, BITMAP_SOUND_IDENT);
//  XByVolume(FSingleSound.Volume);
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

class procedure TPlayController.First;
var
  _Volume: Single;
begin
  _Volume := TState.Volume;
  TState.LastPlayState := TState.PlayState;
  Stop;
  SetFirst;
  if TState.LastPlayState = psPlay then
  begin
    Volume := _Volume;
    Play;
  end;
end;

class procedure TPlayController.Prev;
var
  _Volume: Single;
begin
  _Volume := TState.Volume;
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
  _Volume := TState.Volume;
  TState.LastPlayState := TState.PlayState;
  Stop;
  SetNext;
  if TState.LastPlayState = psPlay then
  begin
    Volume := _Volume;
    Play;
  end;
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

class procedure TPlayController.SetFirst;
begin
  FSingleSound.FileName := FPlayList.First.Path;
end;

class procedure TPlayController.SetPrev;
begin
  FSingleSound.FileName := FPlayList.Prev.Path;
end;

class procedure TPlayController.SetNext;
begin
  FSingleSound.FileName := FPlayList.Next.Path;
end;

//class procedure TPlayController.SetFileName(const AFileName: String);
//begin
//  Stop;
//  FSingleSound.FileName := AFileName;
//end;
//
//class function TPlayController.GetFileName: String;
//begin
//  Result := FSingleSound.FileName;
//end;

//class function TPlayController.GetCurrentCompositon: TPlayItem;
//begin
//  Result := FPlayList.Current;
//end;

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

//class procedure TPlayController.VolumeByX(const AX: Single);
//var
//  VolumeControl: TControl;
//  X: Single;
//begin
////  MainForm.Memo1.Lines.Insert(0, FloatToStr(AX));
////  MainForm.Memo1.ScrollToTop;
//
//  X := AX;
//
//  VolumeControl := MainForm.VolumeControl;
//
//  if (X < 0) or (X > VolumeControl.Width) then
//    Exit;
//
////  TTools.RenderVolumeCaretPosition(X - (MainForm.VolumeCaretControl.Width / 2));
////  MainForm.Memo1.Lines.Insert(0, FloatToStr((1 / VolumeControl.Width) * X));
////  MainForm.Memo1.ScrollToTop;
//  Volume := (1 / VolumeControl.Width) * X;
//end;

//class procedure TPlayController.XByVolume(const AVolume: Single);
//var
//  X: Single;
//begin
//  X := (aVolume * MainForm.VolumeControl.Width) -
//    (MainForm.VolumeCaretControl.Width / 2);
//  TTools.RenderVolumeCaretPosition(X);
//end;

class procedure TPlayController.MountVolume;
var
//  Volume: Single;
  X: Single;
begin
  X := TTools.ReadVolumeCaretPosition;
  Volume := TTools.VolumeCaretPositionToVolume(X);
//  TTools.RenderVolumeCaretPosition(Volume);
end;

end.
