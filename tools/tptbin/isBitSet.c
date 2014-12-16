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

#include "isBitSet.h"

int isBitSet (unsigned char c, int n) {
    static unsigned char mask[] = {128, 64, 32, 16, 8, 4, 2, 1};
    return ((c & mask[n]) != 0);
}
