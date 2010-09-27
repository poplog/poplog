/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:			$poplocal/local/rclib/auto/rc_set_panel_entity.p
 > Purpose:			Given a an item, a list of labels and a panel go down the panel
					hierarchy using the labels. Use the item to set the appropriate
					panel entity.
 > Author:			Aaron Sloman, Aug 10 2002 (see revisions)
 > Documentation:   HELP RCLIB, HELP RC_CONTROL_PANEL
 > Related Files:	
 */


section;
compile_mode
            :pop11 +varsch +defpdr -defcon -lprops -constr +global
            :vm +prmfix
            :popc -wrdflt -wrclos;

uses rclib
uses rc_control_panel


define :method rc_set_panel_entity(val, panel:rc_panel, labels);
	;;; Use the labels to trace a path through the panel to a field
	;;; or an item in a field. Then use val to set that field or
	;;; item.

	;;; make sure the panel is rc_ current_window object

	dlocal rc_current_window_object;	
	
	unless panel == rc_current_window_object then
		panel -> rc_current_window_object;
	endunless;

	if null(labels) then
		mishap('EMPTY LIST OF LABELS', [%val,[], panel%])
	else
		lvars
			(label, rest) = dest(labels),
			field = rc_field_of_label(panel, label),
			contents = rc_field_contents(field);

		if rest == [] then
			;;; use val to set the field. It should be a Radio or Someof
			;;; field.
			if isrc_radio_field(field) then
				rc_set_radio_buttons(val, contents)
			elseif isrc_someof_field(field) then
				rc_set_someof_buttons(val, contents)
			else
				mishap('CANNOT SET ITEM VALUE', [%field, val, labels, panel%])
			endif;
		else
			dest(rest) -> (label, rest);
			if rest == [] then
				;;; end of path

				if islist(contents) then
					lvars object =
						rc_informant_with_label(label, contents);

						;;; set the value depending on the type
					if isrc_someof_button(object) then
						if val == "none" then
							rc_set_someof_buttons(val, contents)
						elseif isboolean(val) then
							val -> rc_button_value(object)
						else
							mishap('Boolean value needed for updating',
										[%val, object,  labels, panel%]);
						endif;
					elseif isrc_radio_button(object) then
						;;; includes someof buttons
						unless isboolean(val) then
							mishap('Boolean value needed for updating',
										[%val, object,  labels, panel%]);
						endunless;							
						val -> rc_button_value(object)
					elseif isrc_display_button(object) then
						;;; includes toggle and counter buttons
						val -> rc_button_value(object)
					elseif isrc_informant(object) then
						val -> rc_informant_value(object)
					else
						mishap('Wrong field contents for setting',
							[%object, label, panel %]);
					endif;
				 elseif isrc_informant(contents)
					and rc_informant_label(contents) = label then
					val -> rc_informant_value(contents)
				else
					mishap('NOTHING IN PANEL MATCHES PANEL PATH', [%panel, labels%])
				endif
			else
				mishap('UNEXPECTED LABEL IN PANEL PATH', [%hd(rest), labels%])
			endif;
		endif
	endif;
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep  9 2002
		Changed compile mode
--- Aaron Sloman, Aug 25 2002
		replaced rc_informant*_contents with rc_informant_value
 */
