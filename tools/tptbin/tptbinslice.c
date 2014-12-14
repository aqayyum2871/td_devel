#include "Standards.h"
#include "isInt.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <getopt.h>
#include <ctype.h>

int main(int argc, char **argv) {

	unsigned int fromrow = 1;
	unsigned int torow = 1;
	unsigned int i;
	int c;

	opterr = 0;

	while ((c = getopt (argc, argv, "f:t:h")) != -1) {
		switch (c) {
			case 'f':
				if (isInt(optarg) == 1) {
					fprintf(stderr, "Argument of \"-f\" is not numeric!\n");
					return(1);
				}
				fromrow = atoi(optarg);
				break;
			case 't':
				if (isInt(optarg) == 1) {
					fprintf(stderr, "Argument of \"-t\" is not numeric!\n");
					return(1);
				}
				torow = atoi(optarg);
				break;
			case 'h':
				fprintf(stderr, "usage: %s [-f fromrow] [-t torow] [-h] filename\n", argv[0]);
				return(1);
				break;
			case '?':
				if (optopt == 'f' || optopt == 't' || optopt == 'm')
					fprintf (stderr, "Option -%c requires an argument.\n", optopt);
				else if (isprint (optopt))
					fprintf (stderr, "Unknown option '-%c'.\n", optopt);
				else
					fprintf (stderr, "Unknown option character '\\x%x'.\n", optopt);
				return(1);
		}
	}

	FILE *ptr_myfile;
	char *buffer;
	unsigned int rownum = 0;

	for (i = optind; i < argc; i++) {
		if ((ptr_myfile=fopen(argv[i],"r")) == NULL) {
			fprintf(stderr, "Please, provide file in tptbin format!\n");
			return(1);
		} else {
			break;
		}
	}
	
	// allocate memory for one record
	buffer = (char *)malloc(MAXBUF+1);
	if (!buffer) {
		fprintf(stderr, "Memory error!");
        fclose(ptr_myfile);
		return(8);
	}

	char exit = -1;

	while (!feof(ptr_myfile)) {

		unsigned short rowlen;
		size_t bytesread;

		// read the row len definition from file (2 bytes)
		bytesread = fread(&rowlen, 1, sizeof(rowlen), ptr_myfile);

		if (bytesread == sizeof(rowlen)) {

			// read the row data based on the known length
			bytesread = fread(buffer, 1, rowlen, ptr_myfile);

			if (bytesread == rowlen) {
			
				if ((rownum + 1) >= fromrow && (rownum + 1) <= torow) {
					fwrite(&rowlen, sizeof(rowlen), 1, stdout);
					fwrite(buffer, rowlen, 1, stdout);
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
