/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/auto/menu_set_box_colours.p
 > Purpose:         set colours for menu
 > Author:          Aaron Sloman, Jan 21 1995
 > Documentation:
 > Related Files:
 */

/*
Set colours for menu.
Does not seem to work for Solaris Poplog
*/

section;

define global procedure menu_set_box_colours(propbox, fg, bg);
	;;; provided by Adrian Howard
	;;; set the foreground and background colours on the box
	lvars propbox;
    dlvars fg, bg;
returnunless(fg or bg);

	#_IF DEF SYSTEM_V
	;;; doesn't seem to work yet A.S. Mon Jun 28  1993
	;;;	return();
	#_ENDIF

    applist(
        propbox.XptWidgetTree.flatten,
        procedure(widget);
            lvars widget, doit = false,
                has_fg = fg and XptResourceInfo(widget, XtN foreground),
                has_bg = bg and XptResourceInfo(widget, XtN background),
                has_fc = fg and XptResourceInfo(widget, XtN fontColor)
            ;
            if has_fg and fg then fg ->> doit; endif;
            if has_bg and bg then bg ->> doit; endif;
            if has_fc and fg then fg ->> doit; endif;
			if doit then
               	-> XptPopValue(
                	widget,
                	if has_fg and fg then XtN foreground endif,
                	if has_bg and bg then XtN background endif,
                	if has_fc and fg then XtN fontColor  endif
            	);
			endif;
        	endprocedure
    );
enddefine;

endsection;


/*
Revisions
	--- 25 Jan 1995 Anthony Worrall
		Stack underflow bug fixed
	--- 10 Dec 1993 Aaron Sloman
		Changed to allow false for fg and or bg

*/
