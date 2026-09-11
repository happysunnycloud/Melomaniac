unit MenuManagerUnit;

interface

uses
    FMX.Types
  , MenuFrameUnit
  , TypesUnit
  ;

type
  TMenuManager = class
  strict private
    class var FMenuFrame: TMenuFrame;
    class var FParent: TFmxObject;
    class var FOnClose: TCloseMenuEvent;

    class procedure DoClose(Sender: TObject);
  public
    class procedure Init(const AParent: TFmxObject);

    class procedure OpenMenu(const ARCIdent: String);

    class property OnClose: TCloseMenuEvent read FOnClose write FOnClose;
  end;

implementation

uses
    System.SysUtils
  , System.Classes
  ;

{ TMenuManager }

class procedure TMenuManager.Init(const AParent: TFmxObject);
begin
  if not Assigned(AParent) then
    raise Exception.Create('Parent is nil');

  FParent := AParent;
  FMenuFrame := nil;
  FOnClose := nil;
end;

class procedure TMenuManager.DoClose(Sender: TObject);
var
  MenuFrame: TMenuFrame;
begin
  MenuFrame := FMenuFrame;
  TThread.ForceQueue(nil,
    procedure
    begin
      FreeAndNil(MenuFrame);
    end);
  TThread.ForceQueue(nil,
    procedure
    begin
      FOnClose(nil);
    end);
end;

class procedure TMenuManager.OpenMenu(const ARCIdent: String);
begin
  if not Assigned(FParent) then
    raise Exception.Create('Parent is nil');

  if not Assigned(FOnClose) then
    raise Exception.Create('OnClose is nil');

  FMenuFrame := TMenuFrame.Create(ARCIdent);
  FMenuFrame.Parent := FParent;
  FMenuFrame.Align := TAlignLayout.Contents;
  FMenuFrame.CloseButton.OnClick := DoClose;
  FMenuFrame.AddHostButton.Enabled := ARCIdent.IsEmpty;
  FMenuFrame.EditHostButton.Enabled := not ARCIdent.IsEmpty;
  FMenuFrame.DeleteHostButton.Enabled := not ARCIdent.IsEmpty;
end;

end.
