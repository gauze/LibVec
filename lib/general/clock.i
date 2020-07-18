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
;temp1               ds       2
;temp2		     ds       2
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
; result printable with Print_Str functions eg
;         ldu #timestr
;         jsr Print_Str 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
; requires macros from:
; score/score.i
;
********************************************************
;                   CLOCK_SET 
;     requires 2 2 byte temp variables called: 
;               temp1 and temp2
;          usage: CLOCK_SET MIN,SEC  
;                where MIN SEC are integers between 
;                 SEC == between  0 and 99
;                 MIN == between  0 and 99
;               do not call in a loop!!!
;            - specifically meant for use with 
;               CLOCK_COUNT_DOWN but could be 
;               used other ways
********************************************************
CLOCK_SET           macro    MIN, SEC 
                    ldd      #MIN 
                    std      temp1 
                    cmpd     #10                          ; subtract 10 from seconds 
                    blt      under_10m                    ; done with seconds if negative 
                    pshs     a                            ; sv a 
                    lda      # '0'                        ; put 1 in seconds tens column
                    sta      _min 
                    puls     a                            ; restore a 
calc_10m 
                    subd     #10                          ; subtract again 
                    bmi      less_10m                     ; under 10 bra 
                    inc      _min                         ; else inc sec 10 colum 
                    bra      calc_10m                     ; do again 

under_10m                                                 ;        under 10s total, set 0, then value in b+30 
                    lda      # '0'
                    addb     # '0'                       
                    std      _min                         ; store both bytes 
                    bra      do_sec 

less_10m 
                    addb     # '0'+10                     ; adding 10 back to number that was less than 10, add 30 to ones to get char
                    stb      _min+1                       ; store in one's column _sec tens colum already set 
do_sec 
; seconds
                    ldd      #SEC                         ; 
                    std      temp2                        ; save in temp2 
                    cmpd     #10                          ; subtract 10 from seconds 
                    blt      under_10s                    ; done with seconds if negative 
                    pshs     a                            ; sv a 
                    lda      # '0'                        ; put 1 in seconds tens column
                    sta      _sec 
                    puls     a                            ; restore a 
calc_10s 
                    subd     #10                          ; subtract again 
                    bmi      less_10s                     ; under 10 bra 
                    inc      _sec                         ; else inc sec 10 colum 
                    bra      calc_10s                     ; do again 

under_10s                                                 ;        under 10s total, set 0, then value in b+30 
                    lda      # '0'
                    addb     # '0'                       
                    std      _sec                         ; store both bytes 
                    bra      do_cent 

less_10s 
                    addb     # '0'+10                     ; adding 10 back to number that was less than 10, add 30 to ones to get char
                    stb      _sec+1                       ; store in one's column _sec tens colum already set 
; can't set fractional seconds
do_cent 
                    lda      # '0'
                    ldb      # '0'
                    std      _centsec 
                    endm     

********************************************************
;                  CLOCK_COUNT_UP
;                called once per Wait_Recal loop
;                assumes 50 frames per second
********************************************************
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

********************************************************
;                  CLOCK_COUNTDOWN
;                called once per Wait_Recal loop
;                assumes 50 frames per second
********************************************************
CLOCK_COUNTDOWN     macro    
                    lda      PAUSE 
                    lbne     no_ticks                     ; no no 
*
                    ldd      _centsec                     ; checking of '00' 
                    cmpd     # '00'
                    bne      centsec_cont                 ; no sub 2 below 
                    ldd      _sec                         ; check seconds if '00' 
                    cmpd     # '00' 
                    bne      centsec_cont                 ; no 
                    ldd      _min                         ; check min '00' 
                    cmpd     # '00'
                    lbeq      zero_seconds_left            ; time is 00:00.00 time expired 
* get to work on 1/100th of second                 
centsec_cont 
                    ldd      _centsec                     ; test 2nd digit if over 0 , cont
                    cmpb     # '0'
                    bgt      no_sub_10cs                  ; just subtract .02 
* handling of roll over 
                    ldb      #'8'                         ; 2nd digt '8' on roll under
                    deca                                  ; 
                    cmpa     # '0'                        ; test if under 0 ... cont if no
                    bge      save_centsec
                    ldd      # "98"                       ; if 1st digit below 0 then has to be .98
                    std      _centsec
                    ldd      #_min
                    cmpd     #'00'
                    bne      check_seconds
                    dec      _sec+1
                    ldd      #'00'
                    cmpd     _sec
                    bne      check_seconds
                    bra      zero_seconds_left                 
* END handling of roll over
no_sub_10cs 
                    ldd      _centsec 
                    subd     #2 
save_centsec 
                    std      _centsec                     ; done
                    bra      no_sub_1s
; check seconds
check_seconds
                    ldb      _sec+1                    ; check if second is '0'
                    cmpb     #'0'                      ; if it's greater than jmp to sub
                    bgt      sec_cont                     ; 
                    ldb      # '9'                       ; else make it 9
                    stb      _sec+1
                    lda      _sec    
                    deca
                    cmpa     #'0'
                    blt      sub_min
                    dec      _sec
                    std      _sec 
                    bra      no_sub_1m
sub_min             
;                    dec      _min+1                        ; reduce min count do int check minute block
                    lda      #'5'
                    sta      _sec
                    bra      check_minutes
sec_cont 
                    dec      _sec+1
                    bra      no_sub_1m  
sec_done
check_minutes
                    ldd      # '00'
                    cmpd     _min 
                    beq      zero_minutes_left 
 
                    dec      _min+1 
                    ldb      _min+1                    ; check if second is '0'
                    cmpb     #'0'                      ; if it's greater than jmp to sub
                    bge      min_done                     ; 
                    ldb      # '9'                       ; else make it 9
                    stb      _min+1
                    lda      _min 
                    cmpa     #'0'
                    beq      min_done
                    dec      _min
min_done                 
zero_seconds_left 
zero_minutes_left 
no_sub_1m  
no_sub_1s 
; PAUSED below
no_ticks 
                    endm     
; 
********************************************************
;                  FORMAT_CLOCK_STR
;	 formats digits in _min and _sec and _centsec
;		into printable string
;                called once per Wait_Recal loop
;                  after calling CLICK_COUNT* macro
;		   and before printing
;                assumes 50 frames per second
********************************************************
FORMAT_CLOCK_STR    macro    
                    ldx      #timestr 
                    ldy      #_min 
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
;
********************************************************
;                  CLOCK_COUNTDOWN
;                called once per Wait_Recal loop
;                assumes 50 frames per second
********************************************************
CLEAR_SCORE_ZERO    macro    
                    LDD      # '0'*256+'0'                ;Store the leading blanks
                    STD      ,X 
                    STD      2,X 
                    STA      4,X 
                    LDD      # '0'*256+$80                ;Store the zero and terminator byte
                    STD      5,X 
                    endm  
