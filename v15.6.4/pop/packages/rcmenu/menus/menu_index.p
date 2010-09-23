/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/menus/menu_index.p
 > Purpose:
 > Author:          Aaron Sloman, Jan 21 1995
 > Documentation:
 > Related Files:
 */


/*
-- -- Indexify and related procedures
*/
section;

define :menu index;
	'Index Ops:'
	'Menu index'
	'(Indexify' 'Go to section)'
	['TUTORIAL' 'help enter_g']
	['Indexify' 'indexify']
	['GoSection' 'g']
	['IndexProcs' 'indexify define']
	['GoProc'  'g define']
	['Get headers' 'headers']
	['GP' 'gp']
	['Quit1' ved_q]
	['RotateFiles' ved_rb]
	['SwapFile' vedswapfiles]
	['Teach...' [MENU teach]]
	['Editor...' [MENU editor]]
	['Files...' [MENU files]]
	['HELP Indexify' 'help ved_indexify']
	['HELP headers' 'help ved_headers']
	['MENUS...' [MENU toplevel]]
enddefine;

endsection;
