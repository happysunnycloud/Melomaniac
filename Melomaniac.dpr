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
  FileToolsUnit in '..\DevelopmentsCollection\FileToolsUnit.pas',
  PlayListUnit in 'PlayListUnit.pas',
  LockedListExtUnit in '..\DevelopmentsCollection\LockedListExtUnit.pas',
  TAGReaderThreadUnit in 'TAGReaderThreadUnit.pas',
  MouseHandlersUnit in 'MouseHandlersUnit.pas',
  StringToolsUnit in '..\DevelopmentsCollection\StringToolsUnit.pas',
  TimelineTrackerThreadUnit in 'TimelineTrackerThreadUnit.pas',
  PlayControllerUnit in 'PlayControllerUnit.pas',
  ClickListenerThreadUnit in 'ClickListenerThreadUnit.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
