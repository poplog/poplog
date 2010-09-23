/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/brait/lib/mousehandlers.p
 > Purpose:         define mouse actions for sim_multiwin_mobile objects
	button 1 = grab and move object(whilst held down, move mouse)
	- for ball objects, this updates their spped and heading so that
	they can be 'thrown' by dragging and then letting go of the button.
	-other buttons - no actions
	-box objects cannot be dragged or moved.
 > Author:          Duncan K Fewkes, July 24 2000 (see revisions)
 > Documentation:
 > Related Files:
 */

/*
         CONTENTS - (Use <ENTER> g to access required sections)


 -- MOUSE EVENT CONTROLLERS
 -- BUTTON 1 - DRAG OBJECTS
 -- BUTTON 2
 -- BUTTON 3
 -- IGNORE WALL OBJECTS


CONTENTS. Use ENTER gg to access
 define :method rc_button_1_down(pic:sim_object, x, y, modifiers);
 define :method rc_button_1_down(pic:sim_picagent_window, x, y, modifiers);
 define :method rc_button_1_drag(pic:sim_picagent_window, x, y, modifiers);
 define :method rc_button_1_drag(pic:vehicle, x, y, modifiers);
 define :method rc_button_1_drag(pic:source, x, y, modifiers);
 define :method rc_button_1_drag(pic:ball_object, x, y, modifiers);
 define :method rc_button_1_up(pic:vehicle, x, y, modifiers);
 define :method rc_button_1_up(pic:ball_object, x, y, modifiers);
 define :method rc_button_1_up(pic:source, x, y, modifiers);
 define :method rc_button_1_up(pic:sim_picagent_window, x, y, modifiers);
 define :method rc_button_2_down(pic:sim_object, x, y, modifiers);
 define :method rc_button_2_down(pic:sim_picagent_window, x, y, modifiers);
 define :method rc_button_2_up(pic:sim_object, x, y, modifiers);
 define :method rc_button_2_up(pic:sim_object, x, y, modifiers);
 define :method rc_button_2_drag(pic:sim_object, x, y, modifiers);
 define :method rc_button_2_drag(pic:sim_picagent_window, x, y, modifiers);
 define :method rc_button_3_down(pic:sim_object, x, y, modifiers);
 define :method rc_button_3_down(pic:sim_picagent_window, x, y, modifiers);
 define :method rc_button_3_up(pic:sim_object, x, y, modifiers);
 define :method rc_button_3_up(pic:sim_picagent_window, x, y, modifiers);
 define :method rc_button_3_drag(pic:sim_picagent_window, x, y, modifiers);
 define :method rc_button_1_down(pic:box, x, y, modifiers);
 define :method rc_button_1_up(pic:box, x, y, modifiers);
 define :method rc_button_1_drag(pic:box, x, y, modifiers);
 define :method rc_button_2_down(pic:box, x, y, modifiers);
 define :method rc_button_2_up(pic:box, x, y, modifiers);
 define :method rc_button_2_drag(pic:box, x, y, modifiers);

*/

/*
-- MOUSE EVENT CONTROLLERS --------------------------------------------

-- BUTTON 1 - DRAG OBJECTS --------------------------------------------
*/

define :method rc_button_1_down(pic:sim_object, x, y, modifiers);

    pic -> rc_mouse_selected(brait_world);
    ;;; Make sure it is now on "top" of all the others.
    rc_set_front(pic);

;;;[button 1 down on ^pic]==>;

enddefine;



define :method rc_button_1_down(pic:sim_picagent_window, x, y, modifiers);
    false ->rc_mouse_selected(brait_world);
enddefine;


define :method rc_button_1_drag(pic:sim_picagent_window, x, y, modifiers);

    lvars current_selected = rc_mouse_selected(brait_world);


    if current_selected then
        ;;; An object was already selected keep dragging that one
        rc_set_front(current_selected);
        if isball_object(current_selected) then
            (sqrt((x - sim_x(current_selected)+0.001)**2 + (y-sim_y(current_selected)+0.001)**2))
            /(time_slice_duration*2) -> speed(current_selected);
            arctan((y - sim_y(current_selected)+0.001)/(x-sim_x(current_selected)+0.001))
                -> heading(current_selected);
            if sim_x(current_selected) > x then
                heading(current_selected) + 180 -> heading(current_selected);
            endif;
        endif;

        sim_move_to(current_selected, x, y, true);
    else
        false ->rc_mouse_selected(brait_world);
    endif;

        ;;;[button 1 drag in window ^pic]==>;
        ;;;current_selected==>;
enddefine;


define :method rc_button_1_drag(pic:vehicle, x, y, modifiers);

    lvars current_selected = rc_mouse_selected(brait_world);

    if current_selected then
        ;;; An object was already selected keep dragging that one
        rc_set_front(current_selected);
        sim_move_to(current_selected, x, y, true);
    else
        ;;; choose this object as the selected one
        rc_set_front(pic);
        pic -> rc_mouse_selected(brait_world);
        sim_move_to(pic, x, y, true);
    endif;

        ;;;[button 1 drag ^pic ^x ^y  modifiers ^modifiers] =>

enddefine;

define :method rc_button_1_drag(pic:source, x, y, modifiers);

    lvars current_selected = rc_mouse_selected(brait_world);

    if current_selected then
        ;;; An object was already selected keep dragging that one
        rc_set_front(current_selected);
        sim_move_to(current_selected, x, y, true);
    else
        ;;; choose this object as the selected one
        rc_set_front(pic);
        pic -> rc_mouse_selected(brait_world);
        sim_move_to(pic, x, y, true);
    endif;

        ;;;[button 1 drag ^pic ^x ^y  modifiers ^modifiers] =>

enddefine;

define :method rc_button_1_drag(pic:ball_object, x, y, modifiers);

    lvars current_selected = rc_mouse_selected(brait_world);

    if current_selected then
        ;;; An object was already selected keep dragging that one
        rc_set_front(current_selected);
            (sqrt((x - sim_x(current_selected)+0.001)**2 + (y-sim_y(current_selected)+0.001)**2))
            /(time_slice_duration*2) -> speed(current_selected);
            arctan((y - sim_y(current_selected)+0.001)/(x-sim_x(current_selected)+0.001))
                -> heading(current_selected);
            if sim_x(current_selected) > x then
                heading(current_selected) + 180 -> heading(current_selected);
            endif;

        sim_move_to(current_selected, x, y, true);
    else
        ;;; choose this object as the selected one
        rc_set_front(pic);
        pic -> rc_mouse_selected(brait_world);
            (sqrt((x - sim_x(pic)+0.001)**2 + (y-sim_y(pic)+0.001)**2))
            /(time_slice_duration*2) -> speed(pic);
            arctan((y - sim_y(pic)+0.001)/(x-sim_x(pic)+0.001))
                -> heading(pic);
            if sim_x(pic) > x then
                heading(pic) + 180 -> heading(pic);
            endif;

        sim_move_to(pic, x, y, true);
    endif;

        ;;;[button 1 drag ^pic ^x ^y  modifiers ^modifiers] =>

enddefine;

define :method rc_button_1_up(pic:vehicle, x, y, modifiers);

    ;;;[button 1 up on ^pic]==>;
    false -> rc_mouse_selected(brait_world);

enddefine;

define :method rc_button_1_up(pic:ball_object, x, y, modifiers);

    ;;;[button 1 up on ^pic]==>;
    false -> rc_mouse_selected(brait_world);

enddefine;

define :method rc_button_1_up(pic:source, x, y, modifiers);

    ;;;[button 1 up on ^pic]==>;
    false -> rc_mouse_selected(brait_world);

enddefine;

define :method rc_button_1_up(pic:sim_picagent_window, x, y, modifiers);

    false ->rc_mouse_selected(brait_world);

    ;;;[button 1 up in ^pic]==>;

enddefine;

/*
-- BUTTON 2 -----------------------------------------------------------
*/

define :method rc_button_2_down(pic:sim_object, x, y, modifiers);
enddefine;

define :method rc_button_2_down(pic:sim_picagent_window, x, y, modifiers);
    ;;;[button 2 down ^x ^y ^pic] =>
enddefine;


define :method rc_button_2_up(pic:sim_object, x, y, modifiers);
    ;;;[button 2 up in ^pic]=>
enddefine;

define :method rc_button_2_up(pic:sim_object, x, y, modifiers);
enddefine;


define :method rc_button_2_drag(pic:sim_object, x, y, modifiers);
enddefine;

define :method rc_button_2_drag(pic:sim_picagent_window, x, y, modifiers);
      ;;;[button 2 drag nothing ^x ^y modifiers ^modifiers] =>
enddefine;

/*
-- BUTTON 3 -----------------------------------------------------------
*/
;;; uncomment the print commands for testing

define :method rc_button_3_down(pic:sim_object, x, y, modifiers);
enddefine;


define :method rc_button_3_down(pic:sim_picagent_window, x, y, modifiers);
    ;;;[button 3 down ^x ^y ^modifiers] =>
enddefine;


define :method rc_button_3_up(pic:sim_object, x, y, modifiers);
     ;;;[button 3 up ^x ^y ^pic] =>
enddefine;

define :method rc_button_3_up(pic:sim_picagent_window, x, y, modifiers);
     ;;;[button 3 up ^x ^y ^pic] =>
enddefine;

define :method rc_button_3_drag(pic:sim_picagent_window, x, y, modifiers);
     ;;;[button 3 drag nothing ^x ^y modifiers ^modifiers] =>
enddefine;

/*
-- IGNORE WALL OBJECTS ------------------------------------------------
*/

define :method rc_button_1_down(pic:box, x, y, modifiers);
enddefine;

define :method rc_button_1_up(pic:box, x, y, modifiers);
enddefine;

define :method rc_button_1_drag(pic:box, x, y, modifiers);
enddefine;

define :method rc_button_2_down(pic:box, x, y, modifiers);
enddefine;

define :method rc_button_2_up(pic:box, x, y, modifiers);
enddefine;

define :method rc_button_2_drag(pic:box, x, y, modifiers);
enddefine;

;;; for "uses"
global constant mousehandlers = true;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Oct  8 2000

	Fixed header.
	Added "define" index

--- Duncan K Fewkes, Sep 25 2000
Altered old sim_object methods. Was for sim_multiwin_mobile - was causing
crashes (?) when mouse went into control panel window.

Also made vehicle, source and ball specific methods to make mouse actions more
consistent
--- Duncan K Fewkes, Aug 30 2000
converted to lib format
 */
