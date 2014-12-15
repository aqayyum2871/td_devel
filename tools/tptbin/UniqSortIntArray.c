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
