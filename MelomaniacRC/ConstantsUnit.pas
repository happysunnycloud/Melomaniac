unit ConstantsUnit;

interface

const
  {$IFDEF ANDROID}
  FILE_PATH_SPLITTER = '/';
  {$ELSE IF MSWINDOWS}
  FILE_PATH_SPLITTER = '\';
  {$ENDIF}

  ConfigFileName = 'MelomaniacRemoteControl.conf';

implementation

end.
