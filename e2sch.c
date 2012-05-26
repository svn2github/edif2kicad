/*
 * e2sch - EDIF to KiCad schematic
 */
#define global

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ed.h"
#include "eelibsl.h"

int bug=0;  		// debug level: 
int yydebug=0;

char *InFile = "-";

char  FileNameNet[80], FileNameLib[80], FileNameEESchema[80], FileNameKiPro[80];
FILE *FileEdf, *FileNet, *FileEESchema=NULL, *FileLib=NULL, *FileKiPro=NULL;

global struct inst               *insts=NULL, *iptr=NULL;
global struct con                *cons=NULL,  *cptr=NULL;
global int pass2=0;
global float scale;
global char  efName[50];

main(int argc, char *argv[])
{
  char * version      = "0.99";
  char * progname;
  extern int nPages;
  extern struct pwr  *pgs;

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

  Libs=NULL; strcpy(fName,"");
  fprintf(stderr, "Parsing %s & writing .sch file\n", InFile);
  ParseEDIF(FileEdf, stderr) ; 

  fprintf(stderr, "\n%s Libs -> cache <<<<\n", progname);
  sprintf(FileNameLib,"%s.cache.lib", fName);
  if( (FileLib = fopen( FileNameLib, "wt" )) == NULL ) {
	 printf( " %s impossible too create\n", FileNameLib);
     return(-1);
  }
  OutLibHead(FileLib, Libs );

  for( ; Libs != NULL; Libs = Libs->nxt ){
	SaveActiveLibrary(FileLib, Libs );
  }
  OutLibEnd(FileLib); 

  pass2++;
//  freopen(InFile, "rt", FileEdf);

  fprintf(stderr, " %d Pages\n",nPages);
  fprintf(stderr, " BonJour\n");
  exit(0);
}
