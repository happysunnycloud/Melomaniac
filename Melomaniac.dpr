program Melomaniac;

uses
  System.StartUpCopy,
  FMX.Forms,
  MelomaniacUnit in 'MelomaniacUnit.pas' {MainForm},
  FMX.SingleSoundUnit in 'C:\Desktop\DevelopmentsCollection\FMX.SingleSoundUnit.pas',
  MP3TAGsReaderUnit in 'MP3TAGsReaderUnit.pas',
  ThreadFactoryUnit in 'C:\Desktop\DevelopmentsCollection\ThreadFactoryUnit.pas',
  ThreadRegistryUnit in 'C:\Desktop\DevelopmentsCollection\ThreadRegistryUnit.pas',
  ParamsExtUnit in 'C:\Desktop\DevelopmentsCollection\ParamsExtUnit.pas',
  FMX.FormExtUnit in 'C:\Desktop\DevelopmentsCollection\FMX.FormExtUnit.pas',
  ThreadFactoryRegistryUnit in 'C:\Desktop\DevelopmentsCollection\ThreadFactoryRegistryUnit.pas',
  ObjectRegistryUnit in 'C:\Desktop\DevelopmentsCollection\ObjectRegistryUnit.pas',
  FileToolsUnit in 'C:\Desktop\DevelopmentsCollection\FileToolsUnit.pas',
  PlayListUnit in 'PlayListUnit.pas',
  LockedListExtUnit in 'C:\Desktop\DevelopmentsCollection\LockedListExtUnit.pas',
  TAGReaderThreadUnit in 'TAGReaderThreadUnit.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
