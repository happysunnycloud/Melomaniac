unit MelomaniacUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.SingleSoundUnit, FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls,
  FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, FMX.Objects,
  FMX.FormExtUnit,
  PlayListUnit
  ;

type
  TMainForm = class(TFormExt)
    PlayButton: TButton;
    NavigatorLayout: TLayout;
    StopButton: TButton;
    Memo1: TMemo;
    TrackerLayout: TLayout;
    DurationBar: TRectangle;
    TimelineCaret: TCircle;
    CurrentTimeLabel: TLabel;
    PrevButton: TButton;
    NextButton: TButton;
    BackwardRewindButton: TButton;
    ForwardRewindButton: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure StopButtonClick(Sender: TObject);
  private
  public
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

uses
    System.Generics.Collections
  , PlayControllerUnit
  , MouseHandlersUnit
  , ClickListenerThreadUnit
  , StateUnit
  ;

procedure TMainForm.FormCreate(Sender: TObject);
var
  PlayItemsList: TPlayItemsList;
  ClickListenerThread: TClickListenerThread;
begin
  ReportMemoryLeaksOnShutdown := true;

  TState.Init;

  TPlayController.Init(
    ThreadFactory,
    ThreadFactoryRegistry,
    TimelineCaret,
    DurationBar,
    CurrentTimeLabel);

//  TPlayController.PlayList.ReloadPlayList('E:\Desktop\Music\Alternative\Collection\');
  TPlayController.PlayList.ReloadPlayList('C:\000');
  TPlayController.PlayList.OnPlayListReloaded :=
    procedure
    var
      PlayItem: TPlayItem;
    begin
      PlayItemsList := TPlayController.PlayList.LockList;
      try
        for PlayItem in PlayItemsList do
        begin
          Memo1.Lines.Add(PlayItem.Path);
        end;
      finally
        TPlayController.PlayList.UnlockList;
      end;

      TPlayController.SingleSound.FileName := TPlayController.PlayList.First.Path;
      TPlayController.Play;
    end;

  ClickListenerThread := TClickListenerThread.Create(ThreadFactory);
  TMouseHandlers.Init(ClickListenerThread);
  TimelineCaret.OnMouseDown := TMouseHandlers.OnMouseDownHandler;
  TimelineCaret.OnMouseMove := TMouseHandlers.OnMouseMoveHandler;
  TimelineCaret.OnMouseUp := TMouseHandlers.OnMouseUpHandler;

  DurationBar.OnMouseUp := TMouseHandlers.OnMouseUpHandler;

  PlayButton.OnMouseDown := TMouseHandlers.OnMouseDownHandler;
  PlayButton.OnMouseMove := TMouseHandlers.OnMouseMoveHandler;
  PlayButton.OnMouseUp := TMouseHandlers.OnMouseUpHandler;

  PrevButton.OnMouseDown := TMouseHandlers.OnMouseDownHandler;
  PrevButton.OnMouseMove := TMouseHandlers.OnMouseMoveHandler;
  PrevButton.OnMouseUp := TMouseHandlers.OnMouseUpHandler;

  NextButton.OnMouseDown := TMouseHandlers.OnMouseDownHandler;
  NextButton.OnMouseMove := TMouseHandlers.OnMouseMoveHandler;
  NextButton.OnMouseUp := TMouseHandlers.OnMouseUpHandler;

  BackwardRewindButton.OnMouseDown := TMouseHandlers.OnMouseDownHandler;
  BackwardRewindButton.OnMouseMove := TMouseHandlers.OnMouseMoveHandler;
  BackwardRewindButton.OnMouseUp := TMouseHandlers.OnMouseUpHandler;

  ForwardRewindButton.OnMouseDown := TMouseHandlers.OnMouseDownHandler;
  ForwardRewindButton.OnMouseMove := TMouseHandlers.OnMouseMoveHandler;
  ForwardRewindButton.OnMouseUp := TMouseHandlers.OnMouseUpHandler;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  TPlayController.UnInit;
end;

procedure TMainForm.StopButtonClick(Sender: TObject);
begin
  TPlayController.Stop;
end;

end.
