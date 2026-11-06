unit PlayListFormUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  System.Generics.Collections,
  FMX.FormExtUnit,
  FMX.Theme,
  PlayListItemFrameUnit,
  PlayListUnit, FMX.Controls.Presentation, FMX.Edit, FMX.StdCtrls
  ;

type
  TPlayListForm = class(TFormExt)
    ScrollBox: TScrollBox;
    SearchLayout: TLayout;
    SearchEdit: TEdit;
    CloseButton: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure CloseButtonClick(Sender: TObject);
    procedure SearchEditKeyUp(Sender: TObject; var Key: Word;
      var KeyChar: WideChar; Shift: TShiftState);
  private
    FPathControlDict: TDictionary<String, TControl>;

    procedure DoBorderMouseDown(
      Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure DoBorderMouseUp(
      Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);

    procedure Search(const ASearchString: String);
    procedure ClearSearch;
  public
    constructor Create(AOwner: TComponent); override;

    function AddFrame(
      const APath: String;
      const ATitle: String;
      const AArtist: String;
      const AAlbum: String;
      const ADuration: String): TPlayListItemFrame;
    procedure DeleteFrame(const APath: String);
    procedure Clear;
    procedure Select(const APath: String);
    procedure ScrollToItem(const APath: String);

    function GetPath(Sender: TObject): String;

    procedure RenumerateItems;

    procedure Refresh(const APlayList: TPlayList);

//    property OnItemClick: TProc<String> read FOnItemClick write FOnItemClick;
  end;

var
  PlayListForm: TPlayListForm;

implementation

{$R *.fmx}

uses
    FMX.ControlToolsUnit
  , StateUnit
  , FMX.SingleSoundUnit
  , PlayListFormMouseHandlersUnit
  , CommonTypesUnit
  , ToolsUnit
  ;

{ TPlayListForm }

constructor TPlayListForm.Create(AOwner: TComponent);
begin
  inherited;

  BorderFrame.OnBorderMouseDown := DoBorderMouseDown;
  BorderFrame.OnBorderMouseUp := DoBorderMouseUp;
end;

procedure TPlayListForm.DoBorderMouseDown(
  Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  ScrollBox.BeginUpdate;
end;

procedure TPlayListForm.DoBorderMouseUp(
  Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  ScrollBox.EndUpdate;
end;

function TPlayListForm.GetPath(Sender: TObject): String;
var
  Control: TControl;
  PlayListItemFrame: TPlayListItemFrame;
  Path: String;
begin
  Result := '';
  Control := Sender as TControl;
  PlayListItemFrame := TControlTools.FindParentFrame(Control) as TPlayListItemFrame;
  if Assigned(PlayListItemFrame) then
  begin
    Path := PlayListItemFrame.PathLabel.Text;
    Select(Path);

    Result := Path;
  end;
end;

procedure TPlayListForm.RenumerateItems;
var
  Control: TControl;
  PlayListItemFrame: TPlayListItemFrame;
  i: Integer;
begin
  if ScrollBox.Content.ControlsCount = 0 then
    Exit;

  i := 0;
  ScrollBox.BeginUpdate;
  try
    for Control in ScrollBox.Content.Controls do
    begin
      Inc(i);

      PlayListItemFrame := Control as TPlayListItemFrame;
      PlayListItemFrame.NumberLabel.Text := i.ToString;
    end;
  finally
    ScrollBox.EndUpdate;
  end;
end;

procedure TPlayListForm.Refresh(const APlayList: TPlayList);
var
  PlayList: TPlayList absolute APlayList;
  PlayItemsList: TPlayItemsList;
  PlayItem: TPlayItem;
begin
  Clear;

  ScrollBox.BeginUpdate;
  try
    PlayItemsList := PlayList.LockList;
    try
      for PlayItem in PlayItemsList do
      begin
        AddFrame(
          PlayItem.Path,
          PlayItem.Title,
          PlayItem.Artist,
          PlayItem.Album,
          TSingleSound.GetHumanTime(PlayItem.Duration));
      end;
    finally
      PlayList.UnLockList;
    end;
  finally
    ScrollBox.EndUpdate;
  end;

  PlayListForm.RenumerateItems;
end;

function TPlayListForm.AddFrame(
  const APath: String;
  const ATitle: String;
  const AArtist: String;
  const AAlbum: String;
  const ADuration: String): TPlayListItemFrame;
var
  PlayListItemFrame: TPlayListItemFrame;
begin
  PlayListItemFrame := TPlayListItemFrame.Create(ScrollBox);
  PlayListItemFrame.Parent := ScrollBox;
  PlayListItemFrame.Align := TAlignLayout.Top;
  PlayListItemFrame.Visible := True;

  PlayListItemFrame.NumberLabel.Text := '0';
  PlayListItemFrame.PathLabel.Text := APath;
  PlayListItemFrame.TitleLabel.Text := ATitle;
  PlayListItemFrame.ArtistLabel.Text := AArtist;
  PlayListItemFrame.AlbumLabel.Text := AAlbum;
  PlayListItemFrame.DurationLabel.Text := ADuration;

  TPlayListFormMouseHandlers.ConnectHandlers([
    PlayListItemFrame.BaseLayout
   ]);

  FPathControlDict.Add(APath, PlayListItemFrame);

  Result := PlayListItemFrame;
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

  RenumerateItems;
end;

procedure TPlayListForm.Clear;
var
  Control: TControl;
begin
  ScrollBox.BeginUpdate;
  try
    for Control in FPathControlDict.Values do
    begin
      ScrollBox.Content.RemoveObject(Control);

      Control.Free;
    end;
  finally
    ScrollBox.EndUpdate;
  end;

  FPathControlDict.Clear;
end;

procedure TPlayListForm.Search(const ASearchString: String);
begin
  ScrollBox.BeginUpdate;
  try
    ScrollBox.ContentControlsEnumerator(
      edForward,
      procedure (const AControl: TControl)
      var
        PlayListItemFrame: TPlayListItemFrame;
      begin
        if AControl is TPlayListItemFrame then
        begin
          PlayListItemFrame := TPlayListItemFrame(AControl);
          AControl.Visible := Pos(ASearchString,
            UpperCase(PlayListItemFrame.PathLabel.Text)) > 0;
        end;
      end)
  finally
    ScrollBox.EndUpdate;
  end;
end;

procedure TPlayListForm.ClearSearch;
var
  i: Integer;
begin
  i := 0;
  ScrollBox.BeginUpdate;
  try
    ScrollBox.ContentControlsEnumerator(
      edForward,
      procedure (const AControl: TControl)
      begin
        if AControl is TPlayListItemFrame then
        begin
          AControl.Position.Y := i * AControl.Height;
          AControl.Visible := true;

          Inc(i);
        end;
      end);
  finally
    ScrollBox.EndUpdate;
  end;

//  TThread.Queue(nil,
//    procedure
//    var
//      i: Integer;
//    begin
//      i := 0;
//      ScrollBox.BeginUpdate;
//      try
//        ScrollBox.ContentControlsEnumerator(
//          edForward,
//          procedure (const AControl: TControl)
//          begin
//            if AControl is TPlayListItemFrame then
//            begin
//              AControl.Visible := true;
//              AControl.Position.Y := i * AControl.Height;
//
//              Inc(i);
//            end;
//          end);
//      finally
//        ScrollBox.EndUpdate;
//      end;
//    end);

//  TThread.Queue(nil,
//    procedure
//    begin
//      ScrollBox.BeginUpdate;
//      try
//        ScrollBox.ContentControlsEnumerator(
//          edBackward,
//          procedure (const AControl: TControl)
//          var
//            PlayListItemFrame: TPlayListItemFrame;
//            Text: String;
//          begin
//            if AControl is TPlayListItemFrame then
//            begin
//              PlayListItemFrame := TPlayListItemFrame(AControl);
//              Text := PlayListItemFrame.PathLabel.Text;
//              AControl.Align := TAlignLayout.Bottom;
//            end;
//          end);
//      finally
//        ScrollBox.EndUpdate;
//      end;
//    end);
//
//  TThread.Queue(nil,
//    procedure
//    begin
//      ScrollBox.BeginUpdate;
//      try
//        ScrollBox.ContentControlsEnumerator(
//          edForward,
//          procedure (const AControl: TControl)
//          begin
//            if AControl is TPlayListItemFrame then
//            begin
//              AControl.Visible := true;
//            end;
//          end);
//      finally
//        ScrollBox.EndUpdate;
//      end;
//    end);
//
//  TThread.Queue(nil,
//    procedure
//    begin
//      ScrollBox.BeginUpdate;
//      try
//        ScrollBox.ContentControlsEnumerator(
//          edForward,
//          procedure (const AControl: TControl)
//          begin
//            if AControl is TPlayListItemFrame then
//            begin
//              AControl.Align := TAlignLayout.Top;
//            end;
//          end);
//      finally
//        ScrollBox.EndUpdate;
//      end;
//    end);
//
//  TThread.Queue(nil,
//    procedure
//    begin
//      ScrollBox.RealignContent;
//    end);
end;

procedure TPlayListForm.CloseButtonClick(Sender: TObject);
begin
  Close;
end;

procedure TPlayListForm.SearchEditKeyUp(Sender: TObject; var Key: Word;
  var KeyChar: WideChar; Shift: TShiftState);
var
  SearchString: String;
begin
  SearchString := UpperCase(Trim(SearchEdit.Text));

  if not SearchString.IsEmpty then
    Search(SearchString)
  else
    ClearSearch;
end;

procedure TPlayListForm.Select(const APath: String);
var
  PlayListItemFrame: TPlayListItemFrame;
  Control: TControl;

  ViewportRect: TRectF;
  ControlRect: TRectF;
begin
  if ScrollBox.Content.ControlsCount = 0 then
    Exit;

  ScrollBox.BeginUpdate;
  try
    for Control in ScrollBox.Content.Controls do
    begin
      PlayListItemFrame := Control as TPlayListItemFrame;
      PlayListItemFrame.BackgroundRectangle.Fill.Color :=
        Theme.ItemSettings.NormalBackgroundColor;
    end;
  finally
    ScrollBox.EndUpdate;
  end;

  FPathControlDict.TryGetValue(APath, Control);
  if not Assigned(Control) then
    Exit;

  PlayListItemFrame := Control as TPlayListItemFrame;

  // Визуальная парковка ScrollBox на текущий трек

  ViewportRect := TRectF.Create(
    ScrollBox.ViewportPosition,
    ScrollBox.ViewportPosition +
      PointF(ScrollBox.Content.Width, ScrollBox.Content.Height));

  ControlRect := TRectF.Create(
    PlayListItemFrame.Position.X,
    PlayListItemFrame.Position.Y,
    PlayListItemFrame.Position.X + PlayListItemFrame.Width,
    PlayListItemFrame.Position.Y + PlayListItemFrame.Height);

  if not ViewportRect.Contains(ControlRect) then
    ScrollBox.ViewportPosition :=
      PointF(0, PlayListItemFrame.Index * PlayListItemFrame.Height);

  TThread.ForceQueue(nil,
    procedure
    begin
      PlayListItemFrame.BackgroundRectangle.Fill.Color :=
        Theme.ItemSettings.FocusedBackgroundColor;
    end);
end;

procedure TPlayListForm.ScrollToItem(const APath: String);
var
  PlayListItemFrame: TPlayListItemFrame;
  Control: TControl;
begin
  FPathControlDict.TryGetValue(APath, Control);
  if not Assigned(Control) then
    Exit;

  PlayListItemFrame := Control as TPlayListItemFrame;

  ScrollBox.ScrollTo(PlayListItemFrame);
end;

procedure TPlayListForm.FormCreate(Sender: TObject);
begin
  Self.Fill.Kind := TBrushKind.Solid;
  FPathControlDict := TDictionary<String, TControl>.Create;

  TTools.HeighlightChangeView(true);
end;

procedure TPlayListForm.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FPathControlDict);

  TTools.HeighlightChangeView(false);

  PlayListForm := nil;
end;

end.
