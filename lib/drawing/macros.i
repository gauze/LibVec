;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; vim: ts=4
; vim: syntax=asm6809
; MACROS
;
RESET0REF           macro    
                    ldd      #$00CC 
                    stb      <VIA_cntl                    ;/BLANK low and /ZERO low 
                    sta      <VIA_shift_reg               ;clear shift register 
                    ldd      #$0302 
                    clr      <VIA_port_a                  ;clear D/A register 
                    sta      <VIA_port_b                  ;mux=1, disable mux 
                    stb      <VIA_port_b                  ;mux=1, enable mux 
                    stb      <VIA_port_b                  ;do it again 
                    ldb      #$01 
                    stb      <VIA_port_b                  ;disable mu 
                    endm     
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MOVETO_D            macro    
                    local    MLF318, MLF33B,MLF33D,MLF341,MLF345,moveto_d_done 
                    sta      <VIA_port_a                  ;Store Y in D/A register 
                    clr      <VIA_port_b                  ;Enable mux 
                    pshs     b,a                          ;Save D-register on stack 
MLF318:             lda      #$CE                         ;Blank low, zero high? 
                    sta      <VIA_cntl 
                    clr      <VIA_shift_reg               ;Clear shift regigster 
                    inc      <VIA_port_b                  ;Disable mux 
                    stb      <VIA_port_a                  ;Store X in D/A register 
                    clr      <VIA_t1_cnt_hi               ;timer 1 count high 
                    puls     a,b                          ;Get back D-reg 
                    jsr      Abs_a_b 
                    stb      -1,s 
                    ora      -1,s 
                    ldb      #$40 
                    cmpa     #$40 
                    bls      MLF345 
                    cmpa     #$64 
                    bls      MLF33B 
                    lda      #$08 
                    bra      MLF33D 

MLF33B:             lda      #$04                         ;Wait for timer 1 
; could insert some routines in here before checking countdown?
MLF33D:             bitb     <VIA_int_flags 
                    beq      MLF33D 
MLF341:             deca                                  ;Delay a moment 
                    bne      MLF341 
                    bra      moveto_d_done 

MLF345:             bitb     <VIA_int_flags               ;Wait for timer 1 
                    beq      MLF345 
moveto_d_done 
                    endm     
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INTENSITY_A         macro    
                    sta      <VIA_port_a                  ;Store intensity in D/A 
                    sta      Vec_Brightness               ;Save intensity in $C827 
                    ldd      #$0504                       ;mux disabled channel 2 
                    sta      <VIA_port_b 
                    stb      <VIA_port_b                  ;mux enabled channel 2 
                    stb      <VIA_port_b                  ;do it again just because 
                    ldb      #$01 
                    stb      <VIA_port_b                  ;turn off mux 
                    endm     
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;########################DRAWING MACROS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DRAW_VLC            macro    
                    local    LF3F4,Draw_VLa 
                    lda      ,x+ 
Draw_VLa 
                    sta      $C823 
                    ldd      ,x 
                    sta      <VIA_port_a                  ;Send Y to A/D 
                    clr      <VIA_port_b                  ;Enable mux 
                    leax     2,x                          ;Point to next coordinate pair 
                    nop                                   ;Wait a moment 
                    inc      <VIA_port_b                  ;Disable mux 
                    stb      <VIA_port_a                  ;Send X to A/D 
                    ldd      #$FF00                       ;Shift reg=$FF (solid line), T1H=0 
                    sta      <VIA_shift_reg               ;Put pattern in shift register 
                    stb      <VIA_t1_cnt_hi               ;Set T1H (scale factor?) 
                    ldd      #$0040                       ;B-reg = T1 interrupt bit 
LF3F4:              bitb     <VIA_int_flags               ;Wait for T1 to time out 
                    beq      LF3F4 
                    nop                                   ;Wait a moment more 
                    sta      <VIA_shift_reg               ;Clear shift register (blank output) 
                    lda      $C823                        ;Decrement line count 
                    deca     
                    bpl      Draw_VLa                     ;Go back for more points 
                                                          ; jmp Check0Ref ;Reset zero reference if necessary 
                    endm     
DRAW_VL_MODE        macro    
                    local    next_byte, next_line, dvm_done ,dorgle, fuckle, draw_solid 
next_byte:          lda      ,x+                          ;Get the next mode byte 
                    bne      draw_solid 
                                                          ; MOV_DRAW_VL ;If =0, move to the next point 
                    ldd      ,x                           ;Get next coordinate pair 
                    sta      <VIA_port_a                  ;Send Y to A/D 
                    clr      <VIA_port_b                  ;Enable mux 
                    leax     2,x                          ;Point to next coordinate pair 
                    nop                                   ;Wait a moment 
                    inc      <VIA_port_b                  ;Disable mux 
                    stb      <VIA_port_a                  ;Send X to A/D 
                    ldd      #$0000                       ;Shift reg=0 (no draw), T1H=0 
                                                          ; BRA LF3ED ;A->D00A, B->D005 
                    sta      <VIA_shift_reg               ;Put pattern in shift register 
                    stb      <VIA_t1_cnt_hi               ;Set T1H (scale factor?) 
                    ldd      #$0040                       ;B-reg = T1 interrupt bit 
fuckle:             bitb     <VIA_int_flags               ;Wait for T1 to time out 
                    beq      fuckle 
                    nop                                   ;Wait a moment more 
                    sta      <VIA_shift_reg               ;Clear shift register (blank output) 
                                                          ; commented because not 'VL_c' which has vector line count 
                                                          ; lda $C823 ;Decrement line count 
                                                          ; deca 
                    bra      next_byte 

draw_solid:         deca     
                    beq      dvm_done                     ;value was 1 which si end of packlet marker 
                                                          ; DRAW_VL ;If <>1, draw a solid line 
                    ldd      ,x 
                    sta      <VIA_port_a                  ;Send Y to A/D 
                    clr      <VIA_port_b                  ;Enable mux 
                    leax     2,x                          ;Point to next coordinate pair 
                    nop                                   ;Wait a moment 
                    inc      <VIA_port_b                  ;Disable mux 
                    stb      <VIA_port_a                  ;Send X to A/D 
                    ldd      #$FF00                       ;Shift reg=$FF (solid line), T1H=0 
                    sta      <VIA_shift_reg               ;Put pattern in shift register 
                    stb      <VIA_t1_cnt_hi               ;Set T1H (scale factor?) 
                    ldd      #$0040                       ;B-reg = T1 interrupt bit 
; could insert some routines in here before checking countdown?
dorgle:             bitb     <VIA_int_flags               ;Wait for T1 to time out 
                    beq      dorgle 
                    nop                                   ;Wait a moment more 
                    sta      <VIA_shift_reg               ;Clear shift register (blank output) 
                    bra      next_byte 

dvm_done 
                    endm     
;;;;;;;;;;;; from BIOS optimized slightly ;;;;;;;;;;;;;;;;;;;;;;;;
DRAW_LINE_D         macro    
                    local    timeout 
                    STA      <VIA_port_a                  ;Send Y to A/D 
                    CLR      <VIA_port_b                  ;Enable mux 
;                   LEAX     2,X                          ;Point to next coordinate pair 
                    NOP                                   ;Wait a moment 
                    INC      <VIA_port_b                  ;Disable mux 
                    STB      <VIA_port_a                  ;Send X to A/D 
                                                          ; Add pattern logic here for weirdly strobing line 
                    LDD      #$FF00                       ;Shift reg=$FF (solid line), T1H=0 
                    STA      <VIA_shift_reg               ;Put pattern in shift register 
                    STB      <VIA_t1_cnt_hi               ;Set T1H (scale factor?) 
                    LDD      #$0040                       ;B-reg = T1 interrupt bit 
timeout:            BITB     <VIA_int_flags               ;Wait for T1 to time out 
                    BEQ      timeout 
                    NOP                                   ;Wait a moment more 
                    STA      <VIA_shift_reg               ;Clear shift register (blank output) 
                                                          ;LDA $C823 ;Decrement line count 
                                                          ;DECA 
                                                          ;BPL Draw_VL_a ;Go back for more points 
                                                          ;JMP Check0Ref ;Reset zero reference if necessary 
                    endm     
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DRAW_LINE_D_PAT     macro    
                    local    _timeout_pat 
                    STA      <VIA_port_a                  ;Send Y to A/D 
                    CLR      <VIA_port_b                  ;Enable mux 
                    NOP                                   ;Wait a moment 
                    INC      <VIA_port_b                  ;Disable mux 
                    STB      <VIA_port_a                  ;Send X to A/D 
                    CLR      <VIA_t1_cnt_hi               ;Set T1H (scale factor?) 
                    LDB      #$40                         ;B-reg = T1 interrupt bit 
                    LDA      Line_Pat                     ;Shift reg 
_timeout_pat        STA      <VIA_shift_reg               ;Put pattern in shift register 
                    BITB     <VIA_int_flags               ;Wait for T1 to time out 
                    BEQ      _timeout_pat 
                    NOP                                   ;Wait a moment more 
                    CLR      <VIA_shift_reg               ;Clear shift register (blank output) 
                    endm     
;;;;;;;;;;;; from BIOS optimized slightly ;;;;;;;;;;;;;;;;;;;;;;;;    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DRAW_VECTOR_SCORE   macro    
                    lda      #$5F 
                    INTENSITY_A  
                    lda      frm2cnt 
                    lbeq     _no_print_vscore 
                    lda      Demo_Mode 
                    lbne     demo_score 
                    RESET0REF  
                    lda      #-127                        ; position before scaling 
                    ldb      #-20 
                    MOVETO_D  
                    lda      #14                          ; scale it lower is better 
                    sta      VIA_t1_cnt_lo 
                    ldy      #score 
_scoreloop 
                    lda      ,y+ 
                    cmpa     #$20                         ; is space? 
                    beq      _is_zero 
                    cmpa     #$80                         ; is EOL? 
                    lbeq     score_done 
                    suba     #$30                         ; otherwise get DEC value 
                    lsla     
                    ldx      #numbers_t 
                    ldx      a,x 
                    DRAW_VL_MODE  
                    bra      _scoreloop 

_is_zero 
                    ldx      #zero 
                    DRAW_VL_MODE  
                    ldx      #numbers_t 
                    lbra      _scoreloop 

demo_score 
                    RESET0REF  
                    lda      demo_label_cnt 
                    lsla     
                    ldu      #Demo_Label_t 
                    ldu      a,u 
                    lda      #-127 
                    ldb      #-100 
                    PRINT_STR_D  
                                                          ;jsr Print_Str_d 
score_done 
_no_print_vscore 
                    endm     
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MOVETO_D_BEFORE     macro    
                    sta      <VIA_port_a                  ;Store Y in D/A register 
                    clr      <VIA_port_b                  ;Enable mux 
                    pshs     b,a                          ;Save D-register on stack 
                    lda      #$CE                         ;Blank low, zero high? 
                    sta      <VIA_cntl 
                    clr      <VIA_shift_reg               ;Clear shift regigster 
                    inc      <VIA_port_b                  ;Disable mux 
                    stb      <VIA_port_a                  ;Store X in D/A register 
                    clr      <VIA_t1_cnt_hi               ;timer 1 count high 
                    puls     a,b                          ;Get back D-reg 
                    jsr      Abs_a_b 
                    stb      -1,s 
                    ora      -1,s 
                    ldb      #$40 
                    cmpa     #$40 
                    bls      MLF345 
                    cmpa     #$64 
                    bls      MLF33B 
                    lda      #$08 
                    bra      MLF33D 

                    endm     
; ^%^%$^%@*&^@(  
MOVETO_D_AFTER      macro    
                    local    AMLF33B,AMLF33D,AMLF341,AMLF345,moveto_d_a_done 
AMLF33B:            lda      #$04                         ;Wait for timer 1 
; could insert some routines in here before checking countdown?
AMLF33D:            bitb     <VIA_int_flags 
                    beq      AMLF33D 
AMLF341:            deca                                  ;Delay a moment 
                    bne      AMLF341 
                    bra      moveto_d_done 

AMLF345             bitb     <VIA_int_flags               ;Wait for timer 1 
                    beq      AMLF345 
moveto_d_a_done 
                    endm     
;###################################################################################
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
ABS_A_B             macro    
                    local    abs_end, _Abs_b 
                    TSTA     
                    BPL      _Abs_b 
                    NEGA     
                    BVC      _Abs_b 
                    DECA     
_Abs_b              TSTB     
                    BPL      abs_end 
                    NEGB     
                    BVC      abs_end 
                    DECB     
abs_end 
                    endm     
;#############################################################
PRINT_STR_D         macro    
                    local    psdelayloop, psddone,linestart, moveflagset 
                    local    movedelay, movetimer1, movetimer2, movedone 
                    local    charlineread,charlinenext 
;                    JSR      >Moveto_d_7F 
;Moveto_d_7F:   
                    STA      <VIA_port_a                  ;Store Y in D/A register 
                    PSHS     d                            ;Save D-register on stack 
                                                          ;clr temp1 
                    LDA      #$7F                         ;Set scale factor to $7F 
                    STA      <VIA_t1_cnt_lo 
                    CLR      <VIA_port_b                  ;Enable mux 
;                    BRA      LF318 
;LF318:
                    LDA      #$CE                         ;Blank low, zero high? 
;                            %1100 1110  
                    STA      <VIA_cntl 
                    CLR      <VIA_shift_reg               ;Clear shift regigster 
                    INC      <VIA_port_b                  ;Disable mux 
                    STB      <VIA_port_a                  ;Store X in D/A register 
                    CLR      <VIA_t1_cnt_hi               ;timer 1 count high 
                    PULS     d                            ;Get back D-reg 
                                                          ;JSR Abs_a_b 
                    ABS_A_B  
                    STB      -1,s 
                    ORA      -1,s 
                    LDB      #$40                         ; used in tests below of VIA_int_flags 
                    CMPA     #$40                         ; %01000000 
                    BLS      movetimer2                   ; 'a' <= 0x40, skip first set of delays while moving 
                                                          ; 0x64 %0110 0100 
                    CMPA     #$64                         ; 'a' <= 0x64, set flag to '4' 
                    BLS      moveflagset 
                    LDA      #$08                         ; delay used in movedelay set flag to '8' 
                    BRA      movetimer1 

moveflagset         LDA      #$04                         ; delay used in movedelay 
movetimer1          BITB     <VIA_int_flags               ;Wait for timer 1 , BIT vs $40==0100 0000 
                    BEQ      movetimer1 
movedelay           DECA                                  ;Delay a moment 4 or 8 depending on scale 
                    BNE      movedelay 
                    bra      movedone 

movetimer2          BITB     <VIA_int_flags               ;Wait for timer 1 
                    BEQ      movetimer2                   ; 
movedone 
;                    RTS      
; End Moveto_d_7F
                    NOP      10                           ; pause 20 cycles more readable? 
                                                          ; JSR Delay_1 ; pauze 20 cycles 
                                                          ; JMP Print_Str 
                    STU      Vec_Str_Ptr                  ;Save string pointer 
                                                          ; LDX #Char_Table-$20 ;Point to start of chargen bitmaps 
                    LDD      #$1883                       ;$8x = enable RAMP? 
;                            a=  %0001 1000 | b= %1000 0011
                    CLR      <VIA_port_a                  ;Clear D/A output 
                    STA      <VIA_aux_cntl                ;Shift reg mode = 110, T1 PB7 enabled 
                    LDX      #Char_Table-$20              ;Point to start of chargen bitmaps 
linestart           STB      <VIA_port_b                  ;Update RAMP, set mux to channel 1 
                    DEC      <VIA_port_b                  ;Enable mux 
                    LDD      #$8081 
                    NOP                                   ;Wait a moment 
                    INC      <VIA_port_b                  ;Disable mux 
                    STB      <VIA_port_b                  ;Enable RAMP, set mux to channel 0 
                    STA      <VIA_port_b                  ;Enable mux 
                    TST      $C800                        ;I think this is a delay only 
                    INC      <VIA_port_b                  ;Enable RAMP, disable mux 
                    LDA      Vec_Text_Width               ;Get text width 
                    STA      <VIA_port_a                  ;Send it to the D/A 
                    LDD      #$0100 
                    LDU      Vec_Str_Ptr                  ;Point to start of text string 
                    STA      <VIA_port_b                  ;Disable RAMP, disable mux 
                    BRA      charlinenext 

; reading each line from chargen (character generator) table to form letters
charlineread        LDA      a,x                          ;Get bitmap from chargen table 
                    STA      <VIA_shift_reg               ;Save in shift register 
charlinenext 
                    LDA      ,u+                          ;Get next char 
;                    cmpa     #$4F                         ; 'O' 
;                    BNE      charlinenext 
;                  pshs     a
;                    lda      #127 
;                    sta      <VIA_port_a
;                  puls     a 
                    BPL      charlineread                 ;Go back if not terminator 
; continue next line
                    LDA      #$81 
                    STA      <VIA_port_b                  ;Enable RAMP, disable mux 
                    NEG      <VIA_port_a                  ;Negate text width to D/A 
                    LDA      #$01 
                    STA      <VIA_port_b                  ;Disable RAMP, disable mux 
                    CMPX     #Char_Table_End-$20          ; Check for last row 
                    BEQ      psddone                      ;Branch if last row 
                    LEAX     $50,x                        ;Point to next chargen row 
                    TFR      u,d                          ;Get string length 
                    SUBD     Vec_Str_Ptr 
                    SUBB     #$02                         ; - 2 
                    ASLB                                  ; * 2 
                    BRN      psdelayloop                  ;3 cycles Delay a moment BRN=branch never 
psdelayloop         LDA      #$81 
                    NOP      
                    DECB     
                    BNE      psdelayloop                  ;Delay some more in a loop 
                    STA      <VIA_port_b                  ;Enable RAMP, disable mux 
                    LDB      Vec_Text_Height              ;Get text height 
                    STB      <VIA_port_a                  ;Store text height in D/A 
                    DEC      <VIA_port_b                  ;Enable mux 
                    LDD      #$8101 
                    NOP                                   ;Wait a moment 
                    STA      <VIA_port_b                  ;Enable RAMP, disable mux 
                    CLR      <VIA_port_a                  ;Clear D/A 
                    STB      <VIA_port_b                  ;Disable RAMP, disable mux 
                    STA      <VIA_port_b                  ;Enable RAMP, disable mux 
; maybe change brightness here?
                                                          ; LDA #127 
                                                          ; INTENSITY_A 
                    LDB      #$03                         ;$0x = disable RAMP? 
                    BRA      linestart                    ;Go back for next scan line 

psddone             LDA      #$98 
                    STA      <VIA_aux_cntl                ;T1->PB7 enabled 
                                                          ; JMP Reset0Ref ;Reset the zero reference 
                    endm     
