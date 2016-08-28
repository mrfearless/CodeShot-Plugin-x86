include advapi32.inc
includelib advapi32.lib

IniGetCodeShotsFolder               PROTO :DWORD
IniSetCodeShotsFolder               PROTO :DWORD
IniGetCameraShutterClick            PROTO 
IniSetCameraShutterClick            PROTO :DWORD
IniGetSeperateFolderForModules      PROTO
IniSetSeperateFolderForModules      PROTO :DWORD
IniGetImageFileIncludeAddress       PROTO
IniSetImageFileIncludeAddress       PROTO :DWORD
IniGetImageFileIncludeDatetime      PROTO
IniSetImageFileIncludeDatetime      PROTO :DWORD
IniGetDefaultImageType              PROTO
IniSetDefaultImageType              PROTO :DWORD
IniGetImageCompression              PROTO
IniSetImageCompression              PROTO :DWORD
IniGetShowToolbarButton             PROTO
IniSetShowToolbarButton             PROTO :DWORD
IniGetExcludeStatusBar              PROTO
IniSetExcludeStatusBar              PROTO :DWORD
IniGetExcludeCommandBar             PROTO
IniSetExcludeCommandBar             PROTO :DWORD

.CONST


.DATA


.DATA?


.CODE



;**************************************************************************
;
;**************************************************************************
IniGetCodeShotsFolder PROC USES EBX lpszCodeShotsFolder:DWORD
	Invoke GetPrivateProfileString, Addr szCodeShot, Addr szCodeShotsFolder, Addr szColon, lpszCodeShotsFolder, MAX_PATH, Addr CodeShotIni
    .IF eax == 0 || eax == 1 ; just got nothing or the colon and nothing else, so no published stored for this
        mov ebx, lpszCodeShotsFolder
        mov byte ptr [ebx], 0
        mov eax, FALSE
    .ELSE
		mov eax, TRUE
	.ENDIF    
    ret
IniGetCodeShotsFolder ENDP


;**************************************************************************
;
;**************************************************************************
IniSetCodeShotsFolder PROC lpszCodeShotsFolder:DWORD
   	Invoke WritePrivateProfileString, Addr szCodeShot, Addr szCodeShotsFolder, lpszCodeShotsFolder, Addr CodeShotIni
   	.IF eax == 0 ; failed
		mov eax, FALSE
	.ELSE
		mov eax, TRUE
	.ENDIF    
    ret
IniSetCodeShotsFolder ENDP


;**************************************************************************
;
;**************************************************************************
IniGetCameraShutterClick PROC
    Invoke GetPrivateProfileInt, Addr szCodeShot, Addr szCameraShutterClick, 0, Addr CodeShotIni
    ret
IniGetCameraShutterClick ENDP


;**************************************************************************
;
;**************************************************************************
IniSetCameraShutterClick PROC dwValue:DWORD
    .IF dwValue == 0
        Invoke WritePrivateProfileString, Addr szCodeShot, Addr szCameraShutterClick, Addr szZero, Addr CodeShotIni
    .ELSE
        Invoke WritePrivateProfileString, Addr szCodeShot, Addr szCameraShutterClick, Addr szOne, Addr CodeShotIni
    .ENDIF
    ret
IniSetCameraShutterClick ENDP



;**************************************************************************
;
;**************************************************************************
IniGetSeperateFolderForModules PROC
    Invoke GetPrivateProfileInt, Addr szCodeShot, Addr szSeperateFolderForModules, 0, Addr CodeShotIni
    ret
IniGetSeperateFolderForModules ENDP


;**************************************************************************
;
;**************************************************************************
IniSetSeperateFolderForModules PROC dwValue:DWORD
    .IF dwValue == 0
        Invoke WritePrivateProfileString, Addr szCodeShot, Addr szSeperateFolderForModules, Addr szZero, Addr CodeShotIni
    .ELSE
        Invoke WritePrivateProfileString, Addr szCodeShot, Addr szSeperateFolderForModules, Addr szOne, Addr CodeShotIni
    .ENDIF
    ret
IniSetSeperateFolderForModules ENDP



;**************************************************************************
;
;**************************************************************************
IniGetImageFileIncludeAddress PROC
    Invoke GetPrivateProfileInt, Addr szCodeShot, Addr szImageFileIncludeAddress, 0, Addr CodeShotIni
    ret
IniGetImageFileIncludeAddress ENDP


;**************************************************************************
;
;**************************************************************************
IniSetImageFileIncludeAddress PROC dwValue:DWORD
    .IF dwValue == 0
        Invoke WritePrivateProfileString, Addr szCodeShot, Addr szImageFileIncludeAddress, Addr szZero, Addr CodeShotIni
    .ELSE
        Invoke WritePrivateProfileString, Addr szCodeShot, Addr szImageFileIncludeAddress, Addr szOne, Addr CodeShotIni
    .ENDIF
    ret
IniSetImageFileIncludeAddress ENDP


;**************************************************************************
;
;**************************************************************************
IniGetImageFileIncludeDatetime PROC
    Invoke GetPrivateProfileInt, Addr szCodeShot, Addr szImageFileIncludeDatetime, 1, Addr CodeShotIni
    ret
IniGetImageFileIncludeDatetime ENDP


;**************************************************************************
;
;**************************************************************************
IniSetImageFileIncludeDatetime PROC dwValue:DWORD
    .IF dwValue == 0
        Invoke WritePrivateProfileString, Addr szCodeShot, Addr szImageFileIncludeDatetime, Addr szZero, Addr CodeShotIni
    .ELSE
        Invoke WritePrivateProfileString, Addr szCodeShot, Addr szImageFileIncludeDatetime, Addr szOne, Addr CodeShotIni
    .ENDIF
    ret
IniSetImageFileIncludeDatetime ENDP


;**************************************************************************
;
;**************************************************************************
IniGetDefaultImageType PROC
    Invoke GetPrivateProfileInt, Addr szCodeShot, Addr szDefaultImageType, IMAGE_TYPE_PNG, Addr CodeShotIni
    .IF eax == IMAGE_TYPE_DEFAULT
        mov eax, IMAGE_TYPE_PNG
    .ENDIF
    ret
IniGetDefaultImageType ENDP


;**************************************************************************
;
;**************************************************************************
IniSetDefaultImageType PROC dwValue:DWORD

    mov eax, dwValue
    .IF dwValue == IMAGE_TYPE_DEFAULT
        Invoke WritePrivateProfileString, Addr szCodeShot, Addr szDefaultImageType, Addr szZero, Addr CodeShotIni
    .ELSEIF dwValue == IMAGE_TYPE_BMP
        Invoke WritePrivateProfileString, Addr szCodeShot, Addr szDefaultImageType, Addr szOne, Addr CodeShotIni
    .ELSEIF dwValue == IMAGE_TYPE_JPG
        Invoke WritePrivateProfileString, Addr szCodeShot, Addr szDefaultImageType, Addr szTwo, Addr CodeShotIni
    .ELSEIF dwValue == IMAGE_TYPE_GIF
        Invoke WritePrivateProfileString, Addr szCodeShot, Addr szDefaultImageType, Addr szThree, Addr CodeShotIni
    .ELSEIF dwValue == IMAGE_TYPE_PNG
        Invoke WritePrivateProfileString, Addr szCodeShot, Addr szDefaultImageType, Addr szFour, Addr CodeShotIni
    .ENDIF
    ret
IniSetDefaultImageType ENDP


;**************************************************************************
;
;**************************************************************************
IniGetImageCompression PROC
    Invoke GetPrivateProfileInt, Addr szCodeShot, Addr szImageCompression, 90, Addr CodeShotIni
    ret
IniGetImageCompression ENDP

;**************************************************************************
;
;**************************************************************************
IniSetImageCompression PROC dwValue:DWORD
    LOCAL szValue[16]:BYTE
    Invoke utoa_ex, dwValue, Addr szValue
    Invoke WritePrivateProfileString, Addr szCodeShot, Addr szImageCompression, Addr szValue, Addr CodeShotIni
    mov eax, dwValue
    ret
IniSetImageCompression ENDP



;**************************************************************************
;
;**************************************************************************
IniGetShowToolbarButton PROC
    Invoke GetPrivateProfileInt, Addr szCodeShot, Addr szShowToolbarButton, 1, Addr CodeShotIni
    ret
IniGetShowToolbarButton ENDP


;**************************************************************************
;
;**************************************************************************
IniSetShowToolbarButton PROC dwValue:DWORD
    .IF dwValue == 0
        Invoke WritePrivateProfileString, Addr szCodeShot, Addr szShowToolbarButton, Addr szZero, Addr CodeShotIni
    .ELSE
        Invoke WritePrivateProfileString, Addr szCodeShot, Addr szShowToolbarButton, Addr szOne, Addr CodeShotIni
    .ENDIF
    ret
IniSetShowToolbarButton ENDP


;**************************************************************************
;
;**************************************************************************
IniGetExcludeStatusBar PROC
    Invoke GetPrivateProfileInt, Addr szCodeShot, Addr szExcludeStatusBar, 1, Addr CodeShotIni
    ret
IniGetExcludeStatusBar ENDP


;**************************************************************************
;
;**************************************************************************
IniSetExcludeStatusBar PROC dwValue:DWORD
    .IF dwValue == 0
        Invoke WritePrivateProfileString, Addr szCodeShot, Addr szExcludeStatusBar, Addr szZero, Addr CodeShotIni
    .ELSE
        Invoke WritePrivateProfileString, Addr szCodeShot, Addr szExcludeStatusBar, Addr szOne, Addr CodeShotIni
    .ENDIF
    ret
IniSetExcludeStatusBar ENDP


;**************************************************************************
;
;**************************************************************************
IniGetExcludeCommandBar PROC
    Invoke GetPrivateProfileInt, Addr szCodeShot, Addr szExcludeCommandBar, 1, Addr CodeShotIni
    ret
IniGetExcludeCommandBar ENDP


;**************************************************************************
;
;**************************************************************************
IniSetExcludeCommandBar PROC dwValue:DWORD
    .IF dwValue == 0
        Invoke WritePrivateProfileString, Addr szCodeShot, Addr szExcludeCommandBar, Addr szZero, Addr CodeShotIni
    .ELSE
        Invoke WritePrivateProfileString, Addr szCodeShot, Addr szExcludeCommandBar, Addr szOne, Addr CodeShotIni
    .ENDIF
    ret
IniSetExcludeCommandBar ENDP






