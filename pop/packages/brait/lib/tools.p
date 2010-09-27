/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/brait/lib/tools.p
 > Purpose:         tool procedures for brait sim
 > Author:          Duncan K Fewkes, Aug 29 2000 (see revisions)
 > Documentation:
 > Related Files:
 */

/*
         CONTENTS - (Use <ENTER> gg to access required sections)

 define decomplex(number);
 define decide_colour(type);
 define create_window(v1, v2);
 define create_centred_window(v1, v2);
 define draw_graph(funct_list);
 define show_and_name_instance(word, obj, win);
 define killwindows();
*/

/*
PROCEDURE: decomplex (number)
INPUTS   : number is a number
OUTPUTS  : NONE
USED IN  : many procedures
CREATED  : 2 Feb 2000
PURPOSE  : To prevent the introduction of complex non-real) numbers into the
            simulator (they occur in certain sqrt calculations and give
            negative distances).

TESTS:

decomplex(-430.267_+:64.9622)==>;
decomplex(-430.267)==>;


*/


define decomplex(number);

    if iscomplex(number) then
        return(0);
    else
        return(number);
    endif;

enddefine;


/*
PROCEDURE: decide_colour (type)
INPUTS   : type is a list of the source_info
OUTPUTS  : returns a string representing the appropriate colour
USED IN  : vehicle and source creation procedures
CREATED  : 11 Mar 2000
PURPOSE  : to decide the colour to draw the object, depending on the stimulus
        it emits

TESTS:

*/

define decide_colour(type);

    lvars col;

    if type matches ['light' ==] or
            type matches [light ==] then
        'orange' -> col;
    elseif type matches ['smell' ==] or
            type matches [smell ==]then
        'brown' -> col;
    elseif type matches ['heat' ==] or
            type matches [heat ==] then
        'red' -> col;
    elseif type matches ['sound' ==] or
            type matches [sound ==] then
        'blue' -> col;
    elseif type matches ['proximity' ==] or
            type matches [proximity ==]then
        'purple' -> col;
    else
        'black' -> col;
    endif;

    return(col);

enddefine;

/*
PROCEDURE: create_window (v1, v2)
INPUTS   : v1, v2
  Where  :
    v1 is width
    v2 is height
OUTPUTS  : NONE
USED IN  : most experiments
CREATED  : 8 Mar 2000
PURPOSE  : to create the main graphical window with origin in bottom-left corner
    (also to destroy previous window to keep desktop tidy).

TESTS:

*/

;;; global variables added by AS 7 Oct 2000
global vars
	braitwindow_x = "right",
	braitwindow_y = "bottom";

define create_window(v1, v2);

    if isundef(brait_world) or not(rc_islive_window_object(brait_world)) then
    else
        rc_kill_window_object(brait_world);
        delete(brait_world,sim_all_windows) -> sim_all_windows;
    endif;

    rc_new_window_object(braitwindow_x, braitwindow_y, v1, v2, {0 %v2% 0.25 -0.25}, 'The World', newsim_picagent_window) -> brait_world;

    [^^sim_all_windows ^brait_world] -> sim_all_windows;

enddefine;

/*
PROCEDURE: create_centred_window (v1, v2)
INPUTS   : v1, v2
  Where  :
    v1 is width
    v2 is height
OUTPUTS  : NONE
USED IN  : some experiments
CREATED  : 8 Mar 2000
PURPOSE  : to create the main graphical window with origin in centre (also to
        destroy previous window to keep desktop tidy).

TESTS:

*/

define create_centred_window(v1, v2);

    if isundef(brait_world) or not(rc_islive_window_object(brait_world)) then
    else
        rc_kill_window_object(brait_world);
        delete(brait_world,sim_all_windows) -> sim_all_windows;
    endif;

    rc_new_window_object(braitwindow_x, braitwindow_y,
		v1, v2, {%v1/2% %v2/2% 0.3 -0.3}, 'The World', newsim_picagent_window) -> brait_world;

    [^^sim_all_windows ^brait_world] -> sim_all_windows;

enddefine;

/*
PROCEDURE: draw_graph (funct, config1, config2)
INPUTS   : funct, config1, config2
  Where  :
    funct is an activation function
    config1 is the first config value for the activation function
    config2 is the second config value for the activation function
OUTPUTS  : graph of the function to screen
USED IN  : testing activation functions (primarily the distribution curve)
CREATED  : 14 Mar 2000
PURPOSE  : testing activation functions (primarily the distribution curve)


TESTS:

draw_graph([[%straight% 0 50 1 0] [%normal_dist% 50 100 50 20] ] );


*/

define draw_graph(funct_list);

    lvars x,function;

    create_centred_window(200, 200);

    rc_drawline(0, -200, 0, 200);  ;;;y-axis
    rc_drawline(-200, 0, 200, 0);  ;;;x-axis

    for function in funct_list do
        for x from function(2) by 1 to function(3) do
            rc_draw_blob(x*2, (recursive_valof(function(1))(x, function(4), function(5))*2) , 2, 'red');
        endfor;
    endfor;

enddefine;

/*
PROCEDURE: show_and_name_instance (word, obj, brait_world)
INPUTS   : word, obj, brait_world
  Where  :
    word is a ???
    obj is a ???
    brait_world is a ???
OUTPUTS  : NONE
USED IN  : ???
CREATED  : 3 Jul 2000 - copied from Aaron Sloman's teach sim_feelings
PURPOSE  : add object to graphical window

TESTS:

*/



define show_and_name_instance(word, obj, win);
    ;;; Used when an object is first created, to draw it and make it
    ;;; mouse sensitive.

    ;;; An object has been created, with the word as its sim_name
    ;;; Declare its name as a variable, and make the object its valof

    ident_declare(word, 0, 0);
    obj -> valof(word);

    if islist(win) then
        rc_add_containers(obj, win);
    else
        rc_add_container(obj, win);
    endif;

enddefine;

/*
PROCEDURE: killwindows ()
INPUTS   : NONE
OUTPUTS  : NONE
USED IN  :
CREATED  : 25 Jul 2000
PURPOSE  : kill old windows

TESTS:

*/

define killwindows();
    ;;; Get rid of old windows if necessary.
    ;;; Assumes sim_all_windows is a list of names of windows
    ;;; or windows.

    lvars win_name, win;
    for win_name in sim_all_windows do
        recursive_valof(win_name) -> win;
        if isrc_window_object(win) then
            rc_kill_window_object(win);
            if isword(win_name) then
                false -> valof(win_name);
            endif;
        endif;
    endfor;
    [] -> sim_all_windows;
    false -> rc_current_window_object;

    if not(isundef(brait_world)) and rc_widget(brait_world) then
        rc_kill_window_object(brait_world);
    endif;

enddefine;


;;; for "uses"
global constant tools = true;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Oct  8 2000

	Removed sim_distance (already in LIB sim_picagent)
	Removed "largest". Use "max" instead.
	Removed "smallest". Use "min" instead.

	Introduced two new variables:
        braitwindow_x = "right",
        braitwindow_y = "bottom";

    These are now used by the procedures create_window
    and create_centred_window.

	Fixed header and introduced "define" index.

--- Duncan K Fewkes, Aug 30 2000
	converted to lib format
 */
