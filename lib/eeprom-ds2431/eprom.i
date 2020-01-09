;***************************************************************************
; example/perimeter values 
;***************************************************************************
;EEPROM_CHECKSUM     equ      69                          ; any value other than $00 or $e0 
; Variables put in var.i
;eeprom_buffer 
;eeprom_buffer1      ds       32                           ; 32 byte buffer 
;eeprom_buffer2      ds       32                           ; 32 byte buffer 
;EEPROM_STORESIZE    EQU      64                           ; only using 2 banks 
;functions
;                    JSR      eeprom_load
;                    JSR      eeprom_save 
eeprom_load                                               ;        #isfunction 
                    ldx      #eeprom_buffer               ; 
                    jsr      ds2431_load                  ; load 32 byte eeprom to ram 
                    clra     
                    ldb      #(EEPROM_STORESIZE) 
eeload_loop                                               ;        
                    adda     ,x+                          ; sum the bytes 
                    decb                                  ; 
                    bne      eeload_loop                  ; 
                    cmpa     #EEPROM_CHECKSUM             ; equal to checksum? 
                    bne      eeprom_format                ; if not, then format the eeprom 
                    rts                                   ; otherwise, return 

;****************************************************************************
eeprom_format 
                    ldu      #default_high0               ; our HS table template 
                    ldx      #eeprom_buffer               ; 
                    ldb      #$3F                         ; 63 
eeformat_loop                                             ;        copy default data (rom) to ram 
                    pulu     a                            ; 
                    sta      ,x+                          ; 
                    decb                                  ; 
                    bne      eeformat_loop                ; 
; AND BEGIN*******************************************************************
eeprom_save                                               ;        #isfunction 
                    ldx      #eeprom_buffer               ; 
                    ldd      #(EEPROM_CHECKSUM<<8)+$3F    ; lda chksum ldb #63 
eesave_loop                                               ;        
                    suba     ,x+                          ; create checksum byte 
                    decb                                  ; 
                    bne      eesave_loop                  ; 
                    sta      ,x                           ; 
                    ldx      #eeprom_buffer               ; 
                    jsr      ds2431_verify                ; compare ram to eeprom 
                    tsta                                  ; 
                    lbne     ds2431_save                  ; if different, then update eeprom 
                    rts      

; Include the driver files
;                    include  "ds2431LowLevel.i"
;                    include  "ds2431HighLevel.i"
; ROM default high scores and name with padding so 31 bytes
; place in data.i
; page 1
;default_high0       fcc      "  5000",$80                 ; 7
;default_high1       fcc      "  4000",$80                 ; 14
;default_high2       fcc      "  3000",$80                 ; 21
;default_high3       fcc      "  2000",$80                 ; 28
;                    db       0,0,0,0                      ; zero padding to 32 
; page 2
;default_high4       fcc      "  1000",$80                 ; 7
;default_name0       fcc      "GOZ",$80                    ; 11
;default_name1       fcc      "JAW",$80                    ; 15
;default_name2       fcc      "GGG",$80                    ; 19
;default_name3       fcc      "GCE",$80                    ; 23
;default_name4       fcc      "GZE",$80                    ; 27
;                    db       0,0,0,0                      ; zero padding to 31 leaving one for check sum
