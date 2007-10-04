/*
 * e2net - EDIF to KiCad netlist
 */
#define global

#include <stdio.h>
#include "ed.h"
#include "eelibsl.h"

char *InFile = "-";

extern int yydebug;
int bug;  		// debug level: >2 netlist, >5 schematic, >8 all

char FileNameEdf[64], FileNameNet[64], FileNameSdtLib[64], FileNameEESchema[64];
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

  printf("*** %s Version %s ***\n", progname, version);

  // if( argc != 2 ) {
  //    printf( " usage: %s EDIDsrc \n") ; return(1);
  // }

  if( argc != 2 ){
     FileEdf = stdin;
     FileNet = stdout;
  }else{
     sprintf(FileNameEdf,"%s",argv[1]);
     sprintf(FileNameNet,"%s.net",argv[1]);
     if( (FileEdf = fopen( FileNameEdf, "rt" )) == NULL ) {
          printf( " %s non trouve\n", FileNameEdf);
          return(-1);
     }

     if( (FileNet = fopen( FileNameNet, "wt" )) == NULL ) {
          printf( " %s impossible a creer\n", FileNameNet);
          return(-1);
     }
  }

  ParseEDIF(FileEdf, stderr);

  // bubble sort cons by ref
  struct con *start, *a, *b, *c, *e = NULL, *tmp;
  char line[80], s1[40], s2[40], *s;

//  for (start=cons ; start != NULL ; start = start->nxt ){
//      printf("%s %25s %s\n", start->ref, start->pin, start->nnam);
//  }

  while (e != cons->nxt ) {
    c = a = cons; b = a->nxt;
    while(a != e) {
      sprintf(s1, "%s%25s", a->ref, a->pin);
      sprintf(s2, "%s%25s", b->ref, b->pin);
      if( strcmp( s1, s2 ) >0 ) {
        if(a == cons) {
          tmp = b->nxt; b->nxt = a; a->nxt = tmp;
          cons = b; c = b;
        } else {
          tmp = b->nxt; b->nxt = a; a->nxt = tmp;
          c->nxt = b; c = b;
        }
      } else {
        c = a; a = a->nxt;
      }
      b = a->nxt;
      if(b == e)
        e = a;
    }
  }

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

  // output kicad netlist
  int  first=1;

  fprintf(FileNet,"( { netlist created  13/9/2007-18:11:44 }\n");
  // by component
  strcpy(s1,  "" );
  while (cons != NULL){
    if(strcmp(s1, cons->ref) != 0) {
      if(!first) fprintf(FileNet," )\n");
      for( s=NULL, iptr=insts ; iptr != NULL ; iptr = iptr->nxt ){
	if( !strcmp(cons->ref, iptr->ins)){
	   s = iptr->sym;
	   break;
	}
      }	
      fprintf(FileNet," ( 84DFBB8F $noname %s %s  {Lib=%s}\n", cons->ref, s, s);
      first=0;
    }
    fprintf(FileNet,"  (%5s %s )\n",cons->pin, cons->nnam);
    strcpy(s1,  cons->ref);
    cons = cons->nxt;
  }
  fprintf(FileNet," )\n)\n");

  fclose(FileEdf);
  fclose(FileNet);
  
  if( FileNet != stdout )
    printf("  output is %s \n", FileNameNet);
  return(0);
}
