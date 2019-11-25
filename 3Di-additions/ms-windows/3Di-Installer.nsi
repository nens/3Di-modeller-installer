;--------------------------------------------------------------------------
;    QGIS-Installer.nsi - 3Di Modeller Interface Installer for Windows
;    ---------------------
;    Date                 : Januari 2018
;    Copyright            : (C) 2008 by Marco Pasetti
;    Email                : marco dot pasetti at alice dot it
;--------------------------------------------------------------------------
;                                                                         #
;   This program is free software; you can redistribute it and/or modify  #
;   it under the terms of the GNU General Public License as published by  #
;   the Free Software Foundation; either version 2 of the License, or     #
;   (at your option) any later version.                                   #
;                                                                         #
;--------------------------------------------------------------------------

;Extended for creatensis.pl by Jürgen E. Fischer <jef@norbit.de>

;----------------------------------------------------------------------------------------------------------------------------

; Adapted for Nelen en Schuurmans by Marco Duiker (MD-kwadraat)

;----------------------------------------------------------------------------------------------------------------------------

; Added by Tim to get optimal compression
SetCompressor /SOLID lzma
;SetCompress off

; Added by Tim to allow privilege elevation in vista
RequestExecutionLevel admin

;----------------------------------------------------------------------------------------------------------------------------

;NSIS Includes

!include "x64.nsh"
!include "MUI.nsh"
!include "LogicLib.nsh"

;----------------------------------------------------------------------------------------------------------------------------

;Set the installer variables, depending on the selected version to build

!addplugindir osgeo4w/untgz
!addplugindir osgeo4w/nsis

;----------------------------------------------------------------------------------------------------------------------------

;Publisher variables

!define PUBLISHER "Nelen en Schuurmans"
!define WEB_SITE "https://docs.3di.lizard.net/en/stable/"
!define WIKI_PAGE "https://docs.3di.lizard.net/en/stable/"

;----------------------------------------------------------------------------------------------------------------------------

;General Definitions

;Name of the application shown during install
Name "${DISPLAYED_NAME}"

;Name of the output file (installer executable)
OutFile "${INSTALLER_NAME}"

;Tell the installer to show Install and Uninstall details as default
ShowInstDetails hide
ShowUnInstDetails hide

;----------------------------------------------------------------------------------------------------------------------------

; .onInit Function (called when the installer is nearly finished initializing)

; Check if QGIS is already installed on the system and, if yes, what version and binary release;
; depending on that, select the install procedure:

; 1. first installation = if QGIS is not already installed
;    install QGIS asking for the install PATH

; 2. upgrade installation = if an older release of QGIS is already installed
;    call the uninstaller of the currently installed QGIS release
;    if the uninstall procedure succeeded, call the current installer without asking for the install PATH
;    QGIS will be installed in the same PATH of the previous installation

; 3. downgrade installation = if a newer release of QGIS is already installed
;    call the uninstaller of the currently installed QGIS release
;    if the uninstall procedure succeeded, call the current installer without asking for the install PATH
;    QGIS will be installed in the same PATH of the previous installation

; 4. repair installation = if the same release of QGIS is already installed
;    call the uninstaller of the currently installed QGIS release
;    if the uninstall procedure succeeded, call the current installer asking for the install PATH

Function .onInit
!ifdef INNER
	WriteUninstaller "${UNINSTALLERDEST}\uninstall.exe"
	Quit
!endif
	${If} ${ARCH} == "x86_64"
		${If} ${RunningX64}
			DetailPrint "Installer running on 64-bit host"
			; disable registry redirection (enable access to 64-bit portion of registry)
			SetRegView 64
			; change install dir
			${If} $INSTDIR == ""
			  StrCpy $INSTDIR "$PROGRAMFILES64\${QGIS_BASE}"
			${EndIf}
		${EndIf}
	${EndIf}

	${If} $INSTDIR == ""
		StrCpy $INSTDIR "$PROGRAMFILES\${QGIS_BASE}"
	${EndIf}

	Var /GLOBAL ASK_FOR_PATH
	StrCpy $ASK_FOR_PATH "YES"

	Var /GLOBAL UNINSTALL_STRING
	Var /GLOBAL INSTALL_PATH

	Var /GLOBAL INSTALLED_VERSION_NUMBER
	Var /GLOBAL INSTALLED_SVN_REVISION
	Var /GLOBAL INSTALLED_BINARY_REVISION

	Var /GLOBAL INSTALLED_VERSION_INT

	Var /GLOBAL DISPLAYED_INSTALLED_VERSION

	Var /GLOBAL MESSAGE_0_
	Var /GLOBAL MESSAGE_1_
	Var /GLOBAL MESSAGE_2_
	Var /GLOBAL MESSAGE_3_

	ReadRegStr $UNINSTALL_STRING HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${QGIS_BASE}" "UninstallString"
	ReadRegStr $INSTALL_PATH HKLM "Software\${QGIS_BASE}" "InstallPath"
	ReadRegStr $INSTALLED_VERSION_NUMBER HKLM "Software\${QGIS_BASE}" "VersionNumber"
	ReadRegStr $INSTALLED_BINARY_REVISION HKLM "Software\${QGIS_BASE}" "BinaryRevision"

	ReadRegStr $INSTALLED_VERSION_INT HKLM "Software\${QGIS_BASE}" "VersionInt"
	${If} $INSTALLED_VERSION_INT == ""
		# First using new scheme: 1080001
		# Previous: SvnRevision 14615 + BinaryRevision 0
		ReadRegStr $INSTALLED_SVN_REVISION HKLM "Software\${QGIS_BASE}" "SvnRevision"
		IntOp $INSTALLED_VERSION_INT $INSTALLED_SVN_REVISION + $INSTALLED_BINARY_REVISION
	${EndIf}

	StrCpy $MESSAGE_0_ "${QGIS_BASE} is already installed on your system.$\r$\n"
	StrCpy $MESSAGE_0_ "$MESSAGE_0_$\r$\n"

	${If} $INSTALLED_BINARY_REVISION == ""
		StrCpy $DISPLAYED_INSTALLED_VERSION "$INSTALLED_VERSION_NUMBER"
	${Else}
		StrCpy $DISPLAYED_INSTALLED_VERSION "$INSTALLED_VERSION_NUMBER-$INSTALLED_BINARY_REVISION"
	${EndIf}

	StrCpy $MESSAGE_0_ "$MESSAGE_0_The installed release is $DISPLAYED_INSTALLED_VERSION$\r$\n"

	StrCpy $MESSAGE_1_ "$MESSAGE_0_$\r$\n"
	StrCpy $MESSAGE_1_ "$MESSAGE_1_You are going to install a newer release of ${QGIS_BASE}$\r$\n"
	StrCpy $MESSAGE_1_ "$MESSAGE_1_$\r$\n"
	StrCpy $MESSAGE_1_ "$MESSAGE_1_Press OK to uninstall ${DISPLAYED_NAME} $DISPLAYED_INSTALLED_VERSION"
	StrCpy $MESSAGE_1_ "$MESSAGE_1_ and install ${DISPLAYED_NAME} or Cancel to quit."

	StrCpy $MESSAGE_2_ "$MESSAGE_0_$\r$\n"
	StrCpy $MESSAGE_2_ "$MESSAGE_2_You are going to install an older release of ${QGIS_BASE}$\r$\n"
	StrCpy $MESSAGE_2_ "$MESSAGE_2_$\r$\n"
	StrCpy $MESSAGE_2_ "$MESSAGE_2_Press OK to uninstall ${DISPLAYED_NAME} $DISPLAYED_INSTALLED_VERSION"
	StrCpy $MESSAGE_2_ "$MESSAGE_2_ and install ${DISPLAYED_NAME} or Cancel to quit."

	StrCpy $MESSAGE_3_ "$MESSAGE_0_$\r$\n"
	StrCpy $MESSAGE_3_ "$MESSAGE_3_This is the latest release available.$\r$\n"
	StrCpy $MESSAGE_3_ "$MESSAGE_3_$\r$\n"
	StrCpy $MESSAGE_3_ "$MESSAGE_3_Press OK to reinstall ${DISPLAYED_NAME} or Cancel to quit."

	${If} $INSTALLED_VERSION_INT = 0
	${Else}
		${If} $INSTALLED_VERSION_INT < ${VERSION_INT}
			MessageBox MB_OKCANCEL "$MESSAGE_1_" IDOK upgrade IDCANCEL quit_upgrade
			upgrade:
				StrCpy $ASK_FOR_PATH "NO"
				ExecWait '"$UNINSTALL_STRING" _?=$INSTALL_PATH' $0
				Goto continue_upgrade
			quit_upgrade:
				Abort
			continue_upgrade:
		${ElseIf} $INSTALLED_VERSION_INT > ${VERSION_INT}
			MessageBox MB_OKCANCEL "$MESSAGE_2_" IDOK downgrade IDCANCEL quit_downgrade
			downgrade:
				StrCpy $ASK_FOR_PATH "NO"
				ExecWait '"$UNINSTALL_STRING" _?=$INSTALL_PATH' $0
				Goto continue_downgrade
			quit_downgrade:
				Abort
			continue_downgrade:
		${ElseIf} $INSTALLED_VERSION_INT = ${VERSION_INT}
			MessageBox MB_OKCANCEL "$MESSAGE_3_" IDOK reinstall IDCANCEL quit_reinstall
			reinstall:
				ExecWait '"$UNINSTALL_STRING" _?=$INSTALL_PATH' $0
				Goto continue_reinstall
			quit_reinstall:
				Abort
			continue_reinstall:
		${EndIf}

		${If} $0 = 0
		${Else}
			Abort
		${EndIf}
	${EndIf}
FunctionEnd

;----------------------------------------------------------------------------------------------------------------------------

;CheckUpdate Function
;Check if to show the MUI_PAGE_DIRECTORY during the installation (to ask for the install PATH)

Function CheckUpdate

	${If} $ASK_FOR_PATH == "NO"
		Abort
	${EndIf}

FunctionEnd

;----------------------------------------------------------------------------------------------------------------------------

;Interface Settings

!define MUI_ABORTWARNING
!define MUI_ICON ".\Installer-Files\Install_3Di.ico"
!define MUI_UNICON ".\Installer-Files\Uninstall_3Di.ico"
!define MUI_HEADERIMAGE_BITMAP_NOSTETCH ".\Installer-Files\InstallHeaderImage3Di.bmp"
!define MUI_HEADERIMAGE_UNBITMAP_NOSTRETCH ".\Installer-Files\UnInstallHeaderImage3Di.bmp"
!define MUI_WELCOMEFINISHPAGE_BITMAP ".\Installer-Files\WelcomeFinishPage3Di.bmp"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP ".\Installer-Files\WelcomeFinishPage3Di.bmp"

;----------------------------------------------------------------------------------------------------------------------------

;Installer Pages

!define MUI_WELCOMEPAGE_TITLE_3LINES
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE ${LICENSE_FILE}

!define MUI_PAGE_CUSTOMFUNCTION_PRE CheckUpdate
!insertmacro MUI_PAGE_DIRECTORY

!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_TITLE_3LINES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

;----------------------------------------------------------------------------------------------------------------------------

; Language files
!insertmacro MUI_LANGUAGE "English"
;!insertmacro MUI_LANGUAGE "German"
;!insertmacro MUI_LANGUAGE "French"
;!insertmacro MUI_LANGUAGE "Russian"
;!insertmacro MUI_LANGUAGE "Japanese"
;!insertmacro MUI_LANGUAGE "Italian"
;!insertmacro MUI_LANGUAGE "Polish"
;!insertmacro MUI_LANGUAGE "Spanish"
;!insertmacro MUI_LANGUAGE "PortugueseBR"
;!insertmacro MUI_LANGUAGE "Portuguese"
;!insertmacro MUI_LANGUAGE "Czech"
;!insertmacro MUI_LANGUAGE "Croatian"
;!insertmacro MUI_LANGUAGE "Thai"
;!insertmacro MUI_LANGUAGE "Dutch"

;----------------------------------------------------------------------------------------------------------------------------

;Installer Sections

!ifndef INNER
Section "3Di Modeller Interface" SecQGIS
	SectionIn RO

        ;Added by Tim to set the reg key so we get default plugin loading
        !include plugins-3di.nsh
        ;Added by Tim to set the reg key so we get default python & py plugins
        !include python_plugins-3di.nsh

	;Set the INSTALL_DIR variable
	Var /GLOBAL INSTALL_DIR

	${If} $ASK_FOR_PATH == "NO"
		StrCpy $INSTALL_DIR "$INSTALL_PATH"
	${Else}
		StrCpy $INSTALL_DIR "$INSTDIR"
	${EndIf}

	;Set to try to overwrite existing files
	SetOverwrite try

	;Set the GIS_DATABASE directory
	SetShellVarContext current
	Var /GLOBAL GIS_DATABASE
	StrCpy $GIS_DATABASE "$DOCUMENTS\GIS DataBase"

	;Create the GIS_DATABASE directory
	CreateDirectory "$GIS_DATABASE"

	;add Installer files
	SetOutPath "$INSTALL_DIR\icons"
	File .\Installer-Files\QGIS.ico
	File .\Installer-Files\QGIS_Web.ico
	SetOutPath "$INSTALL_DIR"
	File .\Installer-Files\postinstall.bat
    File .\Installer-Files\postinstall-3di-ltr.bat
	File .\Installer-Files\preremove.bat
    File .\Installer-Files\preremove-3di-ltr.bat

	;add QGIS files
	SetOutPath "$INSTALL_DIR"
	File /r ${PACKAGE_FOLDER}\*.*

!ifndef INNER
	SetOutPath $INSTDIR
	File uninstall.exe
!endif

	;Registry Key Entries

	;HKEY_LOCAL_MACHINE Install entries
	;Set the Name, Version and Revision of QGIS+ PublisherInfo + InstallPath
	WriteRegStr HKLM "Software\${QGIS_BASE}" "Name" "${QGIS_BASE}"
	WriteRegStr HKLM "Software\${QGIS_BASE}" "VersionNumber" "${VERSION_NUMBER}"
	WriteRegStr HKLM "Software\${QGIS_BASE}" "VersionName" "${VERSION_NAME}"
	WriteRegStr HKLM "Software\${QGIS_BASE}" "VersionInt" "${VERSION_INT}"
	WriteRegStr HKLM "Software\${QGIS_BASE}" "BinaryRevision" "${BINARY_REVISION}"
	WriteRegStr HKLM "Software\${QGIS_BASE}" "Publisher" "${PUBLISHER}"
	WriteRegStr HKLM "Software\${QGIS_BASE}" "WebSite" "${WEB_SITE}"
	WriteRegStr HKLM "Software\${QGIS_BASE}" "InstallPath" "$INSTALL_DIR"

	;HKEY_LOCAL_MACHINE Uninstall entries
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${QGIS_BASE}" "DisplayName" "${DISPLAYED_NAME}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${QGIS_BASE}" "DisplayVersion" "${VERSION_NUMBER}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${QGIS_BASE}" "UninstallString" "$INSTALL_DIR\uninstall.exe"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${QGIS_BASE}" "DisplayIcon" "$INSTALL_DIR\icons\3Di.ico"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${QGIS_BASE}" "EstimatedSize" 1
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${QGIS_BASE}" "HelpLink" "${WIKI_PAGE}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${QGIS_BASE}" "URLInfoAbout" "${WEB_SITE}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${QGIS_BASE}" "Publisher" "${PUBLISHER}"

	;Create the Desktop Shortcut
	SetShellVarContext current

	;Create the Windows Start Menu Shortcuts
	;SetShellVarContext all
    SetShellVarContext current
    

	CreateDirectory "$SMPROGRAMS\${QGIS_BASE}"
    
	GetFullPathName /SHORT $0 $INSTALL_DIR
	System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("OSGEO4W_ROOT", "$0").r0'
	System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("OSGEO4W_STARTMENU", "$SMPROGRAMS\${QGIS_BASE}").r0'
	System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("OSGEO4W_DESKTOP", "$DESKTOP\${QGIS_BASE}").r0'
	System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("OSGEO4W_MENU_LINKS", "1").r0'
	System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("OSGEO4W_DESKTOP_LINKS", "1").r0'
	System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("OSGEO4W_PROFILE_FOLDER", "$APPDATA\3Di\QGIS3\").r0'
	

	ReadEnvStr $0 COMSPEC
	nsExec::ExecToLog '"$0" /c "$INSTALL_DIR\postinstall-3di-ltr.bat"'
    ;nsExec::ExecToLog '"$0" /c "$INSTALL_DIR\postinstall-3di.bat"'

	IfFileExists "$INSTALL_DIR\etc\reboot" RebootNecessary NoRebootNecessary

RebootNecessary:
	IfSilent FlagRebootNecessary
	SetRebootFlag true
	Return

FlagRebootNecessary:
	SetErrorLevel 3010 ; ERROR_SUCCESS_REBOOT_REQUIRED
	Return

NoRebootNecessary:
	Return

SectionEnd
!endif



Section "3Di Profile" SecProfile

    SectionIn RO

	;Set to try to overwrite existing files
	SetOverwrite try
    ;RequestExecutionLevel user       This is not allowed in a section; probably isn't going to work on Vista

    SetShellVarContext current

    Var /GLOBAL INSTDIR_PROFILE_DATA
    
    StrCpy $INSTDIR_PROFILE_DATA "$APPDATA\3Di\QGIS3\profiles\"
    CreateDirectory "$INSTDIR_PROFILE_DATA"
    
	;add Profile files
	SetOutPath "$INSTDIR_PROFILE_DATA"
	File /r ${PROFILE_FOLDER}\*.*

    ;NO SEPARATE UNINSTALLER; WILL BE UNINSTALLED WITH BASE
	;Create the Uninstaller
	;WriteUninstaller "$INSTALL_DIR\Uninstall-3Di.exe"

	;Registry Key Entries

	;HKEY_LOCAL_MACHINE Install entries
	;Set the Name, Version and Revision of QGIS+ PublisherInfo + InstallPath
	;WriteRegStr HKLM "Software\${QGIS_PROFILE}" "Name" "${QGIS_PROFILE}"
	;WriteRegStr HKLM "Software\${QGIS_PROFILE}" "VersionNumber" "${PROFILE_VERSION_NUMBER}"
	;WriteRegStr HKLM "Software\${QGIS_PROFILE}" "VersionName" "${VERSION_NAME}"
	;WriteRegStr HKLM "Software\${QGIS_PROFILE}" "VersionInt" "${VERSION_INT}"
	;WriteRegStr HKLM "Software\${QGIS_PROFILE}" "BinaryRevision" "${BINARY_REVISION}"
	;WriteRegStr HKLM "Software\${QGIS_PROFILE}" "Publisher" "${PUBLISHER}"
	;WriteRegStr HKLM "Software\${QGIS_PROFILE}" "WebSite" "${WEB_SITE}"
	;WriteRegStr HKLM "Software\${QGIS_PROFILE}" "InstallPath" "$INSTDIR_DATA"


SectionEnd



;----------------------------------------------------------------------------------------------------------------------------

;Uninstaller Section

!ifdef INNER
Section "Uninstall"
	${If} ${ARCH} == "x86_64"
		${If} ${RunningX64}
			DetailPrint "Installer running on 64-bit host"
			; disable registry redirection (enable access to 64-bit portion of registry)
			SetRegView 64
		${EndIf}
	${EndIf}

	GetFullPathName /SHORT $0 $INSTDIR
	System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("OSGEO4W_ROOT", "$0").r0'
	System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("OSGEO4W_STARTMENU", "$SMPROGRAMS\${QGIS_BASE}").r0'
	System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("OSGEO4W_DESKTOP", "$DESKTOP\${QGIS_BASE}").r0'
	System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("OSGEO4W_MENU_LINKS", "1").r0'
	System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("OSGEO4W_DESKTOP_LINKS", "1").r0'

	ReadEnvStr $0 COMSPEC
	;nsExec::ExecToLog '"$0" /c "$INSTDIR\preremove.bat"'
    nsExec::ExecToLog '"$0" /c "$INSTDIR\preremove-3di.bat"'

	Delete "$INSTDIR\uninstall.exe"
	Delete "$INSTDIR\*.bat.done"
	Delete "$INSTDIR\*.log"
	Delete "$INSTDIR\*.txt"
	Delete "$INSTDIR\*.ico"
	Delete "$INSTDIR\*.bat"
	Delete "$INSTDIR\*.dll"

	RMDir /r "$INSTDIR\bin"
	RMDir /r "$INSTDIR\apps"
	RMDir /r "$INSTDIR\etc"
	RMDir /r "$INSTDIR\include"
	RMDir /r "$INSTDIR\lib"
	RMDir /r "$INSTDIR\share"
	RMDir /r "$INSTDIR\icons"
	RMDir /r "$INSTDIR\src"
	RMDir /r "$INSTDIR\contrib"
	RMDir /r "$INSTDIR\manifest"
	RMDir /r "$INSTDIR\man"

	;if empty, remove the install folder
	RMDir "$INSTDIR"

	;remove the Desktop ShortCut
	SetShellVarContext current
	Delete "$DESKTOP\3Di Desktop (${VERSION_NUMBER}).lnk"
    Delete "$DESKTOP\3Di Desktop.lnk"
	Delete "$DESKTOP\QGIS Browser (${VERSION_NUMBER}).lnk"
	Delete "$DESKTOP\OSGeo4W.lnk"

	;remove the Programs Start ShortCut
	SetShellVarContext current
	RMDir /r "$SMPROGRAMS\${QGIS_BASE}"

	;remove the Registry Entries
	DeleteRegKey HKLM "Software\${QGIS_BASE}"
	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${QGIS_BASE}"
SectionEnd
!endif

;----------------------------------------------------------------------------------------------------------------------------

!ifndef INNER
;Installer Section Descriptions
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
	!insertmacro MUI_DESCRIPTION_TEXT ${SecQGIS} "Install ${QGIS_BASE}"
!insertmacro MUI_FUNCTION_DESCRIPTION_END
!endif

;----------------------------------------------------------------------------------------------------------------------------