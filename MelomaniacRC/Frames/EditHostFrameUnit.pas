unit EditHostFrameUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Edit, FMX.Controls.Presentation, FMX.Objects, FMX.Layouts
  , PoolUnit
  , TypesUnit
  , HostsFrameUnit
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
    ScanHostsButton: TButton;
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
    procedure ScanHostsButtonClick(Sender: TObject);
  strict private
    FRC: TMRC;
    FEditFrameMode: TEditFrameMode;
    FHostsFrame: THostsFrame;

    procedure DoCloseHostsFrame(Sender: TObject);
    procedure DoHostNameButtonClick(Sender: TObject);
  public
    constructor Create(
      const ARC: TMRC;
      const AEditFrameMode: TEditFrameMode); reintroduce;
    destructor Destroy; override;
  end;

implementation

{$R *.fmx}

uses
    ToolsUnit
  , CryptoUtils
  , CommonConstantsUnit
  , AppManagerUnit
  , StringToolsUnit
  , CommonToolsUnit
  , FMX.PasswordEditHelper
  , NET.UDPLocator
  ;

{ TEditHostFrame }

constructor TEditHostFrame.Create(
  const ARC: TMRC;
  const AEditFrameMode: TEditFrameMode);
begin
  FRC := ARC;
  FEditFrameMode := AEditFrameMode;
  FHostsFrame := nil;

  inherited Create(nil);

  TPasswordEditHelper.Create(PasswordEdit);
  TPasswordEditHelper.Create(RetryPasswordEdit);

  if not Assigned(FRC) then
    Exit;

  HostNameEdit.Text := FRC.HostName;
  IPEdit.Text := FRC.IP;
  PortEdit.Text := FRC.Port.ToString;
end;

destructor TEditHostFrame.Destroy;
begin
  DoCloseHostsFrame(nil);

  inherited;
end;

procedure TEditHostFrame.SaveButtonClick(Sender: TObject);
var
  HostName: String;
  IP: String;
  Port: String;
  Password: String;
  RetryPassword: String;
  RC: TMRC;
begin
  Password := '';

  HostName := Trim(HostNameEdit.Text);
  IP := Trim(IPEdit.Text);
  Port := Trim(PortEdit.Text);

  if (Length(Trim(HostName)) = 0) and (Length(Trim(IP)) = 0) then
  begin
    ShowMessage('The "Host name" or "IP" field can not be empty' );

    Exit;
  end;

  if PortEdit.Text.IsEmpty or RetryPasswordEdit.Text.IsEmpty then
  begin
    ShowMessage('The password cannot be empty');

    Exit;
  end;

  if PortEdit.Text.IsEmpty then
  begin
    ShowMessage('The port cannot be empty');

    Exit;
  end;

  if Password <> RetryPassword then
  begin
    ShowMessage('Passwords do not match');

    Exit;
  end;

  if TPasswordEditHelper.IsChanged(PasswordEdit) or
     TPasswordEditHelper.IsChanged(RetryPasswordEdit)
  then
  begin
    if Trim(PasswordEdit.Text).Length < PASSWORD_LENGTH then
    begin
      ShowMessage(
        Format('The password must be at least %s characters long',
          [PASSWORD_LENGTH.ToString]));

      Exit;
    end;

    Password := Trim(PasswordEdit.Text);
    RetryPassword := Trim(RetryPasswordEdit.Text);

    Password := TCryptoUtils.EncryptString(Password, TTools.GetCryptoKey);
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

    if not IP.IsEmpty then
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

    if not IP.IsEmpty then
      if AppManager.RCPool.IsIPExists(IP) then
      begin
        ShowMessage(Format('Then IP "%s" exists', [IP]));

        Exit;
      end;
  end;

  if (Length(Trim(IP)) > 0)
      and
      not TStringTools.IsIP4(Trim(IP))
  then
  begin
    ShowMessage('The "IP" is incorrect' );

    Exit;
  end;

  if not TCommonTools.CheckCorrectPort(Port) then
    Exit;

  if FEditFrameMode = efmAdd then
  begin
    RC := AppManager.RCPool.AddRC(
      HostName,
      IP,
      Word(Port.ToInteger),
      Password);
    RC.RCControlFrame.TopSplitterRectangle.Height := 0;
  end
  else
  if FEditFrameMode = efmEdit then
  begin
    FRC.HostName := HostName;
    FRC.IP := IP;
    FRC.Port := Word(Port.ToInteger);
    if not Password.IsEmpty then
      FRC.Password := Password;
    FRC.RCControlFrame.UpdateInfo(FRC.HostName);
    FRC.NetClient.Disconnect;
  end;

  TTools.SaveHosts;
end;

procedure TEditHostFrame.DoCloseHostsFrame(Sender: TObject);
begin
  FreeAndNil(FHostsFrame);
end;

procedure TEditHostFrame.DoHostNameButtonClick(Sender: TObject);
var
  Host: String;
  HostName: String;
  Address: String;
  P: Integer;
begin
  Host := TButton(Sender).Text;
  Host := StringReplace(Host, ' ', '', [rfReplaceAll, rfIgnoreCase]);

  P := Pos('::', Host);
  HostName := Copy(Host, 1, P - 1);
  Address := Copy(Host, P + '::'.Length, Host.Length);

  HostNameEdit.Text := HostName;
  IPEdit.Text := Address;

  DoCloseHostsFrame(nil);
end;

procedure TEditHostFrame.ScanHostsButtonClick(Sender: TObject);
var
  Locator: TUDPLocator;
  Responses: TUDPResponses;
  Response: TUDPResponse;
  Port: String;
begin
  Port := Trim(PortEdit.Text);
  if not TCommonTools.CheckCorrectPort(Port) then
    Exit;

  FHostsFrame := THostsFrame.Create(Self);
  FHostsFrame.Parent := ContentLayout;
  FHostsFrame.Align := TAlignLayout.Contents;
  FHostsFrame.Visible := true;
  FHostsFrame.CloseButton.OnClick := DoCloseHostsFrame;
  FHostsFrame.OnHostNameButtonClick := DoHostNameButtonClick;

  Locator := TUDPLocator.Create;
  try
    Responses := Locator.Locate(Word(Port.ToInteger));
    for Response in Responses do
    begin
      FHostsFrame.AddHost(Response.Data + ' :: ' + Response.IP);
    end;
  finally
    FreeAndNil(Locator);
  end;
end;

end.

