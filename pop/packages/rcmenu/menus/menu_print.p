/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/menus/menu_print.p
 > Purpose:
 > Author:          Aaron Sloman, Jan 21 1995
 > Documentation:
 > Related Files:
 */

/*
-- Printing utilities at Birmingham

Needs to be generalised and extended
*/
section;

define :menu print;
	'PRINTING'
	'Menu print'
	 'Printing\nFiles'
	;;; Basic printing to ascii printer
	['RnoPrint' 'rnoprint']
	;;; Landscape printing using a2ps
	['PsPrintMR' 'psprintmr']
	['PsPrintAll' 'psprint']
	;;; portrait printing using a2ps
	['PsPrintP' 'psprint -p']
	['PsPrintP MR' 'psprintmr -p']
	['LatexPrint' 'latex print']
	['Latex...' [MENU latex]]
	['Editor...' [MENU editor]]
	['Use LPR' 'lpr']
	['Use LPR mr' 'lprmr']
	['HELP' 'help printmenu']
	['TEACH Printing' 'teach printing']
	['HELP PsPrint' 'help ved_psprint']
	['HELP Rno' 'help rno']
;;;	['HELP Sun1Print' 'help sun1print']
	['TEACH Latex' 'tach latex']
	['HELP Latex' 'help latex']
	['HELP LPR' 'help lpr']
	['MENUS...' [MENU toplevel]]
enddefine;

endsection;
