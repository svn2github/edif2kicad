/*
 * e2sch - EDIF to KiCad schematic
 */
#define global

#include <stdio.h>
#include "ed.h"
#include "eelibsl.h"

int yydebug=0;
int bug=0;  		// debug level: 0 off, >5 netlist, >2 schematic, >8 all

char *InFile = "-";

char  FileNameNet[64], FileNameLib[64], FileNameEESchema[64];
FILE * FileEdf, * FileNet, * FileEESchema, * FileLib=NULL;

global char 	      		 *cur_nnam=NULL; 
global struct inst    		 *insts=NULL, *iptr=NULL; 
global struct con     		 *cons=NULL,  *cptr=NULL;

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
     fprintf(stderr, " usage: %s EDIFsrc \n") ; return(1);
  }

  InFile= argv[1];
  if( (FileEdf = fopen( InFile, "rt" )) == NULL ) {
       fprintf(stderr, " %s non trouve\n", InFile);
       return(-1);
  }

  fprintf(stderr, "Parsing %s\n", InFile);
  Libs=NULL;
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

  for( ; Libs != NULL; Libs = Libs->nxt ){
	// fprintf(FileLib,"### Library: %s ###\n", Libs->Name);
  	sprintf(FileNameLib,"%s.lib", Libs->Name);
	if( (FileLib = fopen( FileNameLib, "wt" )) == NULL ) {
       	    printf( " %s impossible a creer\n", FileNameLib);
       	    return(-1);
  	}
  	fprintf(stderr," writing %s\n", FileNameLib);
	SaveActiveLibrary(FileLib, Libs );
  	fclose(FileLib);
  }

  fprintf(stderr, " BonJour\n");
  return(0);
}
