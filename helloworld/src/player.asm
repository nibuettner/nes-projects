.include "inc/constants.inc"
.include "inc/backgrounds.inc"

.segment "ZEROPAGE"
.importzp PLAYER_X, PLAYER_Y, PLAYER_VEL_Y, PLAYER_DIR, PLAYER_SPRITE_ATTRS, PLAYER_STATE
.importzp JOYPAD1, JOYPAD2
.importzp COLLISION_MAP
.importzp TMP, TMPLOBYTE, TMPHIBYTE
.importzp TOPTEXT, TOPNUMBERS

.segment "CODE"
.export update_player
.export draw_player

.proc check_collision_d
  LDX PLAYER_X
  LDY PLAYER_Y

  JSR check_collision

  RTS
.endproc

.proc check_collision_u
  LDX PLAYER_X
  LDA PLAYER_Y
  SEC
  SBC #$08
  ; STA PLAYER_Y
  TAY
  

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

CHECK_BTN_SELECT:
  LDA JOYPAD1
  AND #BTN_SELECT
  BEQ CHECK_BTN_START
  JMP DONE_CHECKING
CHECK_BTN_START:
  LDA JOYPAD1
  AND #BTN_START
  BEQ CHECK_LEFT
  JMP DONE_CHECKING

CHECK_LEFT:
  LDA JOYPAD1           ; load button presses
  AND #BTN_LEFT         ; filter out all but Left
  BEQ CHECK_RIGHT          ; if result is zero, left not pressed
  ;BEQ DIRECTIONS_DONE          ; if result is zero, left not pressed
  ; DEC PLAYER_X          ; If the branch is not taken, move player left
  LDA PLAYER_X
  SEC
  SBC #$01              ; TODO: Replace with speed variable
  STA PLAYER_X
  LDA #%01000000        ; mirror horizontally
  STA PLAYER_SPRITE_ATTRS

  ; #DEBUG
  LDY #$00
  LDA #'L'
  STA TOPTEXT,Y

  JMP CHECK_UP
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

  ; #DEBUG
  LDY #$00
  LDA #'R'
  STA TOPTEXT,Y
CHECK_UP:
  LDA JOYPAD1
  AND #BTN_UP
  BEQ CHECK_DOWN
  ;DEC PLAYER_Y
  ; SEC
  ; LDA PLAYER_Y
  ; SBC #$01              ; TODO: Replace with speed variable
  ; STA PLAYER_Y
  JMP DIRECTIONS_DONE
CHECK_DOWN:
  LDA JOYPAD1
  AND #BTN_DOWN
  BEQ DIRECTIONS_DONE
  ;INC PLAYER_Y
  ; CLC
  ; LDA PLAYER_Y
  ; ADC #$01              ; TODO: Replace with speed variable
  ; STA PLAYER_Y

DIRECTIONS_DONE:
  ; LDY #$04
  ; LDA #'X'
  ; STA TOPTEXT,Y

  ; LDY #$05
  ; LDA #'X'
  ; STA TOPTEXT,Y

CHECK_BTN_A:
  LDA JOYPAD1
  AND #BTN_A

  ; TODO: Don't STA PLAYER_STATE if I am not jumping anymore
  BEQ STOP_JUMPING

JUMP:
  LDA PLAYER_STATE
  ORA #PLAYER_IS_JUMPING        ; set jumping flag
  ; AND #%11111001
  ; ORA #%00000001
  ; ; AND #%11111101        ; reset falling flag
  ; ; AND #!PLAYER_IS_FALLING        ; reset falling flag
  ; ; AND #%11111011        ; reset on ground flag
  ; ; AND #!PLAYER_IS_ON_GROUND        ; reset on ground flag
  STA PLAYER_STATE
  ; ; LDA #PLAYER_JMP_VEL
  ; ; STA PLAYER_VEL_Y
  JMP CHECK_BTN_B

STOP_JUMPING:
  LDA PLAYER_STATE
  AND #%11111110
  ; AND #!PLAYER_IS_JUMPING        ; reset jumping flag
  ; TODO: Don't STA PLAYER_STATE if I am not jumping anymore
  STA PLAYER_STATE


SKIP_JUMPING:

  ; JSR jump
CHECK_BTN_B:
  LDA JOYPAD1
  AND #BTN_B
  ; JSR jump

DONE_CHECKING:

  RTS
.endproc

; TODO: Check if these PLAYER_STATES are actually necessary:
; PLAYER_IS_ON_GROUND
; PLAYER_IS_FALLING

.proc update_player

  ; #DEBUG
  LDY #$00
  LDA #' '
  STA TOPTEXT,Y

  LDY #$01
  LDA #' '
  STA TOPTEXT,Y

  LDY #$02
  LDA #' '
  STA TOPTEXT,Y

  LDY #$03
  LDA #' '
  STA TOPTEXT,Y

  LDY #$04
  LDA #' '
  STA TOPTEXT,Y

  LDY #$05
  LDA #' '
  STA TOPTEXT,Y

  LDY #$06
  LDA #' '
  STA TOPTEXT,Y
  ; /#DEBUG


  JSR check_input

  ; is player jumping?
  LDA PLAYER_STATE
  AND #PLAYER_IS_JUMPING ; jump button is pressed
  BNE JUMP_PRESSED ; jump button is pressed

  LDA PLAYER_STATE
  AND #PLAYER_IS_ON_GROUND ; player is on ground
  BNE CHECK_COLLISION_D ; player is on ground

IN_AIR: ; gravity
  ; #DEBUG
  LDY #$01
  LDA #'A'
  STA TOPTEXT,Y

  ; we're not jumping but we are in air
  ; accumulate velocity change (sub pixel stuff)
  LDA PLAYER_STATE
  ; AND #!PLAYER_IS_ON_GROUND        ; reset on ground flag
  AND #%11111011
  ORA #PLAYER_IS_FALLING ; set falling flag
  STA PLAYER_STATE

  LDA PLAYER_VEL_Y+1    ; byte PLAYER_VEL_Y+1 holds accumulator
  CLC
  ADC #GRAVITY              ; accumulate up to 255 by adding #$50 each frame
  STA PLAYER_VEL_Y+1    ; store accumulated value
  ;BCC APPLY_Y_VELOCITY ; skip if < 255
  BCS :+ ; skip if < 255
  JMP APPLY_Y_VELOCITY

:
  ; if carry set (PLAYER_VEL_Y+1 overflow), decrease Y velocity
  DEC PLAYER_VEL_Y
  JMP APPLY_Y_VELOCITY

JUMP_PRESSED:
  ; #DEBUG
  LDY #$01
  LDA #'J'
  STA TOPTEXT,Y

  LDA #PLAYER_JMP_VEL
  STA PLAYER_VEL_Y

  LDA PLAYER_STATE
  AND #%11111001 ; reset on ground and falling
  ; AND #!PLAYER_IS_FALLING
  STA PLAYER_STATE

  JMP APPLY_Y_VELOCITY

CHECK_COLLISION_U:
  JSR check_collision_u
  BEQ SKIP_COLLISION_D

  LDY #$01
  LDA #' '
  STA TOPTEXT,Y

  LDY #$03
  LDA #'U'
  STA TOPTEXT,Y

  ; collision upwards
  ; reset position
  LDA PLAYER_Y
  CLC
  ADC #$08

  AND #%11111000
  STA PLAYER_Y
  LDA #$00
  STA PLAYER_VEL_Y
  
  ; LDA PLAYER_STATE
  ; AND #!PLAYER_IS_FALLING ; reset falling flag
  ; ORA #PLAYER_IS_ON_GROUND ; set on ground flag
  ; STA PLAYER_STATE
  ; JMP SKIP_COLLISION_D

; TODO: don't check when moving upwards
CHECK_COLLISION_D:
  JSR check_collision_d
  BEQ NO_COLLISION_D

  LDA PLAYER_STATE
  AND #PLAYER_IS_ON_GROUND
  ; we're already on ground, so no need to update player y position again
  BNE SKIP_COLLISION_D

  ; #DEBUG
  LDY #$01
  LDA #' '
  STA TOPTEXT,Y

  ; #DEBUG
  LDY #$02
  LDA #'D'
  STA TOPTEXT,Y

  ; collision downwards
  ; reset position
  LDA PLAYER_Y
  AND #%11111000
  STA PLAYER_Y
  LDA #$00
  STA PLAYER_VEL_Y
  
  LDA PLAYER_STATE
  AND #%11111101 ; reset falling flag
  ORA #PLAYER_IS_ON_GROUND ; set on ground flag
  STA PLAYER_STATE
  JMP SKIP_COLLISION_D

NO_COLLISION_D:
  ; #DEBUG
  LDY #$02
  LDA #' '
  STA TOPTEXT,Y

  LDA PLAYER_STATE
  ; ORA #PLAYER_IS_FALLING ; set falling flag
  AND #%11111011 ; reset on ground flag
  STA PLAYER_STATE
  JMP SKIP_COLLISION_D

; apply before checking for collision
APPLY_Y_VELOCITY: 
  LDA PLAYER_Y
  SEC
  SBC PLAYER_VEL_Y
  STA PLAYER_Y
  LDA PLAYER_VEL_Y
  BPL CHECK_COLLISION_U
  JMP CHECK_COLLISION_D

TEST:
  ; ; #DEBUG
  ; LDY #$02
  ; LDA #' '
  ; STA TOPTEXT,Y

SKIP_COLLISION_D:











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
  
  ; PLA
  ; TAY
  ; PLA
  ; TAX
  ; PLA
  ; PLP

  RTS
.endproc

.proc draw_player
  ; write player sprite
  ;.byte $70, $01, %00000000, $40
  LDA PLAYER_Y          ; load value of PLAYER_Y var from zero page into A
  SEC
  SBC #$08              ; move sprite up 1 tile
  STA $0200             ; store value in the first byte of the sprite which is pos Y
  LDA #$01              ; second sprite in tileset
  STA $0201             ; second byte is sprite index (first is X position -> $0200)
  LDA PLAYER_SPRITE_ATTRS      ; sprite attributes (use palette 0)
  STA $0202             ; third byte is sprite attributes
  LDA PLAYER_X          ; load value of PLAYER_X var from zero page into A
  SEC
  SBC #$04              ; move sprite to the left 1/2 of a tile
  STA $0203             ; store value in the fourth byte of the sprite which is pos X
  ; X:Y position of the sprite is selected so that the actual player position is
  ; in the middle of the bottom edge of the sprite

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