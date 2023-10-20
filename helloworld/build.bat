cd helloworld
del helloworld.nes
del build\main.o
del build\reset.o

ca65 src/main.asm -o build/main.o
ca65 src/reset.asm -o build/reset.o

ld65 build/reset.o ^
  build/main.o ^
  -C nes.cfg -o helloworld.nes

start helloworld.nes