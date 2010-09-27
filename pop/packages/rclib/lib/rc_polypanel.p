/* --- Copyright University of Birmingham 2005. All rights reserved. ------
 > File:            $poplocal/local/rclib/lib/rc_polypanel.p
 > Purpose:			Demonstrate rc_control_panel with picture drawing
 > Author:          Aaron Sloman, Jul  4 1997 (see revisions)
 > Documentation:
 > Related Files: LIB * RC_CONTROL_PANEL, * RC_POLYDEMO
 */

/*

This is a modified version of LIB RC_POLY


This is based on the old LIB POLY, originally implemented circa 1977
in Pop-11 on the PDP11/40, and before that on the DEC-10 in Pop-2.

*/
section;

uses rclib
uses rc_graphic
uses rc_window_object
uses rc_slider
uses rc_buttons
uses rc_control_panel
uses rc_scratchpad;
uses rc_message;
uses rc_message_wait;

global vars current_panel;

;;; Controls speed of drawing.
global vars rc_paneldelay = 1;

;;; These global variables could be made lvars, but then
;;; the {ident <name>} format in field specifies would have
;;; to be replaced by {ident %ident <name> %} to get the
;;; identifiers not the words into the ident field.

global vars polylen, polyinc, polyang, polynum, polysize, bgcolour, fgcolour;

vars
polyadvice =
[
	'Try a square: length 400, increment 0, angle 90, sides 4'
	'Try a square with a bigger or a smaller side'
	'Try a hexagon: length 100, increment 0, angle 60, sides 6'
	'Try the same angle with only 5 or 4 or 3 sides'
	'Can you draw a pentagon (5 sides closing up)?'
	'Try: 400 0 72 5'
	'Adding extra lines will not change the appearance: 400 0 72 50'
	'Try an 8 sided closed figure. What angle will you need?'
	'Try a small octagon: 10 0 45 8'
	'Try a growing octagon: 10 2 45 50'
	'Try the same starting from length 0, growing to 600'
	'Try again with a different increment, e.g. 1'
	'An N sided closed figure needs an angle of 360 divided by N'
	'How many distinct sides will this have: 450 0 120 30'
	'Make a triangle with side length 450. Think about the angle.'
	'Triangles haves sides turning through 120 degrees (exterior angle)'
	'If you did not manage try: 450 0 120 3'
	'Try a rotating triangle: 500 0 121 360'
	'Try varying the angle for a triangle: 120.5 instead of 121'
	'Try varying the angle for a triangle: 121.5 instead of 121'
	'How many sides will this show: 100 0 40 30'
	'How many sides will this show: 0 1 40 300'
	'Try: 0 0.4 40 600'
	'Try some other angles that make sides cross over each other'
	'Try: 300 0 135 8'
	'Why does an angle of 135 make a closed figure?'
	'Try: 0 1 135 700'
	'Try a smaller increment: 0 0.75 135 900'
	'Try other increments, smaller and larger'
	'Try an angle very slightly larger than 135, e.g. 135.1'
	'Try a rotating triangle: 500 0 121 360'
	'Try a negative increment: 600 -2 120 200'
	'Try getting it to close up to the middle: 600 -2 120 300'
	'Try making the increment smaller and the number of sides bigger'
	'Change the angle slightly, e.g. 600 -1 120.5 600'
	'Try another small angle change'
	'Make it shrink to the middle, and beyond: 600 -2 120.5 600'
	'Try: 600 -1 90.5 1200'
	'Try: 600 -0.5 75.5 1200'
	'600 -0.5 75.5 2400'
	'700 -1 74 700'
	'700 -1 74.5 700'
	'700 -1 75 700'
	'700 -1 75 1400'
	'700 -0.5 75 1400'
	'700 -0.25 75 2800'
	'Try a very long side and a small turn angle: 10000 0 182 6'
	'Try more sides: 10000 0 182 180'
	'Try varying the angle with a long side: 10000 0 181 180'
	'Try: 10000 0 181.5 180'
	'Try: 10000 0 180.5 360'
	'From now on you are on your own!'
]

;
false -> pop_longstrings;

/*
;;; test

poly_advise();

*/

define poly_advise();
	lvars string;
		dest(polyadvice) -> (string, polyadvice);
		polyadvice nc_<> [^string] -> polyadvice;

		rc_message(300,300,[^string], 1,
					true, '12x24', 'gray20', 'gray90')->;
enddefine;

;;; variable to control speed of drawing
vars drawing_speed = false;

define polyspi(side, inc, ang, num, bg, fg);
	;;; Draw a polygonal spiral. Initial arm length is side.
	;;; inc is added at each turn.
	;;; The angle turned (to left) is ang (in degrees).
	;;; The total number of sides is num.
	;;; This is invoked by the operation -rc_poly- below
	
	10->> rc_scratch_x -> rc_scratch_y;
	
	lvars side, inc, ang, num;
	dlocal popradians = false;
	dlocal rc_current_window_object = rc_scratch_window ;

	bg -> rc_background(rc_window);
	fg -> rc_foreground(rc_window);


	1 -> rc_xscale;
	-1 -> rc_yscale;
	rc_window_xsize >> 1 -> rc_xorigin;
	rc_window_ysize >> 1 -> rc_yorigin;
	rc_jumpto(0, 0); 45 -> rc_heading;

	;;; move to a location and heading which will cause the centre of the
	;;; spiral to be near centre of screen (very approximate).
	;;; but first normalise ang to lie in range 0 to 359

	ang mod 360 -> ang;

	if ang > 0.5 then
		ang/2.0 -> rc_heading;
		;;;rc_jump(min(side/(2.0*sin(ang/2.0)),side));
		rc_jump(side/(2.0*sin(ang/2.0)));
	endif;
	rc_turn(90 + ang/2.0);
	repeat num times
		rc_draw(side); rc_turn(ang);
		if drawing_speed == "slower" then
			syssleep(3);
		elseif drawing_speed == "slow" then
			syssleep(2);
		elseif drawing_speed == "medium" then
			syssleep(1)
		elseif drawing_speed == "fast" and random(100) < 60 then
			syssleep(1)
		elseif drawing_speed == "faster" and random(100) < 30 then
			syssleep(1)
		else
		endif;
		side+inc ->side;
	endrepeat;
enddefine;


define inc_slider(slider, num, inc);
	rc_increment_slider(current_panel, slider, num, inc);
	if slider == "slider4" then
		slider_value_of_name(current_panel, "slider4", 1)
			-> rc_field_item_of_name(current_panel, "numberin", 1)
	endif;
enddefine;

define set_sliders(len, inc, ang, num);
	len -> slider_value_of_name(current_panel,"slider1", 1);
	inc -> slider_value_of_name(current_panel,"slider2", 1);
	ang -> slider_value_of_name(current_panel,"slider3", 1);
	num -> slider_value_of_name(current_panel,"slider4", 1);
	num -> rc_field_item_of_name(current_panel, "numberin", 1);
enddefine;

vars procedure rc_poly;	;;; defined below

define set_sides(num) -> num;
	min(10000, round(num)) -> num;
	;;; when panel complete, use this to update slider4.
	unless iscaller(rc_poly) then
		num -> slider_value_of_name(current_panel,"slider4", 1);
	endunless;
enddefine;


define slider4_reactor(obj, item);
	unless iscaller(rc_poly) or iscaller(slider4_reactor, 1) then
		item -> rc_field_item_of_name(current_panel, "numberin", 1);
	endunless;
enddefine;


global vars
	;;; default for slider value panel (rc_slider_value_panel)
	;;; i.e. the panel to the right of the slider showing the value
	rc_slider_field_value_panel_def =
	;;; Now the specificiation for the numeric slider value display
	;;; {whichend bg      fg     font places px py length ht fx fy}
		{2      'gray95' 'black' '8x13' 2    10  0  60     12 4 -4};

;;; Some ancillary lists used in building up the specification for the control
;;; panel
vars picture_colours =
	;;; Colour option specifications for foreground and background
	[   {margin 1}
		{fieldbg 'grey60'}
        {width 62}{height 24} {cols 7} :
		'black'  'blue'   'brown' 'cyan'  'gold'   'gray20' 'gray80'
		'green'  'ivory'  'orange' 'pink'   'red'   'white' 'yellow'
	],

	;;; a list of specifications for sliders
	slider_specs =
		[ {type square}
		{width 350} {radius 4} {blobcol 'blue'}
		{framecol 'black'} {height 28} {spacing 0}
		{margin 0}
		{fieldbg 'grey75'}
		{barcol 'white'} {gap -5} ],

	;;; A list of specifications for the buttons to be used for adjusting sliders
	slider_adjuster_specs =
		[{align right} {gap -32} {cols 2}
		 {width 35} {height 17} {spacing 0}]
;

vars

	textfont = {font '9x15bold'},

	panel_specs =
    [
        ;;; Default settings for the background and foreground of
        ;;; the panel
        {bg 'grey75'} ;;; try other colours, e.g. 'pink', 'ivory'
        {fg 'grey10'}
        {font '8x13'}
		;;; expand minimum width to accommodate slider accelerators
		{width 445}
      	[TEXT
			^textfont
			{margin 3} :

        	'A DEMONSTRATION OF RC_CONTROL_PANEL'
			'Choose background and foreground colours'
			'from the buttons, and picture parameters'
			'using sliders,'
			'Then click on DRAW.'
      	]

	    ;;; background_instructions =
      	[TEXT
			^textfont
			{gap 1} :
         	'Select background colour here'
      	]

    	;;; background_radio_buttons =
      	[RADIO
			{label background}
			{ident bgcolour}
			^^picture_colours
	  	]

    	;;; background_instructions =
      	[TEXT
			^textfont
			{gap 1} :
        	'Select foreground colour here'
       	]

    	;;; foreground_radio_buttons =
      	[RADIO
			{label foreground}
			{ident fgcolour}
			^^picture_colours
	  	]

      	[TEXT
			^textfont
			{gap 1} :
        	'Use sliders to select picture parameters'
       	]
		[SLIDERS
			{label slider1}
			{ident polylen}
			^slider_specs {gap 3}:
			[{0 1000 400} round
          		[{-5 10 'Initial length: [0 to 1000]'}] ]
	  	]
		[ACTIONS
			^slider_adjuster_specs {margin 4} :
			['-1' [POPNOW inc_slider("slider1", 1, -1)]]
			['+1' [POPNOW inc_slider("slider1", 1, 1)]]
			['-5' [POPNOW inc_slider("slider1",1, -5)]]
			['+5' [POPNOW inc_slider("slider1",1, 5)]]
		]
		[SLIDERS
			{label slider2}
			{ident polyinc}
			^slider_specs  :
			[{-10 10 0} noround
          		[{-5 10 'Increment: [-10 to +10]'} ] ]
	  	]
		[ACTIONS
			^slider_adjuster_specs {margin 4} :
			['-0.1' [POPNOW inc_slider("slider2", 1, -0.1)]]
			['+0.1' [POPNOW inc_slider("slider2", 1, 0.1)]]
			['-0.5' [POPNOW inc_slider("slider2", 1, -0.5)]]
			['+0.5' [POPNOW inc_slider("slider2", 1, 0.5)]]
			['-1'   [POPNOW inc_slider("slider2", 1, -1)]]
			['+1'   [POPNOW inc_slider("slider2", 1, 1)]]
		]
		[SLIDERS
			{label slider3}
			{ident polyang}
			^slider_specs :
			[{-360 360 90} noround
          		[{-5 10 'Angle to turn: [-360 to 360]'}] ]
	  	]
		[ACTIONS
			^slider_adjuster_specs {margin 4}:
			['-0.1' [POPNOW inc_slider("slider3", 1, -0.1)]]
			['+0.1' [POPNOW inc_slider("slider3", 1, 0.1)]]
			['-0.5' [POPNOW inc_slider("slider3", 1, -0.5)]]
			['+0.5' [POPNOW inc_slider("slider3", 1, 0.5)]]
			['-1'   [POPNOW inc_slider("slider3", 1, -1)]]
			['+1'   [POPNOW inc_slider("slider3", 1, 1)]]
		]
		[SLIDERS
			{label slider4}
			{ident polynum}
			^slider_specs {gap -4}:
			[{1 10000 4} round
          		[{-5  10 'Number of sides: [1 to 10000]'}] ]
	  	]
		[ACTIONS
			^slider_adjuster_specs {gap -23}:
			['-1'  [POP11  inc_slider("slider4", 1, -1)]]
			['+1'  [POP11 inc_slider("slider4", 1, 1)]]
			;;;['-10' [POP11 inc_slider("slider4", 1, -10)]]
			;;;['+10' [POP11 inc_slider("slider4", 1, 10)]]
			;;;['-50' [POP11 inc_slider("slider4", 1, -50)]]
			;;;['+50' [POP11 inc_slider("slider4", 1, 50)]]
			]
		[NUMBERIN
			{label numberin}
			{labelstring 'Number of lines:'}
			{bg 'grey10'}
			{activebg 'blue'}
			{textinbg 'brown'}
			{textinfg 'white'}
			{fg 'grey90'}
			{gap 1}
			:
			[4 {constrain set_sides}]]
		[TEXT
			^textfont
			{gap 1}
			{label getsize}:
			'Select size for picture'
		]
		[SLIDERS
			{label slider5}
			{ident rc_scratch_width}
			^slider_specs {gap -4}:
			[{1 1500 600} round
          		[{-5  10 'window width: [1 to 1000]'}] ]
	  	]
		[SLIDERS
			{label slider6}
			{ident rc_scratch_height}
			^slider_specs {gap -4}:
			[{1 1500 600} round
          		[{-5  10 'window height: [1 to 1000]'}] ]
	  	]
		[TEXT
			^textfont
			{gap 1}
			{label instruct}:
			'Select speed then click on DRAW to make picture'
		]
		[ACTIONS
			{font
					;;; '7x13bold'
					'*lucida*-r-*sans-10*'
			}
			{width 65} {height 26} :
			['FASTEST' [POPNOW false -> drawing_speed]]
			['FASTER' [POPNOW "faster" -> drawing_speed]]
			['FAST' [POPNOW "fast" -> drawing_speed]]
			['MEDIUM' [POPNOW "medium" -> drawing_speed]]
			['SLOW' [POPNOW "slow" -> drawing_speed]]
			['SLOWER' [POPNOW "slower" -> drawing_speed]]
			['DRAW' [POP11 rc_polypanel()]
                {
					rc_button_font '10x20'
                  	rc_button_stringcolour 'white'
                  	rc_button_bordercolour 'red'
                  	rc_button_labelground 'brown'
                  	rc_button_blobcolour 'ivory' }
			]
		]

		[TEXT
			^textfont
			: 'Some Sample shapes to choose from'
			'See how they change the sliders.'
			'Try varying initial length.']

		[ACTIONS
			{width 70} {height 24}
			{font
					;;; '7x13bold'
					'*lucida*-r-*sans-10*'
			}
        	{spec
                {
                  	;;;rc_button_stringcolour 'white'
                  	;;; rc_button_bordercolour 'red'
                  	;;; rc_button_labelground 'brown'
				}}
			:
			['TRIANGLE' [POPNOW set_sliders(425,0,120,3)]]
			['HEXAGON' [POPNOW set_sliders(240,0,60,6)]]
			['OCTAGON' [POPNOW set_sliders(185,0,45,8)]]
			['DECAGON' [POPNOW set_sliders(145,0,36,10)]]
			['FIFTEEN' [POPNOW set_sliders(95,0,24,15)]]
			['TWENTY' [POPNOW set_sliders(70,0,18,20)]]
	  	]
		[TEXT
			^textfont
			:
			'To get new picture panel'
			'click on SAVEPIC before clicking on DRAW'
		]

	  	[ACTIONS
			{cols 0}
			{width 114}{height 23}
			{gap 1}
			{fieldbg 'blue'}
			{font
					;;; '7x13bold'
					'*lucida*-r-*sans-10*'
			}
			:
        	;;; This saves the previous scratchpad and starts a new one
        	['SAVEPIC'  rc_tearoff]

        	;;; this kills all the saved tearoffs
        	['KILL TEAROFFS' rc_kill_tearoffs]

        	;;; This hides the current scratchpad window
        	['HIDE PIC'
                [POP11
					false -> rc_scratch_window;
					false -> rc_current_window_object]]

        ]
		[ACTIONS
			{align centre} {gap 1} {spacing 1}
			{fieldbg 'blue'}
			{width 130} {height 25}
			{font '7x13bold'}
        	{spec
                {
                  	rc_button_stringcolour 'white'
                  	rc_button_bordercolour 'red'
                  	rc_button_labelground 'brown'
                  	rc_button_blobcolour 'ivory' }}
			:

			['SUGGESTIONS' poly_advise]
			
            {blob 'KILL PANEL'
                [POP11
					rc_kill_tearoffs();
					false -> rc_scratch_window;
					rc_kill_menu();
					]
			} ]
	];


define rc_polypanel();
	;;; uses the global variables set on the panel, ie.
	;;; polylen, polyinc, polyang, polynum), bgcolour, fgcolour

	if not(isstring(bgcolour)) then
		rc_message_wait(300,300,['Please choose a background colour'], 1,
					true, '12x24', 'gray20', 'gray90');
		return();
	elseif not(isstring(fgcolour)) then
		rc_message_wait(300,300,['Please choose a foreground colour'], 1,
					true, '12x24', 'gray20', 'gray90');
		return();
	endif;

	polyspi(polylen, polyinc, polyang, round(polynum), bgcolour, fgcolour)
enddefine;


define syntax poly;
	sysCALL("rc_poly");
	";" :: proglist -> proglist
enddefine;

define syntax polyoff;
	sysPUSH("current_panel");
	sysCALL("rc_kill_window_object");
	";" :: proglist -> proglist
enddefine;


define rc_poly();
	dlocal rc_slider_field_height_def = 30;
	rc_control_panel("right", "top", panel_specs, 'Demo Panel') -> current_panel;
	slider4_reactor ->
		rc_informant_reactor(hd(rc_field_contents(rc_field_of_label(current_panel, "slider4"))));
enddefine;

pr('\n TYPE:\n   rc_poly();\n');

endsection;
/*
CONTENTS

 define poly_advise();
 define polyspi(side, inc, ang, num, bg, fg);
 define inc_slider(slider, num, inc);
 define set_sliders(len, inc, ang, num);
 define set_sides(num) -> num;
 define slider4_reactor(obj, item);
 define rc_polypanel();
 define syntax poly;
 define syntax polyoff;
 define rc_poly();

*/

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Dec 31 2005
		Added more sliders and buttons, making it possible to alter width and
		height of display window, and more speed options to suit faster cpus.

		Also the control panel now appears top right and the graphic panel top
		left.
--- Aaron Sloman, Jul 21 2000
	Reduced size, using smaller fonts, etc.
--- Aaron Sloman, Jul 29 1999
	Changed to create panel to right of centre
--- Aaron Sloman, Apr  1 1999
	Changed to use activebg, textinbg, textinfg in TEXTIN field.
--- Aaron Sloman, Mar 30 1999
	Use mechanism allowing a variableto be associated with a RADIO
	or SOMEOF field.
--- Aaron Sloman, Mar 24 1999
	Introduced a numberin panel as an alternative to setting number
	of sides.
--- Aaron Sloman, Mar 21 1999
	Allowed fast, medium, slow, slower, and speeded up medium.
	Added an extra action button
--- Aaron Sloman, Feb  6 1998
	Altered to use new slider width values
--- Aaron Sloman, Feb  3 1998
	Slight adjustments for new rc_polypanel
--- Aaron Sloman, Nov 29 1997
	Changed to make ycoords for slider labels increase upwards.
--- Aaron Sloman, Aug 28 1997
	Changed to use rc_message_wait
--- Aaron Sloman, Aug  10 1997
	Removed unnecessary uses of DEFER
--- Aaron Sloman, Aug  3 1997
	Changed to use square slider buttons
--- Aaron Sloman, Aug  2 1997
	A few changed details, including the HIDE button.
--- Aaron Sloman, Jul 21 1997
	changed to use "align" instead of "centre", and to allow a
	list of field properties
 */
