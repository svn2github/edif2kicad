%{
/*
 * $ID:   $
 */
/************************************************************************
 *									*
 *				edif.y					*
 *									*
 *			EDIF 2.0.0 parser, Level 0			*
 *									*
 *	You are free to copy, distribute, use it, abuse it, make it	*
 *	write bad tracks all over the disk ... or anything else.	*
 *									*
 *	Your friendly neighborhood Rogue Monster - roger@mips.com	*
 *									*
 ************************************************************************/
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <math.h>

#include "ed.h"
#include "eelibsl.h"


// #define DEBUG
#define SIZE_PIN_TEXT 60

static FILE *Input = NULL;              /* input stream */
static FILE *Error = NULL;              /* error stream */
static int   LineNumber;                /* current input line number */

global char 	   *cur_nnam; 
global struct inst *insts, *iptr; 
global struct con  *cons,  *cptr;
global float  scale;

LibraryEntryStruct	 *LEptr;
LibraryDrawEntryStruct   *New=NULL, *INew, *LDptr;
int  		 num, *Poly, TextSize=SIZE_PIN_TEXT;
char 		*bad="BBBB", *s, fname[30], **eptr;
struct plst 	*pl;
struct st	*stp, *ref, *val;
int convert=1;	  // normal
int savtext=0;    // debug - no text
int skip=1;       // debug - skip for now
float a,b,c,d,e,f,k,h;
int Rot[2][2], Rot90=0, tx, ty, ox=0, oy=0, stop;
int SchHead=1;

%}

%union    { 
	    int n; 
	    float f;
	    struct st   *st;
	    struct pt   *pt;
	    struct plst *pl;
	  }

%type   <n>	Int _Member TextHeight Direction _Direction
%type   <n> 	Orientation _Orientation _DisplayOrien _TransOrien
%type	<f>	ScaledInt

%type   <pl>	Rectangle BoundBox PointList _PointList Path _Path Polygon _Polygon 
%type 	<pl>	Circle 
%type   <pl>	Origin Point _Point PointValue _Rectangle Dot _Dot _DisplayOrg _TransOrg

%type	<st>	StrDisplay _StrDisplay PropDisp _PropDisp KeywordDisp _KeywordDisp 
%type	<st>	Designator _Designator Annotate _Annotate
%type	<st>	Display
%type	<st>	_Display 
%type   <st> 	CommGraph _CommGraph 
%type	<st>	PropNameRef 

%type   <st>	Str String _String KeywordName 
%type   <st>	Ident Name _Name NameDef NameRef EdifFileName
%type   <st>	NetNameDef Array
%type   <st>	CellNameDef CellNameRef CellRef _CellRef Cell 
%type 	<st>	Transform 
%type   <st>	Rename _Rename __Rename
%type   <st>	FigGrp _FigGrp 
%type   <st>	FigGrpNameDef FigGrpOver _FigGrpOver FigGrpNameRef 
%type   <st>	ViewRef _ViewRef ViewNameRef ViewList _ViewList 
// %type	<st>	View ValueNameDef
%type   <st>	Instance _Instance InstanceRef _InstanceRef InstNameDef InstNameRef
%type   <st>	LibNameDef LibraryRef LibNameRef 
%type	<st>	Port _Port PortNameDef PortNameRef PortRef _PortRef Member 
%type	<st>	Design _Design DesignNameDef
%type   <st>	PortImpl _PortImpl ConnectLoc _ConnectLoc PropNameDef
%type	<st>	Interface _Interface 
// %type 	<st>	TypedValue Boolean _Boolean Integer _Integer MiNoMa _MiNoMa Number _Number
%type 	<st>	Boolean _Boolean Integer _Integer MiNoMa _MiNoMa Number _Number
%type	<st>	Property _Property Owner 
%type	<st>	Symbol _Symbol Figure _Figure Comment _Comment
%type	<st>	Justify _Justify _DisplayJust 

%token	<st>	IDENT
%token	<st>	INT
%token	<st>	KEYWORD
%token	<st>	STR
%token	<st>	NAME

%token		ANGLE
%token		BEHAVIOR
%token		CALCULATED
%token		CAPACITANCE
%token		CENTERCENTER
%token		CENTERLEFT
%token		CENTERRIGHT
%token		CHARGE
%token		CONDUCTANCE
%token		CURRENT
%token		DISTANCE
%token		DOCUMENT
%token		ENERGY
%token		EXTEND
%token		FLUX
%token		FREQUENCY
%token		GENERIC
%token		GRAPHIC
%token		INDUCTANCE
%token		INOUT
%token		INPUT
%token		LOGICMODEL
%token		LOWERCENTER
%token		LOWERLEFT
%token		LOWERRIGHT
%token		MASKLAYOUT
%token		MASS
%token		MEASURED
%token		MX
%token		MXR90
%token		MY
%token		MYR90
%token		NETLIST
%token		OUTPUT
%token		PCBLAYOUT
%token		POWER
%token		R0
%token		R180
%token		R270
%token		R90
%token		REQUIRED
%token		RESISTANCE
%token		RIPPER
%token		ROUND
%token		SCHEMATIC
%token		STRANGER
%token		SYMBOLIC
%token		TEMPERATURE
%token		TIE
%token		TIME
%token		TRUNCATE
%token		UPPERCENTER
%token		UPPERLEFT
%token		UPPERRIGHT
%token		VOLTAGE

%token		ACLOAD
%token		AFTER
%token		ANNOTATE
%token		APPLY
%token		ARC
%token		ARRAY
%token		ARRAYMACRO
%token		ARRAYRELATEDINFO
%token		ARRAYSITE
%token		ATLEAST
%token		ATMOST
%token		AUTHOR
%token		BASEARRAY
%token		BECOMES
%token		BETWEEN
%token		BOOLEAN
%token		BOOLEANDISPLAY
%token		BOOLEANMAP
%token		BORDERPATTERN
%token		BORDERWIDTH
%token		BOUNDINGBOX
%token		CELL
%token		CELLREF
%token		CELLTYPE
%token		CHANGE
%token		CIRCLE
%token		COLOR
%token		COMMENT
%token		COMMENTGRAPHICS
%token		COMPOUND
%token		CONNECTLOCATION
%token		CONTENTS
%token		CORNERTYPE
%token		CRITICALITY
%token		CURRENTMAP
%token		CURVE
%token		CYCLE
%token		DATAORIGIN
%token		DCFANINLOAD
%token		DCFANOUTLOAD
%token		DCMAXFANIN
%token		DCMAXFANOUT
%token		DELAY
%token		DELTA
%token		DERIVATION
%token		DESIGN
%token		DESIGNATOR
%token		DIFFERENCE
%token		DIRECTION
%token		DISPLAY
%token		DOMINATES
%token		DOT
%token		DURATION
%token		E
%token		EDIF
%token		EDIFLEVEL
%token		EDIFVERSION
%token		ENCLOSUREDISTANCE
%token		ENDTYPE
%token		ENTRY
%token		EVENT
%token		EXACTLY
%token		EXTERNAL
%token		FABRICATE
%token		FALSE
%token		FIGURE
%token		FIGUREAREA
%token		FIGUREGROUP
%token		FIGUREGROUPOBJECT
%token		FIGUREGROUPOVERRIDE
%token		FIGUREGROUPREF
%token		FIGUREPERIMETER
%token		FIGUREWIDTH
%token		FILLPATTERN
%token		FOLLOW
%token		FORBIDDENEVENT
%token		GLOBALPORTREF
%token		GREATERTHAN
%token		GRIDMAP
%token		IGNORE
%token		INCLUDEFIGUREGROUP
%token		INITIAL
%token		INSTANCE
%token		INSTANCEBACKANNOTATE
%token		INSTANCEGROUP
%token		INSTANCEMAP
%token		INSTANCEREF
%token		INTEGER
%token		INTEGERDISPLAY
%token		INTERFACE
%token		INTERFIGUREGROUPSPACING
%token		INTERSECTION
%token		INTRAFIGUREGROUPSPACING
%token		INVERSE
%token		ISOLATED
%token		JOINED
%token		JUSTIFY
%token		KEYWORDDISPLAY
%token		KEYWORDLEVEL
%token		KEYWORDMAP
%token		LESSTHAN
%token		LIBRARY
%token		LIBRARYREF
%token		LISTOFNETS
%token		LISTOFPORTS
%token		LOADDELAY
%token		LOGICASSIGN
%token		LOGICINPUT
%token		LOGICLIST
%token		LOGICMAPINPUT
%token		LOGICMAPOUTPUT
%token		LOGICONEOF
%token		LOGICOUTPUT
%token		LOGICPORT
%token		LOGICREF
%token		LOGICVALUE
%token		LOGICWAVEFORM
%token		MAINTAIN
%token		MATCH
%token		MEMBER
%token		MINOMAX
%token		MINOMAXDISPLAY
%token		MNM
%token		MULTIPLEVALUESET
%token		MUSTJOIN
%token		NET
%token		NETBACKANNOTATE
%token		NETBUNDLE
%token		NETDELAY
%token		NETGROUP
%token		NETMAP
%token		NETREF
%token		NOCHANGE
%token		NONPERMUTABLE
%token		NOTALLOWED
%token		NOTCHSPACING
%token		NUMBER
%token		NUMBERDEFINITION
%token		NUMBERDISPLAY
%token		OFFPAGECONNECTOR
%token		OFFSETEVENT
%token		OPENSHAPE
%token		ORIENTATION
%token		ORIGIN
%token		OVERHANGDISTANCE
%token		OVERLAPDISTANCE
%token		OVERSIZE
%token		OWNER
%token		PAGE
%token		PAGESIZE
%token		PARAMETER
%token		PARAMETERASSIGN
%token		PARAMETERDISPLAY
%token		PATH
%token		PATHDELAY
%token		PATHWIDTH
%token		PERMUTABLE
%token		PHYSICALDESIGNRULE
%token		PLUG
%token		POINT
%token		POINTDISPLAY
%token		POINTLIST
%token		POLYGON
%token		PORT
%token		PORTBACKANNOTATE
%token		PORTBUNDLE
%token		PORTDELAY
%token		PORTGROUP
%token		PORTIMPLEMENTATION
%token		PORTINSTANCE
%token		PORTLIST
%token		PORTLISTALIAS
%token		PORTMAP
%token		PORTREF
%token		PROGRAM
%token		PROPERTY
%token		PROPERTYDISPLAY
%token		PROTECTIONFRAME
%token		PT
%token		RANGEVECTOR
%token		RECTANGLE
%token		RECTANGLESIZE
%token		RENAME
%token		RESOLVES
%token		SCALE
%token		SCALEX
%token		SCALEY
%token		SECTION
%token		SHAPE
%token		SIMULATE
%token		SIMULATIONINFO
%token		SINGLEVALUESET
%token		SITE
%token		SOCKET
%token		SOCKETSET
%token		STATUS
%token		STEADY
%token		STRING
%token		STRINGDISPLAY
%token		STRONG
%token		SYMBOL
%token		SYMMETRY
%token		TABLE
%token		TABLEDEFAULT
%token		TECHNOLOGY
%token		TEXTHEIGHT
%token		TIMEINTERVAL
%token		TIMESTAMP
%token		TIMING
%token		TRANSFORM
%token		TRANSITION
%token		TRIGGER
%token		TRUE
%token		UNCONSTRAINED
%token		UNDEFINED
%token		UNION
%token		UNIT
%token		UNUSED
%token		USERDATA
%token		VERSION
%token		VIEW
%token		VIEWLIST
%token		VIEWMAP
%token		VIEWREF
%token		VIEWTYPE
%token		VISIBLE
%token		VOLTAGEMAP
%token		WAVEVALUE
%token		WEAK
%token		WEAKJOINED
%token		WHEN
%token		WRITTEN

%start	Edif

%%

PopC :		')' { PopC(); }
     ;

EdifFileName :	NameDef
		{if(bug>2);fprintf(Error,"EdifFileName: %s\n", $1->s);}
	     ;

Edif  :		EDIF EdifFileName EdifVersion EdifLevel KeywordMap _Edif PopC
      ;

_Edif :
      |		_Edif Status
      |		_Edif External
      |		_Edif Library
      |		_Edif Design
      |		_Edif Comment
      |		_Edif UserData
      ;

EdifLevel :	EDIFLEVEL Int PopC
	  ;

EdifVersion :	EDIFVERSION Int Int Int PopC
		{if(bug>2);fprintf(Error,"EdifVersion: %d %d %d\n", $2,$3,$4);}
	    ;

AcLoad :	ACLOAD _AcLoad PopC
       ;

_AcLoad :	MiNoMaValue
	|	MiNoMaDisp
	;

After :		AFTER _After PopC
      ;

_After :	MiNoMaValue
       |	_After Follow
       |	_After Maintain
       |	_After LogicAssn
       |	_After Comment
       |	_After UserData
       ;

Annotate :	ANNOTATE _Annotate PopC
		{$$=$2; if(bug>4)fprintf(Error," Annotate: %s %d %d\n",$2->s, $2->p->x, $2->p->y);

		if(savtext){
		    New->U.Text.Text = $2->s;
                    if( New->U.Text.Text == NULL )
                        New->U.Text.Text = strdup("AAAA");
                    New->U.Text.x += (New->U.Text.size * strlen(New->U.Text.Text))/2;
                    New->U.Text.y += New->U.Text.size / 2;
		}
		}
	 ;

_Annotate :	STR
	  |	StrDisplay
	  ;

Apply :		APPLY _Apply PopC
      ;

_Apply :	Cycle
       |	_Apply LogicIn
       |	_Apply LogicOut
       |	_Apply Comment
       |	_Apply UserData
       ;

Arc :		ARC PointValue PointValue PointValue PopC
		{
		if(bug>4)fprintf(Error,"New ARC LibraryDrawEntryStruct\n");
		    New = (LibraryDrawEntryStruct *) Malloc(sizeof(LibraryDrawEntryStruct));
                    New->nxt = LibEntry->Drawings;
		    LibEntry->Drawings = New; New->Unit = 0; New->Convert = convert;

                    New->DrawType = ARC_DRAW_TYPE; 
		
		    a=$2->x; b=$2->y; c=$3->x; d=$3->y; e=$4->x; f=$4->y;
		    h = ((a*a+b*b)*(f-d)+(c*c+d*d)*(b-f)+(e*e+f*f)*(d-b))/(a*(f-d)+c*(b-f)+e*(d-b))/2;
		    k = ((a*a+b*b)*(e-c)+(c*c+d*d)*(a-e)+(e*e+f*f)*(c-a))/(b*(e-c)+d*(a-e)+f*(c-a))/2;
		    if(bug>4)fprintf(Error," a=%f b=%f k=%f h=%f\n", a,b,k,h);
                    New->U.Arc.x  = (int) h ;
                    New->U.Arc.y  = (int) k ;
		    New->U.Arc.r = sqrt((a-h)*(a-h) + (b-k)*(b-k));

		    New->U.Arc.t1 = (int)(atan2(b-k, a-h) * 1800 /M_PI);
                    while( New->U.Arc.t1 < 0 ) New->U.Arc.t1 += 3600;
		    New->U.Arc.t2 = (int)(atan2(f-k, e-h) * 1800 /M_PI);
                    while( New->U.Arc.t2 < 0 ) New->U.Arc.t2 += 3600;
                    New->U.Arc.width = 0;
		}
    ;

Array :		ARRAY NameDef Int _Array PopC
		{$$=$2;}
      ;

_Array :
       |	Int
       ;

ArrayMacro :	ARRAYMACRO Plug PopC
	   ;

ArrayRelInfo :	ARRAYRELATEDINFO _ArrayRelInfo PopC
	     ;

_ArrayRelInfo :	BaseArray
	      |	ArraySite
	      |	ArrayMacro
	      |	_ArrayRelInfo Comment
	      |	_ArrayRelInfo UserData
	      ;

ArraySite :	ARRAYSITE Socket PopC
	  ;

AtLeast :	ATLEAST ScaledInt PopC
	;

AtMost :	ATMOST ScaledInt PopC
       ;

Author :	AUTHOR Str PopC
       ;

BaseArray :	BASEARRAY PopC
	  ;

Becomes :	BECOMES _Becomes PopC
	;

_Becomes :	LogicNameRef
	 |	LogicList
	 |	LogicOneOf
	 ;

Between :	BETWEEN __Between _Between PopC
	;

__Between :	AtLeast
	  |	GreaterThan
	  ;

_Between :	AtMost
	 |	LessThan
	 ;

Boolean :	BOOLEAN _Boolean PopC
		{$$=$2;}
	;

_Boolean :
		{$$=NULL;}
	 |	_Boolean BooleanValue
	 |	_Boolean BooleanDisp
	 |	_Boolean Boolean
	 ;

BooleanDisp :	BOOLEANDISPLAY _BooleanDisp PopC
	    ;

_BooleanDisp :	BooleanValue
	     |	_BooleanDisp Display
	     ;

BooleanMap :	BOOLEANMAP BooleanValue PopC
	   ;

BooleanValue :	True
	     |	False
	     ;

BorderPat :	BORDERPATTERN Int Int Boolean PopC
	  ;

BorderWidth :	BORDERWIDTH Int PopC
	    ;

BoundBox    :	BOUNDINGBOX Rectangle PopC
		{$$=$2;}
	    ;

CellNameDef :	NameDef
		{ 
		if(bug>2)fprintf(Error,"CurrLib %s CellNameDef: '%s'\n", CurrentLib->Name, $1->s); 

		if(bug>4)fprintf(Error,"New LibraryEntryStruct\n");
  		LibEntry = (LibraryEntryStruct *) Malloc(sizeof(LibraryEntryStruct));
  		LibEntry->Type = ROOT;
  		LibEntry->PrefixSize =  DEFAULT_SIZE_TEXT;
                LibEntry->PrefixPosX = 0; LibEntry->PrefixPosY = 0;
  		LibEntry->NamePosX   = 0;
  		LibEntry->NamePosY   = 0;
  		LibEntry->NameSize =  DEFAULT_SIZE_TEXT;
  		LibEntry->Prefix[0] = 'U';
  		LibEntry->Prefix[1] = 0; 
		LibEntry->DrawPrefix = 1;
  		LibEntry->TextInside = 30;
  		LibEntry->DrawPinNum = 1;
  		LibEntry->DrawPinName = 1;
  		LibEntry->NumOfUnits = 1;
  		LibEntry->Fields = NULL;
  		LibEntry->Drawings = NULL;
                LibEntry->nxt = CurrentLib->Entries;
                CurrentLib->Entries = LibEntry; CurrentLib->NumOfParts++;
		}
	    ;

Cell        :	CELL CellNameDef _Cell PopC
		{
		$$=$2;
		strcpy(LibEntry->Name, $2->s);
		LibEntry->DrawName = 0;
		}
            ;

_Cell       :	CellType
            |	_Cell Status
            |	_Cell ViewMap
            |	_Cell View
            |	_Cell Comment
            |	_Cell UserData
            |	_Cell Property
            ;

CellNameRef :	NameRef
		{if(bug>2)fprintf(Error,"\nCellNameRef: '%s'\n", $1->s);
		Rot[0][0] = 1; Rot[0][1] = Rot[1][0] = 0; Rot[1][1] = -1; /* Orient NORMAL */
		Rot90 = 0;
		}
	    ;

CellRef     :	CELLREF CellNameRef _CellRef PopC
		{$$=$2; 
		    if(bug>2 && $3==NULL)fprintf(Error," CellRef: '%s' \n", $2->s); 
		    if(bug>2 && $3!=NULL)fprintf(Error," CellRef: '%s' lib:'%s'\n", $2->s, $3->s); 
		// Instance
		    if(bug>4)fprintf(Error,"New LibraryDrawEntryStruct\n");
                    LibEntry = (LibraryEntryStruct *) Malloc(sizeof(LibraryEntryStruct));
                    LibEntry->Type = ROOT;
                    LibEntry->PrefixSize = DEFAULT_SIZE_TEXT;
                    LibEntry->PrefixPosX = 0; LibEntry->PrefixPosY = 0;
  		    LibEntry->NamePosX   = 0; LibEntry->NamePosY   = 0;
                    LibEntry->NameSize   = DEFAULT_SIZE_TEXT;
                    LibEntry->DrawPrefix = 1;
                    LibEntry->TextInside = 30;
                    LibEntry->DrawPinNum = 1;
                    LibEntry->DrawPinName = 1;
                    LibEntry->NumOfUnits = 1;
		    LibEntry->Fields = NULL;
                    strcpy(LibEntry->Prefix, "U");
                    strcpy(LibEntry->Name, $2->s);
                    LibEntry->nxt = CurrentLib->Entries;
                    CurrentLib->Entries = LibEntry; 
		    CurrentLib->NumOfParts++;

		val=$2;
		}
	    ;

LibNameRef :	NameRef
		{if(bug>2)fprintf(Error," LibNameRef: %s\n", $1->s); }
	   ;

LibraryRef :	LIBRARYREF LibNameRef PopC
		{ $$=$2;} 
	   ;

_CellRef    :
		{$$=NULL;}
	    |	LibraryRef
	    ;

CellType    :	CELLTYPE _CellType PopC
	    ;

_CellType   :	TIE
	    |	RIPPER
	    |	GENERIC
	    ;

Change :	CHANGE __Change _Change PopC
       ;

__Change :	PortNameRef
	 |	PortRef
	 |	PortList
	 ;

_Change :
	|	Becomes
	|	Transition
	;

Circle :	CIRCLE PointValue PointValue _Circle PopC
		{
		$$=(struct plst *)Malloc(sizeof(struct plst));
		pl=(struct plst *)Malloc(sizeof(struct plst));
                $$->x=$2->x; $$->y=$2->y; $$->nxt=pl; 
                pl->x=$3->x; pl->y=$3->y; pl->nxt=NULL; 
		}
       ;

_Circle :
	|	_Circle Property
	;

Color :		COLOR ScaledInt ScaledInt ScaledInt PopC
      ;

Comment :	COMMENT _Comment PopC
		{$$=$2; if(bug>5)fprintf(Error,"   Comment: %s\n",$2->s);}
	;

_Comment :	Str
	 |	_Comment Str
		{$$=$2;}
	 ;

CommGraph :	COMMENTGRAPHICS _CommGraph PopC
		{$$=$2;}
          ;

_CommGraph :
		{$$=NULL;}
	   |	_CommGraph Annotate
		{ if(bug>4)fprintf(Error," _CommGra Annot '%s'\n", $2->s); }
	   |	_CommGraph Figure
	   |	_CommGraph Instance
	   |	_CommGraph BoundBox
	   |	_CommGraph Property
	   |	_CommGraph Comment
	   |	_CommGraph UserData
	   ;

Compound :	COMPOUND LogicNameRef PopC
	 ;

Contents :	CONTENTS _Contents PopC
	 ;

_Contents :
	  |	_Contents Instance
	  |	_Contents OffPageConn
	  |	_Contents Figure
	  |	_Contents Section
	  |	_Contents Net
	  |	_Contents NetBundle
	  |	_Contents Page
	  |	_Contents CommGraph
	  |	_Contents PortImpl
	  |	_Contents Timing
	  |	_Contents Simulate
	  |	_Contents When
	  |	_Contents Follow
	  |	_Contents LogicPort
	  |	_Contents BoundBox
	  |	_Contents Comment
	  |	_Contents UserData
	  ;

ConnectLoc :	CONNECTLOCATION _ConnectLoc PopC
		{$$=$2;}
	   ;

_ConnectLoc :
		{$$=NULL;}
	    |	Figure
	    ;

CornerType :	CORNERTYPE _CornerType PopC
	   ;

_CornerType :	EXTEND
	    |	ROUND
	    |	TRUNCATE
	    ;

Criticality :	CRITICALITY _Criticality PopC
	    ;

_Criticality :	Int
	     |	IntDisplay
	     ;

CurrentMap :	CURRENTMAP MiNoMaValue PopC
	   ;

Curve :		CURVE _Curve PopC
      ;

_Curve :
       |	_Curve Arc
       |	_Curve PointValue
       ;

Cycle :		CYCLE Int _Cycle PopC
      ;

_Cycle :
       |	Duration
       ;

DataOrigin :	DATAORIGIN Str _DataOrigin PopC
	   ;

_DataOrigin :
	    |	Version
	    ;

DcFanInLoad :	DCFANINLOAD _DcFanInLoad PopC
	    ;

_DcFanInLoad :	ScaledInt
	     |	NumbDisplay
	     ;

DcFanOutLoad :	DCFANOUTLOAD _DcFanOutLoad PopC
	     ;

_DcFanOutLoad :	ScaledInt
	      |	NumbDisplay
	      ;

DcMaxFanIn :	DCMAXFANIN _DcMaxFanIn PopC
	   ;

_DcMaxFanIn :	ScaledInt
	    |	NumbDisplay
	    ;

DcMaxFanOut :	DCMAXFANOUT _DcMaxFanOut PopC
	    ;

_DcMaxFanOut :	ScaledInt
	     |	NumbDisplay
	     ;

Delay :		DELAY _Delay PopC
      ;

_Delay :	MiNoMaValue
       |	MiNoMaDisp
       ;

Delta :		DELTA _Delta PopC
      ;

_Delta :
       |	_Delta PointValue
       ;

Derivation  :	DERIVATION _Derivation PopC
	    ;

_Derivation :	CALCULATED
	    |	MEASURED
	    |	REQUIRED
	    ;

DesignNameDef :	NameDef
		{if(bug>2)fprintf(Error,"%5d DesignNameDef: '%s'\n",LineNumber, $1->s); }
	      ;

Design 	    :	DESIGN DesignNameDef _Design PopC
		{$$=$2;
		if(bug>0 && $3 != NULL)fprintf(Error,"Design: '%s' '%s'\n\n", $2->s, $3->s); 
		if(bug>0 && $3 == NULL)fprintf(Error,"Design: '%s' ''  \n\n", $2->s); 
		strcpy(CurrentLib->Name, "DESIGN");

		CurrentLib->NumOfParts = 0; // fixme - previous Lib was DESIGN
		}
       	    ;

_Design     :	CellRef
	    |	_Design Status
	    |	_Design Comment
	    |	_Design Property
	    |	_Design UserData
	    ;

Designator  :	DESIGNATOR _Designator PopC
		{$$=$2;} 
	    ;

_Designator :	Str
		{if(bug>4)fprintf(Error,"-%s\n",$1->s);}
	    |	StrDisplay
		{if(bug>2)fprintf(Error," _Designator Disp: %s %d %d\n",$1->s, $1->p->x, $1->p->y); 
		ref = $1;
		}
	    ;

DesignRule :	PHYSICALDESIGNRULE _DesignRule PopC
	   ;

_DesignRule :
	    |	_DesignRule FigureWidth
	    |	_DesignRule FigureArea
	    |	_DesignRule RectSize
	    |	_DesignRule FigurePerim
	    |	_DesignRule OverlapDist
	    |	_DesignRule OverhngDist
	    |	_DesignRule EncloseDist
	    |	_DesignRule InterFigGrp
	    |	_DesignRule IntraFigGrp
	    |	_DesignRule NotchSpace
	    |	_DesignRule NotAllowed
	    |	_DesignRule FigGrp
	    |	_DesignRule Comment
	    |	_DesignRule UserData
	    ;

Difference  :	DIFFERENCE _Difference PopC
	    ;

_Difference :	FigGrpRef
	    |	FigureOp
	    |	_Difference FigGrpRef
	    |	_Difference FigureOp
	    ;

Direction   :	DIRECTION _Direction PopC
		{$$=$2;}
	    ;

_Direction  :	INOUT
		{$$=PIN_BIDI;}
	    |	INPUT
		{$$=PIN_INPUT;}
	    |	OUTPUT
		{$$=PIN_OUTPUT;}
	    ;

Display     :	DISPLAY _Display _DisplayJust _DisplayOrien _DisplayOrg PopC
		{$$ = (struct st *)Malloc(sizeof(struct st));
		 $$->s=$2->s; $$->p=$5; 
		 if(bug>2)fprintf(Error,"%5d Display: '%s' ", LineNumber, $2->s);
		 if(bug>2 && $3 != NULL)fprintf(Error," %s", $3->s);
		 if(bug>2 && $4 != 0   )fprintf(Error," %c", $4);
		 if(bug>2              )fprintf(Error," %d %d\n", $5->x, $5->y);

		 if($4 != 0){
                    // find Pin to add Orient
                    for( LDptr=New ; LDptr != NULL ; LDptr=LDptr->nxt ) {
			if(bug>2)fprintf(Error,"  Check '%s' '%s' %s\n", 
				$$->s, LDptr->U.Pin.Name, LDptr->U.Pin.ReName);
                        if( LDptr->DrawType != PIN_DRAW_TYPE)
                           continue;
                        if(  !strcmp(LDptr->U.Pin.Name, $$->s) )
                           break;
                    }
                    if( LDptr != NULL ){
			if(bug>4)fprintf(Error,"  Found %s\n", LDptr->U.Pin.Name);
                        LDptr->U.Pin.Orient = $4;
                    }
		}
		}
   	    ;

FigGrpNameRef :	NameRef
	      ;

_Display      :	FigGrpNameRef
		{if(bug>2)fprintf(Error,"%5d FigGrpNameRef:'%s'\n", LineNumber, $1->s); }
	      |	FigGrpOver
		{if(bug>2)fprintf(Error,"%5d FigGrpOver:   '%s'\n", LineNumber, $1->s); }
	      ;

_DisplayJust :
		{$$=NULL; if(bug>4)fprintf(Error,"%5d _DisplayJust: NULL\n", LineNumber); }
	     |	Justify
		{         if(bug>4)fprintf(Error,"%5d _DisplayJust: %s\n", LineNumber, $1->s); }
	     ;

_DisplayOrien :
		{$$=0;}
	      |	Orientation
	      ;

_DisplayOrg :
		{if(bug>4)fprintf(Error,"%5d _DisplayOrg: NULL\n", LineNumber); }
	    |	Origin
		{if(bug>4)fprintf(Error,"%5d _DisplayOrg: %d %d \n", LineNumber, $1->x, $1->y); }
	    ;

Dominates :	DOMINATES _Dominates PopC
	  ;

_Dominates :
	   |	_Dominates LogicNameRef
	   ;

Dot 	   :	DOT _Dot PopC
		{$$=$2; if(bug>4)fprintf(Error,"   Dot: %d %d\n", $2->x, $2->y);}
    	   ;

_Dot 	   :	PointValue
     	   |	_Dot Property
     	   ;

Duration :	DURATION ScaledInt PopC
	 ;

EncloseDist :	ENCLOSUREDISTANCE RuleNameDef FigGrpObj FigGrpObj _EncloseDist
		PopC
	    ;

_EncloseDist :	Range
	     |	SingleValSet
	     |	_EncloseDist Comment
	     |	_EncloseDist UserData
	     ;

EndType :	ENDTYPE _EndType PopC
	;

_EndType :	EXTEND
	 |	ROUND
	 |	TRUNCATE
	 ;

Entry :		ENTRY ___Entry __Entry _Entry
		PopC
      ;

___Entry :	Match
	 |	Change
	 |	Steady
	 ;

__Entry :	LogicRef
	|	PortRef
	|	NoChange
	|	Table
	;

_Entry :
       |	Delay
       |	LoadDelay
       ;

Event :		EVENT _Event PopC
      ;

_Event :	PortRef
       |	PortList
       |	PortGroup
       |	NetRef
       |	NetGroup
       |	_Event Transition
       |	_Event Becomes
       ;

Exactly :	EXACTLY ScaledInt PopC
	;

External :	EXTERNAL LibNameDef EdifLevel _External PopC
	 ;

_External :	Technology
	  |	_External Status
	  |	_External Cell
	  |	_External Comment
	  |	_External UserData
	  ;

Fabricate :	FABRICATE LayerNameDef FigGrpNameRef PopC
	  ;

False :		FALSE PopC
      ;

FigGrpNameDef :	NameDef
	      ;

FigGrp  :	FIGUREGROUP _FigGrp PopC
		{$$=$2;}
        ;

_FigGrp :	FigGrpNameDef
		{$$->p=NULL; if(bug>2)fprintf(Error,"%5d _FigGrp: FigGrpNameDef %s\n", LineNumber, $1->s); }
	|	_FigGrp CornerType
	|	_FigGrp EndType
	|	_FigGrp PathWidth
	|	_FigGrp BorderWidth
	|	_FigGrp Color
	|	_FigGrp FillPattern
	|	_FigGrp BorderPat
	|	_FigGrp TextHeight
		{$$->n=$2; if(bug>2)fprintf(Error,"%5d _FigGrp: TextHeight %d\n", LineNumber, $2); }
	|	_FigGrp Visible
	|	_FigGrp Comment
		{       if(bug>2)fprintf(Error,"%5d _FigGrpOver: Comment \n", LineNumber); }
	|	_FigGrp Property
	|	_FigGrp UserData
	|	_FigGrp IncFigGrp
	;

FigGrpObj :	FIGUREGROUPOBJECT _FigGrpObj PopC
	  ;

_FigGrpObj :	FigGrpNameRef
	   |	FigGrpRef
	   |	FigureOp
	   ;

FigGrpOver :	FIGUREGROUPOVERRIDE _FigGrpOver PopC
		{$$=$2;}
	   ;

_FigGrpOver :	FigGrpNameRef
		{$$->p=NULL; 
		 if(bug>2)fprintf(Error,"%5d _FigGrp: FigGrpNameRef %s\n", LineNumber, $1->s); }
	    |	_FigGrpOver CornerType
	    |	_FigGrpOver EndType
	    |	_FigGrpOver PathWidth
	    |	_FigGrpOver BorderWidth
	    |	_FigGrpOver Color
	    |	_FigGrpOver FillPattern
	    |	_FigGrpOver BorderPat
	    |	_FigGrpOver TextHeight
		{$$->n=$2; if(bug>2)fprintf(Error,"%5d _FigGrpOver: TextHeight %d\n", LineNumber, $2); }
	    |	_FigGrpOver Visible
	    |	_FigGrpOver Comment
		{       if(bug>2)fprintf(Error,"%5d _FigGrpOver: Comment \n", LineNumber); }
	    |	_FigGrpOver Property
	    |	_FigGrpOver UserData
	    ;

FigGrpRef :	FIGUREGROUPREF FigGrpNameRef _FigGrpRef PopC
	  ;

_FigGrpRef :
	   |	LibraryRef
	   ;

Figure     :	FIGURE _Figure PopC
		{$$=$2;}
           ;

_Figure :	FigGrpNameDef
	|	FigGrpOver
	|	_Figure Circle
		{
		if(bug>4)fprintf(Error,"New CIRCLE LibraryDrawEntryStruct\n");
		    New = (LibraryDrawEntryStruct *) Malloc(sizeof(LibraryDrawEntryStruct));
		    New->nxt = LibEntry->Drawings;
		    LibEntry->Drawings = New; New->Unit = 0; New->Convert =convert;

		    New->DrawType = CIRCLE_DRAW_TYPE;
		    New->U.Circ.x =    (($2->x  ) + ($2->nxt->x  ))/2;
		    New->U.Circ.y =    (($2->y  ) + ($2->nxt->y  ))/2;
		    a=$2->x - $2->nxt->x;
		    b=$2->y - $2->nxt->y;
		    New->U.Circ.r = (int) sqrt((a*a)+(b*b)); 
		    New->U.Circ.width = 0; 
		    New->Unit = 0;
		}
	|	_Figure Dot
		{$$->p=$2;
		    if(bug>4)fprintf(Error,"New SQUARE LibraryDrawEntryStruct\n");
		    New = (LibraryDrawEntryStruct *) Malloc(sizeof(LibraryDrawEntryStruct));
                    New->nxt = LibEntry->Drawings;
		    LibEntry->Drawings = New; New->Unit = 0; New->Convert = convert;

		    New->DrawType = SQUARE_DRAW_TYPE; 
                    // New->nxt = LibEntry->Drawings;
                    // LibEntry->Drawings = New;
		    New->U.Sqr.width = 0;
		    New->U.Sqr.x1 = ($2->x+10) ; 
		    New->U.Sqr.y1 = ($2->y+10) ;
		    New->U.Sqr.x2 = ($2->x-10) ;
		    New->U.Sqr.y2 = ($2->y-10) ;
		}
	|	_Figure OpenShape
	|	_Figure Path
		{
		    if(bug>2 && $2!=NULL)fprintf(Error,"New PATH LibraryDrawEntryStruct %d %d %d %d\n",
			$2->x, $2->y, $2->nxt->x, $2->nxt->y);
		    if(bug>2 && $2==NULL)fprintf(Error,"New PATH LibraryDrawEntryStruct '' '' '' ''\n");

		    New = (LibraryDrawEntryStruct *) Malloc(sizeof(LibraryDrawEntryStruct));
                    New->nxt = LibEntry->Drawings;
		    LibEntry->Drawings = New; New->Unit = 0; New->Convert = convert;
		    New->U.Poly.width = 0;

		    New->DrawType = POLYLINE_DRAW_TYPE; 
		    for( pl = $2; pl != NULL ; pl=pl->nxt )
		        New->U.Poly.n++;
		    Poly = New->U.Poly.PolyList = (int*) Malloc( 2*New->U.Poly.n * sizeof(int) );
		    for(  ; $2 != NULL ; $2=$2->nxt ){
		        *Poly++ = (int)( $2->x );    
                        *Poly++ = (int)( $2->y ); 
		    }
		}
	|	_Figure Polygon
		{
		    if(bug>4)fprintf(Error,"New POLYLINE LibraryDrawEntryStruct\n");
		    New = (LibraryDrawEntryStruct *) Malloc(sizeof(LibraryDrawEntryStruct));
                    New->nxt = LibEntry->Drawings;
		    LibEntry->Drawings = New; New->Unit = 0; New->Convert = convert;
		    New->U.Poly.width = 0;

		    New->DrawType = POLYLINE_DRAW_TYPE; 
		    for( pl = $2; pl != NULL ; pl=pl->nxt )
		        New->U.Poly.n++;
		    Poly = New->U.Poly.PolyList = (int*) Malloc( 2*New->U.Poly.n * sizeof(int) );
		    for(  ; $2 != NULL ; $2=$2->nxt ){
		        *Poly++ = (int)( $2->x  );      
                        *Poly++ = (int)( $2->y  );   
		    }
		}
	|	_Figure Rectangle
		{
		    if(bug>4)fprintf(Error,"New SQUARE LibraryDrawEntryStruct\n");
		    New = (LibraryDrawEntryStruct *) Malloc(sizeof(LibraryDrawEntryStruct));
                    New->nxt = LibEntry->Drawings;
		    LibEntry->Drawings = New; New->Unit = 0; New->Convert = convert;

                    New->DrawType = SQUARE_DRAW_TYPE; 
                    New->U.Sqr.width = 0;
                    New->U.Sqr.x1 = LibEntry->BBoxMinX;
                    New->U.Sqr.y1 = LibEntry->BBoxMinY;
                    New->U.Sqr.x2 = LibEntry->BBoxMaxX;
                    New->U.Sqr.y2 = LibEntry->BBoxMaxY;
		}
	|	_Figure Shape
	|	_Figure Comment
	|	_Figure UserData
	;

FigureArea :	FIGUREAREA RuleNameDef FigGrpObj _FigureArea PopC
	   ;

_FigureArea :	Range
	    |	SingleValSet
	    |	_FigureArea Comment
	    |	_FigureArea UserData
	    ;

FigureOp :	Intersection
	 |	Union
	 |	Difference
	 |	Inverse
	 |	Oversize
	 ;

FigurePerim :	FIGUREPERIMETER RuleNameDef FigGrpObj _FigurePerim PopC
	    ;

_FigurePerim :	Range
	     |	SingleValSet
	     |	_FigurePerim Comment
	     |	_FigurePerim UserData
	     ;

FigureWidth :	FIGUREWIDTH RuleNameDef FigGrpObj _FigureWidth PopC
	    ;

_FigureWidth :	Range
	     |	SingleValSet
	     |	_FigureWidth Comment
	     |	_FigureWidth UserData
	     ;

FillPattern :	FILLPATTERN Int Int Boolean PopC
	    ;

Follow :	FOLLOW __Follow _Follow PopC
       ;

__Follow :	PortNameRef
	 |	PortRef
	 ;

_Follow :	PortRef
	|	Table
	|	_Follow Delay
	|	_Follow LoadDelay
	;

Forbidden :	FORBIDDENEVENT _Forbidden PopC
	  ;

_Forbidden :	TimeIntval
	   |	_Forbidden Event
	   ;

Form :		Keyword _Form ')'
     ;

_Form :
      |		_Form Int
      |		_Form Str
      |		_Form Ident
      |		_Form Form
      ;

GlobPortRef :	GLOBALPORTREF PortNameRef PopC
	    ;

GreaterThan :	GREATERTHAN ScaledInt PopC
	    ;

GridMap :	GRIDMAP ScaledInt ScaledInt PopC
	;

Ignore :	IGNORE PopC
       ;

IncFigGrp :	INCLUDEFIGUREGROUP _IncFigGrp PopC
	  ;

_IncFigGrp :	FigGrpRef
	   |	FigureOp
	   ;

Initial :	INITIAL PopC
	;

InstNameDef :	NameDef
		{if(bug>2)fprintf(Error,"\n%5d InstNameDef: '%s'\n",LineNumber, $1->s); 
		if( SchHead ){
		    if(bug>2)fprintf(Error," Out:Head'%s' \n", Libs->Name);
		    OutHead(Libs); SchHead=0;
		}
		ref=val=NULL;
                LibEntry->DrawName = 0;
		}
	    |	Array
	    ;

Instance :	INSTANCE InstNameDef _Instance PopC
		{
		$$=$2; 
		if(bug>2 && val->s != NULL)fprintf(Error," INSTANCE:%s '%s' \n", $2->s, val->s );
		if(bug>2 && val->s == NULL)fprintf(Error," INSTANCE:%s '' \n", $2->s );

		strcpy(LibEntry->Name, $2->s);

		if( val != NULL ){
		   if(ref == NULL) {
		       s=(char *)Malloc(strlen($2->s)+1); 
		       strcpy(s,"#"); s=strcat(s,$2->s);
		       if(bug>2)fprintf(Error," Out:Inst '%s' '%s' %d %d \n", val->s, s, tx, ty);
		       OutInst(val->s, s,      tx, -ty,        tx,        -ty, Rot);
		   }else{
		       if(bug>2)fprintf(Error," Out:Inst '%s' '%s' %d %d \n", val->s, ref->s, tx, ty);
		       OutInst(val->s, ref->s, tx, -ty, ref->p->x, -ref->p->y, Rot);
	           }
		}
		}
	 ;

_Instance :	ViewRef
	  |	ViewList
	  |	_Instance Transform
	  |	_Instance ParamAssign
	  |	_Instance PortInst
	  |	_Instance Timing
	  |	_Instance Designator
	  |	_Instance Property
	  |	_Instance Comment
	  |	_Instance UserData
	  ;

InstNameRef :	NameRef
		{if(bug>4)fprintf(Error," InstNameRef: %s\n", $1->s);}
	    |	Member
	    ;

InstanceRef :	INSTANCEREF InstNameRef _InstanceRef PopC
		{$$=$2;}
	    ;

_InstanceRef :
		{$$=NULL;}
	     |	InstanceRef
	     |	ViewRef
	     ;

InstBackAn :	INSTANCEBACKANNOTATE _InstBackAn PopC
	   ;

_InstBackAn :	InstanceRef
	    |	_InstBackAn Designator
	    |	_InstBackAn Timing
	    |	_InstBackAn Property
	    |	_InstBackAn Comment
	    ;

InstGroup :	INSTANCEGROUP _InstGroup PopC
	  ;

_InstGroup :
	   |	_InstGroup InstanceRef
	   ;

InstMap :	INSTANCEMAP _InstMap PopC
	;

_InstMap :
	 |	_InstMap InstanceRef
	 |	_InstMap InstGroup
	 |	_InstMap Comment
	 |	_InstMap UserData
	 ;

IntDisplay :	INTEGERDISPLAY _IntDisplay PopC
	   ;

_IntDisplay :	Int
	    |	_IntDisplay Display
	    ;

Integer     :	INTEGER _Integer PopC
		{$$=$2;}
	    ;

_Integer :
		{$$=NULL;}
	 |	_Integer Int
	 |	_Integer IntDisplay
	 |	_Integer Integer
	 ;

Interface :	INTERFACE _Interface PopC
		{$$=$2;}
	  ;

_Interface :
		{$$=NULL;}
	   |	_Interface Port
		{$$=$2; if(bug>4)fprintf(Error," _Interface Port '%s'\n", $2->s);}
	   |	_Interface PortBundle
	   |	_Interface Symbol
		{$$=$2; if(bug>4)fprintf(Error," _Interface Symb '%s'\n", $2->s);}
	   |	_Interface ProtectFrame
	   |	_Interface ArrayRelInfo
	   |	_Interface Parameter
	   |	_Interface Joined
	   |	_Interface MustJoin
	   |	_Interface WeakJoined
	   |	_Interface Permutable
	   |	_Interface Timing
	   |	_Interface Simulate
	   |	_Interface Designator
		{ $$=$2; 
		strcpy(LibEntry->Prefix, $2->s); 
		}
	   |	_Interface Property
	   |	_Interface Comment
	   |	_Interface UserData
	   ;

InterFigGrp :	INTERFIGUREGROUPSPACING RuleNameDef FigGrpObj FigGrpObj
		_InterFigGrp PopC
	    ;

_InterFigGrp :	Range
	     |	SingleValSet
	     |	_InterFigGrp Comment
	     |	_InterFigGrp UserData
	     ;

Intersection :	INTERSECTION _Intersection PopC
	     ;

_Intersection :	FigGrpRef
	      |	FigureOp
	      |	_Intersection FigGrpRef
	      |	_Intersection FigureOp
	      ;

IntraFigGrp :	INTRAFIGUREGROUPSPACING RuleNameDef FigGrpObj _IntraFigGrp PopC
	    ;

_IntraFigGrp :	Range
	     |	SingleValSet
	     |	_IntraFigGrp Comment
	     |	_IntraFigGrp UserData
	     ;

Inverse :	INVERSE _Inverse PopC
	;

_Inverse :	FigGrpRef
	 |	FigureOp
	 ;

Isolated :	ISOLATED PopC
	 ;

Joined :	JOINED _Joined PopC
       ;

_Joined :
	|	_Joined PortRef
	|	_Joined PortList
	|	_Joined GlobPortRef
	;

Justify :	JUSTIFY _Justify PopC
		{$$ = (struct st *)Malloc(sizeof(struct st));
	 	 $$->s=s;}
	;

_Justify :	CENTERCENTER
		{s="CC";}
	 |	CENTERLEFT
		{s="CL";}
	 |	CENTERRIGHT
		{s="CR";}
	 |	LOWERCENTER
		{s="LC";}
	 |	LOWERLEFT
		{s="LL";}
	 |	LOWERRIGHT
		{s="LR";}
	 |	UPPERCENTER
		{s="UC";}
	 |	UPPERLEFT
		{s="UL"; ox=0; oy= TextSize + TextSize/2;}
	 |	UPPERRIGHT
		{s="UR";}
	 ;

KeywordDisp :	KEYWORDDISPLAY _KeywordDisp PopC
		{$$=$2; 
 		 if(bug>2 && $2->nxt != NULL )fprintf(Error,"%5d KeywDisp: %s %s %d %d\n",
				LineNumber, $2->s, $2->nxt->s, $2->p->x, $2->p->y);
 		 if(bug>2 && $2->nxt == NULL )fprintf(Error,"%5d KeywDisp: %s '' %d %d\n",
				LineNumber, $2->s,             $2->p->x, $2->p->y);

		if(!strcmp($2->s, "DESIGNATOR")){
		    LibEntry->PrefixPosX=$2->p->x; LibEntry->PrefixPosY=$2->p->y;
		}

		if(savtext){
		    New->U.Text.Text = $2->s;
                    if( New->U.Text.Text == NULL )
                        New->U.Text.Text = strdup("KKKK");
                    New->U.Text.x += (New->U.Text.size * strlen(New->U.Text.Text))/2;
                    New->U.Text.y += New->U.Text.size / 2;
		}
		}
	    ;

KeywordName :	Ident
		{if(bug>2)fprintf(Error," KeywNam: %s\n",$1->s); }
	    ;

_KeywordDisp :	KeywordName
	     |	_KeywordDisp Display
		{$$=$1; $$->p=$2->p; $$->nxt=$2;}
	     ;

KeywordLevel :	KEYWORDLEVEL Int PopC
	     ;

KeywordMap :	KEYWORDMAP _KeywordMap PopC
	   ;

_KeywordMap :	KeywordLevel
	    |	_KeywordMap Comment
	    ;

LayerNameDef :	NameDef
	     ;

LessThan :	LESSTHAN ScaledInt PopC
	 ;

LibNameDef :	NameDef
		{if(bug>8)fprintf(Error,"\nLibrary: %s\n", $1->s);
		 convert=1; // normal view

  		 CurrentLib = (LibraryStruct *) Malloc(sizeof(LibraryStruct));
  		 strncpy(CurrentLib->Name,$1->s ,40);
		 CurrentLib->Entries = NULL; CurrentLib->NumOfParts=0; 
  		 CurrentLib->nxt = Libs;
	 	 Libs=CurrentLib;
		}
	   ;

Library :	LIBRARY LibNameDef EdifLevel _Library PopC
		{if(bug>2)fprintf(Error,"EndLibrary %s\n", $2->s);}
	;

_Library :	Technology
	 |	_Library Status
	 |	_Library Cell
	 |	_Library Comment
	 |	_Library UserData
	 ;

ListOfNets :	LISTOFNETS _ListOfNets PopC
	   ;

_ListOfNets :
	    |	_ListOfNets Net
	    ;

ListOfPorts :	LISTOFPORTS _ListOfPorts PopC
	    ;

_ListOfPorts :
	     |	_ListOfPorts Port
	     |	_ListOfPorts PortBundle
	     ;

LoadDelay :	LOADDELAY _LoadDelay _LoadDelay PopC
	  ;

_LoadDelay :	MiNoMaValue
	   |	MiNoMaDisp
	   ;

LogicAssn :	LOGICASSIGN ___LogicAssn __LogicAssn _LogicAssn PopC
	  ;

___LogicAssn :	PortNameRef
	     |	PortRef
	     ;

__LogicAssn :	PortRef
	    |	LogicRef
	    |	Table
	    ;

_LogicAssn :
	   |	Delay
	   |	LoadDelay
	   ;

LogicIn :	LOGICINPUT _LogicIn PopC
	;

_LogicIn :	PortList
	 |	PortRef
	 |	PortNameRef
	 |	_LogicIn LogicWave
	 ;

LogicList :	LOGICLIST _LogicList PopC
	  ;

_LogicList :
	   |	_LogicList LogicNameRef
	   |	_LogicList LogicOneOf
	   |	_LogicList Ignore
	   ;

LogicMapIn :	LOGICMAPINPUT _LogicMapIn PopC
	   ;

_LogicMapIn :
	    |	_LogicMapIn LogicNameRef
	    ;

LogicMapOut :	LOGICMAPOUTPUT _LogicMapOut PopC
	    ;

_LogicMapOut :
	     |	_LogicMapOut LogicNameRef
	     ;

LogicNameDef :	NameDef
	     ;

LogicNameRef :	NameRef
	     ;

LogicOneOf :	LOGICONEOF _LogicOneOf PopC
	   ;

_LogicOneOf :
	    |	_LogicOneOf LogicNameRef
	    |	_LogicOneOf LogicList
	    ;

LogicOut :	LOGICOUTPUT _LogicOut PopC
	 ;

_LogicOut :	PortList
	  |	PortRef
	  |	PortNameRef
	  |	_LogicOut LogicWave
	  ;

LogicPort :	LOGICPORT _LogicPort PopC
	  ;

_LogicPort :	PortNameDef
	   |	_LogicPort Property
	   |	_LogicPort Comment
	   |	_LogicPort UserData
	   ;

LogicRef :	LOGICREF LogicNameRef _LogicRef PopC
	 ;

_LogicRef :
	  |	LibraryRef
	  ;

LogicValue :	LOGICVALUE _LogicValue PopC
	   ;

_LogicValue :	LogicNameDef
	    |	_LogicValue VoltageMap
	    |	_LogicValue CurrentMap
	    |	_LogicValue BooleanMap
	    |	_LogicValue Compound
	    |	_LogicValue Weak
	    |	_LogicValue Strong
	    |	_LogicValue Dominates
	    |	_LogicValue LogicMapOut
	    |	_LogicValue LogicMapIn
	    |	_LogicValue Isolated
	    |	_LogicValue Resolves
	    |	_LogicValue Property
	    |	_LogicValue Comment
	    |	_LogicValue UserData
	    ;

LogicWave :	LOGICWAVEFORM _LogicWave PopC
	  ;

_LogicWave :
	   |	_LogicWave LogicNameRef
	   |	_LogicWave LogicList
	   |	_LogicWave LogicOneOf
	   |	_LogicWave Ignore
	   ;

Maintain :	MAINTAIN __Maintain _Maintain PopC
	 ;

__Maintain :	PortNameRef
	   |	PortRef
	   ;

_Maintain :
	  |	Delay
	  |	LoadDelay
	  ;

Match :		MATCH __Match _Match PopC
      ;

__Match :	PortNameRef
	|	PortRef
	|	PortList
	;

_Match :	LogicNameRef
       |	LogicList
       |	LogicOneOf
       ;

Member :	MEMBER NameRef _Member PopC
		{$$=$2; if(bug>4)fprintf(Error," Member %s\n", $2->s);}
       ;

_Member :	Int
	|	_Member Int
	;

MiNoMa :	MINOMAX _MiNoMa PopC
		{$$=$2;}
       ;

_MiNoMa :
		{$$=NULL;}
	|	_MiNoMa MiNoMaValue
	|	_MiNoMa MiNoMaDisp
	|	_MiNoMa MiNoMa
	;

MiNoMaDisp :	MINOMAXDISPLAY _MiNoMaDisp PopC
	   ;

_MiNoMaDisp :	MiNoMaValue
	    |	_MiNoMaDisp Display
	    ;

MiNoMaValue :	Mnm
	    |	ScaledInt
	    ;

Mnm :		MNM _Mnm _Mnm _Mnm PopC
    ;

_Mnm :		ScaledInt
     |		Undefined
     |		Unconstrained
     ;

MultValSet :	MULTIPLEVALUESET _MultValSet PopC
	   ;

_MultValSet :
	    |	_MultValSet RangeVector
	    ;

MustJoin :	MUSTJOIN _MustJoin PopC
	 ;

_MustJoin :
	  |	_MustJoin PortRef
	  |	_MustJoin PortList
	  |	_MustJoin WeakJoined
	  |	_MustJoin Joined
	  ;

NameDef :	Ident
	|	Name
	|	Rename
	;

NameRef :	Ident
	|	Name
	;

NetNameDef :	NameDef
		{
		if(bug>2)fprintf(Error,"\n%5d NetNameDef: '%s'\n", LineNumber, $1->s);
		cur_nnam = $1->s;
		}
	   |	Array
	   ;

Net 	:	NET NetNameDef _Net PopC
    	;

_Net :		Joined
     |		_Net Criticality
     |		_Net NetDelay
     |		_Net Figure
     |		_Net Net
     |		_Net Instance
     |		_Net CommGraph
     |		_Net Property
     |		_Net Comment
     |		_Net UserData
     ;

NetBackAn :	NETBACKANNOTATE _NetBackAn PopC
	  ;

_NetBackAn :	NetRef
	   |	_NetBackAn NetDelay
	   |	_NetBackAn Criticality
	   |	_NetBackAn Property
	   |	_NetBackAn Comment
	   ;

NetBundle :	NETBUNDLE NetNameDef _NetBundle PopC
	  ;

_NetBundle :	ListOfNets
	   |	_NetBundle Figure
	   |	_NetBundle CommGraph
	   |	_NetBundle Property
	   |	_NetBundle Comment
	   |	_NetBundle UserData
	   ;

NetDelay :	NETDELAY Derivation _NetDelay PopC
	 ;

_NetDelay :	Delay
	  |	_NetDelay Transition
	  |	_NetDelay Becomes
	  ;

NetGroup :	NETGROUP _NetGroup PopC
	 ;

_NetGroup :
	  |	_NetGroup NetNameRef
	  |	_NetGroup NetRef
	  ;

NetMap :	NETMAP _NetMap PopC
       ;

_NetMap :
	|	_NetMap NetRef
	|	_NetMap NetGroup
	|	_NetMap Comment
	|	_NetMap UserData
	;

NetNameRef :	NameRef
		{if(bug>4)fprintf(Error," NetNameRef: %s\n", $1->s);}
	   |	Member
	   ;

NetRef :	NETREF NetNameRef _NetRef PopC
       ;

_NetRef :
	|	NetRef
	|	InstanceRef
	|	ViewRef
	;

NoChange :	NOCHANGE PopC
	 ;

NonPermut :	NONPERMUTABLE _NonPermut PopC
	  ;

_NonPermut :
	   |	_NonPermut PortRef
	   |	_NonPermut Permutable
	   ;

NotAllowed :	NOTALLOWED RuleNameDef _NotAllowed PopC
	   ;

_NotAllowed :	FigGrpObj
	    |	_NotAllowed Comment
	    |	_NotAllowed UserData
	    ;

NotchSpace :	NOTCHSPACING RuleNameDef FigGrpObj _NotchSpace PopC
	   ;

_NotchSpace :	Range
	    |	SingleValSet
	    |	_NotchSpace Comment
	    |	_NotchSpace UserData
	    ;

Number :	NUMBER _Number PopC
		{$$=$2;}
       ;

_Number :
		{$$=NULL;}
	|	_Number ScaledInt
	|	_Number NumbDisplay
	|	_Number Number
	;

NumbDisplay :	NUMBERDISPLAY _NumbDisplay PopC
	    ;

_NumbDisplay :	ScaledInt
	     |	_NumbDisplay Display
	     ;

NumberDefn :	NUMBERDEFINITION _NumberDefn PopC
	   ;

_NumberDefn :
	    |	_NumberDefn Scale
	    |	_NumberDefn GridMap
	    |	_NumberDefn Comment
	    ;

OffPageConn :	OFFPAGECONNECTOR _OffPageConn PopC
	    ;

_OffPageConn :	PortNameDef
	     |	_OffPageConn Unused
	     |	_OffPageConn Property
	     |	_OffPageConn Comment
	     |	_OffPageConn UserData
	     ;

OffsetEvent :	OFFSETEVENT Event ScaledInt PopC
	    ;

OpenShape :	OPENSHAPE _OpenShape PopC
	  ;

_OpenShape :	Curve
	   |	_OpenShape Property
	   ;

Orientation :	ORIENTATION _Orientation PopC
		{$$=$2; if(bug>4)fprintf(Error," Orient %c ",$2);}
	    ;

_Orientation :	R0
		{$$=PIN_RIGHT;}
	     |	R90
		{$$=PIN_UP;
		Rot[0][0] =  0; Rot[0][1] = Rot[1][0] = -1; Rot[1][1] = 0;
		Rot90 = 1;
		}
	     |	R180
		{$$=PIN_LEFT;
		Rot[0][0] = -1; Rot[0][1] = Rot[1][0] = 0; Rot[1][1] = 1;
		}
	     |	R270
		{$$=PIN_DOWN;
		Rot[0][0] =  0; Rot[0][1] = Rot[1][0] =  1; Rot[1][1] = 0;
		Rot90 = 1;
		}
	     |	MX
		{$$=PIN_RIGHT;
		Rot[0][0] =  1; Rot[0][1] = Rot[1][0] =  0; Rot[1][1] = 1;
		}
	     |	MY
		{int TempR, TempMat[2][2];
		$$=PIN_RIGHT;

		TempMat[0][0] = -1;
                TempMat[1][1] = 1;
                TempMat[0][1] = TempMat[1][0] = 0;
                TempR     = Rot[0][0] * TempMat[0][0] + Rot[0][1] * TempMat[1][0];
                Rot[0][1] = Rot[0][0] * TempMat[0][1] + Rot[0][1] * TempMat[1][1];
                Rot[0][0] = TempR;
                TempR     = Rot[1][0] * TempMat[0][0] + Rot[1][1] * TempMat[1][0];
                Rot[1][1] = Rot[1][0] * TempMat[0][1] + Rot[1][1] * TempMat[1][1];
                Rot[1][0] = TempR;
		}
	     |	MYR90
		{$$=PIN_RIGHT;}
	     |	MXR90
		{$$=PIN_RIGHT;}
	     ;

Origin       :	ORIGIN PointValue PopC
		{$$=$2; if(bug>4)fprintf(Error,"\nOrg: %d %d\n", $2->x, $2->y);
	
		if(savtext){
                    New = (LibraryDrawEntryStruct *) Malloc(sizeof(LibraryDrawEntryStruct));
                    New->DrawType = TEXT_DRAW_TYPE; New->Convert = convert;
                    New->nxt = LibEntry->Drawings;
                    LibEntry->Drawings = New;
                    New->Unit = 0;
		    New->U.Text.Horiz =1; 
                    New->U.Text.x = (int)( $2->x * 1 ) ;
                    New->U.Text.y = (int)( $2->y * 1 );
                    New->U.Text.size = TextSize;
                    New->U.Text.type = 0;
		    New->U.Text.Text = bad;		// fixme
		}
                }
             ;

OverhngDist :	OVERHANGDISTANCE RuleNameDef FigGrpObj FigGrpObj _OverhngDist
		PopC
	    ;

_OverhngDist :	Range
	     |	SingleValSet
	     |	_OverhngDist Comment
	     |	_OverhngDist UserData
	     ;

OverlapDist :	OVERLAPDISTANCE RuleNameDef FigGrpObj FigGrpObj _OverlapDist
		PopC
	    ;

_OverlapDist :	Range
	     |	SingleValSet
	     |	_OverlapDist Comment
	     |	_OverlapDist UserData
	     ;

Oversize :	OVERSIZE Int _Oversize CornerType PopC
	 ;

_Oversize :	FigGrpRef
	  |	FigureOp
	  ;

Owner :		OWNER Str PopC
		{$$=$2;}
      ;

Page :		PAGE _Page PopC
     ;

_Page :		InstNameDef
      |		_Page Instance
      |		_Page Net
      |		_Page NetBundle
      |		_Page CommGraph
      |		_Page PortImpl
      |		_Page PageSize
      |		_Page BoundBox
      |		_Page Comment
      |		_Page UserData
      ;

PageSize :	PAGESIZE Rectangle PopC
	 ;

ParamDisp :	PARAMETERDISPLAY _ParamDisp PopC
	  ;

_ParamDisp :	ValueNameRef
	   |	_ParamDisp Display
	   ;

Parameter :	PARAMETER ValueNameDef TypedValue _Parameter PopC
	  ;

_Parameter :
	   |	Unit
	   ;

ParamAssign :	PARAMETERASSIGN ValueNameRef TypedValue PopC
	    ;

Path :		PATH _Path PopC
		{$$=$2;
		    if(!SchHead){
	            	if(bug>2)fprintf(Error," Out:Wire  %d %d %d %d\n", 
			        $2->x, -$2->y, $2->nxt->x, -$2->nxt->y);
		    	OutWire($2->x, -$2->y, $2->nxt->x, -$2->nxt->y);
		    }
		}
     ;

_Path :		PointList
      |		_Path Property
      ;

PathDelay :	PATHDELAY _PathDelay PopC
	  ;

_PathDelay :	Delay
	   |	_PathDelay Event
	   ;

PathWidth :	PATHWIDTH Int PopC
	  ;

Permutable :	PERMUTABLE _Permutable PopC
	   ;

_Permutable :
	    |	_Permutable PortRef
	    |	_Permutable Permutable
	    |	_Permutable NonPermut
	    ;

Plug :		PLUG _Plug PopC
     ;

_Plug :
      |		_Plug SocketSet
      ;

Point :		POINT _Point PopC
		{$$=$2;}
      ;

_Point :
		{$$=NULL;}
       |	_Point PointValue
		{$$=$2;}
       |	_Point PointDisp
       |	_Point Point
       ;

PointDisp :	POINTDISPLAY _PointDisp PopC
	  ;

_PointDisp :	PointValue
	   |	_PointDisp Display
	   ;

PointList :	POINTLIST _PointList PopC
		{$$=$2}
	  ;

_PointList :
		{$$=NULL;}
	   |	_PointList PointValue
		{ 	
		pl=(struct plst *)Malloc(sizeof(struct plst)); 
		pl->x=$2->x; 
		pl->y=$2->y; 
		pl->nxt=$$;
		$$ = pl;
		}
	   ;

PointValue : 	PT Int Int PopC
		{
		if(bug>4)fprintf(Error,"PtVal %d %d\n", $2,$3);
	
	 	$$=(struct plst *)Malloc(sizeof(struct plst)); 
		$$->x=$2; $$->y=$3;
		}
	   ;

Polygon    :	POLYGON _Polygon PopC
		{$$=$2;}
	   ;

_Polygon   :	PointList
	   |	_Polygon Property
	   ;

Port :		PORT _Port PopC
		{$$=$2;}
     ;

PortNameDef :	NameDef
		{if(bug>4)fprintf(Error," PortNameDef: %s\n", $1->s);}
	    |	Array
	    ;

_Port :		PortNameDef
		{
		    if(bug>2){
		    	if($1->nxt != NULL)
			    fprintf(Error," _Port PortNameDef:'%s' '%s'\n", $1->s, $1->nxt->s);
		    	else
			    fprintf(Error," _Port PortNameDef:'%s'\n", $1->s);
		    }
		    New = (LibraryDrawEntryStruct *) Malloc(sizeof(LibraryDrawEntryStruct));
                    New->DrawType = PIN_DRAW_TYPE; New->Convert = convert;
                    New->nxt = LibEntry->Drawings;
                    LibEntry->Drawings = New;
                    New->Unit = 1; 			// PartPerPack-ii;     
                    New->U.Pin.Len = 300;
                    New->U.Pin.PinShape = NONE;		// NONE, DOT, CLOCK, SHORT
		    New->U.Pin.Orient   = 0;
                    New->U.Pin.Flags    = 1;           	/* Pin InVisible */
                    New->U.Pin.SizeNum  = TextSize;
                    New->U.Pin.SizeName = TextSize;
		    if($1->nxt != NULL)
		        New->U.Pin.ReName = $1->nxt->s;
		    else
		        New->U.Pin.ReName = NULL;
		    New->U.Pin.Name = $1->s;
		}
      |		_Port Direction
                {
		    New->U.Pin.PinType = $2; 
		}
      |		_Port Unused
      |		_Port PortDelay
      |		_Port Designator
                {
		$$=$2; if(bug>2)fprintf(Error," _Port Designator '%s'\n", $2->s);
		    strncpy((char*)&New->U.Pin.Num, $2->s, 4);
		    if( !strcmp($2->s, ""))
			LibEntry->DrawPinNum=0;
		}
      |		_Port DcFanInLoad
      |		_Port DcFanOutLoad
      |		_Port DcMaxFanIn
      |		_Port DcMaxFanOut
      |		_Port AcLoad
      |		_Port Property
                {
		$$=$2; if(bug>2)fprintf(Error," _Port Prop '%s'='%s' '%s' PShape %x\n", 
				$2->s, $2->nxt->s, New->U.Pin.Name, New->U.Pin.PinShape);
		    if( !strcmp($2->s, "CLOCK") && !strcmp($2->nxt->s, "True") )
			New->U.Pin.PinShape |= CLOCK;
		    if( !strcmp($2->s, "DOT")   && !strcmp($2->nxt->s, "True") )
			New->U.Pin.PinShape |= INVERT;
		    if( !strcmp($2->s, "LONG")  && !strcmp($2->nxt->s, "False") )
                    	New->U.Pin.Len = 100;
		    if( !strcmp($2->s, "PIN_32_NUMBER_32_IS_32_VISIBLE") && !strcmp($2->nxt->s, "True") ){
			// LibEntry->DrawPinNum = 1;
                    	New->U.Pin.Flags = 0;  // set visable
		    }
		}
      |		_Port Comment
      |		_Port UserData
      ;

PortBackAn :	PORTBACKANNOTATE _PortBackAn PopC
	   ;

_PortBackAn :	PortRef
	    |	_PortBackAn Designator
	    |	_PortBackAn PortDelay
	    |	_PortBackAn DcFanInLoad
	    |	_PortBackAn DcFanOutLoad
	    |	_PortBackAn DcMaxFanIn
	    |	_PortBackAn DcMaxFanOut
	    |	_PortBackAn AcLoad
	    |	_PortBackAn Property
	    |	_PortBackAn Comment
	    ;

PortBundle :	PORTBUNDLE PortNameDef _PortBundle PopC
	   ;

_PortBundle :	ListOfPorts
	    |	_PortBundle Property
	    |	_PortBundle Comment
	    |	_PortBundle UserData
	    ;

PortDelay :	PORTDELAY Derivation _PortDelay PopC
	  ;

_PortDelay :	Delay
	   |	LoadDelay
	   |	_PortDelay Transition
	   |	_PortDelay Becomes
	   ;

PortGroup :	PORTGROUP _PortGroup PopC
	  ;

_PortGroup :
	   |	_PortGroup PortNameRef
	   |	_PortGroup PortRef
	   ;

PortImpl :	PORTIMPLEMENTATION _PortImpl PopC
		{$$=$2;}
	 ;

_PortImpl :	Name
		{if(bug>2)fprintf(Error," _PortImpl Name  '%s'\n", $1->s); 
		}
	  |	Ident
		{if(bug>2)fprintf(Error," _PortImpl Ident '%s'\n", $1->s);
		}
	  |	_PortImpl ConnectLoc
		{$$=$2; 
		if(bug>2) fprintf(Error," _PortImpl ConnLoc: '%s' %d %d '%s'\n", 
			$2->s, $2->p->x, $2->p->y, $1->s );
		
		// find Pin
		s = (char *)Malloc( strlen($1->s)+1);   // rename hack
		strcpy(s, $1->s+1); 
		for( LDptr=New ; LDptr != NULL ; LDptr=LDptr->nxt ) {
		    if( LDptr->DrawType != PIN_DRAW_TYPE)
			continue;
		    if( !strcmp(LDptr->U.Pin.Name,   $1->s) ||
		        !strcmp(LDptr->U.Pin.Name,       s) ){
			   break;
			}
		}
		if( LDptr != NULL ){
		    if(bug>2)fprintf(Error,"  Found %s %s\n", LDptr->U.Pin.Name, LDptr->U.Pin.ReName);
		    LDptr->U.Pin.posX = $2->p->x;
		    LDptr->U.Pin.posY = $2->p->y;
		    if($2->p->x < 0 && LDptr->U.Pin.Orient==0)  // pin direction kludge
			   LDptr->U.Pin.Orient = PIN_RIGHT;
		    else
			   LDptr->U.Pin.Orient = PIN_LEFT;
		}
		}
	  |	_PortImpl Figure
		{$$=$2; if(bug>4)fprintf(Error," _PortImpl Figure \n");}
	  |	_PortImpl Instance
		{$$=$2; if(bug>4)fprintf(Error," _PortImpl Instance \n");}
	  |	_PortImpl CommGraph
		{$$=$2; if(bug>4)fprintf(Error," _PortImpl CommGraph \n");}
	  |	_PortImpl PropDisp
		{$$=$2; if(bug>4)fprintf(Error," _PortImpl PropDisp '%s' %d %d\n", $2->s, $2->p->x, $2->p->y);}
	  |	_PortImpl KeywordDisp
		{$$=$2; if(bug>4)fprintf(Error," _PortImpl KeywDisp '%s' %d %d\n", $2->s, $2->p->x, $2->p->y);}
	  |	_PortImpl Property
	  |	_PortImpl UserData
	  |	_PortImpl Comment
	  ;

PortInst :	PORTINSTANCE _PortInst PopC
	 ;

_PortInst :	PortRef
	  |	PortNameRef
	  |	_PortInst Unused
	  |	_PortInst PortDelay
	  |	_PortInst Designator
	  |	_PortInst DcFanInLoad
	  |	_PortInst DcFanOutLoad
	  |	_PortInst DcMaxFanIn
	  |	_PortInst DcMaxFanOut
	  |	_PortInst AcLoad
	  |	_PortInst Property
	  |	_PortInst Comment
	  |	_PortInst UserData
	  ;

PortList :	PORTLIST _PortList PopC
	 ;

_PortList :
	  |	_PortList PortRef
	  |	_PortList PortNameRef
	  ;

PortListAls :	PORTLISTALIAS PortNameDef PortList PopC
	    ;

PortMap :	PORTMAP _PortMap PopC
	;

_PortMap :
	 |	_PortMap PortRef
	 |	_PortMap PortGroup
	 |	_PortMap Comment
	 |	_PortMap UserData
	 ;

PortNameRef :	NameRef
	    |	Member
	    ;

PortRef     :	PORTREF PortNameRef _PortRef PopC
		{$$=$2; $$->nxt=$3;
		if(bug>2 && $3 != NULL)fprintf(Error," PortRef: %s '%s'\n", $2->s, $3->s);
		if(bug>2 && $3 == NULL)fprintf(Error," PortRef: %s ''\n", $2->s);

		if(cptr != NULL)  // InstRef usually first
            	  cptr->pin = $2->s;
		}
	    ;

_PortRef :
		{$$=NULL;}
	 |	PortRef
	 |	InstanceRef
                {$$=$1; 

                if(bug>2)fprintf(Error,"InstRef: %8s \n", $1->s);
                cptr = (struct con *) malloc (sizeof (struct con));
                cptr->ref = $1->s;
                cptr->nnam = cur_nnam;
                cptr->nxt = cons;
                cons = cptr;
                }
	 |	ViewRef
	 ;

Program :	PROGRAM Str _Program PopC
	;

_Program :
	 |	Version
	 ;

PropDisp  :	PROPERTYDISPLAY _PropDisp PopC
		{$$=$2; 
		 if(bug>2 && $2->nxt->s != NULL)fprintf(Error,"%5d PropDisp: %s %s %d %d\n",
				LineNumber, $2->s, $2->nxt->s, $2->p->x, $2->p->y);
		 if(bug>2 && $2->nxt->s == NULL)fprintf(Error,"%5d PropDisp: %s '' %d %d\n",
				LineNumber, $2->s,             $2->p->x, $2->p->y);

		if(!strcmp($2->s, "VALUE")){
		    LibEntry->NamePosX=$2->p->x; LibEntry->NamePosY=$2->p->y;
		}
	
		if(savtext){
		    New->U.Text.Text = $2->s;
                    if( New->U.Text.Text == NULL )
                        New->U.Text.Text = strdup("PPPP");
                    New->U.Text.x += (New->U.Text.size * strlen(New->U.Text.Text))/2;
                    New->U.Text.y += New->U.Text.size / 2;
		}
		}
    	  ;

PropNameRef :	NameRef
		{if(bug>2)fprintf(Error," PropNameRef: %s ", $1->s); }
	    ;

_PropDisp    :	PropNameRef
	     |	_PropDisp Display
		{$$=$1; $$->p=$2->p; $$->nxt=$2;}
	     ;

PropNameDef :	NameDef
		{if(bug>4)fprintf(Error," PropNameDef: %s\n", $1->s); }
	    ;

Property  :	PROPERTY PropNameDef _Property PopC
		{$$=$2; $$->nxt=$3;
		if(bug>2 && $3 != NULL)fprintf(Error," Property: '%s'='%s'\n", $2->s, $3->s);
		if(bug>2 && $3 == NULL)fprintf(Error," Property: '%s' ''\n", $2->s);

		if( $3 != NULL ){
		    if( !strcmp($2->s, "PIN_32_NUMBERS_32_VISIBLE") && !strcmp($3->s, "True") ){
			// LibEntry->DrawPinNum = 1;
		        for( LDptr=LibEntry->Drawings ; LDptr != NULL ; LDptr=LDptr->nxt ){
			    if( LDptr->DrawType != PIN_DRAW_TYPE)
                               continue;
			    if(bug>2)fprintf(Error," Set VIS %s\n", LDptr->U.Pin.Name);
		    	    LDptr->U.Pin.Flags = 0;  // set Visable
		        }
		    }
		}
		}
	  ;

_Property :	String  // TypedValue
	  |	_Property Owner
	  |	_Property Unit
	  |	_Property Property
	  |	_Property Comment
	  ;

ProtectFrame :	PROTECTIONFRAME _ProtectFrame PopC
	     ;

_ProtectFrame :
	      |	_ProtectFrame PortImpl
	      |	_ProtectFrame Figure
	      |	_ProtectFrame Instance
	      |	_ProtectFrame CommGraph
	      |	_ProtectFrame BoundBox
	      |	_ProtectFrame PropDisp
	      |	_ProtectFrame KeywordDisp
	      |	_ProtectFrame ParamDisp
	      |	_ProtectFrame Property
	      |	_ProtectFrame Comment
	      |	_ProtectFrame UserData
	      ;

Range :		LessThan
      |		GreaterThan
      |		AtMost
      |		AtLeast
      |		Exactly
      |		Between
      ;

RangeVector :	RANGEVECTOR _RangeVector PopC
	    ;

_RangeVector :
	     |	_RangeVector Range
	     |	_RangeVector SingleValSet
	     ;

Rectangle :	RECTANGLE PointValue _Rectangle PopC
		{
		// for e2lib
                LibEntry->BBoxMinX = $2->x *1;
                LibEntry->BBoxMaxX = $3->x *1;
                LibEntry->BBoxMinY = $2->y *1;
                LibEntry->BBoxMaxY = $3->y *1;
		}
	  ;

_Rectangle :	PointValue
	   |	_Rectangle Property
	   ;

RectSize  :	RECTANGLESIZE RuleNameDef FigGrpObj _RectSize PopC
	  ;

_RectSize :	RangeVector
	  |	MultValSet
	  |	_RectSize Comment
	  |	_RectSize UserData
	  ;

Rename 	  :	RENAME __Rename _Rename PopC
		{$$=$2; $$->nxt = $3;
		 if(bug>4)fprintf(Error,"ReName:'%s'-'%s'\n", $2->s, $3->s);
		}
       	  ;

__Rename  :	Ident
	  |	Name
	  ;

_Rename   :	Str
	  |	StrDisplay
	  ;

Resolves  :	RESOLVES _Resolves PopC
	  ;

_Resolves :
	  |	_Resolves LogicNameRef
	  ;

RuleNameDef :	NameDef
	    ;

ScaledInt :	Int
		{$$=(float)$1;}
	  |	E Int Int PopC
		{sprintf(fname,"%de%d", $2, $3);
		 sscanf(fname,"%f", &$$);
		}
	  ;

Scale     :	SCALE ScaledInt ScaledInt Unit PopC
		{	
		 scale = 100000.0 * $3 / (2.54 * $2);
		 if(bug>2)fprintf(stderr, "%f %g %f\n", $2, $3, scale);
		 // scale =1.0;
		}
          ;

ScaleX :	SCALEX Int Int PopC
       ;

ScaleY :	SCALEY Int Int PopC
       ;

Section :	SECTION _Section PopC
	;

_Section :	Str
	 |	_Section Section
	 |	_Section Str
	 |	_Section Instance
	 ;

Shape :		SHAPE _Shape PopC
      ;

_Shape :	Curve
       |	_Shape Property
       ;

SimNameDef :	NameDef
	   ;

Simulate :	SIMULATE _Simulate PopC
	 ;

_Simulate :	SimNameDef
	  |	_Simulate PortListAls
	  |	_Simulate WaveValue
	  |	_Simulate Apply
	  |	_Simulate Comment
	  |	_Simulate UserData
	  ;

SimulInfo :	SIMULATIONINFO _SimulInfo PopC
	  ;

_SimulInfo :
	   |	_SimulInfo LogicValue
	   |	_SimulInfo Comment
	   |	_SimulInfo UserData
	   ;

SingleValSet :	SINGLEVALUESET _SingleValSet PopC
	     ;

_SingleValSet :
	      |	Range
	      ;

Site :		SITE ViewRef _Site PopC
     ;

_Site :
      |		Transform
      ;

Socket :	SOCKET _Socket PopC
       ;

_Socket :
	|	Symmetry
	;

SocketSet :	SOCKETSET _SocketSet PopC
	  ;

_SocketSet :	Symmetry
	   |	_SocketSet Site
	   ;

Status :	STATUS _Status PopC
       ;

_Status :
	|	_Status Written
	|	_Status Comment
	|	_Status UserData
	;

Steady :	STEADY __Steady _Steady PopC
       ;

__Steady :	PortNameRef
	 |	PortRef
	 |	PortList
	 ;

_Steady :	Duration
	|	_Steady Transition
	|	_Steady Becomes
	;

StrDisplay :	STRINGDISPLAY _StrDisplay PopC
		{$$=$2;

		    if(savtext){
		    New->U.Text.Text = $2->s;
                    if( New->U.Text.Text == NULL )
                        New->U.Text.Text = strdup("SSSS");
                    New->U.Text.x += (New->U.Text.size * strlen(New->U.Text.Text))/2;
                    New->U.Text.y += New->U.Text.size / 2;
		    }
		}
	   ;

_StrDisplay :	STR
		{$$->s=$1->s; if(bug>2)fprintf(Error," _StrDisplay STR: '%s' \n",$1->s); 
		}
	    |	_StrDisplay Display
		{$$=$1; $$->p=$2->p; $1->nxt=$2;
		 if(bug>2)fprintf(Error,"%5d _StrDisplay Disp: '%s' '%s' %d %d\n",
					LineNumber, $1->s, $2->s, $2->p->x, $2->p->y); 

		if(!SchHead){
		    s = $1->s;
	            if(bug>2)fprintf(Error," Out:Text L '%s' %d %d %d\n", 
					s, $2->p->x +ox, $2->p->y +oy, TextSize);
	    	    OutText(0, s, $2->p->x +ox, -$2->p->y +oy, TextSize);
		    ox=oy=0;
		    TextSize=SIZE_PIN_TEXT;
		}
		}
	    ;

String :	STRING _String PopC
		{$$=$2; if(bug>4 && $2->s != NULL)fprintf(Error,"%5d STRING: '%s'\n",LineNumber, $2->s); }
       ;

_String :
		{$$=NULL;}
	|	_String Str
		{$$=$2; if(bug>4)fprintf(Error," _String Str: %s \n",$2->s); }
	|	_String StrDisplay
		{$$=$2; if(bug>4)fprintf(Error," _String StrDisp: %s \n",$2->s); }
	|	_String String
		{$$=$2; if(bug>4)fprintf(Error," _String String: %s \n",$2->s); }
	;

Strong  :	STRONG LogicNameRef PopC
        ;

Symbol  :	SYMBOL _Symbol PopC
		{$$=$2;}
        ;

_Symbol :
		{$$=NULL;}
	|	_Symbol PortImpl
		{ $$=$2; if(bug>4)fprintf(Error," _Sym PortImpl '%s'\n", $2->s); }
	|	_Symbol Figure
		{ $$=$2; if(bug>4)fprintf(Error," _Sym Figure '%s'\n", $2->s); }
	|	_Symbol Instance
		{ $$=$2; if(bug>4)fprintf(Error," _Sym Instance '%s'\n", $2->s); }
	|	_Symbol CommGraph
	|	_Symbol Annotate
		{ $$=$2; if(bug>4)fprintf(Error," _Sym Annot '%s'\n", $2->s); }
	|	_Symbol PageSize
	|	_Symbol BoundBox
	|	_Symbol PropDisp
		{ $$=$2; if(bug>4)fprintf(Error," _Sym PropD '%s'\n", $2->s); }
	|	_Symbol KeywordDisp
		{ $$=$2; if(bug>4)fprintf(Error," _Sym KeywD '%s'\n", $2->s); }
	|	_Symbol ParamDisp
		{        if(bug>4)fprintf(Error," _Sym ParamDisp \n");}
	|	_Symbol Property
		{        if(bug>4)fprintf(Error," _Sym Property \n");}
	|	_Symbol Comment
		{ $$=$2; if(bug>4)fprintf(Error," _Sym Comment \n");}
	|	_Symbol UserData
	;

Symmetry :	SYMMETRY _Symmetry PopC
	 ;

_Symmetry :
	  |	_Symmetry Transform
	  ;

Table :		TABLE _Table PopC
      ;

_Table :
       |	_Table Entry
       |	_Table TableDeflt
       ;

TableDeflt :	TABLEDEFAULT __TableDeflt _TableDeflt PopC
	   ;

__TableDeflt :	LogicRef
	     |	PortRef
	     |	NoChange
	     |	Table
	     ;

_TableDeflt :
	    |	Delay
	    |	LoadDelay
	    ;

Technology :	TECHNOLOGY _Technology PopC
	   ;

_Technology :	NumberDefn
	    |	_Technology FigGrp
	    |	_Technology Fabricate
	    |	_Technology SimulInfo
	    |	_Technology DesignRule
	    |	_Technology Comment
	    |	_Technology UserData
	    ;

TextHeight :	TEXTHEIGHT Int PopC
		{$$=$2; TextSize = $2;}
	   ;

TimeIntval :	TIMEINTERVAL __TimeIntval _TimeIntval PopC
	   ;

__TimeIntval :	Event
	     |	OffsetEvent
	     ;

_TimeIntval :	Event
	    |	OffsetEvent
	    |	Duration
	    ;

TimeStamp :	TIMESTAMP Int Int Int Int Int Int PopC
	  ;

Timing :	TIMING _Timing PopC
       ;

_Timing :	Derivation
	|	_Timing PathDelay
	|	_Timing Forbidden
	|	_Timing Comment
	|	_Timing UserData
	;

Transform :	TRANSFORM _TransX _TransY _TransDelta _TransOrien _TransOrg PopC
		{
		INew = New;	// Instance position
		if(bug>2)fprintf(Error,"%5d  Transform: %c %d %d\n", LineNumber, $5, $6->x, $6->y);
		tx=$6->x; ty=$6->y;
		}
	  ;

_TransX :
	|	ScaleX
	;

_TransY :
	|	ScaleY
	;

_TransDelta :
	    |	Delta
	    ;

_TransOrien :
		{$$=PIN_RIGHT;}
	    |	Orientation
	    ;

_TransOrg :
		{$$=NULL;}
	  |	Origin
	  ;

Transition :	TRANSITION _Transition _Transition PopC
	   ;

_Transition :	LogicNameRef
	    |	LogicList
	    |	LogicOneOf
	    ;

Trigger :	TRIGGER _Trigger PopC
	;

_Trigger :
	 |	_Trigger Change
	 |	_Trigger Steady
	 |	_Trigger Initial
	 ;

True :		TRUE PopC
     ;

TypedValue :	Boolean
	   |	Integer
	   |	MiNoMa
	   |	Number
	   |	Point
	   |	String
	   ;

Unconstrained :	UNCONSTRAINED PopC
	      ;

Undefined :	UNDEFINED PopC
	  ;

Union :		UNION _Union PopC
      ;

_Union :	FigGrpRef
       |	FigureOp
       |	_Union FigGrpRef
       |	_Union FigureOp
       ;

Unit :		UNIT _Unit PopC
     ;

_Unit :		DISTANCE
      |		CAPACITANCE
      |		CURRENT
      |		RESISTANCE
      |		TEMPERATURE
      |		TIME
      |		VOLTAGE
      |		MASS
      |		FREQUENCY
      |		INDUCTANCE
      |		ENERGY
      |		POWER
      |		CHARGE
      |		CONDUCTANCE
      |		FLUX
      |		ANGLE
      ;

Unused :	UNUSED PopC
       ;

UserData :	USERDATA _UserData PopC
	 ;

_UserData :	Ident
	  |	_UserData Int
	  |	_UserData Str
	  |	_UserData Ident
	  |	_UserData Form
	  ;

ValueNameDef :	NameDef
	     |	Array
	     ;

ValueNameRef :	NameRef
		{if(bug>5)fprintf(Error," ValueNameRef: %s\n", $1->s);}
	     |	Member
	     ;

Version :	VERSION Str PopC
	;

ViewNameDef :	NameDef
		{
		if(bug>4)fprintf(Error," ViewNameDef: '%s'\n", $1->s);
		if( strcmp( $1->s, "CONVERT")==0 | strcmp( $1->s, "Convert")==0 )
		    convert=2;
		if( strcmp( $1->s, "NORMAL")==0 | strcmp( $1->s, "Normal")==0 )
		    convert=1;
		}
	    ;

View 	    :	VIEW ViewNameDef ViewType _View PopC
     	    ;

_View :		Interface
      |		_View Status
      |		_View Contents
      |		_View Comment
      |		_View Property
      |		_View UserData
      ;

ViewList :	VIEWLIST _ViewList PopC
		{$$=$2;}
	 ;

_ViewList :
		{$$=NULL;}
	  |	_ViewList ViewRef
		{$$=$2;}
	  |	_ViewList ViewList
		{$$=$2;}
	  ;

ViewMap :	VIEWMAP _ViewMap PopC
	;

_ViewMap :
	 |	_ViewMap PortMap
	 |	_ViewMap PortBackAn
	 |	_ViewMap InstMap
	 |	_ViewMap InstBackAn
	 |	_ViewMap NetMap
	 |	_ViewMap NetBackAn
	 |	_ViewMap Comment
	 |	_ViewMap UserData
	 ;

ViewNameRef :	NameRef
		{if(bug>5)fprintf(Error," ViewNameRef: %s\n", $1->s);
		}
	    ;

ViewRef :	VIEWREF ViewNameRef _ViewRef PopC
		{
		$$=$2; if(bug>2)fprintf(Error," ViewRef: '%s' \n", $3->s);

		iptr = (struct inst *)Malloc(sizeof (struct inst));
		iptr->sym = $3->s;
		iptr->nxt = insts;
		insts = iptr;
		}
	;

_ViewRef :
		{$$=NULL;}
	 |	CellRef
	 ;

ViewType :	VIEWTYPE _ViewType PopC
	 ;

_ViewType :	MASKLAYOUT
	  |	PCBLAYOUT
	  |	NETLIST
	  |	SCHEMATIC
	  |	SYMBOLIC
	  |	BEHAVIOR
	  |	LOGICMODEL
	  |	DOCUMENT
	  |	GRAPHIC
	  |	STRANGER
	  ;

Visible :	VISIBLE BooleanValue PopC
	;

VoltageMap :	VOLTAGEMAP MiNoMaValue PopC
	   ;

WaveValue :	WAVEVALUE LogicNameDef ScaledInt LogicWave PopC
	  ;

Weak :		WEAK LogicNameRef PopC
     ;

WeakJoined :	WEAKJOINED _WeakJoined PopC
	   ;

_WeakJoined :
	    |	_WeakJoined PortRef
	    |	_WeakJoined PortList
	    |	_WeakJoined Joined
	    ;

When :		WHEN _When PopC
     ;

_When :		Trigger
      |		_When After
      |		_When Follow
      |		_When Maintain
      |		_When LogicAssn
      |		_When Comment
      |		_When UserData
      ;

Written :	WRITTEN _Written PopC
	;

_Written :	TimeStamp
	 |	_Written Author
	 |	_Written Program
	 |	_Written DataOrigin
	 |	_Written Property
	 |	_Written Comment
	 |	_Written UserData
	 ;

Name 	  :	NAME _Name PopC
		{$$=$2;
                 if(bug>2 && $2->nxt->s != NULL)fprintf(Error,"%5d NameDisp: %s %s %d %d\n",
                                LineNumber, $2->s, $2->nxt->s, $2->p->x, $2->p->y);
                 if(bug>2 && $2->nxt->s == NULL)fprintf(Error,"%5d NameDisp: %s '' %d %d\n",
                                LineNumber, $2->s,             $2->p->x, $2->p->y);
		}
     	  ;

_Name     :	Ident
		{if(bug>4)fprintf(Error,"%5d _Name: Ident '%s'\n",LineNumber, $1->s); }
          |	_Name Display
		{$$=$1; $$->p=$2->p; $$->nxt=$2;

		if(!SchHead){
		    // search for an ReName
		    s = $1->s;
		    for( LEptr=CurrentLib->Entries, stop=0 ; LEptr != NULL && !stop ; LEptr=LEptr->nxt )
		    	for( LDptr=LEptr->Drawings ; LDptr != NULL && !stop ; LDptr=LDptr->nxt ){
			    if( LDptr->DrawType != PIN_DRAW_TYPE)
                           	continue;
			    if(bug>2)fprintf(Error,"  Check '%s' '%s' %s\n", 
				s, LDptr->U.Pin.Name, LDptr->U.Pin.ReName);
			    if( !strcmp(s, LDptr->U.Pin.Name )){
			   	s = LDptr->U.Pin.ReName;
				stop=1;
			    }
		        }
		    // Global Label or Normal
		    if( !strcmp($1->nxt->s, "OFFPAGECONNECTOR")) {
		        if(bug>2)fprintf(Error," Out:Text G '%s' %d %d %d\n", s, $2->p->x +ox, $2->p->y +oy, TextSize);
		    	OutText(1, s, $2->p->x +ox, -$2->p->y +oy, TextSize);
		    } else {
		        if(bug>2)fprintf(Error," Out:Text L '%s' %d %d %d\n", s, $2->p->x +ox, $2->p->y +oy, TextSize);
		    	OutText(0, s, $2->p->x +ox, -$2->p->y +oy, TextSize);
		    }
		    TextSize=SIZE_PIN_TEXT;
		    ox=oy=0;
		}
		}
          ;

Ident    :	IDENT
		{if(bug>4)fprintf(Error,"%5d ID: '%s'\n",LineNumber, $1->s); }
         ;

Str      :	STR
		{if(bug>4)fprintf(Error,"%5d STR: '%s'\n",LineNumber, $1->s); }
         ;

Int 	 :	INT
		{sscanf($1->s,"%d",&num); $$=num;  }
    	 ;

Keyword :	KEYWORD
	;

%%
/*
 *	Token & context carriers:
 *
 *	  These are the linkage pointers for threading this context garbage
 *	for converting identifiers into parser tokens.
 */
typedef struct TokenCar {
  struct TokenCar *Next;	/* pointer to next carrier */
  struct Token *Token;		/* associated token */
} TokenCar;
typedef struct UsedCar {
  struct UsedCar *Next;		/* pointer to next carrier */
  short Code;			/* used '%token' value */
} UsedCar;
typedef struct ContextCar {
  struct ContextCar *Next;	/* pointer to next carrier */
  struct Context *Context;	/* associated context */
  union {
    int Single;			/* single usage flag (context tree) */
    struct UsedCar *Used;	/* single used list (context stack) */
  } u;
} ContextCar;
/*
 *	Parser state variables.
 */
extern char *InFile;			/* file name on the input stream */
static ContextCar *CSP = NULL;		/* top of context stack */
static char yytext[IDENT_LENGTH + 1];	/* token buffer */
static char CharBuf[IDENT_LENGTH + 1];	/* garbage buffer */
/*
 *	Token definitions:
 *
 *	  This associates the '%token' codings with strings which are to
 *	be free standing tokens. Doesn't have to be in sorted order but the
 *	strings must be in lower case.
 */
typedef struct Token {
  char *Name;			/* token name */
  int Code;			/* '%token' value */
  struct Token *Next;		/* hash table linkage */
} Token;
static Token TokenDef[] = {
  {"angle",		ANGLE},
  {"behavior",		BEHAVIOR},
  {"calculated",	CALCULATED},
  {"capacitance",	CAPACITANCE},
  {"centercenter",	CENTERCENTER},
  {"centerleft",	CENTERLEFT},
  {"centerright",	CENTERRIGHT},
  {"charge",		CHARGE},
  {"conductance",	CONDUCTANCE},
  {"current",		CURRENT},
  {"distance",		DISTANCE},
  {"document",		DOCUMENT},
  {"energy",		ENERGY},
  {"extend",		EXTEND},
  {"flux",		FLUX},
  {"frequency",		FREQUENCY},
  {"generic",		GENERIC},
  {"graphic",		GRAPHIC},
  {"inductance",	INDUCTANCE},
  {"inout",		INOUT},
  {"input",		INPUT},
  {"logicmodel",	LOGICMODEL},
  {"lowercenter",	LOWERCENTER},
  {"lowerleft",		LOWERLEFT},
  {"lowerright",	LOWERRIGHT},
  {"masklayout",	MASKLAYOUT},
  {"mass",		MASS},
  {"measured",		MEASURED},
  {"mx",		MX},
  {"mxr90",		MXR90},
  {"my",		MY},
  {"myr90",		MYR90},
  {"netlist",		NETLIST},
  {"output",		OUTPUT},
  {"pcblayout",		PCBLAYOUT},
  {"power",		POWER},
  {"r0",		R0},
  {"r180",		R180},
  {"r270",		R270},
  {"r90",		R90},
  {"required",		REQUIRED},
  {"resistance",	RESISTANCE},
  {"ripper",		RIPPER},
  {"round",		ROUND},
  {"schematic",		SCHEMATIC},
  {"stranger",		STRANGER},
  {"symbolic",		SYMBOLIC},
  {"temperature",	TEMPERATURE},
  {"tie",		TIE},
  {"time",		TIME},
  {"truncate",		TRUNCATE},
  {"uppercenter",	UPPERCENTER},
  {"upperleft",		UPPERLEFT},
  {"upperright",	UPPERRIGHT},
  {"voltage",		VOLTAGE}
};
static int TokenDefSize = sizeof(TokenDef) / sizeof(Token);
/*
 *	Token enable definitions:
 *
 *	  There is one array for each set of tokens enabled by a
 *	particular context (barf). Another array is used to bind
 *	these arrays to a context.
 */
static short e_CellType[] = {TIE,RIPPER,GENERIC};
static short e_CornerType[] = {EXTEND,TRUNCATE,ROUND};
static short e_Derivation[] = {CALCULATED,MEASURED,REQUIRED};
static short e_Direction[] = {INPUT,OUTPUT,INOUT};
static short e_EndType[] = {EXTEND,TRUNCATE,ROUND};
static short e_Justify[] = {
  CENTERCENTER,CENTERLEFT,CENTERRIGHT,LOWERCENTER,LOWERLEFT,LOWERRIGHT,
  UPPERCENTER,UPPERLEFT,UPPERRIGHT
};
static short e_Orientation[] = {R0,R90,R180,R270,MX,MY,MXR90,MYR90};
static short e_Unit[] = {
  DISTANCE,CAPACITANCE,CURRENT,RESISTANCE,TEMPERATURE,TIME,VOLTAGE,MASS,
  FREQUENCY,INDUCTANCE,ENERGY,POWER,CHARGE,CONDUCTANCE,FLUX,ANGLE
};
static short e_ViewType[] = {
  MASKLAYOUT,PCBLAYOUT,NETLIST,SCHEMATIC,SYMBOLIC,BEHAVIOR,LOGICMODEL,
  DOCUMENT,GRAPHIC,STRANGER
};
/*
 *	Token tying table:
 *
 *	  This binds enabled tokens to a context.
 */
typedef struct Tie {
  short *Enable;		/* pointer to enable array */
  short Origin;			/* '%token' value of context */
  short EnableSize;		/* size of enabled array */
} Tie;
#define	TE(e,o)			{e,o,sizeof(e)/sizeof(short)}
static Tie TieDef[] = {
  TE(e_CellType,	CELLTYPE),
  TE(e_CornerType,	CORNERTYPE),
  TE(e_Derivation,	DERIVATION),
  TE(e_Direction,	DIRECTION),
  TE(e_EndType,		ENDTYPE),
  TE(e_Justify,		JUSTIFY),
  TE(e_Orientation,	ORIENTATION),
  TE(e_Unit,		UNIT),
  TE(e_ViewType,	VIEWTYPE)
};
static int TieDefSize = sizeof(TieDef) / sizeof(Tie);
/*
 *	Context definitions:
 *
 *	  This associates keyword strings with '%token' values. It
 *	also creates a pretty much empty header for later building of
 *	the context tree. Again they needn't be sorted, but strings
 *	must be lower case.
 */
typedef struct Context {
  char *Name;			/* keyword name */
  short Code;			/* '%token' value */
  short Flags;			/* special operation flags */
  struct ContextCar *Context;	/* contexts which can be moved to */
  struct TokenCar *Token;	/* active tokens */
  struct Context *Next;		/* hash table linkage */
} Context;
static Context ContextDef[] = {
  {"",				0},		/* start context */
  {"acload",			ACLOAD},
  {"after",			AFTER},
  {"annotate",			ANNOTATE},
  {"apply",			APPLY},
  {"arc",			ARC},
  {"array",			ARRAY},
  {"arraymacro",		ARRAYMACRO},
  {"arrayrelatedinfo",		ARRAYRELATEDINFO},
  {"arraysite",			ARRAYSITE},
  {"atleast",			ATLEAST},
  {"atmost",			ATMOST},
  {"author",			AUTHOR},
  {"basearray",			BASEARRAY},
  {"becomes",			BECOMES},
  {"between",			BETWEEN},
  {"boolean",			BOOLEAN},
  {"booleandisplay",		BOOLEANDISPLAY},
  {"booleanmap",		BOOLEANMAP},
  {"borderpattern",		BORDERPATTERN},
  {"borderwidth",		BORDERWIDTH},
  {"boundingbox",		BOUNDINGBOX},
  {"cell",			CELL},
  {"cellref",			CELLREF},
  {"celltype",			CELLTYPE},
  {"change",			CHANGE},
  {"circle",			CIRCLE},
  {"color",			COLOR},
  {"comment",			COMMENT},
  {"commentgraphics",		COMMENTGRAPHICS},
  {"compound",			COMPOUND},
  {"connectlocation",		CONNECTLOCATION},
  {"contents",			CONTENTS},
  {"cornertype",		CORNERTYPE},
  {"criticality",		CRITICALITY},
  {"currentmap",		CURRENTMAP},
  {"curve",			CURVE},
  {"cycle",			CYCLE},
  {"dataorigin",		DATAORIGIN},
  {"dcfaninload",		DCFANINLOAD},
  {"dcfanoutload",		DCFANOUTLOAD},
  {"dcmaxfanin",		DCMAXFANIN},
  {"dcmaxfanout",		DCMAXFANOUT},
  {"delay",			DELAY},
  {"delta",			DELTA},
  {"derivation",		DERIVATION},
  {"design",			DESIGN},
  {"designator",		DESIGNATOR},
  {"difference",		DIFFERENCE},
  {"direction",			DIRECTION},
  {"display",			DISPLAY},
  {"dominates",			DOMINATES},
  {"dot",			DOT},
  {"duration",			DURATION},
  {"e",				E},
  {"edif",			EDIF},
  {"ediflevel",			EDIFLEVEL},
  {"edifversion",		EDIFVERSION},
  {"enclosuredistance",		ENCLOSUREDISTANCE},
  {"endtype",			ENDTYPE},
  {"entry",			ENTRY},
  {"exactly",			EXACTLY},
  {"external",			EXTERNAL},
  {"fabricate",			FABRICATE},
  {"false",			FALSE},
  {"figure",			FIGURE},
  {"figurearea",		FIGUREAREA},
  {"figuregroup",		FIGUREGROUP},
  {"figuregroupobject",		FIGUREGROUPOBJECT},
  {"figuregroupoverride",	FIGUREGROUPOVERRIDE},
  {"figuregroupref",		FIGUREGROUPREF},
  {"figureperimeter",		FIGUREPERIMETER},
  {"figurewidth",		FIGUREWIDTH},
  {"fillpattern",		FILLPATTERN},
  {"follow",			FOLLOW},
  {"forbiddenevent",		FORBIDDENEVENT},
  {"globalportref",		GLOBALPORTREF},
  {"greaterthan",		GREATERTHAN},
  {"gridmap",			GRIDMAP},
  {"ignore",			IGNORE},
  {"includefiguregroup",	INCLUDEFIGUREGROUP},
  {"initial",			INITIAL},
  {"instance",			INSTANCE},
  {"instancebackannotate",	INSTANCEBACKANNOTATE},
  {"instancegroup",		INSTANCEGROUP},
  {"instancemap",		INSTANCEMAP},
  {"instanceref",		INSTANCEREF},
  {"integer",			INTEGER},
  {"integerdisplay",		INTEGERDISPLAY},
  {"interface",			INTERFACE},
  {"interfiguregroupspacing",	INTERFIGUREGROUPSPACING},
  {"intersection",		INTERSECTION},
  {"intrafiguregroupspacing",	INTRAFIGUREGROUPSPACING},
  {"inverse",			INVERSE},
  {"isolated",			ISOLATED},
  {"joined",			JOINED},
  {"justify",			JUSTIFY},
  {"keyworddisplay",		KEYWORDDISPLAY},
  {"keywordlevel",		KEYWORDLEVEL},
  {"keywordmap",		KEYWORDMAP},
  {"lessthan",			LESSTHAN},
  {"library",			LIBRARY},
  {"libraryref",		LIBRARYREF},
  {"listofnets",		LISTOFNETS},
  {"listofports",		LISTOFPORTS},
  {"loaddelay",			LOADDELAY},
  {"logicassign",		LOGICASSIGN},
  {"logicinput",		LOGICINPUT},
  {"logiclist",			LOGICLIST},
  {"logicmapinput",		LOGICMAPINPUT},
  {"logicmapoutput",		LOGICMAPOUTPUT},
  {"logiconeof",		LOGICONEOF},
  {"logicoutput",		LOGICOUTPUT},
  {"logicport",			LOGICPORT},
  {"logicref",			LOGICREF},
  {"logicvalue",		LOGICVALUE},
  {"logicwaveform",		LOGICWAVEFORM},
  {"maintain",			MAINTAIN},
  {"match",			MATCH},
  {"member",			MEMBER},
  {"minomax",			MINOMAX},
  {"minomaxdisplay",		MINOMAXDISPLAY},
  {"mnm",			MNM},
  {"multiplevalueset",		MULTIPLEVALUESET},
  {"mustjoin",			MUSTJOIN},
  {"name",			NAME},
  {"net",			NET},
  {"netbackannotate",		NETBACKANNOTATE},
  {"netbundle",			NETBUNDLE},
  {"netdelay",			NETDELAY},
  {"netgroup",			NETGROUP},
  {"netmap",			NETMAP},
  {"netref",			NETREF},
  {"nochange",			NOCHANGE},
  {"nonpermutable",		NONPERMUTABLE},
  {"notallowed",		NOTALLOWED},
  {"notchspacing",		NOTCHSPACING},
  {"number",			NUMBER},
  {"numberdefinition",		NUMBERDEFINITION},
  {"numberdisplay",		NUMBERDISPLAY},
  {"offpageconnector",		OFFPAGECONNECTOR},
  {"offsetevent",		OFFSETEVENT},
  {"openshape",			OPENSHAPE},
  {"orientation",		ORIENTATION},
  {"origin",			ORIGIN},
  {"overhangdistance",		OVERHANGDISTANCE},
  {"overlapdistance",		OVERLAPDISTANCE},
  {"oversize",			OVERSIZE},
  {"owner",			OWNER},
  {"page",			PAGE},
  {"pagesize",			PAGESIZE},
  {"parameter",			PARAMETER},
  {"parameterassign",		PARAMETERASSIGN},
  {"parameterdisplay",		PARAMETERDISPLAY},
  {"path",			PATH},
  {"pathdelay",			PATHDELAY},
  {"pathwidth",			PATHWIDTH},
  {"permutable",		PERMUTABLE},
  {"physicaldesignrule",	PHYSICALDESIGNRULE},
  {"plug",			PLUG},
  {"point",			POINT},
  {"pointdisplay",		POINTDISPLAY},
  {"pointlist",			POINTLIST},
  {"polygon",			POLYGON},
  {"port",			PORT},
  {"portbackannotate",		PORTBACKANNOTATE},
  {"portbundle",		PORTBUNDLE},
  {"portdelay",			PORTDELAY},
  {"portgroup",			PORTGROUP},
  {"portimplementation",	PORTIMPLEMENTATION},
  {"portinstance",		PORTINSTANCE},
  {"portlist",			PORTLIST},
  {"portlistalias",		PORTLISTALIAS},
  {"portmap",			PORTMAP},
  {"portref",			PORTREF},
  {"program",			PROGRAM},
  {"property",			PROPERTY},
  {"propertydisplay",		PROPERTYDISPLAY},
  {"protectionframe",		PROTECTIONFRAME},
  {"pt",			PT},
  {"rangevector",		RANGEVECTOR},
  {"rectangle",			RECTANGLE},
  {"rectanglesize",		RECTANGLESIZE},
  {"rename",			RENAME},
  {"resolves",			RESOLVES},
  {"scale",			SCALE},
  {"scalex",			SCALEX},
  {"scaley",			SCALEY},
  {"section",			SECTION},
  {"shape",			SHAPE},
  {"simulate",			SIMULATE},
  {"simulationinfo",		SIMULATIONINFO},
  {"singlevalueset",		SINGLEVALUESET},
  {"site",			SITE},
  {"socket",			SOCKET},
  {"socketset",			SOCKETSET},
  {"status",			STATUS},
  {"steady",			STEADY},
  {"string",			STRING},
  {"stringdisplay",		STRINGDISPLAY},
  {"strong",			STRONG},
  {"symbol",			SYMBOL},
  {"symmetry",			SYMMETRY},
  {"table",			TABLE},
  {"tabledefault",		TABLEDEFAULT},
  {"technology",		TECHNOLOGY},
  {"textheight",		TEXTHEIGHT},
  {"timeinterval",		TIMEINTERVAL},
  {"timestamp",			TIMESTAMP},
  {"timing",			TIMING},
  {"transform",			TRANSFORM},
  {"transition",		TRANSITION},
  {"trigger",			TRIGGER},
  {"true",			TRUE},
  {"unconstrained",		UNCONSTRAINED},
  {"undefined",			UNDEFINED},
  {"union",			UNION},
  {"unit",			UNIT},
  {"unused",			UNUSED},
  {"userdata",			USERDATA},
  {"version",			VERSION},
  {"view",			VIEW},
  {"viewlist",			VIEWLIST},
  {"viewmap",			VIEWMAP},
  {"viewref",			VIEWREF},
  {"viewtype",			VIEWTYPE},
  {"visible",			VISIBLE},
  {"voltagemap",		VOLTAGEMAP},
  {"wavevalue",			WAVEVALUE},
  {"weak",			WEAK},
  {"weakjoined",		WEAKJOINED},
  {"when",			WHEN},
  {"written",			WRITTEN}
};
static int ContextDefSize = sizeof(ContextDef) / sizeof(Context);
/*
 *	Context follower tables:
 *
 *	  This is pretty ugly, an array is defined for each context
 *	which has following context levels. Yet another table is used
 *	to bind these arrays to the originating contexts.
 *	  Arrays are declared as:
 *
 *		static short f_<Context name>[] = { ... };
 *
 *	The array entries are the '%token' values for all keywords which
 *	can be reached from the <Context name> context. Like I said, ugly,
 *	but it works.
 *	  A negative entry means that the follow can only occur once within
 *	the specified context.
 */
static short f_NULL[] = {EDIF};
static short f_Edif[] = {
  NAME,RENAME,EDIFVERSION,EDIFLEVEL,KEYWORDMAP,-STATUS,EXTERNAL,LIBRARY,
  DESIGN,COMMENT,USERDATA
};
static short f_AcLoad[] = {MNM,E,MINOMAXDISPLAY};
static short f_After[] = {MNM,E,FOLLOW,MAINTAIN,LOGICASSIGN,COMMENT,USERDATA};
static short f_Annotate[] = {STRINGDISPLAY};
static short f_Apply[] = {CYCLE,LOGICINPUT,LOGICOUTPUT,COMMENT,USERDATA};
static short f_Arc[] = {PT};
static short f_Array[] = {NAME,RENAME};
static short f_ArrayMacro[] = {PLUG};
static short f_ArrayRelatedInfo[] = {
  BASEARRAY,ARRAYSITE,ARRAYMACRO,COMMENT,USERDATA
};
static short f_ArraySite[] = {SOCKET};
static short f_AtLeast[] = {E};
static short f_AtMost[] = {E};
static short f_Becomes[] = {NAME,LOGICLIST,LOGICONEOF};
static short f_Between[] = {ATLEAST,GREATERTHAN,ATMOST,LESSTHAN};
static short f_Boolean[] = {FALSE,TRUE,BOOLEANDISPLAY,BOOLEAN};
static short f_BooleanDisplay[] = {FALSE,TRUE,DISPLAY};
static short f_BooleanMap[] = {FALSE,TRUE};
static short f_BorderPattern[] = {BOOLEAN};
static short f_BoundingBox[] = {RECTANGLE};
static short f_Cell[] = {
  NAME,RENAME,CELLTYPE,-STATUS,-VIEWMAP,VIEW,COMMENT,USERDATA,PROPERTY
};
static short f_CellRef[] = {NAME,LIBRARYREF};
static short f_Change[] = {NAME,PORTREF,PORTLIST,BECOMES,TRANSITION};
static short f_Circle[] = {PT,PROPERTY};
static short f_Color[] = {E};
static short f_CommentGraphics[] = {
  ANNOTATE,FIGURE,INSTANCE,-BOUNDINGBOX,PROPERTY,COMMENT,USERDATA
};
static short f_Compound[] = {NAME};
static short f_ConnectLocation[] = {FIGURE};
static short f_Contents[] = {
  INSTANCE,OFFPAGECONNECTOR,FIGURE,SECTION,NET,NETBUNDLE,PAGE,
  COMMENTGRAPHICS,PORTIMPLEMENTATION,TIMING,SIMULATE,WHEN,FOLLOW,
  LOGICPORT,-BOUNDINGBOX,COMMENT,USERDATA
};
static short f_Criticality[] = {INTEGERDISPLAY};
static short f_CurrentMap[] = {MNM,E};
static short f_Curve[] = {ARC,PT};
static short f_Cycle[] = {DURATION};
static short f_DataOrigin[] = {VERSION};
static short f_DcFanInLoad[] = {E,NUMBERDISPLAY};
static short f_DcFanOutLoad[] = {E,NUMBERDISPLAY};
static short f_DcMaxFanIn[] = {E,NUMBERDISPLAY};
static short f_DcMaxFanOut[] = {E,NUMBERDISPLAY};
static short f_Delay[] = {MNM,E};
static short f_Delta[] = {PT};
static short f_Design[] = {
  NAME,RENAME,CELLREF,STATUS,COMMENT,PROPERTY,USERDATA
};
static short f_Designator[] = {STRINGDISPLAY};
static short f_Difference[] = {
  FIGUREGROUPREF,INTERSECTION,UNION,DIFFERENCE,INVERSE,OVERSIZE
};
static short f_Display[] = {
  NAME,FIGUREGROUPOVERRIDE,JUSTIFY,ORIENTATION,ORIGIN
};
static short f_Dominates[] = {NAME};
static short f_Dot[] = {PT,PROPERTY};
static short f_Duration[] = {E};
static short f_EnclosureDistance[] = {
  NAME,RENAME,FIGUREGROUPOBJECT,LESSTHAN,GREATERTHAN,ATMOST,ATLEAST,
  EXACTLY,BETWEEN,SINGLEVALUESET,COMMENT,USERDATA
};
static short f_Entry[] = {
  MATCH,CHANGE,STEADY,LOGICREF,PORTREF,NOCHANGE,TABLE,DELAY,LOADDELAY
};
static short f_Exactly[] = {E};
static short f_External[] = {
  NAME,RENAME,EDIFLEVEL,TECHNOLOGY,-STATUS,CELL,COMMENT,USERDATA
};
static short f_Fabricate[] = {NAME,RENAME};
static short f_Figure[] = {
  NAME,FIGUREGROUPOVERRIDE,CIRCLE,DOT,OPENSHAPE,PATH,POLYGON,RECTANGLE,
  SHAPE,COMMENT,USERDATA
};
static short f_FigureArea[] = {
  NAME,RENAME,FIGUREGROUPOBJECT,LESSTHAN,GREATERTHAN,ATMOST,ATLEAST,
  EXACTLY,BETWEEN,SINGLEVALUESET,COMMENT,USERDATA
};
static short f_FigureGroup[] = {
  NAME,RENAME,-CORNERTYPE,-ENDTYPE,-PATHWIDTH,-BORDERWIDTH,-COLOR,
  -FILLPATTERN,-BORDERPATTERN,-TEXTHEIGHT,-VISIBLE,INCLUDEFIGUREGROUP,
  COMMENT,PROPERTY,USERDATA
};
static short f_FigureGroupObject[] = {
  NAME,FIGUREGROUPOBJECT,INTERSECTION,UNION,DIFFERENCE,INVERSE,OVERSIZE
};
static short f_FigureGroupOverride[] = {
  NAME,-CORNERTYPE,-ENDTYPE,-PATHWIDTH,-BORDERWIDTH,-COLOR,-FILLPATTERN,
  -TEXTHEIGHT,-BORDERPATTERN,VISIBLE,COMMENT,PROPERTY,USERDATA
};
static short f_FigureGroupRef[] = {NAME,LIBRARYREF};
static short f_FigurePerimeter[] = {
  NAME,RENAME,FIGUREGROUPOBJECT,LESSTHAN,GREATERTHAN,ATMOST,ATLEAST,EXACTLY,
  BETWEEN,SINGLEVALUESET,COMMENT,USERDATA
};
static short f_FigureWidth[] = {
  NAME,RENAME,FIGUREGROUPOBJECT,LESSTHAN,GREATERTHAN,ATMOST,ATLEAST,EXACTLY,
  BETWEEN,SINGLEVALUESET,COMMENT,USERDATA
};
static short f_FillPattern[] = {BOOLEAN};
static short f_Follow[] = {NAME,PORTREF,TABLE,DELAY,LOADDELAY};
static short f_ForbiddenEvent[] = {TIMEINTERVAL,EVENT};
static short f_GlobalPortRef[] = {NAME};
static short f_GreaterThan[] = {E};
static short f_GridMap[] = {E};
static short f_IncludeFigureGroup[] = {
  FIGUREGROUPREF,INTERSECTION,UNION,DIFFERENCE,INVERSE,OVERSIZE
};
static short f_Instance[] = {
  NAME,RENAME,ARRAY,VIEWREF,VIEWLIST,-TRANSFORM,PARAMETERASSIGN,PORTINSTANCE,
  TIMING,-DESIGNATOR,PROPERTY,COMMENT,USERDATA
};
static short f_InstanceBackAnnotate[] = {
  INSTANCEREF,-DESIGNATOR,TIMING,PROPERTY,COMMENT
};
static short f_InstanceGroup[] = {INSTANCEREF};
static short f_InstanceMap[] = {
  INSTANCEREF,INSTANCEGROUP,COMMENT,USERDATA
};
static short f_InstanceRef[] = {NAME,MEMBER,INSTANCEREF,VIEWREF};
static short f_Integer[] = {INTEGERDISPLAY,INTEGER};
static short f_IntegerDisplay[] = {DISPLAY};
static short f_Interface[] = {
  PORT,PORTBUNDLE,-SYMBOL,-PROTECTIONFRAME,-ARRAYRELATEDINFO,PARAMETER,
  JOINED,MUSTJOIN,WEAKJOINED,PERMUTABLE,TIMING,SIMULATE,-DESIGNATOR,PROPERTY,
  COMMENT,USERDATA
};
static short f_InterFigureGroupSpacing[] = {
  NAME,RENAME,FIGUREGROUPOBJECT,LESSTHAN,GREATERTHAN,ATMOST,ATLEAST,EXACTLY,
  BETWEEN,SINGLEVALUESET,COMMENT,USERDATA
};
static short f_Intersection[] = {
  FIGUREGROUPREF,INTERSECTION,UNION,DIFFERENCE,INVERSE,OVERSIZE
};
static short f_IntraFigureGroupSpacing[] = {
  NAME,RENAME,FIGUREGROUPOBJECT,LESSTHAN,GREATERTHAN,ATMOST,ATLEAST,EXACTLY,
  BETWEEN,SINGLEVALUESET,COMMENT,USERDATA
};
static short f_Inverse[] = {
  FIGUREGROUPREF,INTERSECTION,UNION,DIFFERENCE,INVERSE,OVERSIZE
};
static short f_Joined[] = {PORTREF,PORTLIST,GLOBALPORTREF};
static short f_KeywordDisplay[] = {DISPLAY};
static short f_KeywordMap[] = {KEYWORDLEVEL,COMMENT};
static short f_LessThan[] = {E};
static short f_Library[] = {
  NAME,RENAME,EDIFLEVEL,TECHNOLOGY,-STATUS,CELL,COMMENT,USERDATA
};
static short f_LibraryRef[] = {NAME};
static short f_ListOfNets[] = {NET};
static short f_ListOfPorts[] = {PORT,PORTBUNDLE};
static short f_LoadDelay[] = {MNM,E,MINOMAXDISPLAY};
static short f_LogicAssign[] = {NAME,PORTREF,LOGICREF,TABLE,DELAY,LOADDELAY};
static short f_LogicInput[] = {PORTLIST,PORTREF,NAME,LOGICWAVEFORM};
static short f_LogicList[] = {NAME,LOGICONEOF,IGNORE};
static short f_LogicMapInput[] = {LOGICREF};
static short f_LogicMapOutput[] = {LOGICREF};
static short f_LogicOneOf[] = {NAME,LOGICLIST};
static short f_LogicOutput[] = {PORTLIST,PORTREF,NAME,LOGICWAVEFORM};
static short f_LogicPort[] = {NAME,RENAME,PROPERTY,COMMENT,USERDATA};
static short f_LogicRef[] = {NAME,LIBRARYREF};
static short f_LogicValue[] = {
  NAME,RENAME,-VOLTAGEMAP,-CURRENTMAP,-BOOLEANMAP,-COMPOUND,-WEAK,-STRONG,
  -DOMINATES,-LOGICMAPOUTPUT,-LOGICMAPINPUT,-ISOLATED,RESOLVES,PROPERTY,
  COMMENT,USERDATA
};
static short f_LogicWaveform[] = {NAME,LOGICLIST,LOGICONEOF,IGNORE};
static short f_Maintain[] = {NAME,PORTREF,DELAY,LOADDELAY};
static short f_Match[] = {NAME,PORTREF,PORTLIST,LOGICLIST,LOGICONEOF};
static short f_Member[] = {NAME};
static short f_MiNoMax[] = {MNM,E,MINOMAXDISPLAY,MINOMAX};
static short f_MiNoMaxDisplay[] = {MNM,E,DISPLAY};
static short f_Mnm[] = {E,UNDEFINED,UNCONSTRAINED};
static short f_MultipleValueSet[] = {RANGEVECTOR};
static short f_MustJoin[] = {PORTREF,PORTLIST,WEAKJOINED,JOINED};
static short f_Name[] = {DISPLAY};
static short f_Net[] = {
  NAME,RENAME,-CRITICALITY,NETDELAY,FIGURE,NET,INSTANCE,COMMENTGRAPHICS,
  PROPERTY,COMMENT,USERDATA,JOINED,ARRAY
};
static short f_NetBackAnnotate[] = {
  NETREF,NETDELAY,-CRITICALITY,PROPERTY,COMMENT
};
static short f_NetBundle[] = {
  NAME,RENAME,ARRAY,LISTOFNETS,FIGURE,COMMENTGRAPHICS,PROPERTY,COMMENT,
  USERDATA
};
static short f_NetDelay[] = {DERIVATION,DELAY,TRANSITION,BECOMES};
static short f_NetGroup[] = {NAME,MEMBER,NETREF};
static short f_NetMap[] = {NETREF,NETGROUP,COMMENT,USERDATA};
static short f_NetRef[] = {NAME,MEMBER,NETREF,INSTANCEREF,VIEWREF};
static short f_NonPermutable[] = {PORTREF,PERMUTABLE};
static short f_NotAllowed[] = {
  NAME,RENAME,FIGUREGROUPOBJECT,COMMENT,USERDATA
};
static short f_NotchSpacing[] = {
  NAME,RENAME,FIGUREGROUPOBJECT,LESSTHAN,GREATERTHAN,ATMOST,ATLEAST,EXACTLY,
  BETWEEN,SINGLEVALUESET,COMMENT,USERDATA
};
static short f_Number[] = {E,NUMBERDISPLAY,NUMBER};
static short f_NumberDefinition[] = {SCALE,-GRIDMAP,COMMENT};
static short f_NumberDisplay[] = {E,DISPLAY};
static short f_OffPageConnector[] = {
  NAME,RENAME,-UNUSED,PROPERTY,COMMENT,USERDATA
};
static short f_OffsetEvent[] = {EVENT,E};
static short f_OpenShape[] = {CURVE,PROPERTY};
static short f_Origin[] = {PT};
static short f_OverhangDistance[] = {
  NAME,RENAME,FIGUREGROUPOBJECT,LESSTHAN,GREATERTHAN,ATMOST,ATLEAST,EXACTLY,
  BETWEEN,SINGLEVALUESET,COMMENT,USERDATA
};
static short f_OverlapDistance[] = {
  NAME,RENAME,FIGUREGROUPOBJECT,LESSTHAN,GREATERTHAN,ATMOST,ATLEAST,EXACTLY,
  BETWEEN,SINGLEVALUESET,COMMENT,USERDATA
};
static short f_Oversize[] = {
  FIGUREGROUPREF,INTERSECTION,UNION,DIFFERENCE,INVERSE,OVERSIZE,CORNERTYPE
};
static short f_Page[] = {
  NAME,RENAME,ARRAY,INSTANCE,NET,NETBUNDLE,COMMENTGRAPHICS,PORTIMPLEMENTATION,
  -PAGESIZE,-BOUNDINGBOX,COMMENT,USERDATA
};
static short f_PageSize[] = {RECTANGLE};
static short f_Parameter[] = {
  NAME,RENAME,ARRAY,BOOLEAN,INTEGER,MINOMAX,NUMBER,POINT,STRING
};
static short f_ParameterAssign[] = {
  NAME,MEMBER,BOOLEAN,INTEGER,MINOMAX,NUMBER,POINT,STRING
};
static short f_ParameterDisplay[] = {NAME,MEMBER,DISPLAY};
static short f_Path[] = {POINTLIST,PROPERTY};
static short f_PathDelay[] = {DELAY,EVENT};
static short f_Permutable[] = {PORTREF,PERMUTABLE,NONPERMUTABLE};
static short f_PhysicalDesignRule[] = {
  FIGUREWIDTH,FIGUREAREA,RECTANGLESIZE,FIGUREPERIMETER,OVERLAPDISTANCE,
  OVERHANGDISTANCE,ENCLOSUREDISTANCE,INTERFIGUREGROUPSPACING,NOTCHSPACING,
  INTRAFIGUREGROUPSPACING,NOTALLOWED,FIGUREGROUP,COMMENT,USERDATA
};
static short f_Plug[] = {SOCKETSET};
static short f_Point[] = {PT,POINTDISPLAY,POINT};
static short f_PointDisplay[] = {PT,DISPLAY};
static short f_PointList[] = {PT};
static short f_Polygon[] = {POINTLIST,PROPERTY};
static short f_Port[] = {
  NAME,RENAME,ARRAY,-DIRECTION,-UNUSED,PORTDELAY,-DESIGNATOR,-DCFANINLOAD,
  -DCFANOUTLOAD,-DCMAXFANIN,-DCMAXFANOUT,-ACLOAD,PROPERTY,COMMENT,USERDATA
};
static short f_PortBackAnnotate[] = {
  PORTREF,-DESIGNATOR,PORTDELAY,-DCFANINLOAD,-DCFANOUTLOAD,-DCMAXFANIN,
  -DCMAXFANOUT,-ACLOAD,PROPERTY,COMMENT
};
static short f_PortBundle[] = {
  NAME,RENAME,ARRAY,LISTOFPORTS,PROPERTY,COMMENT,USERDATA
};
static short f_PortDelay[] = {DERIVATION,DELAY,LOADDELAY,TRANSITION,BECOMES};
static short f_PortGroup[] = {NAME,MEMBER,PORTREF};
static short f_PortImplementation[] = {
  PORTREF,NAME,MEMBER,-CONNECTLOCATION,FIGURE,INSTANCE,COMMENTGRAPHICS,
  PROPERTYDISPLAY,KEYWORDDISPLAY,PROPERTY,USERDATA,COMMENT
};
static short f_PortInstance[] = {
  PORTREF,NAME,MEMBER,-UNUSED,PORTDELAY,-DESIGNATOR,-DCFANINLOAD,-DCFANOUTLOAD,
  -DCMAXFANIN,-DCMAXFANOUT,-ACLOAD,PROPERTY,COMMENT,USERDATA
};
static short f_PortList[] = {PORTREF,NAME,MEMBER};
static short f_PortListAlias[] = {NAME,RENAME,ARRAY,PORTLIST};
static short f_PortMap[] = {PORTREF,PORTGROUP,COMMENT,USERDATA};
static short f_PortRef[] = {NAME,MEMBER,PORTREF,INSTANCEREF,VIEWREF};
static short f_Program[] = {VERSION};
static short f_Property[] = {
  NAME,RENAME,BOOLEAN,INTEGER,MINOMAX,NUMBER,POINT,STRING,-OWNER,-UNIT,
  PROPERTY,COMMENT
};
static short f_PropertyDisplay[] = {NAME,DISPLAY};
static short f_ProtectionFrame[] = {
  PORTIMPLEMENTATION,FIGURE,INSTANCE,COMMENTGRAPHICS,-BOUNDINGBOX,
  PROPERTYDISPLAY,KEYWORDDISPLAY,PARAMETERDISPLAY,PROPERTY,COMMENT,USERDATA
};
static short f_RangeVector[] = {
  LESSTHAN,GREATERTHAN,ATMOST,ATLEAST,EXACTLY,BETWEEN,SINGLEVALUESET
};
static short f_Rectangle[] = {PT,PROPERTY};
static short f_RectangleSize[] = {
  NAME,RENAME,FIGUREGROUPOBJECT,RANGEVECTOR,MULTIPLEVALUESET,COMMENT,USERDATA
};
static short f_Rename[] = {NAME,STRINGDISPLAY};
static short f_Resolves[] = {NAME};
static short f_Scale[] = {E,UNIT};
static short f_Section[] = {SECTION,INSTANCE};
static short f_Shape[] = {CURVE,PROPERTY};
static short f_Simulate[] = {
  NAME,PORTLISTALIAS,WAVEVALUE,APPLY,COMMENT,USERDATA
};
static short f_SimulationInfo[] = {LOGICVALUE,COMMENT,USERDATA};
static short f_SingleValueSet[] = {
  LESSTHAN,GREATERTHAN,ATMOST,ATLEAST,EXACTLY,BETWEEN
};
static short f_Site[] = {VIEWREF,TRANSFORM};
static short f_Socket[] = {SYMMETRY};
static short f_SocketSet[] = {SYMMETRY,SITE};
static short f_Status[] = {WRITTEN,COMMENT,USERDATA};
static short f_Steady[] = {
  NAME,MEMBER,PORTREF,PORTLIST,DURATION,TRANSITION,BECOMES
};
static short f_String[] = {STRINGDISPLAY,STRING};
static short f_StringDisplay[] = {DISPLAY};
static short f_Strong[] = {NAME};
static short f_Symbol[] = {
  PORTIMPLEMENTATION,FIGURE,INSTANCE,COMMENTGRAPHICS,ANNOTATE,-PAGESIZE,
  -BOUNDINGBOX,PROPERTYDISPLAY,KEYWORDDISPLAY,PARAMETERDISPLAY,PROPERTY,
  COMMENT,USERDATA
};
static short f_Symmetry[] = {TRANSFORM};
static short f_Table[] = {ENTRY,TABLEDEFAULT};
static short f_TableDefault[] = {
  LOGICREF,PORTREF,NOCHANGE,TABLE,DELAY,LOADDELAY
};
static short f_Technology[] = {
  NUMBERDEFINITION,FIGUREGROUP,FABRICATE,-SIMULATIONINFO,COMMENT,USERDATA,
  -PHYSICALDESIGNRULE
};
static short f_TimeInterval[] = {EVENT,OFFSETEVENT,DURATION};
static short f_Timing[] = {
  DERIVATION,PATHDELAY,FORBIDDENEVENT,COMMENT,USERDATA
};
static short f_Transform[] = {SCALEX,SCALEY,DELTA,ORIENTATION,ORIGIN};
static short f_Transition[] = {NAME,LOGICLIST,LOGICONEOF};
static short f_Trigger[] = {CHANGE,STEADY,INITIAL};
static short f_Union[] = {
  FIGUREGROUPREF,INTERSECTION,UNION,DIFFERENCE,INVERSE,OVERSIZE
};
static short f_View[] = {
  NAME,RENAME,VIEWTYPE,INTERFACE,-STATUS,-CONTENTS,COMMENT,PROPERTY,USERDATA
};
static short f_ViewList[] = {VIEWREF,VIEWLIST};
static short f_ViewMap[] = {
  PORTMAP,PORTBACKANNOTATE,INSTANCEMAP,INSTANCEBACKANNOTATE,NETMAP,
  NETBACKANNOTATE,COMMENT,USERDATA
};
static short f_ViewRef[] = {NAME,CELLREF};
static short f_Visible[] = {FALSE,TRUE};
static short f_VoltageMap[] = {MNM,E};
static short f_WaveValue[] = {NAME,RENAME,E,LOGICWAVEFORM};
static short f_Weak[] = {NAME};
static short f_WeakJoined[] = {PORTREF,PORTLIST,JOINED};
static short f_When[] = {
  TRIGGER,AFTER,FOLLOW,MAINTAIN,LOGICASSIGN,COMMENT,USERDATA
};
static short f_Written[] = {
  TIMESTAMP,AUTHOR,PROGRAM,DATAORIGIN,PROPERTY,COMMENT,USERDATA
};
/*
 *	Context binding table:
 *
 *	  This binds context follower arrays to their originating context.
 */
typedef struct Binder {
  short *Follower;		/* pointer to follower array */
  short Origin;			/* '%token' value of origin */
  short FollowerSize;		/* size of follower array */
} Binder;
#define	BE(f,o)			{f,o,sizeof(f)/sizeof(short)}
static Binder BinderDef[] = {
  BE(f_NULL,			0),
  BE(f_Edif,			EDIF),
  BE(f_AcLoad,			ACLOAD),
  BE(f_After,			AFTER),
  BE(f_Annotate,		ANNOTATE),
  BE(f_Apply,			APPLY),
  BE(f_Arc,			ARC),
  BE(f_Array,			ARRAY),
  BE(f_ArrayMacro,		ARRAYMACRO),
  BE(f_ArrayRelatedInfo,	ARRAYRELATEDINFO),
  BE(f_ArraySite,		ARRAYSITE),
  BE(f_AtLeast,			ATLEAST),
  BE(f_AtMost,			ATMOST),
  BE(f_Becomes,			BECOMES),
  BE(f_Boolean,			BOOLEAN),
  BE(f_BooleanDisplay,		BOOLEANDISPLAY),
  BE(f_BooleanMap,		BOOLEANMAP),
  BE(f_BorderPattern,		BORDERPATTERN),
  BE(f_BoundingBox,		BOUNDINGBOX),
  BE(f_Cell,			CELL),
  BE(f_CellRef,			CELLREF),
  BE(f_Change,			CHANGE),
  BE(f_Circle,			CIRCLE),
  BE(f_Color,			COLOR),
  BE(f_CommentGraphics,		COMMENTGRAPHICS),
  BE(f_Compound,		COMPOUND),
  BE(f_ConnectLocation,		CONNECTLOCATION),
  BE(f_Contents,		CONTENTS),
  BE(f_Criticality,		CRITICALITY),
  BE(f_CurrentMap,		CURRENTMAP),
  BE(f_Curve,			CURVE),
  BE(f_Cycle,			CYCLE),
  BE(f_DataOrigin,		DATAORIGIN),
  BE(f_DcFanInLoad,		DCFANINLOAD),
  BE(f_DcFanOutLoad,		DCFANOUTLOAD),
  BE(f_DcMaxFanIn,		DCMAXFANIN),
  BE(f_DcMaxFanOut,		DCMAXFANOUT),
  BE(f_Delay,			DELAY),
  BE(f_Delta,			DELTA),
  BE(f_Design,			DESIGN),
  BE(f_Designator,		DESIGNATOR),
  BE(f_Difference,		DIFFERENCE),
  BE(f_Display,			DISPLAY),
  BE(f_Dominates,		DOMINATES),
  BE(f_Dot,			DOT),
  BE(f_Duration,		DURATION),
  BE(f_EnclosureDistance,	ENCLOSUREDISTANCE),
  BE(f_Entry,			ENTRY),
  BE(f_Exactly,			EXACTLY),
  BE(f_External,		EXTERNAL),
  BE(f_Fabricate,		FABRICATE),
  BE(f_Figure,			FIGURE),
  BE(f_FigureArea,		FIGUREAREA),
  BE(f_FigureGroup,		FIGUREGROUP),
  BE(f_FigureGroupObject,	FIGUREGROUPOBJECT),
  BE(f_FigureGroupOverride,	FIGUREGROUPOVERRIDE),
  BE(f_FigureGroupRef,		FIGUREGROUPREF),
  BE(f_FigurePerimeter,		FIGUREPERIMETER),
  BE(f_FigureWidth,		FIGUREWIDTH),
  BE(f_FillPattern,		FILLPATTERN),
  BE(f_Follow,			FOLLOW),
  BE(f_ForbiddenEvent,		FORBIDDENEVENT),
  BE(f_GlobalPortRef,		GLOBALPORTREF),
  BE(f_GreaterThan,		GREATERTHAN),
  BE(f_GridMap,			GRIDMAP),
  BE(f_IncludeFigureGroup,	INCLUDEFIGUREGROUP),
  BE(f_Instance,		INSTANCE),
  BE(f_InstanceBackAnnotate,	INSTANCEBACKANNOTATE),
  BE(f_InstanceGroup,		INSTANCEGROUP),
  BE(f_InstanceMap,		INSTANCEMAP),
  BE(f_InstanceRef,		INSTANCEREF),
  BE(f_Integer,			INTEGER),
  BE(f_IntegerDisplay,		INTEGERDISPLAY),
  BE(f_InterFigureGroupSpacing,	INTERFIGUREGROUPSPACING),
  BE(f_Interface,		INTERFACE),
  BE(f_Intersection,		INTERSECTION),
  BE(f_IntraFigureGroupSpacing,	INTRAFIGUREGROUPSPACING),
  BE(f_Inverse,			INVERSE),
  BE(f_Joined,			JOINED),
  BE(f_KeywordDisplay,		KEYWORDDISPLAY),
  BE(f_KeywordMap,		KEYWORDMAP),
  BE(f_LessThan,		LESSTHAN),
  BE(f_Library,			LIBRARY),
  BE(f_LibraryRef,		LIBRARYREF),
  BE(f_ListOfNets,		LISTOFNETS),
  BE(f_ListOfPorts,		LISTOFPORTS),
  BE(f_LoadDelay,		LOADDELAY),
  BE(f_LogicAssign,		LOGICASSIGN),
  BE(f_LogicInput,		LOGICINPUT),
  BE(f_LogicList,		LOGICLIST),
  BE(f_LogicMapInput,		LOGICMAPINPUT),
  BE(f_LogicMapOutput,		LOGICMAPOUTPUT),
  BE(f_LogicOneOf,		LOGICONEOF),
  BE(f_LogicOutput,		LOGICOUTPUT),
  BE(f_LogicPort,		LOGICPORT),
  BE(f_LogicRef,		LOGICREF),
  BE(f_LogicValue,		LOGICVALUE),
  BE(f_LogicWaveform,		LOGICWAVEFORM),
  BE(f_Maintain,		MAINTAIN),
  BE(f_Match,			MATCH),
  BE(f_Member,			MEMBER),
  BE(f_MiNoMax,			MINOMAX),
  BE(f_MiNoMaxDisplay,		MINOMAXDISPLAY),
  BE(f_Mnm,			MNM),
  BE(f_MultipleValueSet,	MULTIPLEVALUESET),
  BE(f_MustJoin,		MUSTJOIN),
  BE(f_Name,			NAME),
  BE(f_Net,			NET),
  BE(f_NetBackAnnotate,		NETBACKANNOTATE),
  BE(f_NetBundle,		NETBUNDLE),
  BE(f_NetDelay,		NETDELAY),
  BE(f_NetGroup,		NETGROUP),
  BE(f_NetMap,			NETMAP),
  BE(f_NetRef,			NETREF),
  BE(f_NonPermutable,		NONPERMUTABLE),
  BE(f_NotAllowed,		NOTALLOWED),
  BE(f_NotchSpacing,		NOTCHSPACING),
  BE(f_Number,			NUMBER),
  BE(f_NumberDefinition,	NUMBERDEFINITION),
  BE(f_NumberDisplay,		NUMBERDISPLAY),
  BE(f_OffPageConnector,	OFFPAGECONNECTOR),
  BE(f_OffsetEvent,		OFFSETEVENT),
  BE(f_OpenShape,		OPENSHAPE),
  BE(f_Origin,			ORIGIN),
  BE(f_OverhangDistance,	OVERHANGDISTANCE),
  BE(f_OverlapDistance,		OVERLAPDISTANCE),
  BE(f_Oversize,		OVERSIZE),
  BE(f_Page,			PAGE),
  BE(f_PageSize,		PAGESIZE),
  BE(f_Parameter,		PARAMETER),
  BE(f_ParameterAssign,		PARAMETERASSIGN),
  BE(f_ParameterDisplay,	PARAMETERDISPLAY),
  BE(f_Path,			PATH),
  BE(f_PathDelay,		PATHDELAY),
  BE(f_Permutable,		PERMUTABLE),
  BE(f_PhysicalDesignRule,	PHYSICALDESIGNRULE),
  BE(f_Plug,			PLUG),
  BE(f_Point,			POINT),
  BE(f_PointDisplay,		POINTDISPLAY),
  BE(f_PointList,		POINTLIST),
  BE(f_Polygon,			POLYGON),
  BE(f_Port,			PORT),
  BE(f_PortBackAnnotate,	PORTBACKANNOTATE),
  BE(f_PortBundle,		PORTBUNDLE),
  BE(f_PortDelay,		PORTDELAY),
  BE(f_PortGroup,		PORTGROUP),
  BE(f_PortImplementation,	PORTIMPLEMENTATION),
  BE(f_PortInstance,		PORTINSTANCE),
  BE(f_PortList,		PORTLIST),
  BE(f_PortListAlias,		PORTLISTALIAS),
  BE(f_PortMap,			PORTMAP),
  BE(f_PortRef,			PORTREF),
  BE(f_Program,			PROGRAM),
  BE(f_Property,		PROPERTY),
  BE(f_PropertyDisplay,		PROPERTYDISPLAY),
  BE(f_ProtectionFrame,		PROTECTIONFRAME),
  BE(f_RangeVector,		RANGEVECTOR),
  BE(f_Rectangle,		RECTANGLE),
  BE(f_RectangleSize,		RECTANGLESIZE),
  BE(f_Rename,			RENAME),
  BE(f_Resolves,		RESOLVES),
  BE(f_Scale,			SCALE),
  BE(f_Section,			SECTION),
  BE(f_Shape,			SHAPE),
  BE(f_Simulate,		SIMULATE),
  BE(f_SimulationInfo,		SIMULATIONINFO),
  BE(f_SingleValueSet,		SINGLEVALUESET),
  BE(f_Site,			SITE),
  BE(f_Socket,			SOCKET),
  BE(f_SocketSet,		SOCKETSET),
  BE(f_Status,			STATUS),
  BE(f_Steady,			STEADY),
  BE(f_String,			STRING),
  BE(f_StringDisplay,		STRINGDISPLAY),
  BE(f_Strong,			STRONG),
  BE(f_Symbol,			SYMBOL),
  BE(f_Symmetry,		SYMMETRY),
  BE(f_Table,			TABLE),
  BE(f_TableDefault,		TABLEDEFAULT),
  BE(f_Technology,		TECHNOLOGY),
  BE(f_TimeInterval,		TIMEINTERVAL),
  BE(f_Timing,			TIMING),
  BE(f_Transform,		TRANSFORM),
  BE(f_Transition,		TRANSITION),
  BE(f_Trigger,			TRIGGER),
  BE(f_Union,			UNION),
  BE(f_View,			VIEW),
  BE(f_ViewList,		VIEWLIST),
  BE(f_ViewMap,			VIEWMAP),
  BE(f_ViewRef,			VIEWREF),
  BE(f_Visible,			VISIBLE),
  BE(f_VoltageMap,		VOLTAGEMAP),
  BE(f_WaveValue,		WAVEVALUE),
  BE(f_Weak,			WEAK),
  BE(f_WeakJoined,		WEAKJOINED),
  BE(f_When,			WHEN),
  BE(f_Written,			WRITTEN)
};
static int BinderDefSize = sizeof(BinderDef) / sizeof(Binder);
/*
 *	Keyword table:
 *
 *	  This hash table holds all strings which may have to be matched
 *	to. WARNING: it is assumed that there is no overlap of the 'token'
 *	and 'context' strings.
 */
typedef struct Keyword {
  struct Keyword *Next;	 	/* pointer to next entry */
  char *String;			/* pointer to associated string */
} Keyword;
#define	KEYWORD_HASH	127	/* hash table size */
static Keyword *KeywordTable[KEYWORD_HASH];
/*
 *	Enter keyword:
 *
 *	  The passed string is entered into the keyword hash table.
 */
static EnterKeyword(str)
char *str;
{
  register Keyword *key;
  register unsigned int hsh;
  register char *cp;
  /*
   *	Create the hash code, and add an entry to the table.
   */
  for (hsh = 0, cp = str; *cp; hsh += hsh + *cp++);
  hsh %= KEYWORD_HASH;
  key = (Keyword *) Malloc(sizeof(Keyword));
  key->Next = KeywordTable[hsh];
  (KeywordTable[hsh] = key)->String = str;
}
/*
 *	Find keyword:
 *
 *	  The passed string is located within the keyword table. If an
 *	entry exists, then the value of the keyword string is returned. This
 *	is real useful for doing string comparisons by pointer value later.
 *	If there is no match, a NULL is returned.
 */
static char *FindKeyword(str)
char *str;
{
  register Keyword *wlk,*owk;
  register unsigned int hsh;
  register char *cp;
  char lower[IDENT_LENGTH + 1];
  /*
   *	Create a lower case copy of the string.
   */
  for (cp = lower; *str;)
    if (isupper(*str))
      *cp++ = tolower(*str++);
    else
      *cp++ = *str++;
  *cp = '\0';
  /*
   *	Search the hash table for a match.
   */
  for (hsh = 0, cp = lower; *cp; hsh += hsh + *cp++);
  hsh %= KEYWORD_HASH;
  for (owk = NULL, wlk = KeywordTable[hsh]; wlk; wlk = (owk = wlk)->Next)
    if (!strcmp(wlk->String,lower)){
      /*
       *	Readjust the LRU.
       */
      if (owk){
      	owk->Next = wlk->Next;
      	wlk->Next = KeywordTable[hsh];
      	KeywordTable[hsh] = wlk;
      }
      return (wlk->String);
    }
  return (NULL);
}
/*
 *	Token hash table.
 */
#define	TOKEN_HASH	51
static Token *TokenHash[TOKEN_HASH];
/*
 *	Find token:
 *
 *	  A pointer to the token of the passed code is returned. If
 *	no such beastie is present a NULL is returned instead.
 */
static Token *FindToken(cod)
register int cod;
{
  register Token *wlk,*owk;
  register unsigned int hsh;
  /*
   *	Search the hash table for a matching token.
   */
  hsh = cod % TOKEN_HASH;
  for (owk = NULL, wlk = TokenHash[hsh]; wlk; wlk = (owk = wlk)->Next)
    if (cod == wlk->Code){
      if (owk){
      	owk->Next = wlk->Next;
      	wlk->Next = TokenHash[hsh];
      	TokenHash[hsh] = wlk;
      }
      break;
    }
  return (wlk);
}
/*
 *	Context hash table.
 */
#define	CONTEXT_HASH	127
static Context *ContextHash[CONTEXT_HASH];
/*
 *	Find context:
 *
 *	  A pointer to the context of the passed code is returned. If
 *	no such beastie is present a NULL is returned instead.
 */
static Context *FindContext(cod)
register int cod;
{
  register Context *wlk,*owk;
  register unsigned int hsh;
  /*
   *	Search the hash table for a matching context.
   */
  hsh = cod % CONTEXT_HASH;
  for (owk = NULL, wlk = ContextHash[hsh]; wlk; wlk = (owk = wlk)->Next)
    if (cod == wlk->Code){
      if (owk){
      	owk->Next = wlk->Next;
      	wlk->Next = ContextHash[hsh];
      	ContextHash[hsh] = wlk;
      }
      break;
    }
  return (wlk);
}
/*
 *	Token stacking variables.
 */
#ifdef	DEBUG
#define	TS_DEPTH	8
#define	TS_MASK		(TS_DEPTH - 1)
static unsigned int TSP = 0;		/* token stack pointer */
static char *TokenStack[TS_DEPTH];	/* token name strings */
static short TokenType[TS_DEPTH];	/* token types */
/*
 *	Stack:
 *
 *	Add a token to the debug stack. The passed string and type are
 *	what is to be pushed.
 */
static Stack(str,typ)
char *str;
int typ;
{
  /*
   *	Free any previous string, then push.
   */
  if (TokenStack[TSP & TS_MASK])
    Free(TokenStack[TSP & TS_MASK]);
  TokenStack[TSP & TS_MASK] = strcpy((char *)Malloc(strlen(str) + 1),str);
  TokenType[TSP & TS_MASK]  = typ;
  TSP += 1;
}
/*
 *	Dump stack:
 *
 *	  This displays the last set of accumulated tokens.
 */
static DumpStack()
{
  register int i;
  register Context *cxt;
  register Token *tok;
  register char *nam;
  /*
   *	Run through the list displaying the oldest first.
   */
  fprintf(Error,"\n\n");
  for (i = 0; i < TS_DEPTH; i += 1)
    if (TokenStack[(TSP + i) & TS_MASK]){
      /*
       *	Get the type name string.
       */
      if (cxt = FindContext(TokenType[(TSP + i) & TS_MASK]))
        nam = cxt->Name;
      else if (tok = FindToken(TokenType[(TSP + i) & TS_MASK]))
        nam = tok->Name;
      else switch (TokenType[(TSP + i) & TS_MASK]){
      	case IDENT:	nam = "IDENT";		break;
      	case INT:	nam = "INT";		break;
      	case KEYWORD:	nam = "KEYWORD";	break;
      	case STR:	nam = "STR";		break;
      	default:	nam = "?";		break;
      }
      /*
       *	Now print the token state.
       */
      fprintf(Error,"%2d %-16.16s '%s'\n",TS_DEPTH - i,nam,
        TokenStack[(TSP + i) & TS_MASK]);
    }
  fprintf(Error,"\n");
}
#else
#define	Stack(s,t)
#endif

/*
 *	yyerror:
 *
 *	  Standard error reporter, it prints out the passed string
 *	preceeded by the current filename and line number.
 */
yyerror(ers)
char *ers;
{
#ifdef	DEBUG
  DumpStack();
#endif
  fprintf(Error,"%s, Line %d: %s\n", InFile, LineNumber, ers);
}

/*
 *	String bucket definitions.
 */
#define	BUCKET_SIZE	64
typedef struct Bucket {
  struct Bucket *Next;			/* pointer to next bucket */
  int 		Index;			/* pointer to next free slot */
  char 		Data[BUCKET_SIZE];	/* string data */
} Bucket;
static Bucket *CurrentBucket = NULL;	/* string bucket list */
int StringSize = 0;		/* current string length */
/*
 *	Push string:
 *
 *	  This adds the passed charater to the current string bucket.
 */
static PushString(chr)
char chr;
{
  register Bucket *bck;
  /*
   *	Make sure there is room for the push.
   */
  if ((bck = CurrentBucket)->Index >= BUCKET_SIZE){
    bck = (Bucket *) Malloc(sizeof(Bucket));
    bck->Next = CurrentBucket;
    (CurrentBucket = bck)->Index = 0;
  }
  /*
   *	Push the character.
   */
  bck->Data[bck->Index++] = chr;
  StringSize++;
}
/*
 *	Form string:
 *
 *	  This converts the current string bucket into a real live string,
 *	whose pointer is returned.
 */
char *FormString()
{
  register Bucket *bck;
  register char *cp;
  /*
   *	Allocate space for the string, set the pointer at the end.
   */
  cp = (char *) Malloc(StringSize + 1);
  cp += StringSize;
  *cp-- = '\0';
  /*
   *	Yank characters out of the bucket.
   */
  for (bck = CurrentBucket; bck->Index || (bck->Next !=NULL) ;){
    if (!bck->Index){
      CurrentBucket = bck->Next;
      Free(bck);
      bck = CurrentBucket;
    }
    *cp-- = bck->Data[--bck->Index];
  }
  // fprintf(stderr,"FormStr:'%s'\n",cp+1);
  StringSize = 0;
  return (cp + 1);
}

/*
 *	Parse EDIF:
 *
 *	  This builds the context tree and then calls the real parser.
 *	It is passed two file streams, the first is where the input comes
 *	from; the second is where error messages get printed.
 */
ParseEDIF(inp,err)
FILE *inp,*err;
{
  register int i;
  static int ContextDefined = 1;
  /*
   *	Set up the file state to something useful.
   */
  Input = inp;
  Error = err;
  LineNumber = 1;
  /*
   *	Define both the enabled token and context strings.
   */
  if (ContextDefined){
    for (i = TokenDefSize; i--; EnterKeyword(TokenDef[i].Name)){
      register unsigned int hsh;
      hsh = TokenDef[i].Code % TOKEN_HASH;
      TokenDef[i].Next = TokenHash[hsh];
      TokenHash[hsh] = &TokenDef[i];
    }
    for (i = ContextDefSize; i--; EnterKeyword(ContextDef[i].Name)){
      register unsigned int hsh;
      hsh = ContextDef[i].Code % CONTEXT_HASH;
      ContextDef[i].Next = ContextHash[hsh];
      ContextHash[hsh] = &ContextDef[i];
    }
    /*
     *	Build the context tree.
     */
    for (i = BinderDefSize; i--;){
      register Context *cxt;
      register int j;
      /*
       *	Define the current context to have carriers bound to it.
       */
      cxt = FindContext(BinderDef[i].Origin);
      for (j = BinderDef[i].FollowerSize; j--;){
        register ContextCar *cc;
        /*
         *	Add carriers to the current context.
         */
        cc = (ContextCar *) Malloc(sizeof(ContextCar));
        cc->Next = cxt->Context;
        (cxt->Context = cc)->Context =
          FindContext(ABS(BinderDef[i].Follower[j]));
        cc->u.Single = BinderDef[i].Follower[j] < 0;
      }
    }
    /*
     *	Build the token tree.
     */
    for (i = TieDefSize; i--;){
      register Context *cxt;
      register int j;
      /*
       *	Define the current context to have carriers bound to it.
       */
      cxt = FindContext(TieDef[i].Origin);
      for (j = TieDef[i].EnableSize; j--;){
        register TokenCar *tc;
        /*
         *	Add carriers to the current context.
         */
        tc = (TokenCar *) Malloc(sizeof(TokenCar));
        tc->Next = cxt->Token;
        (cxt->Token = tc)->Token = FindToken(TieDef[i].Enable[j]);
      }
    }
    /*
     *	Put a bogus context on the stack which has 'EDIF' as its
     *	follower.
     */
    CSP = (ContextCar *) Malloc(sizeof(ContextCar));
    CSP->Next = NULL;
    CSP->Context = FindContext(NULL);
    CSP->u.Used = NULL;
    ContextDefined = 0;
  }
  /*
   *	Create an initial, empty string bucket.
   */
  CurrentBucket = (Bucket *) Malloc(sizeof(Bucket));
  CurrentBucket->Next = NULL;
  CurrentBucket->Index = 0;
  /*
   *	Fill the token stack with NULLs if debugging is enabled.
   */
#ifdef	DEBUG
  for (i = TS_DEPTH; i--; TokenStack[i] = NULL)
    if (TokenStack[i])
      Free(TokenStack[i]);
  TSP = 0;
#endif
  /*
   *	Go parse things!
   */
  yyparse();

  // DumpStack();
}

/*
 *	Match token:
 *
 *	  The passed string is looked up in the current context's token
 *	list to see if it is enabled. If so the token value is returned,
 *	if not then zero.
 */
static int MatchToken(str)
register char *str;
{
  register TokenCar *wlk,*owk;
  /*
   *	Convert the string to the proper form, then search the token
   *	carrier list for a match.
   */
  str = FindKeyword(str);
  for (owk = NULL, wlk = CSP->Context->Token; wlk; wlk = (owk = wlk)->Next)
    if (str == wlk->Token->Name){
      if (owk){
        owk->Next = wlk->Next;
        wlk->Next = CSP->Context->Token;
        CSP->Context->Token = wlk;
      }
      return (wlk->Token->Code);
    }
  return (0);
}

/*
 *	Match context:
 *
 *	  If the passed keyword string is within the current context, the
 *	new context is pushed and token value is returned. A zero otherwise.
 */
static int MatchContext(str)
register char *str;
{
  register ContextCar *wlk,*owk;
  /*
   *	See if the context is present.
   */
  str = FindKeyword(str);
  for (owk = NULL, wlk = CSP->Context->Context; wlk; wlk = (owk = wlk)->Next)
    if (str == wlk->Context->Name){
      if (owk){
      	owk->Next = wlk->Next;
      	wlk->Next = CSP->Context->Context;
      	CSP->Context->Context = wlk;
      }
      /*
       *	If a single context, make sure it isn't already used.
       */
      if (wlk->u.Single){
      	register UsedCar *usc;
      	for (usc = CSP->u.Used; usc; usc = usc->Next)
      	  if (usc->Code == wlk->Context->Code)
      	    break;
      	if (usc){
      	  sprintf(CharBuf,"'%s' is Used more than once within '%s'",
      	    str,CSP->Context->Name);
      	  yyerror(CharBuf);
      	} else {
      	  usc = (UsedCar *) Malloc(sizeof(UsedCar));
      	  usc->Next = CSP->u.Used;
      	  (CSP->u.Used = usc)->Code = wlk->Context->Code;
      	}
      }
      /*
       *	Push the new context.
       */
      owk = (ContextCar *) Malloc(sizeof(ContextCar));
      owk->Next = CSP;
      (CSP = owk)->Context = wlk->Context;
      owk->u.Used = NULL;
      return (wlk->Context->Code);
    }
  return (0);
}

/*
 *	PopC:
 *
 *	  This pops the current context.
 */
PopC()
{
  register UsedCar *usc;
  register ContextCar *csp;
  /*
   *	Release single markers and pop context.
   */
  while (usc = CSP->u.Used){
    CSP->u.Used = usc->Next;
    Free(usc);
  }
  csp = CSP->Next;
  Free(CSP);
  CSP = csp;
}

/*
 *	Lexical analyzer states.
 */
#define	L_START		0
#define	L_INT		1
#define	L_IDENT		2
#define	L_KEYWORD	3
#define	L_STRING	4
#define	L_KEYWORD2	5
#define	L_ASCIICHAR	6
#define	L_ASCIICHAR2	7
/*
 *	yylex:
 *
 *	  This is the lexical analyzer called by the YACC/BISON parser.
 *	It returns a pretty restricted set of token types and does the
 *	context movement when acceptable keywords are found. The token
 *	value returned is a NULL terminated string to allocated storage
 *	(ie - it should get released some time) with some restrictions.
 *	  The token value for integers is strips a leading '+' if present.
 *	String token values have the leading and trailing '"'-s stripped.
 *	'%' conversion characters in string values are passed converted.
 *	The '(' and ')' characters do not have a token value.
 */
int yylex()
{
  extern YYSTYPE yylval;
  struct st  *st;
  register int c,s,l,len;
  /*
   *	Keep on sucking up characters until we find something which
   *	explicitly forces us out of this function.
   */
  for (s = L_START, l = 0; 1; ){
    yytext[l++] = c = Getc(Input);
    if (c == '\n')
       LineNumber++ ;
    switch (s){
      case L_START:
        if (isdigit(c) || c == '-')
          s = L_INT;
        else if (isalpha(c) || c == '&')
          s = L_IDENT;
        else if (isspace(c)){
          l = 0;
        } else if (c == '('){
          l = 0;
          s = L_KEYWORD;
        } else if (c == '"')
          s = L_STRING;
        else if (c == '+'){
          l = 0;				/* strip '+' */
          s = L_INT;
        } else if (c == EOF)
          return ('\0');
        else {
          yytext[1] = '\0';
          Stack(yytext, c);
          return (c);
        }
        break;
      /*
       *	Suck up the integer digits.
       */
      case L_INT:
        if (isdigit(c))
          break;
        Ungetc(c);
        yytext[--l] = '\0';
        // yylval.s = strcpy((char *)Malloc(l + 1),yytext);
	st = (struct st *)Malloc(sizeof (struct st));
        st->s = strdup(yytext); 
	yylval.st = st ;
        Stack(yytext, INT);
        return (INT);
      /*
       *	Grab an identifier, see if the current context enables
       *	it with a specific token value.
       */
      case L_IDENT:
        if (isalpha(c) || isdigit(c) || c == '_')
          break;
        Ungetc(c);
        yytext[--l] = '\0';
        if (CSP->Context->Token && (c = MatchToken(yytext))){
          Stack(yytext, c);
          return (c);
        }
        // yylval.s = strcpy((char *)Malloc(l + 1),yytext);
        // st->s = strdup(yytext); 
	st = (struct st *)Malloc(sizeof (struct st));
	if(l>0 && st != NULL){
           st->s = (char *)Malloc(l + 1); 
	// fprintf(stderr,"l %d st %x st.s %x yytext '%s'\n",l,st,st->s,yytext);
           strcpy(st->s, yytext);
	   yylval.st = st ;
	}
        Stack(yytext, IDENT);
        return (IDENT);
      /*
       *	Scan until you find the start of an identifier, discard
       *	any whitespace found. On no identifier, return a '('.
       */
      case L_KEYWORD:
        if (isalpha(c) || c == '&'){
          s = L_KEYWORD2;
          break;
        } else if (isspace(c)){
          l = 0;
          break;
        }
        Ungetc(c);
        Stack("(",'(');
        return ('(');
      /*
       *	Suck up the keyword identifier, if it matches the set of
       *	allowable contexts then return its token value and push
       *	the context, otherwise just return the identifier string.
       */
      case L_KEYWORD2:
        if (isalpha(c) || isdigit(c) || c == '_')
          break;
        Ungetc(c);
        yytext[--l] = '\0';
        if (c = MatchContext(yytext)){
          Stack(yytext, c);
          return (c);
        }
        // yylval.s = strcpy((char *)Malloc(l + 1),yytext);
	st = (struct st *)Malloc(sizeof (struct st));
        st->s = strdup(yytext); 
	yylval.st = st ;
        Stack(yytext, KEYWORD);
        return (KEYWORD);
      /*
       *	Suck up string characters but once resolved they should
       *	be deposited in the string bucket because they can be
       *	arbitrarily long.
       */
      case L_STRING:
        if (c == '\r')
          ;
        else if (c == '"' || c == EOF){
	  st = (struct st *)Malloc(sizeof (struct st));
          st->s = FormString();  
	  yylval.st = st ; 
          Stack(yytext, STR);
          return (STR);
        } else  if (c == '%')
          s = L_ASCIICHAR;
        else
          PushString(c);
        l = 0;
        break;
      /*
       *	Skip white space and look for integers to be pushed
       *	as characters.
       */
      case L_ASCIICHAR:
        if (isdigit(c)){
          s = L_ASCIICHAR2;
          break;
        } else if (c == '%' || c == EOF)
          s = L_STRING;
        l = 0;
        break;
      /*
       *	Convert the accumulated integer into a char and push.
       */
      case L_ASCIICHAR2:
        if (isdigit(c))
          break;
        Ungetc(c);
        yytext[--l] = '\0';
        PushString(yytext);
        s = L_ASCIICHAR;
        l = 0;
        break;
    }
  }
}
