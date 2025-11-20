program Melomaniac;

uses
  System.StartUpCopy,
  FMX.Forms,
  MelomaniacUnit in 'MelomaniacUnit.pas' {MainForm},
  FMX.SingleSoundUnit in '..\DevelopmentsCollection\FMX.SingleSoundUnit.pas',
  MP3TAGsReaderUnit in 'MP3TAGsReaderUnit.pas',
  ThreadFactoryUnit in '..\DevelopmentsCollection\ThreadFactoryUnit.pas',
  ThreadRegistryUnit in '..\DevelopmentsCollection\ThreadRegistryUnit.pas',
  ParamsExtUnit in '..\DevelopmentsCollection\ParamsExtUnit.pas',
  FMX.FormExtUnit in '..\DevelopmentsCollection\FMX.FormExtUnit.pas',
  ThreadFactoryRegistryUnit in '..\DevelopmentsCollection\ThreadFactoryRegistryUnit.pas',
  ObjectRegistryUnit in '..\DevelopmentsCollection\ObjectRegistryUnit.pas',
  PlayListUnit in 'PlayListUnit.pas',
  LockedListExtUnit in '..\DevelopmentsCollection\LockedListExtUnit.pas',
  TAGReaderThreadUnit in 'TAGReaderThreadUnit.pas',
  MouseHandlersUnit in 'MouseHandlersUnit.pas',
  StringToolsUnit in '..\DevelopmentsCollection\StringToolsUnit.pas',
  TimelineTrackerThreadUnit in 'TimelineTrackerThreadUnit.pas',
  PlayControllerUnit in 'PlayControllerUnit.pas',
  ClickListenerThreadUnit in 'ClickListenerThreadUnit.pas',
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
  HeighlightFailThreadUnit in 'HeighlightFailThreadUnit.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
