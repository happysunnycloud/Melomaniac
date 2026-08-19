unit ControlPanelFrameUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts,
  FMX.Objects, FMX.Effects
  ;

const
  CONNECTED_COLOR = TAlphaColorRec.Yellowgreen;
  DISCONNECTED_COLOR = TAlphaColorRec.Lavender;
  TRY_TO_CONNECT_COLOR = $FFFFD984;

type
  TControlPanelFrame = class(TFrame)
    PlayButton: TButton;
    HostPanel: TPanel;
    HostNameLabel: TLabel;
    CompositionNamePanel: TPanel;
    CompositionNameLabel: TLabel;
    NextButton: TButton;
    PlayLayout: TLayout;
    NavigateLayout: TLayout;
    PrevButton: TButton;
    ConnectionLayout: TLayout;
    ConnectButton: TRectangle;
    Background: TRectangle;
    MenuLabel: TLabel;
    Layout1: TLayout;
    Layout2: TLayout;
    VolumeDownButton: TButton;
    VolumeUpButton: TButton;
    VolumePanel: TPanel;
    VolumeLabel: TLabel;
    TopSplitterRectangle: TRectangle;
    ButtonSplitterRectangle: TRectangle;
    CompositionTimeTotalLabel: TLabel;
    CompositionTimeCurrentLabel: TLabel;
    CompotitionNameTopLayout: TLayout;
    CompositionTimeBottomLayout: TLayout;
    procedure FrameResized(Sender: TObject);
    procedure MenuLabelClick(Sender: TObject);
  strict private
    FRCIdent: String;
  private
  public
    constructor Create(
      AOwner: TComponent;
      const ARCIdent: String); reintroduce;
  end;

implementation

{$R *.fmx}

uses
    MenuManagerUnit
  ;

{ TControlPanelFrame }

constructor TControlPanelFrame.Create(
  AOwner: TComponent;
  const ARCIdent: String);
begin
  FRCIdent := ARCIdent;

  inherited Create(AOwner);
end;

procedure TControlPanelFrame.FrameResized(Sender: TObject);
begin
  PrevButton.Width := NavigateLayout.Width / 2;
  NextButton.Position.X := PrevButton.Position.X + PrevButton.Width;
  NextButton.Width := NavigateLayout.Width / 2;

//  VolumeDownButton.Width := NavigateLayout.Width / 2;
//  VolumeUpButton.Position.X := VolumeDownButton.Position.X + VolumeDownButton.Width;
//  VolumeUpButton.Width := NavigateLayout.Width / 2;

  VolumeDownButton.Width := NavigateLayout.Width / 3;
  VolumePanel.Position.X := VolumeDownButton.Position.X + VolumeDownButton.Width;
  VolumePanel.Width := NavigateLayout.Width / 3;
  VolumeUpButton.Position.X := VolumePanel.Position.X + VolumePanel.Width;
  VolumeUpButton.Width := NavigateLayout.Width / 3;

  Repaint;
end;

procedure TControlPanelFrame.MenuLabelClick(Sender: TObject);
begin
  TMenuManager.OpenMenu(FRCIdent);
end;

end.
