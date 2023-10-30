.include "inc/constants.inc"

.importzp ENEMY_Xs, ENEMY_Ys
.importzp ENEMY_X_VELs, ENEMY_Y_VELs
.importzp ENEMY_FLAGs, CURRENT_ENEMY, CURRENT_ENEMY_TYPE
.importzp ENEMY_TIMER

.segment "CODE"

.export setup_enemies
.export update_enemy
.export draw_enemy
.export process_enemies

.proc setup_enemies
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; set up enemy slots
  LDA #$00
  STA CURRENT_ENEMY
  STA CURRENT_ENEMY_TYPE

  LDX #$00
ENEMY1_DATA:
  LDA #$00
  STA ENEMY_FLAGs, X
  LDA #$01
  STA ENEMY_Y_VELs, X
  LDA #$01
  STA ENEMY_X_VELs, X
  INX
  CPX #$03
  BNE ENEMY1_DATA
  ; X is now $03, no need to reset

ENEMY2_DATA:
  LDA #$01
  STA ENEMY_FLAGs, X
  LDA #$02
  STA ENEMY_Y_VELs, X
  LDA #$01
  STA ENEMY_X_VELs, X
  INX
  CPX #$05
  BNE ENEMY2_DATA

  LDX #$00
  LDA #$10

SETUP_ENEMY_X:
  STA ENEMY_Xs, X
  CLC
  ADC #$20
  INX
  CPX #MAX_NUM_ENEMIES
  BNE SETUP_ENEMY_X

  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  
  RTS
.endproc

.proc update_enemy
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; Check if this enemy is active.
  LDX CURRENT_ENEMY
  LDA ENEMY_FLAGs, X
  AND #%10000000
  BEQ DONE

  ; Update X position.
  LDA ENEMY_Xs, X
  CLC
  ADC ENEMY_X_VELs, X
  STA ENEMY_Xs, X

  ; Update Y position.
  LDA ENEMY_Ys, X
  CLC
  ADC ENEMY_Y_VELs, X
  STA ENEMY_Ys, X

  ; Set inactive if Y >= 239
  CPY #239
  BCC DONE
  LDA ENEMY_FLAGs, X
  EOR #%10000000
  STA ENEMY_FLAGs, X

DONE:
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP

  RTS
.endproc

.proc draw_enemy
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; check if the enemy is active.
  LDX CURRENT_ENEMY     ; store what is at address of CURRENT_ENEMY in X
  LDA ENEMY_FLAGs, X    ; load the ENEMY_FLAG at pos X into A
  AND #%10000000        ; check if active, active state is stored in bit 7 of ENEMY_FLAG
  BNE CONTINUE          ; if active, handle the enemy
  JMP DONE              ; if not active, jump to end
  ; NOTE: we could just use BEQ DONE here but we will probably have
  ;       DONE be more than 128 bytes away from here, which the CPU would not be able to handle

CONTINUE:
  ; Find the appropriate OAM address offset
  ; by starting at $0210 (after the player
  ; sprites) and adding $10 for each enemy
  ; until we hit the current index.
  LDA #$10              ; init A with #$10 (will result in OAM address $0210)
  LDX CURRENT_ENEMY
  BEQ OAM_ADDRESS_FOUND ; if CURRENT_ENEMY is 0, no offset needed

FIND_ADDRESS:
  CLC
  ADC #$10              ; increase A by 4 bytes (size of one sprite)
  DEX                   ; decrement X
  BNE FIND_ADDRESS      ; if X is not yet 0, we did not decrement it enough
                        ; we have to countinue searching for the enemies OAM address
OAM_ADDRESS_FOUND:
  LDX CURRENT_ENEMY     ; reload CURRENT_ENEMY into X
  TAY                   ; use Y to hold OAM address offset

  ; find the current enemy's type and
  ; store it for later use. The enemy type
  ; is in bits 0-2 of enemy_flags.
  LDA ENEMY_FLAGs, X
  AND #%00000111
  STA CURRENT_ENEMY_TYPE

  ; write sprite info to OAM
  LDA ENEMY_Ys, X       ; Y pos on screen
  STA $0200, Y
  INY
  LDX CURRENT_ENEMY_TYPE
  LDA ENEMY_SPRITES, X  ; sprite address
  STA $0200, Y
  INY
  LDA ENEMY_PALETTES, X ; sprite palette
  STA $0200, Y
  INY
  LDX CURRENT_ENEMY
  LDA ENEMY_Xs, X       ; X pos on screen
  STA $0200, Y
  INY

  ; this is for enemies consisting of more than 1 sprite
  ; ; enemy top-right
  ; LDA enemy_y_pos, X
  ; STA $0200, Y
  ; INY
  ; LDX current_enemy_type
  ; LDA enemy_top_rights, X
  ; STA $0200, Y
  ; INY
  ; LDA enemy_palettes, X
  ; STA $0200, Y
  ; INY
  ; LDX CURRENT_ENEMY
  ; LDA enemy_x_pos, X
  ; CLC
  ; ADC #$08
  ; STA $0200, Y
  ; INY

  ; ; enemy bottom-left
  ; LDA enemy_y_pos, X
  ; CLC
  ; ADC #$08
  ; STA $0200, Y
  ; INY
  ; LDX current_enemy_type
  ; LDA enemy_bottom_lefts, X
  ; STA $0200,Y
  ; INY
  ; LDA enemy_palettes, X
  ; STA $0200, Y
  ; INY
  ; LDX CURRENT_ENEMY
  ; LDA enemy_x_pos, X
  ; STA $0200, Y
  ; INY

  ; ; enemy bottom-right
  ; LDA enemy_y_pos, X
  ; CLC
  ; ADC #$08
  ; STA $0200, Y
  ; INY
  ; LDX current_enemy_type
  ; LDA enemy_bottom_rights, X
  ; STA $0200,Y
  ; INY
  ; LDA enemy_palettes, X
  ; STA $0200,Y
  ; INY
  ; LDX CURRENT_ENEMY
  ; LDA enemy_x_pos, X
  ; CLC
  ; ADC #$08
  ; STA $0200, Y

DONE:
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
  
  RTS
.endproc

.proc process_enemies
  ; Push registers onto the stack
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; Start with enemy zero.
  LDX #$00

ENEMY:
  STX CURRENT_ENEMY
  LDA ENEMY_FLAGs, X
  ; Check if active (bit 7 set)
  AND #%10000000
  BEQ SPAWN_OR_TIMER
  ; If we get here, the enemy is active,
  ; so call update_enemy
  JSR update_enemy
  ; Then, get ready for the next loop.
  JMP NEXT_ENEMY_IN_LOOP

SPAWN_OR_TIMER: ; enemy is not active
  ; start a timer if it is not already running.
  LDA ENEMY_TIMER
  BEQ SPAWN_ENEMY ; if zero, time to spawn
  CMP #20 ; otherwise, see if it's running
  ; if carry cleared, the timer is between 0 and 20 frames,
  ; it is already running
  BCC NEXT_ENEMY_IN_LOOP

  ; if carry is set, enemy_timer > 20 frames
  ; we need to start the timer
  LDA #20
  STA ENEMY_TIMER
  JMP NEXT_ENEMY_IN_LOOP

SPAWN_ENEMY:
	; Set this slot as active
  ; (set bit 7 to "1")
  LDA ENEMY_FLAGs, X
  ORA #%10000000
  STA ENEMY_FLAGs, X
  ; Set y position to zero
  LDA #$00
  STA ENEMY_Ys, X
  ; IMPORTANT: reset the timer!
  LDA #$FF
  STA ENEMY_TIMER

NEXT_ENEMY_IN_LOOP:
  INX                   ; increment enemy counter
  CPX #MAX_NUM_ENEMIES      ; are all enemies processed?
  BNE ENEMY             ; if no, continue to next enemy in loop

  ; all enemies were processed
  ; decrement enemy spawn timer if 20 or less
  ; (and not zero)
  LDA ENEMY_TIMER
  BEQ DONE              ; if timer is 0, DONE; will spawn an inactive enemy next loop
  CMP #20               
  BEQ DECREMENT         ; if timer is 20, decrement
  BCS DONE              ; timer between 0 and 19 (?)

DECREMENT:
  DEC ENEMY_TIMER

DONE:
  ; Restore registers, then return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP

  RTS
.endproc

.segment "RODATA"
ENEMY_SPRITES:
.byte $20, $21
; enemy_top_rights:
; .byte $0b, $0e
; enemy_bottom_lefts:
; .byte $0a, $0f
; enemy_bottom_rights:
; .byte $0c, $10

ENEMY_PALETTES:
.byte $02, $02