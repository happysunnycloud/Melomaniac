unit ConstantsUnit;

interface

const
  {$IFDEF ANDROID}
  FILE_PATH_SPLITTER = '/';
  {$ELSE IF MSWINDOWS}
  FILE_PATH_SPLITTER = '\';
  {$ENDIF}

  ConfigFileName = 'MelomaniacRemoteControl.conf';

  FORWARD_REWIND_OFF = '>>';
  FORWARD_REWIND_ON = '>>>>';
  BACKWARD_REWIND_OFF = '<<';
  BACKWARD_REWIND_ON = '<<<<';

implementation

end.
