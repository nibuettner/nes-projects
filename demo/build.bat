ca65 demo/src/cart.s -o demo/build/cart.o

ld65 demo/build/cart.o -t nes -o demo/cart.nes

start demo/cart.nes