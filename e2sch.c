/*
 * e2sch - EDIF to KiCad schematic
 */
#define e_global

#include <stdio.h>
#include "ed.h"

char *InFile = "-";

extern int yydebug;
int bug;  		// debug level: >2 netlist, >5 schematic, >8 all

char FileNameEdf[64], FileNameNet[64], FileNameSdtLib[64], FileNameEESchema[64];
FILE * FileEdf, * FileNet, * FileEESchema, * FileSdtLib=NULL;

e_global char *cur_nnam=NULL; 
e_global struct inst *insts=NULL, *iptr=NULL; 
e_global struct con  *cons=NULL,  *cptr=NULL;

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

  printf("*** %s Version %s ***\n", progname, version);

  if( argc != 2 ) {
     printf( " usage: %s EDIDsrc \n") ; return(1);
  }

  sprintf(FileNameEdf,"%s",argv[1]);
  sprintf(FileNameEESchema,"%s.sch",argv[1]);
  sprintf(FileNameSdtLib,"%s.src",argv[1]);
  if( (FileEdf = fopen( FileNameEdf, "rt" )) == NULL ) {
       printf( " %s non trouve\n", FileNameEdf);
       return(-1);
  }

  if( (FileEESchema = fopen( FileNameEESchema, "wt" )) == NULL ) {
       printf( " %s impossible a creer\n", FileNameEESchema);
       return(-1);
  }

  fprintf(FileEESchema,"EESchema Schematic File Version 1\n");
  fprintf(FileEESchema,"LIBS:none\n");
  fprintf(FileEESchema,"EELAYER 0 0\nEELAYER END\n");

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
