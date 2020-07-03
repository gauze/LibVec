; timer that counts up in .2 second intervals
; have to set some variables in RAM to use this:
; xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;timestr             ds       9 
;min 
;                    ds       4 
;_min                ds       3 
;sec 
;                    ds       4 
;_sec                ds       3      ; 0 -> 59 
;centsec 
;                    ds       4      ; .00-.98 in .02 1 per frame stored as int 
;_centsec            ds       3 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
; result printable with Print_Str functions eg
;         ldu #timestr
;         jsr Print_Str 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
; requires macros from:
; score/score.i
;
CLOCK_COUNT_UP          macro    
                    local not_sixty, not_onehundred
                    ldd      #2 
                    ldx      #centsec 
                    ADD_SCORE_D
                    ldx      #_centsec-1 
                    lda      ,x 
                    cmpa     # '1'                    ; if 3rd digit is 1 gone too far
                    bne      not_onehundred 
                    ldx      #centsec 
                    CLEAR_SCORE_ZERO
                    ldd      #1                         ; and add 1 to sec column 
                    ldx      #sec 
                    ADD_SCORE_D
not_onehundred 
                    ldx      #_sec 
                    lda      ,x 
                    cmpa     # '6'                       ; 60 seconds ...
                    bne      not_sixty 
                    ldx      #sec 
                    CLEAR_SCORE_ZERO
                    ldd      #1                         ; add 1 to minutes.
                    ldx      #min 
                    ADD_SCORE_D 
not_sixty 
                    ldx      #timestr                   ; format time string
                    ldy      #_min                      ; MM:SS.CC
                    lda      ,y+ 
                    ldb      ,y 
                    std      ,x 
                    lda      # ':'
                    sta      2,x 
                    ldy      #_sec 
                    lda      ,y+ 
                    ldb      ,y 
                    std      3,x 
                    lda      # '.'
                    sta      5,x 
                    ldy      #_centsec 
                    lda      ,y+ 
                    ldb      ,y 
                    std      6,x 
                    lda      #$80 
                    sta      8,x 
                    endm   
