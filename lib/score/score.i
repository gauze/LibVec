; vim: syntax=asm6809 ts=4
; Bios routine can't set score to all zeros
; this routine does
CLEAR_SCORE_ZERO    macro    
                    ldd      # '0'*256+'0'                
                    std      ,X 
                    std      2,X 
                    sta      4,X 
                    ldd      # '0'*256+$80
                    std      5,X 
                    endm  

; macro'ed version of BIOS routine Add_Score_d
ADD_SCORE_D         macro    
                    local    LF8AE, LF8A5, LF897, LF895, LF88F, LF882
;Add_Score_d         
                    PSHS     A                            ;Save BCD on stack in reverse order 
                    PSHS     B 
                    LDB      #$05 
LF882               CLRA                                  ;Add zero to 10000 and 100000 digits 
                    CMPB     #$01 
                    BLS      LF897 
                    BITB     #$01                         ;Add right nibble to hundreds and ones 
                    BEQ      LF88F 
                    LDA      ,S 
                    BRA      LF895 

LF88F               LDA      ,S+                          ;Add left nibble to thousands and tens 
                    LSRA     
                    LSRA     
                    LSRA     
                    LSRA     
LF895               ANDA     #$0F                         ;Isolate desired nibble 
LF897               ADDA     $C823                        ;Add in carry ($C823 is normally zero) 
                    CLR      $C823                        ;Clear carry 
                    ADDA     B,X                          ;Add to digit 
                    CMPA     # '0'-1                      ;If digit was a blank,
                    BGT      LF8A5 
                    ADDA     #$10                         ; promote the result to a digit 
LF8A5               CMPA     # '9'                        ;If a carry has occurred,
                    BLS      LF8AE 
                    SUBA     #10                          ; subtract ten 
                    INC      $C823                        ; and set carry flag 
LF8AE               STA      B,X                          ;Store resulting digit 
                    DECB                                  ;Go back for more digits 
                    BPL      LF882 
                    CLR      $C823                        ;Clear $C823 back to zero 
                    CLRB     
                    endm     

