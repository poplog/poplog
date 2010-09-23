/*
TEACH RC_LINEPIC.DEMO.P                         Aaron Sloman,  4 Apr 1997

Executable code demonstrating much of what can be done using
	LIB RC_WINDOW_OBJECT LIB RC_LINEPIC,
	LIB RC_MOUSEPIC and LIB RC_BUTTONS
*/

uses rc_linepic;

/*

CONTENTS

 -- Introduction
 -- Ensure required libraries are compiled
 -- Stuff with windows
 -- Define a class of draggable objects
 -- Motion
 -- Dragging
 -- Move object to another window
 -- object selection
 -- Buttons and menus
 -- A class of static objects
 -- A class of movable objects
 -- Make some instances
 -- Simplify the printing
 -- Try drawing and moving the objects
 -- Making moving pictures
 -- using RECT and SQUARE
 -- Rotatable objects
 -- Detecting keyboard events: rc_handle_keypress
 -- More on rotation
 -- Allowing squares or rectangles to rotate
 -- -- Part of a rotatable object may be offset by an angle
 -- Giving a class of objects a non-standard line-thickness

-- Introduction -------------------------------------------------------

This loadable file includes some example Pop-11 code and suggestions
for trying things out.

*/

/*
-- Ensure required libraries are compiled -----------------------------
*/

uses objectclass
uses rc_graphic
uses rclib
uses rc_font
uses rc_foreground
uses rc_linepic
uses rc_window_object
uses rc_mousepic
uses rc_buttons
/*

-- Stuff with windows

*/


    vars win1 = rc_new_window_object(400, 40, 500, 400, true);
    win1 =>

    rc_window_title(win1) =>
    'win1' -> rc_window_title(win1);
    win1 =>
    rc_window_location(win1) =>
    400, 400, false, false -> rc_window_location(win1);
    win1 =>
    false, false, 450, 350 -> rc_window_location(win1);
    10, 40, false, false -> rc_window_location(win1);
    win1 =>
    rc_hide_window(win1);
    500, 40, false, false -> rc_window_location(win1);
    rc_show_window(win1);   ;;; may change the location
    win1 =>
    rc_drawline(0, 0, 150, 150);
    rc_raise_window(win1);
    rc_drawline(0, 0, 150, 200);
    rc_kill_window_object(win1);
/*

-- Define a class of draggable objects --------------------------------

Use the mixins provided by rc_mousepic and rc_linepic to make a class of
objects that can be dragged.

*/
    vars win1, win2;
    rc_new_window_object(200, 40, 300, 250, true) -> win1;
    rc_new_window_object(510, 40, 300, 250, true) -> win2;
    'win1' -> rc_window_title(win1);
    'win2' -> rc_window_title(win2);

uses rc_mousepic;

define :class dragpic;
    is rc_keysensitive rc_selectable rc_linepic_movable;
    slot pic_name = gensym("drag");
enddefine;

;;; define a printing method to simplify printing

define :method print_instance(p:dragpic);
    printf('<pic %P %P %P>', [%pic_name(p), rc_coords(p) %])
enddefine;

define :instance drag1:dragpic;
    pic_name = "drag1";
    rc_picx = 100;
    rc_picy = 50;
    rc_pic_lines =
        [WIDTH 2 COLOUR 'black'
            [SQUARE {-25 25 50}]
            [CLOSED {-30 20} {30 20} {30 -20} {-30 -20}]
        ];
    rc_pic_strings =
    [[FONT '9x15bold' COLOUR 'red' {-22 -5 'drag1'}]];
enddefine;

    win1 -> rc_current_window_object;
    rc_draw_linepic(drag1);

define :instance drag2:dragpic;
    pic_name = "drag2";
    rc_picx = 100;
    rc_picy = -50;
    rc_pic_lines =
        [WIDTH 2     COLOUR 'blue'
            [CLOSED {-30 20}  {30 20} {30 -20}  {-30 -20}]
            [CIRCLE {0 15 10}]
            [SQUARE {-10 -15 20}]
        ];
    rc_pic_strings =
        [[FONT '8x13bold' COLOUR 'brown' {-20 -10 'drag2'}]];
enddefine;

    win2 -> rc_current_window_object;
    rc_draw_linepic(drag2);
/*

-- Motion

*/

	rc_start();
	rc_undraw_all([^drag1 ^drag2]);
	rc_draw_linepic(drag1);
	rc_draw_linepic(drag2);

    win1 -> rc_current_window_object;
    rc_move_to(drag1, 60, -75, true); ;;; true means show the motion

    win2 -> rc_current_window_object;
    rc_move_to(drag2, 110, 30, true);

    win1 -> rc_current_window_object;
    repeat 10 times rc_move_by(drag1, -4, 4, true) endrepeat;
    repeat 10 times rc_move_by(drag1, -4, 4, "trail") endrepeat;
    repeat 10 times rc_move_by(drag1, 5, -5, true) endrepeat;
    repeat 10 times rc_move_by(drag1, -5, 5, "trail") endrepeat;
    repeat 10 times rc_move_by(drag1, 5, -5, "trail") endrepeat;
    win2 -> rc_current_window_object;
    repeat 10 times rc_move_by(drag2, 0, 3, true) endrepeat;
    repeat 10 times rc_move_by(drag2, 0, -3, "trail") endrepeat;
    repeat 10 times rc_move_by(drag2, -4, 0, true) endrepeat;
    repeat 10 times rc_move_by(drag2, -4, 0, "trail") endrepeat;
    repeat 10 times rc_move_by(drag2, 4, 0, true) endrepeat;
    repeat 10 times rc_move_by(drag2, 3, 0, "trail") endrepeat;

/*
-- Dragging

*/
    rc_mousepic(win1);
    rc_mousepic(win2);

    rc_add_pic_to_window(drag1, win1, true);
    rc_add_pic_to_window(drag2, win2, true);

    rc_window_contents(win1) ==>
    rc_window_contents(win2) ==>

    rc_mouse_limit(drag1) =>
    rc_mouse_limit(drag2) =>


define :instance drag3:dragpic;
    pic_name = "drag3";
    rc_picx = 120;
    rc_picy = 60;
    rc_pic_lines =
    [WIDTH 3    COLOUR 'black'
        [CLOSED {-30 20}  {30 20} {30 -20}  {-30 -20}]
        [CIRCLE {0 15 10}]
        [WIDTH 2 SQUARE {-10 -10 15}]
        ;;; give rc_draw_blob four sets of inputs, to draw
        ;;; a circular blob at each order
        [rc_draw_blob {-35 25 20 'red'} {35 25 20 'red'}
            {35 -25 20 'blue'} {-35 -25 20 'blue'}]
    ];
    rc_pic_strings =
        [[FONT '8x13bold' COLOUR 'blue' {-20 -10 'drag3'}]];
enddefine;

    win2 -> rc_current_window_object;
	rc_mousepic(win2);
    rc_draw_linepic(drag3);
    rc_create_mouse_limit(drag3);

    rc_add_pic_to_window(drag3, win2, true);

/*
-- Move object to another window
*/

    rc_add_pic_to_window(drag3, win1, true);
    win1 -> rc_current_window_object;
    rc_draw_linepic(drag3);
;;; dragging now will mess things up

    rc_remove_pic_from_window(drag3, win2);
    rc_redraw_window_object(win2);
    rc_redraw_window_object(win1);
    rc_window_contents(win1) =>
    rc_window_contents(win2) =>

/*
-- object selection
*/

    win1 -> rc_current_window_object;
    rc_move_to(drag1, 0, 60, true);
    rc_move_to(drag3, -30, -60, true);

    rc_pictures_selected(win1, 0, 55, false) =>
    rc_pictures_selected(win1, 100, 55, false) =>
    rc_pictures_selected(win1, -35, -55, false) =>

;;; But if they are moved closer together ...

    rc_move_to(drag1, 30, 60, true);
    rc_move_to(drag3, 25, 55, true);

    rc_pictures_selected(win1, 25, 55, false) =>
    rc_pictures_selected(win1, 15, 55, false) =>
    rc_pictures_selected(win1, 40, 75, false) =>

    rc_kill_window_object(win1);
    rc_kill_window_object(win2);
/*
-- Buttons and menus
*/

See HELP RC_BUTTONS for examples


/*
-- A class of static objects ------------------------------------------
*/

define :class rc_static;
    is rc_linepic;
    slot pic_name = gensym("static");
    slot rc_pic_lines =
          [
          ;;; Use "WIDTH" to specify line thickness
          ;;; One sub-picture forming a closed four-point polygon
            [WIDTH 3 CLOSED {-18 18}  {18 18} {18 -18}  {-18 -18}]
        ];
enddefine;

/*
-- A class of movable objects -----------------------------------------
*/

define :class rc_mover;
    is rc_linepic_movable;  ;;; Note: not rc_keysensitive rc_selectable

    slot pic_name = gensym("mover");
    slot rc_pic_lines =
          [ WIDTH 2 [{-20 20}  {20 -20} ] [{-20 -20}  {20 20}]];
enddefine;

/*
-- Make some instances ------------------------------------------------

*/

define :instance stat1:rc_static;
        rc_picx = 100;
        rc_picy = 50;
        rc_pic_strings = [{-15 -5 'stat1'}];
enddefine;

define :instance move1:rc_mover;
    ;;; This will inherit the default picture
    rc_picx = 0;
    rc_picy = 0;
    ;;; But add some  strings
    rc_pic_strings = [{0 20 'a'}{20 0 'b'}{0 -20 'c'} {-20 0 'd'}];
enddefine;

define :instance move2:rc_mover;
    ;;; Override the default rc_mover picture.
    ;;; Include a circle of linewidth 2 and colour blue
    ;;; and a bigger one of linewith 3 and colour red
    rc_picx = 0;
    rc_picy = -150;
    rc_pic_lines = [
        ;;; red circle at 0,0 radius 20
        [WIDTH 3 COLOUR 'red' CIRCLE {0 0 20} ]
        ;;; blue circle at 0,20 radius 15
        [WIDTH 2 COLOUR 'blue' CIRCLE {0 20 15}]
    ];
    rc_pic_strings =
        [[FONT '6x13bold' {-16 -5 'move2'}]];
enddefine;



;;; Print out the instances

stat1 =>
move1 =>
move2 =>

/*

-- Simplify the printing ----------------------------------------------

*/

define :method print_instance(p:rc_linepic);
    printf('<pic %P %P %P>', [%pic_name(p), rc_coords(p) %])
enddefine;

stat1 =>
move1 =>
move2 =>

;;;You can still get full information by printing thus:
datalist(move2) ==>

/*

-- Try drawing and moving the objects ---------------------------------

*/

vars win1 = rc_new_window_object(400, 40, 500, 400, true);
rc_draw_linepic(stat1);
rc_draw_linepic(move1);
rc_draw_linepic(move2);

;;; Try moving move1, first using absolute, then relative coordinates
rc_move_to(move1, 30, 50, true);
rc_move_by(move1, -5, -5, true);
;;; Put it back in the original location
rc_move_to(move1, 0, 0, true);

    rc_move_to(move1, 30, 50, true);

    rc_move_by(move1, -5, -5, true);    ;;; repeat a few times


/*
-- Making moving pictures ---------------------------------------------
*/

define test_moves(pic, drawmode);
    ;;; Drawmode can be true, false, or "trail" --  given as
    ;;; the third argument to rc_move_by

    ;;; repeatedly move and draw pic
    repeat 15 times
        ;;; move up right
        rc_move_by(pic, 5, 5, drawmode);
    endrepeat;
    repeat 15 times
        ;;; move right
        rc_move_by(pic,5,0, drawmode);
    endrepeat;
    repeat 10 times
        ;;; move down
        rc_move_by(pic,0,-5,drawmode);
    endrepeat;
    repeat 10 times
        ;;; move down left
        rc_move_by(pic,-5,-5, drawmode);
    endrepeat;
    repeat 20 times
        ;;; move left
        rc_move_by(pic,-5,0,drawmode);
    endrepeat;

enddefine;


;;; Start again with a clear screen
rc_start();

;;; Inform the pictures that they are now undrawn.
rc_undraw_all([^move1 ^move2]);

rc_draw_linepic(move1);
rc_draw_linepic(move2);

;;; Now try moving move1 and move2 around without leaving a trail:

test_moves(move2, true);
test_moves(move1, true);

;;; Now try moving move1 and move2 around in "trail" mode
rc_start();
rc_undraw_all([^move1 ^move2]);

rc_draw_linepic(move1);
rc_draw_linepic(move2);

repeat 4 times test_moves(move1, "trail"); endrepeat;
repeat 4 times test_moves(move2, "trail"); endrepeat;


/*
-- using RECT and SQUARE ----------------------------------------------
*/


define :instance rects:rc_mover;
    pic_name = "rects";
    rc_picx = 0;
    rc_picy = 0;
    rc_pic_lines =
        [   ;;; A rectangle centre -25, 25, width 60 height 40
            [RECT {-25 25 60 40}]
            ;;; two squares
            [SQUARE {-20 20 15} {5 -5 40}]
            ;;; A line
            [WIDTH 3 COLOUR 'green'
            {-15 -10} {15 -10}]
        ];
    rc_pic_strings = [[FONT '9x15bold' {5 5 'rects'}]]
enddefine;

rects =>
rc_start();
;;; draw it

rc_draw_linepic(rects);
;;; This is an instance of rc_mover, and can be moved

repeat 60 times rc_move_by(rects, -2, -2, true) endrepeat;

;;; For examples using oblongs see TEACH RC_LINEPIC



/*
-- Rotatable objects --------------------------------------------------
*/

;;; A class, based on the rc_rotatable mixin
define :class rc_rotator; is rc_rotatable;
    slot rc_axis = 0;
    slot pic_name = "rot0";
enddefine;


;;; Make an object in that class consisting of a line with a circle near
;;; one end.
define :instance rp1:rc_rotator;
    pic_name = "rp1";
    rc_picx = 50;
    rc_picy = 100;
    rc_pic_lines =
        [WIDTH 2
            [{5 5} {30 30}][COLOUR 'pink' CIRCLE {25 25 5}]];
enddefine;

rp1 =>

;;; A rotatable arrow shape
define :instance rp2:rc_rotator;
    pic_name = "rp2";
    rc_picx = 100;
    rc_picy = 50;
    ;;; Make an arrow with a blue head
    rc_pic_lines
        = [WIDTH 3 [{0 0} {30 0}][COLOUR 'blue' {25 8}{30 0}{25 -8}]];
enddefine;

rp2 =>

;;; Make a new printing procedure for the class, showing the axis

define :method print_instance(p:rc_rotator);
    printf('<pic %P %P %P axis:%P>',
        [%pic_name(p), rc_coords(p), rc_axis(p) %])
enddefine;

rp1 =>
rp2=>


rc_start();
;;; draw them
rc_draw_linepic(rp1);
rc_draw_linepic(rp2);

;;; Rotatable objects can be moved
rc_move_by(rp1, -10, -10, true);
rc_move_by(rp2, 0, 10, true);

;;; And rotated

0 -> rc_axis(rp1); rc_draw_linepic(rp1);
30 -> rc_axis(rp1); rc_draw_linepic(rp1);
-45 -> rc_axis(rp1); rc_draw_linepic(rp1);
45 -> rc_axis(rp1); rc_draw_linepic(rp1);
-90 -> rc_axis(rp1); rc_draw_linepic(rp1);
-135 -> rc_axis(rp1); rc_draw_linepic(rp1);

;;; Or using rc_set_axis to cause automatic drawing
rc_set_axis(rp1, 90, true);
rc_set_axis(rp1, 135, true);

vars x;
for x from 0 by 10 to 360 do rc_set_axis(rp1, x, true) endfor;

;;; Rotating can also be done in "trail" mode
vars x;
for x from 0 by 10 to 360 do rc_set_axis(rp1, x, "trail") endfor;

;;; Then do it again
for x from 0 by 10 to 360 do rc_set_axis(rp1, x, "trail") endfor;

;;; Or by using rc_turn_by to do relative rotation
rc_turn_by(rp1, 10, true);rc_move_by(rp1, 5,5,true);

rc_move_to(rp2,150,150,true);
repeat 36 times
    rc_turn_by(rp2, 10, true);rc_move_by(rp2,-5,-5,true);
    ;;; use syssleep to slow it down
    syssleep(10);       ;;; sleep for 10/100 of a second
endrepeat;

;;; Bring it back to the original location
repeat 36 times
    rc_turn_by(rp2, 10, true);rc_move_by(rp2,5,5,true);
    syssleep(10);
endrepeat;

;;; Rotating with a trail

;;; Prepare rp1 for a demonstration
rc_move_to(rp1,50,150,true); rc_set_axis(rp1,0,true);

;;; Mark these two loops and then do them both repeatedly.

repeat 36 times
    rc_turn_by(rp1, 10, true);rc_move_by(rp1, -5, -5, "trail");
endrepeat;

repeat 36 times
    rc_turn_by(rp1, 10, true);rc_move_by(rp1, 5, 5, "trail");
endrepeat;

;;; Try that with different initial angles,e.g.
rc_start();
rc_undrawn(rp1);
rc_set_axis(rp1,90,true);   ;;; then try the above loops
rc_set_axis(rp1,180,true);  ;;; ditto

/*
-- Detecting keyboard events: rc_handle_keypress ----------------------
*/

rc_mousepic(win1);

define :method rc_handle_keypress(w:rc_window_object, x, y, modifier, key);
    ;;; select Ved's output file for printing, but prevent the
    ;;; file being writeable
    vededit('output.p', vedhelpdefaults);
    vedendfile();

    ;;; Make printing go into the output buffer
    dlocal cucharout = vedcharinsert;

    [
        %if key >= 0 then 'Key pressed at'
         else 'key released at'
         endif% ^x ^y : key ^key modifier: ^modifier] ==>
enddefine;

define :method rc_handle_keypress(w:rc_window_object, x, y, modifier, key);
enddefine;

/*
-- More on rotation
*/


define :instance rp3:rc_rotator;
    pic_name = "rp3";
    rc_picx = 0;
    rc_picy = 0;
    ;;; Make an arrow
    rc_pic_lines = [[{0 0} {30 0}][{25 8}{30 0}{25 -8}]];
    ;;; And a string
    rc_pic_strings = [{0 -20 'arrow'}]
enddefine;

    rc_start();


    rc_move_to(rp3, 0, 50, true);


repeat 18 times    rc_turn_by(rp3, 20, true);syssleep(2) endrepeat;


define :instance rp4:rc_rotator;
    pic_name = "rp4";
    rc_picx = 0;
    rc_picy = 0;
    ;;; Make an arrow
    rc_pic_lines = [[{0 0} {30 0}][{25 8}{30 0}{25 -8}]];
    ;;; And a string
    rc_pic_strings =
        [[FONT '6x13bold'
            {0 -20 'a'} {7 -20 'r'} {14 -20 'r'} {21 -20 'o'}
        {28 -20 'w'}]];
    ;;; For the 6x13 font, I incremented the x coordinate in steps of 7.
enddefine;

    rc_start();


    rc_move_to(rp4, 0, -20, true);


    repeat 18 times rc_turn_by(rp4, 30, true); syssleep(2) endrepeat;
/*
-- Allowing squares or rectangles to rotate
*/

define :instance rp5:rc_rotator;
    pic_name = "rp5";
    rc_picx = 0;
    rc_picy = 0;
    rc_pic_lines =
        [
            ;;; A rectangle of thickness 2, non-rotatable
            [WIDTH 2 RECT {-25 25 50 45}]
            ;;; A rectangle of thickness 4, rotatable
            [WIDTH 4 RRECT {-35 35 75 65}]
            ;;; A line of current default thickness
            [{-15 -10} {15 -10}]
        ];
enddefine;

    rc_start();


    rc_draw_linepic(rp5);

    rc_move_to(rp5, -75, -75, true);
    rc_move_by(rp5, 30, 30, true);


    rc_turn_by(rp5, -30, true);
    repeat 12 times rc_turn_by(rp5, 30, true) endrepeat;



define :instance rp6:rc_rotator;
    pic_name = "rp6";
    rc_picx = 0;
    rc_picy = 0;
    rc_pic_lines =
        [ ;;; an ordinary closed polygon
            [CLOSED {-10 15} {10 10} {10 -10}{-10 -15}]
            ;;; A non rotatable square
            [WIDTH 2 SQUARE {-20 20 40}]
            ;;; A rotatable square
            [WIDTH 4 RSQUARE {-30 30 60}]
        ];
enddefine;

    rc_start();

    rc_draw_linepic(rp6);
    rc_move_to(rp6, -75, -75, true);
    rc_move_by(rp6, 20, 30, true);
    rc_move_to(rp6, 30, 40, true);

    rc_turn_by(rp6, 60, true);
    repeat 12 times rc_turn_by(rp6, -30, true) endrepeat;


/*
-- -- Part of a rotatable object may be offset by an angle
*/


define :instance rp7:rc_rotator;
    pic_name = "rp7";
    rc_picx = 0;
    rc_picy = 60;
    rc_pic_lines =
        [
            ;;; an ordinary closed polygon
            [CLOSED {-10 15} {10 10} {10 -10}{-10 -15}]
            ;;; A non rotatable square
            [WIDTH 2 SQUARE {-20 20 40}]
            ;;; A rotatable square
            [ANGLE 30 WIDTH 4 RSQUARE {-30 30 60}]
        ];
enddefine;

    rc_start();
    rc_draw_linepic(rp7);
    rc_move_to(rp7, -80, 30, true);
    rc_move_by(rp7, 20, 40, true);


    rc_turn_by(rp7, 60, true);
    repeat 36 times rc_turn_by(rp7, -10, true) endrepeat;

/*
-- Giving a class of objects a non-standard line-thickness ------------
*/
define :mixin rc_thick;
    slot rc_thickness = 0;
enddefine;

;;; These methods all need to be redefined
define :method rc_draw_linepic(p:rc_thick);
    dlocal rc_linewidth = rc_thickness(p);
	call_next_method(p)
enddefine;

define :method rc_undraw_linepic(p:rc_thick);
    dlocal rc_linewidth = rc_thickness(p);
	call_next_method(p)
enddefine;


define :method rc_move_to(pic:rc_thick, newx, newy, draw);
    dlocal rc_linewidth = rc_thickness(pic);
    call_next_method(pic, newx, newy, draw)
enddefine;

define :method rc_move_by(pic:rc_thick, dx, dy, draw);
    dlocal rc_linewidth = rc_thickness(pic);
    call_next_method(pic, dx, dy, draw)
enddefine;

define :method rc_set_axis(pic:rc_thick, ang, draw);
    dlocal rc_linewidth = rc_thickness(pic);
    call_next_method(pic, ang, draw)
enddefine;

define :method rc_turn_by(pic:rc_thick, ang, draw);
    dlocal rc_linewidth = rc_thickness(pic);
    call_next_method(pic, ang, draw)
enddefine;

;;; Now define a class that inherits from rc_thick and rc_rotator.
define :class rc_thickpic; is rc_thick rc_rotator;
    ;;; no new slots needed
enddefine;

;;;  Create an instance made of a triangle and a circle

define :instance thick2:rc_thickpic;
    pic_name = "thick2";
    rc_picx = 50;
    rc_picy = 50;
    rc_thickness = 3;
    rc_pic_lines = [[CLOSED {-20 -10}{0 15}{20 -10}][CIRCLE {0 10 10}]]
enddefine;

    thick2 =>

    rc_start();
    rc_move_to(thick2, 100, 100, true);

    repeat 10 times rc_move_by(thick2, -5, -5, true); endrepeat;

    repeat 36 times rc_turn_by(thick2, 10, true); endrepeat;

    repeat 36 times
        rc_turn_by(thick2, 10, true);
        rc_move_by(thick2, -3, 3, true)
    endrepeat;


    rc_draw_linepic(thick2);

/*
rc_kill_window_object(win1);
*/

--- $poplocal/local/rclib/teach/rc_linepic.demo.p
--- Copyright University of Birmingham 1997. All rights reserved. ------
