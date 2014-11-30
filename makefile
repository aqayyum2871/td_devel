OBJ = getcols.o CalcNumberColumns.o tptbinview.o testfile.o

all: getcols CalcNumberColumns.o tptbinview testfile

clean:
	rm -rf $(OBJ)

%.o: %.c
	gcc -Wall -g -c $<

getcols: getcols.o CalcNumberColumns.o
	gcc -o getcols getcols.o CalcNumberColumns.o

tptbinview: tptbinview.o
	gcc -o tptbinview tptbinview.o

testfile: testfile.o
	gcc -o testfile testfile.o
