.include "inc/constants.inc"
.include "inc/header.inc"
.include "inc/backgrounds.inc"

.segment "ZEROPAGE" ; reserve memory in fast zero-page RAM and assign to variables
TMP: .res 1
TMPLOBYTE: .res 1
TMPHIBYTE: .res 1

PLAYER_X: .res 1        ; reserve 1 byte on zero page for player x pos
PLAYER_Y: .res 1        ; reserve 1 byte on zero page for player y pos
PLAYER_DIR: .res 1      ; reserve 1 byte on zero page for player direction
PLAYER_ATTRS: .res 1    ; reserve 1 byte on zero page for player attributes

SCROLL: .res 1          ; scroll position
PPUCTRL_SETTINGS: .res 1
.exportzp TMPLOBYTE, TMPHIBYTE, PLAYER_X, PLAYER_Y, PLAYER_DIR, PLAYER_ATTRS ; export for use in other asm files

; special addresses to handle important events
.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler
; /.segment "VECTORS"

.import update_player
.import draw_player
.import draw_background
.import reset_handler

.segment "CODE" ; 32KB as defined in the header
.proc irq_handler ; dunno
  RTI
.endproc ; /.proc irq_handler

; is called every frame on VBLANK
; handle all graphics updates here
.proc nmi_handler
  LDA #$00              ; load literal value #$00 into accumulator
  STA OAMADDR           ; prepare OAM; we want to write sprite data to beginning of OAM
  LDA #$02              ; load high byte #$02 into acc
  STA OAMDMA            ; write high byte #$02 into OAMDMA; tells the PPU to initiate a high-speed transfer of the 256 bytes from $0200-$02ff into OAM

  ; update tiles *after* DMA transfer
  JSR update_player
  JSR draw_player

  ; scrolling
  LDA SCROLL
  CMP #255              ; did we scroll to the end of a nametable?
                        ; as we increase SCROLL. check for 255
  BNE SET_SCROLL_POS
  ;BCC SET_SCROLL_POS

  ; if yes, update base nametable
  LDA PPUCTRL_SETTINGS
  EOR #%00000001        ; flip bit #0 to its opposite 00: $2000, 01: $2400
  STA PPUCTRL_SETTINGS
  STA PPUCTRL
  ; scroll is already at #255, so no need to change anything there
  ;LDA #255                ; reset scroll position
  ;STA SCROLL

SET_SCROLL_POS:
  ;LDA TMP              ; load TMP into A
  ;BNE NO_SCROLL        ; only scroll when A is 0, otherwise decrease TMP

  INC SCROLL            ; scroll to the left, if SCROLL is 255 this will wrap to 0
  LDA SCROLL            ; X scroll first
  STA PPUSCROLL
  LDA #$00              ; then Y scroll
  STA PPUSCROLL
  INC TMP
  ; LDA TMP             ; even slower scrolling
  ; ADC #2              ; even slower scrolling
  ; STA TMP             ; even slower scrolling
  ;JMP SCROLL_DONE

; NO_SCROLL:
;   DEC TMP               ; only DEC TMP if we did not scroll

; SCROLL_DONE:

  RTI                   ; return from interrupt
.endproc ; /.proc nmi_handler

; main processing
.export main ; export so main can be referenced in other asm files
.proc main
  LDA #0              ; scroll max value
  STA SCROLL

; --- LOAD PALETTES -----------------------------------------------------------
  LDX PPUSTATUS         ; load PPUSTATUS to reset address latch
  LDX #$3f              ; load #$3f to X register
  STX PPUADDR           ; store value in X register to high byte of PPUADDR
  LDX #$00              ; load #$00 to X register -> #$3f00 is address for first bg palette
  STX PPUADDR           ; store value in X register to low byte of PPUADDR

  LDX #$00              ; start loop at 0
LOAD_PALETTES:
  LDA PALETTES,X        ; load value at address of (PALETTES+X) into A
  STA PPUDATA           ; store value of A (color of palette at address (PALETTES+X)) at PPUDATA
                        ; PPUADDR is increased each time we write to PPUDATA, so no need to do anything about this here
  INX                   ; increase loop index
  CPX #$20              ; check if loop index in X equals 32 (8 x 4 bytes for 8 palettes)
  BNE LOAD_PALETTES     ; as long as zero flag is not set, loop index is not 32, so continue looping

; --- LOAD SPRITES ------------------------------------------------------------
  LDX #$04              ; loop index
LOAD_SPRITES:
  LDA SPRITES,X         ; load data at address (SPRITES+X) into A
  STA $0200,X           ; store data from A at address ($0200+X) -> sprite buffer
  INX                   ; increase loop index
  CPX #$10              ; compare X with 16 (4 sprites, 16 bytes; we want to check for equality)
  BNE LOAD_SPRITES      ; continue loop if X ne 16 (as result of comparison before)
                        ; sprites are now loaded into the CPU sprite buffer; during the next VBLANK, they will be transferred
                        ; to the PPU OAM by the nmi_handler proc

; --- LOAD BACKGROUNDS --------------------------------------------------------
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

VBLANKWAIT:             ; wait for another vblank before continuing
  BIT PPUSTATUS
  BPL VBLANKWAIT

  LDA #%10010000        ; turn on NMIs, sprites use first pattern table
  STA PPUCTRL_SETTINGS  ; need to be stored so that we can switch name tables
  STA PPUCTRL
  LDA #%00011110        ; load PPUMASK value into the accumulator; this is the default with color, no 8px disables, bg and fg enabled and no color emphasized
  STA PPUMASK           ; tell the PPU to start drawing by storing the the mask value from the accumulator in the PPUMASK address

INFINITELOOP:
  JMP INFINITELOOP

.endproc ; /.proc main
; /.segment "CODE"

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

; graphical data
.segment "CHR" ; 8KB as defined in the header
.incbin "../chr/sprites.chr" ; 4KB sprites table
.incbin "../chr/backgrounds.chr" ; 4KB backgrounds table
; /.segment "CHARS"