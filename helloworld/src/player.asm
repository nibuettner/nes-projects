.include "inc/constants.inc"

.segment "ZEROPAGE"
.importzp PLAYER_X, PLAYER_Y, PLAYER_DIR, PLAYER_ATTRS

.segment "CODE"
.export update_player
.export draw_player
.proc update_player
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  LDA PLAYER_X
  CMP #$e0              ; PLAYER_X - 240 - sets carry flag
  BCC not_at_right_edge ; carry flag will only be cleared when PLAYER_X < 240

  ; PLAYER_X > A -> we want to turn around and start moving left
  LDA #$00              ; direction "left"
  STA PLAYER_DIR        ; start moving left
  LDA #%01000000        ; mirror horizontally
  STA PLAYER_ATTRS
  JMP direction_set     ; we already chose a direction, so we can skip the left side check

not_at_right_edge:      ; we might be at left edge, though
  LDA PLAYER_X
  CMP #$10              ; PLAYER_X - 16 - sets carry flag
  BCS direction_set     ; carry flag will be set (not be cleared) if PLAYER_X > 16

  ; PLAYER_X < A -> we want to turn around and start moving right
  LDA #$01              ; direction "right"
  STA PLAYER_DIR        ; start moving right
  LDA #%00000000        ; no mirroring
  STA PLAYER_ATTRS

direction_set:
  ; now, actually update PLAYER_X
  LDA PLAYER_DIR        ; can be 0 or 1
  CMP #$01              ; PLAYER_DIR - 1
  BEQ move_right        ; move right when PLAYER_DIR was 1 before, otherwise move left

; move_left:
  DEC PLAYER_X
  JMP exit_subroutine
move_right:
  INC PLAYER_X
  ; no need for JMP exit_subroutine

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
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; write player sprite
  ;.byte $70, $01, %00000000, $40
  LDA #$01              ; second sprite in tileset
  STA $0201             ; second byte is sprite index (first is X position -> $0200)
  LDA PLAYER_ATTRS      ; sprite attributes (use palette 0)
  STA $0202             ; third byte is sprite attributes

  LDA PLAYER_Y          ; load value of PLAYER_Y var from zero page into A
  STA $0200             ; store value in the first byte of the sprite which is pos Y
  LDA PLAYER_X          ; load value of PLAYER_X var from zero page into A
  STA $0203             ; store value in the fourth byte of the sprite which is pos X

  ; restore registers and return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP

  RTS
.endproc