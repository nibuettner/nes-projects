.include "inc/constants.inc"

.segment "ZEROPAGE"
.importzp PAD1, PAD2

.segment "CODE"
.export read_input

.proc read_input
  LDA #$01
  STA CONTROLLER1
  LDA #$00
  STA CONTROLLER1

GET_CONTROLLER1_STATE:
  LDA CONTROLLER1       ; Get the next button state
  LSR A                 ; Shift the accumulator right one bit,
                        ; dropping the button state from bit 0
                        ; into the carry flag (!!!)
  ROL PAD1              ; Shift everything in pad1 left one bit,
                        ; moving the carry flag (!!!) into bit 0
                        ; (because rotation) and bit 7
                        ; of pad1 into the carry flag
  BCC GET_CONTROLLER1_STATE ; If the carry flag is still 0,
                        ; continue the loop. If the "1"
                        ; that we started with drops into
                        ; the carry flag, we are done.
GET_CONTROLLER2_STATE:
  LDA CONTROLLER2       ; Get the next button state
  LSR A                 ; Shift the accumulator right one bit,
                        ; dropping the button state from bit 0
                        ; into the carry flag (!!!)
  ROL PAD2              ; Shift everything in pad1 left one bit,
                        ; moving the carry flag (!!!) into bit 0
                        ; (because rotation) and bit 7
                        ; of pad1 into the carry flag
  BCC GET_CONTROLLER2_STATE ; If the carry flag is still 0,
                        ; continue the loop. If the "1"
                        ; that we started with drops into
                        ; the carry flag, we are done.
  RTS
.endproc