#include <stdio.h>

id(int j)
{
printf("\n");
for( ; j>0 ; j--)
   printf(" ");
}

main()
{   
    int ch, i=0, j=0, wh=0, last=0;

    while((ch = getchar()) != EOF){
	switch (ch) {
	case '(':
	    if( last == ')')
	        id(i);
	    i++; j=i+1;
	    wh=0;
	    break;

	case ')':
	    if(--j == i){
	        printf(")");
		if(i>0)i--;
		last=ch;
	        continue;
	    }
	    wh=0;
	    break;

	case '\r':
	case '\n':

	case ' ':
	case '\t':
	    if(wh++ != 0)
		continue;
	    ch=' ';
	    break;

        default:
 	    wh=0;
	    break;
	}
	last = ch;
    	printf("%c", ch);
    }
}
