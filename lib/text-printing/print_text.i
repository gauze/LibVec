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
