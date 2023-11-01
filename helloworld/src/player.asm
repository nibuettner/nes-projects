.include "inc/constants.inc"
.include "inc/backgrounds.inc"

.segment "ZEROPAGE"
.importzp PLAYER_X, PLAYER_Y, PLAYER_VEL_Y, PLAYER_DIR, PLAYER_SPRITE_ATTRS, PLAYER_STATE
.importzp JOYPAD1, JOYPAD2
.importzp COLLISION_MAP
.importzp TMP

.segment "CODE"
.export update_player
.export draw_player

.proc check_collision_d
  LDX PLAYER_X
  LDY PLAYER_Y

  JSR check_collision

  RTS
.endproc

.proc check_collision
; X / 64 + (Y/8) * 4
; X / 8 AND %00000111
  ; collision

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

; .proc jump
;   LDA PLAYER_STATE
;   ORA #%00000001        ; set jumping flag
;   STA PLAYER_STATE
;   ; LDA PLAYER_JMP_VEL
;   ; LDA #$04
;   ; STA PLAYER_VEL_Y

;   RTS
; .endproc

.proc check_input
; CHECK_BTN_SELECT:
;   LDA JOYPAD1
;   AND #BTN_SELECT
;   BEQ CHECK_BTN_START
; CHECK_BTN_START:
;   LDA JOYPAD1
;   AND #BTN_START
;   BEQ CHECK_LEFT

CHECK_LEFT:
  LDA JOYPAD1           ; load button presses
  AND #BTN_LEFT         ; filter out all but Left
  BEQ CHECK_RIGHT       ; if result is zero, left not pressed
  ; DEC PLAYER_X          ; If the branch is not taken, move player left
  SEC
  LDA PLAYER_X
  SBC #$01              ; TODO: Replace with speed variable
  STA PLAYER_X
  LDA #%01000000        ; mirror horizontally
  STA PLAYER_SPRITE_ATTRS
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
  STA PLAYER_SPRITE_ATTRS
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
  BEQ DIRECTIONS_DONE
  ;INC PLAYER_Y
  CLC
  LDA PLAYER_Y
  ADC #$01              ; TODO: Replace with speed variable
  STA PLAYER_Y

DIRECTIONS_DONE:

CHECK_BTN_A:
  LDA JOYPAD1
  AND #BTN_A
  BEQ STOP_JUMPING

JUMP:
  LDA PLAYER_STATE
  ORA #PLAYER_IS_JUMPING        ; set jumping flag
  ;AND #%11111101        ; reset falling flag
  AND #!PLAYER_IS_FALLING        ; reset falling flag
  ;AND #%11111011        ; reset on ground flag
  AND #!PLAYER_IS_ON_GROUND        ; reset on ground flag
  STA PLAYER_STATE
  LDA #PLAYER_JMP_VEL
  STA PLAYER_VEL_Y
  JMP SKIP_RESET_JUMP

STOP_JUMPING:
  LDA PLAYER_STATE
  AND #%11111110        ; reset jumping flag
  STA PLAYER_STATE
  ; LDA #$00
  ; STA PLAYER_VEL_Y

SKIP_RESET_JUMP:

  ; JSR jump
CHECK_BTN_B:
  LDA JOYPAD1
  AND #BTN_B
  ; JSR jump

DONE_CHECKING:

  RTS
.endproc

.proc update_player
  JSR check_input

  ; jumping
  LDA PLAYER_STATE
  AND #PLAYER_IS_JUMPING ; jump button is pressed
  BNE UPDATE_PLAYER_Y_VEL ; jump button is pressed

  ; jump button not pressed, gravity

  LDA PLAYER_STATE
  AND #PLAYER_IS_ON_GROUND ; player is on ground
  BNE NO_COLLISION_D

; STOP_JUMPING:
  LDA PLAYER_VEL_Y+1
  ; STA PLAYER_VEL_Y+1
  CLC
  ADC #$50              ; accumulate up to 255
  STA PLAYER_VEL_Y+1
  BCC SKIP_DEC_PLAYER_VEL_Y ; skip if < 255

  ; if carry set (PLAYER_VEL_Y+1 overflow), decrease Y velocity
; DEC_PLAYER_VEL_Y:
  DEC PLAYER_VEL_Y
  ; LDA PLAYER_VEL_Y
  ; SEC
  ; CMP #$04
  ; BCC SKIP_DEC_PLAYER_VEL_Y
  ; LDA #$04
  ; STA PLAYER_VEL_Y

SKIP_DEC_PLAYER_VEL_Y:
  LDA PLAYER_VEL_Y
  BNE :+
  ; if Y velocity is 0, switch to falling state
  LDA PLAYER_STATE
  AND #!PLAYER_IS_JUMPING        ; reset jumping flag
  ORA #PLAYER_IS_FALLING ; set falling flag
  STA PLAYER_STATE
: ; still moving upwards

UPDATE_PLAYER_Y_VEL:
  LDA PLAYER_Y
  SEC
  SBC PLAYER_VEL_Y
  STA PLAYER_Y

  ; LDA PLAYER_STATE
  ; AND #PLAYER_IS_FALLING ; check falling flag
  ; BEQ NO_COLLISION_D

  JSR check_collision_d
  BEQ NO_COLLISION_D

  ; collision downwards
  ; reset position
  LDA PLAYER_Y
  AND #%11111000
  STA PLAYER_Y
  LDA #$00
  STA PLAYER_VEL_Y
  LDA PLAYER_STATE
  AND #!PLAYER_IS_JUMPING ; reset jumping flag
  AND #!PLAYER_IS_FALLING ; reset falling flag
  ORA #PLAYER_IS_ON_GROUND ; set on ground flag
  STA PLAYER_STATE

NO_COLLISION_D:
  ; LDA PLAYER_STATE
  ; ORA #PLAYER_IS_FALLING ; set falling flag
  ; AND #%11111011        ; reset on ground flag
  ; STA PLAYER_STATE


  ; BEQ CONTINUE           ; no collision downwards
  ; ; collision downwards
  ; ; reset position
  ; LDA PLAYER_Y
  ; AND #%11111000
  ; STA PLAYER_Y
  ; LDA #$00
  ; STA PLAYER_VEL_Y

  ; JMP SKIP_ALL



  ; LDA PLAYER_Y
  ; SEC
  ; SBC PLAYER_VEL_Y
  ; STA PLAYER_Y

;   BEQ GRAVITY
;   ; BNE SKIP_GRAVITY

;   LDA #$01
;   STA PLAYER_VEL_Y
;   LDA PLAYER_Y
;   SEC
;   SBC PLAYER_VEL_Y
;   STA PLAYER_Y

;   ; gravity
; GRAVITY:
;   ; INC PLAYER_VEL_Y
;   LDA #$01
;   STA PLAYER_VEL_Y
;   LDA PLAYER_Y
;   CLC
;   ADC PLAYER_VEL_Y
;   STA PLAYER_Y


;   LDA PLAYER_X
;   CMP #$e0              ; PLAYER_X - 240 - sets carry flag
;   BCC not_at_right_edge ; carry flag will only be cleared when PLAYER_X < 240

;   ; PLAYER_X > A -> we want to turn around and start moving left
;   LDA #$00              ; direction "left"
;   STA PLAYER_DIR        ; start moving left
;   LDA #%01000000        ; mirror horizontally
;   STA PLAYER_SPRITE_ATTRS
;   JMP direction_set     ; we already chose a direction, so we can skip the left side check

; not_at_right_edge:      ; we might be at left edge, though
;   LDA PLAYER_X
;   CMP #$10              ; PLAYER_X - 16 - sets carry flag
;   BCS direction_set     ; carry flag will be set (not be cleared) if PLAYER_X > 16

;   ; PLAYER_X < A -> we want to turn around and start moving right
;   LDA #$01              ; direction "right"
;   STA PLAYER_DIR        ; start moving right
;   LDA #%00000000        ; no mirroring
;   STA PLAYER_SPRITE_ATTRS

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
  LDA PLAYER_Y          ; load value of PLAYER_Y var from zero page into A
  SBC #$08
  STA $0200             ; store value in the first byte of the sprite which is pos Y
  LDA #$01              ; second sprite in tileset
  STA $0201             ; second byte is sprite index (first is X position -> $0200)
  LDA PLAYER_SPRITE_ATTRS      ; sprite attributes (use palette 0)
  STA $0202             ; third byte is sprite attributes
  LDA PLAYER_X          ; load value of PLAYER_X var from zero page into A
  SBC #$04
  STA $0203             ; store value in the fourth byte of the sprite which is pos X

  ; LDA #$0F              ; second sprite in tileset
  ; STA $0205             ; second byte is sprite index (first is X position -> $0200)
  ; LDA PLAYER_SPRITE_ATTRS      ; sprite attributes (use palette 0)
  ; STA $0206             ; third byte is sprite attributes

  ; LDA PLAYER_Y          ; load value of PLAYER_Y var from zero page into A
  ; SBC #$08
  ; STA $0204             ; store value in the first byte of the sprite which is pos Y
  ; LDA PLAYER_X          ; load value of PLAYER_X var from zero page into A
  ; SBC #$04
  ; STA $0207             ; store value in the fourth byte of the sprite which is pos X

  RTS
.endproc