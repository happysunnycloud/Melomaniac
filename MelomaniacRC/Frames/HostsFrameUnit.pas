unit HostsFrameUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, FMX.Objects;

type
  THostButton = class(TButton)
  strict private
  public
  end;

  THostsFrame = class(TFrame)
    ScrollBoxLayout: TLayout;
    ButtonsLayout: TLayout;
    CloseButton: TButton;
    HostsScrollBox: TScrollBox;
    BackgroundRectangle: TRectangle;
  private
    FOnHostNameButtonClick: TNotifyEvent;
  public
    constructor Create(AOwner: TControl); reintroduce;

    procedure AddHost(const AHostName: String);
    property OnHostNameButtonClick: TNotifyEvent write FOnHostNameButtonClick;
  end;

implementation

{$R *.fmx}

{ THostsFrame }

constructor THostsFrame.Create(AOwner: TControl);
begin
  inherited Create(AOwner);
end;

procedure THostsFrame.AddHost(const AHostName: String);
var
  HostButton: THostButton;
begin
  HostButton := THostButton.Create(HostsScrollBox);
  HostButton.Parent := HostsScrollBox;
  HostButton.Text := AHostName;
  HostButton.TextSettings.HorzAlign := TTextAlign.Center;
  HostButton.Height := 44;
  HostButton.Align := TAlignLayout.Top;
  HostButton.OnClick := FOnHostNameButtonClick;
end;

end.
