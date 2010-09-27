/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/brait/lib/source_object.p
 > Purpose:         source object definition
 > Author:          Duncan K Fewkes, Dec 3 1999 (see revisions)
 > Documentation:
 > Related Files:
 */

/*

         CONTENTS - (Use <ENTER> gg to access required sections)

 define: class source; is sim_movable sim_object;
 define:method sim_run_sensors(s:source, object_list) -> sensor_data;
 define create_source( coord_x, coord_y, source_specs
 define create_simple_source(coord_x, coord_y, type)-> newsource;
 define:method draw_source_spreading(obj:sim_object);

*/


define: class source; is sim_movable sim_object;


    slot rc_picx;        ;;; Location information
    slot rc_picy;

    slot Radius;

    slot source_info;
    ;;; This will be a list identical to that in the vehicle agent's
    ;;; source_info slot. i.e.
    ;;; Each entry in this list represents a stimulus - that is detectable by
    ;;; VEHICLE SENSORS - that the source is producing. Each entry consists of
    ;;; the stimulus type, strength, decay function (i.e. how the strength
    ;;; changes over distance) and a value that configures the decay function.

    ;;; NB strength is a value between 0 and 100.

    slot destroyability = 0;
    ;;; This will be 0 when it is indestructable or destroyability in the
    ;;; simulator is turned off. When it is on, this slot will hold a value
    ;;; for the minimum momentum (speed*mass) needed to destroy it.

    slot sim_status = [active];

    slot sim_name;
    slot rc_pic_lines;
    slot pic_name = sim_name;
    slot sim_setup_done = false;

enddefine;

/*
METHOD   : sim_run_sensors (object, object_list) -> sensor_data
INPUTS   : object, object_list
  Where  :
    object is a source object
    object_list is the list of all of the current objects and agents running
        in the simulator
OUTPUTS  : sensor_data is the sensory input data for the object
USED IN  : sim_scheduler
CREATED  : 21 Jan 2000
PURPOSE  : to make sure that the source objects are not getting any sensory
            input.

TESTS:

*/



define:method sim_run_sensors(s:source, object_list) -> sensor_data;

    [] -> sensor_data;

enddefine;


/*
PROCEDURE: create_source (coord_x, coord_y, source_specs) -> newsource
INPUTS   : coord_x, coord_y, source_specs
  Where  :
    coord_x is the x coordinate of the source
    coord_y is the y coordinate of the source
    source_specs is a list of the source types and strengths etc. that this
        source gives out. (NB Usually more than one source-type for each
        source. e.g. lightbulb gives out lots of light, plenty of heat and
        maybe a little smell?!)
OUTPUTS  : newsource is a source object
USED IN  : sim_scheduler
CREATED  : 17 Jan 2000
PURPOSE  : To create new instances of source objects as specified.

TESTS:

create_source( 150, 150, [[light 100 %exponential_decay% 20]]) -> source;
source ==>;
source_info(source)==>;



*/


define create_source( coord_x, coord_y, source_specs
        )-> newsource;

    lvars source, piclines = [], picture_extent =0, name= gensym("source"), radiu;

    /********** MAKE SURE STRENGTH IS BETWEEN 0 AND 100  ************/

    for source in source_specs do

        ;;;source==>; ;;; debug
        if source(2) > 100 then
            100 -> source(2);
        elseif source(2) < 0 then
            0 -> source(2);
        endif;


        /********** MAKE SURE CONFIGURE IS DECIMALISED  ************/


        if isinteger(source(4)) then
            source(4) + 0.00 -> source(4);
        endif;


        /********** MAKE SURE FUNCTION NAME IS A PROCEDURE_KEY  ************/


        if (not(isprocedure(recursive_valof(source(3))))) then
            [DECAY FUNCTION NOT RECOGNISED]==>;
            return(false);
        endif;

        if ((source(2))/4) > picture_extent then
            ((source(2))/4) -> picture_extent;
        endif;

        piclines <> [[COLOUR %decide_colour(source)%
                CIRCLE {0 0 %(source(2))/4%} ] ] -> piclines;


    endfor;

    ;;;piclines==>; ;;;debug


    instance source

        sim_x = coord_x;
        sim_y = coord_y;
        Radius = picture_extent;
        source_info = source_specs;
        rc_pic_lines = piclines;
        sim_name = name;

        rc_mouse_limit = picture_extent;

    endinstance -> newsource;

    ;;;sim_set_coords(newsource, coord_x, coord_y);


    if isundef(brait_world) or not(xt_islivewindow(rc_widget(brait_world))) then
        create_window(500,500);
    endif;

    unless sim_running then
        show_and_name_instance(name, newsource, brait_world);
        endunless


enddefine;


/*
PROCEDURE: create_simple_source (coord_x, coord_y, type) -> newsource
INPUTS   : coord_x, coord_y, type
  Where  :
    coord_x is x coord
    coord_y is y coord
    type is stimulus type
OUTPUTS  : newsource is the new source object
USED IN  :
CREATED  : 21 Jul 2000
PURPOSE  : shortcuut for creating sources

TESTS:

*/

define create_simple_source(coord_x, coord_y, type)-> newsource;

    create_source( coord_x, coord_y, [[^type 100 exponential_decay 100]])
        -> newsource;

enddefine;


/*
METHOD   : draw_source_spreading (obj)
INPUTS   : obj is a vehicle or source
OUTPUTS  : to main graphical screen
USED IN  :
CREATED  : 24 Mar 2000
PURPOSE  : show the spread of source stimulus (with contours, i.e. draw a
    circle every drop of 10 units of stimulus strength).

TESTS:

*/

define:method draw_source_spreading(obj:sim_object);


    lvars diameter = 0.1, item, count = 10;

    ;;;XpwSetColor(rc_window, 'red');
    1 -> rc_linewidth;

    for item in source_info(obj) do
        XpwSetColor(rc_window, decide_colour(item) );

        repeat 10 times
            until round(item(3)(diameter, item(2), item(4))) = (count*10) do
                diameter + 0.1 -> diameter;
            enduntil;

            rc_draw_arc(sim_x(obj)-(diameter/2), sim_y(obj)+(diameter/2), diameter, diameter, 0, 360*64);
            count -1 -> count;
        endrepeat;
    endfor;


enddefine;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Dec 23 2000
	Renamed file as source_object.p
--- Aaron Sloman, Oct  8 2000
	Fixed header and introduced "define" index

--- Duncan K Fewkes, Aug 30 2000
converted to lib format
 */
