OBJ = tptbincheck.o CalcNumberColumns.o tptbinview.o tptbintestfile.o tptbinslice.o isBitSet.o
EXE = tptbincheck tptbinview tptbintestfile tptbinslice

all: tptbincheck tptbinview tptbintestfile tptbinslice

clean:
	rm -rf $(OBJ) $(EXE)

install:
	cp -p tptbincheck tptbinview tptbintestfile tptbinslice $(HOME)/bin

%.o: %.c
	gcc -Wall -g -c $<

tptbincheck: tptbincheck.o CalcNumberColumns.o isBitSet.o
	gcc -o tptbincheck tptbincheck.o CalcNumberColumns.o isBitSet.o

tptbinview: tptbinview.o
	gcc -o tptbinview tptbinview.o -lncurses

tptbintestfile: tptbintestfile.o
	gcc -o tptbintestfile tptbintestfile.o

tptbinslice: tptbinslice.o
	gcc -o tptbinslice tptbinslice.o
