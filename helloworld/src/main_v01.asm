.include "constants.inc"
.include "header.inc"

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

  ;write first bg palette
  LDA #$29
  STA PPUDATA          ;store value in accumulator to PPUDATA at address PPUADDR (which is the address of the first color of the first palette)
  LDA #$29
  STA PPUDATA          ;no need to increase PPUADDR as each write to PPUDATA increases PPUADDR by 1
  LDA #$29
  STA PPUDATA          ;no need to increase PPUADDR as each write to PPUDATA increases PPUADDR by 1
  LDA #$29
  STA PPUDATA          ;no need to increase PPUADDR as each write to PPUDATA increases PPUADDR by 1

  ;write first sprite palette
  LDX PPUSTATUS        ;load PPUSTATUS to reset address latch
  LDX #$3f             ;load #$3f to X register
  STX PPUADDR          ;store value in X register to high byte of PPUADDR
  LDX #$10             ;load #$10 to X register -> #$3f10 is address for first sprite palette
  STX PPUADDR          ;store value in X register to low byte of PPUADDR
  LDA #$0f
  STA PPUDATA          ;store value in accumulator to PPUDATA at address PPUADDR (which is the address of the first color of the first palette)
  LDA #$15
  STA PPUDATA          ;no need to increase PPUADDR as each write to PPUDATA increases PPUADDR by 1
  LDA #$05
  STA PPUDATA          ;no need to increase PPUADDR as each write to PPUDATA increases PPUADDR by 1
  LDA #$30
  STA PPUDATA          ;no need to increase PPUADDR as each write to PPUDATA increases PPUADDR by 1

  ;write sprite data
  LDA #$70             ;Y-coord of first sprite
  STA $0200
  LDA #$01             ;tile number of first sprite from sprite set
  STA $0201
  LDA #%00000000       ;attributes of first sprite
  STA $0202
  LDA #$80             ;X-coord of first sprite
  STA $0203

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
.byte $29, $29, $29, $29
.byte $0f, $0f, $0f, $0f
.byte $0f, $0f, $0f, $0f
.byte $0f, $0f, $0f, $0f
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