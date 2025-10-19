unit MelomaniacUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.SingleSoundUnit, FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls,
  FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, FMX.Objects,
  FMX.FormExtUnit,
  PlayListUnit,
  TimelineTrackerThreadUnit
  ;

type
  TMainForm = class(TFormExt)
    PlayButton: TButton;
    NavigatorLayout: TLayout;
    PauseButton: TButton;
    StopButton: TButton;
    Memo1: TMemo;
    TrackerLayout: TLayout;
    DurationBar: TRectangle;
    TimelineCaret: TCircle;
    CurrentTimeLabel: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure PlayButtonClick(Sender: TObject);
    procedure StopButtonClick(Sender: TObject);
    procedure PauseButtonClick(Sender: TObject);
  private
    FPlayList: TPlayList;
  public
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

uses
    System.Generics.Collections
  , PlayControllerUnit
  , MP3TAGsReaderUnit
  , ThreadFactoryUnit
  , MouseHandlersUnit
  ;

procedure TMainForm.FormCreate(Sender: TObject);
var
  PlayItemsList: TPlayItemsList;
  PlayListThreadFactory: TThreadFactory;
begin
  ReportMemoryLeaksOnShutdown := true;

  TPlayController.Init(
    ThreadFactory,
    TimelineCaret,
    DurationBar,
    CurrentTimeLabel);

  PlayListThreadFactory := ThreadFactoryRegistry.CreateThreadFactory;

  FPlayList := TPlayList.Create(PlayListThreadFactory);

  FPlayList.ReloadPlayList('E:\Desktop\Music\Alternative\Collection\');
  FPlayList.OnPlayListReloaded :=
    procedure
    var
      PlayItem: TPlayItem;
    begin
      PlayItemsList := FPlayList.LockList;
      try
        for PlayItem in PlayItemsList do
        begin
          Memo1.Lines.Add(PlayItem.Path);
        end;
      finally
        FPlayList.UnlockList;
      end;

      TPlayController.SingleSound.FileName := FPlayList.First.Path;
      TPlayController.Play;
    end;

  TMouseHandlers.Init;
  TimelineCaret.OnMouseDown := TMouseHandlers.OnMouseDownHandler;
  TimelineCaret.OnMouseMove := TMouseHandlers.OnMouseMoveHandler;
  TimelineCaret.OnMouseUp := TMouseHandlers.OnMouseUpHandler;

  DurationBar.OnMouseUp := TMouseHandlers.OnMouseUpHandler;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FPlayList);

  TPlayController.UnInit;
end;

procedure TMainForm.PauseButtonClick(Sender: TObject);
begin
  TPlayController.Pause;
end;

procedure TMainForm.PlayButtonClick(Sender: TObject);
begin
  TPlayController.Play;
end;

procedure TMainForm.StopButtonClick(Sender: TObject);
begin
  TPlayController.Stop;
end;

end.
