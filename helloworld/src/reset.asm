.include "constants.inc"

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
  JMP main
.endproc