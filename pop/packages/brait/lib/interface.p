/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/brait/lib/interface.p
 > Purpose:         asynchronous simulator control panel
 > Author:          Duncan K Fewkes, Aug 22 2000 (see revisions)
                    - copied and altered procedures from version in teach
                    rc_async_demo
 > Documentation:
 > Related Files:
 */
/*
         CONTENTS - (Use <ENTER> g to access required sections)

 -- CREATE NEW OBJECT PROCS
 -- CONTROL PANEL CODE
 -- Remote control panel - sliders to show + control variables
 -- Dials readout panel

DEFINE CONTENTS: use ENTER gg to access

 define create_source_from_menu(x, y, type);
 define create_box_from_menu();
 define graphic_live() -> boole;
 define control_panel();
 define remote_control();
 define:method make_dial_panel(obj:vehicle);

*/
/*
-- CREATE NEW OBJECT PROCS --------------------------------------------
*/
/*
PROCEDURE: create_source_from_menu (x, y, type)
INPUTS   : x, y, type
  Where  :
    x is the x coord
    y is the y coord
    type is the stimulus type
OUTPUTS  : creates/returns the new source object
USED IN  : control panel
CREATED  : 22 Aug 2000
PURPOSE  : pause simulator, create source, add to screen and then return to
simulator

TESTS:

*/

define create_source_from_menu(x, y, type);
 dlocal rc_in_event_handler = true;


    lvars newsource;

    create_simple_source( x, y, type) -> newsource;

    if islist(sim_objects) then
        [^newsource] <> sim_objects -> sim_objects;
    endif;

    show_and_name_instance(sim_name(newsource), newsource, brait_world);

    create_source_coords + 20 -> create_source_coords;

enddefine;




/*
PROCEDURE: create_box_from_menu ()
INPUTS   : user must draw box in graphical window
OUTPUTS  : creates/returns the new box object
USED IN  : control panel
CREATED  : 22 Aug 2000
PURPOSE  : pause the simulator until user draws box, then create it and
return to simulator

TESTS:

*/

define create_box_from_menu();
 dlocal rc_in_event_handler = true;

    lvars newbox;

    draw_box()->newbox;

    if islist(sim_objects) then
        [^newbox] <> sim_objects -> sim_objects;
    endif;

    show_and_name_instance(sim_name(newbox), newbox, brait_world);


enddefine;

/*
-- CONTROL PANEL CODE -------------------------------------------------
*/

/*
PROCEDURE: graphic_live ()-> boole
INPUTS   : NONE
OUTPUTS  : boole is a boolean
USED IN  : control panel and kill_windows
CREATED  : 22 Aug 2000 - copied and altered from version in teach rc_async_demo
PURPOSE  : check to see if brait_world is a live widget

TESTS:

*/

define graphic_live() -> boole;
    ;;; utility procedure
    brait_world
    and rc_widget(brait_world)
    and xt_islivewindow(rc_widget(brait_world))
        -> boole;
enddefine;



/*
PROCEDURE: control_panel ()
INPUTS   : NONE
OUTPUTS  : creates the control panel (in top left)
USED IN  :
CREATED  : 22 Aug 2000 - copied and altered from version in teach rc_async_demo
PURPOSE  : to create an asynchronous control panel for the braitenberg
simulator

TESTS:

*/

define control_panel();
    ;;; This sets up the main control panel

	if rc_islive_window_object(brait_control_panel) then
     	rc_kill_window_object(brait_control_panel);
 	endif;

    rc_control_panel("right", "top",
        [
			;;; added by AS to prevent spurious move effects. 7 Oct 2000
			;;; See HELP rc_control_panel
    		{events [button motion]}

            {font '8x13bold'}       ;;; font specification
            {bg 'black'}            ;;; background black  (try brown)
            {fg 'white'}            ;;; foreground white  (try yellow)
            ;;; try {cols 2}
            [TEXT : 'Simulator Controls']
            ;;; Now button definitions. Use POPNOW for instant action.
            [ACTIONS
				{width 80}
                {cols 2}        ;;; orientation vertical, 2 columns
                {bg 'grey20'}:
                ['START' [POP11 false ->> do_stop -> do_finish ;
                                unless sim_running=true then
                                    if not(graphic_live()) then
                                        create_window(500,500);
                                    endif;
                                    brait_world->rc_current_window_object;
									;;; Added AS 7 Oct 2000
									;;; prevent interference by mouse moves
									true -> rc_drag_only(brait_world);
                                    brait_sim(false);
                                endunless;]]
                ['STOP' [POPNOW true -> do_stop]]
				['SLOW DOWN' [POPNOW delay_time + 1 -> delay_time]]
				['SPEED UP'
					[POPNOW max(-1, delay_time) - 1 -> delay_time]]
            ]

            [TEXT
            {gap 2}:
            'Add Objects:' ]

            [ACTIONS
                {cols 1}:
                ['New sound Source' [DEFER POP11 create_source_from_menu(create_source_coords,create_source_coords, sound);]]
                ['New Box' [DEFER POP11 create_box_from_menu();]]
				% if identprops("make_vehicle") /== undef
					 and isprocedure(valof("make_vehicle")) then
					['New vehicle'
						[DEFER POP11
							make_vehicle():: sim_object_add_list
								-> sim_object_add_list;]]
				endif %
            ]

            [TEXT
            {gap 2}:
            'Path Tracing Options:' ]

            [ACTIONS
				{width 65}
                {cols 2}:
                ['Blob Trace' [DEFER POP11 'blob' -> path_tracing]]
                ['Line Trace' [DEFER POP11 'line' -> path_tracing]]
            ]
            [ACTIONS
				{width 90}
                {cols 1}:
                ['Path trace OFF' [DEFER POP11 false-> path_tracing]]
		    ]

            [TEXT
            {gap 2}:
            'Window Management:' ]

            [ACTIONS
				{width 95}
                {cols 2}:
                ['Redraw Window' [DEFER POP11 dlocal rc_in_event_handler = true;
                                if graphic_live() then
                                    rc_redraw_window_object(brait_world)
                                endif;]]
                ['Kill Windows'
                    [POP11
                        true -> do_stop;
                        killwindows();]]
                ['New Window' [DEFER POP11
                                true ->> do_stop -> do_finish;
                                killwindows();
                                create_window(500,500); ]]
                ['DISMISS PANEL' [POP11
                            true ->> do_stop -> do_finish;
                            rc_hide_panel();
                            ]]
            ]
        ],
    'Control Panel') -> brait_control_panel;
enddefine;

/*
-- Remote control panel - sliders to show + control variables ---------
*/

vars
    ;;; variables to be controlled by sliders
    slider1, slider2;


/*
PROCEDURE: remote_control ()
INPUTS   : NONE
OUTPUTS  : NONE
USED IN  :
CREATED  : 29 Aug 2000
PURPOSE  : to make a panel with two sliders on it that control and are
controlled by the values in vars slider1 and slider2.

TESTS:

*/

define remote_control();

if rc_islive_window_object(remote_control_panel) then
    rc_kill_window_object(remote_control_panel);
endif;


    rc_control_panel("right", "top",
        [
			;;; added by AS to prevent spurious move effects. 7 Oct 2000
    		{events [button dragonly]}
            {font '8x13bold'}       ;;; font specification
            {bg 'black'}            ;;; background black  (try brown)
            {fg 'white'}            ;;; foreground white  (try yellow)
            ;;; try {cols 2}
            {width 325}
            [TEXT : 'REMOTE CONTROL PANEL']

            [SLIDERS
            ;;; Give the field the access label "slider"
            {label sliders}
            {width 250}
            {height 30}
            {radius 7}
            {barcol 'white'}
            {blobcol 'red'}
            {framecol 'black'}
            ;;; Try uncommenting this, to change the appearance of the
            ;;; movable part:
            ;;; {type panel}
            ;;; uncomment this to disable text input to slider
            {textin ^false}
            ;;; format for number value panel
            ;;;    end bg       fg     font  px py len ht
            {panel {2 'yellow' 'blue' '8x13' 12 0  55 16}}
            ;;; uncomment this to disable text panel
            ;;; {panel ^false}
            ;;; Make slider bars have a frame of width 3.
            {framewidth 3}
            ;;; try uncommenting the following
            ;;; {places 0}
            {spacing 20}
            {gap 4} :
            ;;; range 0 to 100, default value 0, steps 1
            [slider1 {0 100 0 1}
                ;;; labels on left and right
                [[{-5 15 'MIN(0) slider1'}]
                    [{-50 15'MAX(100)'} ]]
            ]
            [slider2 {0 100 0 1}
            ;;; labels on left and right
                [[{-5 15 'MIN(0) slider2'}]
                    [{-50 15'MAX(100)'} ]]
            ]
        ]
        ],
    'Remote Control Panel') -> remote_control_panel;

[^^sim_all_windows ^remote_control_panel] -> sim_all_windows;
enddefine;


/*
-- Dials readout panel ------------------------------------------------
*/

/*
METHOD   : make_dial_panel (obj)
INPUTS   : obj is a vehicle object to be traced - the values of the units will
show up on the dials
OUTPUTS  : NONE
USED IN  :
CREATED  : 31 Aug 2000
PURPOSE  : to create a panel and assign global vars such that there is a bank
of dials, one for each of the vehicle's units, that show the activity of the
units.


TESTS:

*/

define:method make_dial_panel(obj:vehicle);

lvars unit, dials_list = [];

if rc_islive_window_object(dial_panel) then
    rc_kill_window_object(dial_panel);
endif;

1 -> gensym("dial");
1-> gensym("Unit");
1-> gensym("Sensor");

if islist(activation_function_matrix(obj)) then
    for unit from 1 to (length(activation_function_matrix(obj))-2) do
        dials_list <> [[%gensym("dial")% %word_string(gensym("Unit"))%]] -> dials_list;
    endfor;
    for unit from 1 to length(sensors(obj)) do
        word_string(gensym("Sensor")) -> dials_list(unit)(2);
    endfor
else
    for unit from 1 to (length(sensors(obj))) do
        dials_list <> [[%gensym("dial")% %word_string(gensym("Sensor"))%]] -> dials_list;
    endfor;
    if islist(hand(obj)) then
        dials_list <> [[%gensym("dial")% 'Hand']] -> dials_list;
    endif;
endif;


    lvars dial_specs =
    [ {width 200}
			;;; added by AS to prevent spurious move effects. 7 Oct 2000
    		{events [button dragonly]}
            [DIALS
                {label dials}
                {fieldbg 'grey95'}{spacing 25}{fieldheight 50}
                {dialwidth 160} {dialheight 130} {dialbase 30}
                {margin 4} {offset 70}{gap 30}:

		;;; Loop - make a dial for each unit (ignoring motors, these dials are done
		;;; differently after the loop

                %for unit from 1 to length(dials_list) do

                [%dials_list(unit)(1)% 0 0 180 180 {0 100 0 1} 60 5 'yellow' 'blue'
                    [MARKS
                        ;;; {extra radius, angular gap, mark width, length, colour}
                        {5 18 2 3 'black'}]
                    [LABELS
                        ;;; {extra radius, angular gap, initial value, increment,
                        ;;;         colour font}
                        {10 18 0 10 'blue' '6x13'}]
                    [CAPTIONS
                        ;;; {relative location, string, colour, font}
                        {-30 30 %dials_list(unit)(2)% 'blue' '10x20'}]
                ]
                endfor%
			;;; end of loop
                ;;; a large additional x_offset (70) because of extra
                ;;; width of dial1.
                [leftmotordial 70 -60 -90 180 {0 100 0 1} 50 10 ^false ^false
                    [LABELS
                        {10 18 0 10 'blue' '6x13'}]
                    [CAPTIONS
                        ;;; {relative location, string, colour, font}
                        {-90 85 'Left Motor' 'blue' '10x20'}]
                ]

                [rightmotordial -25 -60 90 180 {100 0 0 -1} 50 10 ^false ^false
                    [LABELS
                        {10 18 100 -10 'blue' '6x13'}]
                    [CAPTIONS
                        ;;; {relative location, string, colour, font}
                        {-10 85 'Right Motor' 'blue' '10x20'}]
                ]
            ]
        ];

rc_control_panel("right", "bottom", dial_specs , 'Dial_panel') -> dial_panel;

[^^sim_all_windows ^dial_panel] -> sim_all_windows;
obj -> sim_dial_panel_for;

enddefine;

;;; for "uses"
global constant interface = true;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Oct  8 2000

	Fixed header. Added "define" index.
	Made control panel include two more buttons
		SPEED UP
		SLOW DOWN
	Added true -> rc_drag_only(brait_world), so that movement of
	mouse will not interfere with drawing of moving objects.

--- Duncan K Fewkes, Aug 31 2000
added dials_panel creation procedure

changed panel creation procedures slightly so that they check
rc_islive_window_object(panel) and if true, then use rc_kill_window_object(panel)
to destroy old before creating new.

Also made it so that panels are included in sim_all_windows list so that they
can all be killed when main control panel "kill windows" button is used.

--- Duncan K Fewkes, Aug 30 2000
converted to lib format
--- Duncan K Fewkes, Aug 29 2000
added basic remote control panel with sliders - on suggestion from A.Sloman
 */
