/*
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
#include "CalcNumberColumns.h"
#include "isBitSet.h"

int CalcNumberColumns(char *buffer, unsigned short rowlen, unsigned char indicator, unsigned int numcols) {
	
	int ret = 0;
	unsigned int i;

	// hold the moving offset from buffer
	unsigned int coloffset;
	// is the offset of the starting byte with the coloffset length
	unsigned int startbyte;
	// column counter
	unsigned int colnum = 0;
	// current field length read
	unsigned short actlen;
	// calculate number of indicator bytes from indicator and numcols
	unsigned int numindic = 0;
	// max number of columns found
	unsigned int maxnumcols = 0;

	// array, to hold length of every column
	unsigned short collen[MAXCOLS];

	// set starting point if in indicator mode	
	coloffset = 0;
	startbyte = 0;
	if (indicator == 1 && numcols > 0) {
		numindic = (numcols + 7) / 8;
		coloffset = numindic;
		startbyte = numindic;
	} else if (indicator == 1) {
		coloffset = 1;
		startbyte = 1;
	}

	for (;;) {

		if (maxnumcols > 0 && (startbyte > rowlen || startbyte > MAXCOLS) ) {
			ret = maxnumcols;
			break;
		} else if (startbyte > rowlen) {
			// No number of columns found
			ret = -3;
			break;
		} else if (startbyte > MAXCOLS) {
			// No number of columns found
			ret = -2;
			break;
		}

		//printf("Startbyte: %d; Colnum: %d; Coloffset: %d\n", startbyte, colnum, coloffset);

		if (memcpy(&actlen, buffer + coloffset, sizeof(actlen))) {
			//printf("Actlen: %d, Calculation: %d\n", actlen, coloffset + actlen);
			
			collen[colnum] = actlen;

			if (coloffset + actlen < rowlen) {
				coloffset += actlen + sizeof(rowlen);
				colnum++;
			} else if (coloffset + actlen == rowlen) {
				// found number of coloffsets
				if (indicator == 1) {
					// we have indicator byte(s)
					// check, if the number of indicator bytes match to
					// found number of coloffsets
					if (numindic > 0) {
						// number of indicator bytes are given from invoking routine
						// so, we treat it as true
						ret = colnum;
						break;
					} else if ((colnum + 7 ) / 8 == startbyte) {
						// cross check
						// number of calculated coloffsets meet indicator byte
						unsigned int correct = 0;
						for (i = 0; i < (((colnum + 7) / 8) * 8); i++) {
							if (i < colnum) {
								if (collen[i] == 0 && isBitSet(buffer[i / 8], (i % 8))) {
									// null bit for column is set, and column length is zero
									correct++;
								} else if (collen[i] > 0 && !isBitSet(buffer[i / 8], (i % 8))) {
									// null bit for column is not set, and column length is greater zero
									correct++;
								}
							} else {
								// check if remaining bits of indicator byte are not set
								if (!isBitSet(buffer[i / 8], (i % 8))) {
									// bits are not set
									correct++;
								}
							}
						}
						if (correct == (((colnum + 7) / 8) * 8)) {
							// all indicators fit to column content
							// memorize if largest number of columns and start over
							if (maxnumcols < colnum) {
								maxnumcols = colnum;
							}
							startbyte++;           // start at next byte again
							coloffset = startbyte; // set offset to new start
							colnum = 0;
						} else {
							// No correct layout found, starting over
							startbyte++;           // start at next byte again
							coloffset = startbyte; // set offset to new start
							colnum = 0;
						}
					} else {
						// No correct layout found, starting over
						startbyte++;           // start at next byte again
						coloffset = startbyte; // set offset to new start
						colnum = 0;
					}
				} else {
					ret = colnum;
					break;
				}
			} else {
				// ran over row length
				if (indicator == 1 && numcols == 0) {
					startbyte++;        // start at next byte again
					coloffset = startbyte; // set offset to new start
					colnum = 0;
				} else if (indicator == 1 && numcols > 0) {
					ret = -4;
					break;
				} else if (indicator == 0 && numcols == 0) {
					ret = -5;
					break;
				} else if (indicator == 0 && numcols > 0) {
					ret = -6;
					break;
				}
			}
		} else {
			ret = -1;
			break;
		}
	}

	return(ret);

}
