#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "CalcNumberColumns.h"

#define MAXBUF 1000000

int main(void) {

	FILE *ptr_myfile;
	int i;
	unsigned short rowlen;
	char *buffer;
	unsigned int rownum = 0;

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
		// read the row len definition from file (2 bytes)
		if (fread(&rowlen, 1, sizeof(rowlen), ptr_myfile) != EOF) {
			// read the row data based on the known length
			if (fread(buffer, 1, rowlen, ptr_myfile) == rowlen) {
				numofcols = CalcNumberColumns(buffer, rowlen, 1);
				if (numofcols > 0) {
					printf("Number of columns: %d in row %d\n", numofcols, rownum);
				} else {
					// coloffset count calculation return with error
					exit = 3;
				}
			} else {
				// row len definition in file does not meet actual row len
				exit = 2;
			}
			rownum++;
		} else {
			// not able to read row len definition in file
			exit = 1;
		}
	}

	fclose(ptr_myfile);
	free(buffer);

	return(exit);

}
