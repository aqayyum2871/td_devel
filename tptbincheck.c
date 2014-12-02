#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "CalcNumberColumns.h"

#define MAXBUF 1000000

int main(int argc, char **argv) {

	FILE *ptr_myfile;
	char *buffer;
	unsigned int rownum = 0;

	if (argc != 2) {
		fprintf(stderr, "Please, give file in tptbin format!\n");
		return(1);
	}
		
	ptr_myfile=fopen(argv[1],"r");
	
	if (!ptr_myfile) {
		printf("Unable to open file: %s!\n", argv[1]);
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

				//printf("Row: %d; Length: %d\n", rownum, rowlen);
				
				// calculate here
				numofcols = CalcNumberColumns(buffer, rowlen, 1);

				// clear buffer
				int i;
				char *p = buffer;
				for (i = 0; i < rowlen; i++) {
					*p++ = 0x00;
				}

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
					exit = 7;
					break;
				} else if (numofcols == -2) {
					// maximum number of columns reached
					printf("%d: No number of columns determined. Reached maximum column count.\n", rownum + 1);
					exit = 6;
					break;
				} else if (numofcols == -3) {
					// offset reached length of row
					printf("%d: No number of columns determined. Reached record len.\n", rownum + 1);
					exit = 5;
					break;
				}

			} else if (bytesread == 0) {

				if (printnumcols > 0) {
					printf("%d columns for rows %d to %d\n", printnumcols, printnumrows + 1, rownum);
				}

				exit = 4;
				break;

			} else {

				if (printnumcols > 0) {
					printf("%d columns for rows %d to %d\n", printnumcols, printnumrows + 1, rownum);
				}

				// row len definition in file does not meet actual row len
				printf("Row %d: Row len definition in file does not meet actual row len\n", rownum);
				exit = 3;
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
