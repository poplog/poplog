/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/lib/rc_sprite.p
 > Purpose:         Demonstration of rclib facilities with mobile objects
 > Author:          Aaron Sloman, Dec 18 2000 (see revisions)
 > Documentation:	TEACH rc_sprite
 > Related Files:
 */

/*

;;; TESTS, after ENTER l1

;;; create a window
vars win1 =rc_new_window_object("right", "top", 400, 400, true, 'WIN1');

rc_start();

;;; draft format for creating a sprite
;;; rc_make_sprite(x, y, base, height, axis, colour, name) -> sprite;

;;; create one called s1.
vars s1 = rc_make_sprite(100, 100, 40, 60, -90, 'blue', 's1');

vars s2 = rc_make_sprite(10, 10, 30, 30, 0, 'red', false);



;;; rc_move_sprite(s, steplen, turnang, delay, num, trail);
rc_move_sprite(s2, 2, 5, 1, 100, true);
rc_move_sprite(s2, 5, -3, 1, 100, false);
rc_move_sprite(s1, 5, -3, 1, 100, true);
rc_move_sprite(s1, 4, 2, 1, 100, true);

rc_move_to(s1, 0, 0,true);
rc_set_axis(s1, 0, true);

;;; rc_move_sprite_on_path(s, path, delay,  trail);
rc_move_sprite_on_path(s1,
	[{1 1 20}{2 -2 20}{3 3 20}{4 -4 20}{5 5 20}],
	5,  false);

rc_move_sprite_on_path(s1,
	[{1 1 20}{2 -2 20}{3 3 20}{4 -4 20}{5 5 20}],
	5,  true);

rc_move_sprite_on_path(s2,
	[{1 1 40}{2 -2 40}{3 3 50}{4 -4 80}{5 5 180}],
	1,  true);

rc_move_to(s2, 0, 0,true);
rc_set_axis(s2, 0, true);

*/


section;

uses rclib
uses rc_window_object
uses rc_draw_filled_triangle


global vars rc_draw_sprite_trail = false;


;;; Define the main class. Instances will be movable, rotatable,
;;; selectable and will be depicted as triangles.
define :class rc_sprite;
	is rc_rotatable_picsonly rc_selectable;

	;;; define a sensitive square of side 30 x 30
	slot rc_mouse_limit = {-15 -15 15 15};

	slot rc_pic_lines = "rc_sprite_pic"; 	;;; defined below

	slot rc_sprite_base;
	slot rc_sprite_height;
	slot rc_sprite_colour;

enddefine;



/*
METHOD   : rc_sprite_pic (sprite)
INPUTS   : sprite is an instance of the rc_sprite class
OUTPUTS  : NONE
USED IN  : class rc_sprite, as the drawing method
CREATED  : 19 Dec 2000
PURPOSE  : Draw an instance of rc_sprite

TESTS:

*/

define :method rc_sprite_pic(sprite:rc_sprite);

	lvars
		halfbase = rc_sprite_base(sprite) * 0.5,
		halfheight = rc_sprite_height(sprite) * 0.5,
		colour = rc_sprite_colour(sprite);

	;;; draw a triangle, and possibly draw the trail blob
    rc_draw_filled_triangle(
		-halfheight, -halfbase, -halfheight, halfbase, halfheight, 0, colour);

	;;; if drawing the trail then
	if rc_draw_sprite_trail then
		;;; make sure the trail is drawn, as a small blob.
    	rc_draw_blob(0, 0, 1, rc_sprite_colour(sprite));
	endif;
enddefine;


/*
PROCEDURE: rc_make_sprite (x, y, base, height, axis, colour, name) -> sprite
INPUTS   : x, y, base, height, axis, colour, name
  Where  :
    x is a number, x coordinate
    y is the y coordinate
    base is a number, the size of base of triangle
    height is a number the length of main axis of triangle.
    axis is an integer, the initial orientation
    colour is a string: colour of the filled triangle
    name is false, or a string to be drawn
OUTPUTS  : sprite is an instance of rc_sprite
USED IN  : rc_make sprite and others. See TEACH RC_SPRITE
CREATED  : 19 Dec 2000
PURPOSE  : Demonstrate rclib.

TESTS:
 See the teach file.

*/

define rc_make_sprite(x, y, base, height, axis, colour, name) -> sprite;

	;;; create the sprite
	newrc_sprite() -> sprite;

	base -> rc_sprite_base(sprite);
	height -> rc_sprite_height(sprite);
	colour -> rc_sprite_colour(sprite);


	;;; if no name required, turn off strings.
	if name then
		[FONT '8x13' {^(0.5*height) -5 ^name}];
	else
		[]
	endif -> rc_pic_strings(sprite);

	(x,y) -> rc_coords(sprite);

	rc_draw_linepic(sprite);
	rc_set_axis(sprite, axis, true);

	rc_add_pic_to_window(sprite, rc_current_window_object, true);

enddefine;


define :method rc_undraw_linepic(s:rc_sprite);
	;;; make sure that when undrawing a sprite, the trail is false
 	dlocal rc_draw_sprite_trail = false;
	call_next_method(s);
enddefine;


define :method rc_set_axis(s:rc_sprite, ang, draw);
	;;; make sure that when turning a sprite, the trail is false
 	dlocal rc_draw_sprite_trail = false;
	call_next_method(s, ang, draw);
enddefine;



/*
METHOD   : rc_move_sprite (s, steplen, turnang, delay, num, trail)
INPUTS   : s, steplen, turnang, delay, num, trail
  Where  :
    s is a sprite (instance of rc_sprite)
    steplen is a number, the length of step to move.
    turnang is a number, the angle to turn in degrees
    delay is an integer, the amount to delay between moves
    num is a total number of steps to draw
    trail is a boolean. If true leave a trail.
OUTPUTS  : NONE
USED IN  : next procedure
CREATED  : 19 Dec 2000
PURPOSE  : Demonstration of RCLIB

TESTS:

*/

define :method rc_move_sprite(s:rc_sprite, steplen, turnang, delay, num, trail);

    ;;; draw the sprite, and if trail is true show a trail.
	dlocal rc_draw_sprite_trail = trail;

	repeat num times
		lvars
			heading = rc_axis(s),
			dx = steplen*cos(heading),
			dy = steplen*sin(heading),;

		rc_move_by(s, dx,dy, true);

		rc_turn_by(s, turnang, true);

		;;; sleep to slow the thing down
		syssleep(delay);
	endrepeat;

enddefine;



/*
METHOD   : rc_move_sprite_on_path (s, path, delay, trail)
INPUTS   : s, path, delay, trail
  Where  :
    s is a sprite
    path is a list of three element lists or vectors, each giving a steplen,
		a turnang, and a number of steps
    delay is an integer, the amount to delay between steps.
    trail is a boolean. leave a trail of true
OUTPUTS  : NONE
USED IN  : TEACH rc_sprite
CREATED  : 19 Dec 2000
PURPOSE  : Demonstration

TESTS:

See the teach file

*/

define :method rc_move_sprite_on_path(s:rc_sprite, path, delay,  trail);

	lvars
		item,
		steplen, turnang, delay, num;

	;;; repeatedly do the portions of the path
	for item in path do
		explode(item) -> (steplen, turnang, num);
		rc_move_sprite(s, steplen, turnang, delay, num, trail)
	endfor;
	
enddefine;


endsection;



/*

         CONTENTS - (Use <ENTER> gg to access required sections)

 define :class rc_sprite;
 define :method rc_sprite_pic(sprite:rc_sprite);
 define rc_make_sprite(x, y, base, height, axis, colour, name) -> sprite;
 define :method rc_undraw_linepic(s:rc_sprite);
 define :method rc_set_axis(s:rc_sprite, ang, draw);
 define :method rc_move_sprite(s:rc_sprite, steplen, turnang, delay, num, trail);
 define :method rc_move_sprite_on_path(s:rc_sprite, path, delay,  trail);

*/

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Dec 19 2000
	Simplified the drawing of the trail
 */
