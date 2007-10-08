	/************************/
	/*	savelib.cc	*/
	/************************/

/* Routines de sauvegarde et maintenance de librairies et composants
*/

#include "fctsys.h"
#include "eelibsl.h"

#define DisplayError printf
#define TEXT_NO_VISIBLE 1

int LibraryEntryCompare(LibraryEntryStruct *LE1, LibraryEntryStruct *LE2);
static int WriteOneLibEntry(FILE * ExportFile, LibraryEntryStruct * LibEntry);

/* Variables locales */



/**************************************************************************/
/* void SaveActiveLibrary(FILE * SaveFile, LibraryEntryStruct *LibEntry ) */
/**************************************************************************/

void SaveActiveLibrary(FILE * SaveFile, LibraryStruct *CurrentLib )
{
LibraryEntryStruct *LibEntry;
int ii;

	/* Creation de l'entete de la librairie */
	fprintf(SaveFile,"%s Version 1.0\n", FILE_IDENT);
	fprintf(SaveFile,"### Library: %s ###\n", CurrentLib->Name);

	LibEntry = (LibraryEntryStruct *) CurrentLib->Entries;
	for( ii = CurrentLib->NumOfParts ; ii > 0; ii-- ) {
		if(LibEntry != NULL) {
			WriteOneLibEntry(SaveFile, LibEntry);
			fprintf(SaveFile,"#\n");
			}
		else break;
		LibEntry = (LibraryEntryStruct *) LibEntry->nxt;
		}

	fprintf(SaveFile,"#End Library\n");
}


/**************************************************************************/
/* int WriteOneLibEntry(FILE * ExportFile, LibraryEntryStruct * LibEntry) */
/**************************************************************************/

/* Routine d'ecriture du composant pointe par LibEntry
	dans le fichier ExportFile( qui doit etre deja ouvert)
	return: 0 si Ok
			-1 si err write
			1 si composant non ecrit ( type ALIAS )
*/
#define UNUSED 0
int WriteOneLibEntry(FILE * ExportFile, LibraryEntryStruct * LibEntry)
{
LibraryDrawEntryStruct *DrawEntry;
LibraryFieldEntry * Field;
void * DrawItem;
int * ptpoly;
int ii, t1, t2, Etype;
char PinNum[5];
char FlagXpin = 0;

	if( LibEntry->Type != ROOT ) return(1);

	/* Creation du commentaire donnant le nom du composant */
	fprintf(ExportFile,"# %s\n#\n", LibEntry->Name);

	/* Generation des lignes utiles */
	fprintf(ExportFile,"DEF");
	if(LibEntry->DrawName) fprintf(ExportFile," %s",LibEntry->Name);
	else fprintf(ExportFile," ~%s",LibEntry->Name);

	if(LibEntry->Prefix[0] > ' ') fprintf(ExportFile," %s",LibEntry->Prefix);
	else fprintf(ExportFile," ~");
	fprintf(ExportFile," %d %d %c %c %d %d %c\n",
		UNUSED, LibEntry->TextInside,
		LibEntry->DrawPinNum ? 'Y' : 'N',
		LibEntry->DrawPinName ? 'Y' : 'N',
		LibEntry->NumOfUnits, UNUSED, 'N');

	/* Position / orientation / visibilite des champs */
	fprintf(ExportFile,"F0 \"%s\" %d %d %d %c %c\n",
				LibEntry->Prefix,
				LibEntry->PrefixPosX, LibEntry->PrefixPosY,
				LibEntry->PrefixSize,
				LibEntry->PrefixOrient == 0 ? 'H' : 'V',
				LibEntry->DrawPrefix ? 'V' : 'I' );

	fprintf(ExportFile,"F1 \"%s\" %d %d %d %c %c\n",
				LibEntry->Name,
				LibEntry->NamePosX, LibEntry->NamePosY,
				LibEntry->NameSize,
				LibEntry->NameOrient == 0 ? 'H' : 'V',
				LibEntry->DrawName ? 'V' : 'I' );

	for ( Field = LibEntry->Fields; Field!= NULL; Field = Field->nxt )
		{
		if( Field->Text == NULL ) continue;
		if( strlen(Field->Text) == 0 ) continue;
		fprintf(ExportFile,"F%d \"%s\" %d %d %d %c %c\n",
				Field->FieldId,
				Field->Text,
				Field->PosX, Field->PosY, Field->Size,
				Field->Orient == 0 ? 'H' : 'V',
				(Field->Flags & TEXT_NO_VISIBLE) ? 'I' : 'V' );
		}

	/* Sauvegarde de la ligne "ALIAS" */
	if( LibEntry->AliasList )
		if( strlen(LibEntry->AliasList) )
			fprintf(ExportFile,"ALIAS %s\n", LibEntry->AliasList);

	/* Sauvegarde des elements de trace */
	DrawEntry = LibEntry->Drawings;
	if(DrawEntry)
		{
		fprintf(ExportFile,"DRAW\n");
		while( DrawEntry )
			{
			switch( DrawEntry->DrawType)
				{
				case ARC_DRAW_TYPE:
					#define DRAWSTRUCT     (&(DrawEntry->U.Arc))
					t1 = DRAWSTRUCT->t1 - 1; if(t1 > 1800) t1 -= 3600;
					t2 = DRAWSTRUCT->t2 + 1; if(t2 > 1800) t2 -= 3600;
					fprintf(ExportFile,"A %d %d %d %d %d %d %d %d\n",
						DRAWSTRUCT->x, DRAWSTRUCT->y,
						DRAWSTRUCT->r, t1, t2,
						DrawEntry->Unit,DrawEntry->Convert, DRAWSTRUCT->width);
					break;

				case CIRCLE_DRAW_TYPE:
					#undef DRAWSTRUCT
					#define DRAWSTRUCT (&(DrawEntry->U.Circ))
					fprintf(ExportFile,"C %d %d %d %d %d %d\n",
						DRAWSTRUCT->x, DRAWSTRUCT->y,
						DRAWSTRUCT->r,
						DrawEntry->Unit,DrawEntry->Convert, DRAWSTRUCT->width);
					break;

				case TEXT_DRAW_TYPE:
					#undef DRAWSTRUCT
					#define DRAWSTRUCT (&(DrawEntry->U.Text))
					if( DRAWSTRUCT->Text != NULL &
					    strcmp(DRAWSTRUCT->Text, " ") )
					fprintf(ExportFile,"T %d %d %d %d %d %d %d %s\n",
						DRAWSTRUCT->Horiz,DRAWSTRUCT->x, DRAWSTRUCT->y,
						DRAWSTRUCT->size, DRAWSTRUCT->type,
						DrawEntry->Unit,DrawEntry->Convert,
						DRAWSTRUCT->Text );
					break;

				case SQUARE_DRAW_TYPE:
					#undef DRAWSTRUCT
					#define DRAWSTRUCT (&(DrawEntry->U.Sqr))
					fprintf(ExportFile,"S %d %d %d %d %d %d %d\n",
					DRAWSTRUCT->x1,DRAWSTRUCT->y1,
					DRAWSTRUCT->x2,DRAWSTRUCT->y2,
					DrawEntry->Unit,DrawEntry->Convert, DRAWSTRUCT->width);
					break;

				case PIN_DRAW_TYPE:
					#undef DRAWSTRUCT
					#define DRAWSTRUCT (&(DrawEntry->U.Pin))
					FlagXpin = 1;
					Etype = 'I';
						switch(DRAWSTRUCT->PinType)
						{
						case PIN_INPUT: Etype = 'I'; break;
						case PIN_OUTPUT: Etype = 'O'; break;
						case PIN_BIDI: Etype = 'B'; break;
						case PIN_TRISTATE: Etype = 'T'; break;
						case PIN_PASSIVE: Etype = 'P'; break;
						case PIN_UNSPECIFIED: Etype = 'U'; break;
						case PIN_POWER: Etype = 'W'; break;
						case PIN_OPENCOLLECTOR: Etype = 'C'; break;
						case PIN_OPENEMITTER:	Etype = 'E'; break;
						}
					memset(PinNum,0, sizeof(PinNum) );
					if(DRAWSTRUCT->Num)
						strncpy(PinNum,(char *)(&DRAWSTRUCT->Num), 4);
					else PinNum[0] = '0';
					if((DRAWSTRUCT->Name != NULL) && (DRAWSTRUCT->Name[0] > ' '))
						  fprintf(ExportFile,"X %s", DRAWSTRUCT->Name);
					else fprintf(ExportFile,"X ~");

					fprintf(ExportFile," %s %d %d %d %c %d %d %d %d %c",
						PinNum,
						DRAWSTRUCT->posX,DRAWSTRUCT->posY,
						(int)DRAWSTRUCT->Len,(int)DRAWSTRUCT->Orient,
						DRAWSTRUCT->SizeNum, DRAWSTRUCT->SizeName,
						DrawEntry->Unit,DrawEntry->Convert, Etype);

					if( (DRAWSTRUCT->PinShape) || (DRAWSTRUCT->Flags & PINNOTDRAW) )
						fprintf(ExportFile," ");
					if (DRAWSTRUCT->Flags & PINNOTDRAW)
						fprintf(ExportFile,"N");
					if (DRAWSTRUCT->PinShape & INVERT)
						fprintf(ExportFile,"I");
					if (DRAWSTRUCT->PinShape & CLOCK)
						fprintf(ExportFile,"C");
					if (DRAWSTRUCT->PinShape & LOWLEVEL_IN)
						fprintf(ExportFile,"L");
					if (DRAWSTRUCT->PinShape & LOWLEVEL_OUT)
						fprintf(ExportFile,"V");

					fprintf(ExportFile,"\n");
					break;

				case POLYLINE_DRAW_TYPE:
					#undef DRAWSTRUCT
					#define DRAWSTRUCT (&(DrawEntry->U.Poly))
					fprintf(ExportFile,"P %d %d %d %d", DRAWSTRUCT->n,
						DrawEntry->Unit,DrawEntry->Convert, DRAWSTRUCT->width);
					ptpoly = DRAWSTRUCT->PolyList;
					for( ii = DRAWSTRUCT->n ; ii > 0; ii-- )
						{
						fprintf(ExportFile,"  %d %d", *ptpoly, *(ptpoly+1) );
						ptpoly += 2;
						}
					if (DRAWSTRUCT->Fill) fprintf(ExportFile," F");
					fprintf(ExportFile,"\n");
					break;

				default: DisplayError( "Save Lib: Unknown Draw Type");
					break;
				}

			DrawEntry = DrawEntry->nxt;
			}
		fprintf(ExportFile,"ENDDRAW\n");
		}

	fprintf(ExportFile,"ENDDEF\n");

	return(0);
}


/*****************************************************************************
* Routine to compare two LibraryEntryStruct for the PriorQue module.		 *
* Comparison is based on Part name.											 *
*****************************************************************************/
int LibraryEntryCompare(LibraryEntryStruct *LE1, LibraryEntryStruct *LE2)
{
	return strcmp(LE1->Name, LE2->Name);
}


