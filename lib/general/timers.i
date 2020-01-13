; vim: ts=4 syntax=asm6809
; frame counts for animations/speed
frm100cnt           ds       1 
frm50cnt            ds       1 
frm25cnt            ds       1 
frm20cnt            ds       1 
frm10cnt            ds       1 
frm5cnt             ds       1 
frm4cnt             ds       1 
frm3cnt             ds       1 
frm2cnt             ds       1 
fmt1cnt             ds       1 
fmt0cnt             ds       1 

; in your game reset routine zero all vars the macro uses
reset_counters:
                    clrd
                    std      frm100cnt
                    std      frm25cnt
                    std      frm10cnt
                    std      frm4cnt
                    std      frm2cnt
                    sta      fmt0cnt
		    rts

; @@@@ Macro to increment and reset timers
; place in main loop, called once per frame
; frame count 100=2 seconds (at full refresh speed)  
; frame freq 1, 2, 4, 5, 10, 20, 25,50, 100 
; frame len .02, .04, .08, .1, .2, .4, .5, 1, 2 
; you can add arbitrary frame counts too! 
; Just add a variable (see above) 
; and a test block to keep count (see below)
; "YOUR CODE HERE" markers are where tasks you want for that
; frame to happen
; takes no arguments, A reg == 0 on exit.
FRAME_CNTS          macro    
                    lda      #2			; load test 
                    inc      frm2cnt		; increment var 
                    cmpa     frm2cnt		; test it 
                    bne      no2cntreset 	; not equ skip
                    clr      frm2cnt            ; reset var
; YOUR CODE HERE 
no2cntreset 
                    lda      #3 
                    inc      frm3cnt 
                    cmpa     frm3cnt 
                    bne      no3cntreset 
                    clr      frm3cnt 
; YOUR CODE HERE
no3cntreset 
                    lda      #4 
                    inc      frm4cnt 
                    cmpa     frm4cnt 
                    bne      no4cntreset 
                    clr      frm4cnt 
; YOUR CODE HERE
no4cntreset 
                    lda      #5 
                    inc      frm5cnt 
                    cmpa     frm5cnt 
                    bne      no5cntreset 
                    clr      frm5cnt 
; YOUR CODE HERE
no5cntreset 
                    lda      #10 
                    inc      frm10cnt 
                    cmpa     frm10cnt 
                    bne      no10cntreset 
                    clr      frm10cnt 
; YOUR CODE HERE
no10cntreset 
                    lda      #20 
                    inc      frm20cnt 
                    cmpa     frm20cnt 
                    bne      no20cntreset 
                    clr      frm20cnt 
; YOUR CODE HERE
no20cntreset 
                    lda      #25 
                    inc      frm25cnt 
                    cmpa     frm25cnt 
                    bne      no25cntreset 
                    clr      frm25cnt 
; YOUR CODE HERE
no25cntreset 
                    lda      #50 
                    inc      frm50cnt 
                    cmpa     frm50cnt 
                    bne      no50cntreset 
                    clr      frm50cnt 
; YOUR CODE HERE
no50cntreset 
                    lda      #100                         
                    inc      frm100cnt 
                    cmpa     frm100cnt 
                    bne      no100cntreset 
                    clra     
                    sta      frm100cnt 
no100cntreset 
                    endm     
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
