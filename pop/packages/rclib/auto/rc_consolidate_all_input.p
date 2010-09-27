/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:			$poplocal/local/rclib/auto/rc_consolidate_all_input.p
 > Purpose:			Consolidate all the text or number input buttons
					in a panel
 > Author:			Aaron Sloman, Aug  4 2002 (see revisions)
 > Documentation:
 > Related Files:
 */

section;

compile_mode
            :pop11 +varsch +defpdr -defcon -lprops -constr +global
            :vm +prmfix
            :popc -wrdflt -wrclos;

uses rclib;
uses rc_text_input;
uses rc_control_panel;

define :method vars rc_consolidate_all_input(panel:rc_panel);
	;;; find all the text intput fields in the panel and consolidate them.
	dlocal rc_current_window_object;

	unless panel == rc_current_window_object then
		panel -> rc_current_window_object;
	endunless;

	lvars field, contents, item;
	for field in rc_panel_fields(panel) do
		;;;[field ^field].Veddebug;
		if isrc_textin_field(field) then
			rc_field_contents(field) -> contents;
			if isrc_text_input(contents) then
				if rc_text_input_active(contents) then
					consolidate_or_activate(contents)
				endif;
			else
				;;; it is a list of items, so
				for item in contents do
					if rc_text_input_active(item) then
						consolidate_or_activate(item)
					endif;
				endfor;
			endif;
		endif;
	endfor;

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep  9 2002
		changed compile_mode
 */
