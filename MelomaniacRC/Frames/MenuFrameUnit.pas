unit MenuFrameUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Objects, FMX.Layouts
  , EditHostFrameUnit
  , TypesUnit
  ;

type
  TMenuFrame = class(TFrame)
    ContentLayout: TLayout;
    BackgroundLayout: TLayout;
    BaseLayoutRectangle: TRectangle;
    NavigationLayout: TLayout;
    Layout2: TLayout;
    CloseButton: TButton;
    BaseLayout: TLayout;
    Layout1: TLayout;
    AddHostButton: TButton;
    EditHostButton: TButton;
    DeleteHostButton: TButton;
    procedure AddHostButtonClick(Sender: TObject);
    procedure EditHostButtonClick(Sender: TObject);
    procedure DeleteHostButtonClick(Sender: TObject);
  strict private
    FEditHostFrame: TEditHostFrame;
    FRCIdent: String;

    procedure DoCloseEditHostFrame(Sender: TObject);
    procedure CreateEditHostFrame(
      const ARCIdent: String;
      const AEditFrameMode: TEditFrameMode);
  public
    constructor Create(const ARCIdent: String); reintroduce;
  end;

implementation

{$R *.fmx}

uses
    AppManagerUnit
  , PoolUnit
  , ToolsUnit
  ;

{ TMenuFrame }

constructor TMenuFrame.Create(const ARCIdent: String);
begin
  FEditHostFrame := nil;
  FRCIdent := ARCIdent;

  inherited Create(nil);
end;

procedure TMenuFrame.CreateEditHostFrame(
  const ARCIdent: String;
  const AEditFrameMode: TEditFrameMode);
var
  RC: TMRC;
begin
  AppManager.RCPool.TryGetRC(ARCIdent, RC);

  FEditHostFrame := TEditHostFrame.Create(RC, AEditFrameMode);
  FEditHostFrame.Parent := ContentLayout;
  FEditHostFrame.Align := TAlignLayout.Contents;
  FEditHostFrame.CloseButton.OnClick := DoCloseEditHostFrame;
end;

procedure TMenuFrame.DoCloseEditHostFrame(Sender: TObject);
var
  RCIdent: String;
begin
  RCIdent := FRCIdent;
  FreeAndNil(FEditHostFrame);
end;

procedure TMenuFrame.AddHostButtonClick(Sender: TObject);
begin
  CreateEditHostFrame(FRCIdent, efmAdd);
end;

procedure TMenuFrame.EditHostButtonClick(Sender: TObject);
begin
  CreateEditHostFrame(FRCIdent, efmEdit);
end;

procedure TMenuFrame.DeleteHostButtonClick(Sender: TObject);
var
  RC: TMRC;
begin
  if not AppManager.RCPool.TryGetRC(FRCIdent, RC) then
    raise Exception.Create('RC instance not found');

  AppManager.RCPool.FreeRC(RC);
  TTools.SaveHosts;

  ShowMessage('Host deleted');

  DeleteHostButton.Enabled := false;
  EditHostButton.Enabled := false;
  AddHostButton.Enabled := true;
end;

end.
