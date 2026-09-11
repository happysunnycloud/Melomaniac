unit EditHostFrameUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Edit, FMX.Controls.Presentation, FMX.Objects, FMX.Layouts
  , PoolUnit
  , TypesUnit
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
    PasswordLayout: TLayout;
    RetryPasswordLayout: TLayout;
    PasswordLabel: TLabel;
    RetryPasswordLabel: TLabel;
    PasswordEdit: TEdit;
    RetryPasswordEdit: TEdit;
    procedure SaveButtonClick(Sender: TObject);
  strict private
    FRC: TMRC;
    FEditFrameMode: TEditFrameMode;
  public
    constructor Create(
      const ARC: TMRC;
      const AEditFrameMode: TEditFrameMode); reintroduce;
  end;

implementation

{$R *.fmx}

uses
    ToolsUnit
  , CryptoUtils
  , AppManagerUnit
  , StringToolsUnit
  ;

{ TEditHostFrame }

constructor TEditHostFrame.Create(
  const ARC: TMRC;
  const AEditFrameMode: TEditFrameMode);
begin
  FRC := ARC;
  FEditFrameMode := AEditFrameMode;

  inherited Create(nil);

  if not Assigned(FRC) then
    Exit;

  HostNameEdit.Text := FRC.HostName;
  IPEdit.Text := FRC.IP;
  PortEdit.Text := FRC.Port.ToString;
end;

procedure TEditHostFrame.SaveButtonClick(Sender: TObject);
var
  HostName: String;
  IP: String;
  Port: String;
  WPort: Word;
  Password: String;
  RetryPassword: String;
  RC: TMRC;
begin
  HostName := Trim(HostNameEdit.Text);
  IP := Trim(IPEdit.Text);
  Port := Trim(PortEdit.Text);

  Password := Trim(PasswordEdit.Text);
  RetryPassword := Trim(RetryPasswordEdit.Text);
  if Password.IsEmpty or RetryPassword.IsEmpty then
  begin
    ShowMessage('The password cannot be empty');

    Exit;
  end;

  if Password <> RetryPassword then
  begin
    ShowMessage('Passwords do not match');

    Exit;
  end;

  Password := TCryptoUtils.EncryptString(Password, TTools.GetCryptoKey);

  if (Length(Trim(HostName)) = 0) and (Length(Trim(IP)) = 0) then
  begin
    ShowMessage('The "Host name" or "IP" field can not be empty' );

    Exit;
  end;

  if Assigned(FRC) then
  begin
    AppManager.RCPool.TryGetRC(FRC.Ident, RC);
    if FRC <> RC then
      if AppManager.RCPool.IsHostNameExists(HostName) then
      begin
        ShowMessage(Format('Then host name "%s" exists', [HostName]));

        Exit;
      end;

    if FRC <> RC then
      if AppManager.RCPool.IsIPExists(IP) then
      begin
        ShowMessage(Format('Then IP "%s" exists', [IP]));

        Exit;
      end;
  end
  else
  begin
    if AppManager.RCPool.IsHostNameExists(HostName) then
    begin
      ShowMessage(Format('Then host name "%s" exists', [HostName]));

      Exit;
    end;

    if AppManager.RCPool.IsIPExists(IP) then
    begin
      ShowMessage(Format('Then IP "%s" exists', [IP]));

      Exit;
    end;
  end;

  if (Length(Trim(IP)) > 0)
      and
      { TODO: TStringTools.IsIP4 Плохо проверяет IP адрес на корректность, нужно отладить}
      not TStringTools.IsIP4(Trim(IP))
  then
  begin
    ShowMessage('The "IP" is incorrect' );

    Exit;
  end;

  if Length(Trim(Port)) = 0 then
  begin
    ShowMessage('The "Port" field can not be empty' );

    Exit;
  end;

  if not TStringTools.IsContainsOnlyDigits(Port) then
  begin
    ShowMessage('The "Port" field can only contain numbers' );

    Exit;
  end;

  WPort := Word(Trim(PortEdit.Text).ToInteger);

  if not ((WPort > 0) and (WPort < 65000)) then
  begin
    ShowMessage('The "Port" value out of range. Must be between 1 and 65K' );

    Exit;
  end;

  if FEditFrameMode = efmAdd then
  begin
    AppManager.RCPool.AddRC(
      HostName,
      IP,
      WPort,
      Password);
  end
  else
  if FEditFrameMode = efmEdit then
  begin
    FRC.HostName := HostName;
    FRC.IP := IP;
    FRC.Port := WPort;
    FRC.Password := Password;
    FRC.RCControlFrame.UpdateInfo(FRC.HostName);
  end;

  TTools.SaveHosts;
end;

end.
