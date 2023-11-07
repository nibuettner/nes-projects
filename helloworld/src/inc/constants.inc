PPUCTRL              = $2000
PPUMASK              = $2001
PPUSTATUS            = $2002
PPUSCROLL            = $2005
PPUADDR              = $2006
PPUDATA              = $2007
OAMADDR              = $2003
DMCIRQ               = $4010
OAMDMA               = $4014
OAMBUFF              = $0200

APUSOUND             = $4015
APUIRQ               = $4017

CONTROLLER1          = $4016
CONTROLLER2          = $4017
BTN_RIGHT            = %00000001
BTN_LEFT             = %00000010
BTN_DOWN             = %00000100
BTN_UP               = %00001000
BTN_START            = %00010000
BTN_SELECT           = %00100000
BTN_B                = %01000000
BTN_A                = %10000000

MAX_NUM_ENEMIES      = 5
MAX_NUM_BULLETS      = 3

GRAVITY              = $50

PLAYER_WALK_SPEED    = $01
PLAYER_ACCEL         = $50
PLAYER_JMP_VEL       = $04

PLAYER_CAN_JUMP      = %00000001
PLAYER_IS_JUMPING    = %00000010
PLAYER_IS_FALLING    = %00000100
PLAYER_IS_ON_GROUND  = %00001000

PLAYER_STOP          = %00000000
PLAYER_MOVE_R        = %00010000
PLAYER_MOVE_L        = %00100000
PLAYER_DIR_Y_U       = %00000000

; -----------------------------------------------------------------------------

COLL_EMPTY_TILE_IDX     = $00 ; to $1F
COLL_SOLID_TILE_IDX     = $20 ; to $3F
COLL_PLATFORM_TILE_IDX  = $40 ; to $5F

COLL_EMPTY              = $00
COLL_SOLID              = $01
COLL_PLATFORM           = $10
