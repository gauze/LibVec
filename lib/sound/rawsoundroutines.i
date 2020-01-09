; vim: ts=4
; vim: syntax=asm6809
; Sound effects 
; ALL
MUTE                =        0 
; ch 1
GHOST_SPAWN         =        1 
CB_BOUNCE           =        2 
CB_SPAWN            =        3 
GET_PRIZE           =        4 
BLOOP               =        5 
PIP                 =        6 
REVBLOOP            =        7 
; ch 2
ARROW_SPAWN         =        1 
TANK_SPAWN          =        2 
UPBURST             =        3 
DOWNBURST           =        4 
VERTMOVE            =        5 
; ch 3
SHOT                =        1 
ALLEY_MOVE          =        2 
; add to main 
;                    jsr      Do_Sound_FX_C1 
;                    jsr      Do_Sound_FX_C2 
;                    jsr      Do_Sound_FX_C3 
;  Sound_Byte_raw
;   A-reg = which of the 15 sound chip registers to modify
;   B-reg = the byte of sound data     
;   X-reg = 15 byte shadow area (Sound_Byte_x only)
; Registers:  
; 0 = freq ch1 (lower 8 bits)
; 1 = freq ch1 (top 4 bits)
; 2-3 = freq ch2
; 4-5 = freq ch3
; 6 = noise generator freq (shared)
; 7 = on/off per channel (bits)
;        0 - Voice 1 use Tone Generator 1 On/Off
;        1 - Voice 2 use Tone Generator 2 On/Off
;        2 - Voice 3 use Tone Generator 3 On/Off
;        3 - Voice 1 use Noise Generator On/Off
;        4 - Voice 2 use Noise Generator On/Off
;        5 - Voice 3 use Noise Generator On/Off
;       6-7 Unused (accidental use of these will break button handling)
; 8 = volume ch1 (LOWER 4 bits, 0-15)
; 9 = volume ch2 "
; 10 = volume ch3    
; 11 = envelope fine 
; 12 = envelope coarse 
; 13 = Envelope shape (lower 4 bits)
;          0 - continue
;          1 - attack
;          2  - Alternate
;          3  - hold 
; 14 = Data port (A) (there is no B on 8912)
;                                                        
;===========
SfxInit: 
                    ldd      #0 
;                    sta      tempB5 
                    sta      sfxC1ID 
                    sta      sfxC2ID 
                    sta      sfxC3ID 
                    std      tempW1 
                    std      tempW2 
                    sta      tempB3 
                                                          ; std sfx_FC 
                    std      sfxC1W1 
                    std      sfxC2W1 
                    std      sfxC3W1 
                    lda      #PSG_OnOff 
                    ldb      #Ch_All_Off 
                    jsr      Sound_Byte_raw 
                                                          ;set vol 0 
                    lda      #PSG_Ch1_Vol 
                    ldb      #0 
                    jsr      Sound_Byte_raw 
                    lda      #PSG_Ch2_Vol 
                    ldb      #0 
                    jsr      Sound_Byte_raw 
                    lda      #PSG_Ch3_Vol 
                    ldb      #0 
                    jsr      Sound_Byte_raw
					lda      #PSG_Ch1_Freq_Lo
					ldb      #0
					jsr      Sound_Byte_raw
					lda      #PSG_Ch1_Freq_Hi
					ldb      #0
					jsr      Sound_Byte_raw
					lda      #PSG_Ch2_Freq_Lo
					ldb      #0
					jsr      Sound_Byte_raw
					lda      #PSG_Ch2_Freq_Hi
					ldb      #0
					jsr      Sound_Byte_raw
					lda      #PSG_Ch3_Freq_Lo
					ldb      #0
					jsr      Sound_Byte_raw
					lda      #PSG_Ch3_Freq_Hi
					ldb      #0
					jsr      Sound_Byte_raw
					lda      #PSG_Noise
					ldb      #0
					jsr      Sound_Byte_raw
                    rts      

;=========
Do_Sound_FX_C1: 
;sound effect? checks "ID" value to decide sound effect 
                    lda      sfxC1ID 
                    cmpa     #CB_BOUNCE 
                    lbeq     Do_Sound_FX_C1CB_Bounce 
                    cmpa     #GHOST_SPAWN 
                    lbeq     Do_Sound_FX_C1Ghost_Spawn 
                    cmpa     #BLOOP 
                    lbeq     Do_Sound_FX_C1Bloop 
                    cmpa     #REVBLOOP 
                    lbeq     Do_Sound_FX_C1RevBloop 
                    cmpa     #PIP 
                    lbeq     Do_Sound_FX_C1Pip 
                    cmpa     #MUTE 
                    blt      Do_Sound_FX_C1SoundOff 
; ??? does this drop through on
; something other than 0-3 ??? nope mask %011 in another section
                    rts      

;========
Do_Sound_FX_C1Mute: 
Do_Sound_FX_C1SoundOff: 
                    lda      #PSG_Ch2_Freq_Lo 
                    ldb      #0 
                    jsr      Sound_Byte_raw 
                    lda      #PSG_Ch2_Freq_Hi 
                    ldb      #0 
                    jsr      Sound_Byte_raw               ;set vol ch1 
;
                    lda      #PSG_Ch1_Vol                 ; ch1 
                    ldb      #0 
                    jsr      Sound_Byte_raw 
;
                    lda      #PSG_OnOff 
                    lda      #Ch1_Noise_Off               ; #Ch1_Tone_Off 
                    jsr      Sound_Byte_raw 
;
                    lda      #PSG_Env_Shape                  
                    ldb      #0 
                    jsr      Sound_Byte_raw 
                    clr      sfxC1ID 
                    rts      

;===================
Do_Sound_FX_C1Ghost_Spawn: 
                    lda      sfxC1W1 
                    cmpa     #0 
                    beq      Do_Sound_FX_C1SoundOff 
                                                          ;set mixer byte 
                    lda      #PSG_OnOff 
                    ldb      #Ch1_Tone_On 
                    jsr      Sound_Byte_raw 
;
                    ldx      #Ghost_Spawn_Freq 
                    lda      sfxC1W1 
                    lsla                                  ; 2 bytes 
                    ldd      a,x 
                    std      tempW1 
                                                          ;set pitch ch1 
                    lda      #PSG_Ch1_Freq_Lo 
                    ldb      tempW1+1 
                    jsr      Sound_Byte_raw 
                    lda      #PSG_Ch1_Freq_Hi 
                    ldb      tempW1 
                    jsr      Sound_Byte_raw 
                    lda      #PSG_Ch1_Vol 
                    ldb      #13 
                    jsr      Sound_Byte_raw 
                    dec      sfxC1W1 
                    rts      

Do_Sound_FX_C1CB_Bounce: 
                    lda      sfxC1W1 
                    cmpa     #0 
                    beq      Do_Sound_FX_C1SoundOff 
                                                          ;set mixer byte 
                    lda      #PSG_OnOff 
                    ldb      #Ch1_Tone_On                 ;| #Ch1_Noise_On ; #$90 
                    jsr      Sound_Byte_raw 
                    ldx      #CB_Bounce_Freq 
                    lda      sfxC1W1 
                    lsla                                  ; 2 bytes 
                    ldd      a,x 
                    std      tempW1 
                    lda      #PSG_Ch1_Freq_Lo 
                    ldb      tempW1+1 
                    jsr      Sound_Byte_raw 
                    lda      #PSG_Ch1_Freq_Hi 
                    ldb      tempW1 
                    jsr      Sound_Byte_raw 
                    lda      #PSG_Ch1_Vol 
                                                          ; ldb #Use_Env 
                    ldb      #12 
                    jsr      Sound_Byte_raw 
; use env test 
                                                          ; lda #13 ;; env ?? 
                                                          ; ldb #%1101 
                                                          ; jsr Sound_Byte_raw 
                    dec      sfxC1W1 
                    rts      

Do_Sound_FX_C1Bloop: 
                    lda      sfxC1W1 
                    cmpa     #0 
                    lbeq      Do_Sound_FX_C1SoundOff 
                    lda      #PSG_OnOff 
                    ldb      #Ch1_Tone_On                 ;| #Ch1_Noise_Off 
                    jsr      Sound_Byte_raw 
                    ldx      #Bloop_Vol 
                    lda      sfxC1W1 
                    ldb      a,x 
                    lda      #PSG_Ch1_Vol 
                    jsr      Sound_Byte_raw 
                    ldd      #3650 
                    std      tempW1 
                    lda      #PSG_Ch1_Freq_Lo 
                    ldb      tempW1+1 
                    jsr      Sound_Byte_raw 
                    lda      #PSG_Ch1_Freq_Hi 
                    ldd      tempW1 
                    jsr      Sound_Byte_raw 
                    dec      sfxC1W1                      ; or it'll never end! 
                    rts      

Do_Sound_FX_C1Pip: 
                                                          ; lda #PSG_Ch1_Freq_Lo 
                                                          ; ldb #0 
                                                          ; jsr Sound_Byte_raw 
                                                          ; lda #PSG_Ch1_Freq_Hi 
                                                          ; ldb #0 
                                                          ; jsr Sound_Byte_raw 
                    lda      sfxC1W1 
                    cmpa     #0 
                    lbeq      Do_Sound_FX_C1SoundOff 
                    lda      #PSG_OnOff 
                    ldb      #Ch1_Tone_On                 ;| #Ch1_Noise_Off 
                    jsr      Sound_Byte_raw 
                    ldx      #Bloop_Vol 
                    lda      sfxC1W1 
                    ldb      a,x 
                    lda      #PSG_Ch1_Vol 
                    jsr      Sound_Byte_raw 
                    ldd      #34                          ; high "pip" 
                    std      tempW1 
                    lda      #PSG_Ch1_Freq_Lo 
                    ldb      tempW1+1 
                    jsr      Sound_Byte_raw 
                    lda      #PSG_Ch1_Freq_Hi 
                    ldd      tempW1 
                    jsr      Sound_Byte_raw 
                    dec      sfxC1W1                      ; or it'll never end! 
                    rts    
Do_Sound_FX_C1RevBloop: 
                    lda      sfxC1W1 
                    cmpa     #0 
                    lbeq      Do_Sound_FX_C1SoundOff 
                    lda      #PSG_OnOff 
                    ldb      #Ch1_Tone_On                 ;| #Ch1_Noise_Off 
                    jsr      Sound_Byte_raw 
                    ldx      #RevBloop_Vol 
                    lda      sfxC1W1 
                    ldb      a,x 
                    lda      #PSG_Ch1_Vol 
                    jsr      Sound_Byte_raw 
                    ldd      #34                          ; high "pip" 
                    std      tempW1 
                    lda      #PSG_Ch1_Freq_Lo 
                    ldb      tempW1+1 
                    jsr      Sound_Byte_raw 
                    lda      #PSG_Ch1_Freq_Hi 
                    ldd      tempW1 
                    jsr      Sound_Byte_raw 
                    dec      sfxC1W1                      ; or it'll never end! 
                    rts     

;=Channel 2 effects check =======
Do_Sound_FX_C2: 
                    lda      sfxC2ID 
                    cmpa     #UPBURST 
                    lbeq     Do_Sound_FX_C2UpBurst 
                    cmpa     #DOWNBURST 
                    lbeq     Do_Sound_FX_C2DownBurst 
                    cmpa     #VERTMOVE 
                    lbeq     Do_Sound_FX_C2VertMove 
                    cmpa     #MUTE 
                    lbeq     Do_Sound_FX_C2SoundOff 
;                    ldd      #0 
;                    std      tempW2 
                    rts      

;===============================
Do_Sound_FX_C2VertMove: 
                    lda      sfxC2W1 
                    cmpa     #0 
                    lbeq     Do_Sound_FX_C2SoundOff 
					lda      #0
					ldb      #53
					jsr      Sound_Byte_raw
                    lda      #PSG_OnOff 
                    ldb      #Ch2_Tone_On                 ;| #Ch1_Noise_Off 
                    jsr      Sound_Byte_raw 
                    lda      #PSG_OnOff 
                    ldb      #Ch2_Noise_Off 
                    jsr      Sound_Byte_raw 
;new code v
                    lda      #PSG_Env_Period_Fine 
                    ldb      tempB3 
                    jsr      Sound_Byte_raw 
;
                    lda      #PSG_Env_Period_Coarse 
                    ldb      #0 
                    jsr      Sound_Byte_raw 
; 
                    lda      #PSG_Ch2_Vol 
                    ldb      #16 
                    jsr      Sound_Byte_raw 
; new code ^
                    ldx      #VertMove_Freq 
                    lda      sfxC2W1 
                    ldd      a,x 
                    std      tempW1 
                    lda      #PSG_Ch2_Freq_Lo 
                    ldb      tempW1+1 
                    jsr      Sound_Byte_raw 
                    lda      #PSG_Ch2_Freq_Hi 
                    ldd      tempW1 
                    jsr      Sound_Byte_raw 
;
                    dec      sfxC2W1                      ; or it'll never end! 
                    dec      tempB3                       ; envelope counter 
                    rts      

; ============================
Do_Sound_FX_C2UpBurst: 
                    lda      sfxC2W1 
                    cmpa     #0 
                    lbeq     Do_Sound_FX_C2SoundOff 
                                                          ;set mixer byte 
                    lda      #PSG_OnOff 
                    ldb      #Ch2_Tone_Off 
                    jsr      Sound_Byte_raw 
                    lda      #PSG_OnOff 
                    ldb      #Ch2_Noise_On 
                    jsr      Sound_Byte_raw 
                    ldx      #Up_Burst_Noise 
                    lda      sfxC2W1 
                    lda      a,x 
                    sta      tempW1 
                                                          ;set pitch ch3 
                    lda      #PSG_Noise 
                    ldb      tempW1 
                    jsr      Sound_Byte_raw 
                    lda      #PSG_Ch1_Vol 
                    ldb      #0 
                    jsr      Sound_Byte_raw 
                    lda      #PSG_Ch3_Vol 
                    ldb      #0 
                    jsr      Sound_Byte_raw 
                    lda      #PSG_Ch2_Vol 
                    ldb      #15 
                    jsr      Sound_Byte_raw 
                    dec      sfxC2W1 
                    rts      

Do_Sound_FX_C2DownBurst: 
; extra bit to clean registers BS.
                    lda      #PSG_Ch2_Freq_Lo 
                    ldb      #0 
                    jsr      Sound_Byte_raw 
                    lda      #PSG_Ch2_Freq_Hi 
                    ldb      #0 
                    jsr      Sound_Byte_raw 
; extra bit to clear registers above
                    lda      sfxC2W1 
                    cmpa     #0 
                    beq      Do_Sound_FX_C2SoundOff 
                                                          ;set mixer byte 
                    lda      #PSG_OnOff 
                    ldb      #Ch2_Tone_Off 
                    jsr      Sound_Byte_raw 
                    lda      #PSG_OnOff 
                    ldb      #Ch2_Noise_On 
                    jsr      Sound_Byte_raw 
                    ldx      #Down_Burst_Noise 
                    lda      sfxC2W1 
                    lda      a,x 
                    sta      tempW1 
                    lda      #PSG_Noise 
                    ldb      tempW1 
                    jsr      Sound_Byte_raw 
                    lda      #PSG_Ch1_Vol 
                    ldb      #0 
                    jsr      Sound_Byte_raw 
                    lda      #PSG_Ch3_Vol 
                    ldb      #0 
                    jsr      Sound_Byte_raw 
                    lda      #PSG_Ch2_Vol 
                    ldb      #15 
                    jsr      Sound_Byte_raw 
                    dec      sfxC2W1 
                    rts      

;=========================
;=Channel 3 FX ======
Do_Sound_FX_C3: 
                                                          ;channel 3 sfx 
                    lda      sfxC3ID 
                    cmpa     #SHOT 
                    beq      Do_Sound_FX_C3Shot 
; silence functions                                        
Do_Sound_FX_C3Mute: 
                                                          ;set vol ch3 
                    lda      #PSG_Ch3_Vol 
                    ldb      #0 
                    jsr      Sound_Byte_raw 
                    rts      

;Do_Sound_FX_C1SoundOff:    DUPLICATE FUNCTION LABEL commenting 
                                                          ;nothing playing 
;                    lda      #PSG_Ch1_Vol 
;                    ldb      #0 
;                    jsr      Sound_Byte_raw 
;                    lda      #0 
;                    sta      sfxC1ID 
;                    jsr      Clear_Sound 
;                    rts      

Do_Sound_FX_C2Mute: 
Do_Sound_FX_C2SoundOff: 
                                                          ; rts 
                                                          ;nothing playing 
                    lda      #PSG_Env_Shape 
                    ldb      #0 
                    jsr      Sound_Byte_raw 
;
                    lda      #PSG_Ch2_Vol 
                    ldb      #0 
                    jsr      Sound_Byte_raw 
;
;
;                    lda      #PSG_OnOff 
;                    ldb      #Ch2_Noise_Off | #Ch2_Tone_Off 
;                    jsr      Sound_Byte_raw 
;
;                    lda      #PSG_Ch2_Freq_Lo 
;                    ldb      #0 
;                    jsr      Sound_Byte_raw 
;
;                    lda      #PSG_Ch2_Freq_Hi 
;                    ldb      #0 
;                    jsr      Sound_Byte_raw 
                                                          ; jsr Clear_Sound 
                    rts      

Do_Sound_FX_C3SoundOff: 
                                                          ;nothing playing 
                    lda      #0 
                    sta      sfxC3ID 
                    rts      

;=================
Do_Sound_FX_C3Shot: 
                    lda      sfxC3W1 
                    cmpa     #0 
                    beq      Do_Sound_FX_C3SoundOff 
                                                          ;set mixer byte 
                    lda      #PSG_OnOff 
                    ldb      #Ch3_Tone_On                 ;| Ch1_Noise_On | Ch2_Noise_On 
                                                          ; ldb #Ch_All_On 
                    jsr      Sound_Byte_raw 
                    ldx      #Shot_Freq 
                    lda      sfxC3W1 
                    lsla                                  ; 2 bytes 
                    ldd      a,x 
                    std      tempW1 
                                                          ;set pitch ch3 
                    lda      #PSG_Ch3_Freq_Lo 
                    ldb      tempW1+1 
                    jsr      Sound_Byte_raw 
                    lda      #PSG_Ch3_Freq_Hi 
                    ldb      tempW1 
                    jsr      Sound_Byte_raw 
                    lda      #PSG_Ch3_Vol 
                    ldb      #13 
                    jsr      Sound_Byte_raw 
                    dec      sfxC3W1 
                    rts      

; SFX FUNCTIONS - CALL THESE TO START SFX        
SFX_Shot: 
                    lda      sfxC3W1 
                    cmpa     #10                          ; time before starting new sound 
                                                          ; over existing 
                    bgt      notrumpshot 
;                    lda      sfxC3ID 
;                    bne      notrumpshot 
                    lda      #SHOT 
                    sta      sfxC3ID 
                    lda      #12                          ; length 
                    sta      sfxC3W1 
notrumpshot 
                    rts      

SFX_Ghost_Spawn: 
                    lda      #GHOST_SPAWN 
                    sta      sfxC1ID 
                    lda      #33 
                    sta      sfxC1W1 
                    rts      

SFX_Arrow_Spawn: 
                    lda      #ARROW_SPAWN 
                    sta      sfxC1ID 
                    lda      #33                          ; ? length 
                    sta      sfxC1W1 
                    rts      

SFX_CB_Bounce: 
                                                          ; can skip a bounce if it means not truncating Ghost|Arrow Spawn 
                    lda      sfxC1ID 
                    bne      notrumpcb 
                    lda      #CB_BOUNCE 
                    sta      sfxC1ID 
                    lda      #4 
                    sta      sfxC1W1 
notrumpcb 
                    rts      

SFX_Up_Burst: 
                    lda      #UPBURST 
                    sta      sfxC2ID 
                    lda      #31 
                    sta      sfxC2W1 
                    rts      

SFX_Down_Burst: 
                    lda      #DOWNBURST 
                    sta      sfxC2ID 
                    lda      #31 
                    sta      sfxC2W1 
                    rts      

SFX_Bloop: 
                    lda      #BLOOP 
                    sta      sfxC1ID 
                    lda      #3 
                    sta      sfxC1W1 
                    rts      

SFX_Pip: 
                    lda      #PIP 
                    sta      sfxC1ID 
                    lda      #3 
                    sta      sfxC1W1 
                    rts      
SFX_RevBloop: 
                    lda      #REVBLOOP 
                    sta      sfxC1ID 
                    lda      #3 
                    sta      sfxC1W1 
                    rts    

SFX_VertMove: 
                    lda      #VERTMOVE 
                    sta      sfxC2ID 
                    lda      #15                          ; length 15 frames 
                    sta      sfxC2W1 
                                                          ;initial env 
                    lda      #16 
                    sta      tempB3 
                                                          ;set env shape (triggers envelope start) 
                    lda      #PSG_Env_Shape 
                    ldb      #%00001110 
                    jsr      Sound_Byte_raw 
                    rts      
