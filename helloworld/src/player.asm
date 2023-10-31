.include "inc/constants.inc"
.include "inc/backgrounds.inc"

.segment "ZEROPAGE"
.importzp PLAYER_X, PLAYER_Y, PLAYER_VEL_Y, PLAYER_DIR, PLAYER_ATTRS
.importzp JOYPAD1, JOYPAD2
.importzp COLLISION_MAP
.importzp TMP

.segment "CODE"
.export update_player
.export draw_player

.proc check_collision
; X / 64 + (Y/8) * 4
; X / 8 AND %00000111
  ; collision
  LDX PLAYER_X
  LDY PLAYER_Y

  TXA                   ; X / 64
  LSR
  LSR
  LSR
  LSR
  LSR
  LSR
  STA TMP
  TYA                   ; (Y / 8) * 4
  LSR
  LSR
  LSR
  ASL
  ASL
  CLC
  ADC TMP
  TAY                   ; player's byte index

  TXA
  LSR
  LSR
  LSR
  AND #%00000111
  TAX                   ; bitmask index

  LDA BG1_COLLISION, Y
  AND BG1_BITMASK, X

  RTS
.endproc

.proc update_player
  JSR check_collision

  BEQ GRAVITY
  ; BNE SKIP_GRAVITY

  LDA #$02
  STA PLAYER_VEL_Y
  LDA PLAYER_Y
  SEC
  SBC PLAYER_VEL_Y
  STA PLAYER_Y

  ; gravity
GRAVITY:
  ; INC PLAYER_VEL_Y
  LDA #$02
  STA PLAYER_VEL_Y
  LDA PLAYER_Y
  CLC
  ADC PLAYER_VEL_Y
  STA PLAYER_Y


  LDA JOYPAD1           ; load button presses
  AND #BTN_LEFT         ; filter out all but Left
  BEQ CHECK_RIGHT       ; if result is zero, left not pressed
  ; DEC PLAYER_X          ; If the branch is not taken, move player left
  SEC
  LDA PLAYER_X
  SBC #$01              ; TODO: Replace with speed variable
  STA PLAYER_X
  LDA #%01000000        ; mirror horizontally
  STA PLAYER_ATTRS
CHECK_RIGHT:
  LDA JOYPAD1
  AND #BTN_RIGHT
  BEQ CHECK_UP
  ; INC PLAYER_X
  CLC
  LDA PLAYER_X
  ADC #$01              ; TODO: Replace with speed variable
  STA PLAYER_X
  LDA #%00000000        ; no mirroring
  STA PLAYER_ATTRS
CHECK_UP:
  LDA JOYPAD1
  AND #BTN_UP
  BEQ CHECK_DOWN
  ;DEC PLAYER_Y
  SEC
  LDA PLAYER_Y
  SBC #$01              ; TODO: Replace with speed variable
  STA PLAYER_Y
CHECK_DOWN:
  LDA JOYPAD1
  AND #BTN_DOWN
  BEQ DONE_CHECKING
  ;INC PLAYER_Y
  CLC
  LDA PLAYER_Y
  ADC #$01              ; TODO: Replace with speed variable
  STA PLAYER_Y
DONE_CHECKING:

;   LDA PLAYER_X
;   CMP #$e0              ; PLAYER_X - 240 - sets carry flag
;   BCC not_at_right_edge ; carry flag will only be cleared when PLAYER_X < 240

;   ; PLAYER_X > A -> we want to turn around and start moving left
;   LDA #$00              ; direction "left"
;   STA PLAYER_DIR        ; start moving left
;   LDA #%01000000        ; mirror horizontally
;   STA PLAYER_ATTRS
;   JMP direction_set     ; we already chose a direction, so we can skip the left side check

; not_at_right_edge:      ; we might be at left edge, though
;   LDA PLAYER_X
;   CMP #$10              ; PLAYER_X - 16 - sets carry flag
;   BCS direction_set     ; carry flag will be set (not be cleared) if PLAYER_X > 16

;   ; PLAYER_X < A -> we want to turn around and start moving right
;   LDA #$01              ; direction "right"
;   STA PLAYER_DIR        ; start moving right
;   LDA #%00000000        ; no mirroring
;   STA PLAYER_ATTRS

; direction_set:
;   ; now, actually update PLAYER_X
;   LDA PLAYER_DIR        ; can be 0 or 1
;   CMP #$01              ; PLAYER_DIR - 1
;   BEQ move_right        ; move right when PLAYER_DIR was 1 before, otherwise move left

; ; move_left:
;   DEC PLAYER_X
;   JMP exit_subroutine
; move_right:
;   INC PLAYER_X
;   ; no need for JMP exit_subroutine
  
  RTS
.endproc

.proc draw_player
  ; write player sprite
  ;.byte $70, $01, %00000000, $40
  LDA #$01              ; second sprite in tileset
  STA $0201             ; second byte is sprite index (first is X position -> $0200)
  LDA PLAYER_ATTRS      ; sprite attributes (use palette 0)
  STA $0202             ; third byte is sprite attributes

  LDA PLAYER_Y          ; load value of PLAYER_Y var from zero page into A
  SBC #$08
  STA $0200             ; store value in the first byte of the sprite which is pos Y
  LDA PLAYER_X          ; load value of PLAYER_X var from zero page into A
  SBC #$04
  STA $0203             ; store value in the fourth byte of the sprite which is pos X

  ; LDA #$0F              ; second sprite in tileset
  ; STA $0205             ; second byte is sprite index (first is X position -> $0200)
  ; LDA PLAYER_ATTRS      ; sprite attributes (use palette 0)
  ; STA $0206             ; third byte is sprite attributes

  ; LDA PLAYER_Y          ; load value of PLAYER_Y var from zero page into A
  ; SBC #$08
  ; STA $0204             ; store value in the first byte of the sprite which is pos Y
  ; LDA PLAYER_X          ; load value of PLAYER_X var from zero page into A
  ; SBC #$04
  ; STA $0207             ; store value in the fourth byte of the sprite which is pos X

  RTS
.endproc