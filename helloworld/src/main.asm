.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"
PLAYER_X: .res 1       ;reserve 1 byte on zero page for player x pos
PLAYER_Y: .res 1       ;reserve 1 byte on zero page for player y pos
PLAYER_DIR: .res 1     ;reserve 1 byte on zero page for player direction
.exportzp PLAYER_X, PLAYER_Y ;export for use in other asm files

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
  LDA #$00
	STA $2005
	STA $2005
  RTI                  ;return from interrupt
.endproc ;/.proc nmi_handler

;called when powering on or resetting the nes
.import reset_handler ;import reset_handler proc from different file

;main processing
.export main ;export so main can be referenced in other asm files
.proc main
;WRITE PALETTES
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

;LOAD SPRITES
  LDX #$00             ;loop index
LOAD_SPRITES:
  LDA SPRITES,X      ;load data at address (SPRITES+X) into A
  STA $0200,X        ;store data from A at address ($0200+X) -> sprite buffer
  INX                ;increase loop index
  CPX #$10           ;compare X with 8 (two sprites, 8 bytes; we want to check for equality)
  BNE LOAD_SPRITES   ;continue loop if X ne 8 (as result of comparison before)
  ;sprites are now loaded into the CPU sprite buffer; during the next VBLANK, they will be transferred
  ;to the PPU OAM by the nmi_handler proc

;BACKGROUNDS
  ;write a nametable
  LDA PPUSTATUS
  LDA #$21
  STA PPUADDR
  LDA #$26
  STA PPUADDR
  LDX #$07
  STX PPUDATA

  LDA PPUSTATUS
  LDA #$21
  STA PPUADDR
  LDA #$27
  STA PPUADDR
  LDX #$fe
  STX PPUDATA

  LDA PPUSTATUS
  LDA #$21
  STA PPUADDR
  LDA #$28
  STA PPUADDR
  LDX #$fe
  STX PPUDATA

  LDA PPUSTATUS
  LDA #$21
  STA PPUADDR
  LDA #$46
  STA PPUADDR
  LDX #$fe
  STX PPUDATA

  LDA PPUSTATUS
  LDA #$21
  STA PPUADDR
  LDA #$47
  STA PPUADDR
  LDX #$fe
  STX PPUDATA

  LDA PPUSTATUS
  LDA #$21
  STA PPUADDR
  LDA #$48
  STA PPUADDR
  LDX #$fe
  STX PPUDATA

  ;finally, attribute table
  LDA PPUSTATUS
  LDA #$23
  STA PPUADDR
  LDA #$d1
  STA PPUADDR
  LDA #%00000100
  STA PPUDATA

  LDA PPUSTATUS
  LDA #$23
  STA PPUADDR
  LDA #$d2
  STA PPUADDR
  LDA #%00000000
  STA PPUDATA

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