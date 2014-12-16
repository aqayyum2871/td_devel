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
#include <stdlib.h> //noetig fuer atexit()
#include <ncurses.h>
#include <locale.h>
#include <getopt.h>
#include <ctype.h>
#include "CalcNumberColumns.h"

WINDOW *headerwin;
WINDOW *linenumwin;
WINDOW *contentwin;

struct windim {
	unsigned short x;
	unsigned short y;
};

void quit() {
	delwin(headerwin);
	delwin(linenumwin);
	//delwin(contentwin);
	endwin();
}

void CursesInitialSetup(struct windim *work) {
	int screenx, screeny;
	unsigned int i;
	initscr();
	atexit(quit);

	start_color();
	init_pair(1, COLOR_YELLOW, COLOR_BLUE);
	init_pair(2, COLOR_BLUE, COLOR_WHITE);

	bkgd(COLOR_PAIR(1));

	curs_set(0);

	getmaxyx(stdscr, screeny, screenx);

	work->x = screenx;
	work->y = screeny;

	headerwin = newwin(1, screenx - 5, 0, 5);
	wbkgd(headerwin, COLOR_PAIR(2));

	linenumwin = newwin(screeny - 1, 5, 1, 0);
	wbkgd(linenumwin, COLOR_PAIR(2));

	contentwin = newwin(screeny - 1, screenx - 5, 2, 6);
	wbkgd(contentwin, COLOR_PAIR(1));

	for (i = 0; i < screeny - 1; i++) {
		mvwprintw(linenumwin, i, 0, "%5u\n", i + 1);
	}

	mvwprintw(headerwin, 0, 0, "Test");

	scrollok(linenumwin, TRUE);
	scrollok(contentwin, TRUE);

	refresh();
	wrefresh(linenumwin);
	wrefresh(headerwin);
	wrefresh(contentwin);
}

int main(int argc, char **argv) {
	//int x, y;

	int c;
	unsigned short numcols = 0;
	unsigned int i;
	char indicator = 0;
	struct windim work;
	int exit;

	opterr = 0;

	while ((c = getopt (argc, argv, "c:hi")) != -1) {
		switch (c) {
			case 'c':
				numcols = atoi(optarg);
				break;
			case 'i':
				indicator = 1;
				break;
			case 'h':
				printf("usage: %s [-c numcols] [-i] [-h] filename\n", argv[0]);
				return(1);
				break;
			case '?':
				if (optopt == 'c')
					fprintf (stderr, "Option -%c requires an argument.\n", optopt);
				else if (isprint (optopt))
					fprintf (stderr, "Unknown option '-%c'.\n", optopt);
				else
					fprintf (stderr, "Unknown option character '\\x%x'.\n", optopt);
				return(1);
		}
	}

	FILE *ptr_myfile;
	char *buffer;
	unsigned int rownum = 0;

	for (i = optind; i < argc; i++) {
		if ((ptr_myfile=fopen(argv[i],"r")) == NULL) {
			fprintf(stderr, "Please, provide file in tptbin format!\n");
			return(1);
		} else {
			break;
		}
	}

	// allocate memory for one record
	buffer = (char *)malloc(MAXBUF+1);
	char *p;
	p = buffer;
	if (!buffer) {
		fprintf(stderr, "Memory error!");
		fclose(ptr_myfile);
		return(8);
	}

	// clear buffer
	for (i = 0; i < sizeof(buffer); i++) {
		buffer[i] = 0x00;
	}

	setlocale(LC_CTYPE, "");

	CursesInitialSetup(&work);

	while (!feof(ptr_myfile)) {

		unsigned short rowlen;
		size_t bytesread;
		int numofcols = 0;

		// read the row len definition from file (2 bytes)
		bytesread = fread(&rowlen, 1, sizeof(rowlen), ptr_myfile);

		if (bytesread == sizeof(rowlen)) {

			// read the row data based on the known length
			bytesread = fread(p, 1, rowlen, ptr_myfile);

			if (bytesread == rowlen) {

				// clear buffer before loading it again
				for (i = 0; i < rowlen; i++) {
					*p[i] = 0x00;
				}

				// calculate here
				numofcols = CalcNumberColumns(buffer, rowlen, indicator, numcols);

				if (numofcols > 0) {
				}

			} else {

				// row len definition in file does not meet actual row len
				fprintf(stderr, "Row %d: Row len definition in file does not meet actual row len\n", rownum);
				exit = 3;
				break;

			}

			rownum++;

		} else {

			// not able to read row len definition in file
			fprintf(stderr, "Row %d: Not able to read row len definition in file\n", rownum);
			exit = 1;
			break;

		}

	}

	fclose(ptr_myfile);
	free(buffer);

	getch();
	return(0);
}
