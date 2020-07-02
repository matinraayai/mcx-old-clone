;;======================================================================
;; Inno Setup Script for MCX Studio and MCX Suite Windows Installer
;;
;; Author: Qianqian Fang <q.fang at neu.edu>
;; Initially added on Jun. 28, 2020
;; URL: http://mcx.space
;; Github: http://github.com/fangq/mcx
;;
;;======================================================================

#define MyAppName "MCX Studio"
#define MyAppDir "MCXStudio"
#define MyAppVersion "v2020"
#define MyAppPublisher "COTILab"
#define MyAppURL "http://mcx.space"
#define MyAppExeName "mcxstudio.exe"

;;----------------------------------------------------------------------

[Setup]
; NOTE: The value of AppId uniquely identifies this application. Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{0A4EBE79-4F72-4379-8C40-2A395E069EC8}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppDir}
DisableProgramGroupPage=yes
LicenseFile=..\MCXSuite\mcx\LICENSE.txt
InfoAfterFile=..\README.txt
; Uncomment the following line to run in non administrative install mode (install for current user only.)
;PrivilegesRequired=lowest
OutputBaseFilename=mcxstudio
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ChangesEnvironment=true

;;----------------------------------------------------------------------

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

;;----------------------------------------------------------------------

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: envPath; Description: "Add to PATH variable" 

;;----------------------------------------------------------------------

[Dirs]
Name: "{app}\MCXSuite"

;;----------------------------------------------------------------------

[Files]
Source: "..\mcxstudio.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\plink.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\pscp.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\README.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\MATLAB\*"; DestDir: "{code:GetMatlabToolboxLocalPath}"; Excludes: "AUTO_BUILD_*.log"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\mcxsuite_addpath.m"; DestDir: "{code:GetMatlabToolboxLocalPath}\local"; Flags: ignoreversion
Source: "..\MCXSuite\*"; DestDir: "{app}\MCXSuite"; Excludes: "AUTO_BUILD_*.log"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

;;----------------------------------------------------------------------

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Parameters: "--user"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}";  Parameters: "--user"; Tasks: desktopicon
Name: "{autoprograms}\MCX Website"; Filename: "http://mcx.space/"
Name: "{autoprograms}\MCX Wiki"; Filename: "http://mcx.space/wiki/"
Name: "{autoprograms}\MCX Forum"; Filename: "https://groups.google.com/forum/?hl=en#!forum/mcx-users"

;;----------------------------------------------------------------------

[Registry]
; Create "Software\My Company\My Program" keys under CURRENT_USER or
; LOCAL_MACHINE depending on administrative or non administrative install
; mode. The flags tell it to always delete the "My Program" key upon
; uninstall, and delete the "My Company" key if there is nothing left in it.
Root: HKA; Subkey: "Software\COTILab"; Flags: uninsdeletekeyifempty
Root: HKA; Subkey: "Software\COTILab\MCXStudio"; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\COTILab\MCXStudio\Settings"; ValueType: string; ValueName: "Language"; ValueData: "{language}"
; Associate .mcxp files with My Program (requires ChangesAssociations=yes)
Root: HKA; Subkey: "Software\Classes\.mcxp"; ValueType: string; ValueName: ""; ValueData: "MCXStudio.mcxp"; Flags: uninsdeletevalue
Root: HKA; Subkey: "Software\Classes\.mcxp\OpenWithProgids"; ValueType: string; ValueName: "MCXStudio.mcxp"; ValueData: ""; Flags: uninsdeletevalue
Root: HKA; Subkey: "Software\Classes\MCXStudio.mcxp"; ValueType: string; ValueName: ""; ValueData: "MCXStudio"; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\MCXStudio.mcxp\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\mcxstudio.exe,0"
Root: HKA; Subkey: "Software\Classes\MCXStudio.mcxp\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\mcxstudio.exe"" ""%1"""
; HKA (and HKCU) should only be used for settings which are compatible with
; roaming profiles so settings like paths should be written to HKLM, which
; is only possible in administrative install mode.
Root: HKLM; Subkey: "Software\COTILab"; Flags: uninsdeletekeyifempty; Check: IsAdminInstallMode
Root: HKLM; Subkey: "Software\COTILab\MCXStudio"; Flags: uninsdeletekey; Check: IsAdminInstallMode
Root: HKLM; Subkey: "Software\COTILab\MCXStudio\Settings"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}"; Check: IsAdminInstallMode
; User specific settings should always be written to HKCU, which should only
; be done in non administrative install mode.
Root: HKCU; Subkey: "Software\COTILab\MCXStudio\Settings"; ValueType: string; ValueName: "UserName"; ValueData: "{userinfoname}"; Check: not IsAdminInstallMode
Root: HKCU; Subkey: "Software\COTILab\MCXStudio\Settings"; ValueType: string; ValueName: "UserOrganization"; ValueData: "{userinfoorg}"; Check: not IsAdminInstallMode

; Fix windows graphics driver watchdog time limit
Root: HKLM; Subkey: "System\CurrentControlSet\Control\GraphicsDrivers"; ValueType: dword; ValueName: "TdrDelay"; ValueData: 10000000

;;----------------------------------------------------------------------

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

;;----------------------------------------------------------------------

[Code]

const
  EnvironmentKey = 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment';

// codes to finding MATLAB's installation path is derived from
// https://stackoverflow.com/a/46283761/4271392
var
  MatlabToolboxLocalPath: string;

function GetMatlabToolboxLocalPath(Param: string): string;
begin
  Result := MatlabToolboxLocalPath;
end;

function InitializeSetup(): Boolean;
var
  MatlabExePath: string;
begin
  MatlabExePath := FileSearch('matlab.exe', GetEnv('PATH'));
  if MatlabExePath = '' then
  begin
    MatlabExePath := ExpandConstant('{app}') + '\MATLAB';
    Result := true;
    Exit;
  end;

  MatlabToolboxLocalPath := ExtractFilePath(MatlabExePath) + '..\toolbox';

  Result := True;
end;

// codes to modify PATH environment variable is derived from
// https://stackoverflow.com/a/46609047/4271392

procedure EnvAddPath(Path: string);
var
    Paths: string;
begin
    { Retrieve current path (use empty string if entry not exists) }
    if not RegQueryStringValue(HKEY_LOCAL_MACHINE, EnvironmentKey, 'Path', Paths)
    then Paths := '';

    { Skip if string already found in path }
    if Pos(';' + Uppercase(Path) + ';', ';' + Uppercase(Paths) + ';') > 0 then exit;

    { App string to the end of the path variable }
    Paths := Paths + ';'+ Path +';'

    { Overwrite (or create if missing) path environment variable }
    if RegWriteStringValue(HKEY_LOCAL_MACHINE, EnvironmentKey, 'Path', Paths)
    then Log(Format('The [%s] added to PATH: [%s]', [Path, Paths]))
    else Log(Format('Error while adding the [%s] to PATH: [%s]', [Path, Paths]));
end;

procedure EnvRemovePath(Path: string);
var
    Paths: string;
    P: Integer;
begin
    { Skip if registry entry not exists }
    if not RegQueryStringValue(HKEY_LOCAL_MACHINE, EnvironmentKey, 'Path', Paths) then
        exit;

    { Skip if string not found in path }
    P := Pos(';' + Uppercase(Path) + ';', ';' + Uppercase(Paths) + ';');
    if P = 0 then exit;

    { Update path variable }
    Delete(Paths, P - 1, Length(Path) + 1);

    { Overwrite path environment variable }
    if RegWriteStringValue(HKEY_LOCAL_MACHINE, EnvironmentKey, 'Path', Paths)
    then Log(Format('The [%s] removed from PATH: [%s]', [Path, Paths]))
    else Log(Format('Error while removing the [%s] from PATH: [%s]', [Path, Paths]));
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
    if (CurStep = ssPostInstall) and (IsTaskSelected('envPath')) then begin
      EnvAddPath(ExpandConstant('{app}'));
      EnvAddPath(ExpandConstant('{app}') +'\MCXSuite\mcx\bin');
      EnvAddPath(ExpandConstant('{app}') +'\MCXSuite\mmc\bin');
      EnvAddPath(ExpandConstant('{app}') +'\MCXSuite\mcxcl\bin');
    end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
    if CurUninstallStep = usPostUninstall then 
    begin
      EnvRemovePath(ExpandConstant('{app}'));
      EnvRemovePath(ExpandConstant('{app}') +'\MCXSuite\mcx\bin');
      EnvRemovePath(ExpandConstant('{app}') +'\MCXSuite\mmc\bin');
      EnvRemovePath(ExpandConstant('{app}') +'\MCXSuite\mcxcl\bin');
    end;
end;
