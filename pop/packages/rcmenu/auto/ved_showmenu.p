/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/auto/ved_showmenu.p
 > Purpose:         Examine a menu
 > Author:          Aaron Sloman, Jan 21 1995
 > Documentation:
 > Related Files:
 */

section;

global vars vedmenuname = undef;

define ved_showmenu();
	;;; lib ENTER showlib, but shows a menu instead.
	;;; e.g. ENTER showmenu files
	if vedargument /= nullstring then
		;;; add standard prefix and suffix
		dlocal vedargument = 'menu_' sys_>< vedargument sys_>< '.p';
	endif;

	vedsysfile("vedmenuname", menu_dirs <> popautolist,
					procedure();
						"menu" -> vedfileprops;
						vedhelpdefaults()
					endprocedure);
enddefine;

endsection;
