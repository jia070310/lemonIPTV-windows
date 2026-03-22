; 脚本用于打包 LemonTV Windows 安装包
[Setup]
AppName=柠檬TV
AppVersion=1.1.5
AppVerName=柠檬TV 1.1.5
AppPublisher=EasyTV Team
AppPublisherURL=https://github.com/jia070310/lemonIPTV-windows
AppSupportURL=https://github.com/jia070310/lemonIPTV-windows
AppUpdatesURL=https://github.com/jia070310/lemonIPTV-windows
DefaultDirName={autopf}\LemonTV
DisableProgramGroupPage=yes
OutputDir=.\installer
OutputBaseFilename=LemonTV_Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ShowLanguageDialog=yes
LanguageDetectionMethod=uilanguage
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
SetupLogging=yes
UninstallDisplayIcon={app}\LemonTV.exe

[Languages]
Name: "zh"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"
Name: "en"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs
Source: "LICENSE"; DestDir: "{app}"; Flags: ignoreversion
Source: "README.md"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\柠檬TV"; Filename: "{app}\LemonTV.exe"
Name: "{autodesktop}\柠檬TV"; Filename: "{app}\LemonTV.exe"; Tasks: desktopicon
Name: "{autostartmenu}\柠檬TV"; Filename: "{app}\LemonTV.exe"

[Run]
Filename: "{app}\LemonTV.exe"; Description: "{cm:LaunchProgram,LemonTV}"; Flags: nowait postinstall skipifsilent
