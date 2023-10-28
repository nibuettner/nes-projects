cd helloworld
del helloworld.nes
del build\main.o
del build\player.o
del build\background.o
del build\reset.o

ca65 src/main.asm -o build/main.o
ca65 src/player.asm -o build/player.o
ca65 src/background.asm -o build/background.o
ca65 src/reset.asm -o build/reset.o

ld65 build/reset.o ^
  build/player.o ^
  build/background.o ^
  build/main.o ^
  -C nes.cfg -o helloworld.nes

start helloworld.nes