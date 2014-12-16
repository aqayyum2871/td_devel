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

// function to sort array with unsigned int

int UniqSortIntArray (unsigned int numElements, unsigned int *array) {
	unsigned int i, j, k, swapper;

	// dedupe
	for (i = 0; i < numElements; i++) {
		for (j = 0; j < numElements; j++) {
			if (i == j) {
				continue;
			} else if (*(array + i) == *(array + j)) {
				k = j;
				numElements--;
				while (k < numElements) {
					*(array + k) = *(array + k + 1);
					k++;
				}
				j = 0;
			}
		}
	}

	// sort ascending
	for (i = 0; i < numElements; i++) {
		for (j = i + 1; j < numElements; j++) {
			if (*(array + i) > *(array + j)) {
				swapper = *(array + i);
				*(array + i) = *(array + j);
				*(array + j) = swapper;
			}
		}
	}

	return(numElements);

}
