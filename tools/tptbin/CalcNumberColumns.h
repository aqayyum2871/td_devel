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

#ifndef CALCNUMBERCOLUMNS_H
#define CALCNUMBERCOLUMNS_H

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int CalcNumberColumns(char *buffer, unsigned short rowlen, unsigned char indicator, unsigned int numcols);

#endif
