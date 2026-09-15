unit MelomaniacRCUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.Controls.Presentation, FMX.StdCtrls
  , ConstantsUnit
  , FMX.FormExtUnit
  , MenuFrameUnit
  ;

type
  TMainForm = class(TFormExt)
    NavigationLayout: TLayout;
    MenuButton: TButton;
    BaseLayout: TLayout;
    ScrollBox: TScrollBox;
    ContentLayout: TLayout;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure MenuButtonClick(Sender: TObject);
  private
    procedure DoCloseMenuFrame(Sender: TObject);
  public
    procedure MenuFormClose(Sender: TObject; var Action: TCloseAction);
    procedure AddHostFormClose(Sender: TObject; var Action: TCloseAction);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

uses
    MenuManagerUnit
  , AppManagerUnit
  , FMX.ControlToolsUnit
  ;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  ReportMemoryLeaksOnShutdown := true;

  TMenuManager.Init(Self.ContentLayout);
  TMenuManager.OnClose := DoCloseMenuFrame;

  AppManager := TAppManager.Create;
  AppManager.RCScrollBox := ScrollBox;
  AppManager.MainContentLayout := ContentLayout;

  TThread.ForceQueue(nil,
    procedure
    begin
      AppManager.CreateRCPool;
    end);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FreeAndNil(AppManager);
end;

procedure TMainForm.MenuFormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

procedure TMainForm.AddHostFormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

procedure TMainForm.DoCloseMenuFrame(Sender: TObject);
begin
  ScrollBox.Rebuild;
end;

procedure TMainForm.MenuButtonClick(Sender: TObject);
begin
  TMenuManager.OpenMenu('');
end;

end.
