[Setup]
AppName=Eclipse
AppVersion=1.0
DefaultDirName={autopf}\Eclipse
DefaultGroupName=Eclipse
OutputDir=.\installer
OutputBaseFilename=Eclipse_Setup
Compression=lzma
SolidCompression=yes
PrivilegesRequired=admin

[Files]
Source: "build\windows\x64\runner\Release\vpn_client.exe"; DestDir: "{app}"; DestName: "eclipse.exe"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs
Source: "build\windows\sing-box.exe"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{commondesktop}\Eclipse"; Filename: "{app}\eclipse.exe"
Name: "{group}\Eclipse"; Filename: "{app}\eclipse.exe"

[Run]
Filename: "{app}\eclipse.exe"; Description: "Запустить Eclipse"; Flags: postinstall nowait shellexec runascurrentuser