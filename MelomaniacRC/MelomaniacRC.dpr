program MelomaniacRC;

uses
  System.StartUpCopy,
  FMX.Forms,
  MelomaniacRCUnit in 'MelomaniacRCUnit.pas' {MainForm},
  HostNameResolverUnit in '..\DevelopmentsCollection\HostNameResolverUnit.pas',
  PoolUnit in 'PoolUnit.pas',
  ToolsUnit in 'ToolsUnit.pas',
  ConstantsUnit in 'ConstantsUnit.pas',
  MenuFrameUnit in 'MenuFrameUnit.pas' {MenuFrame: TFrame},
  EditHostFrameUnit in 'EditHostFrameUnit.pas' {EditHostFrame: TFrame},
  TypesUnit in 'TypesUnit.pas',
  MenuManagerUnit in 'MenuManagerUnit.pas',
  AppManagerUnit in 'AppManagerUnit.pas',
  RCFunctionManagerUnit in 'RCFunctionManagerUnit.pas',
  Net.Client in 'Net.Client.pas',
  SafeQueueThread in '..\DevelopmentsCollection\SafeQueueThread\SafeQueueThread.pas',
  SafeQueueThreadSignal in '..\DevelopmentsCollection\SafeQueueThread\SafeQueueThreadSignal.pas',
  Net.RequestHeaders in '..\MelomaciacCommon\Net.RequestHeaders.pas',
  Net.ResponseHeaders in '..\MelomaciacCommon\Net.ResponseHeaders.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
