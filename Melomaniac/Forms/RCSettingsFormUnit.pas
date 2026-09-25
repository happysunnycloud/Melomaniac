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
  ;


procedure TRCSettingsForm.CancelButtonClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TRCSettingsForm.FormCreate(Sender: TObject);
begin
  TThread.ForceQueue(nil,
    procedure
    begin
      Left := (Screen.Width div 2) - (Width div 2);
      Top := (Screen.Height div 2) - (Height div 2);

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
    ShowMessage('The password cannot be empty');

    Exit;
  end;

  if Password <> RetryPassword then
  begin
    ShowMessage('The passwords do not match');

    Exit;
  end;

  ModalResult := mrOk;
end;

end.
