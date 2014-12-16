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
	int readerror = 0;
	int filecount = 0;

	unsigned short rowlen;

	char *buffer;
	buffer = (char *)malloc(MAXBUF+1);
	if (!buffer) {
		fprintf(stderr, "Memory error!");
		return(8);
	}

	if (argc < 2) {

		// no arguments given
		// coming from stdin

		int rowcount = 0;

		while (!feof(stdin)) {

			size_t bytesread;

			// read the row len definition from file (2 bytes)
			bytesread = fread(&rowlen, 1, sizeof(rowlen), stdin);

			if (bytesread == sizeof(rowlen)) {

				// read the row data based on the known length
				bytesread = fread(buffer, 1, rowlen, stdin);

				if (bytesread != rowlen) {
					readerror++;
					break;
				}
			}

			rowcount++;
		}

		printf("%d %s\n", rowcount, "total");

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

			FILE *fp;
			fp=fopen(filename, "rb");

			if (!fp) {
				fprintf(stderr, "File open error on %s!\n", filename);
				continue;
			}

			while (!feof(fp)) {

				size_t bytesread;

				// read the row len definition from file (2 bytes)
				bytesread = fread(&rowlen, 1, sizeof(rowlen), fp);

				if (bytesread == sizeof(rowlen)) {

					// read the row data based on the known length
					bytesread = fread(buffer, 1, rowlen, fp);

					if (bytesread != rowlen) {
						readerror++;
						break;
					}
				}

				rowcount++;
			}

			fclose(fp);

			if (readerror == 0) {
				printf("%d %s\n", rowcount, filename);
				filecount++;
				sumrowcount += rowcount;
			}

		}

		if (filecount > 1) {
			printf("%d %s\n", sumrowcount, "total");
		}

	}

	return(0);

}
