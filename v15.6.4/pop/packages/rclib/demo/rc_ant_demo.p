/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/demo/rc_ant_demo.p
 > Purpose:			Demonstrate LIB * RC_LINEPIC
 > Author:          Aaron Sloman, Jan 18 1997 (see revisions)
 > Documentation:	TEACH RC_LINEPIC
 > Related Files:	LIB RC_LINEPIC

Use
	ENTER g define
to see contents.
 */

/*
AN ANT WORLD DEMONSTRATION, BASED ORIGINALLY ON CODE BY CHRISTIAN PATERSON

This uses LIB * RC_LINEPIC, which defines an object class that can be
used with rc_graphic.

Create a window containing a square representing a room, with an ant
(depicted by a small cross) running about in it. A panel will appear that
allows you to add another ant, or to stop.

The panel uses facilities in LIB * PUITOOLS

Load this file with ENTER l1 then run this

	rc_ant_demo();

turn Garbage Collection on or off
	true -> popgctrace;		
	false -> popgctrace;		

;;; To find which procedures take most time use the next two commands
	uses profile
	profile rc_ant_demo();

To delete the ant window click on the STOP button, or do this:

    rc_kill_window_object(antwin);


To optimise methods do this. It can take some time:

	optimise_objectclass( "all" );

CONTENTS (define)

 define :class ant_thing;
 define :class ant_room;
 define -- Control buttons
 define :mixin ant_pic; is rc_selectable;
 define :class ant_stop_button;
 define :method ant_stop_button_up(pic:ant_stop_button, x, y, modifiers);
 define SHOW_ANTS(x, y);
 define :class ant_num_panel;
 define :class ant_count_button;
 define UPARROW();
 define DOWNARROW();
 define :method ant_inc_button_up(pic:ant_count_button, x, y, modifiers);
 define :method ant_dec_button_up(pic:ant_count_button, x, y, modifiers);
 define -- Ant methods
 define :method ant_step_by(a:ant_thing, dx, dy);
 define procedure ant_bounce_direction(dir, ant);
 define procedure wall_collisions(xpos, ypos, a);
 define procedure object_collision(xpos, ypos, ant, ants);
 define procedure ant_step_coords(a) -> (dx, dy);
 define procedure ant_move(ant,ants);
 define draw_room();
 define create_ant() -> ant;
 define run_ants(num);
 define rc_ant_demo(num);

*/

section;

uses objectclass;
uses rclib;
uses rc_linepic;
uses rc_mousepic

/*
-- GLOBAL VARIABLES
*/

global vars

	;;; Room bounds, Ant radius, and ant step size
	room_xmin = 0, room_ymin = -290, room_xmax = 320, room_ymax = 260,
	room_width = room_xmax - room_xmin,
	room_height = room_ymax - room_ymin,
	ant_radius = 4, ant_step_size = 5,

	
	;;; the window
	antwin,
	;;; location and size
	antwinX = 400, antwinY = 30, antwinW = 600, antwinH = 600,

	;;; the coordinate frame
	antwinFrame = {230 290 1 -1},

	the_num_panel,

	ant_list = [];	;;; list of ants

lvars
	finish = false,
	newant = 0;


vars procedure (rc_picx, rc_picy, ant_dir, ant_picture);


define :class ant_thing;
	is rc_linepic_movable;
	slot ant_dir;
	slot ant_step = ant_step_size;
	slot rc_pic_lines =
		;;; A cross. Choose a colour that stands out after
		;;; xor with background
		[WIDTH 2
			;;; COLOUR 'darkslategrey'
			COLOUR
				^(oneof(['red' 'blue' 'orange'  'green' 'brown' 'purple'
						'gray10' 'gray30' 'gray50']))
		[%conspair(-ant_radius,-ant_radius),
			conspair(ant_radius,ant_radius)%]
		[%conspair(-ant_radius,ant_radius),
			conspair(ant_radius,-ant_radius)%]]
	;
	slot ant_name = undef;
enddefine;

define :class ant_room;
	is rc_linepic;
	slot rc_picx = room_xmin;
	slot rc_picy = room_ymin;
	slot rc_pic_lines =
		[ ;;; a square
		[WIDTH ^room_height COLOUR 'white' ;;; 'ivory'
			{0 ^(room_height div 2)}{^room_width ^(room_height div 2)}]
		[WIDTH 3 RECT {0 ^room_height ^room_width ^room_height}]
		];
enddefine;


/*

define -- Control buttons

*/

define :mixin ant_pic; is rc_selectable;
	slot rc_button_up_handlers = { ^false ^false ^false};
	slot rc_button_down_handlers = { ^false ^false ^false};
	slot rc_drag_handlers = { ^false ^false ^false};
	slot rc_move_handler = false;
enddefine;

define :class ant_stop_button;
	is ant_pic rc_linepic;
	slot rc_mouse_limit = {-8 -15 100 15};
	slot rc_button_up_handlers = { ant_stop_button_up ^false ^false};
	slot rc_pic_lines =
		[
			;;; white background - overwrite printing when
			;;; re-drawn
			[WIDTH 30 COLOUR 'ivory' {0 0} {100 0}]
			;;; rectangular frame
			[WIDTH 3 COLOUR 'red' RECT {0 15 100 30 }]
		];
	slot rc_pic_strings = [COLOUR 'black' FONT '9x15bold' {3 -5 ' STOP '}];
enddefine;


define :method ant_stop_button_up(pic:ant_stop_button, x, y, modifiers);
	true -> finish;
enddefine;


define SHOW_ANTS(x, y);
	dlocal %rc_font(rc_window)% = '9x15bold';
	rc_print_at(x, y, length(ant_list) >< ' ants')
enddefine;

define :class ant_num_panel;
	is rc_linepic;
	slot rc_pic_lines =
		[
			;;; white background
			[WIDTH 30 COLOUR 'ivory' {0 0} {100 0}]
			;;; rectangular frame
			[WIDTH 3 COLOUR 'red' RECT {0 15 100 30 }]
			[COLOUR 'black' SHOW_ANTS {3 -5} ]
		];
	slot rc_pic_strings =
		[COLOUR 'black' FONT '9x15bold' {0 22 'More ants?'}];
enddefine;

define :class ant_count_button;
	is ant_pic rc_linepic;
	slot rc_mouse_limit = {-15 -15 15 15};
	slot rc_pic_lines =
		[   [COLOUR 'ivory' WIDTH 30 {-15 0}{15 0}]
			[COLOUR 'red' WIDTH 3 RECT {-15 15 30 30}]
			];
enddefine;

define UPARROW();
		rc_drawline(-5,-10,0,10);
		rc_drawline(0,10,5,-10);
enddefine;

define DOWNARROW();
		rc_drawline(-5,10,0,-10);
		rc_drawline(0,-10,5,10);
enddefine;

define :method ant_inc_button_up(pic:ant_count_button, x, y, modifiers);
	newant + 1 -> newant;
enddefine;

define :method ant_dec_button_up(pic:ant_count_button, x, y, modifiers);
	newant - 1 -> newant;
enddefine;

	
/*
define -- Ant methods

*/
define :method ant_step_by(a:ant_thing, dx, dy);
	rc_move_by(a, dx, dy, true)
enddefine;

define procedure ant_bounce_direction(dir, ant);
	;;; change direction of ant, depending on which dir it is
	;;; with a slight random jitter.
	;;; dir is a word, indicating orientation of obstacle relative to
	;;; which direction should change.
    lvars dir, ant,
		heading = ant_dir(ant);

	(if dir == "north" then
		360 fi_- heading
	elseif dir == "east" then
		180 fi_- heading
	elseif dir == "south" then
		360 fi_- heading
	elseif dir == "west" then
		180 fi_- heading
	else
		mishap('Unknown dir', [^dir])
	endif fi_+ 15 fi_- random(30)) fi_mod 360 -> ant_dir(ant);
enddefine;

define procedure wall_collisions(xpos, ypos, a);
	;;; check whether ant a at the locatin xpos, ypos has collided
	;;; with a wall
	lvars xpos, ypos,
		bounced = false,
		oldx = xpos,
		oldy = ypos;

    ;;; contact with wall 1
    if ypos fi_>= room_ymax then
        ant_bounce_direction("north", a);
        room_ymax fi_- 2 -> ypos;
		true -> bounced;
    ;;; contact with wall 3
    elseif ypos fi_<= room_ymin then
        ant_bounce_direction("south", a);
        room_ymin fi_+ 2 -> ypos;
		true -> bounced;
    endif;
    ;;; contact with wall 2
    if xpos fi_>= room_xmax then
        ant_bounce_direction("east", a);
        room_xmax fi_- 2 -> xpos;
		true -> bounced;
    ;;; contact with wall 4
    elseif xpos fi_<= room_xmin then
        ant_bounce_direction("west", a);
        room_xmin fi_+ 2 -> xpos;
		true -> bounced;
    endif ;
	if bounced then
		ant_step_by(a, xpos fi_- oldx, ypos fi_- oldy);
	endif;
enddefine;


define procedure object_collision(xpos, ypos, ant, ants);
    lvars ant, ants, other, xpos, ypos;
		lconstant dirs = [north south east west];
    for other in ants do
        unless other == ant then
			;;; see if it is close enough to change direction
            if abs(xpos fi_- rc_picx(other)) fi_< 15
            and abs(ypos fi_- rc_picy(other)) fi_< 15
            then
                ant_bounce_direction(oneof(dirs), ant);
				quitloop();	;;; ignore other collisions
            endif;
        endunless;
    endfor;
enddefine;


define procedure ant_step_coords(a) -> (dx, dy);
    lvars a, dx, dy;
    lvars step_size=ant_step(a),
		direction = ant_dir(a),
		;
    ;;; use step size and heading to calculate the x and y coordinate changes
	round(cos(direction)*step_size) ->dx;
    round(sin(direction)*step_size) ->dy;
enddefine;

define procedure ant_move(ant,ants);
    lvars dx, dy,x,y;
    ant_step_coords(ant)-> (dx,dy);
	;;; Move and draw the ant
	rc_move_by(ant,dx,dy,true);
	rc_picx(ant) -> x;
	rc_picy(ant) -> y;
    wall_collisions(x, y, ant);
    object_collision(x, y, ant, ants);
enddefine;


define draw_room();
    vars room =
      instance ant_room;
	  endinstance;
	rc_draw_linepic(room);
enddefine;

define create_ant() -> ant;
    lvars ant, name = gensym("a");

    ident_declare(name,0,false);

    newant_thing()-> ant;
	name -> ant_name(ant);

	;;; Add printable name. Try with and without this next line.
	;;; [{-3 -1 ^(name >< nullstring)}] -> rc_pic_strings(ant);

    room_xmin + random(room_xmax - room_xmin) -> rc_picx(ant);
    room_ymin + random(room_ymax - room_ymin) -> rc_picy(ant);
    random(359)->ant_dir(ant);
	rc_draw_linepic(ant);
enddefine;



define run_ants(num);
	dlocal
		;;; Make all drawing use this. Window must already exist;
		rc_clipping = false;

    draw_room();
	1 -> gensym("a");

    [%repeat num times create_ant() endrepeat%] -> ant_list;

	instance ant_num_panel;
		rc_picx = -180;
		rc_picy = 150;
	endinstance -> the_num_panel;

	lvars
		the_inc =
			instance ant_count_button
				rc_picx = -180 + 100 + 16;
				rc_picy = 150;
				rc_button_up_handlers
					= { ant_inc_button_up ^false ant_dec_button_up};
			endinstance,

		the_dec =
			instance ant_count_button
				rc_picx = -180 + 100 + 18 + 2 + 30;
				rc_picy = 150;
				rc_button_up_handlers
					= { ant_dec_button_up ^false ant_inc_button_up};
			endinstance,

		the_stop =
			instance ant_stop_button;
				rc_picx = -180;
				rc_picy = 100;
			endinstance;

	rc_pic_lines(the_inc) <> [[COLOUR 'blue' WIDTH 4 [UPARROW {}]]]
			-> rc_pic_lines(the_inc);
	rc_pic_lines(the_dec) <> [[COLOUR 'blue' WIDTH 4 [DOWNARROW {}]]]
			-> rc_pic_lines(the_dec);

		rc_draw_linepic(the_num_panel);
		rc_draw_linepic(the_inc);
		rc_draw_linepic(the_dec);
		rc_draw_linepic(the_stop);
		rc_add_pic_to_window(the_inc, antwin, true);
		rc_add_pic_to_window(the_dec, antwin, true);
		rc_add_pic_to_window(the_stop, antwin, true);


	dlocal finish, newant;
    ;;; animate ants until finish = true
    false -> finish;
	0 -> newant;
    until finish do
		lvars ant;
        fast_for ant in ant_list do
			quitif(finish);
            ant_move(ant, ant_list);
			if newant /== 0 then ;;; "new ant" button pressed
				rc_undraw_linepic(front(ant_list));
				while newant fi_< 0 do
					if ant_list /== [] then
						;;; reduce the number of ants by 1
						back(ant_list) -> ant_list;
						rc_undraw_linepic(front(ant_list));
						newant fi_+ 1 -> newant
					else
						;;; Make sure there's at least one ant
						max(1, newant) -> newant;
						quitloop();
					endif;
				endwhile;
				while newant fi_> 0 do
	        		create_ant()::ant_list -> ant_list;
					newant fi_- 1 -> newant
				endwhile;
				rc_draw_linepic(the_num_panel);
				0 -> newant;
			endif;
        endfor;
    enduntil;
enddefine;


define rc_ant_demo(num);
    cleargensymproperty();

	rc_new_window_object(
		antwinX, antwinY, antwinW, antwinH, antwinFrame, 'antwin')
			-> antwin;
	'LightSkyBlue' -> rc_background(rc_window);

	rc_mousepic(antwin, [button]);

	{^false ^false ^false} ->> rc_button_up_handlers(antwin);
		->> rc_button_down_handlers(antwin)
		-> rc_drag_handlers(antwin);
	false ->> rc_move_handler(antwin) ->rc_keypress_handler(antwin);

	lvars oldinterrupt = interrupt;
	define dlocal interrupt;
		[] -> ant_list;
		true -> finish;
    	;;; rc_kill_window_object(antwin);
		exitfrom(run_ants);
	 	oldinterrupt();
	enddefine;

	run_ants(num);
	clearstack();

    if antwin then
		rc_kill_window_object(antwin)
	endif;
enddefine;


pr('\nType\n\trc_ant_demo(40);\n');

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jun 18 2000
	To reflect the fact that machines are now much faster, increased the
	panel size, and doubled the default number of ants
 */
