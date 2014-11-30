#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define MAXBUF 1000000
#define MAXCOLS 10000

int CalcNumberColumns(char *buffer, unsigned short rowlen, unsigned char indic) {

	unsigned int i;
	
	// hold the offset from buffer start
	unsigned short column;
	int ret = 0;

	// is the offset of the starting byte with the column length
	unsigned int startbyte;
	// index for pointer array col
	unsigned int colnum = 0;
	// current field length read
	unsigned short actlen;

	// set starting point if in indicator mode	
	if (indic == 1) {
		column = 1;
		startbyte = 1;
	} else {
		column = 0;
		startbyte = 0;
	}

	for (;;) {

		printf("Debug: %d\t%d\t%d\t%d\n", startbyte, rowlen, colnum, column); 

		if (column > rowlen) {
			printf("No number of columns found!\n");
			ret = -4;
			break;
		} else if (startbyte > 10) {
			printf("No number of columns found!\n");
			ret = -3;
			break;
		}

		if (memcpy(&actlen, buffer + column, sizeof(rowlen))) {
			if (column + actlen < rowlen) {
				column = column + actlen + sizeof(rowlen);
				colnum++;
			} else if (column + actlen == rowlen) {
				// found number of columns
				if (indic == 1) {
					// we have indicator byte(s)
					// check, if the number of indicator bytes match to
					// found number of columns
					if (((colnum + 1) % 8 == 0 && (colnum + 1) / 8 == startbyte) ||
						((colnum + 1) % 8 > 0 && (colnum + 1) / 8 + 1 == startbyte)) {
						// cross check
						// number of calculated columns does not meet indicator byte
						ret = colnum;
						break;
					} else {
						printf("No correct layout found, starting over!\n");
						startbyte++;        // start at next byte again
						column = startbyte; // set offset to new start
						colnum = 0;
					}
				} else {
					printf("Number of columns: %d\n", colnum);
					ret = colnum;
					break;
				}
			} else {
				// ran over row length, start over
				startbyte++;        // start at next byte again
				column = startbyte; // set offset to new start
				colnum = 0;
			}
		} else {
			printf("Error while coping from buffer to field len.\n");
			ret = -1;
			break;
		}
	}

	return(ret);

}

int main() {

	FILE *ptr_myfile;
	int i;
	unsigned short rowlen;
	char *buffer;

	ptr_myfile=fopen("test.bin","r");
	
	if (!ptr_myfile) {
			printf("Unable to open file!");
			return(1);
	}

	buffer=(char *)malloc(MAXBUF+1);
	if (!buffer) {
		fprintf(stderr, "Memory error!");
        fclose(ptr_myfile);
		return(8);
	}

	char exit = -1;
	unsigned int numofcols = 0;

	while(exit < 0) {
		if (fread(&rowlen, 1, sizeof(rowlen), ptr_myfile) == sizeof(rowlen)) {
			if (fread(buffer, 1, rowlen, ptr_myfile) == rowlen) {
				numofcols = CalcNumberColumns(buffer, rowlen, 1);
				if (numofcols > 0) {
					printf("Number of columns: %d\n", numofcols);
					exit = 0;
				} else {
					// column count calculation return with error
					exit = 3;
				}
			} else {
				// row len definition in file does not meet actual row len
				exit = 2;
			}
		} else {
			// not able to read row len definition in file
			exit = 1;
		}
	}

	fclose(ptr_myfile);
	free(buffer);

	return(exit);

}
