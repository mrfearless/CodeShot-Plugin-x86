;=====================================================================================
; x64dbg plugin SDK for Masm - fearless 2016 - www.LetTheLight.in 
;
; CodeShot.asm 
;
;-------------------------------------------------------------------------------------

.686
.MMX
.XMM
.model flat,stdcall
option casemap:none

;DEBUG32 EQU 1

IFDEF DEBUG32
    PRESERVEXMMREGS equ 1
    includelib M:\Masm32\lib\Debug32.lib
    DBG32LIB equ 1
    DEBUGEXE textequ <'M:\Masm32\DbgWin.exe'>
    include M:\Masm32\include\debug32.inc
ENDIF

Include x64dbgpluginsdk.inc               ; Main x64dbg Plugin SDK for your program, and prototypes for the main exports 

include x64dbgpluginsdk_x86.inc
includelib x64dbgpluginsdk_x86.lib

Include CodeShot.inc ; plugin's include file
include CodeShotIni.asm
include CodeShotDate.asm

;=====================================================================================


.CONST
PLUGIN_VERSION      EQU 1

.DATA
PLUGIN_NAME         DB "CodeShot",0

.DATA?
;-------------------------------------------------------------------------------------
; GLOBAL Plugin SDK variables
;-------------------------------------------------------------------------------------
PUBLIC              pluginHandle
PUBLIC              hwndDlg
PUBLIC              hMenu
PUBLIC              hMenuDisasm
PUBLIC              hMenuDump
PUBLIC              hMenuStack

pluginHandle        DD ?
hwndDlg             DD ?
hMenu               DD ?
hMenuDisasm         DD ?
hMenuDump           DD ?
hMenuStack          DD ?
;-------------------------------------------------------------------------------------


.CODE

;=====================================================================================
; Main entry function for a DLL file  - required.
;-------------------------------------------------------------------------------------
DllMain PROC hinstDLL:HINSTANCE, fdwReason:DWORD, lpvReserved:DWORD
    .IF fdwReason == DLL_PROCESS_ATTACH
        mov eax, hinstDLL
        mov hInstance, eax
    .ENDIF
    mov eax,TRUE
    ret
DllMain ENDP


;=====================================================================================
; pluginit - Called by debugger when plugin.dp32 is loaded - needs to be EXPORTED
; 
; Arguments: initStruct - a pointer to a PLUG_INITSTRUCT structure
;
; Notes:     you must fill in the pluginVersion, sdkVersion and pluginName members. 
;            The pluginHandle is obtained from the same structure - it may be needed in
;            other function calls.
;
;            you can call your own setup routine from within this function to setup 
;            menus and commands, and pass the initStruct parameter to this function.
;
;-------------------------------------------------------------------------------------
pluginit PROC C PUBLIC USES EBX initStruct:DWORD
    mov ebx, initStruct

    ; Fill in required information of initStruct, which is a pointer to a PLUG_INITSTRUCT structure
    mov eax, PLUGIN_VERSION
    mov [ebx].PLUG_INITSTRUCT.pluginVersion, eax
    mov eax, PLUG_SDKVERSION
    mov [ebx].PLUG_INITSTRUCT.sdkVersion, eax
    Invoke lstrcpy, Addr [ebx].PLUG_INITSTRUCT.pluginName, Addr PLUGIN_NAME
    
    mov ebx, initStruct
    mov eax, [ebx].PLUG_INITSTRUCT.pluginHandle
    mov pluginHandle, eax
    
    ; Do any other initialization here
    
    ; Construct plugin's .ini file from module filename
    Invoke GetModuleFileName, 0, Addr szModuleFilename, SIZEOF szModuleFilename
    Invoke GetModuleFileName, 0, Addr X64DBGINIFILE, SIZEOF X64DBGINIFILE
    Invoke GetModuleFileName, hInstance, Addr CodeShotIni, SIZEOF CodeShotIni
    Invoke szLen, Addr CodeShotIni
    lea ebx, CodeShotIni
    add ebx, eax
    sub ebx, 4 ; move back past 'dp32' extention
    mov byte ptr [ebx], 0 ; null so we can use lstrcat
    Invoke szCatStr, ebx, Addr szIni ; add 'ini' to end of string instead       
    
    ; get main .ini file for x32/64dbg.exe
    
    
    Invoke szLen, Addr X64DBGINIFILE
    lea ebx, X64DBGINIFILE
    add ebx, eax
    sub ebx, 3 ; move back past 'exe' extention
    mov byte ptr [ebx], 0 ; null so we can use lstrcat
    Invoke szCatStr, ebx, Addr szIni ; add 'ini' to end of string instead 
    
    ;PrintString X64DBGINIFILE
    
    
    Invoke CS_GetCodeShotsFolder
    
    Invoke GdiplusStartup, Addr CODESHOT_GDIPlusToken, Addr CODESHOT_gdipsi, NULL
	mov eax, TRUE
	ret
pluginit ENDP


;=====================================================================================
; plugstop - Called by debugger when the plugin.dp32 is unloaded - needs to be EXPORTED
;
; Arguments: none
; 
; Notes:     perform cleanup operations here, clearing menus and other housekeeping
;
;-------------------------------------------------------------------------------------
plugstop PROC C PUBLIC 
    
    ; remove any menus, unregister any callbacks etc
    Invoke UnregisterHotKey, hQToolbar, 0
    Invoke UnregisterHotKey, hQToolbar, 1
    Invoke UnregisterHotKey, hQToolbar, 2
    Invoke UnregisterHotKey, hQToolbar, 3
    
    .IF hCodeShotToolbar != NULL 
        Invoke _plugin_stoptoolbargui
    .ENDIF
    Invoke GdiplusShutdown, CODESHOT_GDIPlusToken
    Invoke _plugin_menuclear, hMenu
    Invoke GuiAddLogMessage, Addr szCodeShotUnloaded
    
    mov eax, TRUE
    ret
plugstop ENDP


;=====================================================================================
; plugsetup - Called by debugger to initialize your plugins setup - needs to be EXPORTED
;
; Arguments: setupStruct - a pointer to a PLUG_SETUPSTRUCT structure
; 
; Notes:     setupStruct contains useful handles for use within x64dbg, mainly Qt 
;            menu handles (which are not supported with win32 api) and the main window
;            handle with this information you can add your own menus and menu items 
;            to an existing menu, or one of the predefined supported right click 
;            context menus: hMenuDisam, hMenuDump & hMenuStack
;            
;            plugsetup is called after pluginit. 
;-------------------------------------------------------------------------------------
plugsetup PROC C PUBLIC USES EBX setupStruct:DWORD
    LOCAL hIconData:ICONDATA
    
    mov ebx, setupStruct

    ; Extract handles from setupStruct which is a pointer to a PLUG_SETUPSTRUCT structure  
    mov eax, [ebx].PLUG_SETUPSTRUCT.hwndDlg
    mov hwndDlg, eax
    mov eax, [ebx].PLUG_SETUPSTRUCT.hMenu
    mov hMenu, eax
    mov eax, [ebx].PLUG_SETUPSTRUCT.hMenuDisasm
    mov hMenuDisasm, eax
    mov eax, [ebx].PLUG_SETUPSTRUCT.hMenuDump
    mov hMenuDump, eax
    mov eax, [ebx].PLUG_SETUPSTRUCT.hMenuStack
    mov hMenuStack, eax
    
    mov hMainScreen, 0
    Invoke _plugin_getmainscreenhandle, Addr hMainScreen
    ;PrintDec hMainScreen
    ;Invoke GuiGetWindowHandle
    ;PrintDec eax
    
    .IF hMainScreen == 0
        Invoke GuiAddLogMessage, Addr szFailedToGetMainScreen
    .ENDIF

    Invoke LoadImage, hInstance, ICO_CODESHOT, IMAGE_ICON, 0, 0, 0
    mov hIcoCodeShot, eax
    
    Invoke LoadImage, hInstance, ICO_TAKECODESHOT, IMAGE_ICON, 0, 0, 0
    mov hIcoTakeCodeShot, eax

    ; Load menu icons for popup dropdown menu
    Invoke LoadBitmap, hInstance, BMP_MENU_CODESHOT_PNG
    mov hBmpMenuCodeShotPng, eax    
    Invoke LoadBitmap, hInstance, BMP_MENU_CODESHOT_JPG
    mov hBmpMenuCodeShotJpg, eax    
    Invoke LoadBitmap, hInstance, BMP_MENU_CODESHOT_BMP
    mov hBmpMenuCodeShotBmp, eax    
    Invoke LoadBitmap, hInstance, BMP_MENU_CODESHOT_OPTIONS
    mov hBmpMenuCodeShotOptions, eax    
    Invoke LoadBitmap, hInstance, BMP_MENU_CODESHOT_FOLDER
    mov hBmpMenuCodeShotFolder, eax    
    
    ; Read ini settings
    Invoke IniGetCameraShutterClick
    mov g_CameraShutterClick, eax
    Invoke IniGetSeperateFolderForModules
    mov g_SeperateFolderForModules, eax
    Invoke IniGetImageFileIncludeAddress
    mov g_ImageFileIncludeAddress, eax
    Invoke IniGetDefaultImageType
    mov g_ImageType, eax
    Invoke IniGetImageCompression
    mov g_ImageCompression, eax
    Invoke IniGetShowToolbarButton
    mov g_ShowToolbarButton, eax
    Invoke IniGetImageFileIncludeDatetime
    mov g_ImageFileIncludeDatetime, eax
    Invoke IniGetExcludeStatusBar
    mov g_ExcludeStatusBar, eax
    Invoke IniGetExcludeCommandBar
    mov g_ExcludeCommandBar, eax
    
    mov hCodeShotToolbar, 0
    .IF g_ShowToolbarButton == 1
        Invoke _plugin_starttoolbargui, Addr CC_CodeShotToolbarProc, Addr CC_CodeShotToolbarInitProc
    .ENDIF
    
    ; Do any setup here: add menus, menu items, callback and commands etc
    
    Invoke _plugin_menuaddentry, hMenu, MENU_CODESHOT, Addr szTakeCodeShot
    Invoke _plugin_menuaddentry, hMenu, MENU_CODESHOT_OPTIONS, Addr szCodeShotOptions
    
    ;Invoke _plugin_loadmenuicon, hInstance, IMG_CODESHOT, Addr hIconData
    ;.IF eax == TRUE
    ;    Invoke _plugin_menuseticon, hMenu, Addr hIconData
    ;    ;Invoke _plugin_menuentryseticon, pluginHandle, MENU_CODESHOT, Addr hIconData
    ;.ENDIF
    
    Invoke _plugin_loadmenuicon, hInstance, IMG_CODESHOT_OPTIONS, Addr hIconData
    .IF eax == TRUE
        Invoke _plugin_menuentryseticon, pluginHandle, MENU_CODESHOT_OPTIONS, Addr hIconData
    .ENDIF
    
    Invoke _plugin_loadmenuicon, hInstance, IMG_TAKECODESHOT, Addr hIconData
    .IF eax == TRUE
        Invoke _plugin_menuseticon, hMenu, Addr hIconData
        Invoke _plugin_menuentryseticon, pluginHandle, MENU_CODESHOT, Addr hIconData
    .ENDIF
    
    Invoke _plugin_menuaddseparator, hMenu
    Invoke _plugin_menuaddentry, hMenu, MENU_CODESHOT_FOLDER, Addr szMenuCodeshotOpenFolder

    Invoke _plugin_loadmenuicon, hInstance, IMG_CODESHOT_FOLDER, Addr hIconData
    .IF eax == TRUE
        Invoke _plugin_menuentryseticon, pluginHandle, MENU_CODESHOT_FOLDER, Addr hIconData
    .ENDIF
    
    Invoke GuiAddLogMessage, Addr szCodeShotInfo
    
    
    
    
    ret
plugsetup ENDP


;=====================================================================================
; CC_CodeShotToolbarProc
;-------------------------------------------------------------------------------------
CC_CodeShotToolbarProc PROC USES EBX ECX hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM, uIdSubclass:UINT, dwRefData:DWORD
    LOCAL hParent:DWORD
    ;LOCAL hControl:DWORD
    LOCAL lpThreadId:DWORD
    LOCAL wNotifyCode:DWORD
    LOCAL VK_HOTKEY:DWORD
    LOCAL rect:RECT
    
    mov eax, uMsg
    ;.IF eax == WM_NCDESTROY
    ;    Invoke DestroyWindow, dwRefData
    ;    Invoke RemoveWindowSubclass, hWin, Addr GUIRedirectionProc, uIdSubclass ; remove subclass before control destroyed.

    
    .IF eax == WM_COMMAND
		mov eax, wParam
		shr eax, 16
		mov wNotifyCode, eax
		mov	eax,wParam
		and	eax,0FFFFh

		.IF eax == IDC_TOOLBAR_BTN || eax == TB_CODESHOT
		
            Invoke DbgIsDebugging
            .IF eax == FALSE
                Invoke GuiAddLogMessage, Addr szDebuggingRequired
            .ELSE
                Invoke CS_TakeCodeShot, NULL
            .ENDIF		
		
		.ELSEIF eax == IDM_CODESHOT_PNG
            Invoke DbgIsDebugging
            .IF eax == FALSE
                Invoke GuiAddLogMessage, Addr szDebuggingRequired
            .ELSE
                Invoke CS_TakeCodeShot, IMAGE_TYPE_PNG
            .ENDIF
            
		.ELSEIF eax == IDM_CODESHOT_JPG
            Invoke DbgIsDebugging
            .IF eax == FALSE
                Invoke GuiAddLogMessage, Addr szDebuggingRequired
            .ELSE
                Invoke CS_TakeCodeShot, IMAGE_TYPE_JPG
            .ENDIF
            
		.ELSEIF eax == IDM_CODESHOT_BMP
            Invoke DbgIsDebugging
            .IF eax == FALSE
                Invoke GuiAddLogMessage, Addr szDebuggingRequired
            .ELSE
                Invoke CS_TakeCodeShot, IMAGE_TYPE_BMP
            .ENDIF	
		
            ;Invoke CreateThread, NULL, NULL, Addr CS_TakeCodeShot, IMAGE_TYPE_PNG, NULL, Addr lpThreadId
        
        .ELSEIF eax == IDM_CODESHOT_OPTIONS
            Invoke DialogBoxParam, hInstance, IDD_OPTIONSDLG, hwndDlg, Addr CodeShotOptionsDlgProc, NULL
        
        .ELSEIF eax == IDM_CODESHOT_FOLDER
            Invoke CS_OpenCodeShotsFolder
            
        .ENDIF
    
    .ELSEIF eax == WM_NOTIFY
		mov ecx, lParam				; lParam is a pointer to a NMHDR Struct
		mov eax, (NMHDR PTR [ecx]).code
		mov ebx, (NMHDR PTR [ecx]).hwndFrom
		.IF eax == NM_CUSTOMDRAW
		    ;PrintText 'NMTBCUSTOMDRAW'
		    .IF ebx == hCodeShotToolbar
		        ;PrintText 'hCodeShotToolbar'
		        Invoke GetClientRect, hCodeShotToolbar, Addr rect
		        ;Invoke GetStockObject, LTGRAY_BRUSH	
		        Invoke GetSysColorBrush, COLOR_BTNFACE
		        mov ecx, lParam
		        mov ebx, (NMTBCUSTOMDRAW PTR [ecx]).nmcd.hdc
		        Invoke FillRect, ebx, Addr rect, eax
		    .ENDIF
		.ELSEIF eax == TBN_DROPDOWN
		    ;PrintText 'TBN_DROPDOWN'
            Invoke GetWindowRect, hCodeShotToolbar, Addr rect
            ;Invoke ClientToScreen, hToolBarConnect, Addr TrayMenuPoint
            Invoke MapWindowPoints,  hCodeShotToolbar, NULL, Addr rect, 2
            push eax
            mov ebx, rect.bottom
            mov ecx, rect.top
            sub ecx, ebx
            shr eax, 16
            sub eax, ecx
            mov TrayMenuPoint.y, eax
            pop eax
            and	eax,0FFFFh
            mov TrayMenuPoint.x, eax
        	;Invoke GetCursorPos, addr TrayMenuPoint
        	;sub TrayMenuPoint.x, 10d
        	;add TrayMenuPoint.y, 10d
        	; Focus Main Window - ; Fix for shortcut menu not popping up right
        	Invoke SetForegroundWindow, hWin 
        	Invoke TrackPopupMenu, hCodeShotMenu, TPM_LEFTALIGN +TPM_LEFTBUTTON, TrayMenuPoint.x, TrayMenuPoint.y, NULL, hWin, NULL
        	Invoke PostMessage, hWin, WM_NULL, 0, 0 ; Fix for shortcut menu not popping up right    
		.ENDIF
    
    
    .ELSEIF eax == WM_SIZE
        mov eax, lParam
		and	eax,0FFFFh
		.IF eax > 1024d
            Invoke GetParent, hWin
            mov hParent, eax
            Invoke GetClientRect, hParent, Addr rect
            ;PrintDec rect.right
            mov eax, rect.right
            sub eax, 48;26
            mov rect.left, eax
            ;Invoke GetDlgItem, hWin, IDC_TOOLBAR ;_BTN
            ;mov hControl, eax
            Invoke SetWindowPos, hCodeShotToolbar, HWND_TOP, rect.left, 2, 0, 0, SWP_NOZORDER + SWP_NOSIZE
        .ENDIF
    
    .ELSEIF eax == WM_HOTKEY
		mov eax, lParam
		shr eax, 16
		mov VK_HOTKEY, eax
		mov	eax,lParam
		and	eax,0FFFFh

        .IF wParam == 0 ; possible Ctrl+Printscreen
            .IF eax == MOD_CONTROL
                mov eax, VK_HOTKEY
                .IF eax == VK_CODESHOT        
                    Invoke CS_TakeCodeShot, NULL
                .ENDIF
            .ENDIF

        .ELSEIF wParam == 1
            .IF eax == MOD_CONTROL
                mov eax, VK_HOTKEY
                .IF eax == VK_1
                    Invoke CS_TakeCodeShot, IMAGE_TYPE_PNG
                .ENDIF
            .ENDIF

        .ELSEIF wParam == 2
            .IF eax == MOD_CONTROL
                mov eax, VK_HOTKEY
                .IF eax == VK_2
                    Invoke CS_TakeCodeShot, IMAGE_TYPE_JPG
                .ENDIF
            .ENDIF

        .ELSEIF wParam == 3
            .IF eax == MOD_CONTROL
                mov eax, VK_HOTKEY
                .IF eax == VK_3
                    Invoke CS_TakeCodeShot, IMAGE_TYPE_BMP
                .ENDIF
            .ENDIF

        .ENDIF
    
    .ENDIF
    
    Invoke DefSubclassProc, hWin, uMsg, wParam, lParam         
    ret

CC_CodeShotToolbarProc ENDP


;=====================================================================================
; CC_CodeShotToolbarInitProc
;-------------------------------------------------------------------------------------
CC_CodeShotToolbarInitProc PROC hMainWindow:DWORD, hMenubar:DWORD, hToolbar:DWORD
    LOCAL rect:RECT
    LOCAL hinstance:DWORD
	LOCAL tbab:TBADDBITMAP	; Add Bitmap Structure
	LOCAL tbb:TBBUTTON		; Button Structure
	LOCAL hTbBmp:DWORD			; Toolbar bitmap handle
	LOCAL dwSize:DWORD
	LOCAL dwStyle:DWORD
	LOCAL buffer[64]:BYTE
	
	mov eax, hToolbar
	mov hQToolbar, eax
	
    Invoke GetModuleHandle, NULL
    mov hinstance, eax
    
    Invoke GetClientRect, hMainWindow, Addr rect
    
    mov eax, WS_CHILD + WS_VISIBLE + TBSTYLE_CUSTOMERASE + TBSTYLE_TRANSPARENT + TBSTYLE_TOOLTIPS + TBSTYLE_FLAT + CCS_NORESIZE + CCS_NODIVIDER
    mov dwStyle, eax
    
    mov eax, rect.right
    sub eax, 48;26   
    
    Invoke CreateWindowEx, 0, Addr szToolbarClass, NULL, dwStyle, eax, 2, 48, 22, hToolbar, IDC_TOOLBAR, hinstance, NULL ;+ TBSTYLE_TRANSPARENT 24
    mov hCodeShotToolbar, eax
    
    ;Invoke GetParent, hCodeShotToolbar
    ;PrintDec eax
    ;PrintDec hToolbar
    
    Invoke ImageList_Create, 16,16, ILC_COLOR32, 1, 2
    mov hCodeShotIL_Enabled, eax
    Invoke ImageList_Create, 16,16, ILC_COLOR32, 1, 2
    mov hCodeShotIL_Disabled, eax
    
    Invoke SendMessage, hCodeShotToolbar, CCM_SETVERSION, 5, 0
    Invoke SendMessage, hCodeShotToolbar, TB_SETIMAGELIST, 0, hCodeShotIL_Enabled
    Invoke SendMessage, hCodeShotToolbar, TB_SETDISABLEDIMAGELIST, 0, hCodeShotIL_Disabled
    
    Invoke ImageList_AddIcon, hCodeShotIL_Enabled, hIcoTakeCodeShot
    Invoke ImageList_AddIcon, hCodeShotIL_Disabled, hIcoTakeCodeShot
    
    invoke SendMessage, hCodeShotToolbar, TB_BUTTONSTRUCTSIZE, sizeof TBBUTTON, 0	; Set toolbar struct size

	mov  ebx, 16d ;Wd  ; loword = bitmap Width
	mov  eax, 16d ;Ht  ; hiword = bitmap Height
	shl  eax, 16d
	mov  ax, bx
	mov dwSize, eax
    
    ;invoke SendMessage, hCodeShotToolbar, TB_SETBITMAPSIZE, 0, dwSize ; Set bitmap size
    invoke SendMessage, hCodeShotToolbar, TB_SETBUTTONSIZE, 0, dwSize ; Set each button size

    Invoke SendMessage, hCodeShotToolbar, TB_SETEXTENDEDSTYLE, 0, TBSTYLE_EX_DRAWDDARROWS
    
	mov tbb.fsState, TBSTATE_ENABLED
	mov tbb.dwData, 0
	mov tbb.iString, 0
	mov tbb.iBitmap, 0  ;; button  ID number
	mov tbb.idCommand, TB_CODESHOT  ;; command ID number
	mov tbb.fsStyle, TBSTYLE_BUTTON  or TBSTYLE_AUTOSIZE or TBSTYLE_DROPDOWN
	invoke SendMessage, hCodeShotToolbar, TB_ADDBUTTONS, 1, ADDR tbb
	
	; for without dropdown button comment out after TBSTYLE_BUTTON, adjust to: mov eax, rect.right sub eax, 26, adjust WM_SIZE to same 26d instead of 48d
	
	;Invoke CC_InitRebar, hMainWindow, hMenubar, hToolbar
	
	invoke CreateWindowEx, NULL, addr tiClass, NULL, TTS_ALWAYSTIP, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, hCodeShotToolbar, NULL, hinstance, NULL
    mov hToolTip, eax
    mov ti.cbSize, SIZEOF TOOLINFO
    mov ti.uFlags, TTF_SUBCLASS or TTF_IDISHWND
    
    mov eax, hCodeShotToolbar
    mov ti.TOOLINFO.uId, eax
    Invoke LoadString, hInstance, 1001, Addr buffer, 64d
    lea eax, szCodeShotTooltipText;buffer
    mov ti.TOOLINFO.lpszText, eax
    Invoke SendMessage, hToolTip, TTM_ADDTOOL, NULL, Addr ti
	
	Invoke CS_BuildCodeShotMenu
	
	
	Invoke RegisterHotKey, hToolbar, 0, MOD_CONTROL	+ MOD_NOREPEAT, VK_CODESHOT
	Invoke RegisterHotKey, hToolbar, 1, MOD_CONTROL	+ MOD_NOREPEAT, VK_1
	Invoke RegisterHotKey, hToolbar, 2, MOD_CONTROL	+ MOD_NOREPEAT, VK_2
	Invoke RegisterHotKey, hToolbar, 3, MOD_CONTROL	+ MOD_NOREPEAT, VK_3
	
	
	mov eax, 0
    ret

CC_CodeShotToolbarInitProc ENDP


;=====================================================================================
; CC_InitRebar
;-------------------------------------------------------------------------------------
CC_InitRebar PROC hMainWindow:DWORD, hMenubar:DWORD, hToolbar:DWORD
    LOCAL hinstance:DWORD
    LOCAL rect:RECT
    LOCAL RebarInfo:REBARINFO
    LOCAL rbbi:REBARBANDINFO
    LOCAL tbhandl:DWORD
    LOCAL tbTile:DWORD

    Invoke GetModuleHandle, NULL
    mov hinstance, eax
    
    Invoke GetClientRect, hMainWindow, Addr rect
    
    mov eax, rect.right
    sub eax, 26   
    Invoke CreateWindowEx, 0, Addr szRebarClass, NULL, WS_CHILD + WS_VISIBLE + RBS_TOOLTIPS , eax, 2, 24, 24, hToolbar, IDC_REBAR, hinstance, NULL ;+ TBSTYLE_TRANSPARENT RBS_BANDBORDERS RBS_FIXEDORDER
    mov hCodeShotRebar, eax
    
    
    
    ;PrintDec hCodeShotRebar
    
    mov rbbi.cbSize,SIZEOF REBARBANDINFO
    mov rbbi.fMask,       RBBIM_ID or RBBIM_STYLE or RBBIM_CHILDSIZE or RBBIM_CHILD ;
    mov rbbi.wID,         IDC_TOOLBAR
    mov rbbi.fStyle,      RBBS_FIXEDSIZE or RBBS_CHILDEDGE;RBBS_CHILDEDGE or RBBS_FIXEDSIZE
    mov rbbi.lx,0;100
    mov rbbi.cxMinChild,22
    mov rbbi.cyMinChild,22
    mov rbbi.cyChild,22
    mov eax, hCodeShotToolbar
    mov rbbi.hwndChild,   eax
    invoke SendMessage, hCodeShotRebar, RB_INSERTBAND, 0, ADDR rbbi  
    Invoke SendMessage, hCodeShotRebar, RB_SETBKCOLOR, 0, 0F0F0F0h
    ret

CC_InitRebar ENDP




;=====================================================================================
; CBMENUENTRY - Called by debugger when a menu item is clicked - needs to be EXPORTED
;
; Arguments: cbType
;            cbInfo - a pointer to a PLUG_CB_MENUENTRY structure. The hEntry contains 
;            the resource id of menu item identifiers
;  
; Notes:     hEntry can be used to determine if the user has clicked on your plugins
;            menu item(s) and to do something in response to it.
;            Needs to be PROC C type procedure call to be compatible with debugger
;-------------------------------------------------------------------------------------
CBMENUENTRY PROC C PUBLIC USES EBX cbType:DWORD, cbInfo:DWORD
    mov ebx, cbInfo
    mov eax, [ebx].PLUG_CB_MENUENTRY.hEntry
    
    .IF eax == MENU_CODESHOT
        Invoke DbgIsDebugging
        .IF eax == FALSE
            Invoke GuiAddLogMessage, Addr szDebuggingRequired
            mov eax, FALSE
            ret
        .ENDIF    
        
        Invoke CS_TakeCodeShot, g_ImageType ;IMAGE_TYPE_PNG
        
    .ELSEIF eax == MENU_CODESHOT_OPTIONS    
        
        Invoke DialogBoxParam, hInstance, IDD_OPTIONSDLG, hwndDlg, Addr CodeShotOptionsDlgProc, NULL
    
    .ELSEIF eax == MENU_CODESHOT_FOLDER
        
        Invoke CS_OpenCodeShotsFolder
        
    .ENDIF
    
    ret

CBMENUENTRY ENDP


CBINITDEBUG PROC C PUBLIC USES EBX cbType:DWORD, cbInfo:DWORD
    
    ;Invoke EnableWindow, hCodeShotToolbarButtonControl, TRUE
    ;Invoke ShowWindow, hCodeShotToolbarButtonControl, SW_SHOW
    
    ret

CBINITDEBUG ENDP


CBSTOPDEBUG PROC C PUBLIC USES EBX cbType:DWORD, cbInfo:DWORD
    
    ;Invoke ShowWindow, hCodeShotToolbarButtonControl, SW_HIDE
    ;Invoke EnableWindow, hCodeShotToolbarButtonControl, FALSE
    ret

CBSTOPDEBUG ENDP


;=====================================================================================
; CodeShot Dialog Procedure
;-------------------------------------------------------------------------------------
CodeShotOptionsDlgProc PROC hWin:HWND,iMsg:DWORD,wParam:WPARAM, lParam:LPARAM

    mov eax, iMsg
    .IF eax == WM_INITDIALOG
        
        Invoke GetDlgItem, hWin, IDC_MENUTEXT
        mov hMenuText, eax
        Invoke SetWindowText, hMenuText, Addr szOptionsMenu0Text
        ;-----------------------------------------------------------------------------------------------------
        ; ModernUI_CaptionBar & ModernUI style dialog
        ;-----------------------------------------------------------------------------------------------------    
		Invoke MUIApplyToDialog, hWin, FALSE, TRUE
		
		; Create CaptionBar control and save handle
		Invoke MUICaptionBarCreate, hWin, Addr szCSOptionsDlgTitle, 26, IDC_CAPTIONBAR, MUICS_WINNODROPSHADOW + MUICS_NOMAXBUTTON + MUICS_NOMINBUTTON + MUICS_LEFT ;or MUICS_REDCLOSEBUTTON
		mov hCaptionBar, eax

		; Set some properties for our CaptionBar control 
		Invoke MUICaptionBarSetProperty, hCaptionBar, @CaptionBarBackColor, MUI_RGBCOLOR(27,161,226)
		Invoke MUICaptionBarSetProperty, hCaptionBar, @CaptionBarBtnTxtRollColor, MUI_RGBCOLOR(61,61,61)
		Invoke MUICaptionBarSetProperty, hCaptionBar, @CaptionBarBtnBckRollColor, MUI_RGBCOLOR(87,193,244)	

        ;-----------------------------------------------------------------------------------------------------
		; Create ModernUI_Button controls for our menu items
		
		
		Invoke MUIButtonCreate, hWin, Addr szOptionsMenu5Text, 1, 27, 220, 43, IDC_OPTIONSMENUITEM5, MUIBS_LEFT ;+ MUIBS_HAND
		mov hPreMenuBtn, eax
        Invoke MUIButtonSetAllProperties, hPreMenuBtn, Addr MUI_MENUITEM_DARK_THEME_BLANK_2, SIZEOF MUI_BUTTON_PROPERTIES		
		
		Invoke MUIButtonCreate, hWin, Addr szOptionsMenu0Text, 1, 70, 220, 45, IDC_OPTIONSMENUITEM0, MUIBS_LEFT ;+ MUIBS_HAND
		mov hOptionsMenu0, eax
		Invoke MUIButtonSetProperty, hOptionsMenu0, @ButtonDllInstance, hInstance
		Invoke MUIButtonLoadImages, hOptionsMenu0, MUIBIT_ICO, ICO_OPTIONS_IMAGE, ICO_OPTIONS_IMAGE, ICO_OPTIONS_IMAGE, ICO_OPTIONS_IMAGE, ICO_OPTIONS_IMAGE
		Invoke MUIButtonSetAllProperties, hOptionsMenu0, Addr MUI_MENUITEM_DARK_THEME_2, SIZEOF MUI_BUTTON_PROPERTIES
		
		Invoke MUIButtonCreate, hWin, Addr szOptionsMenu1Text, 1, 115, 220, 45, IDC_OPTIONSMENUITEM1, MUIBS_LEFT + MUIBS_HAND
		mov hOptionsMenu1, eax
		Invoke MUIButtonSetProperty, hOptionsMenu1, @ButtonDllInstance, hInstance
		Invoke MUIButtonLoadImages, hOptionsMenu1, MUIBIT_ICO, ICO_OPTIONS_CAMERA, ICO_OPTIONS_CAMERA, ICO_OPTIONS_CAMERA, ICO_OPTIONS_CAMERA, ICO_OPTIONS_CAMERA
		Invoke MUIButtonSetAllProperties, hOptionsMenu1, Addr MUI_MENUITEM_DARK_THEME_2, SIZEOF MUI_BUTTON_PROPERTIES

		; Create our ModernUI_Button control
		Invoke MUIButtonCreate, hWin, Addr szOptionsMenu2Text, 1, 160, 220, 45, IDC_OPTIONSMENUITEM2, MUIBS_LEFT + MUIBS_HAND
		mov hOptionsMenu2, eax
		Invoke MUIButtonSetProperty, hOptionsMenu2, @ButtonDllInstance, hInstance
		Invoke MUIButtonLoadImages, hOptionsMenu2, MUIBIT_ICO, ICO_OPTIONS_FILE, ICO_OPTIONS_FILE, ICO_OPTIONS_FILE, ICO_OPTIONS_FILE, ICO_OPTIONS_FILE
        Invoke MUIButtonSetAllProperties, hOptionsMenu2, Addr MUI_MENUITEM_DARK_THEME_2, SIZEOF MUI_BUTTON_PROPERTIES
        
		; Create our ModernUI_Button control
		Invoke MUIButtonCreate, hWin, Addr szOptionsMenu3Text, 1, 205, 220, 45, IDC_OPTIONSMENUITEM3, MUIBS_LEFT + MUIBS_HAND
		mov hOptionsMenu3, eax
		Invoke MUIButtonSetProperty, hOptionsMenu3, @ButtonDllInstance, hInstance
		Invoke MUIButtonLoadImages, hOptionsMenu3, MUIBIT_ICO, ICO_OPTIONS_FOLDER, ICO_OPTIONS_FOLDER, ICO_OPTIONS_FOLDER, ICO_OPTIONS_FOLDER, ICO_OPTIONS_FOLDER
        Invoke MUIButtonSetAllProperties, hOptionsMenu3, Addr MUI_MENUITEM_DARK_THEME_2, SIZEOF MUI_BUTTON_PROPERTIES

		Invoke MUIButtonCreate, hWin, Addr szOptionsMenu4Text, 1, 250, 220, 45, IDC_OPTIONSMENUITEM4, MUIBS_LEFT + MUIBS_HAND
		mov hOptionsMenu4, eax
		Invoke MUIButtonSetProperty, hOptionsMenu4, @ButtonDllInstance, hInstance
		Invoke MUIButtonLoadImages, hOptionsMenu4, MUIBIT_ICO, ICO_OPTIONS_EXIT, ICO_OPTIONS_EXIT, ICO_OPTIONS_EXIT, ICO_OPTIONS_EXIT, ICO_OPTIONS_EXIT
        Invoke MUIButtonSetAllProperties, hOptionsMenu4, Addr MUI_MENUITEM_DARK_THEME_2, SIZEOF MUI_BUTTON_PROPERTIES
        
		Invoke MUIButtonCreate, hWin, Addr szOptionsMenu5Text, 1, 295, 220, 45, IDC_OPTIONSMENUITEM5, MUIBS_LEFT ;+ MUIBS_HAND
		mov hOptionsMenu5, eax
        Invoke MUIButtonSetAllProperties, hOptionsMenu5, Addr MUI_MENUITEM_DARK_THEME_BLANK_2, SIZEOF MUI_BUTTON_PROPERTIES
        
        Invoke MUIButtonSetState, hOptionsMenu0, TRUE
        
    	; smart panel container
    	Invoke MUISmartPanelCreate, hWin, 221, 70, 387, 215, IDC_SP1, MUISPS_NORMAL ;327
    	mov hSP1, eax
    	
    	Invoke MUISmartPanelSetProperty, hSP1, @SmartPanelDllInstance, hInstance
    	;Invoke SmartPanelSetIsDlgMsgVar, hSP1, Addr hCurrentPanel
    	Invoke MUISmartPanelRegisterPanel, hSP1, IDD_OptionsPanel0, Addr OptionsPanel0Proc
    	mov hOptionsPanel0, eax
    	Invoke MUISmartPanelRegisterPanel, hSP1, IDD_OptionsPanel1, Addr OptionsPanel1Proc
    	mov hOptionsPanel1, eax
    	Invoke MUISmartPanelRegisterPanel, hSP1, IDD_OptionsPanel2, Addr OptionsPanel2Proc
    	mov hOptionsPanel2, eax
    	Invoke MUISmartPanelRegisterPanel, hSP1, IDD_OptionsPanel3, Addr OptionsPanel3Proc
    	mov hOptionsPanel3, eax
    	Invoke MUISmartPanelSetCurrentPanel, hSP1, 0, FALSE
    	;Invoke SendMessage, hSP1, MUISPM_SETCURRENTPANEL, 0, FALSE    
        

        
	;---------------------------------------------------------------------------------------------------------------
	; Handle painting of our dialog with our specified background and border color to mimic new Modern style UI feel
	;---------------------------------------------------------------------------------------------------------------
    .ELSEIF eax == WM_ERASEBKGND
        mov eax, 1
        ret

	.ELSEIF eax == WM_PAINT
		invoke MUIPaintBackground, hWin, MUI_RGBCOLOR(240,240,240), MUI_RGBCOLOR(51,51,51) ;MUI_RGBCOLOR(27,161,226) 240,240,240
		mov eax, 0
		ret
    ;---------------------------------------------------------------------------------------------------------------


	.ELSEIF eax == WM_CLOSE
        Invoke EndDialog, hWin, NULL
        
	.ELSEIF eax == WM_COMMAND
        mov eax, wParam
        and eax, 0FFFFh
        .IF eax == IDC_OPTIONSMENUITEM0
	        Invoke MUIButtonSetState, hOptionsMenu0, TRUE
	        Invoke MUIButtonSetState, hOptionsMenu1, FALSE
	        Invoke MUIButtonSetState, hOptionsMenu2, FALSE
	        Invoke MUIButtonSetState, hOptionsMenu3, FALSE
	        Invoke MUISmartPanelSetCurrentPanel, hSP1, 0, TRUE
	        Invoke SetWindowText, hMenuText, Addr szOptionsMenu0Text
	        
	    .ELSEIF eax == IDC_OPTIONSMENUITEM1
	        Invoke MUIButtonSetState, hOptionsMenu0, FALSE
	        Invoke MUIButtonSetState, hOptionsMenu1, TRUE
	        Invoke MUIButtonSetState, hOptionsMenu2, FALSE
	        Invoke MUIButtonSetState, hOptionsMenu3, FALSE
	        Invoke MUISmartPanelSetCurrentPanel, hSP1, 1, TRUE
	        Invoke SetWindowText, hMenuText, Addr szOptionsMenu1Text
	    
	    .ELSEIF eax == IDC_OPTIONSMENUITEM2
	        Invoke MUIButtonSetState, hOptionsMenu0, FALSE
	        Invoke MUIButtonSetState, hOptionsMenu1, FALSE
	        Invoke MUIButtonSetState, hOptionsMenu2, TRUE
	        Invoke MUIButtonSetState, hOptionsMenu3, FALSE
	        Invoke MUISmartPanelSetCurrentPanel, hSP1, 2, TRUE
	        Invoke SetWindowText, hMenuText, Addr szOptionsMenu2Text
	        
	    .ELSEIF eax == IDC_OPTIONSMENUITEM3
	        Invoke MUIButtonSetState, hOptionsMenu0, FALSE
	        Invoke MUIButtonSetState, hOptionsMenu1, FALSE
	        Invoke MUIButtonSetState, hOptionsMenu2, FALSE
	        Invoke MUIButtonSetState, hOptionsMenu3, TRUE
	        Invoke MUISmartPanelSetCurrentPanel, hSP1, 3, TRUE
	        Invoke SetWindowText, hMenuText, Addr szOptionsMenu3Text

        .ELSEIF eax == IDC_OPTIONSMENUITEM4
            Invoke SendMessage, hWin, WM_CLOSE, NULL, NULL

        .ENDIF
    .ELSE
        mov eax, FALSE
        ret
	.ENDIF
    mov eax, TRUE
    ret
CodeShotOptionsDlgProc ENDP


;------------------------------------------------------------------------------
; OptionsPanel0Proc
;------------------------------------------------------------------------------
OptionsPanel0Proc PROC USES EBX hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	mov eax, uMsg
	.IF eax==WM_INITDIALOG
        IFDEF DEBUG32
        ;PrintText 'OptionsPanel1Proc:WM_INITDIALOG'
        ENDIF

        Invoke MUIButtonCreate, hWin, Addr szInfoImageFormat, 20, 11, 130, 24, IDC_INFOIMAGEFORMAT, MUIBS_LEFT
        mov hBtnInfoImageFormat, eax
        Invoke MUIButtonSetProperty, hBtnInfoImageFormat, @ButtonTextColor, MUI_RGBCOLOR(51,51,51)
        Invoke MUIButtonSetProperty, hBtnInfoImageFormat, @ButtonTextColorAlt, MUI_RGBCOLOR(51,51,51)
        Invoke MUIButtonSetProperty, hBtnInfoImageFormat, @ButtonBackColor, MUI_RGBCOLOR(240,240,240)
        Invoke MUIButtonSetProperty, hBtnInfoImageFormat, @ButtonBackColorAlt, MUI_RGBCOLOR(240,240,240)
        Invoke MUIButtonSetProperty, hBtnInfoImageFormat, @ButtonBorderStyle, MUIBBS_NONE
        
        Invoke MUICheckboxCreate, hWin, Addr szRadio1Text, 150, 11, 70, 24, IDC_RADIO1, MUICS_HAND
        mov hRadio1, eax
        Invoke MUICheckboxSetProperty, hRadio1, @CheckboxDllInstance, hInstance
        Invoke MUICheckboxLoadImages, hRadio1, MUICIT_ICO, ICO_MUI_NOSETRADIO, ICO_MUI_NOSETRADIO, ICO_MUI_RADIO, ICO_MUI_RADIO, ICO_MUI_RADIO, ICO_MUI_RADIO

        Invoke MUICheckboxCreate, hWin, Addr szRadio2Text, 220, 11, 70, 24, IDC_RADIO2, MUICS_HAND
        mov hRadio2, eax
        Invoke MUICheckboxSetProperty, hRadio2, @CheckboxDllInstance, hInstance
        Invoke MUICheckboxLoadImages, hRadio2, MUICIT_ICO, ICO_MUI_NOSETRADIO, ICO_MUI_NOSETRADIO, ICO_MUI_RADIO, ICO_MUI_RADIO, ICO_MUI_RADIO, ICO_MUI_RADIO

        Invoke MUICheckboxCreate, hWin, Addr szRadio3Text, 290, 11, 70, 24, IDC_RADIO3, MUICS_HAND
        mov hRadio3, eax
        Invoke MUICheckboxSetProperty, hRadio3, @CheckboxDllInstance, hInstance
        Invoke MUICheckboxLoadImages, hRadio3, MUICIT_ICO, ICO_MUI_NOSETRADIO, ICO_MUI_NOSETRADIO, ICO_MUI_RADIO, ICO_MUI_RADIO, ICO_MUI_RADIO, ICO_MUI_RADIO

        Invoke szCopy, Addr szJpegQuality, Addr szInfoJpegQuality
        Invoke utoa_ex, g_ImageCompression, Addr szImageCompressionValue
        Invoke szCatStr, Addr szInfoJpegQuality, Addr szImageCompressionValue

        Invoke MUIButtonCreate, hWin, Addr szInfoJpegQuality, 20, 48, 135, 24, IDC_INFOJPEGQUALITY, MUIBS_LEFT
        mov hBtnInfoJpegQuality, eax
        Invoke MUIButtonSetProperty, hBtnInfoJpegQuality, @ButtonTextColor, MUI_RGBCOLOR(51,51,51)
        Invoke MUIButtonSetProperty, hBtnInfoJpegQuality, @ButtonTextColorAlt, MUI_RGBCOLOR(51,51,51)
        Invoke MUIButtonSetProperty, hBtnInfoJpegQuality, @ButtonBackColor, MUI_RGBCOLOR(240,240,240)
        Invoke MUIButtonSetProperty, hBtnInfoJpegQuality, @ButtonBackColorAlt, MUI_RGBCOLOR(240,240,240)
        Invoke MUIButtonSetProperty, hBtnInfoJpegQuality, @ButtonBorderStyle, MUIBBS_NONE

        Invoke CreateWindowEx, NULL, Addr szTrackbarClass, NULL, WS_CHILD + WS_VISIBLE + TBS_HORZ + TBS_NOTICKS + TBS_FIXEDLENGTH + TBS_NOTIFYBEFOREMOVE, 152, 48, 210, 24, hWin, IDC_TRACKJPEGQUALITY, hInstance, NULL ;+TBS_TRANSPARENTBKGND +TBS_FIXEDLENGTH+ +TBS_TRANSPARENTBKGND TBS_AUTOTICKS+
        mov hTrackbarJpegQuality, eax
        Invoke SendMessage, hTrackbarJpegQuality, TBM_SETRANGEMIN, FALSE, 50
        Invoke SendMessage, hTrackbarJpegQuality, TBM_SETRANGEMAX, FALSE, 100
        Invoke SendMessage, hTrackbarJpegQuality, TBM_SETPOS, TRUE, g_ImageCompression

        mov eax, g_ImageType
        .IF eax == IMAGE_TYPE_BMP
            Invoke MUICheckboxSetState, hRadio1, TRUE
            Invoke MUICheckboxSetState, hRadio2, FALSE
            Invoke MUICheckboxSetState, hRadio3, FALSE
            Invoke EnableWindow, hTrackbarJpegQuality, FALSE
            
        .ELSEIF eax == IMAGE_TYPE_JPG
            Invoke MUICheckboxSetState, hRadio1, FALSE
            Invoke MUICheckboxSetState, hRadio2, TRUE
            Invoke MUICheckboxSetState, hRadio3, FALSE
            Invoke EnableWindow, hTrackbarJpegQuality, TRUE

        .ELSEIF eax == IMAGE_TYPE_PNG
            Invoke MUICheckboxSetState, hRadio1, FALSE
            Invoke MUICheckboxSetState, hRadio2, FALSE
            Invoke MUICheckboxSetState, hRadio3, TRUE
            Invoke InvalidateRect, hRadio3, NULL, TRUE
            Invoke EnableWindow, hTrackbarJpegQuality, FALSE
            
        .ENDIF


	.ELSEIF eax == WM_COMMAND
		mov	eax,wParam
		and	eax,0FFFFh
        .IF eax == IDC_RADIO1
            Invoke MUICheckboxSetState, hRadio1, TRUE
            Invoke MUICheckboxSetState, hRadio2, FALSE
            Invoke MUICheckboxSetState, hRadio3, FALSE
            mov eax, IMAGE_TYPE_BMP
            mov g_ImageType, eax
            Invoke IniSetDefaultImageType, IMAGE_TYPE_BMP
            Invoke EnableWindow, hTrackbarJpegQuality, FALSE
            
        .ELSEIF eax == IDC_RADIO2
            Invoke MUICheckboxSetState, hRadio1, FALSE
            Invoke MUICheckboxSetState, hRadio2, TRUE
            Invoke MUICheckboxSetState, hRadio3, FALSE
            mov eax, IMAGE_TYPE_JPG
            mov g_ImageType, eax
            Invoke IniSetDefaultImageType, IMAGE_TYPE_JPG
            Invoke EnableWindow, hTrackbarJpegQuality, TRUE
            
        .ELSEIF eax == IDC_RADIO3
            Invoke MUICheckboxSetState, hRadio1, FALSE
            Invoke MUICheckboxSetState, hRadio2, FALSE
            Invoke MUICheckboxSetState, hRadio3, TRUE
            mov eax, IMAGE_TYPE_PNG
            mov g_ImageType, eax
            Invoke IniSetDefaultImageType, IMAGE_TYPE_PNG
            Invoke EnableWindow, hTrackbarJpegQuality, FALSE
            
        .ENDIF
        
        Invoke CS_GenExampleFilename, g_ImageType
        Invoke SetWindowText, hBtnFileGen, Addr CODESHOT_EXAMPLEFILE        

   .ELSEIF eax == WM_NOTIFY
		mov ebx, lParam				; lParam is a pointer to a NMHDR Struct
		mov eax, (NMHDR PTR [ebx]).code
		mov ebx, (NMHDR PTR [ebx]).hwndFrom
		.IF ebx == hTrackbarJpegQuality
		    .IF eax == TRBN_THUMBPOSCHANGING
	            mov ebx, lParam
	            mov eax, (NMTRBTHUMBPOSCHANGING ptr [ebx]).dwPos
	            mov g_ImageCompression, eax
                    
                Invoke szCopy, Addr szJpegQuality, Addr szInfoJpegQuality
                Invoke utoa_ex, g_ImageCompression, Addr szImageCompressionValue
                Invoke szCatStr, Addr szInfoJpegQuality, Addr szImageCompressionValue
	            Invoke SetWindowText, hBtnInfoJpegQuality, Addr szInfoJpegQuality
	            Invoke IniSetImageCompression, g_ImageCompression
            .ENDIF
        .ENDIF

    .ELSEIF eax == WM_ERASEBKGND
        mov eax, 1
        ret

	.ELSEIF eax == WM_PAINT
		invoke MUIPaintBackground, hWin, MUI_RGBCOLOR(240,240,240), 0
		
	.ELSEIF eax==WM_CLOSE
	    invoke DestroyWindow, hWin
	.ELSE
      	mov eax,FALSE
		ret
	.ENDIF
	mov  eax,TRUE
	ret

OptionsPanel0Proc ENDP



;------------------------------------------------------------------------------
; OptionsPanel1Proc
;------------------------------------------------------------------------------
OptionsPanel1Proc PROC hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	mov eax, uMsg
	.IF eax==WM_INITDIALOG
        Invoke MUICheckboxCreate, hWin, Addr szCheckbox1Text, 20, 11, 350, 24, IDC_CHECKBOX1, MUICS_HAND
        mov hChk1, eax
        Invoke MUICheckboxSetProperty, hChk1, @CheckboxDllInstance, hInstance
        Invoke MUICheckboxLoadImages, hChk1, MUICIT_ICO, ICO_MUI_NOCHECKMARK, ICO_MUI_NOCHECKMARK, ICO_MUI_CHECKMARK, ICO_MUI_CHECKMARK, ICO_MUI_NOCHECKMARK, ICO_MUI_NOCHECKMARK

;        Invoke MUICheckboxCreate, hWin, Addr szCheckbox2Text, 20, 48, 350, 24, IDC_CHECKBOX2, MUICS_HAND
;        mov hChk2, eax
;        Invoke MUICheckboxSetProperty, hChk2, @CheckboxDllInstance, hInstance
;        Invoke MUICheckboxLoadImages, hChk2, MUICIT_ICO, ICO_MUI_NOCHECKMARK, ICO_MUI_NOCHECKMARK, ICO_MUI_CHECKMARK, ICO_MUI_CHECKMARK, ICO_MUI_NOCHECKMARK, ICO_MUI_NOCHECKMARK

        .IF g_ExcludeStatusBar == 1
            Invoke MUICheckboxSetState, hChk1, TRUE
        .ENDIF
        .IF g_ExcludeCommandBar == 1
            Invoke MUICheckboxSetState, hChk2, TRUE
        .ENDIF

	.ELSEIF eax == WM_COMMAND
		mov	eax,wParam
		and	eax,0FFFFh
        .IF eax == IDC_CHECKBOX1
            Invoke MUICheckboxGetState, hChk1
            .IF eax == TRUE
                mov g_ExcludeStatusBar, 1
                Invoke IniSetExcludeStatusBar, 1
            .ELSE
                mov g_ExcludeStatusBar, 0
                Invoke IniSetExcludeStatusBar, 0
            .ENDIF

;        .ELSEIF eax == IDC_CHECKBOX2
;            Invoke MUICheckboxGetState, hChk2
;            .IF eax == TRUE
;                mov g_ExcludeCommandBar, 1
;                Invoke IniSetExcludeCommandBar, 1
;            .ELSE
;                mov g_ExcludeCommandBar, 0
;                Invoke IniSetExcludeCommandBar, 0
;            .ENDIF

        .ELSEIF eax == IDC_CHECKBOX3
            
        .ENDIF

    .ELSEIF eax == WM_ERASEBKGND
        mov eax, 1
        ret

	.ELSEIF eax == WM_PAINT
		invoke MUIPaintBackground, hWin, MUI_RGBCOLOR(240,240,240), 0
		
	.ELSEIF eax==WM_CLOSE
	    invoke DestroyWindow, hWin
	.ELSE
      	mov eax,FALSE
		ret
	.ENDIF
	mov  eax,TRUE
	ret

OptionsPanel1Proc ENDP


;------------------------------------------------------------------------------
; OptionsPanel2Proc
;------------------------------------------------------------------------------
OptionsPanel2Proc PROC hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	mov eax, uMsg
	.IF eax==WM_INITDIALOG

        Invoke MUICheckboxCreate, hWin, Addr szCheckbox4Text, 20, 11, 350, 24, IDC_CHECKBOX4, MUICS_HAND
        mov hChk4, eax
        Invoke MUICheckboxSetProperty, hChk4, @CheckboxDllInstance, hInstance
        Invoke MUICheckboxLoadImages, hChk4, MUICIT_ICO, ICO_MUI_NOCHECKMARK, ICO_MUI_NOCHECKMARK, ICO_MUI_CHECKMARK, ICO_MUI_CHECKMARK, ICO_MUI_NOCHECKMARK, ICO_MUI_NOCHECKMARK

        Invoke MUICheckboxCreate, hWin, Addr szCheckbox5Text, 20, 48, 350, 24, IDC_CHECKBOX5, MUICS_HAND
        mov hChk5, eax
        Invoke MUICheckboxSetProperty, hChk5, @CheckboxDllInstance, hInstance
        Invoke MUICheckboxLoadImages, hChk5, MUICIT_ICO, ICO_MUI_NOCHECKMARK, ICO_MUI_NOCHECKMARK, ICO_MUI_CHECKMARK, ICO_MUI_CHECKMARK, ICO_MUI_NOCHECKMARK, ICO_MUI_NOCHECKMARK

        Invoke MUICheckboxCreate, hWin, Addr szCheckbox6Text, 20, 85, 350, 24, IDC_CHECKBOX6, MUICS_HAND
        mov hChk6, eax
        Invoke MUICheckboxSetProperty, hChk6, @CheckboxDllInstance, hInstance
        Invoke MUICheckboxLoadImages, hChk6, MUICIT_ICO, ICO_MUI_NOCHECKMARK, ICO_MUI_NOCHECKMARK, ICO_MUI_CHECKMARK, ICO_MUI_CHECKMARK, ICO_MUI_NOCHECKMARK, ICO_MUI_NOCHECKMARK

        .IF g_SeperateFolderForModules == 1
            Invoke MUICheckboxSetState, hChk4, TRUE
        .ENDIF
        .IF g_ImageFileIncludeAddress == 1
            Invoke MUICheckboxSetState, hChk5, TRUE
        .ENDIF
        .IF g_ImageFileIncludeDatetime == 1
            Invoke MUICheckboxSetState, hChk6, TRUE
        .ENDIF
        
        .IF hFontCourierNew == 0
            invoke CreateFont, -10d, 0, 0, 0, FW_NORMAL, 0, 0, 0, 0, 0, 0, 0, 0, Addr szCourierNewFont
            mov hFontCourierNew, eax
        .ENDIF
        
        Invoke MUIButtonCreate, hWin, Addr szNull, 28, 159, 332, 48, IDC_BTNFILEGEN, MUIBS_LEFT
        mov hBtnFileGen, eax
        Invoke MUIButtonSetProperty, hBtnFileGen, @ButtonTextFont, hFontCourierNew
        Invoke MUIButtonSetProperty, hBtnFileGen, @ButtonTextColor, MUI_RGBCOLOR(51,51,51)
        Invoke MUIButtonSetProperty, hBtnFileGen, @ButtonTextColorAlt, MUI_RGBCOLOR(51,51,51)
        Invoke MUIButtonSetProperty, hBtnFileGen, @ButtonBackColor, MUI_RGBCOLOR(240,240,240)
        Invoke MUIButtonSetProperty, hBtnFileGen, @ButtonBackColorAlt, MUI_RGBCOLOR(240,240,240)
        Invoke MUIButtonSetProperty, hBtnFileGen, @ButtonBorderStyle, MUIBBS_ALL
        Invoke MUIButtonSetProperty, hBtnFileGen, @ButtonBorderColor, MUI_RGBCOLOR(41,122,185)
        Invoke MUIButtonSetProperty, hBtnFileGen, @ButtonBorderColorAlt, MUI_RGBCOLOR(41,122,185)

        Invoke CS_GenExampleFilename, g_ImageType
        Invoke SetWindowText, hBtnFileGen, Addr CODESHOT_EXAMPLEFILE

	.ELSEIF eax == WM_COMMAND
		mov	eax,wParam
		and	eax,0FFFFh
        .IF eax == IDC_CHECKBOX4
            Invoke MUICheckboxGetState, hChk4
            .IF eax == TRUE
                mov g_SeperateFolderForModules, 1
                Invoke IniSetSeperateFolderForModules, 1
            .ELSE
                mov g_SeperateFolderForModules, 0
                Invoke IniSetSeperateFolderForModules, 0
            .ENDIF
            Invoke CS_GenExampleFilename, g_ImageType
            Invoke SetWindowText, hBtnFileGen, Addr CODESHOT_EXAMPLEFILE            

        .ELSEIF eax == IDC_CHECKBOX5
            Invoke MUICheckboxGetState, hChk5
            .IF eax == TRUE
                mov g_ImageFileIncludeAddress, 1
                Invoke IniSetImageFileIncludeAddress, 1
            .ELSE
                mov g_ImageFileIncludeAddress, 0
                Invoke IniSetImageFileIncludeAddress, 0
            .ENDIF
            Invoke CS_GenExampleFilename, g_ImageType
            Invoke SetWindowText, hBtnFileGen, Addr CODESHOT_EXAMPLEFILE              

        .ELSEIF eax == IDC_CHECKBOX6
            Invoke MUICheckboxGetState, hChk6
            .IF eax == TRUE
                mov g_ImageFileIncludeDatetime, 1
                Invoke IniSetImageFileIncludeDatetime, 1
            .ELSE
                mov g_ImageFileIncludeDatetime, 0
                Invoke IniSetImageFileIncludeDatetime, 0
            .ENDIF
            Invoke CS_GenExampleFilename, g_ImageType
            Invoke SetWindowText, hBtnFileGen, Addr CODESHOT_EXAMPLEFILE  

        .ENDIF
        
    .ELSEIF eax == WM_ERASEBKGND
        mov eax, 1
        ret

	.ELSEIF eax == WM_PAINT
		invoke MUIPaintBackground, hWin, MUI_RGBCOLOR(240,240,240), 0
		
	.ELSEIF eax==WM_CLOSE
	    invoke DestroyWindow, hWin
	.ELSE
      	mov eax,FALSE
		ret
	.ENDIF
	mov  eax,TRUE
	ret

OptionsPanel2Proc ENDP


;------------------------------------------------------------------------------
; OptionsPanel3Proc
;------------------------------------------------------------------------------
OptionsPanel3Proc PROC hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	mov eax, uMsg
	.IF eax==WM_INITDIALOG
        Invoke MUICheckboxCreate, hWin, Addr szCheckbox7Text, 20, 11, 350, 24, IDC_CHECKBOX7, MUICS_HAND
        mov hChk7, eax
        Invoke MUICheckboxSetProperty, hChk7, @CheckboxDllInstance, hInstance
        Invoke MUICheckboxLoadImages, hChk7, MUICIT_ICO, ICO_MUI_NOCHECKMARK, ICO_MUI_NOCHECKMARK, ICO_MUI_CHECKMARK, ICO_MUI_CHECKMARK, ICO_MUI_NOCHECKMARK, ICO_MUI_NOCHECKMARK

        Invoke MUICheckboxCreate, hWin, Addr szCheckbox8Text, 20, 48, 350, 24, IDC_CHECKBOX8, MUICS_HAND
        mov hChk8, eax
        Invoke MUICheckboxSetProperty, hChk8, @CheckboxDllInstance, hInstance
        Invoke MUICheckboxLoadImages, hChk8, MUICIT_ICO, ICO_MUI_NOCHECKMARK, ICO_MUI_NOCHECKMARK, ICO_MUI_CHECKMARK, ICO_MUI_CHECKMARK, ICO_MUI_NOCHECKMARK, ICO_MUI_NOCHECKMARK
        
        .IF g_CameraShutterClick == 1
            Invoke MUICheckboxSetState, hChk7, TRUE
        .ENDIF
        
        .IF g_ShowToolbarButton == 1
            Invoke MUICheckboxSetState, hChk8, TRUE
        .ENDIF
        
	.ELSEIF eax == WM_COMMAND
		mov	eax,wParam
		and	eax,0FFFFh
        .IF eax == IDC_CHECKBOX7
            Invoke MUICheckboxGetState, hChk7
            .IF eax == TRUE
                mov g_CameraShutterClick, 1
                Invoke IniSetCameraShutterClick, 1
            .ELSE
                mov g_CameraShutterClick, 0
                Invoke IniSetCameraShutterClick, 0
            .ENDIF

        .ELSEIF eax == IDC_CHECKBOX8
            Invoke MUICheckboxGetState, hChk8
            .IF eax == TRUE
                mov g_ShowToolbarButton, 1
                Invoke IniSetShowToolbarButton, 1
                .IF hCodeShotToolbar != NULL
                    Invoke ShowWindow, hCodeShotToolbar, SW_SHOW
                .ENDIF
            .ELSE
                mov g_ShowToolbarButton, 0
                Invoke IniSetShowToolbarButton, 0
                .IF hCodeShotToolbar != NULL
                    Invoke ShowWindow, hCodeShotToolbar, SW_HIDE
                .ENDIF
            .ENDIF

        .ELSEIF eax == IDC_CHECKBOX9

        .ENDIF

    .ELSEIF eax == WM_ERASEBKGND
        mov eax, 1
        ret

	.ELSEIF eax == WM_PAINT
		invoke MUIPaintBackground, hWin, MUI_RGBCOLOR(240,240,240), 0
		
	.ELSEIF eax==WM_CLOSE
	    invoke DestroyWindow, hWin
	.ELSE
      	mov eax,FALSE
		ret
	.ENDIF
	mov  eax,TRUE
	ret

OptionsPanel3Proc ENDP



;-------------------------------------------------------------------------------------
; Takes screenshot of currently debugged code and saves it to codeshot folder with 
; a filename based on module and date/time now
;-------------------------------------------------------------------------------------
CS_TakeCodeShot PROC dwCodeShotImageType:DWORD
    LOCAL hBitmap:DWORD
    ;LOCAL dwColWidths:DWORD
    LOCAL dwImageType:DWORD
    
    Invoke DbgIsDebugging
    .IF eax == FALSE
        Invoke GuiAddLogMessage, Addr szDebuggingRequired
        mov eax, FALSE
        ret
    .ENDIF
    
    .IF hMainScreen == 0
        Invoke GuiAddLogMessage, Addr szFailedToGetMainScreen
        mov eax, FALSE
        ret
    .ENDIF
    
    .IF dwCodeShotImageType == NULL
        mov eax, g_ImageType
    .ELSE
        mov eax, dwCodeShotImageType
    .ENDIF
    mov dwImageType, eax
    
    Invoke CS_GenerateFilename, dwImageType ;dwCodeShotImageType
    
    ;Invoke CS_GetX64dbgCPUColumnWidths
    ;mov dwColWidths, eax
    ;PrintDec dwColWidths
    
    ;Invoke CS_CaptureScreenToBitmap, hMainScreen, dwColWidths
    Invoke CS_CaptureScreenToBitmapV2, hMainScreen
    mov hBitmap, eax
    
    .IF hBitmap == 0
        Invoke GuiAddLogMessage, Addr szFailedToCaptureScreen
        mov eax, FALSE
        ret        
    .ENDIF
    
    Invoke SaveBitmapToFile, dwImageType, hBitmap, 0, Addr CODESHOT_OUTPUTFILE ;dwCodeShotImageType
    Invoke DeleteObject, hBitmap
    
    .IF g_CameraShutterClick == TRUE
        Invoke PlaySound, IDS_CODESHOT_SHUTTER, hInstance, SND_RESOURCE
    .ENDIF
    
    Invoke szCopy, Addr szCodeShotCapturedMsg, Addr szCodeShotMsg
    Invoke szCatStr, Addr szCodeShotMsg, Addr CODESHOT_OUTPUTFILE
    Invoke szCatStr, Addr szCodeShotMsg, Addr szCRLF
    Invoke GuiAddStatusBarMessage, Addr szCodeShotMsg
    ;Invoke GuiAddLogMessage, Addr szCodeShotMsg
    
    mov eax, TRUE
    ret

CS_TakeCodeShot ENDP


;-------------------------------------------------------------------------------------
; CS_CaptureScreenToBitmap Captures main x64dbg screen window to a bitmap 
; (bitmap must be deleted after use)
;-------------------------------------------------------------------------------------
CS_CaptureScreenToBitmap PROC USES EBX ECX EDX hScreenWindow:DWORD, dwColWidths:DWORD
    LOCAL hDC:DWORD
    LOCAL hDCMem:DWORD
    LOCAL hBitmap:DWORD
    LOCAL hOldBitmap:DWORD
    LOCAL rect:RECT
    LOCAL dwHeight:DWORD
    LOCAL dwDumpHeight:DWORD
    
    mov hBitmap, 0
    mov hOldBitmap, 0
    
    Invoke GetClientRect, hScreenWindow, Addr rect
    
    Invoke GetDC, hScreenWindow
    mov hDC, eax
    
    Invoke CreateCompatibleDC, hDC
    mov hDCMem, eax
    
    
    ;PrintDec rect.right
    ;PrintDec dwColWidths
    
    mov eax, rect.right
    mov ebx, dwColWidths
    .IF ebx < eax
        mov eax, dwColWidths
        mov rect.right, eax 
    .ENDIF
    
    mov eax, rect.bottom
    mov dwHeight, eax
    
    finit
    fild dwHeight
    fild dw100
    fdiv
    fld st
    fild dw28
    fmul
    fistp dwDumpHeight
    mov eax, dwDumpHeight
    .IF sdword ptr eax < 101
        mov dwDumpHeight, 101
    .ENDIF
    add dwDumpHeight, 126d
    ;PrintDec dwDumpHeight
    
    mov eax, rect.bottom
    sub eax, dwDumpHeight
    ;PrintDec eax
    	;fild ulProgressMax
    	;fdiv
        ;fld st
        ;fild dw100
        ;fmul
        ;fistp dwPercent
    
    ;sub eax, ebx
    ;PrintDec eax
    ;mov ebx, eax
    ;mov eax, rect.right
    ;sub eax, ebx
    ;mov rect.right, eax
    ;PrintDec rect.right
    
    
    ;sub eax, CODESHOT_RIGHT_ADJUST
    ;add eax, CODESHOT_LEFT_ADJUST
    ;mov rect.right, eax
    
    
    
    mov eax, rect.bottom
    sub eax, dwDumpHeight ;CODESHOT_BOTTOM_ADJUST
    add eax, CODESHOT_TOP_ADJUST
    mov rect.bottom, eax
    
    Invoke CreateCompatibleBitmap, hDC, rect.right, rect.bottom
    mov hBitmap, eax
    
    Invoke SelectObject, hDCMem, hBitmap
    mov hOldBitmap, eax
    
    ;Invoke GetPixel, hDCMem, 0, 15
    ;.IF eax != CLR_INVALID
    ;    ;PrintDec eax
    ;.ENDIF
    
    
    Invoke BitBlt, hDCMem, 0, 0, rect.right, rect.bottom, hDC, CODESHOT_LEFT_ADJUST, CODESHOT_TOP_ADJUST, SRCCOPY
    
    ;Invoke BitBlt, hDCMem, 0,0, rect.right, rect.bottom, hDC, 0, 0, SRCCOPY
    
    Invoke SelectObject, hDCMem, hOldBitmap
    
    Invoke DeleteDC, hDCMem
    Invoke ReleaseDC, hScreenWindow, hDC
    
    mov eax, hBitmap
    
    ret

CS_CaptureScreenToBitmap ENDP



;-------------------------------------------------------------------------------------
; CS_CaptureScreenToBitmap Captures main x64dbg screen window to a bitmap 
; (bitmap must be deleted after use)
;-------------------------------------------------------------------------------------
CS_CaptureScreenToBitmapV2 PROC USES EBX ECX EDX hScreenWindow:DWORD
    LOCAL hDC:DWORD
    LOCAL hDCMem:DWORD
    LOCAL hBitmap:DWORD
    LOCAL hOldBitmap:DWORD
    LOCAL rect:RECT
    LOCAL dwHeight:DWORD
    LOCAL dwDumpHeight:DWORD
    LOCAL dwAdjustTop:DWORD
    LOCAL dwAdjustBottom:DWORD
    
    mov hBitmap, 0
    mov hOldBitmap, 0
    
    Invoke GetClientRect, hScreenWindow, Addr rect
    
    Invoke GetDC, hScreenWindow
    mov hDC, eax
    
    Invoke CreateCompatibleDC, hDC
    mov hDCMem, eax
    
    mov dwAdjustTop, 0
    mov dwAdjustBottom, 0
    
    .IF g_ExcludeTabbar == 1
        mov dwAdjustTop, 28d
    .ENDIF
    
    .IF g_ExcludeStatusBar == 1
        add dwAdjustBottom, 52d ; 12d ; 22d
    .ENDIF
    
    ;.IF g_ExcludeCommandBar == 1
    ;    add dwAdjustBottom, 22d
    ;.ENDIF
    
    mov eax, rect.right
    sub eax, 28d ; width of scrollbars etc
    mov rect.right, eax
    
   ;PrintDec dwAdjustBottom
    ;PrintDec dwAdjustTop
   ; PrintDec rect.bottom
    
    mov eax, rect.bottom
   ; sub eax, dwAdjustBottom
    add eax, dwAdjustTop
    sub eax, 10d
    sub eax, dwAdjustBottom
    mov rect.bottom, eax
    
   ; PrintDec rect.bottom
    
    
    Invoke CreateCompatibleBitmap, hDC, rect.right, rect.bottom
    mov hBitmap, eax
    
    Invoke SelectObject, hDCMem, hBitmap
    mov hOldBitmap, eax
    
    Invoke BitBlt, hDCMem, 0, 0, rect.right, rect.bottom, hDC, CODESHOT_LEFT_ADJUST, dwAdjustTop, SRCCOPY
    
    ;Invoke BitBlt, hDCMem, 0,0, rect.right, rect.bottom, hDC, 0, 0, SRCCOPY
    
    Invoke SelectObject, hDCMem, hOldBitmap
    
    Invoke DeleteDC, hDCMem
    Invoke ReleaseDC, hScreenWindow, hDC
    
    mov eax, hBitmap
    
    ret

CS_CaptureScreenToBitmapV2 ENDP



;-------------------------------------------------------------------------------------
; Generates output filename for the screenshot image we are going to save
;-------------------------------------------------------------------------------------
CS_GenerateFilename PROC dwCodeShotImageType:DWORD
    LOCAL sel:SELECTIONDATA
    LOCAL szCurrentAddressValue[12]:BYTE
    LOCAL szAddressValue[32]:BYTE
    LOCAL szBuffer[32]:BYTE
    LOCAL dwFileCounter:DWORD
    LOCAL szFileCounter[16]:BYTE
    LOCAL bFilenameGoodToGo:DWORD
    
    Invoke szCopy, Addr CODESHOTS_FOLDER, Addr CODESHOT_OUTPUTFILE

    Invoke GuiSelectionGet, GUI_DISASSEMBLY, Addr sel
    
    Invoke ModNameFromAddr, sel.start, Addr szModuleName, FALSE
    ;_DbgFunctions ModNameFromAddr, sel.start, ADDR szModuleName, FALSE
    
    .IF g_SeperateFolderForModules == TRUE
        Invoke JustFnameExt, Addr szModuleName, Addr MODULENAMEFOLDER
        Invoke szCatStr, Addr CODESHOT_OUTPUTFILE, Addr MODULENAMEFOLDER
        Invoke szCatStr, Addr CODESHOT_OUTPUTFILE, Addr szBackSlash
        ;PrintString CODESHOT_OUTPUTFILE
        Invoke CreateDirectoryPath, Addr CODESHOT_OUTPUTFILE
    .ENDIF
    Invoke szCatStr, Addr CODESHOT_OUTPUTFILE, Addr szModuleName

    .IF g_ImageFileIncludeAddress == TRUE
        Invoke szCatStr, Addr CODESHOT_OUTPUTFILE, Addr szDash
        Invoke szCatStr, Addr CODESHOT_OUTPUTFILE, Addr szLeftSquareBracket
        Invoke dw2hex, sel.start, Addr szCurrentAddressValue ; pure hex string address
        Invoke szCopy, Addr sz8zeros, Addr szAddressValue ; 8 zeros to buffer
        Invoke szCopy, Addr szHexPrefix, Addr ADDRESSVALUE
        Invoke szCatStr, Addr szAddressValue, Addr szCurrentAddressValue
        Invoke szRight, Addr szAddressValue, Addr szBuffer, 8d
        Invoke szCatStr, Addr ADDRESSVALUE, Addr szBuffer
        Invoke szCatStr, Addr CODESHOT_OUTPUTFILE, Addr ADDRESSVALUE
        Invoke szCatStr, Addr CODESHOT_OUTPUTFILE, Addr szRightSquareBracket
    .ENDIF    
    
    Invoke szCatStr, Addr CODESHOT_OUTPUTFILE, Addr szUnderscore
    .IF g_ImageFileIncludeDatetime == TRUE
        Invoke DTGetDateTime, Addr szDateTimeNow, CCYYMMDDHHMMSSMS
        Invoke _StripDateTimeString, Addr szDateTimeNow, Addr CODESHOT_DATETIME
        Invoke szCatStr, Addr CODESHOT_OUTPUTFILE, Addr CODESHOT_DATETIME
    .ELSE

        mov dwFileCounter, 1
        Invoke RtlZeroMemory, Addr szFileCounter, SIZEOF szFileCounter
        mov bFilenameGoodToGo, FALSE
        
        .WHILE bFilenameGoodToGo != TRUE
            Invoke szCopy, Addr CODESHOT_OUTPUTFILE, Addr CODESHOT_TESTFILE
            Invoke utoa_ex, dwFileCounter, Addr szFileCounter
            Invoke szCatStr, Addr CODESHOT_TESTFILE, Addr szFileCounter
            
            mov eax, dwCodeShotImageType
            .IF eax == IMAGE_TYPE_JPG
                Invoke szCatStr, Addr CODESHOT_TESTFILE, Addr szJpgExt
            .ELSEIF eax == IMAGE_TYPE_BMP
                Invoke szCatStr, Addr CODESHOT_TESTFILE, Addr szBmpExt
            .ELSEIF eax == IMAGE_TYPE_GIF
                Invoke szCatStr, Addr CODESHOT_TESTFILE, Addr szGifExt
            .ELSEIF eax == IMAGE_TYPE_PNG
                Invoke szCatStr, Addr CODESHOT_TESTFILE, Addr szPngExt
            .ENDIF            
            
            Invoke GetFileAttributes, Addr CODESHOT_TESTFILE
            .IF eax ==  0FFFFFFFFh ; not found
                .IF eax != FILE_ATTRIBUTE_DIRECTORY
                    mov bFilenameGoodToGo, TRUE
                    .BREAK
                .ENDIF
            .ENDIF
            
            inc dwFileCounter
            
        .ENDW
        
        Invoke szCatStr, Addr CODESHOT_OUTPUTFILE, Addr szFileCounter
        
    .ENDIF
    
    mov eax, dwCodeShotImageType
    .IF eax == IMAGE_TYPE_JPG
        Invoke szCatStr, Addr CODESHOT_OUTPUTFILE, Addr szJpgExt
    .ELSEIF eax == IMAGE_TYPE_BMP
        Invoke szCatStr, Addr CODESHOT_OUTPUTFILE, Addr szBmpExt
    .ELSEIF eax == IMAGE_TYPE_GIF
        Invoke szCatStr, Addr CODESHOT_OUTPUTFILE, Addr szGifExt
    .ELSEIF eax == IMAGE_TYPE_PNG
        Invoke szCatStr, Addr CODESHOT_OUTPUTFILE, Addr szPngExt
    .ENDIF
    
    ;PrintString CODESHOT_OUTPUTFILE
    
    
    ret

CS_GenerateFilename ENDP

;-------------------------------------------------------------------------------------
; Generates an example output filename for the screenshot image
;-------------------------------------------------------------------------------------
CS_GenExampleFilename PROC dwCodeShotImageType:DWORD
    LOCAL szCurrentAddressValue[12]:BYTE
    LOCAL szAddressValue[32]:BYTE
    LOCAL szBuffer[32]:BYTE
    LOCAL dwExampleStart:DWORD
    
    mov dwExampleStart, 01234567h
    Invoke szCopy, Addr szNull, Addr CODESHOT_EXAMPLEFILE

    .IF g_SeperateFolderForModules == TRUE
        Invoke JustFnameExt, Addr szExample, Addr MODULENAMEFOLDER
        Invoke szCatStr, Addr CODESHOT_EXAMPLEFILE, Addr MODULENAMEFOLDER
        Invoke szCatStr, Addr CODESHOT_EXAMPLEFILE, Addr szBackSlash
        ;PrintString CODESHOT_EXAMPLEFILE
        ;Invoke CreateDirectoryPath, Addr CODESHOT_EXAMPLEFILE
    .ENDIF
    Invoke szCatStr, Addr CODESHOT_EXAMPLEFILE, Addr szExample

    .IF g_ImageFileIncludeAddress == TRUE
        Invoke szCatStr, Addr CODESHOT_EXAMPLEFILE, Addr szDash
        Invoke szCatStr, Addr CODESHOT_EXAMPLEFILE, Addr szLeftSquareBracket
        Invoke dw2hex, dwExampleStart, Addr szCurrentAddressValue ; pure hex string address
        Invoke szCopy, Addr sz8zeros, Addr szAddressValue ; 8 zeros to buffer
        Invoke szCopy, Addr szHexPrefix, Addr ADDRESSVALUE
        Invoke szCatStr, Addr szAddressValue, Addr szCurrentAddressValue
        Invoke szRight, Addr szAddressValue, Addr szBuffer, 8d
        Invoke szCatStr, Addr ADDRESSVALUE, Addr szBuffer
        Invoke szCatStr, Addr CODESHOT_EXAMPLEFILE, Addr ADDRESSVALUE
        Invoke szCatStr, Addr CODESHOT_EXAMPLEFILE, Addr szRightSquareBracket
    .ENDIF    
    
    Invoke szCatStr, Addr CODESHOT_EXAMPLEFILE, Addr szUnderscore
    .IF g_ImageFileIncludeDatetime == TRUE
        Invoke DTGetDateTime, Addr szDateTimeNow, CCYYMMDDHHMMSSMS
        Invoke _StripDateTimeString, Addr szDateTimeNow, Addr CODESHOT_DATETIME
        Invoke szCatStr, Addr CODESHOT_EXAMPLEFILE, Addr CODESHOT_DATETIME
    .ELSE
        Invoke szCatStr, Addr CODESHOT_EXAMPLEFILE, Addr szOne
    .ENDIF
    
    mov eax, dwCodeShotImageType
    .IF eax == IMAGE_TYPE_JPG
        Invoke szCatStr, Addr CODESHOT_EXAMPLEFILE, Addr szJpgExt
    .ELSEIF eax == IMAGE_TYPE_BMP
        Invoke szCatStr, Addr CODESHOT_EXAMPLEFILE, Addr szBmpExt
    .ELSEIF eax == IMAGE_TYPE_GIF
        Invoke szCatStr, Addr CODESHOT_EXAMPLEFILE, Addr szGifExt
    .ELSEIF eax == IMAGE_TYPE_PNG
        Invoke szCatStr, Addr CODESHOT_EXAMPLEFILE, Addr szPngExt
    .ENDIF
    
    ;PrintString CODESHOT_OUTPUTFILE
    
    ret

CS_GenExampleFilename ENDP



;-------------------------------------------------------------------------------------
; Used to calc width of columns from x64dbg.ini file to guess width of codeshot to take
;-------------------------------------------------------------------------------------
CS_GetX64dbgCPUColumnWidths PROC
    LOCAL dwCol0:DWORD
    LOCAL dwCol1:DWORD
    LOCAL dwCol2:DWORD
    LOCAL dwCol3:DWORD
    LOCAL szCol0[8]:BYTE
    LOCAL szCol1[8]:BYTE
    LOCAL szCol2[8]:BYTE
    LOCAL szCol3[8]:BYTE

    Invoke GetPrivateProfileString, Addr szx64dbgGui, Addr szx64dbgCol0, Addr szZero, Addr szCol0, 8, Addr X64DBGINIFILE
    Invoke GetPrivateProfileString, Addr szx64dbgGui, Addr szx64dbgCol1, Addr szZero, Addr szCol1, 8, Addr X64DBGINIFILE
    Invoke GetPrivateProfileString, Addr szx64dbgGui, Addr szx64dbgCol2, Addr szZero, Addr szCol2, 8, Addr X64DBGINIFILE
    Invoke GetPrivateProfileString, Addr szx64dbgGui, Addr szx64dbgCol3, Addr szZero, Addr szCol3, 8, Addr X64DBGINIFILE
    
    Invoke htodw, Addr szCol0
    mov dwCol0, eax
    Invoke htodw, Addr szCol1
    mov dwCol1, eax
    Invoke htodw, Addr szCol2
    mov dwCol2, eax
    Invoke htodw, Addr szCol3
    mov dwCol3, eax
    
    ;PrintDec dwCol0
    ;PrintDec dwCol1
    ;PrintDec dwCol2
    ;PrintDec dwCol3
    
    
    .IF dwCol0 == 0
        mov eax, 64d
        mov dwCol0, eax
    .ENDIF
    .IF dwCol1 == 0
        mov eax, 176d
        mov dwCol1, eax
    .ENDIF
    .IF dwCol2 == 0
        mov eax, 280d
        mov dwCol2, eax
    .ENDIF
    .IF dwCol3 == 0
        mov eax, 1000d
        mov dwCol3, eax
    .ENDIF    
    
    mov eax, 180d ; default size to first column
    add eax, dwCol0
    add eax, dwCol1
    add eax, dwCol2
    add eax, 333d
    sub eax, CODESHOT_LEFT_ADJUST
    
    ret

CS_GetX64dbgCPUColumnWidths ENDP


;-------------------------------------------------------------------------------------
; Used to get back color from x64dbg.ini file to see which pixels arent this color
;-------------------------------------------------------------------------------------
CS_GetX64dbgCPUBackcolor PROC
    LOCAL dwColor:DWORD
    LOCAL szColor[8]:BYTE
    
    Invoke GetPrivateProfileString, Addr szx64dbgColors, Addr szx64dbgBackcolor, Addr szZero, Addr szColor, 8, Addr X64DBGINIFILE
    
    Invoke szRemove, Addr szColor, Addr szColor, Addr szHash
    
    Invoke htodw, Addr szColor
    mov dwColor, eax
    
    ;PrintDec dwColor
    
    ret

CS_GetX64dbgCPUBackcolor ENDP


;-----------------------------------------------------------------------------------------
; Save bitmap image handle to file using gdi plus to convert bitmap to desired format
;-----------------------------------------------------------------------------------------
SaveBitmapToFile PROC USES EBX ECX dwImageType:DWORD, hBitmap:DWORD, dwJpegQuality:DWORD, lpszFilename:DWORD
    LOCAL pBitmapImage:DWORD
    LOCAL szWFilename[MAX_PATH*2]:BYTE
    
    Invoke MultiByteToWideChar, 0, 0, lpszFilename, 0ffffffffh, Addr szWFilename, MAX_PATH*2 ; convert filename to wide
    Invoke GdipCreateBitmapFromHBITMAP, hBitmap, 0, Addr pBitmapImage ; convert HBITMAP to gdi bitmap image
    
    Invoke RtlZeroMemory, Addr eps, SIZEOF EncoderParameters
    
    
    lea ebx, eps
    mov EncoderParameters.Count[ebx], 1
    lea ecx, [ebx + EncoderParameters.Parameter.pGUID]
    
    Invoke RtlMoveMemory, ecx, Addr _EncoderQuality, 16
    ;Invoke MemCopy, Addr _EncoderQuality, ecx, 16     ; copy the GUID ot the correct address
    lea ebx, eps
    mov EncoderParameters.Parameter.vType[ebx], EncoderParameterValueTypeLong
    mov EncoderParameters.Parameter.NumberOfValues[ebx], 1 ; we have only one EncoderParameter structure

    .IF dwImageType == IMAGE_TYPE_JPG ; set the JPEG compression level
        ;PrintText 'IMAGE_TYPE_JPG'
        .IF dwJpegQuality == 0 || dwJpegQuality > 100
            mov eax, g_ImageCompression ;JpegDefaultQuality
        .ELSE
            mov eax, dwJpegQuality
        .ENDIF
        ;PrintDec eax
        mov JpegQuality, eax
        lea eax, JpegQuality
        lea ebx, eps
        mov EncoderParameters.Parameter.value[ebx], eax
    .ENDIF

    ; get the class identifier (CLSID) of the encoder - The encoder can be bmp,jpeg,gif,tiff or png
    mov eax, dwImageType
    .IF eax == IMAGE_TYPE_JPG
        Invoke GetEncoderClsid, Addr ImageTypeJpg, Addr pImageCodecInfo
    .ELSEIF eax == IMAGE_TYPE_BMP
        Invoke GetEncoderClsid, Addr ImageTypeBmp, Addr pImageCodecInfo
    .ELSEIF eax == IMAGE_TYPE_GIF
        Invoke GetEncoderClsid, Addr ImageTypeGif, Addr pImageCodecInfo
    .ELSEIF eax == IMAGE_TYPE_PNG
        Invoke GetEncoderClsid, Addr ImageTypePng, Addr pImageCodecInfo
    .ENDIF

    Invoke GdipSaveImageToFile, pBitmapImage, Addr szWFilename, eax, Addr eps ; save the image file

    Invoke VirtualFree, pImageCodecInfo, 0, MEM_RELEASE
    
    Invoke GdipDisposeImage, pBitmapImage ; release the image
    xor eax, eax
    ret

SaveBitmapToFile ENDP


;-----------------------------------------------------------------------------------------
; Get clsid for image type to save
;-----------------------------------------------------------------------------------------
GetEncoderClsid PROC USES ebx edi sMimeType:DWORD,pMem:DWORD

LOCAL numEncoders:DWORD
LOCAL nSize:DWORD
LOCAL _buffer[32]:BYTE

    invoke     GdipGetImageEncodersSize, ADDR numEncoders, ADDR nSize
    invoke     VirtualAlloc, 0, nSize, MEM_COMMIT,PAGE_READWRITE
    mov        edi,eax
    mov        eax,pMem                                  ; = pImageCodecInfo
    mov        DWORD PTR [eax],edi
    invoke     GdipGetImageEncoders, numEncoders, nSize,edi
    ;invoke     UnicodeStr, sMimeType, ADDR _buffer
    mov        ebx,numEncoders
@@:
    invoke     lstrcmpW, sMimeType, ImageCodecInfo.MimeType[edi]
    test       eax,eax
    jz         @f
    sub        ebx,1
    add        edi,SIZEOF ImageCodecInfo
    jmp        @b
@@:
    mov        eax,edi                                    ; = lea    eax,[edi+ImageCodecInfo.Clsid]
    ret

GetEncoderClsid ENDP



;-------------------------------------------------------------------------------------
; CS_GetCodeShotsFolder - Determine codeshots folder and create it if it doesnt
; already exist: from the root of x64dbg, normally it will be "\x64dbg\codeshots\"
;-------------------------------------------------------------------------------------	
CS_GetCodeShotsFolder PROC USES EBX ECX
    Invoke IniGetCodeShotsFolder, Addr CODESHOTS_FOLDER
    .IF eax == FALSE
        ;M:\x64dbg\x32
        Invoke JustPath, Addr szModuleFilename, Addr CODESHOTS_FOLDER
        IFDEF DEBUG32
        ;PrintString CODESHOTS_FOLDER
        ENDIF
        Invoke szLen, Addr CODESHOTS_FOLDER
        lea ebx, CODESHOTS_FOLDER
        add ebx, eax
        sub ebx, 2
        sub eax, 2
        mov ecx, eax
        .WHILE ecx != 0
            movzx eax, byte ptr [ebx]
            .IF al == 0
                .BREAK
            .ENDIF
            .IF al == '\' || al == '/'
                mov byte ptr [ebx+1], 0
                Invoke szCatStr, ebx, Addr szCodeShotsDefaultFolder
                .BREAK
            .ENDIF
            dec ebx
            dec ecx
        .ENDW

        Invoke GetFileAttributes, Addr CODESHOTS_FOLDER
        .IF eax != FILE_ATTRIBUTE_DIRECTORY
            Invoke CreateDirectoryPath, Addr CODESHOTS_FOLDER
            .IF eax == FALSE
                Invoke GetTempPath, MAX_PATH, Addr CODESHOTS_FOLDER
            .ENDIF
        .ENDIF
        Invoke IniSetCodeShotsFolder, Addr CODESHOTS_FOLDER 
        
    .ELSE        
        Invoke GetFileAttributes, Addr CODESHOTS_FOLDER
        .IF eax != FILE_ATTRIBUTE_DIRECTORY
            Invoke CreateDirectoryPath, Addr CODESHOTS_FOLDER
            .IF eax == FALSE
                Invoke GetTempPath, MAX_PATH, Addr CODESHOTS_FOLDER
                Invoke IniSetCodeShotsFolder, Addr CODESHOTS_FOLDER 
            .ENDIF
        .ENDIF
    .ENDIF
    IFDEF DEBUG32
    ;PrintString CODESHOTS_FOLDER
    ENDIF
    ret

CS_GetCodeShotsFolder ENDP


;-------------------------------------------------------------------------------------	
; CS_OpenCodeShotsFolder - Opens codeshots folder via explorer
;-------------------------------------------------------------------------------------	
CS_OpenCodeShotsFolder PROC
    
    Invoke ShellExecute, 0, CTEXT("explore"), Addr CODESHOTS_FOLDER, NULL, NULL, SW_SHOW    
    ret

CS_OpenCodeShotsFolder ENDP


;-------------------------------------------------------------------------------------	
;
;-------------------------------------------------------------------------------------	
CS_BuildCodeShotMenu PROC
    
    .IF hCodeShotMenu != NULL
        Invoke DestroyMenu, hCodeShotMenu 
    .ENDIF
    Invoke CreatePopupMenu
    mov hCodeShotMenu, eax
    
    invoke AppendMenu, hCodeShotMenu, MF_STRING, IDM_CODESHOT_PNG, Addr szMenuCodeshotPng
    invoke AppendMenu, hCodeShotMenu, MF_STRING, IDM_CODESHOT_JPG, Addr szMenuCodeshotJpg
    invoke AppendMenu, hCodeShotMenu, MF_STRING, IDM_CODESHOT_BMP, Addr szMenuCodeshotBmp
    invoke AppendMenu, hCodeShotMenu, MF_SEPARATOR, NULL, NULL
    invoke AppendMenu, hCodeShotMenu, MF_STRING, IDM_CODESHOT_OPTIONS, Addr szMenuCodeshotOptions
    invoke AppendMenu, hCodeShotMenu, MF_SEPARATOR, NULL, NULL
    invoke AppendMenu, hCodeShotMenu, MF_STRING, IDM_CODESHOT_FOLDER, Addr szMenuCodeshotOpenFolder

    Invoke SetMenuItemBitmaps, hCodeShotMenu, IDM_CODESHOT_PNG, MF_BYCOMMAND, hBmpMenuCodeShotPng, 0
    Invoke SetMenuItemBitmaps, hCodeShotMenu, IDM_CODESHOT_JPG, MF_BYCOMMAND, hBmpMenuCodeShotJpg, 0
    Invoke SetMenuItemBitmaps, hCodeShotMenu, IDM_CODESHOT_BMP, MF_BYCOMMAND, hBmpMenuCodeShotBmp, 0
    Invoke SetMenuItemBitmaps, hCodeShotMenu, IDM_CODESHOT_OPTIONS, MF_BYCOMMAND, hBmpMenuCodeShotOptions, 0
    Invoke SetMenuItemBitmaps, hCodeShotMenu, IDM_CODESHOT_FOLDER, MF_BYCOMMAND, hBmpMenuCodeShotFolder, 0

    
    
    ret

CS_BuildCodeShotMenu ENDP



;**************************************************************************
; Strip path name to just filename with extention
;**************************************************************************
JustFnameExt PROC USES ESI EDI szFilePathName:DWORD, szFileName:DWORD
	LOCAL LenFilePathName:DWORD
	LOCAL nPosition:DWORD
	
	Invoke szLen, szFilePathName
	mov LenFilePathName, eax
	mov nPosition, eax
	
	.IF LenFilePathName == 0
	    mov edi, szFileName
		mov byte ptr [edi], 0
		mov eax, FALSE
		ret
	.ENDIF
	
	mov esi, szFilePathName
	add esi, eax
	
	mov eax, nPosition
	.WHILE eax != 0
		movzx eax, byte ptr [esi]
		.IF al == '\' || al == ':' || al == '/'
			inc esi
			.BREAK
		.ENDIF
		dec esi
		dec nPosition
		mov eax, nPosition
	.ENDW
	mov edi, szFileName
	mov eax, nPosition
	.WHILE eax != LenFilePathName
		movzx eax, byte ptr [esi]
		mov byte ptr [edi], al
		inc edi
		inc esi
		inc nPosition
		mov eax, nPosition
	.ENDW
	mov byte ptr [edi], 0h ; null out filename
	mov eax, TRUE
	ret

JustFnameExt	ENDP



;**************************************************************************
; Internal Function: Strips filename away from path
;**************************************************************************
JustPath PROC USES EDI ESI EDX ECX szFilePathName:DWORD, szFilePath:DWORD

	xor ecx, ecx    ; zero counter
	mov esi, szFilePathName
	mov edi, szFilePath
@@:
	mov al, [esi]   ; read byte from address in esi
	inc esi
	inc ecx         ; increment counter
	cmp al, 0       ; test for zero
	je gfpOut       ; exit loop on zero
	cmp al, "\"     ; test for "\"
	jne nxt1        ; jump over if not
	mov edx, ecx    ; store counter in ecx = last "\" or "/" offset in ecx
nxt1:

	cmp al, "/"     ; test for "/" - added 15/12/2015 unix style folders
	jne nxt2        ; jump over if not
    mov edx, ecx    ; store counter in ecx = last "\" or "/" offset in ecx
    
nxt2:    
	mov [edi], al   ; write byte to address in edi
	inc edi
	jmp @B
gfpOut:
    ;dec edx
	add edx, szFilePath    ; add destination address to offset of last "\"
	mov [edx], al   ; write terminator to destination

	ret
JustPath	ENDP


;**************************************************************************
; Create each directory in turn from a folderpath
;**************************************************************************
CreateDirectoryPath PROC USES ESI ECX szFolderPath:DWORD
	LOCAL LastBackSlashPos:DWORD
	LOCAL LastFullStopPos:DWORD
	LOCAL LoopCounter:DWORD
	
	;push esi
	;push edi

    mov LastFullStopPos, 0      ; initialize to 0
    mov LastBackSlashPos, 0     ; initialize to 0
    mov LoopCounter, 0
    mov esi, szFolderPath
    
@@:
    movzx eax, byte ptr [esi]   ; read byte from address in esi
	
	cmp al, 0                   ; test for zero    
	je ExitLoop                 ; if null byte then we exit our loop   
	
	cmp al, "."                 ; test for .
	jne CheckBackslash	        ; if found we record position for later use
	mov ecx, LoopCounter
    mov LastFullStopPos, ecx
    
CheckBackslash:
    cmp al, "\"                 ; test for "\" - means we hit an end of a folder whilst looping through each byte
	jne LoopAgain               ; jump over if its not, otherwise create folder path up to this point
	mov ecx, LoopCounter
	mov LastBackSlashPos, ecx   ; record backslash pos
	
	
	
	mov byte ptr [esi], 0       ; write null byte to address in esi as esi contains our path up to this point
	;push esi
    Invoke GetFileAttributes, szFolderPath
    .IF eax != FILE_ATTRIBUTE_DIRECTORY
        Invoke CreateDirectory, szFolderPath, NULL
        ;.IF eax == 0 ; failed
        ;    Invoke GetLastError
        ;    .IF eax != ERROR_ALREADY_EXISTS
        ;        mov byte ptr [esi], '\'       ; restore \ byte to address in esi as esi contains our path up to this point
        ;        jmp ExitError
        ;    .ENDIF
        ;.ENDIF
    .ENDIF	
	;pop esi
	mov byte ptr [esi], '\'       ; restore \ byte to address in esi as esi contains our path up to this point
	
LoopAgain:
 	inc esi
 	inc LoopCounter
    jmp @B   

ExitLoop:

    mov eax, LastFullStopPos
    .IF eax < LastBackSlashPos ; we have one final directory to possibly create, else we got a filename with an extention
        Invoke GetFileAttributes, szFolderPath
        .IF eax != FILE_ATTRIBUTE_DIRECTORY
            Invoke CreateDirectory, szFolderPath, NULL
;            .IF eax == 0 ; failed
;                Invoke GetLastError
;                .IF eax != ERROR_ALREADY_EXISTS
;                    jmp ExitError
;                .ENDIF
;            .ENDIF
        .ENDIF	        
    .ENDIF
    ;xor eax, eax
    
	;pop edi
	;pop esi
	mov eax, TRUE    
    ret
    	
ExitError:
    mov eax, FALSE
    ret
CreateDirectoryPath endp



;--------------------------------------------------------------------------------------------------------------------
; Convert ascii string pointed to by String param to unsigned dword value. Returns dword value in eax.
;--------------------------------------------------------------------------------------------------------------------
OPTION PROLOGUE:NONE
OPTION EPILOGUE:NONE

align 16

atou_ex proc String:DWORD

  ; ------------------------------------------------
  ; Convert decimal string into UNSIGNED DWORD value
  ; ------------------------------------------------

    mov edx, [esp+4]

    xor ecx, ecx
    movzx eax, BYTE PTR [edx]
    test eax, eax
    jz quit

    lea ecx, [ecx+ecx*4]
    lea ecx, [eax+ecx*2-48]
    movzx eax, BYTE PTR [edx+1]
    test eax, eax
    jz quit

    lea ecx, [ecx+ecx*4]
    lea ecx, [eax+ecx*2-48]
    movzx eax, BYTE PTR [edx+2]
    test eax, eax
    jz quit

    lea ecx, [ecx+ecx*4]
    lea ecx, [eax+ecx*2-48]
    movzx eax, BYTE PTR [edx+3]
    test eax, eax
    jz quit

    lea ecx, [ecx+ecx*4]
    lea ecx, [eax+ecx*2-48]
    movzx eax, BYTE PTR [edx+4]
    test eax, eax
    jz quit

    lea ecx, [ecx+ecx*4]
    lea ecx, [eax+ecx*2-48]
    movzx eax, BYTE PTR [edx+5]
    test eax, eax
    jz quit

    lea ecx, [ecx+ecx*4]
    lea ecx, [eax+ecx*2-48]
    movzx eax, BYTE PTR [edx+6]
    test eax, eax
    jz quit

    lea ecx, [ecx+ecx*4]
    lea ecx, [eax+ecx*2-48]
    movzx eax, BYTE PTR [edx+7]
    test eax, eax
    jz quit

    lea ecx, [ecx+ecx*4]
    lea ecx, [eax+ecx*2-48]
    movzx eax, BYTE PTR [edx+8]
    test eax, eax
    jz quit

    lea ecx, [ecx+ecx*4]
    lea ecx, [eax+ecx*2-48]
    movzx eax, BYTE PTR [edx+9]
    test eax, eax
    jz quit

    lea ecx, [ecx+ecx*4]
    lea ecx, [eax+ecx*2-48]
    movzx eax, BYTE PTR [edx+10]
    test eax, eax
    jnz out_of_range

  quit:
    lea eax, [ecx]      ; return value in EAX
    or ecx, -1          ; non zero in ECX for success
    ret 4

  out_of_range:
    xor eax, eax        ; zero return value on error
    xor ecx, ecx        ; zero in ECX is out of range error
    ret 4

atou_ex endp

OPTION PROLOGUE:PrologueDef
OPTION EPILOGUE:EpilogueDef


; Paul Dixon's utoa_ex function. unsigned dword to ascii. 

OPTION PROLOGUE:NONE
OPTION EPILOGUE:NONE

    align 16

utoa_ex proc uvar:DWORD,pbuffer:DWORD

  ; --------------------------------------------------------------------------------
  ; this algorithm was written by Paul Dixon and has been converted to MASM notation
  ; --------------------------------------------------------------------------------

    mov eax, [esp+4]                ; uvar      : unsigned variable to convert
    mov ecx, [esp+8]                ; pbuffer   : pointer to result buffer

    push esi
    push edi

    jmp udword

  align 4
  chartab:
    dd "00","10","20","30","40","50","60","70","80","90"
    dd "01","11","21","31","41","51","61","71","81","91"
    dd "02","12","22","32","42","52","62","72","82","92"
    dd "03","13","23","33","43","53","63","73","83","93"
    dd "04","14","24","34","44","54","64","74","84","94"
    dd "05","15","25","35","45","55","65","75","85","95"
    dd "06","16","26","36","46","56","66","76","86","96"
    dd "07","17","27","37","47","57","67","77","87","97"
    dd "08","18","28","38","48","58","68","78","88","98"
    dd "09","19","29","39","49","59","69","79","89","99"

  udword:
    mov esi, ecx                    ; get pointer to answer
    mov edi, eax                    ; save a copy of the number

    mov edx, 0D1B71759h             ; =2^45\10000    13 bit extra shift
    mul edx                         ; gives 6 high digits in edx

    mov eax, 68DB9h                 ; =2^32\10000+1

    shr edx, 13                     ; correct for multiplier offset used to give better accuracy
    jz short skiphighdigits         ; if zero then don't need to process the top 6 digits

    mov ecx, edx                    ; get a copy of high digits
    imul ecx, 10000                 ; scale up high digits
    sub edi, ecx                    ; subtract high digits from original. EDI now = lower 4 digits

    mul edx                         ; get first 2 digits in edx
    mov ecx, 100                    ; load ready for later

    jnc short next1                 ; if zero, supress them by ignoring
    cmp edx, 9                      ; 1 digit or 2?
    ja   ZeroSupressed              ; 2 digits, just continue with pairs of digits to the end

    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dh                   ; but only write the 1 we need, supress the leading zero
    inc esi                         ; update pointer by 1
    jmp  ZS1                        ; continue with pairs of digits to the end

  align 16
  next1:
    mul ecx                         ; get next 2 digits
    jnc short next2                 ; if zero, supress them by ignoring
    cmp edx, 9                      ; 1 digit or 2?
    ja   ZS1a                       ; 2 digits, just continue with pairs of digits to the end

    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dh                   ; but only write the 1 we need, supress the leading zero
    add esi, 1                      ; update pointer by 1
    jmp  ZS2                        ; continue with pairs of digits to the end

  align 16
  next2:
    mul ecx                         ; get next 2 digits
    jnc short next3                 ; if zero, supress them by ignoring
    cmp edx, 9                      ; 1 digit or 2?
    ja   ZS2a                       ; 2 digits, just continue with pairs of digits to the end

    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dh                   ; but only write the 1 we need, supress the leading zero
    add esi, 1                      ; update pointer by 1
    jmp  ZS3                        ; continue with pairs of digits to the end

  align 16
  next3:

  skiphighdigits:
    mov eax, edi                    ; get lower 4 digits
    mov ecx, 100

    mov edx, 28F5C29h               ; 2^32\100 +1
    mul edx
    jnc short next4                 ; if zero, supress them by ignoring
    cmp edx, 9                      ; 1 digit or 2?
    ja  short ZS3a                  ; 2 digits, just continue with pairs of digits to the end

    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dh                   ; but only write the 1 we need, supress the leading zero
    inc esi                         ; update pointer by 1
    jmp short  ZS4                  ; continue with pairs of digits to the end

  align 16
  next4:
    mul ecx                         ; this is the last pair so don; t supress a single zero
    cmp edx, 9                      ; 1 digit or 2?
    ja  short ZS4a                  ; 2 digits, just continue with pairs of digits to the end

    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dh                   ; but only write the 1 we need, supress the leading zero
    mov byte ptr [esi+1], 0         ; zero terminate string

    pop edi
    pop esi
    ret 8

  align 16
  ZeroSupressed:
    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dx
    add esi, 2                      ; write them to answer

  ZS1:
    mul ecx                         ; get next 2 digits
  ZS1a:
    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dx                   ; write them to answer
    add esi, 2

  ZS2:
    mul ecx                         ; get next 2 digits
  ZS2a:
    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dx                   ; write them to answer
    add esi, 2

  ZS3:
    mov eax, edi                    ; get lower 4 digits
    mov edx, 28F5C29h               ; 2^32\100 +1
    mul edx                         ; edx= top pair
  ZS3a:
    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dx                   ; write to answer
    add esi, 2                      ; update pointer

  ZS4:
    mul ecx                         ; get final 2 digits
  ZS4a:
    mov edx, chartab[edx*4]         ; look them up
    mov [esi], dx                   ; write to answer

    mov byte ptr [esi+2], 0         ; zero terminate string

  sdwordend:

    pop edi
    pop esi

    ret 8

utoa_ex endp

OPTION PROLOGUE:PrologueDef
OPTION EPILOGUE:EpilogueDef




END DllMain
















