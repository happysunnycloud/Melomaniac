unit MelomaniacUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.SingleSoundUnit, FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls,
  FMX.Memo.Types, FMX.ScrollBox, FMX.Memo,
  FMX.FormExtUnit,
  PlayListUnit
  ;

type
  TMainForm = class(TFormExt)
    PlayButton: TButton;
    NavigatorLayout: TLayout;
    PauseButton: TButton;
    StopButton: TButton;
    Memo1: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure PlayButtonClick(Sender: TObject);
    procedure StopButtonClick(Sender: TObject);
    procedure PauseButtonClick(Sender: TObject);
  private
    FPlayList: TPlayList;
    FSingleSound: TSingleSound;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

uses
    System.Generics.Collections
  , MP3TAGsReaderUnit
  , ThreadFactoryUnit
  ;

procedure TMainForm.FormCreate(Sender: TObject);
var
  MP3Info: TMP3Info;
  PlayItemsList: TPlayItemsList;
  PlayListThreadFactory: TThreadFactory;
begin
  ReportMemoryLeaksOnShutdown := true;

  PlayListThreadFactory := ThreadFactoryRegistry.CreateThreadFactory;

  FPlayList := TPlayList.Create(PlayListThreadFactory);

  FSingleSound := TSingleSound.Create;
  FSingleSound.FileName := 'c:\000\phoebe_cates_paradise.mp3';

  if not TMP3Reader.IsMP3Strict(FSingleSound.FileName) then
  begin
    ShowMessage('File incorrect');
    Exit;
  end;
  MP3Info := TMP3Reader.ReadMP3(FSingleSound.FileName);
  Memo1.Lines.Add(MP3Info.Title);
  Memo1.Lines.Add(MP3Info.Artist);
  Memo1.Lines.Add(FloatToStr(MP3Info.Duration));

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
    end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FSingleSound);
  FreeAndNil(FPlayList);
end;

procedure TMainForm.PauseButtonClick(Sender: TObject);
begin
  FSingleSound.Pause;
end;

procedure TMainForm.PlayButtonClick(Sender: TObject);
begin
  FSingleSound.Play;
end;

procedure TMainForm.StopButtonClick(Sender: TObject);
begin
  FSingleSound.Stop;
end;

end.
