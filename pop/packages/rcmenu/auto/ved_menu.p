/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rcmenu/auto/ved_menu.p
 > Purpose:			Set up menus for use in VED
 > Author:          Aaron Sloman, Aug 11 1999 (see revisions)
 > Documentation:
 > Related Files:
 */

/* --- The University of Birmingham 1995. -------------------------
 > File:            $poplocal/local/menu/auto/ved_menu.p
 > Purpose:			Set up menus for use in VED
 > Author:          Aaron Sloman, Jun 21 1993 (see revisions)
 > Documentation:	HELP * VED_MENU, TEACH * VED_MENU HELP POPUPTOOL
 > Related Files:   LIB * PROPSHEET, LIB * MENU_NEW_MENU TEACH * PROPSHEET,
 > 					Various libraries in $usepop/pop/x/pop/lib/
 */

section;
;;; uses puilib
;;; uses menulib
uses rclib
uses rc_control_panel

uses rcmenulib
uses menu_new_menu

define ved_menu;
	;;; 'ENTER menu <name>' gets the menu called menu_<name>
	;;; 'ENTER menu' is equivalent to 'ENTER menu toplevel'
	;;; 'ENTER menu r <name>' recompiles the menu, if it is in an
	;;; appropriate menu directory.
	lvars name, reload = false;

    if  iscaller(vedsetup) or iscaller(vedinitcomp)
    or iscaller(vedinit)
    then
		;;; ved still being initialised. Postpone action
        vedinput(ved_menu);
        return();
	else
		if vedediting then
			;;; already in VED
			if vedargument = 'r' or vedargument = nullstring then
				menu_toplevel_name -> name;
				unless vedargument = nullstring then
				1 -> reload;
				endunless;
				nullstring -> vedargument;
			else
				if isstartstring('r ', vedargument) then
					1 -> reload;
					allbutfirst(2, vedargument) -> name;
				else
					vedargument -> name;
				endif;
			endif;
			menu_new_menu(name, reload)
		else
			;;; not in VED, so start it up, with a menu command in the
			;;; input stream.
			vedinput(veddo(%'menu ' sys_>< vedargument%));
			ved_ved();
		endif;
	endif
enddefine;


endsection;


nil -> proglist;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Aug 11 1999
	removed puilib


 */
