/*************************************************************************
*
* Title: BLKEXITR - sample INMOD routine
*
* COPYRIGHT (C) Teradata Corporation. 2005
*
* This copyrighted material is the Confidential, Unpublished 
* Property of the Teradata Corporation.  This copyright notice and 
* any other copyright notices included in machine readable 
* copies must be reproduced on all authorized copies.
*
*
* Description  This file contains a sample INMOD, written in C.
*              This file supports DBS restarts.
*
*
* History Information
*
* Revision    Date     DCR   DID     Comments
* ----------- -------- ----- ------- ---------------------------------------
* 13.00.00.01 09072007 114414 NT185003 Teradata Corporation Copyright
* 13.00.00.00 09012007 100894 SV185048 Visual Studio 8.0 build          
* 07.07.00.01 06/23/05 96206 CSG     Port to HPUX-11.23 on Itanium
* 07.01.00.01 11/12/98 44120 SF3     Release for FastLoad 7.1
* 06.00.00.00 07/18/96 34208 SF3     Release for FastLoad 6.0
*               
*
* How to build this INMOD on a Unix system:
*
*    Compile and link it into a shared object:
*
*       cc -G -KPIC <inmod-name>.c -o <shared-object-name>
*
*
* How to use this program:
*
*   This INMOD routine will generate 2 columns of data:
*
*      4-byte integer counter for the Unique Primary Index
*      10-byte character string
*
* This sample INMOD will generate 100,000 rows, if no RECORD
* statement is used in the FastLoad job script.
*
* A sample of the job script for this INMOD would be as follows:
*
*
* use your own system, account and password here.
*
LOGON tdpid/user,password;

DROP TABLE Error_1;
DROP TABLE Error_2;
DROP TABLE TestTable;

CREATE TABLE TestTable AS (
   Counter Integer,
   text    char(10) )
UNIQUE PRIMARY INDEX(Counter);

BEGIN LOADING TestTable ErrorFiles Error_1, Error_2;
     
DEFINE 
   Counter (Integer),
   text    (char(10))
INMOD=ebcdic2tpt.so;

INSERT INTO TestTable 
   (Counter, text)
VALUES 
   (:Counter, :text);

END LOADING;
LOGOFF;

*************************************************************************/

#include <stdio.h>
#include <string.h>

#define FILEOF     401
#define EM_OK      0

#define NUMROWS    100000
#define ROWSIZE    64000
              
typedef int Int32; /* DR 96206 */
typedef unsigned int UInt32; /* DR 96206 */
typedef short Int16;

typedef struct inmod_struct {
   Int32 ReturnCode;
   Int32 Length;
   char  Body[ROWSIZE];
} inmdtyp,*inmdptr;

inmdptr inmodptr;

char *str = "123test890";
char *fname = "chkpoint.dat";

FILE *fp = NULL;

Int32 reccnt = 0;
Int32 chkpnt;


/*************************************************************************
*
* Convert external data (is plain text, but ebcdic character set)
*
* Examples are: Timestamp, Date, String
*
* From: http://stackoverflow.com/questions/7734275/c-code-to-convert-ebcdic-printables-to-ascii-in-place
*
*************************************************************************/
static const unsigned char e2a[256] = {
      0,   1,   2,   3, 156,   9, 134, 127, 151, 141, 142,  11,  12,  13,  14,  15,
     16,  17,  18,  19, 157, 133,   8, 135,  24,  25, 146, 143,  28,  29,  30,  31,
    128, 129, 130, 131, 132,  10,  23,  27, 136, 137, 138, 139, 140,   5,   6,   7,
    144, 145,  22, 147, 148, 149, 150,   4, 152, 153, 154, 155,  20,  21, 158,  26,
    32,  160, 226, 228, 224, 225, 227, 229, 231, 241,  91,  46,  60,  40,  43,  33,
    38,  233, 234, 235, 232, 237, 238, 239, 236, 223,  93,  36,  42,  41,  59,  94,
    45,   47, 194, 196, 192, 193, 195, 197, 199, 209, 166,  44,  37,  95,  62,  63,
    248, 201, 202, 203, 200, 205, 206, 207, 204,  96,  58,  35,  64,  39,  61,  34,
    216,  97,  98,  99, 100, 101, 102, 103, 104, 105, 171, 187, 240, 253, 254, 177,
    176, 106, 107, 108, 109, 110, 111, 112, 113, 114, 170, 186, 230, 184, 198, 164,
    181, 126, 115, 116, 117, 118, 119, 120, 121, 122, 161, 191, 208, 221, 222, 174,
    162, 163, 165, 183, 169, 167, 182, 188, 189, 190, 172, 124, 175, 168, 180, 215,
    123,  65,  66,  67,  68,  69,  70,  71,  72,  73, 173, 244, 246, 242, 243, 245,
    125,  74,  75,  76,  77,  78,  79,  80,  81,  82, 185, 251, 252, 249, 250, 255,
    92,  247,  83,  84,  85,  86,  87,  88,  89,  90, 178, 212, 214, 210, 211, 213,
    48,   49,  50,  51,  52,  53,  54,  55,  56,  57, 179, 219, 220, 217, 218, 159
};

unsigned char* ebcdicToAscii (unsigned char *sfrom, unsigned char *sto, size_t len)
{
    for (size_t i = 0; i < len; i++)
        sto[i] = e2a[sfrom[i]];

    return(i);
}


/*************************************************************************
*
* Convert packed decimal
*
*************************************************************************/
unsigned char* packeddecimal2integer (unsigned char *sfrom, unsigned char *sto, size_t len)
{
    /*
        "integer" is here not really correct
        Based on the number of bytes in source string, it will convert to
        BYTEINT, SMALLINT, INTEGER, BIGINTEGER, VERYBIGINTEGER (1, 2, 4, 8 or 16 bytes)
        As there is no decimal point involved, it is always without fractional digits.
        The processing afterwards needs to know, if it needs to interpret a decimal point into this data.
    */

    for (size_t i = 0; i < len; i++)
    {
    }

    return(0);
}


/*************************************************************************
*
* MakeRecord - Generate a record
*
*    This module creates the data record
*
*    In this example, we are just generating dummy records
*    with canned data, only we change the first column,
*    essentially a record number, so that each row is unique.
*
*************************************************************************/
Int32 MakeRecord()
{
   char *p;

   /* have we reached EOF yet? */

   if (reccnt >= NUMROWS)
      return(FILEOF);

   /* nope. get start of buffer */

   p = inmodptr->Body;

   /* place column 1, a unique primary index */

   memcpy(p, &reccnt, (UInt32)sizeof(reccnt));          /*DR96206*/
   p += sizeof(reccnt);

   /* place column 2, a string */

   memcpy(p, str, strlen(str));
   p += strlen(str);

   inmodptr->ReturnCode = 0;
   inmodptr->Length = p - inmodptr->Body;

   reccnt++;

   return(EM_OK);
}

/*************************************************************************
*
* HostRestart - Host restarted 
*
*    Retrieve the checkpoint information from the checkpoint file.
*    Reset record counter to checkpoint value
*
*************************************************************************/
Int32 HostRestart()
{
   Int32 result;

   /* see if the file is already open */

   if (!fp) {
      fp = fopen(fname, "r+");
      if (!fp)
         return(!EM_OK);
   }

   rewind(fp);
   result = fread(&chkpnt, sizeof(chkpnt), 1, fp);
   if (result != 1) {
      fprintf(stderr, "INMOD: ERROR READING CHECKPOINT FILE\n");
      fprintf(stderr, "INMOD: %d ELEMENTS WERE READ\n", result);
      perror("INMOD");
      return(!EM_OK);
   }

   fprintf(stderr, "INMOD: HOST RESTARTED. CHECKPOINT: %d\n", chkpnt);

   reccnt = chkpnt;

   return(EM_OK);
}

/*************************************************************************
*
* CheckPoint - Save checkpoint
*
*************************************************************************/
Int32 CheckPoint()
{
   Int32 result;

   chkpnt = reccnt;

   rewind(fp);
   result = fwrite(&chkpnt, sizeof(chkpnt), 1, fp);
   if (result != 1) {
      fprintf(stderr, "INMOD: ERROR WRITING TO CHECKPOINT FILE\n");
      fprintf(stderr, "INMOD: %d ELEMENTS WERE WRITTEN\n", result);
      perror("INMOD");
      return(!EM_OK);
   }

   fprintf(stderr, "INMOD: CHECKPOINT AT ROW: %d\n", chkpnt);

   return(EM_OK);
}
 
/*************************************************************************
*
* DBSRestart - DBS restarted 
*
*    Retrieve the checkpoint information from the checkpoint file.
*    Reset record counter to checkpoint value
*
*************************************************************************/
Int32 DBSRestart()
{
   Int32 result;

   /* see if the file is already open */

   if (!fp) {
      fp = fopen(fname, "r+");
      if (!fp)
         return(!EM_OK);
   }

   rewind(fp);
   result = fread(&chkpnt, sizeof(chkpnt), 1, fp);
   if (result != 1) {
      fprintf(stderr, "INMOD: ERROR READING CHECKPOINT FILE\n");
      fprintf(stderr, "INMOD: %d ELEMENTS WERE READ\n", result);
      perror("INMOD");
      return(!EM_OK);
   }

   fprintf(stderr, "INMOD: DBS RESTARTED. CHECKPOINT: %d\n", chkpnt);

   reccnt = chkpnt;

   return(EM_OK);
}

/*************************************************************************
*
* CleanUp - Do cleanup.
*
*    Here we close the file and then remove it.
*
*************************************************************************/
Int32 CleanUp()
{
   fclose(fp);
   remove(fname);
   return(EM_OK);
}
 
/*************************************************************************
*
* InvalidCode - Invalid INMOD code returned.
*
*************************************************************************/
Int32 InvalidCode()
{
   fprintf(stderr, "**** Invalid code received by INMOD\n");
   return(EM_OK);
}
 
/*************************************************************************
*
* Init - initialize some stuff
*
*    Do any initialization necessary
*
*    For this example, we will open a disk file to hold
*    the checkpoint information. For this example, we
*    will just store the row number. If this INMOD was
*    reading data from a file, then the file position
*    would need to be stored.
*
*************************************************************************/
Int32 Init()
{
   fp = fopen(fname, "w");
   if (!fp)
      return(!EM_OK);

   return(EM_OK);
}

/*************************************************************************
*
* BLKEXIT - Start processing
*
*    This is the main module which contains the checks for
*    number of records generated and buffer filling.  This
*    module also sends the filled buffer to the DBS.
*
*************************************************************************/
#if defined WIN32
__declspec(dllexport) Int32 BLKEXIT(tblptr)
#elif defined I370
Int32 _dynamn(tblptr)
#else
Int32 BLKEXIT(tblptr)
#endif
char *tblptr;
{
   Int32 result;
 
   inmodptr = (struct inmod_struct *)tblptr;

   /* process the function passed to the INMOD */

   switch (inmodptr->ReturnCode) {
      case 0:  result = Init();
               if (result)
                  break;
               result = MakeRecord();
               break;
      case 1:  result = MakeRecord();
               break;
      case 2:  result = HostRestart();
               break;
      case 3:  result = CheckPoint();
               break;
      case 4:  result = DBSRestart();
               break;
      case 5:  result = CleanUp();
               break;
      default: result = InvalidCode();
   }

   /* see if we have reached EOF condition */

   if (result == FILEOF) {
      inmodptr->Length = 0;
      result = EM_OK;
   }

   return(result);
}

