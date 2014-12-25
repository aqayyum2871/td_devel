/*
	Copyright (c) 2014 Andreas Wenzel, Teradata Germany
	License: You are free to use, adopt and modify this program for your particular
	purpose.
	If you don't have any relationship with Teradata, you will find this tool
	probably not very useful.
	LICENSOR IS NOT LIABLE TO LICENSEE FOR ANY DAMAGES, INCLUDING COMPENSATORY,
	SPECIAL, INCIDENTAL, EXEMPLARY, PUNITIVE, OR CONSEQUENTIAL DAMAGES, CONNECTED
	WITH OR RESULTING FROM THIS LICENSE AGREEMENT OR LICENSEE'S USE OF THIS SOFTWARE.

	It is appreciated, if any changes to the source code are reported
	to the copyright holder.
*/

#include "Standards.h"
#include "CalcNumberColumns.h"
#include "isInt.h"
#include "UniqSortIntArray.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <ctype.h>

void usage(char **whoami) {
	fprintf(stderr, "usage: %s [-n val] [-i] [-a val] [-b val] [-c list] [-f val] [-t val] [-r list] [-q literal] [-d literal] filename\n", *whoami);
	fprintf(stderr, "       %s -h\n", *whoami);
	fprintf(stderr, "       %*s -n value   = help the tool => give number of columns in file\n", (int)strlen(*whoami), " ");
	fprintf(stderr, "       %*s -i         = null indicator mode (omit is no null indicator mode)\n", (int)strlen(*whoami), " ");
	fprintf(stderr, "       %*s -a value   = print columns beginning with\n", (int)strlen(*whoami), " ");
	fprintf(stderr, "       %*s -b value   = print columns up to (must be greater or equal -a value)\n", (int)strlen(*whoami), " ");
	fprintf(stderr, "       %*s -c list    = print column list (seperator is comma)\n", (int)strlen(*whoami), " ");
	fprintf(stderr, "       %*s -f value   = print rows beginning with\n", (int)strlen(*whoami), " ");
	fprintf(stderr, "       %*s -t value   = print rows up to (must be greater or equal -f value)\n", (int)strlen(*whoami), " ");
	fprintf(stderr, "       %*s -r list    = print row list (seperator is comma)\n", (int)strlen(*whoami), " ");
	fprintf(stderr, "       %*s -q literal = use character(s) as quote sign (up to %d)\n", (int)strlen(*whoami), " ", MAXLENQUOTE);
	fprintf(stderr, "       %*s -d literal = use character(s) as delimiter sign (up to %d)\n", (int)strlen(*whoami), " ", MAXLENDELIM);
}

int main(int argc, char **argv) {

	unsigned int fromcol = 0;
	unsigned int tocol = 0;
	unsigned int fromrow = 0;
	unsigned int torow = 0;
	unsigned int columns = 0;
	unsigned int numofcols = 0;
	int indicator = 0;
	unsigned int i, *row;
	unsigned int iCols = 0, iRows = 0;
	unsigned short selectcol[MAXCOLS];
	unsigned int selectrow[MAXNUMSELROWS];
	int c;
	char *token;
	char delimiter[MAXLENDELIM + 1] = ",";
	char quotechar[MAXLENQUOTE + 1] = "";
	char selectrows = 0;
	char rangerows = 0;
	int exit = -1;
	FILE *ptr_myfile;
	char *buffer;
	unsigned int rownum = 0;

	// clear array for select col indicator
	for (i = 0; i < MAXCOLS; i++) {
		selectcol[i]=0;
	}

	while ((c = getopt (argc, argv, ":a:b:f:t:c:n:r:d:q:hi")) != -1) {
		switch (c) {
			case 'd':
				if (strlen(optarg) > MAXLENDELIM) {
					fprintf(stderr, "Maximum of %d characters for delimiter allowed!\n", MAXLENDELIM);
					return(1);
				}
				strncpy(delimiter, optarg, sizeof(delimiter));
				break;
			case 'n':
				if (isInt(optarg) == 1) {
					fprintf(stderr, "Argument of \"-n\" is not numeric!\n");
					return(1);
				}
				columns = atoi(optarg);
				break;
			case 'q':
				if (strlen(optarg) > MAXLENQUOTE) {
					fprintf(stderr, "Maximum of %d characters for quote sign allowed!\n", MAXLENQUOTE);
					return(1);
				}
				strncpy(quotechar, optarg, sizeof(quotechar)-1);
				break;
			case 'a':
				if (isInt(optarg) == 1) {
					fprintf(stderr, "Argument of \"-a\" is not numeric!\n");
					return(1);
				}
				fromcol = atoi(optarg);
				if (fromcol > 0 && tocol > 0 && fromcol <= tocol) {
					for (i = fromcol -1; i < tocol; i++) {
						selectcol[iCols++] = i + 1;
					}
				}
				break;
			case 'b':
				if (isInt(optarg) == 1) {
					fprintf(stderr, "Argument of \"-b\" is not numeric!\n");
					return(1);
				}
				tocol = atoi(optarg);
				if (fromcol > 0 && tocol > 0 && fromcol <= tocol) {
					for (i = fromcol -1; i < tocol; i++) {
						selectcol[iCols++] = i + 1;
					}
				}
				break;
			case 'c':
				token = strtok(optarg, ",");
				while (token) {
					if (isInt(token) == 1) {
						fprintf(stderr, "Argument of \"-c\" is not numeric!\n");
						return(1);
					}
					selectcol[iCols++] = atoi(token);
					token = strtok(NULL, ",");
				}
				break;
			case 'f':
				if (isInt(optarg) == 1) {
					fprintf(stderr, "Argument of \"-f\" is not numeric!\n");
					return(1);
				}
				fromrow = atoi(optarg);
				if (fromrow > 0 && torow > 0 && fromrow > torow) {
					fprintf(stderr, "From row must be less or equal to row!\n");
					return(1);
				}
				rangerows++;
				break;
			case 't':
				if (isInt(optarg) == 1) {
					fprintf(stderr, "Argument of \"-t\" is not numeric!\n");
					return(1);
				}
				torow = atoi(optarg);
				if (fromrow > 0 && torow > 0 && fromrow > torow) {
					fprintf(stderr, "From row must be less or equal to row!\n");
					return(1);
				}
				rangerows++;
				break;
			case 'r':
				token = strtok(optarg, ",");
				while (token) {
					if (iRows >= MAXNUMSELROWS) {
						fprintf(stderr, "Only %d rows supported for select!\n", MAXNUMSELROWS);
						return(1);
					} else if (isInt(token) == 1) {
						fprintf(stderr, "Argument of \"-r\" is not numeric!\n");
						return(1);
					}
					selectrow[iRows++] = atoi(token);
					token = strtok(NULL, ",");
				}
				iRows = UniqSortIntArray(iRows, selectrow);
				row = selectrow;
				selectrows = 1;
				break;
			case 'i':
				indicator = 1;
				break;
			case 'h':
				usage(&argv[0]);
				return(1);
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

	if ((fromrow > 0 && torow == 0) || (fromrow == 0 && torow > 0)) {
		fprintf(stderr, "From row cannot go without to row, and vice versa!\n");
		return(1);
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

		// read the row len definition from file (2 bytes)
		bytesread = fread(&rowlen, 1, sizeof(rowlen), ptr_myfile);

		if (bytesread == sizeof(rowlen)) {

			// read the row data based on the known length
			bytesread = fread(buffer, 1, rowlen, ptr_myfile);

			if (bytesread == rowlen) {

				if ((selectrows == 1 && *row == rownum + 1) || (rangerows == 2 && rownum + 1 >= fromrow && rownum + 1 <= torow) || (selectrows == 0 && rangerows == 0)) {

					if (selectrows == 1 && (row - selectrow) / sizeof(row) < iRows) {
						row++;
					}

					char *column;

					if (columns == 0 && numofcols == 0) {
						// calculate here only if no number of columns are given
						numofcols = CalcNumberColumns(buffer, rowlen, indicator, columns);
						if (numofcols < 1) {
							fprintf(stderr, "Cannot determine the number of columns. Execute again and give number of columns!\n");
							exit = 5;
							break;
						}
						if (iCols == 0) {
							// no columns for output selected
							for (i = 0; i < numofcols; i++) {
								selectcol[i] = i + 1;
							}
						}
					} else if (numofcols == 0) {
						numofcols = columns;
						if (iCols == 0) {
							// no columns for output selected
							for (i = 0; i < numofcols; i++) {
								selectcol[i] = i + 1;
							}
						}
					}


					//printf("%d\n", numofcols);
					if (numofcols > 0) {
						char *col[numofcols];
						unsigned short collen[numofcols];

						if (indicator == 1) {
							column = buffer + ((numofcols + 7) / 8);
						} else {
							column = buffer;
						}

						unsigned short actlen;
						// scan record for column positions
						for (i = 0; i < numofcols; i++) {
							if (memcpy(&actlen, column, sizeof(actlen))) {
								col[i] = column + sizeof(actlen);
								collen[i] = actlen;
								column += actlen + sizeof(actlen);
							}
						}
						//printf("%d\n", i);

						// new loop for output of columns
						i = 0;
						for (;;) {
							if (selectcol[i] == 0) {
								break;
							} else if (i == 0) {
								if (strncmp(quotechar, "", sizeof(quotechar)-1))
									printf("%s", quotechar);
								printf("%.*s", collen[selectcol[i]-1], col[selectcol[i]-1]);
								if (strncmp(quotechar, "", sizeof(quotechar)-1))
									printf("%s", quotechar);
							} else {
								printf("%s", delimiter);
								if (strncmp(quotechar, "", sizeof(quotechar)-1))
									printf("%s", quotechar);
								printf("%.*s", collen[selectcol[i]-1], col[selectcol[i]-1]);
								if (strncmp(quotechar, "", sizeof(quotechar)-1))
									printf("%s", quotechar);
							}
							i++;
						}
						printf("\n");
					}

				}

			} else if (bytesread == 0) {

				fprintf(stderr, "Row %d: Error in row. Rowsize found, but no data\n", rownum);
				exit = 4;
				break;

			} else {

				// row len definition in file does not meet actual row len
				fprintf(stderr, "Row %d: Row len definition in file does not meet actual row len\n", rownum);
				exit = 3;
				break;

			}

			rownum++;

		} else if (bytesread == 0) {

			exit = 0;
			break;

		} else {

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
