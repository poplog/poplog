/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:			$poplocal/local/rclib/auto/rc_panel_field_value.p
 > Purpose:			Given a list of labels and a panel go down the panel
					hierarchy using the labels. Return or update result.
 > Author:			Aaron Sloman, Aug 10 2002 (see revisions)
					including suggestions from Mark Gemmell
 > Documentation:   HELP RCLIB, HELP RC_CONTROL_PANEL
 > Related Files:	LIB rc_control_panel, rc_panelcontents
 */


section;
compile_mode
            :pop11 +varsch +defpdr -defcon -lprops -constr +global
            :vm +prmfix
            :popc -wrdflt -wrclos;

uses rclib
uses rc_informant
uses rc_control_panel

global vars panel_field_warning = false;

define :method rc_panel_field_value(panel:rc_panel, labels) -> val;
	;;; use list labels to find a path through the panel to a field,
	;;; or an item in a field, or a value of an item in a field
	;;; return the field, or item, or value, depending on the
	;;; contents of the list labels.
    lvars item = rc_panelcontents(panel, labels);
	rc_informant_value(item) -> val;
	if val == rc_undefined then
		mishap('Field item has no value',
			[%item, panel, labels%]);
	else
		;;; this case should ideally no longer arise
		if isident(val) then idval(val) -> val endif;
		val -> item;
		if panel_field_warning then
			['WARNING VALUE IS IDENT' labels ^labels panel ^panel
			^newline ^popfilename ^poplinenum] ==>
		endif;
		return();
	endif;
	
enddefine;

define :method updaterof rc_panel_field_value(val, panel:rc_panel, labels);

	dlocal rc_current_window_object;

	unless panel == rc_current_window_object then
		panel -> rc_current_window_object;
	endunless;
	
	if null(labels) or listlength(labels) /== 2 then
		mishap('Inappropriate path for panel_field_value updater', [%labels%]);
	else

		lvars item = rc_panelcontents(panel, labels);

	
	    ;;; Veddebug(item);
		if front(back(labels)) == "all_items" then
			;;; item should be a list of all the components
			lvars component;
			for component in item do
				if isrc_radio_button(component) then
					val -> rc_button_value(component);
				elseif isrc_toggle_button(component) then
					unless val == rc_toggle_value(component) then
						switch_rc_toggle_value(component)
					endunless;
				else
					val -> rc_informant_value(component)
				endif;
			endfor;
			return();
		elseif isrc_toggle_button(item) then
			;;; Veddebug([toggle val ^val ^(rc_toggle_value(item))]);
			unless val == rc_toggle_value(item) then
				switch_rc_toggle_value(item)
			endunless;
		elseif isrc_radio_button(item) then
			val -> rc_button_value(item);
			
		elseif isrc_button(item) then
			;;; check that it makes sense to update. not if this mishaps
			rc_panelcontents(panel, labels) -> ;
			val -> rc_informant_value(item)

		elseif isrc_slider(item) then
			;;; this does not yet run the constraints
			;;; val -> rc_informant_value(item)
			val -> rc_slider_value(item)
		elseif isrc_constrained_pointer(item) then
			;;; it's a dial -- check that this works
			val -> rc_informant_value(item)
		else
			;;; various other cases
			val -> rc_informant_value(item)
		endif;
		;;; invoke side effects
		rc_information_changed(item);
	endif;

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep  9 2002
		Changed compile mode
--- 27 Aug 2002
	Added many more options
	replaced rc_informant_contents with rc_informant_value
--- Aaron Sloman, Aug 25 2002

 */
