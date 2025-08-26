[Setup]
AppName=YupiRead
AppVersion=0.0.3
AppPublisher=Euphyfve
AppPublisherURL=https://github.com/Alpinnnn/yupiread
AppSupportURL=https://github.com/Alpinnnn/yupiread/issues
AppUpdatesURL=https://github.com/Alpinnnn/yupiread/releases
DefaultDirName={autopf}\YupiRead
DisableProgramGroupPage=yes
LicenseFile=..\LICENSE
InfoBeforeFile=..\README.md
OutputDir=..\build\windows\installer
OutputBaseFilename=YupiRead-Setup-{#SetupSetting("AppVersion")}
SetupIconFile=..\windows\runner\resources\app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 6.1

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\build\windows\x64\runner\Release\yupiread.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\YupiRead"; Filename: "{app}\yupiread.exe"
Name: "{autodesktop}\YupiRead"; Filename: "{app}\yupiread.exe"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\YupiRead"; Filename: "{app}\yupiread.exe"; Tasks: quicklaunchicon

[Run]
Filename: "{app}\yupiread.exe"; Description: "{cm:LaunchProgram,YupiRead}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"
