#include <stdlib.h> //noetig fuer atexit()
#include <curses.h>
#include <locale.h>
#include "CalcNumberColumns.h"

WINDOW *headerwin;
WINDOW *linenumwin;
WINDOW *contentwin;

void quit() {
	delwin(headerwin);
	delwin(linenumwin);
	//delwin(contentwin);
	endwin();
}

void CursesInitialSetup(void) {
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

	refresh();
	wrefresh(linenumwin);
	wrefresh(headerwin);
	wrefresh(contentwin);
}

int main(void) {
	//int x, y;

	setlocale(LC_CTYPE, "");

	CursesInitialSetup();

	getch();
	return(0);
}
