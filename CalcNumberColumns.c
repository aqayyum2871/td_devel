#include "CalcNumberColumns.h"

int CalcNumberColumns(char *buffer, unsigned short rowlen, unsigned char indic) {
	
	// hold the offset from buffer
	unsigned int coloffset;
	int ret = 0;

	// is the offset of the starting byte with the coloffset length
	unsigned int startbyte;
	// index for pointer array col
	unsigned int colnum = 0;
	// current field length read
	unsigned int actlen;

	// set starting point if in indicator mode	
	if (indic == 1) {
		coloffset = 1;
		startbyte = 1;
	} else {
		coloffset = 0;
		startbyte = 0;
	}

	for (;;) {

		if (coloffset > rowlen) {
			// No number of columns found
			ret = -3;
			break;
		} else if (startbyte > MAXCOLS) {
			// No number of columns found
			ret = -2;
			break;
		}

		if (memcpy(&actlen, buffer + coloffset, sizeof(rowlen))) {
			if (coloffset + actlen < rowlen) {
				coloffset = coloffset + actlen + sizeof(rowlen);
				colnum++;
			} else if (coloffset + actlen == rowlen) {
				// found number of coloffsets
				if (indic == 1) {
					// we have indicator byte(s)
					// check, if the number of indicator bytes match to
					// found number of coloffsets
					if (((colnum + 1) % 8 == 0 && (colnum + 1) / 8 == startbyte) ||
						((colnum + 1) % 8 > 0 && (colnum + 1) / 8 + 1 == startbyte)) {
						// cross check
						// number of calculated coloffsets does not meet indicator byte
						ret = colnum;
						break;
					} else {
						// No correct layout found, starting over
						startbyte++;        // start at next byte again
						coloffset = startbyte; // set offset to new start
						colnum = 0;
					}
				} else {
					ret = colnum;
					break;
				}
			} else {
				// ran over row length, start over
				startbyte++;        // start at next byte again
				coloffset = startbyte; // set offset to new start
				colnum = 0;
			}
		} else {
			ret = -1;
			break;
		}
	}

	return(ret);

}
