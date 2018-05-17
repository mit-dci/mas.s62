
CFLAGS=-Wall -Wextra -Werror -W -g
LFLAGS=-lsecp256k1
SOURCES= main.c hash_impl.c util.c

all: $(SOURCES)
	gcc $(CFLAGS) $(LFLAGS) $(SOURCES) -o taproot
