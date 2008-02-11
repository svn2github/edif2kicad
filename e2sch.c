/*
 * e2sch - EDIF to KiCad schematic
 */
#define global

#include <stdio.h>
#include "ed.h"
#include "eelibsl.h"

int bug=4;  		// debug level: 
int yydebug=0;

char *InFile = "-";

char  FileNameNet[64], FileNameLib[64], FileNameEESchema[64], FileNameKiPro[64];
FILE * FileEdf, * FileNet, * FileEESchema, * FileLib=NULL, * FileKiPro=NULL;

global char                      *cur_nnam=NULL;
global struct inst               *insts=NULL, *iptr=NULL;
global struct con                *cons=NULL,  *cptr=NULL;
global float scale;

main(int argc, char *argv[])
{
  char * version      = "0.9";
  char * progname;

  progname = strrchr(argv[0],'/');
  if (progname)
    progname++;
  else
    progname = argv[0];

  fprintf(stderr,"*** %s Version %s ***\n", progname, version);

  if( argc != 2 ) {
     fprintf(stderr, " usage: %s EDIDsrc \n") ; return(1);
  }

  InFile= argv[1];
  if( (FileEdf = fopen( InFile, "rt" )) == NULL ) {
       fprintf(stderr, " %s non trouve\n", InFile);
       return(-1);
  }

  sprintf(FileNameEESchema,"%s.sch",argv[1]);
  if( (FileEESchema = fopen( FileNameEESchema, "wt" )) == NULL ) {
       fprintf(stderr, " %s impossible a creer\n", FileNameEESchema);
       return(-1);
  }

  sprintf(FileNameKiPro,"%s.pro",argv[1]);
  if( (FileKiPro = fopen( FileNameKiPro, "wt" )) == NULL ) {
       fprintf(stderr, " %s impossible a creer\n", FileNameKiPro);
       return(-1);
  }

  Libs=NULL;
  fprintf(stderr, "Parsing %s\n", InFile);
  ParseEDIF(FileEdf, stderr);
  fprintf(FileEESchema,"$EndSCHEMATC\n");
  fclose(FileEESchema);

  fprintf(stderr, "Writting Libs \n");
  for( ; Libs != NULL; Libs = Libs->nxt ){
        sprintf(FileNameLib,"%s.lib", Libs->Name);
        if( (FileLib = fopen( FileNameLib, "wt" )) == NULL ) {
            printf( " %s impossible a creer\n", FileNameLib);
            return(-1);
        }
        fprintf(stderr," writing %s %d parts\n", FileNameLib, Libs->NumOfParts);
        SaveActiveLibrary(FileLib, Libs );
        fclose(FileLib);
  }

  fprintf(stderr, " BonJour\n");
  return(0);
}

