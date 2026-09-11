unit TypesUnit;

interface

type
  TCloseMenuEvent = procedure(Sender: TObject) of object;

  TEditHostFormKind = (fkAdd, fkEdit);
  TMenuFormMode = (fmCommon, fmUnit);
  TEditFrameMode = (efmNone, efmAdd, efmEdit);

  THostCallbackProc = reference to procedure (
    const AHostName: String;
    const AIP: String;
    const APort: Word;
    const APassword: String);

implementation

end.
