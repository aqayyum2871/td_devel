#include "isInt.h"
#include <ctype.h>
#include <string.h>
#include "Standards.h"

int isInt(char *p) {
	int isInt = 0;
	int i = 0;

	while(i < strlen(p) && isInt == 0) {
		if (!isdigit(*p))
			return(1);
		i++;
	}

	return(isInt);
}
