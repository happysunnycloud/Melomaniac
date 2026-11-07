unit RCSettingsFormUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.FormExtUnit,
  FMX.Theme, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Edit, FMX.Layouts;

type
  TRCSettingsForm = class(TFormExt)
    PasswordLabel: TLabel;
    PasswordLayout: TLayout;
    PasswordEdit: TEdit;
    RetryPasswordLayout: TLayout;
    RetryPasswordLabel: TLabel;
    RetryPasswordEdit: TEdit;
    OkButton: TButton;
    ButtonsLayout: TLayout;
    CancelButton: TButton;
    PasswordCaptionLayout: TLayout;
    PasswordCaptionLabel: TLabel;
    PortCaptionLayout: TLayout;
    PortCaptionLabel: TLabel;
    PortEdit: TEdit;
    PortLayout: TLayout;
    PortLabel: TLabel;
    ContentLayout: TLayout;
    procedure CancelButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure OkButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  RCSettingsForm: TRCSettingsForm;

implementation

{$R *.fmx}

uses
    CommonConstantsUnit
  , CommonToolsUnit
  , FMX.PasswordEditHelper
  , FMX.MessageBox
  ;


procedure TRCSettingsForm.CancelButtonClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TRCSettingsForm.FormCreate(Sender: TObject);
begin
  TPasswordEditHelper.Create(PasswordEdit);
  TPasswordEditHelper.Create(RetryPasswordEdit);

  SaveFormStateFlag := false;

  TThread.ForceQueue(nil,
    procedure
    begin
      Left := Round((Screen.Width / 2) - (Width / 2));
      Top := Round((Screen.Height / 2) - (Height / 2));

      PasswordCaptionLayout.Align := TAlignLayout.Bottom;
      PasswordLayout.Align := TAlignLayout.Bottom;
      RetryPasswordLayout.Align := TAlignLayout.Bottom;
      PortCaptionLayout.Align := TAlignLayout.Bottom;
      PortLayout.Align := TAlignLayout.Bottom;

      ButtonsLayout.Align := TAlignLayout.Bottom;
    end);

  TThread.ForceQueue(nil,
    procedure
    begin
      PasswordCaptionLayout.Align := TAlignLayout.Top;
      PasswordLayout.Align := TAlignLayout.Top;
      RetryPasswordLayout.Align := TAlignLayout.Top;
      PortCaptionLayout.Align := TAlignLayout.Top;
      PortLayout.Align := TAlignLayout.Top;

      ButtonsLayout.Align := TAlignLayout.Bottom;
    end);
end;

procedure TRCSettingsForm.OkButtonClick(Sender: TObject);
var
  Password: String;
  RetryPassword: String;
begin
  Password := RCSettingsForm.PasswordEdit.Text;
  RetryPassword := RCSettingsForm.RetryPasswordEdit.Text;

  if Password.IsEmpty and RetryPassword.IsEmpty then
  begin
    TMessageBox.Show('The password cannot be empty');

    Exit;
  end;

  if Password <> RetryPassword then
  begin
    TMessageBox.Show('The passwords do not match');

    Exit;
  end;

  if TPasswordEditHelper.IsChanged(PasswordEdit) or
     TPasswordEditHelper.IsChanged(RetryPasswordEdit)
  then
  begin
    if Password.Length < PASSWORD_LENGTH then
    begin
      TMessageBox.Show(
        Format('The password must be at least %s characters long',
          [PASSWORD_LENGTH.ToString]));

      Exit;
    end;
  end;

  ModalResult := mrOk;
end;

end.
