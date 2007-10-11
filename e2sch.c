/*
 * e2sch - EDIF to KiCad schematic
 */
#define global

#include <stdio.h>
#include "ed.h"
#include "eelibsl.h"

int yydebug=0;
int bug=0;  		// debug level: >2 netlist, >5 schematic, >8 all

char *InFile = "-";

char  FileNameNet[64], FileNameSdtLib[64], FileNameEESchema[64];
FILE * FileEdf, * FileNet, * FileEESchema, * FileSdtLib=NULL;

global char                      *cur_nnam=NULL;
global struct inst               *insts=NULL, *iptr=NULL;
global struct con                *cons=NULL,  *cptr=NULL;

main(int argc, char *argv[])
{
  char * version      = "0.9";
  char * progname;

  yydebug=0; bug=0;
//  yydebug=0; bug=3;  
//  yydebug=1; bug=9;

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
  sprintf(FileNameEESchema,"%s.sch",argv[1]);
  sprintf(FileNameSdtLib,"%s.src",argv[1]);
  if( (FileEdf = fopen( InFile, "rt" )) == NULL ) {
       fprintf(stderr, " %s non trouve\n", InFile);
       return(-1);
  }

  if( (FileEESchema = fopen( FileNameEESchema, "wt" )) == NULL ) {
       fprintf(stderr, " %s impossible a creer\n", FileNameEESchema);
       return(-1);
  }

  fprintf(FileEESchema,"EESchema Schematic File Version 1\n");
  fprintf(FileEESchema,"LIBS:none\n");
  fprintf(FileEESchema,"EELAYER 0 0\nEELAYER END\n");

  Libs=NULL;
  fprintf(stderr, "Parsing %s\n", InFile);
  ParseEDIF(FileEdf, stderr);

#ifdef NOT
  // dump connections by component
  strcpy(s1,  "" );
  for (start=cons ; start != NULL ; start = start->nxt ){
      if(strcmp(s1, start->ref) != 0)
	printf("\n");
      printf("%4s %3s %s\n", start->ref, start->pin, start->nnam);
      strcpy(s1,  start->ref);
  }

  while(insts != NULL){
    printf("%5s %s\n", insts->ins, insts->sym);
    insts = insts->nxt;
  }
#endif


  fclose(FileEdf);
  fclose(FileEESchema);
  if( FileSdtLib ) fclose(FileSdtLib);
  return(0);
}
