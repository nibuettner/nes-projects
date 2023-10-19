.segment "HEADER"  ;16 bytes - https://www.nesdev.org/wiki/INES
.byte $4e, $45, $53, $1a ;Magic string that always begins an iNES header: NES<eof>
.byte $02        ;amount of PRG ROM in 16K units ($02 means 32KB storage)
.byte $01        ;amount of CHR ROM in 8K units ($01 means 8KB storage)
.byte %00000001  ;mapper, mirroring, battery, trainer: vertical mirroring, no save RAM, no mapper
.byte %00000000  ;mapper, VS/Playchoice, NES 2.0: no special-case flags set, no mapper
.byte $00        ;no PRG-RAM present
.byte $00        ;NTSC format (?)