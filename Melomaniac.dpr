program Melomaniac;

uses
  System.StartUpCopy,
  FMX.Forms,
  MelomaniacUnit in 'MelomaniacUnit.pas' {MainForm},
  FMX.SingleSoundUnit in '..\DevelopmentsCollection\FMX.SingleSoundUnit.pas',
  ThreadFactoryUnit in '..\DevelopmentsCollection\ThreadFactoryUnit.pas',
  ThreadRegistryUnit in '..\DevelopmentsCollection\ThreadRegistryUnit.pas',
  ParamsExtUnit in '..\DevelopmentsCollection\ParamsExtUnit.pas',
  FMX.FormExtUnit in '..\DevelopmentsCollection\FMX.FormExtUnit.pas',
  ThreadFactoryRegistryUnit in '..\DevelopmentsCollection\ThreadFactoryRegistryUnit.pas',
  ObjectRegistryUnit in '..\DevelopmentsCollection\ObjectRegistryUnit.pas',
  PlayListUnit in 'PlayListUnit.pas',
  LockedListExtUnit in '..\DevelopmentsCollection\LockedListExtUnit.pas',
  MouseHandlersUnit in 'MouseHandlersUnit.pas',
  StringToolsUnit in '..\DevelopmentsCollection\StringToolsUnit.pas',
  PlayControllerUnit in 'PlayControllerUnit.pas',
  StateUnit in 'StateUnit.pas',
  ConstantsUnit in 'ConstantsUnit.pas',
  FMX.MultiResBitmapExtractorUnit in '..\DevelopmentsCollection\FilePacker\FMX.MultiResBitmapExtractorUnit.pas',
  FMX.MultiResBitmapsUnit in '..\DevelopmentsCollection\FMX.MultiResBitmapsUnit.pas',
  VisualSchemeUnit in 'VisualSchemeUnit.pas',
  FilePackerUnit in '..\DevelopmentsCollection\FilePacker\FilePackerUnit.pas',
  FMX.ControlToolsUnit in '..\DevelopmentsCollection\FMX.ControlToolsUnit.pas',
  BitmapStorageUnit in 'BitmapStorageUnit.pas',
  ToolsUnit in 'ToolsUnit.pas',
  FMX.PopupMenuExtUnit in '..\DevelopmentsCollection\FMX.PopupMenuExt\FMX.PopupMenuExtUnit.pas',
  FMX.PopupMenuExtFormUnit in '..\DevelopmentsCollection\FMX.PopupMenuExt\FMX.PopupMenuExtFormUnit.pas',
  FMX.PopupMenuExtThreadUnit in '..\DevelopmentsCollection\FMX.PopupMenuExt\FMX.PopupMenuExtThreadUnit.pas',
  FMX.ThemeUnit in '..\DevelopmentsCollection\FMX.ThemeUnit.pas',
  DebugUnit in '..\DevelopmentsCollection\DebugUnit.pas',
  FileToolsUnit in '..\DevelopmentsCollection\FileToolsUnit.pas',
  AudioFormatDetectorUnit in 'AudioFormatDetectorUnit.pas',
  BaseDBAccessUnit in '..\DevelopmentsCollection\SQL\BaseDBAccessUnit.pas',
  DBToolsUnit in '..\DevelopmentsCollection\SQLite\DBToolsUnit.pas',
  SQLTemplatesUnit in '..\DevelopmentsCollection\SQL\SQLTemplatesUnit.pas',
  TextExtractorUnit in '..\DevelopmentsCollection\FilePacker\TextExtractorUnit.pas',
  DBExceptionContainerUnit in '..\DevelopmentsCollection\SQL\DBExceptionContainerUnit.pas',
  DBAccessUnit in 'DBAccessUnit.pas',
  FlacTAGReaderUnit in 'TAGReaders\FlacTAGReaderUnit.pas',
  MP3TAGsReaderUnit in 'TAGReaders\MP3TAGsReaderUnit.pas',
  OGGTAGReaderUnit in 'TAGReaders\OGGTAGReaderUnit.pas',
  TAGReaderThreadUnit in 'TAGReaders\TAGReaderThreadUnit.pas',
  WAVTAGReaderUnit in 'TAGReaders\WAVTAGReaderUnit.pas',
  FMX.HintFormUnit in '..\DevelopmentsCollection\FMX.Hint\FMX.HintFormUnit.pas',
  FMX.HintThreadUnit in '..\DevelopmentsCollection\FMX.Hint\FMX.HintThreadUnit.pas',
  FMX.HintUnit in '..\DevelopmentsCollection\FMX.Hint\FMX.HintUnit.pas',
  FMX.TrayIcon.Win in '..\DevelopmentsCollection\FMX.TrayIcon.Win.pas',
  BorderFrameUnit in '..\DevelopmentsCollection\BorderFrame\BorderFrameUnit.pas' {BorderFrame: TFrame},
  FMX.ImageToolsUnit in '..\DevelopmentsCollection\FMX.ImageToolsUnit.pas',
  BorderFrameTypesUnit in '..\DevelopmentsCollection\BorderFrame\BorderFrameTypesUnit.pas',
  TimelineTrackerThreadUnit in 'Threads\TimelineTrackerThreadUnit.pas',
  HeighlightFailThreadUnit in 'Threads\HeighlightFailThreadUnit.pas',
  ClickListenerThreadUnit in 'Threads\ClickListenerThreadUnit.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
