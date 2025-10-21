unit StateUnit;

interface

type
  TPlayState = (psPlay = 1, psPause = 0, psStop = -1);

  TState = class
  strict private
    class var FPlayState: TPlayState;
    class var FLastPlayState: TPlayState;
  public
    class procedure Init;

    class property PlayState: TPlayState read FPlayState write FPlayState;
    class property LastPlayState: TPlayState read FLastPlayState write FLastPlayState;
  end;

implementation

{ TState }

class procedure TState.Init;
begin
  FPlayState := psStop;
  FLastPlayState := FPlayState;
end;

end.
