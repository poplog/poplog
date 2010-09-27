/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/rclib/lib/rc_informant.p
 > Purpose:			A mixin for selectable information holders
 > 						e.g. buttons sliders, etc
 > Author:          Aaron Sloman, Jul  8 1997 (see revisions)
 > Documentation:	HELP * RCLIB
 > Related Files:	Various files concerned with active picture objects
 */


uses rclib
uses rc_window_object

section;

compile_mode
            :pop11 +varsch +defpdr -defcon -lprops -constr +global
            :vm +prmfix
            :popc -wrdflt -wrclos;


;;; This is defined in LIB RC_CONTROL_PANEL, which
;;; cannot be compiled before this file.
global vars procedure rc_control_panel;

global constant rc_undefined = consundef("rc_informant");

define :mixin vars rc_informant;
	slot RC_informant_value == rc_undefined;
	slot rc_informant_reactor == "rc_informant_reactor_def";
	slot rc_informant_ident == false;	;;; possible identifier
	slot rc_constrain_contents == identfn;	;;; possible constrainer
	slot rc_informant_window == false;	;;; possible window_object
enddefine;


define global procedure rc_informant_label = newproperty([], 32, false, "tmparg")
	;;; Associates a label with an item. This could be a slot for rc_informant
enddefine;

define isword_or_ident(item) -> boole;
	isword(item) or isident(item) -> boole;
enddefine;

define :method vars rc_informant_value(obj:rc_informant) -> val;
	RC_informant_value(obj) -> val
enddefine;


global
	vars
		rc_constrainer_depth = 0,
		rc_reactor_depth = 0,
	;

define :method updaterof rc_informant_value(val, obj:rc_informant);

	lvars
		old_win = rc_current_window_object,
		this_win = rc_informant_window(obj);

	unless not(this_win) or old_win == this_win then
		this_win -> rc_current_window_object
	endunless;

	if rc_constrainer_depth > 0 or iscaller(rc_control_panel) then
		;;; don't run constraint
	else
		lvars
			oldval = RC_informant_value(obj),
			newval = recursive_valof(rc_constrain_contents(obj))(val);

		if newval = undef then oldval else newval endif -> val;

	endif ;

	dlocal rc_constrainer_depth = rc_constrainer_depth + 1;

	val -> RC_informant_value(obj);

	;;; now set identifier if appropriate
	lvars wid = rc_informant_ident(obj);
	if isword_or_ident(wid) then
		val -> valof(wid)
	endif;

	;;; restore window if necessary
	unless old_win == rc_current_window_object then
		old_win -> rc_current_window_object
	endunless;
enddefine;

define vars procedure rc_update_fields(val, list);
	;;; redefined in rc_control_panel
enddefine;

define :method rc_information_changed(obj:rc_informant);
	;;; Call this method with an object whose information content
	;;; has changed. It will get the appropriate method from the
	;;; object and apply it to the object and its contents.

	dlocal rc_reactor_depth;

	returnif(rc_reactor_depth > 0);

	rc_reactor_depth + 1 -> rc_reactor_depth;

	lvars
		old_win = rc_current_window_object,
		this_win = rc_informant_window(obj);

	unless not(this_win) or old_win == this_win then
		this_win -> rc_current_window_object
	endunless;

	lvars
		reactor = recursive_valof(rc_informant_reactor(obj)),
		val = rc_informant_value(obj);

	define lconstant do_reactor(win, depth);
		;;; prevent unwanted mouse pointer warping
		dlocal
			rc_reactor_depth = depth,
			rc_current_window_object,
			vedwarpcontext = false;
			win -> rc_current_window_object;

		returnif(rc_reactor_depth > 1);

		if islist(reactor) then
			;;; This version is defined in rc_control_panel
			
			rc_update_fields(val, reactor)
		else
			;;; it should be a procedure
			reactor(obj, val);
		endif;
	enddefine;	

	do_reactor(rc_current_window_object, rc_reactor_depth);

	;;; restore window if necessary
	unless old_win == rc_current_window_object then
		old_win -> rc_current_window_object
	endunless;
enddefine;

define :method rc_informant_reactor_def(obj:rc_informant, val);
	;;; The default method for reacting to changed contents.
	;;; Can be, and often will be redefined for particular subclasses
	;;; or even replaced in the rc_informant_reactor slot of an
	;;; individual instance.

	;;; Uncomment for testing
	;;; ['New contents for' ^obj : ^val] =>
enddefine;

define :method rc_informant_init(obj:rc_informant);
	;;; initialise informant with value of the corresponding identifier
	lvars
		id = rc_informant_ident(obj),
	;
	if id and not(isundef(valof(id))) then
		valof(id) -> rc_informant_value(obj),
	endif;

enddefine;

define rc_informant_with_label(label, list) -> item;
    ;;; Check that label, usually a string or word, is one of the labels
    ;;; of the items in the list. But treat buttons specially
    ;;; Return the item with the label or false.

    lvars item;

	;;; two things that may not be compiled till after this
	lvars
		nobuttons = true,
		procedure (isbutton, buttonlabel);

   	if identprops("isrc_button") then
		;;; lib rc_buttons loaded
		valof("isrc_button") -> isbutton;
		valof("rc_button_label") -> buttonlabel;
		false -> nobuttons;
	endif;
	
    for item in list do
        if label = rc_informant_label(item)
		or (isbutton(item) and label = buttonlabel(item)) then
			;;; found it
            return()
        endif
    endfor;
    false -> item;
enddefine;

syssynonym("rc_informant_contents", "rc_informant_value");
syssynonym("RC_informant_contents", "RC_informant_value");

;;; for uses
global vars rc_informant = true;
endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep  6 2002
		Removed unnecessary calls of vedinput and external_defer_apply
--- Aaron Sloman, Aug 25 2002
		replaced rc_informant*_contents with rc_informant_value
		Kept the former as a synonym for now.
--- Aaron Sloman, Aug 23 2002
	Moved isword_or_ident(item)  from rc_control_panel

--- Aaron Sloman, Aug 13 2002
	added rc_undefined = consundef("rc_informant");

--- Aaron Sloman, Aug 10 2002
	Generalised rc_informant_with_label(label, list) -> item;
	to treat button labels as equivalent to informant labels
		
--- Aaron Sloman, Aug  2 2002
	Added
		rc_informant_label = newproperty([], 32, false, "tmparg")
		rc_informant_with_label(label, list) -> item;
		
--- Aaron Sloman, Mar 19 2001
	Fixed method rc_information_changed to behave properly in
	xved, including preventing unwanted cursor warping when reactors
	run.
	Required saving rc_current_window_object
--- Aaron Sloman, Oct 10 1999
	Added rc_informant_window, and extra actions to ensure right window is
	current when updaters run
--- Aaron Sloman, Apr 17 1999
	Altered rc_information_changed to cope with the case where
	rc_informant_reactor contents is a list of vectors.
--- Aaron Sloman, Apr  3 1999
	prevented constraints being run inside rc_control_panel
--- Aaron Sloman, Apr  2 1999
	Changed to use old value of constraint returns undef
--- Aaron Sloman, Apr  2 1999
	added rc_informant_init, to allow value of identifier to be used.
--- Aaron Sloman, Mar 30 1999
	Introduced rc_reactor_depth to control chain reactions.
--- Aaron Sloman, Mar 28 1999
	Changed various things to ensure that rc_*informant_value will be
	updated when things changed, and can be used to update other things.
	Separated constrainer from reactor
--- Aaron Sloman, Nov 16 1997
	Added rc_informant_ident

CONTENTS

 define :mixin vars rc_informant;
 define global procedure rc_informant_label = newproperty([], 32, false, "tmparg")
 define isword_or_ident(item) -> boole;
 define :method vars rc_informant_value(obj:rc_informant) -> val;
 define :method updaterof rc_informant_value(val, obj:rc_informant);
 define vars procedure rc_update_fields(val, list);
 define :method rc_information_changed(obj:rc_informant);
 define :method rc_informant_reactor_def(obj:rc_informant, val);
 define :method rc_informant_init(obj:rc_informant);
 define rc_informant_with_label(label, list) -> item;

 */
