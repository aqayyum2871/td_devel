/*
    Rowcount for TPT binary file format

    If reading from stdin is desired, then no argument is allowed

    Read two bytes from the beginning of the file, this number is the row length.
    Seek ahead for this number of bytes. This is one record.
    Read another two bytes, this is the number of bytes for the next row.
    Seek ahead for this number of bytes. This is another record.
    and so on ....
*/

#include "Standards.h"
#include <stdio.h>
#include <unistd.h>
#include <malloc.h>

int main(int argc, char **argv) {

    char *filename;
    filename = NULL;
    int i = 0;
    int sumrowcount = 0;
    int openerror = 0;
    int readerror = 0;
    int filecount = 0;

    unsigned short rowlen;

    if (argc < 2) {

        // no arguments given
        // coming from stdin

        int rowcount = 0;
        char *buffer;
        // allocate memory for one record
        buffer = (char *)malloc(MAXBUF+1);
        if (!buffer) {
            fprintf(stderr, "Memory error!");
            return(8);
        }

        while ( fread(&rowlen, sizeof(rowlen), 1, stdin) ) {
            if (rowlen <= MAXBUF) {
                fread(&buffer, rowlen, 1, stdin);
            } else {
                fprintf(stderr, "No row length of more than %d characters supported!\n", MAXBUF);
                return(1);
            }
            rowcount++;
        }

        fprintf(stdout, "%d %s\n", rowcount, "total");

    } else {
 
        // try every argument if it is a file
        for (i=1; i < argc; i++) {

            int rowcount = 0;
            int result = access(argv[i], F_OK);
            if (result == 0) {
                // it is a file
                filename = argv[i];
            } else {
                // argument is not a file, ignore it
                continue;
            }

            int lreaderror = 0;

            FILE *fp;
            fp=fopen(filename, "rb");

            if (!fp) {
                fprintf(stderr, "File open error on %s!\n", filename);
                openerror++;
                continue;
            }

            while ( fread(&rowlen, sizeof(rowlen), 1, fp) ) {
                if (fseek(fp, rowlen, SEEK_CUR)) {
                    fprintf(stderr, "File %s corrupt?\n", filename);
                    readerror++;
                    lreaderror++;
                    break;
                }
                rowcount++;
            }

            fclose(fp);

            if (lreaderror == 0) {
                fprintf(stdout, "%d %s\n", rowcount, filename);
                filecount++;
                sumrowcount += rowcount;
            }

        }

        if (filecount > 1) {
            fprintf(stdout, "%d %s\n", sumrowcount, "total");
        }

    }

    return(0);

}
