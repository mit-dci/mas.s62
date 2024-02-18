CC = g++
CFLAGS = -g -v -std=c++11

sha256_std: sha256_std.cpp sha256.o
	$(CC) $(CFLAGS) -o sha256_std.out sha256.o sha256_std.cpp

sha256.o: sha256.h sha256.cpp
	$(CC) $(CFLAGS) -c sha256.cpp

lamport.o: lamport.h lamport.cpp
	$(CC) $(CFLAGS) -c lamport.cpp

lamport_test: lamport.o sha256.o
	$(CC) $(CFLAGS) -o lamport_test.out sha256.o lamport.o lamport_test.cpp

forge: lamport.o sha256.o
	$(CC) $(CFLAGS) -o forge.out sha256.o lamport.o forge.cpp

run_forge: forge
	taskset -c 0-9 ./forge.out 

forge_cuda: lamport.o sha256.o
	nvcc -o forge_cuda.out sha256.o lamport.o  forge_cuda.cu

clean:
	rm -f *.out > /dev/null 2>&1
	rm -f *.o > /dev/null 2>&1