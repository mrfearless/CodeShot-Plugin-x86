include masm32.inc
includelib masm32.lib

include \masm32\macros\macros.asm

;-----------------------------------------------------------------------------------------
; CODESHOT - DateTime LIB Prototypes
;-----------------------------------------------------------------------------------------

DTDateFormat                    PROTO :DWORD, :DWORD, :DWORD
DTGetDateTime                   PROTO :DWORD, :DWORD
_StripDateTimeString			PROTO :DWORD, :DWORD


.CONST
;-----------------------------------------------------------------------------------------
; CODESHOT - DateTime LIB CONSTANTS
;-----------------------------------------------------------------------------------------
; Constants: CC=Century, YY=Year, MM=Month, DD=Day, HH=Hours, MM=Minutes, DOW=Day Of Week 

; Reverse Date Formats
CCYYMMDDHHMMSSMS                EQU 1  ; Example 1974/03/27 14:53:01:00
CCYYMMDDHHMMSS                  EQU 2  ; Example 1974/03/27 14:53:01
CCYYMMDDHHMM                    EQU 3  ; Example 1974/03/27 14:53
CCYYMMDDHH                      EQU 4  ; Example 1974/03/27 14:53
CCYYMMDD                        EQU 5  ; Example 1974/03/27
CCYYMM                          EQU 6  ; Example 1974/03
YEAR                            EQU 7  ; Example 1974

; British Date Formats
DDMMCCYYHHMMSSMS                EQU 8  ; Example 27/03/1974 14:53:01:00
DDMMCCYYHHMMSS                  EQU 9  ; Example 27/03/1974 14:53:01
DDMMCCYYHHMM                    EQU 10  ; Example 27/03/1974 14:53
DDMMCCYY                        EQU 11 ; Example 27/03/1974
DDMM                            EQU 12 ; Example 27/03
DAY                             EQU 13 ; Example 27
 
; American Date Formats
MMDDCCYYHHMMSSMS                EQU 14 ; Example 03/27/1974 14:53:01:00
MMDDCCYYHHMMSS                  EQU 15 ; Example 03/27/1974 14:53:01				
MMDDCCYYHHMM                    EQU 16 ; Example 03/27/1974 14:53					
MMDDCCYY                        EQU 17 ; Example 03/27/1974						
MMDD                            EQU 18 ; Example 03/27			
MONTH                           EQU 19 ; Example 03

; Reverse Without Century Date Formats
YYMMDDHHMMSSMS                  EQU 20 ; Example 74/03/27 14:53:01:00
YYMMDDHHMMSS                    EQU 21 ; Example 74/03/27 14:53:01
YYMMDDHHMM                      EQU 22 ; Example 74/03/27 14:53
YYMMDD                          EQU 23 ; Example 74/03/27
YYMM                            EQU 24 ; Example 74/03
YY                              EQU 25 ; Example 74

; Other Date Formats
MMDDYY                          EQU 26 ; Example 03/27/74
DDMMYY                          EQU 27 ; Example 27/03/74
DAYOFWEEK                       EQU 28 ; Example Monday

; Time Formats
HHMMSSMS                        EQU 29 ; Example 14:53:01
HHMMSS                          EQU 30 ; Example 14:53:01		
HHMM                            EQU 31 ; Example 14:53
HH                              EQU 32 ; Example 14

; Useful Named Constants
TODAY                           EQU DDMMCCYYHHMMSS
NOW                             EQU DDMMCCYYHHMMSS
TIME                            EQU HHMM

; Named Date Constants
AMERICAN                        EQU MMDDYY
BRITISH                         EQU DDMMYY
FRENCH                          EQU DDMMYY
JAPAN                           EQU YYMMDD
TAIWAN                          EQU YYMMDD
MDY                             EQU MMDDYY
DMY                             EQU DDMMYY	
YMD                             EQU YYMMDD



.code

;**************************************************************************
; Return as a formatted string as specified 
; by nDateFormat. See .inc file for constants that can be specified.
;**************************************************************************
DTDateFormat PROC USES EBX EDX ESI DateTime:DWORD, szDateTimeString:DWORD, nDateFormat:DWORD
	;LOCAL LocalDateTime[20]:BYTE	; 16 bytes for equivilant size of SYSTEMTIME Struct
	LOCAL Year[6]:BYTE				; 1 extra byte for null terminator
	LOCAL Month[4]:BYTE				; 1 extra byte for null terminator
	LOCAL Day[4]:BYTE				; 1 extra byte for null terminator
	LOCAL Hour[4]:BYTE				; 1 extra byte for null terminator
	LOCAL Minute[4]:BYTE			; 1 extra byte for null terminator
	LOCAL Second[4]:BYTE			; 1 extra byte for null terminator
	LOCAL Millisec[4]:BYTE			; 1 extra byte for null terminator
	LOCAL DOW[1]:DWORD				

;	Invoke GetLocalTime, Addr LocalDateTime

	;lea ebx, LocalDateTime
	mov ebx, DateTime
	xor edx, edx		; each value is a word only so zero out high word to allow us to use edx
	mov dx, word ptr [ebx+0]	; Offset 0 for structure SYSTEMTIME.wYear
	Invoke dwtoa, edx,  Addr Year
	
	xor edx, edx		; each value is a word only so zero out high word to allow us to use edx
	mov dx, word ptr [ebx+2]	; Offset 2 for structure SYSTEMTIME.wMonth
	Invoke dwtoa, edx,  Addr Month
	
	xor edx, edx		; each value is a word only so zero out high word to allow us to use edx
	mov dx, word ptr [ebx+4]	; Offset 4 for structure SYSTEMTIME.wDayOfWeek
	;Invoke dwtoa, edx,  Addr DOW
	mov DOW, edx
	
	xor edx, edx		; each value is a word only so zero out high word to allow us to use edx
	mov dx, word ptr [ebx+6]	; Offset 6 for structure SYSTEMTIME.wDay
	Invoke dwtoa, edx,  Addr Day
	
	xor edx, edx		; each value is a word only so zero out high word to allow us to use edx
	mov dx, word ptr [ebx+8]	; Offset 8 for structure SYSTEMTIME.wHour
	Invoke dwtoa, edx,  Addr Hour
	
	xor edx, edx		; each value is a word only so zero out high word to allow us to use edx
	mov dx, word ptr [ebx+10]	; Offset 10 for structure SYSTEMTIME.wMinute
	;PrintText 'Minute'
	;PrintDec edx 
	Invoke dwtoa, edx,  Addr Minute
	;PrintString Minute
	
	xor edx, edx		; each value is a word only so zero out high word to allow us to use edx
	mov dx, word ptr [ebx+12]	; Offset 12 for structure SYSTEMTIME.wSecond
	;PrintText 'Second'
	;PrintDec edx 
	Invoke dwtoa, edx,  Addr Second
	;PrintString Second
	
	xor edx, edx		; each value is a word only so zero out high word to allow us to use edx
	mov dx, word ptr [ebx+14]	; Offset 14 for structure SYSTEMTIME.wMilliseconds
	;PrintText 'MilliSecond'
	;PrintDec edx 
	Invoke dwtoa, edx,  Addr Millisec
	;PrintString Millisec

	; Main decision block
	.if (nDateFormat==CCYYMMDDHHMMSSMS) ||  (nDateFormat==CCYYMMDDHHMMSS) || (nDateFormat==CCYYMMDDHHMM) || (nDateFormat==CCYYMMDD) || (nDateFormat==CCYYMMDDHH) || (nDateFormat==CCYYMM) || (nDateFormat==YEAR)
		; YEAR
		Invoke lstrcpy, szDateTimeString, Addr Year
		.if nDateFormat==YEAR
			ret
		.endif
		; CCYYMM
		Invoke lstrcat, szDateTimeString, CTEXT("/")
		Invoke lnstr, Addr Month
		.if eax == 1
			Invoke lstrcat, szDateTimeString, CTEXT("0")
		.endif
		Invoke lstrcat, szDateTimeString, Addr Month
		.if nDateFormat==CCYYMM
			ret
		.endif
		; CCYYMMDD
		Invoke lstrcat, szDateTimeString, CTEXT("/")
		Invoke lnstr, Addr Day
		.if eax == 1
			Invoke lstrcat, szDateTimeString, CTEXT("0")
		.endif
		Invoke lstrcat, szDateTimeString, Addr Day
		.if nDateFormat==CCYYMMDD
			ret
		.endif
		;CCYYMMDDHH
		Invoke lstrcat, szDateTimeString, CTEXT(" ")
		Invoke lnstr, Addr Hour
		.if eax == 1
			Invoke lstrcat, szDateTimeString, CTEXT("0")
		.endif
		Invoke lstrcat, szDateTimeString, Addr Hour
		.if nDateFormat==CCYYMMDDHH
			ret
		.endif		
		; CCYYMMDDHHMM
		Invoke lstrcat, szDateTimeString, CTEXT(":")
		Invoke lnstr, Addr Minute
		.if eax == 1
			Invoke lstrcat, szDateTimeString, CTEXT("0")
		.endif
		Invoke lstrcat, szDateTimeString, Addr Minute
		.if nDateFormat==CCYYMMDDHHMM
			ret
		.endif
		; CCYYMMDDHHMMSS
		Invoke lstrcat, szDateTimeString, CTEXT(":")
		Invoke lnstr, Addr Second
		.if eax == 1
			Invoke lstrcat, szDateTimeString, CTEXT("0")
		.endif
		Invoke lstrcat, szDateTimeString, Addr Second
		.IF nDateFormat==CCYYMMDDHHMMSS
			ret
		.ENDIF
		; CCYYMMDDHHMMSSMS
		Invoke lstrcat, szDateTimeString, CTEXT(":")
		Invoke lnstr, Addr Millisec
		.if eax == 1
			Invoke lstrcat, szDateTimeString, CTEXT("0")
		.endif
		Invoke lstrcat, szDateTimeString, Addr Millisec
	
	.elseif (nDateFormat==YYMMDDHHMMSSMS) || (nDateFormat==YYMMDDHHMMSS) || (nDateFormat==YYMMDDHHMM) || (nDateFormat==YYMMDD) ||  (nDateFormat==YYMM) || (nDateFormat==YY)
		; YY
		lea esi, Year
		add esi, 2
		Invoke lstrcpy, szDateTimeString, esi
		.if nDateFormat==YY
			ret
		.endif
		; YYMM
		Invoke lstrcat, szDateTimeString, CTEXT("/")
		Invoke lnstr, Addr Month
		.if eax == 1
			Invoke lstrcat, szDateTimeString, CTEXT("0")
		.endif
		Invoke lstrcat, szDateTimeString, Addr Month
		.if nDateFormat==YYMM
			ret
		.endif
		; YYMMDD
		Invoke lstrcat, szDateTimeString, CTEXT("/")
		Invoke lnstr, Addr Day
		.if eax == 1
			Invoke lstrcat, szDateTimeString, CTEXT("0")
		.endif
		Invoke lstrcat, szDateTimeString, Addr Day
		.if nDateFormat==YYMMDD
			ret
		.endif
		; YYMMDDHHMM
		Invoke lstrcat, szDateTimeString, CTEXT(" ")
		Invoke lnstr, Addr Hour
		.if eax == 1
			Invoke lstrcat, szDateTimeString, CTEXT("0")
		.endif
		Invoke lstrcat, szDateTimeString, Addr Hour
		Invoke lstrcat, szDateTimeString, CTEXT(":")
		Invoke lnstr, Addr Minute
		.if eax == 1
			Invoke lstrcat, szDateTimeString, CTEXT("0")
		.endif
		Invoke lstrcat, szDateTimeString, Addr Minute
		.if nDateFormat==YYMMDDHHMM
			ret
		.endif
		; YYMMDDHHMMSS
		Invoke lstrcat, szDateTimeString, CTEXT(":")
		Invoke lnstr, Addr Second
		.if eax == 1
			Invoke lstrcat, szDateTimeString, CTEXT("0")
		.endif
		Invoke lstrcat, szDateTimeString, Addr Second
		.IF nDateFormat==YYMMDDHHMMSS
			ret
		.ENDIF
		; YYMMDDHHMMSSMS
		Invoke lstrcat, szDateTimeString, CTEXT(":")
		Invoke lnstr, Addr Millisec
		.if eax == 1
			Invoke lstrcat, szDateTimeString, CTEXT("0")
		.endif
		Invoke lstrcat, szDateTimeString, Addr Millisec		
			
		
	.elseif (nDateFormat==DDMMCCYYHHMMSSMS) || (nDateFormat==DDMMCCYYHHMMSS) || (nDateFormat==DDMMCCYYHHMM) || (nDateFormat==DDMMCCYY) || (nDateFormat==DDMMYY) || (nDateFormat==DDMM)  || (nDateFormat==DAY)
		; DAY
		Invoke lnstr, Addr Day
		.if eax == 1
			Invoke lstrcpy, szDateTimeString, CTEXT("0")
			Invoke lstrcat, szDateTimeString, Addr Day
		.elseif
			Invoke lstrcpy, szDateTimeString, Addr Day
		.endif
		.if nDateFormat==DAY
			ret
		.endif
		Invoke lstrcat, szDateTimeString, CTEXT("/")
		Invoke lnstr, Addr Month
		.if eax == 1
			Invoke lstrcat, szDateTimeString, CTEXT("0")
		.endif
		Invoke lstrcat, szDateTimeString, Addr Month
		.if nDateFormat==DDMM
			ret
		.endif
		; DDMMCCYY
		Invoke lstrcat, szDateTimeString, CTEXT("/")
		Invoke lstrcat, szDateTimeString, Addr Year
		.if nDateFormat==DDMMCCYY
			ret
		.endif
		; DDMMCCYYHHMM
		Invoke lstrcat, szDateTimeString, CTEXT(" ")
		Invoke lnstr, Addr Hour
		.if eax == 1
			Invoke lstrcat, szDateTimeString, CTEXT("0")
		.endif
		Invoke lstrcat, szDateTimeString, Addr Hour
		Invoke lstrcat, szDateTimeString, CTEXT(":")
		Invoke lnstr, Addr Minute
		.if eax == 1
			Invoke lstrcat, szDateTimeString, CTEXT("0")
		.endif
		Invoke lstrcat, szDateTimeString, Addr Minute
		.if nDateFormat==DDMMCCYYHHMM
			ret
		.endif
		; DDMMCCYYHHMMSS
		Invoke lstrcat, szDateTimeString, CTEXT(":")
		Invoke lnstr, Addr Second
		.if eax == 1
			Invoke lstrcat, szDateTimeString, CTEXT("0")
		.endif
		Invoke lstrcat, szDateTimeString, Addr Second
		.IF nDateFormat==DDMMCCYYHHMMSS
			ret
		.ENDIF
		; DDMMCCYYHHMMSSMS		
		Invoke lstrcat, szDateTimeString, CTEXT(":")
		Invoke lnstr, Addr Millisec
		.if eax == 1
			Invoke lstrcat, szDateTimeString, CTEXT("0")
		.endif
		Invoke lstrcat, szDateTimeString, Addr Millisec

						
	.elseif (nDateFormat==MMDDCCYYHHMMSSMS) || (nDateFormat==MMDDCCYYHHMMSS) || (nDateFormat==MMDDCCYYHHMM) || (nDateFormat==MMDDCCYY) || (nDateFormat==MMDDYY) || (nDateFormat==MMDD)  || (nDateFormat==MONTH) 
		; MONTH
		Invoke lnstr, Addr Month
		.if eax == 1
			Invoke lstrcpy, szDateTimeString, CTEXT("0")
			Invoke lstrcat, szDateTimeString, Addr Month
		.elseif
			Invoke lstrcpy, szDateTimeString, Addr Month
		.endif
		.if nDateFormat==MONTH
			ret
		.endif
		; MMDD
		Invoke lstrcat, szDateTimeString, CTEXT("/")
		Invoke lnstr, Addr Day
		.if eax == 1
			Invoke lstrcat, szDateTimeString, CTEXT("0")
		.endif
		Invoke lstrcat, szDateTimeString, Addr Day
		.if nDateFormat==MMDD
			ret
		.endif
		; MMDDCCYY
		Invoke lstrcat, szDateTimeString, CTEXT("/")
		Invoke lstrcat, szDateTimeString, Addr Year
		.if nDateFormat==MMDDCCYY
			ret
		.endif
		; MMDDCCYYHHMM
		Invoke lstrcat, szDateTimeString, CTEXT(" ")
		Invoke lnstr, Addr Hour
		.if eax == 1
			Invoke lstrcat, szDateTimeString, CTEXT("0")
		.endif
		Invoke lstrcat, szDateTimeString, Addr Hour
		Invoke lstrcat, szDateTimeString, CTEXT(":")
		Invoke lnstr, Addr Minute
		.if eax == 1
			Invoke lstrcat, szDateTimeString, CTEXT("0")
		.endif
		Invoke lstrcat, szDateTimeString, Addr Minute
		.if nDateFormat==MMDDCCYYHHMM
			ret
		.endif
		; MMDDCCYYHHMMSS
		Invoke lstrcat, szDateTimeString, CTEXT(":")
		Invoke lnstr, Addr Second
		.if eax == 1
			Invoke lstrcat, szDateTimeString, CTEXT("0")
		.endif
		Invoke lstrcat, szDateTimeString, Addr Second
		.if nDateFormat==MMDDCCYYHHMMSS
			ret
		.endif
		; MMDDCCYYHHMMSSMS
		Invoke lstrcat, szDateTimeString, CTEXT(":")
		Invoke lnstr, Addr Millisec
		.if eax == 1
			Invoke lstrcat, szDateTimeString, CTEXT("0")
		.endif
		Invoke lstrcat, szDateTimeString, Addr Millisec
			
	
	.elseif nDateFormat==DDMMYY
		; DDMMYY
		Invoke lnstr, Addr Day
		.if eax == 1
			Invoke lstrcpy, szDateTimeString, CTEXT("0")
			Invoke lstrcat, szDateTimeString, Addr Day
		.elseif
			Invoke lstrcpy, szDateTimeString, Addr Day
		.endif
		Invoke lstrcat, szDateTimeString, CTEXT("/")
		Invoke lnstr, Addr Month
		.if eax == 1
			Invoke lstrcat, szDateTimeString, CTEXT("0")
		.endif
		Invoke lstrcat, szDateTimeString, Addr Month
		Invoke lstrcat, szDateTimeString, CTEXT("/")
		lea ebx, Year
		inc ebx
		inc ebx
		Invoke lstrcat, szDateTimeString, ebx
		
	.elseif (nDateFormat==HHMM) || (nDateFormat==HHMMSS) || (nDateFormat==HHMMSSMS)
		; HHMM
		Invoke lnstr, Addr Hour
		.if eax == 1
			Invoke lstrcpy, szDateTimeString, CTEXT("0")
			Invoke lstrcat, szDateTimeString, Addr Hour	
		.elseif
			Invoke lstrcpy, szDateTimeString, Addr Hour	
		.endif
		Invoke lstrcat, szDateTimeString, CTEXT(":")
		Invoke lnstr, Addr Minute
		.if eax == 1
			Invoke lstrcat, szDateTimeString, CTEXT("0")
		.endif
		Invoke lstrcat, szDateTimeString, Addr Minute
		.if nDateFormat==HHMM
			ret
		.endif
		; HHMMSS
		Invoke lstrcat, szDateTimeString, CTEXT(":")
		Invoke lnstr, Addr Second
		.if eax == 1
			Invoke lstrcat, szDateTimeString, CTEXT("0")
		.endif
		Invoke lstrcat, szDateTimeString, Addr Second
		.if nDateFormat==HHMMSS
			ret
		.endif
		; HHMMSSMS
		Invoke lstrcat, szDateTimeString, CTEXT(":")
		Invoke lnstr, Addr Millisec
		.if eax == 1
			Invoke lstrcat, szDateTimeString, CTEXT("0")
		.endif
		Invoke lstrcat, szDateTimeString, Addr Millisec

	
	.elseif nDateFormat==DAYOFWEEK
		mov eax, DOW
		.if eax==0
			Invoke lstrcpy, szDateTimeString, CTEXT("Sunday")	
		.elseif eax==1
			Invoke lstrcpy, szDateTimeString, CTEXT("Monday")
		.elseif eax==2
			Invoke lstrcpy, szDateTimeString, CTEXT("Tuesday")
		.elseif eax==3
			Invoke lstrcpy, szDateTimeString, CTEXT("Wednesday")
		.elseif eax==4
			Invoke lstrcpy, szDateTimeString, CTEXT("Thursday")
		.elseif eax==5
			Invoke lstrcpy, szDateTimeString, CTEXT("Friday")
		.elseif eax==6
			Invoke lstrcpy, szDateTimeString, CTEXT("Saturday")
		.endif
	.else
		mov eax, FALSE
	.endif
	ret
	
DTDateFormat				ENDP


;**************************************************************************
; Get the current date & time and return as a formatted string as specified 
; by nDateFormat. See .inc file for constants that can be specified.
;**************************************************************************
DTGetDateTime PROC szDateTimeString:DWORD, nDateFormat:DWORD
	LOCAL LocalDateTime[20]:BYTE	; 16 bytes for equivilant size of SYSTEMTIME Struct
	Invoke GetLocalTime, Addr LocalDateTime
	Invoke DTDateFormat, Addr LocalDateTime, szDateTimeString, nDateFormat
	ret
DTGetDateTime ENDP


;**************************************************************************
; Strips a datetime string of all '/', ':' and space characters 
;**************************************************************************
_StripDateTimeString PROC USES EDI ESI szString:DWORD, szStrippedString:DWORD
	mov esi,szString
	mov edi,szStrippedString ;edi will point to somewhere to store the next output byte
	.while byte ptr[esi]!=0 ; while not null character, loop
		xor eax, eax
		mov al, byte ptr [esi]
		.if al == "/" || al == ":" || al == " "
			inc esi
		.else
			mov byte ptr[edi], al
			inc edi
			inc esi
		.endif
	.endw
	
	mov byte ptr[edi],0;write the zero terminator
	
	ret
_StripDateTimeString ENDP











