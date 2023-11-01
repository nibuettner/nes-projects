.include "inc/constants.inc"

.segment "ZEROPAGE"
.importzp PLAYER_X, PLAYER_Y, PLAYER_SPRITE_ATTRS

.segment "CODE"
.import main
.export reset_handler

.proc reset_handler
  SEI
  LDA #$00
  STA PPUCTRL           ; disable NMI
  STA PPUMASK           ; disable rendering
  STA APUSOUND          ; disable APU sound
  STA DMCIRQ            ; disable DMC IRQ
  LDA #$40
  STA APUIRQ            ; disable APU IRQ
        
  CLD
  LDX #$FF
  TXS                   ; initialize stack
  
VBLANKWAIT:
  BIT PPUSTATUS
  BPL VBLANKWAIT

; clear all RAM to 0
	LDA #$00
	LDX #$00
CLEAR_RAM:
  STA $0000,X
  STA $0100,X
  STA $0200,X
  STA $0300,X
  STA $0400,X
  STA $0500,X
  STA $0600,X
  STA $0700,X
  INX
  BNE CLEAR_RAM

  ; place all sprites offscreen at Y=255
  LDA #$FF
  LDX #$00
CLEAR_OAM:
	STA OAMBUFF,X       ; set sprite y-positions off the screen
	INX                  ; a sprite takes 4 bytes, so these INXes
	INX                  ; move the address pointer to
	INX                  ; the y position of the
	INX                  ; next sprite
	BNE CLEAR_OAM

  LDX #$00
  LDY #$20
CLEAR_VRAM:
  TXA
  LDY #$20
  STY PPUADDR
  STA PPUADDR
  LDY #$10
@CLEAR_VRAM_LOOP:
  STA PPUDATA
  INX
  BNE @CLEAR_VRAM_LOOP
  DEY
  BNE @CLEAR_VRAM_LOOP

  LDX #$00
CLEAR_PALETTE:
	LDA #$3F
	STA PPUADDR
	STX PPUADDR ; #$00
	LDA #$0F
	LDX #$20
@CLEAR_PALETTE_LOOP:
	STA PPUDATA
	DEX
	BNE @CLEAR_PALETTE_LOOP

VBLANKWAIT2:
	BIT PPUSTATUS
	BPL VBLANKWAIT2

  ; initialize zero-page values
  LDA #$80
  STA PLAYER_X
  LDA #$A0
  STA PLAYER_Y
  LDA #%01000000
  STA PLAYER_SPRITE_ATTRS

  LDA #$00
  LDX #$00
  LDY #$00

  JMP main
.endproc