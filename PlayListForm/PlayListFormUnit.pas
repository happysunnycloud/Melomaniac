unit PlayListFormUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  System.Generics.Collections,
  FMX.FormExtUnit,
  FMX.ThemeUnit
  ;

type
  TPlayListForm = class(TFormExt)
    ScrollBox: TScrollBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FPathControlDict: TDictionary<String, TControl>;
    procedure OnPlayListItemFrameClickHandler(Sender: TObject);
  public
    procedure AddFrame(
      const APath: String;
      const ATitle: String;
      const AArtist: String;
      const AAlbum: String;
      const ADuration: String);
    procedure DeleteFrame(const APath: String);
    procedure Select(const APath: String);
    procedure ScrollToItem(const APath: String);
  end;

var
  PlayListForm: TPlayListForm;

implementation

{$R *.fmx}

uses
    PlayListItemFrameUnit
  , FMX.ControlToolsUnit
  ;

{ TPlayListForm }

procedure TPlayListForm.OnPlayListItemFrameClickHandler(Sender: TObject);
var
  PlayListItemFrame: TPlayListItemFrame;
begin
  if Sender is TPlayListItemFrame then
  begin
    PlayListItemFrame := Sender as TPlayListItemFrame;
    Select(PlayListItemFrame.PathLabel.Text);
  end;
end;

procedure TPlayListForm.AddFrame(
  const APath: String;
  const ATitle: String;
  const AArtist: String;
  const AAlbum: String;
  const ADuration: String);
var
  PlayListItemFrame: TPlayListItemFrame;
begin
  PlayListItemFrame := TPlayListItemFrame.Create(ScrollBox);
  PlayListItemFrame.Parent := ScrollBox;
  PlayListItemFrame.Align := TAlignLayout.Top;
  PlayListItemFrame.Visible := True;

  PlayListItemFrame.PathLabel.Text := APath;
  PlayListItemFrame.TitleLabel.Text := ATitle;
  PlayListItemFrame.ArtistLabel.Text := AArtist;
  PlayListItemFrame.AlbumLabel.Text := AAlbum;
  PlayListItemFrame.DurationLabel.Text := ADuration;

  PlayListItemFrame.OnClick := OnPlayListItemFrameClickHandler;

  FPathControlDict.Add(APath, PlayListItemFrame);
end;

procedure TPlayListForm.DeleteFrame(const APath: String);
var
  Control: TControl;
begin
  FPathControlDict.TryGetValue(APath, Control);

  if not Assigned(Control) then
    Exit;

  ScrollBox.BeginUpdate;
  try
    ScrollBox.Content.RemoveObject(Control);
    ScrollBox.RealignContent;
  finally
    ScrollBox.EndUpdate;
  end;

  Control.Free;
end;

procedure TPlayListForm.Select(const APath: String);
var
  PlayListItemFrame: TPlayListItemFrame;
  Control: TControl;
begin
  if ScrollBox.Content.ControlsCount = 0 then
    Exit;

  ScrollBox.BeginUpdate;
  try
    for Control in ScrollBox.Content.Controls do
    begin
      PlayListItemFrame := Control as TPlayListItemFrame;
      PlayListItemFrame.BackgroundRectangle.Fill.Color := Theme.NormalBackgroundColor;
    end;
  finally
    ScrollBox.EndUpdate;
  end;

  FPathControlDict.TryGetValue(APath, Control);
  if not Assigned(Control) then
    Exit;

  PlayListItemFrame := Control as TPlayListItemFrame;
  PlayListItemFrame.BackgroundRectangle.Fill.Color := Theme.FocusedBackgroundColor;
end;

procedure TPlayListForm.ScrollToItem(const APath: String);
var
  PlayListItemFrame: TPlayListItemFrame;
  Control: TControl;
  PointF: TPointF;
begin
  FPathControlDict.TryGetValue(APath, Control);
  if not Assigned(Control) then
    Exit;

  PlayListItemFrame := Control as TPlayListItemFrame;

  PointF.X := PlayListItemFrame.Position.X;
  PointF.Y := PlayListItemFrame.Position.Y;
  PointF := PlayListItemFrame.LocalToAbsolute(PointF);
  ScrollBox.ViewportPosition := PointF;
end;

procedure TPlayListForm.FormCreate(Sender: TObject);
begin
  Self.Fill.Kind := TBrushKind.Solid;
  FPathControlDict := TDictionary<String, TControl>.Create;
  Theme.OnApplyProcRef :=
    procedure
    var
      //Control: TControl;
      PlayListItemFrame: TPlayListItemFrame;
    begin
      Self.Fill.Color := Theme.BackgroundColor;
      ScrollBox.ControlsEnumerator(
        procedure (const AControl: TControl)
        begin
          if not (AControl is TPlayListItemFrame) then
            Exit;

          PlayListItemFrame := AControl as TPlayListItemFrame;
          PlayListItemFrame.BackgroundRectangle.Fill.Color := Theme.NormalBackgroundColor;
        end);

//      for Control in ScrollBox.Content.Controls do
//      begin
//        PlayListItemFrame := Control as TPlayListItemFrame;
//        PlayListItemFrame.BackgroundRectangle.Fill.Color := Theme.NormalBackgroundColor;
//      end;
    end;
end;

procedure TPlayListForm.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FPathControlDict);
end;

end.
