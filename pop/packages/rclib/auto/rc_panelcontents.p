/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:			$poplocal/local/rclib/auto/rc_panelcontents.p
 > Purpose:			Given a list of labels and a panel go down the panel
					hierarchy using the labels. Return result.
 > Author:			Aaron Sloman, Aug 10 2002 (see revisions)
					including suggestions from Mark Gemmell
 > Documentation:   HELP RCLIB, HELP RC_CONTROL_PANEL
 > Related Files:	LIB rclib, LIB rc_control_panel, LIB rc_panel_field_value
			
 */


section;
compile_mode
            :pop11 +varsch +defpdr -defcon -lprops -constr +global
            :vm +prmfix
            :popc -wrdflt -wrclos;

uses rclib
uses rc_informant
uses rc_control_panel


define :method rc_panelcontents(panel:rc_panel, labels) -> item;
	;;; use list labels to find a path through the panel to a field,
	;;; or an item in a field, or a value of an item in a field
	;;; return the field, or item, or value, depending on the
	;;; contents of the list labels.

	;;; should it consolidate first?
	rc_consolidate_all_input(panel);

	if null(labels) then
		panel -> item
	elseif hd(labels) == "all_fields" then
		rc_panel_fields(panel) -> item;
	else
		lvars
			(label, rest) = dest(labels),
			field = rc_field_of_label(panel, label);

		if rest == [] then
			field -> item
		else
			dest(rest) -> (label, rest);
			lvars contents = rc_field_contents(field);

			if islist(contents) then
				if label == "all_items" and rest == [] then
					contents -> item
				elseif label == "all_values" and rest == [] then
					maplist(contents, rc_informant_value) -> item
				elseif label == "all_labels" and rest == [] then
					maplist(contents, rc_informant_label) -> item
				elseif label == "all_true" and rest == [] then
					maplist(contents,
						procedure(i);
							if rc_informant_value(i) == true then
								i
							endif
						endprocedure) -> item
				elseif label == "all_false" and rest == [] then
					maplist(contents,
						procedure(i);
							unless rc_informant_value(i) then
								i
							endunless;
						endprocedure) -> item
				elseif label == "labels_true" and rest == [] then
					maplist(contents,
						procedure(i);
							if rc_informant_value(i) then
								rc_informant_label(i)
							endif
						endprocedure) -> item
				elseif label == "labels_false" and rest == [] then
					maplist(contents,
						procedure(i);
							unless rc_informant_value(i) then
								rc_informant_label(i)
							endunless
						endprocedure) -> item
				else
					 rc_informant_with_label(label, contents) -> item;
					if rest == [] then
						;;; end of path
						return();
					elseif rest = [val] then
					;;; to be removed. use rc_panel_field_value
						lvars val;
						rc_informant_value(item) -> val;
						if val == rc_undefined then
							mishap('Field item has no value',
									[%item, panel, labels%]);
						else
							if isident(val) then idval(val) -> val endif;
							val -> item;
							return();
						endif;
					else
						mishap('UNEXPECTED LABEL IN PANEL PATH', [%hd(rest), labels%])
					endif
				endif;
			elseif isrc_linepic(contents)
			and rc_informant_label(contents) = label then
				if rest = [val] then
					rc_informant_value(contents) -> item
				else
					contents -> item
				endif;
			else
				mishap('NOTHING IN PANEL MATCHES PANEL PATH', [%panel, labels%])
			endif
		endif;
	endif
	
enddefine;

define :method updaterof rc_panelcontents(val, panel:rc_panel, labels);
	;;; Should the updater be withdrawn?
	dlocal rc_current_window_object;

	unless panel == rc_current_window_object then
		panel -> rc_current_window_object;
	endunless;
	
	if null(labels) or listlength(labels) /== 3 and last(labels) /== "val" then
		mishap('Inappropriate path for panelcontents updater', [%labels%]);
	else
		lvars item = rc_panelcontents(panel, allbutlast(1, labels));
	    ;;; Veddebug(item);
		if isrc_toggle_button(item) then
		;;; Veddebug([toggle val ^val ^(rc_toggle_value(item))]);
			unless val == rc_toggle_value(item) then
				switch_rc_toggle_value(item)
			endunless;
		elseif isrc_someof_button(item) then
			val -> rc_button_value(item);
	
		elseif isrc_radio_button(item) then
			;;; check that it makes sens to update. not if this mishaps
			rc_panelcontents(panel, labels) -> ;
			val -> rc_informant_value(item)

		elseif isrc_constrained_pointer(item) then
			;;; it's a dial
			val -> rc_pointer_value(item);
		else
			;;; check that it makes sens to update. not if this mishaps
			rc_panelcontents(panel, labels) -> ;
			val -> rc_informant_value(item)

		endif;
	endif;

	 enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep  9 2002
		Changed compile mode
--- Aaron Sloman, Aug 27 2002
		Extended to included all_true all_false labels_true labels_false
--- Aaron Sloman, Aug 26 2002
		Added all_items, all_values, all_labels
--- Aaron Sloman, Aug 26 2002
		Removed the the use of "val" as pseudo label. Introduced
		method rc_panelcontents_value instead
	replaced rc_informant_contents with rc_informant_value
--- Aaron Sloman, Aug 25 2002

 */
