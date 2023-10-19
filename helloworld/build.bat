ca65 helloworld/src/main.asm -o helloworld/build/main.o
ca65 helloworld/src/reset.asm -o helloworld/build/reset.o

ld65 helloworld/build/reset.o ^
  helloworld/build/main.o ^
  -C helloworld/nes.cfg -o helloworld/helloworld.nes

start helloworld/helloworld.nes