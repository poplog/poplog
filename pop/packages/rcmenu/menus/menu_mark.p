/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/menus/menu_mark.p
 > Purpose:
 > Author:          Aaron Sloman, Jan 29 1995
 > Documentation:
 > Related Files:
 */

/*
-- -- Menus concerned with marked ranges
*/

section;

define :menu mark;
	'Mark Ops'
	{cols 2}
	'Menu mark: marked range'	
	['HELP mark' 'menu_doc help mark']
	['TEACH mark' 'menu_doc teach mark']
	['MarkStart' vedmarklo]
	['GoStart' vedmarkfind]
	['MarkEnd' vedmarkhi]
	['GoEnd' vedendrange]
	['DelRange' ved_d]
	['YankBack' ved_y]
	['CopyRange' ved_t]
	['MoveRange' ved_m]
	['MoveIn' ved_mi]
	['CopyIn' ved_ti]
	['MoveOut' ved_mo]
	['CopyOut' ved_to]
	['MarkAll' ved_mbe]
	['ClearMark' ved_crm]
	['MarkProc' ved_mcp]
	['CompProc' ved_lcp]
	['TidyProc' ved_jcp]
	['CompRange' ved_lmr]
	['FillRange' ved_j]
	['FillPara' ved_jp]
	['JustifyRange' ved_jj]
	['JustifyPara' ved_jjp]
	['UnJustify' ved_gobble]
	['TidyRange' ved_tidy]
	['Move...' [MENU move]]
	['Editor...' [MENU editor]]
	['Control...' [MENU control]]
	['MENUS...' [MENU toplevel]]
enddefine ;

endsection;
