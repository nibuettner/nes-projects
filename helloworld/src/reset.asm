.include "constants.inc"

.segment "ZEROPAGE"
.importzp PLAYER_X, PLAYER_Y, PLAYER_ATTRS

.segment "CODE"
.import main
.export reset_handler
.proc reset_handler
  SEI
  CLD
  LDX #$00
  STX PPUCTRL
  STX PPUMASK

VBLANKWAIT:
  BIT PPUSTATUS
  BPL VBLANKWAIT

  LDX #$00
	LDA #$ff
CLEAR_OAM:
	STA $0200,X          ;set sprite y-positions off the screen
	INX                  ;a sprite takes 4 bytes, so these INXes
	INX                  ;move the address pointer to
	INX                  ;the y position of the
	INX                  ;next sprite
	BNE CLEAR_OAM

VBLANKWAIT2:
	BIT PPUSTATUS
	BPL VBLANKWAIT2

  ;initialize zero-page values
  LDA #$80
  STA PLAYER_X
  LDA #$a0
  STA PLAYER_Y
  LDA #%01000000
  STA PLAYER_ATTRS

  JMP main
.endproc