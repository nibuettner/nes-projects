.include "inc/constants.inc"
.include "inc/header.inc"
.include "inc/backgrounds.inc"

.import update_player
.import draw_player
.import draw_background
.import reset_handler
.import read_input
.import setup_enemies
.import process_enemies
.import draw_enemy

.segment "ZEROPAGE" ; reserve memory in fast zero-page RAM and assign to variables

SLEEPING: .res 1         ; nothing more to do than waiting for VBLANK

TMP: .res 1
TMPLOBYTE: .res 1
TMPHIBYTE: .res 1
.exportzp TMP, TMPLOBYTE, TMPHIBYTE

JOYPAD1: .res 1
JOYPAD2: .res 1
.exportzp JOYPAD1, JOYPAD2

PLAYER_X: .res 1        ; reserve 1 byte on zero page for player x pos
PLAYER_Y: .res 1        ; reserve 1 byte on zero page for player y pos
PLAYER_DIR: .res 1      ; reserve 1 byte on zero page for player direction
PLAYER_ATTRS: .res 1    ; reserve 1 byte on zero page for player attributes
.exportzp PLAYER_X, PLAYER_Y, PLAYER_DIR, PLAYER_ATTRS

SCROLL: .res 1          ; scroll position
PPUCTRL_SETTINGS: .res 1

; --- ENEMIES -----------------------------------------------------------------
; enemy object pool
ENEMY_Xs: .res MAX_NUM_ENEMIES
ENEMY_Ys: .res MAX_NUM_ENEMIES
ENEMY_X_VELs: .res MAX_NUM_ENEMIES
ENEMY_Y_VELs: .res MAX_NUM_ENEMIES
ENEMY_FLAGs: .res MAX_NUM_ENEMIES
CURRENT_ENEMY: .res 1
CURRENT_ENEMY_TYPE: .res 1
ENEMY_TIMER: .res 1
.exportzp ENEMY_Xs, ENEMY_Ys
.exportzp ENEMY_X_VELs, ENEMY_Y_VELs
.exportzp ENEMY_FLAGs, CURRENT_ENEMY, CURRENT_ENEMY_TYPE
.exportzp ENEMY_TIMER

; player bullet pool
BULLET_Xs: .res MAX_NUM_BULLETS
BULLET_Ys: .res MAX_NUM_BULLETS

; special addresses to handle important events
.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler
; /.segment "VECTORS"

.segment "CODE" ; 32KB as defined in the header
.proc irq_handler ; dunno
  RTI
.endproc ; /.proc irq_handler

; main processing
.export main ; export so main can be referenced in other asm files
.proc main
  LDA #0              ; scroll max value
  STA SCROLL

  LDA #%00000001
  STA JOYPAD1

  LDA #%00000001
  STA JOYPAD2

; --- LOAD PALETTES -----------------------------------------------------------
  LDX PPUSTATUS         ; load PPUSTATUS to reset address latch
  LDX #$3F              ; load #$3f to X register
  STX PPUADDR           ; store value in X register to high byte of PPUADDR
  LDX #$00              ; load #$00 to X register -> #$3f00 is address for first bg palette
  STX PPUADDR           ; store value in X register to low byte of PPUADDR

  LDX #$00              ; start loop at 0
LOAD_PALETTES:
  LDA PALETTES, X       ; load value at address of (PALETTES+X) into A
  STA PPUDATA           ; store value of A (color of palette at address (PALETTES+X)) at PPUDATA
                        ; PPUADDR is increased each time we write to PPUDATA, so no need to do anything about this here
  INX                   ; increase loop index
  CPX #$20              ; check if loop index in X equals 32 (8 x 4 bytes for 8 palettes)
  BNE LOAD_PALETTES     ; as long as zero flag is not set, loop index is not 32, so continue looping

; --- BACKGROUNDS -------------------------------------------------------------
  LDA #<BACKGROUND1     ; load low byte of BACKGROUND's address
  STA TMPLOBYTE         ; store the address in TMPLOBYTE in the zero page
  LDA #>BACKGROUND1     ; load high byte of BACKGROUND's address
  STA TMPHIBYTE         ; store the address in TMPHIBYTE in the zero page
  LDX #$20
  JSR draw_background

  LDA #<BACKGROUND2     ; load low byte of BACKGROUND's address
  STA TMPLOBYTE         ; store the address in TMPLOBYTE in the zero page
  LDA #>BACKGROUND2     ; load high byte of BACKGROUND's address
  STA TMPHIBYTE         ; store the address in TMPHIBYTE in the zero page
  LDX #$24
  JSR draw_background

; --- PLAYER SPRITES (just for testing) -----------------------------------------
;   LDX #$04              ; loop index, skip first sprite as it is handled by draw_player
; LOAD_SPRITES:
;   LDA SPRITES, X        ; load data at address (SPRITES+X) into A
;   STA $0200, X          ; store data from A at address ($0200+X) -> sprite buffer
;   INX                   ; increase loop index
;   CPX #$10              ; compare X with 16 (4 sprites, 16 bytes; we want to check for equality)
;   BNE LOAD_SPRITES      ; continue loop if X ne 16 (as result of comparison before)
;                         ; sprites are now loaded into the CPU sprite buffer; during the next VBLANK, they will be transferred
;                         ; to the PPU OAM by the nmi_handler proc

  JSR setup_enemies

VBLANKWAIT:             ; wait for another vblank before continuing
  BIT PPUSTATUS
  BPL VBLANKWAIT

  LDA #%10010000        ; turn on NMIs, sprites use first pattern table
  STA PPUCTRL_SETTINGS  ; need to be stored so that we can switch name tables
  STA PPUCTRL
  LDA #%00011110        ; load PPUMASK value into the accumulator; this is the default with color, no 8px disables, bg and fg enabled and no color emphasized
  STA PPUMASK           ; tell the PPU to start drawing by storing the the mask value from the accumulator in the PPUMASK address

; --- MAIN GAME LOOP ----------------------------------------------------------
MAINGAMELOOP:
  ; main game processing
  JSR read_input

  ; update tiles *after* DMA transfer
  JSR update_player
  JSR draw_player

  ; process enemies
	JSR process_enemies

	; draw all enemies
	LDA #$00
	STA CURRENT_ENEMY
DRAW_ENEMIES:
	JSR draw_enemy
	INC CURRENT_ENEMY
	LDA CURRENT_ENEMY
	CMP #MAX_NUM_ENEMIES
	BNE DRAW_ENEMIES

  ; scrolling
  LDA SCROLL
  CMP #255              ; did we scroll to the end of a nametable?
                        ; as we increase SCROLL. check for 255
  BNE SET_SCROLL_POS

  ; if yes, update base nametable settings
  LDA PPUCTRL_SETTINGS
  EOR #%00000001        ; flip bit #0 to its opposite 00: $2000, 01: $2400
  STA PPUCTRL_SETTINGS

SET_SCROLL_POS:
  INC SCROLL            ; scroll to the left, if SCROLL is 255 this will wrap to 0

  ; nothing more to do, wait for next VBLANK
  INC SLEEPING
SLEEP:
  LDA SLEEPING
  BNE SLEEP
  JMP MAINGAMELOOP      ; will only be executed when NMI sets SLEEPING back to 0
.endproc ; /.proc main

; --- NMI HANDLER -------------------------------------------------------------
; is called every frame on VBLANK
; handle all graphics updates here
.proc nmi_handler
  LDA #$00              ; load literal value #$00 into accumulator
  STA OAMADDR           ; prepare OAM; we want to write sprite data to beginning of OAM
  LDA #$02              ; load high byte #$02 into acc
  STA OAMDMA            ; write high byte #$02 into OAMDMA; tells the PPU to initiate a high-speed transfer of the 256 bytes from $0200-$02ff into OAM

  ; load PPUCTRL_SETTINGS (which we might have changed in our main loop) and update PPUCTRL
  LDA PPUCTRL_SETTINGS
  STA PPUCTRL

  ; scrolling
  LDA SCROLL            ; X scroll first
  STA PPUSCROLL
  LDA #$00              ; then Y scroll
  STA PPUSCROLL

  ; set SLEEPING to 0 so that MAINGAMELOOP can continue
  LDA #$00
  STA SLEEPING

  RTI                   ; return from interrupt
.endproc ; /.proc nmi_handler
; /.segment "CODE"

; --- DATA --------------------------------------------------------------------
; read-only data
.segment "RODATA"
PALETTES:
  ; backgrounds
  .byte $0f,$00,$10,$30
  .byte $0f,$01,$21,$30
  .byte $0f,$07,$17,$26
  .byte $0f,$0b,$1b,$2a

  ; sprites
  .byte $0f,$11,$01,$30
  .byte $0f,$15,$05,$30
  .byte $0f,$29,$19,$30
  .byte $0f,$2C,$1C,$30

SPRITES:
  ;     Y-coord of sprite
  ;     |   tile number of sprite from sprite set
  ;     |   |   attributes of sprite
  ;     |   |   |         X-coord of sprite
  ;     |   |   |         |
  .byte $70,$01,%00000000,$40
  .byte $70,$02,%00000001,$4A
  .byte $70,$01,%00000010,$54
  .byte $70,$02,%00000011,$5E
; /.segment "RODATA"

; --- GRAPHICS ----------------------------------------------------------------
; graphical data
.segment "CHR" ; 8KB as defined in the header
.incbin "../chr/sprites.chr" ; 4KB sprites table
.incbin "../chr/backgrounds.chr" ; 4KB backgrounds table
; /.segment "CHARS"