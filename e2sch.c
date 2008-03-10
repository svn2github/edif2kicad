/*
 * e2sch - EDIF to KiCad schematic
 */
#define global

#include <stdio.h>
#include "ed.h"
#include "eelibsl.h"

int bug=0;  		// debug level: 
int yydebug=0;

char *InFile = "-";

char  FileNameNet[64], FileNameLib[64], FileNameEESchema[64], FileNameKiPro[64];
FILE *FileEdf, *FileNet, *FileEESchema=NULL, *FileLib=NULL, *FileKiPro=NULL;

global struct inst               *insts=NULL, *iptr=NULL;
global struct con                *cons=NULL,  *cptr=NULL;
global int pass2=0;
global float scale;
global char  efName[50];

main(int argc, char *argv[])
{
  char * version      = "0.97";
  char * progname;

  progname = strrchr(argv[0],'/');
  if (progname)
    progname++;
  else
    progname = argv[0];

  fprintf(stderr,"*** %s Version %s ***\n", progname, version);

  if( argc != 2 ) {
     fprintf(stderr, " usage: EDIFfile \n") ; return(1);
  }

  InFile= argv[1];
  if( (FileEdf = fopen( InFile, "r" )) == NULL ) {
       fprintf(stderr, " '%s' doesn't exist\n", InFile);
       return(-1);
  }

  Libs=NULL;
  fprintf(stderr, "Parsing %s & writing .sch file\n", InFile);
  ParseEDIF(FileEdf, stderr);

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

  pass2++;
//  freopen(InFile, "rt", FileEdf);

  fprintf(stderr, " BonJour\n");
  return(0);
}

