cd helloworld
del helloworld.nes
del build\main.o
del build\player.o
del build\background.o
del build\reset.o
del build\input.o
del build\enemies.o

ca65 src/main.asm -o build/main.o
ca65 src/player.asm -o build/player.o
ca65 src/background.asm -o build/background.o
ca65 src/reset.asm -o build/reset.o
ca65 src/input.asm -o build/input.o
ca65 src/enemies.asm -o build/enemies.o

ld65 ^
  build/enemies.o ^
  build/input.o ^
  build/reset.o ^
  build/player.o ^
  build/background.o ^
  build/main.o ^
  -C nes.cfg -o helloworld.nes

start helloworld.nes