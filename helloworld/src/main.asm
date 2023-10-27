.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE" ;reserve memory in fast zero-page RAM and assign to variables
TMPLOBYTE: .res 1
TMPHIBYTE: .res 1
PLAYER_X: .res 1       ;reserve 1 byte on zero page for player x pos
PLAYER_Y: .res 1       ;reserve 1 byte on zero page for player y pos
PLAYER_DIR: .res 1     ;reserve 1 byte on zero page for player direction
PLAYER_ATTRS: .res 1     ;reserve 1 byte on zero page for player attributes
.exportzp PLAYER_X, PLAYER_Y, PLAYER_ATTRS ;export for use in other asm files

.segment "CODE" ;32KB as defined in the header

;dunno
.proc irq_handler
  RTI
.endproc ;/.proc irq_handler

;is called every frame on VBLANK
;handle all graphics updates here
.proc nmi_handler
  LDA #$00             ;load literal value #$00 into accumulator
  STA OAMADDR          ;prepare OAM; we want to write sprite data to beginning of OAM
  LDA #$02             ;load high byte #$02 into acc
  STA OAMDMA           ;write high byte #$02 into OAMDMA; tells the PPU to initiate a high-speed transfer of the 256 bytes from $0200-$02ff into OAM

  ; update tiles *after* DMA transfer
  JSR update_player
  JSR draw_player

  LDA #$00
	STA $2005
	STA $2005
  RTI                  ;return from interrupt
.endproc ;/.proc nmi_handler

.proc update_player
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  LDA PLAYER_X
  CMP #$e0                               ;PLAYER_X - 240 - sets carry flag
  BCC not_at_right_edge                  ;carry flag will only be cleared when PLAYER_X < 240

  ;PLAYER_X > A -> we want to turn around and start moving left
  LDA #$00                               ;direction "left"
  STA PLAYER_DIR                         ;start moving left
  LDA #%01000000                         ;mirror horizontally
  STA PLAYER_ATTRS
  JMP direction_set                      ;we already chose a direction, so we can skip the left side check

not_at_right_edge:                       ;we might be at left edge, though
  LDA PLAYER_X
  CMP #$10                               ;PLAYER_X - 16 - sets carry flag
  BCS direction_set                      ;carry flag will be set (not be cleared) if PLAYER_X > 16

  ;PLAYER_X < A -> we want to turn around and start moving right
  LDA #$01                               ;direction "right"
  STA PLAYER_DIR                         ;start moving right
  LDA #%00000000                         ;no mirroring
  STA PLAYER_ATTRS

direction_set:
  ;now, actually update PLAYER_X
  LDA PLAYER_DIR                         ;can be 0 or 1
  CMP #$01                               ;PLAYER_DIR - 1
  BEQ move_right                         ;move right when PLAYER_DIR was 1 before, otherwise move left

;move_left:
  DEC PLAYER_X
  JMP exit_subroutine
move_right:
  INC PLAYER_X
  ;no need for JMP exit_subroutine

exit_subroutine:
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.proc draw_player
  ;save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ;write player sprite
  ;.byte $70, $01, %00000000, $40
  LDA #$01             ;second sprite in tileset
  STA $0201            ;second byte is sprite index (first is X position -> $0200)
  LDA PLAYER_ATTRS     ;sprite attributes (use palette 0)
  STA $0202            ;third byte is sprite attributes

  LDA PLAYER_Y         ;load value of PLAYER_Y var from zero page into A
  STA $0200            ;store value in the first byte of the sprite which is pos Y
  LDA PLAYER_X         ;load value of PLAYER_X var from zero page into A
  STA $0203            ;store value in the fourth byte of the sprite which is pos X

  ;restore registers and return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

;called when powering on or resetting the nes
.import reset_handler ;import reset_handler proc from different file

;main processing
.export main ;export so main can be referenced in other asm files
.proc main

; --- LOAD PALETTES -----------------------------------------------------------
  LDX PPUSTATUS        ;load PPUSTATUS to reset address latch
  LDX #$3f             ;load #$3f to X register
  STX PPUADDR          ;store value in X register to high byte of PPUADDR
  LDX #$00             ;load #$00 to X register -> #$3f00 is address for first bg palette
  STX PPUADDR          ;store value in X register to low byte of PPUADDR

  LDX #$00             ;start loop at 0
LOAD_PALETTES:
  LDA PALETTES,X       ;load value at address of (PALETTES+X) into A
  STA PPUDATA          ;store value of A (color of palette at address (PALETTES+X)) at PPUDATA
  ;PPUADDR is increased each time we write to PPUDATA, so no need to do anything about this here
  INX                  ;increase loop index
  CPX #$20             ;check if loop index in X equals 32 (8 x 4 bytes for 8 palettes)
  BNE LOAD_PALETTES    ;as long as zero flag is not set, loop index is not 32, so continue looping

; --- LOAD SPRITES ------------------------------------------------------------
  LDX #$04             ;loop index
LOAD_SPRITES:
  LDA SPRITES,X        ;load data at address (SPRITES+X) into A
  STA $0200,X          ;store data from A at address ($0200+X) -> sprite buffer
  INX                  ;increase loop index
  CPX #$10             ;compare X with 16 (4 sprites, 16 bytes; we want to check for equality)
  BNE LOAD_SPRITES     ;continue loop if X ne 16 (as result of comparison before)
  ;sprites are now loaded into the CPU sprite buffer; during the next VBLANK, they will be transferred
  ;to the PPU OAM by the nmi_handler proc

; --- LOAD BACKGROUNDS --------------------------------------------------------
  LDA PPUSTATUS         ;read PPU status to reset the high/low latch
  LDA #$20
  STA PPUADDR           ;write the high byte of $2000 address
  LDA #$00
  STA PPUADDR           ;write the low byte of $2000 address

  LDA #<BACKGROUND      ;load low byte of BACKGROUND's address
  STA TMPLOBYTE         ;store the address in TMPLOBYTE in the zero page
  LDA #>BACKGROUND      ;load high byte of BACKGROUND's address
  STA TMPHIBYTE         ;store the address in TMPHIBYTE in the zero page
  LDY #$00              ;start Y loop at 0
  LDX #$04              ;run the X loop 4 times -> 256 (Y; 1 byte) * 4 (X) = 1024
LOAD_BACKGROUND:
  LDA (TMPLOBYTE),Y     ;load a 16 bit address from TMPLOBYTE (starting with low byte) + Y, so we get the
                        ;16 bit address of the current BACKGROUND tile in the loop
  STA PPUDATA           ;write to PPU
  INY                   ;Y++
  BNE LOAD_BACKGROUND   ;Y will be zero when it wraps; it has than run 256 times
                        ;so we start at Y = 0 again
  INC TMPHIBYTE         ;increase the address at ZP TMPHIBYTE by 1
                        ;so we went through 256 addresses of BACKGROUND and go to the next one
  DEX                   ;X-- so we can stop after running 4 times
  BNE LOAD_BACKGROUND   ;if X is not 0, continue the loop, otherwise break

; --- LOAD BACKGROUND ATTRIBUTES ----------------------------------------------
  LDA PPUSTATUS         ;read PPU status to reset the high/low latch
  LDA #$23
  STA PPUADDR           ;write the high byte of $23C0 address
  LDA #$C0
  STA PPUADDR           ;write the low byte of $23C0 address
  LDX #$00              ;start out at 0
LOAD_BGATTR:
  LDA BGATTR, X         ;load data from address (BGATTR + the value in x)
  STA PPUDATA           ;write to PPU
  INX                   ;X = X + 1
  CPX #$40              ;Compare X to hex $40, decimal 64 - copying 64 bytes
  BNE LOAD_BGATTR       ;Branch to LOAD_BGATTR if compare was Not Equal to zero
  ;if compare was equal to 64, keep going down

VBLANKWAIT:            ;wait for another vblank before continuing
  BIT PPUSTATUS
  BPL VBLANKWAIT

  LDA #%10010000       ;turn on NMIs, sprites use first pattern table
  STA PPUCTRL
  LDA #%00011110       ;load PPUMASK value into the accumulator; this is the default with color, no 8px disables, bg and fg enabled and no color emphasized
  STA PPUMASK          ;tell the PPU to start drawing by storing the the mask value from the accumulator in the PPUMASK address

INFINITELOOP:
  JMP INFINITELOOP

.endproc ;/.proc main
;/.segment "CODE"

;read-only data
.segment "RODATA"
PALETTES:
  .byte $0f, $09, $19, $29
  .byte $0f, $03, $13, $23
  .byte $0f, $05, $15, $25
  .byte $0f, $01, $11, $21

  .byte $0f, $15, $05, $30
  .byte $0f, $13, $03, $30
  .byte $0f, $12, $02, $30
  .byte $0f, $16, $06, $30

SPRITES:
  ;     Y-coord of sprite
  ;     |    tile number of sprite from sprite set
  ;     |    |    attributes of sprite
  ;     |    |    |          X-coord of sprite
  ;     |    |    |          |
  .byte $70, $01, %00000000, $40
  .byte $70, $02, %00000001, $4A
  .byte $70, $01, %00000010, $54
  .byte $70, $02, %00000011, $5E

BACKGROUND:
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$06,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$06,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$02,$00,$00,$00,$00,$00,$00,$00,$00,$05,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$05,$06,$00,$00,$00,$00,$00,$00,$00,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$01,$02,$00,$00,$00,$00,$06,$00,$00,$00,$00,$00,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$03,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$07,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$05,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$02,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$04,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$06,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$06,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

BGATTR:
  .byte %01010101,%01010101,%01010101,%01010101,%01010101,%01010101,%01010101,%01010101
  .byte %01010101,%01010101,%01010101,%01010101,%01010101,%01010101,%01010101,%01010101
  .byte %01010101,%01010101,%01010101,%01010101,%01010101,%01010101,%01010101,%01010101
  .byte %01010101,%01010101,%01010101,%01010101,%01010101,%01010101,%01010101,%01010101
  .byte %01010101,%01010101,%01010101,%01010101,%01010101,%01010101,%01010101,%01010101
  .byte %01010101,%01010101,%01010101,%01010101,%01010101,%01010101,%01010101,%01010101
  .byte %01010101,%01010101,%01010101,%01010101,%01010101,%01010101,%01010101,%01010101
  .byte %01010101,%01010101,%01010101,%01010101,%01010101,%01010101,%01010101,%01010101

;/.segment "RODATA"

;special addresses to handle important events
.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler
;/.segment "VECTORS"

;graphical data
.segment "CHR" ;8KB as defined in the header
.incbin "../chr/rom.chr"
;.res 8192
;/.segment "CHARS"