unit SetPasswordFormUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.FormExtUnit,
  FMX.Theme, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Edit, FMX.Layouts;

type
  TSetPasswordForm = class(TFormExt)
    PasswordLabel: TLabel;
    PasswordLayout: TLayout;
    PasswordEdit: TEdit;
    RetryPasswordLayout: TLayout;
    RetryPasswordLabel: TLabel;
    RetryPasswordEdit: TEdit;
    OkButton: TButton;
    ButtonsLayout: TLayout;
    CancelButton: TButton;
    procedure CancelButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure OkButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  SetPasswordForm: TSetPasswordForm;

implementation

{$R *.fmx}

procedure TSetPasswordForm.CancelButtonClick(Sender: TObject);
begin
  ModalResult := mrCancel;
//  TThread.ForceQueue(nil,
//    procedure
//    begin
//      Close;
//    end);
end;

procedure TSetPasswordForm.FormCreate(Sender: TObject);
begin
  TThread.ForceQueue(nil,
    procedure
    begin
      Left := (Screen.Width div 2) - (Width div 2);
      Top := (Screen.Height div 2) - (Height div 2);
    end);
end;

procedure TSetPasswordForm.OkButtonClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

end.
