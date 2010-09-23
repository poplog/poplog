/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/demo/painting_demo.p
 > Purpose:         Demonstrate RCLIB stuff
 > Author:          Aaron Sloman, Jan  8 1997 (see revisions)
 > Documentation:
 > Related Files:
 */

/*
NB. This is just a "toy" demonstration of concept, showing how the RCLIB tools
can be used to create graphical interface for a toy painting tool, with a row of
brushes on top and a column of pain pots on the left.

LOAD THIS FILE

Then do

	painting_go();

or something of form :start_easel(screenx,screeny,width,height);

e.g.
	start_easel(650,20,450,430);

(It may adjust your width and height accommodate the brush rack at the top
and the paint pots on the left)

Then select a colour (default black) and select desired brushes.

As you drag a brush it does nothing unless you depress SHIFT, in
which case it draws a trail. Release mouse button to return brush
to brush holder, using magical invisible elastic.

To temporarily hide it, press the DISMISS button. Then to bring it back do

	rc_show_window(the_easel);

To get rid of the window do

     rc_kill_window_object(the_easel);

To restart with a fresh window, press the RESTART button.

Note: there's a table of contents at the end of the file.
*/

/*
define -- Prerequisites
*/

uses objectclass
uses rc_graphic
uses rclib
uses rc_linepic
uses rc_window_object
uses rc_mousepic
;;; uses rc_buttons ;;; not yet needed

/*
define -- Global variables
*/


global vars
	the_easel,			;;; created by start_easel, defined at the end of this file
	colour_bars = [],	;;; also created by start_easel

	;;; Some default values
	brush_width = 20,
	brush_height = 20,
	button_width = 70,
	button_height = 18,

	pot_radius = 12,
	current_colour = 'black',
	current_brush = false,
	left_margin = 40,
	top_margin = -50,
	;;; the next two are set up by start_easel
	easel_width, easel_height,

	;;; Assume key 65505 = Shift
	rc_shift_code = 65505,

	;;; describe brushes in terms of how they are drawn
	brushes =
	[
		;;; horizontal line
		[WIDTH 2 {-3 0} {3 0}]
		;;; up to right
		[WIDTH 2 {-3 -3} {3 3}]
    	;;; vertical
		[WIDTH 2 {0 -3} {0 3}]
		;;; down to right
		[WIDTH 2 {-3 3} {3 -3}]
		;;; bigger versions
		[WIDTH 4 {-8 0} {8 0}]
		[WIDTH 4 {-8 -8} {8 8}]
		[WIDTH 4 {0 -8} {0 8}]
		[WIDTH 4 {-8 8} {8 -8}]
		;;; two squares
		[WIDTH 10 {0 -5} {0 5}]
		[WIDTH 18 {0 -9} {0 9}]
		;;; brushes made of three or four blobs
		[blob_brush{-4 0 1} {0 0 1} {4 0 1}]
		[blob_brush{0 -4 1} {0 0 1} {0 4 1}]
		[blob_brush{-4 -4 1} {0 0 1} {4 4 1}]
		[blob_brush{-4 4 1} {0 0 1} {4 -4 1}]
		[blob_brush{-4 0 1} {0 4 1} {4 0 1} {0 -4 1}]
		[blob_brush{-5 0 2} {0 5 2} {5 0 2} {0 -5 2}]
		[blob_brush{-7 0 2} {0 7 2} {7 0 2} {0 -7 2}]
		[blob_brush{0 0 1}]
		[blob_brush{0 0 4}]
		[blob_brush{ 0 0 8}]
		[blob_brush{ 0 0 10}]
	],
	;;; Paint colours
	pots =
	[ 'red' 'orange' 'yellow' 'green' 'blue' 'lavender' 'violet'
		'SeaGreen' 'brown' 'gold' 'pink'
		'grey' 'white' 'black' ]
;

/*
define -- Mixin and classes
*/

define :mixin rc_easel;
    is rc_selectable rc_linepic_movable;
	slot rc_button_up_handlers =
		{ ^false ^false ^false};
	slot rc_button_down_handlers =
		{^false ^false ^false};
	slot rc_drag_handlers =
		{^false ^false ^false };
	slot rc_move_handler = false;
	slot rc_keypress_handler = "easel_keypress_handler";
enddefine;

define :class paintbrush;
	is rc_easel;
    ;;; default name dragpic1, dragpic2, etc.
    slot pic_name = gensym("brush");
	slot start_locx;
	slot start_locy;
	slot rc_mouse_limit
		= {%-brush_width div 2, -brush_height div 2, brush_width div 2, brush_height div 2%};
	slot rc_button_up_handlers =
		{ easel_button_1_up ^false ^false};
	slot rc_button_down_handlers =
		{ easel_button_1_down ^false ^false};
	slot rc_drag_handlers =
		{easel_button_1_drag ^false ^false };
enddefine;

define :class paintpot;
	is rc_easel;
    slot pic_name = gensym("pot");
	slot pic_colour;
    slot rc_pic_lines ==
		[WIDTH 2 [SQUARE {%-pot_radius, pot_radius, pot_radius * 2%}]
		 [blob_brush{0 0 ^(pot_radius -2)}]];
	slot rc_button_up_handlers =
		{ easel_button_1_up ^false ^false};
	slot rc_button_down_handlers =
		{ easel_button_1_down ^false ^false};
	slot rc_drag_handlers =
		{easel_button_1_drag ^false ^false };
enddefine;

define :class colourbar;
	is rc_linepic;
    slot rc_pic_strings=[FONT '9x15bold' {5 -15 'THE COLOUR'}];
enddefine;

define :class window_control;
	is rc_easel;
    slot rc_pic_lines ==
		[[WIDTH 2 RECT
			{%-button_width div 2, button_height div 2,
				button_width, button_height%}]
		];
	slot rc_window_action = identfn;
	slot rc_mouse_limit =
			{%-button_width div 2, -button_height div 2,
				button_width div 2, button_height div 2%};
	slot rc_button_up_handlers =
		{ easel_button_1_up ^false ^false};
	slot rc_button_down_handlers =
		{ easel_button_1_down ^false ^false};
enddefine;

define :method rc_draw_linepic(bar:colourbar);
	;;; draw the bar with the current colour
	dlocal %rc_foreground(rc_window)% = current_colour;

	call_next_method(bar)

enddefine;


/*
define -- Utilities for methods
*/

define brush_in_easel(x, y) -> bool;
	(x >= left_margin + (brush_width div 2))
				and (y <= top_margin - (brush_height div 2)) -> bool
enddefine;


define start_coords(pic) /*-> (x,y) */;
	start_locx(pic), start_locy(pic) /* -> (x, y) */
enddefine;

define coords_in_easel(x, y) /*-> (x,y) */;
	max(x, left_margin + (brush_width div 2)),
	min(y, top_margin - (brush_height div 2)) /* ->(x, y) */
enddefine;

define blob_brush(x, y, rad);
	;;; Use current colour to draw a blob
	rc_draw_blob(x, y,rad, current_colour);
enddefine;


/*
define -- Printing methods
*/

define :method print_instance(pic:paintbrush);
	printf('<brush %P %P %P>', [%rc_coords(pic), rc_pic_lines(pic)%])
enddefine;

define :method print_instance(pot:paintpot);
	printf('<pot %P>', [%pic_colour(pot)%]);
enddefine;

/*
define -- Keyboard action methods
*/

define :method easel_keypress_handler(pic:paintbrush, x, y, modifiers, key);
	if key == rc_shift_code then ;;; shift down, start drawing
		false -> rc_fast_drag;
		if current_brush then
			rc_move_to(current_brush, rc_coords(current_brush), "trail");
		endif;
	elseif key == -rc_shift_code then
		;;; shift key moved up - final drawing location
		if current_brush then
		;;; make sure final location is drawn
			rc_move_to(current_brush, rc_coords(current_brush), "trail");
			;;; Now move it to the new coords
			rc_move_to(current_brush, coords_in_easel(x, y), false);
			;;;dlocal Glinefunction = GXcopy;
			;;; draw it there
			rc_move_to(current_brush, rc_coords(current_brush), "trail");
			;;; stop drawing the picture
			rc_undrawn(current_brush)
		endif
	endif;
enddefine;

define :method easel_keypress_handler(b:rc_easel, x, y, modifiers, key);
	;;; default keypress event handler
	if current_brush then
		easel_keypress_handler(current_brush, x, y, modifiers, key)
	endif;
enddefine;

define :method easel_keypress_handler(b:rc_window_object, x, y, modifiers, key);
	;;; default key event handler
	if current_brush then
		easel_keypress_handler(current_brush, x, y, modifiers, key)
	endif;
enddefine;



/*
define Button -- Up/down methods
*/


define :method easel_button_1_up(obj:rc_easel, x, y, modifiers);
	;;; default: do nothing.
enddefine;

define :method easel_button_1_up(pic:paintbrush, x, y, modifiers);
	;;; let the object spring back to the brush holder
	dlocal %rc_foreground(rc_window)%, current_colour;

	if current_brush then
		if modifiers /= 's' then
			;;; Shift key up, so not drawing. Obliterate current picture
			;;; by moving it way off the screen
			rc_move_to(current_brush, 9000,9000, true);
		endif;

		;;; Put the brush back, in black
		'black' ->> current_colour -> rc_foreground(rc_window);
		rc_move_to(current_brush, start_coords(current_brush), "trail");
	endif;
	false -> current_brush;

	;;; restart fast dragging (???)
	true -> rc_fast_drag;

enddefine;

define :method easel_button_1_up(pic:rc_window_object, x, y, modifiers);
	if current_brush then
		easel_button_1_up(current_brush, x, y, modifiers)
	endif;
enddefine;

define :method easel_button_1_up(pic:paintpot, x, y, modifiers);
	if current_brush then
		easel_button_1_up(current_brush, x, y, modifiers)
	else
		pic_colour(pic) -> current_colour;
	endif;
enddefine;

define :method easel_button_1_down(pic:paintbrush, x, y, modifiers);
	false -> rc_fast_drag;
	pic ->> rc_mouse_selected(rc_active_window_object) -> current_brush;
	;;; change it to the current colour

	dlocal current_colour, %rc_foreground(rc_window)%;
	lvars oldcolour = current_colour, background = rc_background(rc_window);

	background ->> current_colour -> rc_foreground(rc_window);
	
    rc_move_to(pic, rc_coords(pic), "trail");	;;; Wipe out pic
    rc_move_to(pic, 9000,9000, "trail");		;;; Move off screen
	
	;;; Now redraw the brush using the current paint colour
	oldcolour ->> current_colour -> rc_foreground(rc_window);
    rc_move_to(pic, coords_in_easel(x, y), true);
enddefine;

define :method easel_button_1_down(pic:rc_window_object, x, y, modifiers);
	;;; Key pressed in empty space.
	;;; if current brush has not been parked, park it
	if current_brush then
		;;; turn off dragging, just in case
		easel_keypress_handler(
			current_brush, coords_in_easel(x, y), modifiers, -rc_shift_code);
		;;; park the brush
		easel_button_1_up(current_brush, x, y, modifiers)
	endif
enddefine;


define :method easel_button_1_down(pic:paintpot, x, y, modifiers);
	;;; park the brush if necessary
	if current_brush then
		;;; park the brush
		;;; easel_button_1_up(current_brush, rc_coords(current_brush), x, y, modifiers)
	endif;
	;;; Store selected colour, and indicate it by drawing lines
	pic_colour(pic) ->> current_colour ->rc_foreground(rc_window);
	;;; current_colour =>
	dlocal rc_linefunction = GXcopy, Glinefunction = GXcopy;
	applist(colour_bars, rc_draw_linepic)
enddefine;


define :method easel_button_1_up(pic:window_control, x, y, modifiers);
	;;; do the action
	rc_defer_apply(rc_window_action(pic));
enddefine;

define :method easel_button_1_down(pic:window_control, x, y, modifiers);
	;;;Nothing.
enddefine;

/*
define -- Drag methods
*/


define :method easel_button_1_drag(pic:paintbrush, x, y, modifiers);
	dlocal %rc_foreground(rc_window)% = current_colour;

	unless current_brush then
		pic -> current_brush;
	endunless;

	;;; make dragging faithful
	false -> rc_fast_drag;

	if modifiers = nullstring then
		;;; no shift key, try to follow mouse
    	rc_move_to(current_brush, coords_in_easel(x,y), true);

	elseif modifiers = 's' then

		;;; Shift key pressed
    	;;; An object was already selected keep dragging that one
    	;;; if there is a selected object, you can drag it
		;;; even in an empty space
		if brush_in_easel(x, y) and brush_in_easel(rc_coords(current_brush)) then
			rc_move_to(current_brush, x, y, "trail")
		elseif brush_in_easel(rc_coords(current_brush)) then
			rc_move_to(current_brush, coords_in_easel(x, y), "trail")
		else
    		rc_move_to(current_brush, coords_in_easel(x,y), true)
		endif
	else
		;;; do nothing
	endif;
enddefine;


define :method easel_button_1_drag(pic:rc_window_object, x, y, modifiers);
	;;; No object currently under mouse, i.e. event in window
	false -> rc_fast_drag;  ;;; ensure all events handled properly

	if current_brush then
		easel_button_1_drag(current_brush, x, y, modifiers)
	else
		;;; do nothing
	endif;

enddefine;


define :method easel_button_1_drag(pic:paintpot, x, y, modifiers);
	if current_brush then
		easel_button_1_drag(current_brush, x, y, modifiers)
	else
		;;; do nothing
	endif;
enddefine;


/*
define -- Null default methods
*/


define :method easel_do_nothing(b:rc_window_object, x, y, modifiers);
	;;; default event handler for windows.
enddefine;


/*
define -- Object creation procedures
*/

define create_brushes(x, y, list, win) -> brushes;
	;;; starting from x,y given a list of brush picture
	;;; specifications, create the brushes, and draw them
	;;; surrounded by black squares.
	rc_start();
	dlocal rc_linewidth = 2; ;;; for drawing the squares.
	lvars picspec, brush;	
	[%
		for picspec in list do
			rc_draw_square(
				x-(brush_width div 2),
				y+(brush_height div 2), brush_width);

			instance paintbrush;
				rc_picx = x;
				rc_picy = y;
				start_locx = x;
				start_locy = y;
				rc_pic_lines = picspec;
			endinstance -> brush;

			rc_draw_linepic(brush);
			brush,
			rc_add_pic_to_window(brush, win, true);
			x + brush_width + 3 -> x;
		endfor;
	%] -> brushes;
enddefine;




define create_pots(x, y, list, win) -> pots;
	dlocal current_colour;
	lvars colour, pot;	
	[%
		for colour in list do
			instance paintpot;
				rc_picx = x;
				rc_picy = y;
				pic_colour = colour;
			endinstance -> pot;

			colour -> current_colour;
			rc_draw_linepic(pot);
			pot,
			rc_add_pic_to_window(pot, win, true);
			y - 2 * pot_radius - 3 -> y;
		endfor;
	%] -> pots;
enddefine;

define create_colour_bars(list) -> bars;

	[%
		lvars pic, bar;
		for pic in list do

			instance colourbar;
				rc_pic_lines = pic;
			endinstance -> bar;

			rc_draw_linepic(bar);
			bar
		endfor;

	%] -> bars
enddefine;

/*
define -- Main startup procedure
*/

vars procedure start_easel; ;;; defined below;

define start_easel(x, y, width, height);
	if isrc_window_object(the_easel) and xt_islivewindow(rc_widget(the_easel)) then
		rc_screen_coords(the_easel) -> (x, y, width, height);
		rc_kill_window_object(the_easel)
	endif;

	'black' -> current_colour;
    false -> current_brush;

	max(width,
		length(brushes)*(brush_width+3)+10) -> easel_width;
	max(height,
		abs(top_margin) + length(pots)*(pot_radius*2+4)+10) -> easel_height;

	rc_new_window_object(
		x,y, easel_width, easel_height, {1 1 1 -1}, 'easel') -> the_easel;
	rc_mousepic(the_easel);

	;;; Give the rc_window_object the right handlers.
	{easel_button_1_down  ^false ^false}
		-> rc_button_down_handlers(the_easel);

	{easel_button_1_up ^false ^false};
		-> rc_button_up_handlers(the_easel);

	{easel_button_1_drag ^false ^false };
		-> rc_drag_handlers(the_easel);

	false -> rc_move_handler(the_easel);

	"easel_keypress_handler" -> rc_keypress_handler(the_easel);

	lvars brushlist = create_brushes(10,-30, brushes, the_easel);
	lvars potlist = create_pots(12, -60, pots, the_easel);

	lvars
	  barlist =
		[
		 [WIDTH 3 {%left_margin - 5,top_margin + 5%} {%easel_width, top_margin + 5%}]
		 [WIDTH 3 {%left_margin - 5,top_margin + 5%} {%left_margin -5, -easel_height%}]
        ],
	  margins =
		[
		 [WIDTH 2 {%left_margin,top_margin%} {%easel_width, top_margin%}]
		 [WIDTH 2 {%left_margin,top_margin%} {%left_margin, -easel_height%}]
        ]
		;
		
	create_colour_bars(barlist) -> colour_bars;	;;; global variable

	create_colour_bars(margins) -> ;

	lvars
		buttons =
		[%
			instance window_control;
				rc_picx = 200; rc_picy = -8;
				rc_window_action =
					rc_hide_window(%the_easel%);
				rc_pic_strings =
					[COLOUR 'black' FONT '9x15bold'
						{% -button_width div 2 + 3,  -5, 'DISMISS' %}];
			endinstance,
		
			instance window_control;
				rc_picx = 200 + 50 + button_width; rc_picy = -8;
				rc_window_action =

					start_easel(%x, y, width, height%);

				rc_pic_strings =
					[COLOUR 'black' FONT '9x15bold'
						{% -button_width div 2 + 3,  -5, 'RESTART'%}];
			endinstance;
		  %];

	lvars button;
	for button in buttons do
		rc_draw_linepic(button);
		rc_add_pic_to_window(button, the_easel, true);
	endfor;
enddefine;

define painting_go();
	start_easel(650,20,450,430);
enddefine;

pr('\nType\n\tpainting_go();\n');

/*
CONTENTS (define)
`
 define -- Prerequisites
 define -- Global variables
 define -- Mixin and classes
 define :mixin rc_easel;
 define :class paintbrush;
 define :class paintpot;
 define :class colourbar;
 define :class window_control;
 define :method rc_draw_linepic(bar:colourbar);
 define -- Utilities for methods
 define brush_in_easel(x, y) -> bool;
 define start_coords(pic) /*-> (x,y) */;
 define coords_in_easel(x, y) /*-> (x,y) */;
 define blob_brush(x, y, rad);
 define -- Printing methods
 define :method print_instance(pic:paintbrush);
 define :method print_instance(pot:paintpot);
 define -- Keyboard action methods
 define :method easel_keypress_handler(pic:paintbrush, x, y, modifiers, key);
 define :method easel_keypress_handler(b:rc_easel, x, y, modifiers, key);
 define :method easel_keypress_handler(b:rc_window_object, x, y, modifiers, key);
 define Button -- Up/down methods
 define :method easel_button_1_up(obj:rc_easel, x, y, modifiers);
 define :method easel_button_1_up(pic:paintbrush, x, y, modifiers);
 define :method easel_button_1_up(pic:rc_window_object, x, y, modifiers);
 define :method easel_button_1_up(pic:paintpot, x, y, modifiers);
 define :method easel_button_1_down(pic:paintbrush, x, y, modifiers);
 define :method easel_button_1_down(pic:rc_window_object, x, y, modifiers);
 define :method easel_button_1_down(pic:paintpot, x, y, modifiers);
 define :method easel_button_1_up(pic:window_control, x, y, modifiers);
 define :method easel_button_1_down(pic:window_control, x, y, modifiers);
 define -- Drag methods
 define :method easel_button_1_drag(pic:paintbrush, x, y, modifiers);
 define :method easel_button_1_drag(pic:rc_window_object, x, y, modifiers);
 define :method easel_button_1_drag(pic:paintpot, x, y, modifiers);
 define -- Null default methods
 define :method easel_do_nothing(b:rc_window_object, x, y, modifiers);
 define -- Object creation procedures
 define create_brushes(x, y, list, win) -> brushes;
 define create_pots(x, y, list, win) -> pots;
 define create_colour_bars(list) -> bars;
 define -- Main startup procedure
 define restart_easel(x, y, width, height);
 define start_easel(x, y, width, height);
 define painting_go();

*/

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Mar 28 1997
	removed re*start_easel. Now redundant.

	Fixed for changes to window_objects and mousepics.

--- Aaron Sloman, Jan 18 1997
	Got rid of dummy methods
--- Aaron Sloman, Jan 17 1997
	Introduced dismiss and restart buttons, and reorganised event handlers
	to ensure that all defaults were of type "do_nothing"
--- Aaron Sloman, Jan 12 1997
	Made the colour bar and margine drawing use the standard rc_linepic stuff,
	so that they work properly on the Alphas.
--- Aaron Sloman, Jan 10 1997
	Fixed various dragging bugs and made it show the current colour with two
	lines.
 */
