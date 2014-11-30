#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "CalcNumberColumns.h"

#define MAXBUF 1000000

int main(void) {

	FILE *ptr_myfile;
	char *buffer;
	unsigned int rownum = 0;

	ptr_myfile=fopen("test.bin","r");
	
	if (!ptr_myfile) {
		printf("Unable to open file!");
		return(1);
	}

	// allocate memory for one record
	buffer = (char *)malloc(MAXBUF+1);
	if (!buffer) {
		fprintf(stderr, "Memory error!");
        fclose(ptr_myfile);
		return(8);
	}

	char exit = -1;
	unsigned int printnumcols = 0;
	unsigned int printnumrows = 0;

	while (!feof(ptr_myfile)) {

		unsigned short rowlen;
		size_t bytesread;
		int numofcols = 0;

		// read the row len definition from file (2 bytes)
		bytesread = fread(&rowlen, 1, sizeof(rowlen), ptr_myfile);

		if (bytesread == sizeof(rowlen)) {

			// read the row data based on the known length
			bytesread = fread(buffer, 1, rowlen, ptr_myfile);

			if (bytesread == rowlen) {

				// calculate here
				numofcols = CalcNumberColumns(buffer, rowlen, 1);

				if (printnumcols == 0) {
					printnumcols = numofcols;
					printnumrows = rownum;
				} else if (printnumcols > 0 && numofcols != printnumcols) {
					printf("%d columns for rows %d to %d\n", printnumcols, printnumrows + 1, rownum);
					printnumcols = numofcols;
					printnumrows = rownum;
				}

				if (numofcols == -1) {
					// internal buffer error
					printf("%d: Error! Record structure faulty?\n", rownum + 1);
					exit = 3;
					break;
				} else if (numofcols == -2) {
					// maximum number of columns reached
					printf("A:%d: No number of columns determined. Probable previous record failure!\n", rownum + 1);
					exit = 3;
					break;
				} else if (numofcols == -3) {
					// offset reached length of row
					printf("B:%d: No number of columns determined. Probable previous record failure!\n", rownum + 1);
					exit = 3;
					break;
				}

			} else if (bytesread == 0) {

				if (printnumcols > 0) {
					printf("%d columns for rows %d to %d\n", printnumcols, printnumrows + 1, rownum);
				}

				exit = 2;
				break;

			} else {

				if (printnumcols > 0) {
					printf("%d columns for rows %d to %d\n", printnumcols, printnumrows + 1, rownum);
				}

				// row len definition in file does not meet actual row len
				printf("Row %d: Row len definition in file does not meet actual row len\n", rownum);
				exit = 2;
				break;

			}

			rownum++;

		} else if (bytesread == 0) {

			if (printnumcols > 0) {
				printf("%d columns for rows %d to %d\n", printnumcols, printnumrows + 1, rownum);
			}

			exit = 0;
			break;

		} else {

			if (printnumcols > 0) {
				printf("%d columns, rows %d to %d\n", printnumcols, printnumrows + 1, rownum);
			}

			// not able to read row len definition in file
			printf("Row %d: Not able to read row len definition in file\n", rownum);
			exit = 1;
			break;

		}

	}

	fclose(ptr_myfile);
	free(buffer);

	return(exit);

}
