/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/brait/lib/ball_object.p
 > Purpose:         Ball object definition - to be pushed around in brait_sim
 > Author:          Duncan K Fewkes, Aug 11 2000 (see revisions)
 > Documentation:
 > Related Files:
 */

/*

 -- create_ball
 -- MAKE SURE STRENGTH IS BETWEEN 0 AND 100
 -- MAKE SURE CONFIGURE IS DECIMALISED
 -- MAKE SURE FUNCTION NAME IS A PROCEDURE_KEY
 -- BALL METHODS
 -- move_ball
 -- CALCULATE STEP VALUE
 -- COLLISION CHECKING!
 -- GO FOR IT !!
 -- CONCERNING WALLS
 -- IF WALLS ARE UPRIGHT OR FLAT
 -- AND THEN THE OTHER OBJECTS
 -- CONVERT ARCTAN VALUES TO REAL DIRECTIONS
 -- CALCULATE DIRECTION OF TRAVEL RELATIVE TO OBJECT
 -- FIND NEAREST COLLISION
 -- BALL RULESYSTEM
 -- LIST OF PROCEDURES, ETC.

*/
/*
CLASS    : ball_object
CREATED  : 11 Aug 2000
PURPOSE  : to be knocked and bounced around in simulator

*/

define: class ball_object; is sim_movable sim_object;

    slot Diameter;
    slot Radius;

    slot rc_picx;        ;;; Location information
    slot rc_picy;

    slot sim_rulesystem = ball_rulesystem;
                        ;;; this rulesystem will handle bounce collisions.

    slot heading =0;
    slot speed = 0;

    slot impulse = 0;
    ;;; = the added speed a vehicle has given to the ball.

    slot bounciness = 0.6;
                        ;;; multiplier for ball speed after impacts

    slot source_info;
    ;;; This will be a list identical to that in the vehicle agent's
    ;;; source_info slot. i.e.
    ;;; Each entry in this list represents a stimulus - that is detectable by
    ;;; VEHICLE SENSORS - that the source is producing. Each entry consists of
    ;;; the stimulus type, strength, decay function (i.e. how the strength
    ;;; changes over distance) and a value that configures the decay function.

    ;;; NB strength is a value between 0 and 100.

    slot sim_status = [ball];

    slot sim_name;
    slot rc_pic_lines;
    slot pic_name = sim_name;
    slot sim_setup_done = false;

enddefine;




/*
METHOD   : sim_run_sensors (object, object_list) -> sensor_data
INPUTS   : object, object_list
  Where  :
    object is a ball object
    object_list is the list of all of the current objects and agents running
        in the simulator
OUTPUTS  : sensor_data is the sensory input data for the object
USED IN  : sim_scheduler
CREATED  : 11 Aug 2000
PURPOSE  : to make sure that the source objects are not getting any sensory
            input.

TESTS:

*/



define:method sim_run_sensors(b:ball_object, object_list) -> sensor_data;

    [] -> sensor_data;

enddefine;

/*
-- create_ball --------------------------------------------------------
*/

/*
PROCEDURE: create_ball (coord_x, coord_y, size, source_specs) -> newball
INPUTS   : coord_x, coord_y, size, source_specs
  Where  :
    coord_x is the intial x coordinate of the ball
    coord_y is the inital y coordinate of the ball
    size is the diameter of the ball
    source_specs is a list of the source types and strengths etc. that the
        ball gives out.
OUTPUTS  : newball is a ball object
USED IN  : sim_scheduler
CREATED  : 11 Aug 2000
PURPOSE  : To create new instances of ball objects as specified.

TESTS:

create_ball( 100, 100,  200, [] )-> ball1;

*/




define create_ball( coord_x, coord_y, size, source_specs
        )-> newball;

    lvars source, piclines = [], picture_extent, name= gensym("ball");
/*
-- MAKE SURE STRENGTH IS BETWEEN 0 AND 100 ----------------------------
*/
    if null(source_specs) then
        [[COLOUR 'black' CIRCLE {0 0 %size/2%} ] ] -> piclines;
        size/2 -> picture_extent;
    else
    for source in source_specs do

        ;;;source==>; ;;; debug
        if source(2) > 100 then
            100 -> source(2);
        elseif source(2) < 0 then
            0 -> source(2);
        endif;

/*
-- MAKE SURE CONFIGURE IS DECIMALISED ---------------------------------
*/

        if isinteger(source(4)) then
            source(4) + 0.00 -> source(4);
        endif;

/*
-- MAKE SURE FUNCTION NAME IS A PROCEDURE_KEY -------------------------
*/

        if (not(isprocedure(recursive_valof(source(3))))) then
            [DECAY FUNCTION NOT RECOGNISED]==>;
            return(false);
        endif;

        if (size/2) > picture_extent then
            (size/2) -> picture_extent;
        endif;

        piclines <> [[COLOUR %decide_colour(source)%
                CIRCLE {0 0 %size/2%} ] ] -> piclines;


    endfor;
    endif;


;;;piclines==>; ;;;debug


    instance ball_object

        Diameter = size;
        Radius = size/2;

        sim_x = coord_x;
        sim_y = coord_y;
        source_info = source_specs;
        rc_pic_lines = piclines;
        sim_name = name;

        rc_mouse_limit = picture_extent;

    endinstance -> newball;

    if isundef(brait_world) or not(rc_islive_window_object(brait_world)) then
        create_window(500,500);
    endif;

    unless sim_running then
        show_and_name_instance(name, newball, brait_world);
    endunless


enddefine;


/*
PROCEDURE: create_simple_ball (coord_x, coord_y, type) -> newball
INPUTS   : coord_x, coord_y, type
  Where  :
    coord_x is the intial x coord
    coord_y is the intial y coord
    type is the stimulus type of the ball
OUTPUTS  : newball is a ball object
USED IN  :
CREATED  : 12 Aug 2000
PURPOSE  : to give an easier method of creating ball objects that emit a
certain type of stimulus.


TESTS:

*/

define create_simple_ball(coord_x, coord_y, type)-> newball;

create_ball( coord_x, coord_y, 150, [[%consword(type)% 100 exponential_decay 200]])
-> newball;

enddefine;

/*
-- BALL METHODS -------------------------------------------------------

-- move_ball ----------------------------------------------------------
*/


/*
METHOD   : move_ball (me)
INPUTS   : me is a ball object
OUTPUTS  : NONE
USED IN  : ball rulesystem
CREATED  : 11 Aug 2000
PURPOSE  : to calculate the ball's path, check it for collisions, if any are
found - calculate the bounce angle (ball's new heading) and new speed, then
move the ball to where it should be.

TESTS:

*/

define:method move_ball(me:ball_object);

    lvars forward_dist,
        direction = heading(me),
        m = tan(direction),                       ;;;the gradient of the path
        c = sim_y(me) - (sim_x(me) * m),        ;;;the C in 'y = Mx + C'
        radius = Radius(me);
    lvars possible = [], x, y, dist, distances_to = [], compare, count, object,
        bounce_angles = [],
        stepper, start_val, end_val, step_value, checking;
    lvars vertex, wallx1, wallx2, wally1, wally2,
        direction_from_object, direction_to_object,
        planx, plany, newx, newy;


if direction < 0 then
    direction + 360 ->> direction -> heading(me);
elseif direction > 360 then
    direction - 360 ->> direction -> heading(me);
endif;

if [being_carried] isin sim_status(sim_myself) then
    ;;;if being carried do nothing!
else

    if impulse(me) > 0 then
        impulse(me) -> speed(me);
        0 -> impulse(me);
    endif;

    speed(me) * time_slice_duration -> forward_dist;

    (cos(direction) * forward_dist) + sim_x(me) -> planx;
    (sin(direction) * forward_dist) + sim_y(me)-> plany;
/*
-- CALCULATE STEP VALUE -----------------------------------------------
*/
    sqrt( ((sim_x(me)-planx) **2) + ((sim_y(me)-plany) **2)) -> dist;

    if dist < 50 then
        1 -> step_value;
    else
        round((dist*4)/100) -> step_value;
    endif;

    ;;;[dist ^dist]==>;
    ;;;[step_value ^step_value]==>;
/*
-- COLLISION CHECKING! ------------------------------------------------
*/
    if m <= 1 and m >= -1 then
        ;;; iterate check along x-axis
        sim_x(me) -> start_val;
        planx -> end_val;
        "x" -> checking;
    else
        ;;; iterate check along y-axis
        sim_y(me) -> start_val;
        plany -> end_val;
        "y" -> checking;
    endif;

    if heading(me) < 315 and heading(me) >= 135 then
        -step_value -> step_value;
    endif;
/*
-- GO FOR IT !! -------------------------------------------------------
*/

    for object in sim_objects do
        if object /== me then


            for stepper from start_val by step_value to end_val do

                if checking == "x" then
                    stepper -> x;
                    (m*x) + c -> y;
                elseif checking == "y" then
                    stepper -> y;
                    (y-c)/m  -> x;
                endif;


                ;;;[STEPPER %stepper%] ==>; ;;;debug
/*
-- CONCERNING WALLS ---------------------------------------------------
*/
                if isbox(object) then

                    for vertex from 1 to length(vertices(object)) do
                        ;;; for each wall do ...

                        if vertex = length(vertices(object)) then
                            min(vertices(object)(vertex)(1), vertices(object)(1)(1)) -> wallx1;
                            max(vertices(object)(vertex)(1), vertices(object)(1)(1)) -> wallx2;
                            min(vertices(object)(vertex)(2), vertices(object)(1)(2)) -> wally1;
                            max(vertices(object)(vertex)(2), vertices(object)(1)(2)) -> wally2;
                        else
                            min(vertices(object)(vertex)(1),vertices(object)(vertex+1)(1)) -> wallx1;
                            max(vertices(object)(vertex)(1), vertices(object)(vertex+1)(1)) -> wallx2;
                            min(vertices(object)(vertex)(2),vertices(object)(vertex+1)(2)) -> wally1;
                            max(vertices(object)(vertex)(2),vertices(object)(vertex+1)(2)) -> wally2;
                        endif;

/*
-- IF WALLS ARE UPRIGHT OR FLAT ---------------------------------------
*/

                        if wallx1 = wallx2 then
                            ;;;wall is upright!
                            if x < wallx1 and x > (wallx1 - radius)
                            and y> wally1
                            and y< wally2
                            and (direction < 90 or direction > 270) then
                                ;;;check for corner
                                if (y < wally1
                                    and direction > 270)
                                or (y > wally2
                                    and direction < 90) then

                                else
                                    ;;;ball bumped it!
                                    possible <> [^stepper] -> possible;
                                    distances_to <> [%sqrt((x - sim_x(me))**2 + (y-sim_y(me))**2)%]
                                        -> distances_to;
                                    if direction < 90 then
                                        [^^bounce_angles %(180 - direction)%]  -> bounce_angles;
                                    else
                                        [^^bounce_angles %(540 - direction)%] -> bounce_angles;
                                    endif;
                                    if round(x) = round(sim_x(me))
                                    and round(y) = round(sim_y(me)) then
                                        quitloop(3);
                                    endif;
                                endif;

                            elseif x > wallx1 and x < (wallx1 + radius)
                            and y> wally1
                            and y< wally2
                            and (direction <270  and direction > 90) then
                                ;;;check for corner
                                if (y < wally1
                                    and direction > 180)
                                or (y > wally2
                                    and direction < 180) then

                                else
                                    ;;;vehicle bumped it!
                                    possible <> [^stepper] -> possible;
                                    distances_to <> [%sqrt((x - sim_x(me))**2 + (y-sim_y(me))**2)%]
                                        -> distances_to;
                                    if direction < 180 then
                                        [^^bounce_angles %(180 - direction)%]  -> bounce_angles;
                                    else
                                        [^^bounce_angles %(540 - direction)%] -> bounce_angles;
                                    endif;
                                    if round(x) = round(sim_x(me))
                                    and round(y) = round(sim_y(me)) then
                                        quitloop(3);
                                    endif;
                                endif;
                            endif;

                        elseif wally1 = wally2 then
                            ;;;wall is horizontal!
                            if y < wally1 and y > (wally1 - radius)
                            and x> wallx1
                            and x<  wallx2
                            and (direction < 180 and direction > 0) then
                                ;;;check for corner
                                if (x < wallx1
                                    and direction > 90)
                                or (x > wallx2
                                    and direction < 90) then

                                else
                                    ;;;vehicle bumped it!
                                    possible <> [^stepper] -> possible;
                                    distances_to <> [%sqrt((x - sim_x(me))**2 + (y-sim_y(me))**2)%]
                                        -> distances_to;
                                    [^^bounce_angles %(360-direction)%] -> bounce_angles;
                                    if round(x) = round(sim_x(me))
                                    and round(y) = round(sim_y(me)) then
                                        quitloop(3);
                                    endif;
                                endif;

                            elseif y > wally1 and y < (wally1 + radius)
                            and x> wallx1
                            and x< wallx2
                            and (direction > 180 and direction < 360) then
                                ;;;check for corner
                                if (x < wallx1
                                    and direction < 270)
                                or (x > wallx2
                                    and direction > 270) then
                                else
                                    ;;;vehicle bumped it!
                                    possible <> [^stepper] -> possible;
                                    distances_to <> [%sqrt((x - sim_x(me))**2 + (y-sim_y(me))**2)%]
                                        -> distances_to;
                                    [^^bounce_angles %(360-direction)%] -> bounce_angles;
                                    if round(x) = round(sim_x(me))
                                    and round(y) = round(sim_y(me)) then
                                        quitloop(3);
                                    endif;
                                endif;
                            endif;
                        endif;
                    endfor;
/*
-- AND THEN THE OTHER OBJECTS -----------------------------------------
*/
                else
                    sqrt((x - sim_x(object))**2 + (y-sim_y(object))**2)
                        -> dist;

                    if sim_x(object) = x then
                        if sim_y(object)>y then
                            90 -> direction_to_object;
                        else
                            270 -> direction_to_object;
                        endif;
                    elseif sim_y(object) = y then
                        if sim_x(object)>x then
                            0 -> direction_to_object;
                        else
                            180 -> direction_to_object;
                        endif;
                    else
                        arctan( (sim_y(object)-y)/(sim_x(object)-x) )
                            -> direction_to_object;
/*
-- CONVERT ARCTAN VALUES TO REAL DIRECTIONS ---------------------------
*/
                        if sim_x(object) < x then
                            direction_to_object + 180 -> direction_to_object;
                        elseif sim_x(object) > x and sim_y(object) < y then
                            direction_to_object + 360 -> direction_to_object;
                        endif;
                    endif;

/*
-- CALCULATE DIRECTION OF TRAVEL RELATIVE TO OBJECT -------------------
*/
                    direction - (direction_to_object - 90)
                        -> direction_from_object;

                    if direction_from_object < 0 then
                        direction_from_object + 360 -> direction_from_object;
                    elseif direction_from_object > 360 then
                        direction_from_object - 360 -> direction_from_object;
                    endif;


                    ;;;[DIST = %dist%]==>; ;;;debug
                    ;;;[DIRECTION TO %object% =  %direction_to_object%] ==>; ;;;debug
                    ;;;[Dir relative to %object% = %direction_from_object%]==>;;;;debug



                    if isvehicle(object) then

                        ;;;[VEHICLE DIST = %dist%]==>; ;;;debug
                        if  dist < (radius + (Diagonal(object)/2))
                        and direction_from_object < 180
                        and direction_from_object > 0
                        then
                            ;;;there is a vehicle collision on the cards!
                            possible <> [^stepper] -> possible;
                            distances_to <> [%sqrt((x - sim_x(me))**2 + (y-sim_y(me))**2)%]
                                -> distances_to;

                            bounce_angles <> [%(360-direction_from_object)
                            + (direction_to_object -90 )%] -> bounce_angles;

                            if round(x) = round(sim_x(me))
                            and round(y) = round(sim_y(me)) then
                                quitloop(2);
                            endif;
                        endif;


                    elseif issource(object) then

                        ;;;[SOURCE DIST = %dist%]==>; ;;;debug
                        if dist < (radius + (Radius(object)))
                        and direction_from_object < 180
                        and direction_from_object > 0 then
                            ;;;there is a source in the way!
                            possible <> [^stepper] -> possible;
                            distances_to <> [%sqrt((x - sim_x(me))**2 + (y-sim_y(me))**2)%]
                                -> distances_to;

                            bounce_angles <> [%(360-direction_from_object)
                            + (direction_to_object -90 )%] -> bounce_angles;

                            if round(x) = round(sim_x(me))
                            and round(y) = round(sim_y(me)) then
                                quitloop(2);
                            endif;
                        endif;

                    elseif isball_object(object) then

                        ;;;[BALL DIST = %dist%]==>; ;;;debug
                        if dist < (radius + (Radius(object)))
                        and direction_from_object < 180
                        and direction_from_object > 0 then
                            ;;;there is a ball in the way!
                            possible <> [^stepper] -> possible;
                            distances_to <> [%sqrt((x - sim_x(me))**2 + (y-sim_y(me))**2)%]
                                -> distances_to;

                            bounce_angles <> [%(360-direction_from_object)
                            + (direction_to_object -90 )%] -> bounce_angles;

                            if round(x) = round(sim_x(me))
                            and round(y) = round(sim_y(me)) then
                                quitloop(2);
                            endif;
                        endif;

                    endif;
                endif;
            endfor;
        endif;
    endfor;
/*
-- FIND NEAREST COLLISION ---------------------------------------------
*/
    ;;;possible ==>;;;;debug
    ;;;distances_to ==> ;;;;debug

    if null(possible) then
        ;;;no obstructions

    elseif length(possible) = 1 then
        ;;;one obstruction
        if checking == "x" then
            hd(possible) -> planx;
            (m * planx) + c -> plany;
            bounce_angles(1) -> heading(me);

        elseif checking == "y" then
            hd(possible) -> plany;
            (plany- c) /m -> planx;
            bounce_angles(1) -> heading(me);
        endif;

        speed(me) * bounciness(me) -> speed(me);
    else
        ;;;more than one obstruction, find closest one.
        for dist from 1 to length(distances_to) do
            0 -> count;
            for compare from 1 to length(distances_to) do
                if distances_to(dist) <= distances_to(compare) then
                    count+1 -> count;
                endif;
            endfor;
            if count = length(distances_to) then
                if checking == "x" then
                    possible(dist) -> planx;
                    (m * planx) + c -> plany;
                    bounce_angles(dist) -> heading(me);
                elseif checking == "y" then
                    possible(dist) -> plany;
                    (plany- c) /m -> planx;
                    bounce_angles(dist) -> heading(me);
                endif;

                speed(me) * bounciness(me) -> speed(me);

            endif;
        endfor;
    endif;
endif;

if impulse(me) > 0 then
    impulse(me) -> speed(me);
    0 -> impulse(me);
endif;

sim_move_to(me, planx, plany, true);

enddefine;

/*
-- BALL RULESYSTEM ----------------------------------------------------
*/

/*
RULESYSTEM: ball_rulesystem
CREATED  : 11 Aug 2000
PURPOSE  : siply moves the ball each cycle.

*/


define :rulesystem ball_rulesystem;
    [DLOCAL [prb_allrules = true]];

include: movement

enddefine;



define :ruleset movement;

    RULE move
        ==>
    [POP11 move_ball(sim_myself);]

enddefine;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Dec 24 2000
	replaced 'x' and 'y' with "x" and "y", and = with ==

--- Aaron Sloman, Dec 23 2000
	Renamed file as ball_object.p

--- Aaron Sloman, Oct  8 2000

	added index, and replaced largest with max, smallest with min.

--- Duncan K Fewkes, Aug 30 2000
	converted to lib format

-- LIST OF PROCEDURES, ETC.

CONTENTS - (Use <ENTER> gg to access required sections)

 define: class ball_object; is sim_movable sim_object;
 define:method sim_run_sensors(b:ball_object, object_list) -> sensor_data;
 define create_ball( coord_x, coord_y, size, source_specs
 define create_simple_ball(coord_x, coord_y, type)-> newball;
 define:method move_ball(me:ball_object);
 define :rulesystem ball_rulesystem;
 define :ruleset movement;

 */
