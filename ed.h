/*
 * ed.h
 */
#ifndef E_H
#define E_H

#ifndef global
#define global extern
#endif

#define YYDEBUG 1

#define IDENT_LENGTH            255
#define Malloc(s)               malloc(s)
#define Free(p)                 free(p)
#define ABS(v)                  ((v) < 0 ? -(v) : (v))
#define Getc(s)                 getc(s)
#define Ungetc(c)               ungetc(c,Input);

extern int atoi();
extern int bug;

struct inst {
  char          *ins, *sym;
  struct inst   *nxt;
};

char *cur_nnam;

struct con  {
  char          *ref;
  char          *pin;
  char          *nnam;
  struct con    *nxt;
};

struct pt   { int x,y;};
struct st   { char *s; struct pt *p; int n; struct st *nxt;};
struct plst { struct pt *xy; struct plst *nxt;};

#endif

/*
ViewRef :       VIEWREF ViewNameRef _ViewRef PopC
                {
                $$=$2; if(bug>2)fprintf(Error,"ViewRef: %25s ", $3);
                iptr = (struct inst *)Malloc(sizeof (struct inst));
                iptr->sym = $3;
                iptr->nxt = insts;
                insts = iptr;
                }
*/
