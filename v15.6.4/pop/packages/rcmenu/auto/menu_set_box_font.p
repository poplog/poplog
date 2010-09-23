/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/auto/menu_set_box_font.p
 > Purpose:         setting fonts
 > Author:          Aaron Sloman, Jan 21 1995
 > Documentation:
 > Related Files:
 */

/*

Utility provided for setting fonts in Propsheets. Does not always
work, so has to be used with caution. In particular does not work
with propsheet fields.

*/


section;

define global procedure menu_set_box_font(root, font);
	;;; provided by Adrian Howard
    dlvars font, root;

#_IF DEF SYSTEM_V
	;;; doesn't seem to work yet A.S. Mon Jun 28  1993
	return();
#_ENDIF

    applist(
        root.XptWidgetTree.flatten,
        procedure(widget);
            lvars widget,
                has_font = XptResourceInfo(widget, XtN font),
                ;
;;;[has_font ^has_font] =>
			if has_font then font -> XptPopValue( widget, XtN font) endif
        endprocedure
    );
enddefine;

endsection;
