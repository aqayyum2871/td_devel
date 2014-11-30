#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <getopt.h>
#include <ctype.h>

int main(int argc, char **argv) {

	FILE *ptr_myfile;
	int i, j;
	char text[100] = "AbCdEfGhIjKlMnOpQrStUvWxYz0123456789aBcDeFgHiJkLmNoPqRsTuVwXyZ";
	int numcols = 5;
	int numrows = 1;
	unsigned short rowlen = 0;
	int c;

	while ((c = getopt (argc, argv, "c:r:")) != -1) {
		switch (c) {
			case 'c':
				numcols = atoi(optarg);
				break;
			case 'r':
				numrows = atoi(optarg);
				break;
			case '?':
				if (optopt == 'c' || optopt == 'r')
					fprintf (stderr, "Option -%c requires an argument.\n", optopt);
				else if (isprint (optopt))
					fprintf (stderr, "Unknown option `-%c'.\n", optopt);
				else
					fprintf (stderr, "Unknown option character `\\x%x'.\n", optopt);
				return(2);
		}
	}

	int numindic;
	if (numcols % 8 == 0) {
		numindic = numcols / 8;
	} else {
		numindic = numcols / 8 + 1;
	}
	char indic[numindic];
	for (i = 0; i < numindic; i++) {
		indic[i] = 0x00;
	}

	char *col[numcols];
	unsigned short collen[numindic];

	for (j = 0; j < numcols; j++) {
		col[j] = &text[j];
		collen[j] = rand() % 50 + 2;
		rowlen += collen[j] + 2;
	}

	rowlen += numindic;

	ptr_myfile=fopen("test.bin","a");
	
	if (!ptr_myfile) {
		printf("Unable to open file!");
		return(1);
	}

	for (j = 0; j < numrows; j++) {
		fwrite(&rowlen, sizeof(rowlen), 1, ptr_myfile); // write row len
		fwrite(&indic, sizeof(indic), 1, ptr_myfile); // write indicator bytes
		for (i = 0; i < numcols; i++) {
			fwrite(&collen[i], sizeof(collen[i]), 1, ptr_myfile);
			fwrite(text, collen[i], 1, ptr_myfile);
		}
	}

	fclose(ptr_myfile);

	return (0);
}
