; UnrealIRCd Windows Installation Script
; Requires Inno Setup 4.1.6 or later

; Uncomment the line below to package with libcurl support
#define USE_CURL

[Setup]
AppName=UnrealIRCd 5
AppVerName=UnrealIRCd 5.0.0-dev
AppPublisher=UnrealIRCd Team
AppPublisherURL=https://www.unrealircd.org
AppSupportURL=https://www.unrealircd.org
AppUpdatesURL=https://www.unrealircd.org
AppMutex=UnrealMutex,Global\UnrealMutex
DefaultDirName={pf}\UnrealIRCd 5
DefaultGroupName=UnrealIRCd
AllowNoIcons=yes
LicenseFile=src\windows\gplplusssl.rtf
Compression=lzma
SolidCompression=true
MinVersion=5.0
OutputDir=.
SourceDir=../../
UninstallDisplayIcon={app}\UnrealIRCd.exe
DisableWelcomePage=no

; !!! Make sure to update SSL/TLS validation (WizardForm.TasksList.Checked[9]) if tasks are added/removed !!!
[Tasks]
Name: "desktopicon"; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"
Name: "quicklaunchicon"; Description: "Create a &Quick Launch icon"; GroupDescription: "Additional icons:"; Flags: unchecked
Name: "installservice"; Description: "Install as a &service (not for beginners)"; GroupDescription: "Service support:"; Flags: unchecked; MinVersion: 0,4.0
Name: "installservice/startboot"; Description: "S&tart UnrealIRCd when Windows starts"; GroupDescription: "Service support:"; MinVersion: 0,4.0; Flags: exclusive unchecked
Name: "installservice/startdemand"; Description: "Start UnrealIRCd on &request"; GroupDescription: "Service support:"; MinVersion: 0,4.0; Flags: exclusive unchecked
Name: "installservice/crashrestart"; Description: "Restart UnrealIRCd if it &crashes"; GroupDescription: "Service support:"; Flags: unchecked; MinVersion: 0,5.0;
Name: "makecert"; Description: "&Create certificate"; GroupDescription: "SSL/TLS options:";
Name: "fixperm"; Description: "Make UnrealIRCd folder writable by current user";

[Files]
Source: "UnrealIRCd.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "UnrealIRCd.pdb"; DestDir: "{app}"; Flags: ignoreversion
Source: "doc\RELEASE-NOTES"; DestDir: "{app}"; DestName: "RELEASE.NOTES.txt"; Flags: ignoreversion

Source: "doc\conf\*.default.conf"; DestDir: "{app}\conf"; Flags: ignoreversion
Source: "doc\conf\*.optional.conf"; DestDir: "{app}\conf"; Flags: ignoreversion
Source: "doc\conf\spamfilter.conf"; DestDir: "{app}\conf"; Flags: onlyifdoesntexist
Source: "doc\conf\badwords.conf"; DestDir: "{app}\conf"; Flags: onlyifdoesntexist
Source: "doc\conf\dccallow.conf"; DestDir: "{app}\conf"; Flags: onlyifdoesntexist
Source: "doc\conf\aliases\*.conf"; DestDir: "{app}\conf\aliases"; Flags: ignoreversion
Source: "doc\conf\help\*.conf"; DestDir: "{app}\conf\help"; Flags: ignoreversion
Source: "doc\conf\examples\*.conf"; DestDir: "{app}\conf\examples"; Flags: ignoreversion

Source: "doc\Donation"; DestDir: "{app}"; DestName: "Donation.txt"; Flags: ignoreversion
Source: "LICENSE"; DestDir: "{app}"; DestName: "LICENSE.txt"; Flags: ignoreversion

Source: "doc\*.*"; DestDir: "{app}\doc"; Flags: ignoreversion
Source: "doc\technical\*.*"; DestDir: "{app}\doc\technical"; Flags: ignoreversion
Source: "doc\conf\aliases\*"; DestDir: "{app}\conf\aliases"; Flags: ignoreversion

Source: "unrealsvc.exe"; DestDir: "{app}"; Flags: ignoreversion; MinVersion: 0,4.0

Source: "src\windows\makecert.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: "extras\tls.cnf"; DestDir: "{app}"; Flags: ignoreversion

Source: "src\modules\*.dll"; DestDir: "{app}\modules"; Flags: ignoreversion
Source: "src\modules\chanmodes\*.dll"; DestDir: "{app}\modules\chanmodes"; Flags: ignoreversion
Source: "src\modules\usermodes\*.dll"; DestDir: "{app}\modules\usermodes"; Flags: ignoreversion
Source: "src\modules\snomasks\*.dll"; DestDir: "{app}\modules\snomasks"; Flags: ignoreversion
Source: "src\modules\extbans\*.dll"; DestDir: "{app}\modules\extbans"; Flags: ignoreversion

Source: "c:\dev\pcre2\bin\pcre*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "c:\dev\argon2\vs2015\build\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "c:\dev\c-ares\msvc\cares\dll-release\cares.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "c:\dev\libressl\bin\openssl.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "c:\dev\libressl\bin\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "c:\dev\setacl.exe"; DestDir: "{app}\tmp"; Flags: ignoreversion

#ifdef USE_CURL
; curl with SSL/TLS support
Source: "C:\dev\curl-ssl\builds\libcurl-vc-x86-release-dll-ssl-dll-ipv6-sspi-obj-lib\libcurl.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "doc\conf\tls\curl-ca-bundle.crt"; DestDir: "{app}\conf\tls"; Flags: ignoreversion
#endif

[Dirs]
Name: "{app}\tmp"
Name: "{app}\cache"
Name: "{app}\logs"
Name: "{app}\conf"
Name: "{app}\conf\tls"
Name: "{app}\data"
Name: "{app}\modules\third"

[UninstallDelete]
Type: files; Name: "{app}\DbgHelp.Dll"

[Code]
var
  uninstaller: String;
  ErrorCode: Integer;

//*********************************************************************************
// This is where all starts.
//*********************************************************************************
function InitializeSetup(): Boolean;
var
  major: Cardinal;
begin
	Result := true;
  if Not RegQueryDWordValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x86', 'Major', major) then
    begin
      MsgBox('UnrealIRCd requires the Microsoft Visual C++ Redistributable for Visual Studio 2017 to be installed.' #13 +
             'After you click OK you will be taken to a download page from Microsoft:' #13 +
             '1) Scroll down to the "Visual Studio 2017" section' #13 +
             '2) Click on the x86 "vc_redist.x86.exe" to download the installer' #13 +
             '3) Run the installer.' #13 + #13 +
             'If you are already absolutely sure that you have this package installed then you can skip this step.', mbInformation, MB_OK);
      ShellExec('open', 'https://support.microsoft.com/help/2977003/the-latest-supported-visual-c-downloads', '', '', SW_SHOWNORMAL,ewNoWait,ErrorCode);
      MsgBox('Your browser was launched. After you have installed the Microsoft Visual C++ Redistributable for Visual Studio 2017 (vc_redist.x86.exe), click OK below to continue the UnrealIRCd installer', mbInformation, MB_OK);
	end;
end;

procedure CurStepChanged(CurStep: TSetupStep);

var
  hWnd: Integer;
  ResultCode: Integer;
  ResultXP: boolean;
  Result2003: boolean;
  Res: Integer;
  s: String;
  d: String;
begin
if CurStep = ssPostInstall then
	begin
     d := ExpandConstant('{app}');
	   if IsTaskSelected('fixperm') then
	   begin
	     // This fixes the permissions in the UnrealIRCd folder by granting full access to the user
	     // running the install.
	     s := '-on "'+d+'" -ot file -actn ace -ace "n:'+GetUserNameString()+';p:full;m:set';
	     Exec(d+'\tmp\setacl.exe', s, d, SW_HIDE, ewWaitUntilTerminated, Res);
	   end
	   else
	   begin
	     MsgBox('You have chosen to not have the installer automatically set write access. Please ensure that the user running the IRCd can write to '+d+', otherwise the IRCd will fail to load.',mbConfirmation, MB_OK);
	   end
  end;
end;

//*********************************************************************************
// Checks if SSL/TLS cert file exists
//*********************************************************************************

procedure CurPageChanged(CurPage: Integer);
begin
  if (CurPage = wpSelectTasks)then
  begin
     if FileExists(ExpandConstant('{app}\conf\tls\server.cert.pem')) then
     begin
        WizardForm.TasksList.Checked[9]:=false;
     end
     else
     begin
        WizardForm.TasksList.Checked[9]:=true;
     end
  end
end;

[Icons]
Name: "{group}\UnrealIRCd"; Filename: "{app}\UnrealIRCd.exe"; WorkingDir: "{app}"
Name: "{group}\Uninstall UnrealIRCd"; Filename: "{uninstallexe}"; WorkingDir: "{app}"
Name: "{group}\Make Certificate"; Filename: "{app}\makecert.bat"; WorkingDir: "{app}"
Name: "{group}\Documentation"; Filename: "https://www.unrealircd.org/docs/UnrealIRCd_5_documentation"; WorkingDir: "{app}"
Name: "{userdesktop}\UnrealIRCd"; Filename: "{app}\UnrealIRCd.exe"; WorkingDir: "{app}"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\UnrealIRCd"; Filename: "{app}\UnrealIRCd.exe"; WorkingDir: "{app}"; Tasks: quicklaunchicon

[Run]
;Filename: "notepad"; Description: "View example.conf"; Parameters: "{app}\conf\examples\example.conf"; Flags: postinstall skipifsilent shellexec runmaximized
Filename: "https://www.unrealircd.org/docs/UnrealIRCd_5_documentation"; Description: "View documentation"; Parameters: ""; Flags: postinstall skipifsilent shellexec runmaximized
Filename: "https://www.unrealircd.org/docs/Installing_%28Windows%29"; Description: "View installation instructions"; Parameters: ""; Flags: postinstall skipifsilent shellexec runmaximized
Filename: "notepad"; Description: "View Release Notes"; Parameters: "{app}\RELEASE.NOTES.txt"; Flags: postinstall skipifsilent shellexec runmaximized
Filename: "{app}\unrealsvc.exe"; Parameters: "install"; Flags: runminimized nowait; Tasks: installservice
Filename: "{app}\unrealsvc.exe"; Parameters: "config startup manual"; Flags: runminimized nowait; Tasks: installservice/startdemand
Filename: "{app}\unrealsvc.exe"; Parameters: "config startup auto"; Flags: runminimized nowait; Tasks: installservice/startboot
Filename: "{app}\unrealsvc.exe"; Parameters: "config crashrestart 2"; Flags: runminimized nowait; Tasks: installservice/crashrestart
Filename: "{app}\makecert.bat"; Tasks: makecert; Flags: postinstall;

[UninstallRun]
Filename: "{app}\unrealsvc.exe"; Parameters: "uninstall"; Flags: runminimized; RunOnceID: "DelService"; Tasks: installservice