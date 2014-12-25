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
#include <stdlib.h> //noetig fuer atexit()
#include <ncurses.h>
#include <locale.h>
#include <getopt.h>
#include <ctype.h>
#include "CalcNumberColumns.h"
#include "CursesInitialSetup.h"
#include "MyCurses.h"

int main(int argc, char **argv) {
	//int x, y;

	WINDOW *headerwin;
	WINDOW *linenumwin;
	WINDOW *contentwin;

	int c;
	unsigned short numcols = 0;
	unsigned int i;
	char indicator = 0;
	struct windim work;
	int exit;

	opterr = 0;

	while ((c = getopt (argc, argv, "c:hi")) != -1) {
		switch (c) {
			case 'c':
				numcols = atoi(optarg);
				break;
			case 'i':
				indicator = 1;
				break;
			case 'h':
				printf("usage: %s [-c numcols] [-i] [-h] filename\n", argv[0]);
				return(1);
				break;
			case '?':
				if (optopt == 'c')
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
	char *p;
	p = buffer;
	if (!buffer) {
		fprintf(stderr, "Memory error!");
		fclose(ptr_myfile);
		return(8);
	}

	// clear buffer
	for (i = 0; i < sizeof(buffer); i++) {
		buffer[i] = 0x00;
	}

	setlocale(LC_CTYPE, "");

	CursesInitialSetup(&work);

	while (!feof(ptr_myfile)) {

		unsigned short rowlen;
		size_t bytesread;
		int numofcols = 0;

		// read the row len definition from file (2 bytes)
		bytesread = fread(&rowlen, 1, sizeof(rowlen), ptr_myfile);

		if (bytesread == sizeof(rowlen)) {

			// read the row data based on the known length
			bytesread = fread(p, 1, rowlen, ptr_myfile);

			if (bytesread == rowlen) {

				// clear buffer before loading it again
				for (i = 0; i < rowlen; i++) {
					*p[i] = 0;
				}

				// calculate here
				numofcols = CalcNumberColumns(buffer, rowlen, indicator, numcols);

				if (numofcols > 0) {
				}

			} else {

				// row len definition in file does not meet actual row len
				fprintf(stderr, "Row %d: Row len definition in file does not meet actual row len\n", rownum);
				exit = 3;
				break;

			}

			rownum++;

		} else {

			// not able to read row len definition in file
			fprintf(stderr, "Row %d: Not able to read row len definition in file\n", rownum);
			exit = 1;
			break;

		}

	}

	fclose(ptr_myfile);
	free(buffer);

	getch();
	return(0);
}
