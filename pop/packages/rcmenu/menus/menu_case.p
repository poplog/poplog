/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/menus/menu_case.p
 > Purpose:			Case change
 > Author:          Aaron Sloman, Jan 21 1995
 */


/*
-- -- Menu concerned with case change
*/
section;

define :menu case;
	'Case Ops'
	'Menu case'
	 'Changing\ncase'
	['HELP Commands' 'menu_doc ref vedcomms Case']
	['HELP Keys' 'menu_doc help vedkeys Miscellaneous']
	[LwrCaseWd ved_lcw]
	[UpprCaseWd ved_ucw]
	[LwrCaseLine ved_lcl]
	[UpprCaseLine ved_ucl]
	[CapWord ved_capword]
	[ChangeWord ved_ccw]
	[ChangeChar vedchangecase]
	['WdLeft' vedwordleft]
	['WdRight' vedwordright]
	['WdStart' vedstartwordleft]
	['WdEnd' vedendwordright]
	['NextLine' vednextline]
	['PrevLine' vedcharup]
	
;;;	[ChangeRange ved_ccr]	;;; not in library
	['MENUS...' [MENU toplevel]]
enddefine;
endsection;
