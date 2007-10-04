#
#	Makefile for EDIF parser.
#

# CFLAGS = -DDEBUG
# CFLAGS = -O
CFLAGS = -g

SOURCES = edif.y

all  :	e2net ppedif e2lib e2sch

ppedif : ppedif.o
	cc $(CFLAGS) ppedif.c -o ppedif

e2net :	ed.h e2net.o edif.o
	cc $(CFLAGS) e2net.o edif.o -o e2net

e2lib :	ed.h eelibsl.h e2lib.o edif.o savelib.o
	cc $(CFLAGS) e2lib.o edif.o savelib.o -o e2lib

e2sch :	ed.h e2sch.o edif.o
	cc $(CFLAGS) e2sch.o edif.o -o e2sch

savelib : fctsys.h eelibsl.h savelib.o 
	cc $(CFLAGS) -c savelib.c

edif :	ed.h edif.o 
	cc $(CFLAGS) -c edif.c

// main.o : main.c
edif.o : edif.c

edif.c : edif.y
	bison -t -v -d edif.y 
	cp edif.tab.c edif.c

#	mv y.tab.c edif.c

# edif.y : edif.y.1 edif.y.2
# 	cat edif.y.1 edif.y.2 > edif.y

clean :
	rm *.o edif.c edif.output edif.tab.c edif.tab.h e2sch e2net ppedif e2lib
