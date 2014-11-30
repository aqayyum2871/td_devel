OBJ = getcols.o CalcNumberColumns.o tptbinview.o testfile.o

all: getcols CalcNumberColumns.o tptbinview testfile

clean:
	rm -rf $(OBJ)

%.o: %.c
	gcc -Wall -g -c $<

checkcols: checkcols.o CalcNumberColumns.o
	gcc -o checkcols checkcols.o CalcNumberColumns.o

tptbinview: tptbinview.o
	gcc -o tptbinview tptbinview.o

testfile: testfile.o
	gcc -o testfile testfile.o
