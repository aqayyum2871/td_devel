/*
	Copyright (c) 2014 Andreas Wenzel, Teradata Germany
	License: You are free to use, adopt and modify this program for your particular
	purpose.
	If you are a Teradata employee you are free to use, copy, and distribute
	this program to Teradata customers.
	If you don't have any relationship with Teradata, you will find this tool
	probably not very useful.
	LICENSOR IS NOT LIABLE TO LICENSEE FOR ANY DAMAGES, INCLUDING COMPENSATORY,
	SPECIAL, INCIDENTAL, EXEMPLARY, PUNITIVE, OR CONSEQUENTIAL DAMAGES, CONNECTED
	WITH OR RESULTING FROM THIS LICENSE AGREEMENT OR LICENSEE'S USE OF THIS SOFTWARE.

	It is appreciated, if any changes to the source code are reported
	to the copyright holder.
*/

#include "Standards.h"
#include "isInt.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <ctype.h>

int main(int argc, char **argv) {

	FILE *ptr_myfile;
	int i, j;
	char text[100] = "AbCdEfGhIjKlMnOpQrStUvWxYz0123456789aBcDeFgHiJkLmNoPqRsTuVwXyZ";
	int numcols = 5;
	int numrows = 1;
	unsigned short rowlen = 0;
	double calcrowlen = 0;
	int c;
	int maxlen = 40;
	char indicator = 0;
	int numindic = 0;

	while ((c = getopt (argc, argv, ":c:r:m:hi")) != -1) {
		switch (c) {
			case 'c':
				if (isInt(optarg) == 1) {
					fprintf(stderr, "Argument of \"-c\" is not numeric!\n");
					return(1);
				}
				numcols = atoi(optarg);
				break;
			case 'r':
				if (isInt(optarg) == 1) {
					fprintf(stderr, "Argument of \"-r\" is not numeric!\n");
					return(1);
				}
				numrows = atoi(optarg);
				break;
			case 'm':
				if (isInt(optarg) == 1) {
					fprintf(stderr, "Argument of \"-m\" is not numeric!\n");
					return(1);
				}
				if (strlen(text) > atoi(optarg)) {
					maxlen = atoi(optarg);
				}
				break;
			case 'h':
				fprintf(stderr, "usage: %s [-c numcols] [-r numrows] [-m maxcollen] [-i] [-h] filename\n", argv[0]);
				return(1);
				break;
			case 'i':
				indicator = 1;
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

	unsigned short collen[numcols];
	char *col[numcols];
	numindic = (numcols + 7) / 8;    // calculate number of indicator bytes base on number of columns

	unsigned char indic[numindic];

	if (indicator == 1) {
		for (i = 0; i < numindic; i++) {
			indic[i] = 0x00;
		}

		rowlen += numindic;
	}

	// Set pointer for random data to write
	for (j = 0; j < numcols; j++) {
		col[j] = &text[j];
		collen[j] = rand() % maxlen;
		rowlen += collen[j] + 2;
		calcrowlen += collen[j] + 2;
	}

	if (calcrowlen + numindic > 32768) {
		fprintf(stderr, "Rowlen got too long: %.0f!\n", calcrowlen + numindic);
		fprintf(stderr, "Choose less columns or shorter maximum length per column!\n");
		return(2);
	}

	ptr_myfile=fopen(argv[optind], "a");
	if (!ptr_myfile) {
		fprintf(stderr, "Unable to open file!");
		return(3);
	}

	for (j = 0; j < numrows; j++) {
		fwrite(&rowlen, sizeof(rowlen), 1, ptr_myfile); // write row len
		if (indicator == 1) {
			fwrite(&indic, sizeof(indic), 1, ptr_myfile); // write indicator bytes
		}
		for (i = 0; i < numcols; i++) {
			fwrite(&collen[i], sizeof(collen[i]), 1, ptr_myfile);
			fwrite(text, collen[i], 1, ptr_myfile);
		}
	}

	fclose(ptr_myfile);

	return (0);
}
