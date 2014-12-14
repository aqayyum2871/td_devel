#include "Standards.h"
#include "CalcNumberColumns.h"
#include "isInt.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <ctype.h>

int main(int argc, char **argv) {

	int c;
	unsigned int columns = 0;
	int indicator = 0;

	FILE *ptr_myfile;
	char *buffer;
	unsigned int rownum = 0;

	char exit = -1;
	unsigned int printnumcols = 0;
	unsigned int printnumrows = 0;

	opterr = 0;

	while ((c = getopt (argc, argv, ":c:hi")) != -1) {
		switch (c) {
			case 'c':
				if (isInt(optarg) == 1) {
					fprintf(stderr, "Argument of \"-c\" is not numeric!\n");
					return(1);
				}
				columns = atoi(optarg);
				break;
			case 'i':
				indicator = 1;
				break;
			case 'h':
				fprintf(stderr, "usage: %s [-c numcols] [-i] [-h] filename\n", argv[0]);
				return(1);
				break;
			case ':':
				fprintf (stderr, "Option -%c requires an argument.\n", optopt);
				return(1);
			case '?':
				if (isprint (optopt))
					fprintf (stderr, "Unknown option '-%c'.\n", optopt);
				else
					fprintf (stderr, "Unknown option character '\\x%x'.\n", optopt);
				return(1);
		}
	}

	ptr_myfile=fopen(argv[optind], "r");
	if (ptr_myfile == NULL) {
		fprintf(stderr, "Please, provide file in tptbin format!\n");
		return(1);
	}

	// allocate memory for one record
	buffer = (char *)malloc(MAXBUF+1);
	if (!buffer) {
		fprintf(stderr, "Memory error!");
		fclose(ptr_myfile);
		return(8);
	}

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
				numofcols = CalcNumberColumns(buffer, rowlen, indicator, columns);

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
					fprintf(stderr, "%d: Internal Error!\n", rownum + 1);
					exit = 7;
					break;
				} else if (numofcols == -2) {
					// maximum number of supported columns reached
					fprintf(stderr, "%d: No number of columns determined. Reached maximum column count.\n", rownum + 1);
					exit = 6;
					break;
				} else if (numofcols == -3) {
					// offset reached length of row
					fprintf(stderr, "%d: No number of columns determined. Reached record len.\n", rownum + 1);
					exit = 5;
					break;
				} else if (numofcols == -4) {
					// Indicator, number of columns, but no record format found
					fprintf(stderr, "%d: Indicator, number of columns given, but no correct record format found!\n", rownum + 1);
					exit = 8;
					break;
				} else if (numofcols == -5) {
					// No indicator, no number of columns, no record format found
					fprintf(stderr, "%d: No indicator, no number of columns given. No correct record format found!\n", rownum + 1);
					exit = 9;
					break;
				} else if (numofcols == -6) {
					// No indicator, number of columns, no record format found
					fprintf(stderr, "%d: No indicator, number of columns given, but no correct record format found!\n", rownum + 1);
					exit = 10;
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
				fprintf(stderr, "Row %d: Row len definition in file does not meet actual row len\n", rownum);
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
				printf("%d columns for rows %d to %d\n", printnumcols, printnumrows + 1, rownum);
			}

			// not able to read row len definition in file
			fprintf(stderr, "Row %d: Not able to read row len definition in file\n", rownum);
			exit = 1;
			break;

		}

	}

	fclose(ptr_myfile);
	free(buffer);

	return(exit);

}
