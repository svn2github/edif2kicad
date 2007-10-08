/*
 * e2sch - EDIF to KiCad schematic
 */
#define global

#include <stdio.h>
#include "ed.h"
#include "eelibsl.h"

char *InFile = "-";

int yydebug=0;
int bug=0;  		// debug level: 0 off, >5 netlist, >2 schematic, >8 all

char FileNameEdf[64], FileNameNet[64], FileNameLib[64], FileNameEESchema[64];
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

  printf("*** %s Version %s ***\n", progname, version);

  if( argc != 2 ) {
     printf( " usage: %s EDIFsrc \n") ; return(1);
  }

  sprintf(FileNameEdf,"%s",argv[1]);
  sprintf(FileNameLib,"%s.lib",argv[1]);
  if( (FileEdf = fopen( FileNameEdf, "rt" )) == NULL ) {
       printf( " %s non trouve\n", FileNameEdf);
       return(-1);
  }

  if( (FileLib = fopen( FileNameLib, "wt" )) == NULL ) {
       printf( " %s impossible a creer\n", FileNameLib);
       return(-1);
  }

  LibEntry = (LibraryEntryStruct *) Malloc(sizeof(LibraryEntryStruct));
  LibEntry->Type = ROOT;
  LibEntry->PrefixSize =  DEFAULT_SIZE_TEXT;
  LibEntry->PrefixPosY = PIN_WIDTH;
  LibEntry->NamePosY = - PIN_WIDTH;
  LibEntry->NameSize =  DEFAULT_SIZE_TEXT;
  LibEntry->Prefix[0] = 'U';
  LibEntry->Prefix[1] = 0; LibEntry->DrawPrefix = 1;
  LibEntry->TextInside = 30;
  LibEntry->DrawPinNum = 1;
  LibEntry->DrawPinName = 1;
  LibEntry->NumOfUnits = 1;
  LibEntry->Fields = NULL;
  LibEntry->Drawings = NULL;
  LibEntry->nxt = NULL;

  CurrentLib = (LibraryStruct *) Malloc(sizeof(LibraryStruct));
  strncpy(CurrentLib->Name,FileNameLib,40);
  CurrentLib->NumOfParts=0; CurrentLib->Entries = LibEntry;
  CurrentLib->nxt=NULL;

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

  printf(" writing %s\n", FileNameLib);
  Libs = CurrentLib;
  for( ; Libs != NULL; Libs = Libs->nxt ){
	// fprintf(FileLib,"### Library: %s ###\n", Libs->Name);
	SaveActiveLibrary(FileLib, Libs );
  }
  fclose(FileLib);

  printf(" GoodBye\n");
  return(0);
}
