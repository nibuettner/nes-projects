.include "constants.inc"
.include "header.inc"

.segment "CODE" ;32KB as defined in the header
.proc irq_handler
  RTI
.endproc ;/.proc irq_handler

.proc nmi_handler
  RTI
.endproc ;/.proc nmi_handler

.import reset_handler ;import reset_handler proc from different file

.export main ;export so main can be referenced in other asm files
.proc main
  LDX PPUSTATUS        ;load PPUSTATUS to reset address latch
  LDX #$3f             ;load #$3f to X register
  STX PPUADDR          ;store value in X register to high byte of PPUADDR
  LDX #$00             ;load #$00 to X register
  STX PPUADDR          ;store value in X register to low byte of PPUADDR
  LDA #$29             ;load value #$29 into accumulator (will be interpreted as the color green in the PPU later)
  STA PPUDATA          ;store value in accumulator to PPUDATA at address PPUADDR (which is the address of the first color of the first palette)
  LDA #%00011110       ;load PPUMASK value into the accumulator; this is the default with color, no 8px disables, bg and fg enabled and no color emphasized
  STA PPUMASK          ;tell the PPU to start drawing by storing the the mask value from the accumulator in the PPUMASK address

INFINITELOOP:
  JMP INFINITELOOP

.endproc ;/.proc main
;/.segment "CODE"

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler
;/.segment "VECTORS"

.segment "CHR" ;8KB as defined in the header
.res 8192
;/.segment "CHARS"