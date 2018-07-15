;=====================================================================================
; x64dbg plugin SDK For Assembler x86 - fearless 
; https://github.com/mrfearless/x64dbg-Plugin-SDK-for-x86-Assembler
;
; CodeShot.inc
;
;-------------------------------------------------------------------------------------
include windows.inc
include user32.inc
include gdi32.inc
include gdiplus.inc
include kernel32.inc
include shell32.inc

includelib user32.lib
includelib gdi32.lib
includelib gdiplus.lib
includelib kernel32.lib
includelib shell32.lib

include masm32.inc
includelib masm32.lib

include winmm.inc
includelib winmm.lib

include ModernUI.inc
includelib ModernUI.lib

include ModernUI_CaptionBar.inc
includelib ModernUI_CaptionBar.lib

include ModernUI_SmartPanel.inc
Includelib ModernUI_SmartPanel.lib

include ModernUI_Button.inc
includelib ModernUI_Button.lib

include ModernUI_Checkbox.inc
includelib ModernUI_Checkbox.lib


CodeShotOptionsDlgProc      PROTO :DWORD, :DWORD, :DWORD, :DWORD
OptionsPanel0Proc           PROTO :DWORD, :DWORD, :DWORD, :DWORD
OptionsPanel1Proc           PROTO :DWORD, :DWORD, :DWORD, :DWORD
OptionsPanel2Proc           PROTO :DWORD, :DWORD, :DWORD, :DWORD
OptionsPanel3Proc           PROTO :DWORD, :DWORD, :DWORD, :DWORD

SaveBitmapToFile            PROTO :DWORD, :DWORD, :DWORD, :DWORD
GetEncoderClsid             PROTO :DWORD, :DWORD

CS_TakeCodeShot             PROTO :DWORD
CS_GetCodeShotsFolder       PROTO
CS_OpenCodeShotsFolder      PROTO

CS_GenerateFilename         PROTO :DWORD
CS_GenExampleFilename       PROTO :DWORD
CS_CaptureScreenToBitmap    PROTO :DWORD, :DWORD
CS_CaptureScreenToBitmapV2  PROTO :DWORD
CS_GetX64dbgCPUColumnWidths PROTO
CS_GetX64dbgCPUBackcolor    PROTO


CC_CodeShotToolbarProc      PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
CC_CodeShotToolbarInitProc  PROTO :DWORD, :DWORD, :DWORD
CC_InitRebar                PROTO :DWORD, :DWORD, :DWORD
CS_BuildCodeShotMenu        PROTO



atou_ex                     PROTO :DWORD
utoa_ex                     PROTO :DWORD, :DWORD
JustFnameExt                PROTO :DWORD, :DWORD
JustPath                    PROTO :DWORD, :DWORD
CreateDirectoryPath         PROTO :DWORD


.CONST

TRBN_FIRST                  EQU -1501
TRBN_THUMBPOSCHANGING       EQU TRBN_FIRST-1

;---------------------------
; Image types
;---------------------------
IMAGE_TYPE_DEFAULT          EQU 0
IMAGE_TYPE_BMP              EQU 1
IMAGE_TYPE_JPG              EQU 2
IMAGE_TYPE_GIF              EQU 3
IMAGE_TYPE_PNG              EQU 4

CRLF                        TEXTEQU <13,10,0> ; carriage return and linefeed for strings that require them (GuiAddLogMessage for example) 


CODESHOT_TOP_ADJUST         EQU 28d
CODESHOT_LEFT_ADJUST        EQU 5d
CODESHOT_RIGHT_ADJUST       EQU 700d
CODESHOT_BOTTOM_ADJUST      EQU 334d

;---------------------------
; Resources: ico, bmp, png, wav
;---------------------------
ICO_CODESHOT                EQU 100
IMG_CODESHOT                EQU 101
ICO_TAKECODESHOT            EQU 102
IMG_TAKECODESHOT            EQU 103
ICO_CODESHOT_OPTIONS        EQU 104
IMG_CODESHOT_OPTIONS        EQU 105
IMG_CODESHOT_FOLDER         EQU 106

BMP_MENU_CODESHOT_PNG       EQU 110
BMP_MENU_CODESHOT_JPG       EQU 111
BMP_MENU_CODESHOT_BMP       EQU 112
BMP_MENU_CODESHOT_OPTIONS   EQU 113
BMP_MENU_CODESHOT_FOLDER    EQU 114

ICO_OPTIONS_IMAGE           EQU 130
ICO_OPTIONS_CAMERA          EQU 131
ICO_OPTIONS_FILE            EQU 132
ICO_OPTIONS_FOLDER          EQU 133
ICO_OPTIONS_EXIT            EQU 134

; MUI Caption bar images: ICO format
ICO_MUI_MIN                 EQU 140
ICO_MUI_MAX                 EQU 141
ICO_MUI_RES                 EQU 142
ICO_MUI_CLOSE               EQU 143
ICO_MUI_NOCHECKMARK         EQU 144
ICO_MUI_CHECKMARK           EQU 145
ICO_MUI_NOSETRADIO          EQU 146
ICO_MUI_RADIO               EQU 147
IDS_CODESHOT_SHUTTER        EQU 120
;---------------------------


; Plugin Menu Items
MENU_CODESHOT               EQU 1
MENU_CODESHOT_OPTIONS       EQU 2
MENU_CODESHOT_FOLDER        EQU 3

; Options Dialog
IDD_OPTIONSDLG              EQU 1000
IDC_CAPTIONBAR              EQU 1001
IDC_SP1                     EQU 1002
IDC_MENUTEXT                EQU 1009
IDC_OPTIONSMENUITEM0        EQU 1010
IDC_OPTIONSMENUITEM1        EQU 1011
IDC_OPTIONSMENUITEM2        EQU 1012
IDC_OPTIONSMENUITEM3        EQU 1013
IDC_OPTIONSMENUITEM4        EQU 1014
IDC_OPTIONSMENUITEM5        EQU 1015

;OptionsPanel0.dlg
IDD_OptionsPanel0			EQU 1800
IDC_RADIO1                  EQU 1801
IDC_RADIO2                  EQU 1802
IDC_RADIO3                  EQU 1803
IDC_INFOIMAGEFORMAT			EQU 1810
IDC_INFOJPEGQUALITY         EQU 1811
IDC_TRACKJPEGQUALITY        EQU 1812

;OptionsPanel1.dlg
IDD_OptionsPanel1			EQU 1500
IDC_CHECKBOX1               EQU 1501
IDC_CHECKBOX2               EQU 1502
IDC_CHECKBOX3               EQU 1503

;OptionsPanel2.dlg
IDD_OptionsPanel2			EQU 1600
IDC_CHECKBOX4               EQU 1601
IDC_CHECKBOX5               EQU 1602
IDC_CHECKBOX6               EQU 1603
IDC_BTNFILEGEN              EQU 1604

;OptionsPanel3.dlg
IDD_OptionsPanel3			EQU 1700
IDC_CHECKBOX7               EQU 1701
IDC_CHECKBOX8               EQU 1702
IDC_CHECKBOX9               EQU 1703


; Toolbar IDs
IDC_TOOLBAR_BTN             EQU 9999
IDC_TOOLBAR                 EQU 9000
IDC_REBAR                   EQU 8999
TB_CODESHOT                 EQU 222
IDM_CODESHOT_PNG            EQU 223
IDM_CODESHOT_JPG            EQU 224
IDM_CODESHOT_BMP            EQU 225
IDM_CODESHOT_OPTIONS        EQU 226
IDM_CODESHOT_FOLDER         EQU 227

.DATA
CODESHOT_GDIPlusToken	    DD 0C5h
CODESHOT_gdipsi	            GdiplusStartupInput	<1,0,0,0>

szCodeShot                  DB "CodeShot",0
szTakeCodeShot              DB "Take a CodeShot",0
szCSOptionsDlgTitle         DB "CodeShot Options",0
szCodeShotLoaded            DB "CodeShot loaded.",CRLF
szCodeShotUnloaded          DB "CodeShot unloaded.",CRLF
szCodeShotInfo              DB 13,10         
                            DB "CodeShot x32dbg plugin by fearless 2016 - www.LetTheLight.in",13,10
                            DB 13,10
                            DB "CodeShot Features & Usage:",13,10
                            DB " - Capture x64dbg screen to image file",13,10
                            DB " - Supports png, jpeg and bmp file formats",13,10
                            DB " - Option to include address and/or datetime in filename",13,10
                            DB " - Option to save filename to seperate folder based on module name",13,10
                            DB " - Optional toolbar with dropdown menu to make it easier to take codeshots",13,10
                            DB " - Hotkeys for taking codeshot image in specific formats",13,10
                            DB " - Shutter sound when taking codeshot",13,10
                            DB 13,10,0
                            
;---------------------------
; Buffers
;---------------------------
szModuleFilename            DB MAX_PATH DUP (0)
szModuleName                DB MAX_PATH DUP (0)
szDateTimeNow               DB 32 DUP (0)
CODESHOT_DATETIME           DB 32 DUP (0)
CODESHOT_OUTPUTFILE         DB MAX_PATH DUP (0)
CODESHOT_EXAMPLEFILE        DB MAX_PATH DUP (0)
CODESHOT_TESTFILE           DB MAX_PATH DUP (0)
CODESHOTS_FOLDER            DB MAX_PATH dup (0)
X64DBGINIFILE               DB MAX_PATH dup (0)
ADDRESSVALUE                DB 32 DUP (0)
MODULENAMEFOLDER            DB MAX_PATH dup (0)

;---------------------------
; Log messages
;---------------------------
szDebuggingRequired         DB "CodeShot: you need to be debugging to use this option.",CRLF
szFailedToGetMainScreen     DB "CodeShot: failed to obtain handle to main x64dbg screen. Cant take any codeshots.",CRLF
szFailedToCaptureScreen     DB "CodeShot: failed to capture screen to bitmap.",CRLF
szCodeShotCapturedMsg       DB "CodeShot: captured screen to : ",0
szCodeShotMsg               DB 512 DUP (0)

;---------------------------
; Ini settings
;---------------------------
szIni                       DB "ini",0
CodeShotIni                 DB MAX_PATH DUP (0)
szCodeShotsFolder           DB "CodeShots",0
szCameraShutterClick        DB "CameraShutterClick",0
szDefaultImageType          DB "DefaultImageType",0
szImageCompression          DB "ImageCompression",0
szSeperateFolderForModules  DB "SeperateFolderForModules",0
szImageFileIncludeAddress   DB "ImageFileIncludeAddress",0
szImageFileIncludeDatetime  DB "ImageFileIncludeDatetime",0
szShowToolbarButton         DB "ShowToolbarButton",0
szExcludeStatusBar          DB "ExcludeStatusBar",0
szExcludeCommandBar         DB "ExcludeCommandBar",0


szCodeShotsDefaultFolder    DB "codeshots\",0
szx64dbgGui                 DB "Gui",0
szx64dbgColors              DB "Colors",0
szx64dbgCol0                DB "CPUDisassemblyColumnWidth0",0
szx64dbgCol1                DB "CPUDisassemblyColumnWidth1",0
szx64dbgCol2                DB "CPUDisassemblyColumnWidth2",0
szx64dbgCol3                DB "CPUDisassemblyColumnWidth3",0
szx64dbgBackcolor           DB "DisassemblyBackgroundColor",0

;---------------------------
; Image saving stuff
;---------------------------
szJpgExt                    DB ".jpeg",0
szBmpExt                    DB ".bmp",0
szGifExt                    DB ".gif",0
szPngExt                    DB ".png",0
ImageTypeJpg                DW 'i', 'm', 'a', 'g', 'e', '/', 'j', 'p', 'e', 'g', 0
ImageTypeBmp                DW 'i', 'm', 'a', 'g', 'e', '/', 'b', 'm', 'p',  0    
ImageTypeGif                DW 'i', 'm', 'a', 'g', 'e', '/', 'g', 'i', 'f',  0    
ImageTypePng                DW 'i', 'm', 'a', 'g', 'e', '/', 'p', 'n', 'g',  0    
JpegDefaultQuality          DD 90
_EncoderQuality             GUID <01d5be4b5h,0fa4ah,0452dh,<09ch,0ddh,05dh,0b3h,051h,05h,0e7h,0ebh>>
JpegQuality                 DD 90
szExample                   DB "Example",0



;---------------------------
; Options Dialog
;---------------------------
szOptionsMenu0Text          DB 'Image Options',0
szOptionsMenu1Text          DB 'Capture Options',0
szOptionsMenu2Text          DB 'Filename Options',0
szOptionsMenu3Text          DB 'Other Options',0
szOptionsMenu4Text          DB 'Exit',0
szOptionsMenu5Text          DB ' ',0
szCheckbox1Text             DB 'Exclude bottom bars from capture',0
szCheckbox2Text             DB 'Exclude command bar from capture',0
szCheckbox3Text             DB 'Checkbox option 3',0
szCheckbox4Text             DB 'Create a folder for each file module',0
szCheckbox5Text             DB 'Include current address in filename',0
szCheckbox6Text             DB 'Include date time in filename',0
szCheckbox7Text             DB 'Shutter sound when taking codeshot',0
szCheckbox8Text             DB 'Toolbar button (restart may be required)',0
szCheckbox9Text             DB 'Checkbox option 9',0
szRadio1Text                DB 'BMP',0
szRadio2Text                DB 'JPEG',0                
szRadio3Text                DB 'PNG',0
szInfoImageFormat           DB 'Default format:',0
szJpegQuality               DB "JPEG quality: ",0
szInfoJpegQuality           DB 32 DUP (0)
szImageCompressionValue     DB 16 DUP (0)
;---------------------------
; Menus
;---------------------------
szCodeShotOptions           DB "CodeShot Options...",0
szMenuCodeshotPng           DB "Take Png CodeShot",09h,"Ctrl+1",0
szMenuCodeshotJpg           DB "Take Jpeg CodeShot",09h,"Ctrl+2",0
szMenuCodeshotBmp           DB "Take Bitmap CodeShot",09h,"Ctrl+3",0
szMenuCodeshotOptions       DB "CodeShot options...",0
szMenuCodeshotOpenFolder    DB "Open CodeShot folder",0

;---------------------------
; Punctuation
;---------------------------
szNull                      DB 0,0
szCRLF                      DB 13,10,0
szColon                     DB ":",0
szQuote                     DB 22h,0
szZero                      DB "0",0
szOne                       DB "1",0
szTwo                       DB "2",0
szThree                     DB "3",0
szFour                      DB "4",0
sz8zeros                    DB "00000000",0
szQ                         DB "?",0
szSpace                     DB " ",0
szHash                      DB "#",0  
sz20CC                      DB "20",0
szForwardSlash              DB "/",0
szBackSlash                 DB "\",0
szLeftSquareBracket         DB "[",0
szRightSquareBracket        DB "]",0
szPercent                   DB "%",0
szDash                      DB "-",0
szUnderscore                DB "_",0
szHexPrefix                 DB "0x",0
dw100                       DD 100d
dw28                        DD 28d
szCodeShotToolbarButtonText DB "Codeshot",0
szCodeShotTooltipText       DB "(Ctrl+Printscreen) CodeShot",0
szButtonClass               db "Button",0


g_ImageType                 DD IMAGE_TYPE_PNG
g_ImageCompression          DD 90 ; default for jpeg
g_SeperateFolderForModules  DD FALSE
g_ImageFileIncludeAddress   DD FALSE
g_ImageFileIncludeDatetime  DD TRUE
g_ExcludeSideBar            DD FALSE
g_ExcludeComments           DD FALSE
g_CameraShutterClick        DD FALSE
g_ShowToolbarButton         DD TRUE
g_ExcludeStatusBar          DD TRUE
g_ExcludeCommandBar         DD TRUE
g_ExcludeTabbar             DD TRUE

TrayMenuPoint		        POINT <> 			; Tray Menu Popup point tracker

szStylecss                  DB "style.css",0 
szCourierNewFont            DB "Courier New",0
szToolbarClass              DB "ToolbarWindow32",0
szRebarClass                DB "ReBarWindow32",0
szHotkeyClass               DB "msctls_hotkey32",0
szCodeShotToolBarTipText    DB "CodeShot",0
tiClass 					db 'Tooltips_class32', 0
szTrackbarClass             DB 'msctls_trackbar32',0

ti                          TOOLINFO <>

VK_CODESHOT                 DD VK_SNAPSHOT
hFontCourierNew             DD 0

.DATA?
hInstance                   DD ?
hMainScreen                 DD ?
hIcoCodeShot                DD ?
hIcoTakeCodeShot            DD ?
hBmpMenuCodeShotPng         DD ?
hBmpMenuCodeShotJpg         DD ?
hBmpMenuCodeShotBmp         DD ?
hBmpMenuCodeShotOptions     DD ?
hBmpMenuCodeShotFolder      DD ?
hCaptionBar                 DD ?
hPreMenuBtn                 DD ?
hOptionsMenu0               DD ?
hOptionsMenu1               DD ?
hOptionsMenu2               DD ?
hOptionsMenu3               DD ?
hOptionsMenu4               DD ?
hOptionsMenu5               DD ?
;hCodeShotToolbarButtonControl DD ?
pImageCodecInfo             DD ?
eps                         EncoderParameters <?>
hQToolbar                   DD ?
hCodeShotToolbar            DD ?
hCodeShotIL_Enabled         DD ?
hCodeShotIL_Disabled        DD ?
hCodeShotRebar              DD ?
hCodeShotMenu               DD ?
hToolTip                    DD ?

hCurrentPanel               DD ?
hSP1                        DD ?
hOptionsPanel0              DD ?
hOptionsPanel1              DD ?
hOptionsPanel2              DD ?
hOptionsPanel3              DD ?
hChk1                       DD ?
hChk2                       DD ?
hChk3                       DD ?
hChk4                       DD ?
hChk5                       DD ?
hChk6                       DD ?
hChk7                       DD ?
hChk8                       DD ?
hChk9                       DD ?
hRadio1                     DD ?
hRadio2                     DD ?
hRadio3                     DD ?
hBtnFileGen                 DD ?
hBtnInfoImageFormat         DD ?
hBtnInfoJpegQuality         DD ?
hTrackbarJpegQuality        DD ?
hMenuText                   DD ?















