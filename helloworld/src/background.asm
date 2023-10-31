.include "inc/constants.inc"

.segment "ZEROPAGE"
.importzp TMPLOBYTE, TMPHIBYTE

.segment "CODE"
.export draw_background
.export draw_text

.proc draw_background
; TMPLOBYTE contains low byte of background nametable definition
; TMPHIBYTE contains high byte of background nametable definition
; X contains high byte of the PPU nametable address (#$20, #$24, #$28, #$2C)

; --- LOAD BACKGROUNDS --------------------------------------------------------
  LDA PPUSTATUS         ; read PPU status to reset the high/low latch
  TXA                   ; load PPU nametable address high byte from X to A
  STA PPUADDR           ; write the high byte of $2000 address
  LDA #$00
  STA PPUADDR           ; write the low byte of $2000 address
  
  LDY #$00              ; start Y loop at 0
  LDX #$04              ; run the X loop 4 times -> 256 (Y; 1 byte) * 4 (X) = 1024
LOAD_BACKGROUND:
  LDA (TMPLOBYTE),Y     ; load a 16 bit address from TMPLOBYTE (starting with low byte) + Y, so we get the
                        ; 16 bit address of the current BACKGROUND tile in the loop
  STA PPUDATA           ; write to PPU
  INY                   ; Y++
  BNE LOAD_BACKGROUND   ; Y will be zero when it wraps; it has than run 256 times
                        ; so we start at Y = 0 again
  INC TMPHIBYTE         ; increase the address at ZP TMPHIBYTE by 1
                        ; so we went through 256 addresses of BACKGROUND and go to the next one
  DEX                   ; X-- so we can stop after running 4 times
  BNE LOAD_BACKGROUND   ; if X is not 0, continue the loop, otherwise break

  RTS
.endproc

.proc draw_text
  LDA PPUSTATUS         ; read PPU status to reset the high/low latch
  STX PPUADDR           ; write the high byte of $2000 address
  STY PPUADDR           ; write the low byte of $2000 address

  LDY #$00              ; start Y loop at 0
  LOAD_TEXT:
    LDA (TMPLOBYTE), Y
    BEQ EXIT
    CLC
    ADC #$99
    STA PPUDATA
    INY
    BNE LOAD_TEXT

EXIT:
  RTS
.endproc

; .proc draw_text_rep
;   LDX #$21              ; draw_text expects X and Y to contain tile indexes
;   LDY #$F0              ; of where the text is to be displayed

;   LDA PPUSTATUS         ; read PPU status to reset the high/low latch
;   STX PPUADDR           ; write the high byte of $2000 address
;   STY PPUADDR           ; write the low byte of $2000 address
  
;   .repeat .strlen("WASD"), I
;     lda #.strat("WASD", I)
;     CLC
;     ADC #$99
;     sta PPUDATA
;   .endrep

;   RTS
; .endproc