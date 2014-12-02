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

		if (startbyte > rowlen) {
			// No number of columns found
			ret = -3;
			break;
		} else if (startbyte > MAXCOLS) {
			// No number of columns found
			ret = -2;
			break;
		}

		//printf("Startbyte: %d; Colnum: %d; Coloffset: %d\n", startbyte, colnum, coloffset);

		if (memcpy(&actlen, buffer + coloffset, sizeof(rowlen))) {
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
						ret = colnum;
						break;
					} else if ((colnum + 7 ) / 8 == startbyte) {
						// cross check
						// number of calculated coloffsets meet indicator byte
						char correct = 0;
						for (i = 0; i < colnum; i++) {
							if (collen[i] == 0 && isBitSet(buffer[i / 8], (i % 8))) {
								// null bit for column is set, and column length is zero
								correct++;
							} else if (collen[i] > 0 && !isBitSet(buffer[i / 8], (i % 8))) {
								// null bit for column is not set, and column length is greater zero
								correct++;
							}
						}
						if (correct == colnum) {
							ret = colnum;
							break;
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
				if (indicator == 1 && numindic == 0) {
					startbyte++;        // start at next byte again
					coloffset = startbyte; // set offset to new start
					colnum = 0;
				} else if (numindic > 0) {
					ret = -4;
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
