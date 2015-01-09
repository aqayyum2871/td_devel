OBJ = tptbincheck.o CalcNumberColumns.o tptbinview.o tptbintestfile.o isBitSet.o tptbinrc.o \
      isInt.o UniqSortIntArray.o tptbin2csv.o CursesInitialSetup.o
EXE = tptbincheck tptbintestfile tptbinrc tptbin2csv

all: $(OBJ) $(EXE)

clean:
	rm -f $(OBJ) $(EXE)

install:
	cp -p $(EXE) $(HOME)/bin

%.o: %.c
	gcc -Wall -g -c $<

tptbin2csv: tptbin2csv.o CalcNumberColumns.o isBitSet.o isInt.o UniqSortIntArray.o
	gcc -o tptbin2csv tptbin2csv.o CalcNumberColumns.o isBitSet.o isInt.o UniqSortIntArray.o

tptbincheck: tptbincheck.o CalcNumberColumns.o isBitSet.o isInt.o
	gcc -o tptbincheck tptbincheck.o CalcNumberColumns.o isBitSet.o isInt.o

tptbinview: tptbinview.o CalcNumberColumns.o isBitSet.o CursesInitialSetup.o
	gcc -o tptbinview tptbinview.o CalcNumberColumns.o isBitSet.o CursesInitialSetup.o -lncurses

tptbintestfile: tptbintestfile.o isInt.o
	gcc -o tptbintestfile tptbintestfile.o isInt.o

tptbinrc: tptbinrc.o
	gcc -o tptbinrc tptbinrc.c
