;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; vim: ts=4
; vim: syntax=asm6809
;
; MACROS from BIOS routines. saves a few cycles.
;
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
;
std                 macro
					ldd #$0000
					endm
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
;#COPY_STR copy a string, must be terminated with $80 #####################
; usage: X is source, Y is destination, a is destroyed
; ldx #source
; ldy #destination
; COPY_STR
COPY_STR			macro
					local cpstrloop
cpstrloop
					lda ,x+
					sta ,y+
					bpl cpstrloop
					endm
