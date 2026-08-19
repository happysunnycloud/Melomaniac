unit EditHostFrameUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Edit, FMX.Controls.Presentation, FMX.Objects, FMX.Layouts
  , PoolUnit
  ;

type
  TEditHostFrame = class(TFrame)
    ContentLayout: TLayout;
    BackgroundLayout: TLayout;
    BaseLayoutRectangle: TRectangle;
    BaseLayout: TLayout;
    SaveLayout: TLayout;
    Layout1: TLayout;
    SaveButton: TButton;
    TryToResolveButton: TButton;
    BaseTopLayout: TLayout;
    BaseTopCenterLayout: TLayout;
    PortLayout: TLayout;
    HostPortLabel: TLabel;
    PortEdit: TEdit;
    HostNameLayout: TLayout;
    HostNameLabel: TLabel;
    HostNameEdit: TEdit;
    Rectangle1: TRectangle;
    HostIPLayout: TLayout;
    HostIPLabel: TLabel;
    IPEdit: TEdit;
    NavigationLayout: TLayout;
    Layout2: TLayout;
    CloseButton: TButton;
    procedure SaveButtonClick(Sender: TObject);
  strict private
    FRC: TMRC;
  private
  public
    constructor Create(const ARC: TMRC); reintroduce;
  end;

implementation

{$R *.fmx}

uses
    ToolsUnit
  ;

{ TEditHostFrame }

constructor TEditHostFrame.Create(const ARC: TMRC);
begin
  FRC := ARC;

  inherited Create(nil);

  if not Assigned(FRC) then
    Exit;

  HostNameEdit.Text := FRC.HostName;
  IPEdit.Text := FRC.IP;
  PortEdit.Text := FRC.Port.ToString;
end;

procedure TEditHostFrame.SaveButtonClick(Sender: TObject);
var
  Index: Integer;
begin
  Index := -1; // Для случая, создания нового подключения
  if Assigned(FRC) then
    Index := FRC._Index;

  TTools.SaveHost(
    HostNameEdit.Text,
    IPEdit.Text,
    PortEdit.Text,
    Index);
end;

end.
