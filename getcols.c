#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define MAXBUF 1000000
#define MAXCOLS 10000

int CalcNumberColumns(char *buffer, unsigned short rowlen, unsigned char indic) {

	unsigned int i;
	
	// array to hold the offset from buffer start for every column
	unsigned short col[MAXCOLS];
	int ret = 0;

	// empty all pointers of columns
	for (i = 0; i < MAXCOLS; i++) {
		col[i] = 0x00;
	}

	// is the offset of the starting byte with the column length
	unsigned int startbyte;
	// index for pointer array col
	unsigned int colnum = 0;
	// current field length read
	unsigned short actlen;

	// set starting point if in indicator mode	
	if (indic == 1) {
		col[0] = 1;
		startbyte = 1;
	} else {
		col[0] = 0;
		startbyte = 0;
	}

	for (;;) {

		printf("Debug: %d\t%d\n", startbyte, colnum); 
		if (col[0] > MAXCOLS / 8 || col[0] > rowlen) {
			printf("No exact row len found!\n");
			ret = -3;
			break;
		}

		if (memcpy(&actlen, buffer + col[colnum], sizeof(rowlen))) {
			if (col[colnum] + actlen < rowlen) {
				col[colnum + 1] = col[colnum] + actlen + sizeof(rowlen);
				colnum++;
			} else if (col[colnum] + actlen == rowlen) {
				// found number of columns
				if ((colnum % 8 == 0 && colnum / 8 == col[0]) || (colnum % 8 > 0 && int(column / 8) + 1 > colnum) {
					// cross check
					// number of calculated columns does not meet indicator byte
				} else {
					printf("Number of columns: %d\n", colnum);
					break;
				}
			} else {
				// ran over row length, start over
				col[0]++;  // start at next byte again
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
		if (fread(&rowlen, sizeof(rowlen), 1, ptr_myfile)) {
			if (fread(buffer, 1, rowlen, ptr_myfile) == rowlen) {
				numofcols = CalcNumberColumns(buffer, rowlen, 1);
				if (numofcols > 0) {
					printf("%d\n", numofcols);
					exit = 0;
				} else {
					exit = 3;
				}
			} else {
				exit = 2;
			}
		} else {
			exit = 1;
		}
	}

	fclose(ptr_myfile);
	free(buffer);

	return(0);

}
