
/*
TEACH MENU_DEMO.P                                Aaron Sloman, Sept 1999
Slightly revised 7 Sep 2002

Compare TEACH rc_async_demo
in RCLIB
*/


/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/rcmenu/teach/menu_demo.p
 > Purpose:            Demonstrate "asynchronous" control panel
 > Author:          Aaron Sloman, Jan 25 1995 (see revisions)
 > Documentation:
 > Related Files:	TEACH RC_ASYNC_DEMO
 */


/*
NOTE:
Loading this file may take some time unless you have already
compiled the following:

	uses rclib
    uses rc_control_panel

	uses rcmenulib
    uses menu_new_menu

RUNNING THE DEMONSTRATION

Load this file (ENTER l1) then run this command

    menu_go();

On some terminals you may get a warning about unknown colours. Just
refresh the screen afterwards (CTRL-L).

Then try clicking on the various buttons and see what happens. After a
while click on STOP and then read the rest of this file.

The procedure menu_go(), defined below, will create a control panel
which you can use to start up a moving graphical display (based on lib
rc_graphic), by clicking on the STARTUP button. You can change the
display by clicking on the buttons on the panel while the display is
actively changing. After playing a while, use the STOP button to stop
the graphics. Then kill the graphic window, by clicking on KillGraphic.

Then look at the definition of the control menu inside the procedure
menu_go() defined below. Try changing the definition, including changing
the location vector, other controls, and the foreground and background
colours (See HELP * XCOLOURS).

The procedure menu_go(), defined below includes the definition of a menu
panel for controlling the graphical display. The comments include
suggestions for redefining parts of the menu to try different colours,
locations, etc.

For more information see

    TEACH * VED_MENU
    HELP  * VED_MENU
    HELP  * POPUPTOOL

The main procedures defined below are

 -- The main procedure: menu_go()
 -- rc_restart();
 -- do_delay();
 -- multi_box
 -- multi_line
 -- multi_poly
 -- multi_square
 -- Colour control

*/


;;; These may take a little while to compile
uses rc_graphic
uses rclib
uses rc_control_panel

uses rcmenulib
uses menu_new_menu

/*
-- The main procedure: menu_go()

;;; Compile the file then test it
menu_go();

*/

;;; A procedure to create a control panel. It uses procedures defined
;;; below to produce the graphics


global vars

    ;;; The main panel
    async_go_panel,

    ;;; The dynamic graphic panel
    async_graphic_panel,

    ;;; The colour control panel
    async_colour_panel,

    do_pause = false,   ;;; used to control drawing loops
    do_stop = false,    ;;; true if demo is to stop
    do_finish = false,  ;;; true of panels are to be removed

    control_procedure,  ;;; current drawing procedure

    ;;; procedures defined below
    procedure (rc_restart, multi_box, multi_line, multi_poly,
            multi_square, rc_restart, startup, make_colour_panel),
    ;


define graphic_live() -> boole;
    ;;; Utility procedure to tell if graphic panel is alive
    async_graphic_panel
    and rc_widget(async_graphic_panel)
    and xt_islivewindow(rc_widget(async_graphic_panel))
        -> boole;
enddefine;

define rc_test_hide(panel);
    if isrc_window_object(panel) and rc_widget(panel) then
        rc_hide_window(panel);
    endif;
enddefine;


define menu_go();
    ;;; This does nothing more than set up the menu

    define :menu rc_control;
        'Control'               ;;; The label, for the window manager
        {-20 10}                ;;; location top right. Try {20 -1}
		{width 105}
        {font '7x13bold'}       ;;; font specification
        {bg 'black'}            ;;; background black  (try brown)
        {fg 'white'}            ;;; foreground white  (try yellow)
        {cols 1}                ;;; orientation vertical, single column
                                ;;; try {cols 2}
        'Change the\nfunction'
		
        ;;; Now button definitions. Use POPNOW for instant action.
        ['STARTUP' startup]
     	['SLOWER' [POP11 do_delay_delay + 1 -> do_delay_delay]]
        ['FASTER'
             [POP11 max(0, do_delay_delay - 1) -> do_delay_delay]]
        [multi_box [POP11 restart(multi_box)]]
        [multi_line [POP11 restart(multi_line)]]
        [multi_poly [POP11 restart(multi_poly)]]
        [multi_square [POP11 restart(multi_square)]]
        ['ChangeColour*' [DEFER make_colour_panel()]]
        ;;; make this one happen immediately
        [STOP [POPNOW true -> do_stop]]
        [KillGraphic
                    [POP11
                        true -> do_stop;
                        rc_test_hide(async_graphic_panel);
                        false -> async_graphic_panel;]]
		['KILL ALL'
				[POP11
                            true ->> do_stop -> do_finish;
                            rc_test_hide(async_graphic_panel);
                            rc_test_hide(async_colour_panel);
                            ;;; hide this panel
                            rc_hide_panel();
                            ]]
    enddefine;

vedrefresh();    ;;; in case there are problems with the above

enddefine;

/*
-- rc_restart();

;;; test it
rc_restart();
*/

define rc_restart();
    ;;; Clear the image.
    true -> do_pause;
    returnif(do_stop or not(graphic_live()));
    async_graphic_panel -> rc_current_window_object;
    rc_start();
    false -> do_pause;
enddefine;

/*
-- do_delay();

Try giving this different definitions to have different effects.
on the speed of the display.

*/

;;; delay is one tenth of a second
global vars do_delay_delay = 0;

define do_delay();
    ;;; could be changed to use an argument set by a counter
    ;;; button
    unless do_pause or do_stop then
        syssleep(do_delay_delay);
    endunless;
enddefine;

/*
-- multi_box

;;; test it
multi_box();

*/

define rc_draw_box(x,y,width, height);
    ;;; Draw a box

    ;;; Add a bit of random jitter.
    x-10+random(20) -> x;
    y-10+random(20) -> y;

    lvars xmax = x + width, ymax = y + height;
;;;    returnif(do_stop or do_pause or not(graphic_live()));
    rc_drawline(x, y, xmax, y);
;;;    returnif(do_stop or do_pause or not(graphic_live()));
    rc_drawline(xmax, y, xmax, ymax);
;;;    returnif(do_stop or do_pause or not(graphic_live()));
    rc_drawline(xmax, ymax, x, ymax);
;;;    returnif(do_stop or do_pause or not(graphic_live()));
    rc_drawline(x, ymax, x, y);
enddefine;

define multi_box();
    ;;; Draw lots of boxes
    lvars x,y,height,width;
    rc_restart();
    for x from -220 by 60 to 180 do
        for y from -220 by 70 to 190 do
            for width from 0 by 80 to 200 do
                for height from -100 by 30 to 100 do
                    returnif(do_stop or do_pause
                                or not(graphic_live()));
                    unless rc_in_event_handler then
                        dlocal
                            rc_current_window_object = async_graphic_panel;
                        rc_draw_box(x,y,width,height);
                    endunless;
                endfor
            endfor
        endfor
    endfor;
    do_delay();
enddefine;

/*
-- multi_line
;;;test it
multi_line();

*/

define multi_line();
    lvars x1,y1,x2,y2;
    rc_restart();
    repeat 500 times
        random(600) - 300 -> x1;
        random(600) - 300 -> x2;
        random(600) - 300 -> y1;
        random(600) - 300 -> y2;
        returnif(do_stop or do_pause
                                or not(graphic_live()));
        unless rc_in_event_handler then
            dlocal rc_current_window_object = async_graphic_panel;
            rc_drawline(x1, y1, x2, y2);
        endunless;
    endrepeat;
    do_delay();
enddefine;


/*
-- multi_poly

;;; test
multi_poly();

*/

define polyspi(side, inc, ang, num);
    ;;; Draw a polygonal spiral. Initial arm length is side.
    ;;; inc is added at each turn.
    ;;; The angle turned (to left) is ang (in degrees).
    ;;; The total number of sides is num.
    ;;; This is invoked by the operation -rc_poly- below

    dlocal popradians = false;

    1 -> rc_xscale;
    -1 -> rc_yscale;
    rc_window_xsize >> 1 -> rc_xorigin;
    rc_window_ysize >> 1 -> rc_yorigin;
    rc_jumpto(0, 0); 45 -> rc_heading;

    ;;; move to a location and heading which will cause the centre of the
    ;;; spiral to be near centre of screen (very approximate).
    ;;; but first normalise ang to lie in range 0 to 359
    until ang >= 0 do ang + 360 ->ang enduntil;
    until ang < 360 do ang - 360 ->ang enduntil;
    if ang > 0.5 then
        ang/2.0 -> rc_heading;
        rc_jump(min(side/(2.0*sin(ang/2.0)),side));
    endif;
    rc_turn(90 + ang/2.0);
    repeat num times
        returnif(do_stop or do_pause
                    or not(graphic_live()));
        unless rc_in_event_handler then
            dlocal rc_current_window_object = async_graphic_panel;
            rc_draw(side); rc_turn(ang);
            side+inc ->side;
        endunless
    endrepeat;
    do_delay();
enddefine;

define multi_poly();
    lvars side, inc, ang, num;
    rc_restart();
    random(400)+ 200 -> side;
    random(4) - 8 -> inc;
    180 - (720 / random(4) + 3) -> ang;
    if random(10) > 5 then -ang -> ang endif;
    random(300) + 300 -> num;
;;;    returnif(do_stop or do_pause or not(graphic_live()));
    polyspi(side,inc,ang,num);
enddefine;


/*
-- multi_square

;;; test it
multi_square();

*/

define rc_demo_square(side);
    repeat 4 times
        unless rc_in_event_handler then
            dlocal rc_current_window_object = async_graphic_panel;
            rc_draw(side); rc_turn(90);
        endunless
    endrepeat;
enddefine;

define multi_square();
    lvars side, angle;

    dlocal popradians = false;

    rc_restart();
    oneof([46 -46]) -> angle;
    random(200) + 30 -> side;
    rc_jumpto(0, 0); random(45) -> rc_heading;
    repeat 64 times
        returnif(do_stop or do_pause
            or not(async_graphic_panel));
        rc_demo_square(side);
        rc_turn(angle);
    endrepeat;
    do_delay();
enddefine;



global vars control_procedure = valof(oneof(
    [multi_box multi_line multi_poly multi_square ]));


/*
-- Colour control
*/

lvars current_colour = 'black';

define rc_set_colour(string);
    if isstring(string) then
        true -> do_pause;
        string -> current_colour;
        if isrc_window_object(async_graphic_panel) then
        ;;; incase current window object has been changed
            async_graphic_panel -> rc_current_window_object
        endif;
    endif;
enddefine;

define ask_colour();
    true -> do_pause;
    rc_set_colour(
        rc_getinput(250, 250,
            ['Please type a colour name'],
            'black',
             [{width 80}{font '9x15'}{align centre}],
            'Select Colour'));
enddefine;


define make_colour_panel();
    ;;; set up a control panel to specify next colour

    dlocal rc_in_event_handler = true;

    define :menu make_colour_panel;
        'NEXT COLOUR'
        {10 10}
		{width 80}
        {cols 6}
        {bg 'white'}
        {fg 'black'}
        'Choose next colour:'
        ['Red' [POPNOW rc_set_colour('red')]]
        ['Orange' [POPNOW rc_set_colour('orange')]]
        ['Yellow' [POPNOW rc_set_colour('yellow')]]
        ['Green' [POPNOW rc_set_colour('green')]]
        ['Darkgreen' [POPNOW rc_set_colour('darkgreen')]]
        ['Blue' [POPNOW rc_set_colour('blue')]]
        ['Navy' [POPNOW rc_set_colour('navy')]]
        ['Brown' [POPNOW rc_set_colour('brown')]]
        ['Pink' [POPNOW rc_set_colour('pink')]]
        ['Grey30' [POPNOW rc_set_colour('grey30')]]
        ['Grey70' [POPNOW rc_set_colour('grey70')]]
        ['AskUser*' ask_colour()]
    enddefine;

	menu_make_colour_panel -> async_colour_panel;
enddefine;

define startup();
    ;;; Make sure the graphical display happens only in the intended
    ;;; window
    dlocal do_pause;
    ;;; Create a new window if nececessary

    if isrc_window_object(async_graphic_panel)
    and xt_islivewindow(rc_widget(async_graphic_panel))
    then
        async_graphic_panel -> rc_current_window_object;
    else
        rc_new_window_object(200,200,400,400, true,'async_graphic')
            -> async_graphic_panel;
    endif;


    ;;; The next variable can be made false by the STOP button
    dlocal do_stop = false, do_finish = false;

    until do_stop do
    rc_restart();
        XpwSetColor(rc_window, current_colour) ->;
        ;;; Print the name on the graphic window
        control_procedure>< nullstring
            -> rc_window_title(async_graphic_panel);
        rc_window_sync();
        ;;; if this is made true, central loop will exit
        false -> do_pause;
        recursive_valof(control_procedure)();
    enduntil;
    if do_finish then
        if graphic_live() then
            rc_kill_window_object(async_graphic_panel);
            false -> async_graphic_panel;
        endif
    endif;
enddefine;


define restart(proc);
    true -> do_pause;
    proc -> control_procedure;
enddefine;



pr('\nplease type:\n   menu_go();\n');

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, 5 Sep 1999
	Further tidied
--- Aaron Sloman, Aug 11 1999
	replaced with TEACH RC_ASYNC_DEMO stuff

         CONTENTS - (Use <ENTER> g to access required sections)

 define graphic_live() -> boole;
 define menu_go();
 define rc_restart();
 define do_delay();
 define rc_draw_box(x,y,width, height);
 define multi_box();
 define multi_line();
 define polyspi(side, inc, ang, num);
 define multi_poly();
 define rc_demo_square(side);
 define multi_square();
 define rc_set_colour(string);
 define ask_colour();
 define make_colour_panel();
 define startup();
 define restart(proc);

 */
