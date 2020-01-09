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
;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
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
