/*
	Rowcount for TPT binary file format

	If reading from stdin is desired, then no argument is allowed

	Read two bytes from the beginning of the file, this number is the row length.
	Seek ahead for this number of bytes. This is one record.
	Read another two bytes, this is the number of bytes for the next row.
	Seek ahead for this number of bytes. This is another record.
	and so on ....
	The number of "blocks" gives the number of actual rows.
	The output is very similar to the output of the standard tool "wc -l"

	For reading a file, a seek ahead without buffering the data is possible.
	For reading from stdin, a seek ahead is not possible. The data must be
	loaded into memory. Therefore, the rowlen is essential. This release
	supports length up to 100000 bytes (defined in MAXROWLEN).
	For longer rows, the buffer must be allocated via malloc, and the software
	changed.

	Copyright (c) 2014 Andreas Wenzel, Teradata Germany

	License: You are free to use and adopt this program for your particular 
	purpose if you are a Teradata customer with a valid Teradata RDBMS license. 
	If you are a Teradata employee you are free to use, copy, and distribute 
	this program to Teradata customers. If you are a Teradata employee you 
	are also free to modify this program but, you must retain the above 
	copyright line and this license statement.

	It is appreciated, if any changes to the source code are reported
	to the copyright holder.
*/

#include "Standards.h"
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>

int main(int argc, char **argv) {

	char *filename;
	filename = NULL;
	int i = 0;
	int sumrowcount = 0;
	int openerror = 0;
	int readerror = 0;
	int filecount = 0;

	unsigned int rowlen;

	if (argc < 2) {

		// no arguments given
		// coming from stdin

		int rowcount = 0;
		// allocate memory for one record
		char *buffer;
		buffer = (char *)malloc(MAXBUF+1);
		if (!buffer) {
			fprintf(stderr, "Memory error!");
			return(8);
		}

		while ( fread(&rowlen, sizeof(rowlen), 1, stdin) ) {
			if (rowlen <= MAXBUF) {
				fread(&buffer, rowlen, 1, stdin);
			} else {
				fprintf(stderr, "Maximum row length of %d characters!\n", MAXBUF);
				return(1);
			}
			rowcount++;
		}

		fprintf(stdout, "%d %s\n", rowcount, "total");

	} else {
 
		// try every argument if it is a file
		for (i=1; i < argc; i++) {

			int rowcount = 0;
			int result = access(argv[i], F_OK);
			if (result == 0) {
				// it is a file
				filename = argv[i];
			} else {
				// argument is not a file, ignore it
				continue;
			}

			int lreaderror = 0;

			FILE *fp;
			fp=fopen(filename, "rb");

			if (!fp) {
				fprintf(stderr, "File open error on %s!\n", filename);
				openerror++;
				continue;
			}

			while ( fread(&rowlen, sizeof(rowlen), 1, fp) ) {
				if (fseek(fp, rowlen, SEEK_CUR)) {
					fprintf(stderr, "File %s corrupt?\n", filename);
					readerror++;
					lreaderror++;
					break;
				}
				rowcount++;
			}

			fclose(fp);

			if (lreaderror == 0) {
				fprintf(stdout, "%d %s\n", rowcount, filename);
				filecount++;
				sumrowcount += rowcount;
			}

		}

		if (filecount > 1) {
			fprintf(stdout, "%d %s\n", sumrowcount, "total");
		}

	}

	return(0);

}
