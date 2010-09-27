/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/menus/menu_move.p
 > Purpose:
 > Author:          Aaron Sloman, Jan 21 1995
 > Documentation:
 > Related Files:
 */

/*
-- -- Cursor move menus
*/

section;

define :menu move;
	'Move Ops'
	{cols 2}
	'Menu move: move cursor'
	['PageUp' vedprevscreen]
	['PageDown' vednextscreen]
	['OtherFileUp' ved_xup]
	['OtherFileDn' ved_xdn]
	['UpLots' vedcharuplots]
	['DownLots' vedchardownlots]
	['TopFile' vedtopfile]
	['EndFile' vedendfile]
	['NextPara' vednextpara]
	['PrevPara' vedprevpara]
	['NextSent' vednextsent]
	['PrevSent' vedprevsent]
	['ScreenLeft' vedscreenleft]
	['TextRight' vedtextright]
	['NextLine' vednextline]
	['MidWindow'  vedmidwindow]
	['WdLeft' vedwordleft]
	['WdRight' vedwordright]
	['WdStart' vedstartwordleft]
	['WdEnd' vedendwordright]
	['Up' vedcharup]
	['Down' vedchardown]
	['Left' vedcharleft]
	['Right' vedcharright]
	['UpL' vedcharupleft]
	['UpR' vedcharupright]
	['DnL' vedchardownleft]
	['DnR' vedchardownright]
	['Switch' vedswapfiles]
	['Editor...' [MENU editor]]
	['HELP Procs' 'menu_doc ref vedprocs Changing']
	['HELP Keys' 'menu_doc help vedkeys Moving']
	['HELP Ncd' 'menu_doc help ncdxtermkeys']
	['HELP Sun4' 'menu_doc help sunxtermkeys']
	['MENUS...' [MENU toplevel]]
enddefine ;

endsection;
