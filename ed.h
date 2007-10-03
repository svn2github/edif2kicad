/*
 * ed.h
 */
#ifndef E_H
#define E_H

#ifndef e_global
#define e_global extern
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

struct pt { int x,y;};

#endif
