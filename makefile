#
#	Makefile for EDIF parser.
#

# CFLAGS = -DDEBUG
# CFLAGS = -O
CFLAGS = -g -DDEBUG

SOURCES = edif.y

edif :	edif.o 
	cc $(CFLAGS) edif.o -o edif

// main.o : main.c
edif.o : edif.c

edif.c : edif.y
	bison -t -v -d edif.y 
	cp edif.tab.c edif.c

#	mv y.tab.c edif.c

# edif.y : edif.y.1 edif.y.2
# 	cat edif.y.1 edif.y.2 > edif.y

clean :
	rm *.o edif.c edif.output edif.tab.c edif.tab.h edif
