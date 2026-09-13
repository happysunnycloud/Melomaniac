program MelomaniacRC;

uses
  System.StartUpCopy,
  FMX.Forms,
  MelomaniacRCUnit in 'MelomaniacRCUnit.pas' {MainForm},
  HostNameResolverUnit in '..\DevelopmentsCollection\HostNameResolverUnit.pas',
  PoolUnit in 'PoolUnit.pas',
  ToolsUnit in 'ToolsUnit.pas',
  ConstantsUnit in 'ConstantsUnit.pas',
  TypesUnit in 'TypesUnit.pas',
  MenuManagerUnit in 'MenuManagerUnit.pas',
  AppManagerUnit in 'AppManagerUnit.pas',
  RCFunctionManagerUnit in 'RCFunctionManagerUnit.pas',
  Net.Client in 'Net.Client.pas',
  SafeQueueThread in '..\DevelopmentsCollection\SafeQueueThread\SafeQueueThread.pas',
  SafeQueueThreadSignal in '..\DevelopmentsCollection\SafeQueueThread\SafeQueueThreadSignal.pas',
  Net.RequestHeaders in '..\MelomaciacCommon\Net.RequestHeaders.pas',
  Net.ResponseHeaders in '..\MelomaciacCommon\Net.ResponseHeaders.pas',
  CommonTypesUnit in '..\MelomaciacCommon\CommonTypesUnit.pas',
  CommonConstantsUnit in '..\MelomaciacCommon\CommonConstantsUnit.pas',
  CryptoUtils in '..\MelomaciacCommon\CryptoUtils.pas',
  HostsFrameUnit in 'Frames\HostsFrameUnit.pas' {HostsFrame: TFrame},
  MenuFrameUnit in 'Frames\MenuFrameUnit.pas' {MenuFrame: TFrame},
  EditHostFrameUnit in 'Frames\EditHostFrameUnit.pas' {EditHostFrame: TFrame},
  ControlPanelFrameUnit in 'Frames\ControlPanelFrameUnit.pas' {ControlPanelFrame: TFrame},
  HostScanner in '..\..\DevelopmentsCollection\HostScanner\HostScanner.pas',
  CommonToolsUnit in '..\MelomaciacCommon\CommonToolsUnit.pas'
  {$IFDEF MSWINDOWS}
  , Windows.LocalIPs in '..\..\DevelopmentsCollection\HostScanner\Windows.LocalIPs.pas'
  {$ELSE IFDEF ANDROID}
  , Android.LocalIPs in '..\..\DevelopmentsCollection\HostScanner\Android.LocalIPs.pas'
  {$ENDIF}
  ;

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
