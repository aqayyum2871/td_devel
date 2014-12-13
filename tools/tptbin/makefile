OBJ = tptbincheck.o CalcNumberColumns.o tptbinview.o tptbintestfile.o tptbinslice.o isBitSet.o tptbinrc.o tptbincut.o isInt.o
EXE = tptbincheck tptbintestfile tptbinslice tptbinrc tptbincut

all: $(EXE)

clean:
	rm -f $(OBJ) $(EXE)

install:
	cp -p $(EXE) $(HOME)/bin

%.o: %.c
	gcc -Wall -g -c $<

tptbincheck: tptbincheck.o CalcNumberColumns.o isBitSet.o isInt.o
	gcc -o tptbincheck tptbincheck.o CalcNumberColumns.o isBitSet.o isInt.o

tptbincut: tptbincut.o CalcNumberColumns.o isBitSet.o isInt.o
	gcc -o tptbincut tptbincut.o CalcNumberColumns.o isBitSet.o isInt.o

tptbinview: tptbinview.o CalcNumberColumns.o isBitSet.o
	gcc -o tptbinview tptbinview.o CalcNumberColumns.o isBitSet.o -lncurses

tptbintestfile: tptbintestfile.o isInt.o
	gcc -o tptbintestfile tptbintestfile.o isInt.o

tptbinslice: tptbinslice.o isInt.o
	gcc -o tptbinslice tptbinslice.o isInt.o

tptbinrc: tptbinrc.o
	gcc -o tptbinrc tptbinrc.c
