/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/brait/lib/vehicle_agent.p
 > Purpose:         vehicle agent definition
 > Author:          Duncan K Fewkes, Dec 3 1999 (see revisions)
 > Documentation:
 > Related Files:
 */

/*


         CONTENTS - (Use <ENTER> g to access required sections)

 -- VEHICLE RULESYSTEM
 -- CLASS VEHICLE DEFINITION
 -- FIRST, Morphology:
 -- SECOND, Movement:
 -- THIRD, Matrices;
 -- FOURTH, Sensors:
 -- FIFTH, user controller procedure output slots
 -- SEVENTH, Data-logging slots
 -- SEVENTH, Miscellaneous;

 -- TOOL METHODS
 -- METHOD   : print_vehicle_data_log (me)
 -- METHOD   : randomise_position (o, coord_limits)
 -- METHOD   : draw_activation_graph (v, node_trac_list, values_list, trace_colour)
 -- PROCEDURE: create_trace_windows (start_x, start_y, wlength)
 -- METHOD   : draw_vehicle_plus_sensors (v, x_loc, y_loc)
 -- METHOD   : display_vehicle_activity (v, activity_list)
 -- PROCEDURE   : normalise_list (list) -> list

 -- METHODS

 -- METHOD   : sim_run_sensors (v, sim_objects) -> sensor_data
 -- FOR ODOMETER OR COMPASS
 -- FOR THE PROXIMITY SENSORS
 -- FOR WALLS (NB - UPRIGHT OR FLAT)
 -- FOR OTHER OBJECTS
 -- CALCULATE THE DISTANCE BETWEEN SENSOR AND SOURCE
 -- ANY OTHER SENSORS
 -- CALCULATE THE DISTANCE BETWEEN SENSOR AND SOURCE
 -- CALCULATE STIMULUS STRENGTH FROM SOURCE AT THIS DISTANCE
 -- ADD THIS VALUE TO ANY OTHER VALUES FROM SIMILAR SOURCES AND CLOSE ALL LOOPS

 -- METHOD   : matrix_processing (v)
 -- EXTRACT SENSOR AND UNIT OUTPUTS DATA FROM DATABASE
 -- INSERT SENSOR DATA INTO UNIT INPUTS LIST
 -- NOW MULTIPLY UNIT INPUTS WITH ACTIVATION FUNCTIONS TO GET UNIT OUTPUTS.
 -- MULTIPLY UNIT OUTPUTS INTO LINK WEIGHT MATRIX TO GET UNIT INPUTS
 -- CHECK NO UNIT INPUT IS >100 OR <0
 -- Do unit input and output tracing if necessary
 -- FINALLY, ADD NEW UNIT INPUTS + OUTPUT LISTS INTO INTERNAL DATABASE

 -- METHOD   : plan_move_vehicle (vehicle, left_motor_input, right_motor_input)
 -- CALCULATE DIST MOVED BY EACH WHEEL
 -- FORWARD DIST MOVED IS average OF THESE TWO
 -- CALCULATE HEADING CHANGE AND X AND Y CHANGE
 -- INSERT PLANNED MOVE INTO DATABASE
 -- UPDATE VEHICLE'S DATA-LOG

 -- METHOD   : check_path_for_obstruction (me, sim_objects, planx, plany, planheading)
 -- CALCULATE STEP VALUE
 -- FIND WHICH AXIS TO CHECK ALONG
 -- GO FOR IT !!
 -- CONCERNING WALLS
 -- IF WALLS ARE UPRIGHT OR FLAT
 -- AND THEN THE OTHER OBJECTS
 -- CONVERT ARCTAN VALUES TO REAL DIRECTIONS
 -- CALCULATE DIRECTION OF TRAVEL RELATIVE TO OBJECT
 -- FIND NEAREST COLLISION
 -- CALCULATE NEW SPEED
 -- UPDATE DATA-LOG SLOTS

 -- PROCEDURE: create_vehicle (vlength, width, coord_x, coord_y, direction, link_wt_matrix, act_function_matrix, sensor_list, vehicle_sourcing, motor_left, motor_right) -> newvehicle
 -- CHECK PARITY OF MATRIX AND ACT. FUNCTIONS LISTS
 -- SENSOR CHECKS
 -- CALCULATE SENSOR LOCATIONS IF SHORTHAND IS USED
 -- MAKE SURE SENSOR SENSITIVITY IS BETWEEN 1 AND ZERO
 -- SOURCE CHECKS
 -- MAKE SURE STRENGTH IS BETWEEN 0 AND 100
 -- MAKE SURE CONFIGURE IS DECIMALISED
 -- MAKE SURE FUNCTION NAME IS A PROCEDURE_KEY
 -- ACTIVATION FUNCTION CHECKS
 -- if null list given, make all [basic_unit]
 -- MAKE SURE FUNCTION NAME IS A PROCEDURE_KEY
 -- CREATE FIRST UNIT OUTPUTS LIST
 -- CALCULATE COLOUR OF VEHICLE AND PICLINES
 -- CREATE INSTANCE

 -- VEHICLE RULESYSTEM

 -- REVISION NOTES
 -- LIST OF PROCEDURES, CLASS DEFINITIONS, METHODS ETC


-- VEHICLE RULESYSTEM

*/
/*
-- CLASS VEHICLE DEFINITION -------------------------------------------
*/

/*
CLASS    : vehicle
CREATED  : 14 Jan 2000
PURPOSE  : for use in simulator

*/



define:class vehicle; is rc_rotatable; is sim_movable_agent;

/*********

-- FIRST, Morphology: -------------------------------------------------
slots that define the general morphology of the vehicle

    **********/

    slot Length;
    slot Width;
    slot Diagonal;  ;;; This will be calculated by the vehicle creation
                    ;;; procedure and is included to reduce calculations during
                    ;;; runtime.

    slot left_wheel_diameter = 80;
    slot right_wheel_diameter = 80;
                    ;;; These will be a certain default until procedures
                    ;;; created to alter them at creation or editing.

    slot max_rps_left_motor = 20;
    slot max_rps_right_motor = 20;
                    ;;;may be used later if want to model motor function more
                    ;;; accurately(?) or give user more control over vehicle
                    ;;; specs.


/**********

-- SECOND, Movement: --------------------------------------------------
slots that define the location and direction of the vehicle

    **********/

    slot sim_x;
    slot sim_y;
    slot rc_picx;   ;;; Co-ordinates of the CENTRE of the vehicle
    slot rc_picy;   ;;; NB also sim_x and sim_y, inherent in sim_agent class
    slot heading = 0;
                    ;;; NB. This is measured in degrees counter-clockwise from
                    ;;; the x axis (which will be the 3 O'clock position.

    /**********

-- THIRD, Matrices; ---------------------------------------------------
for the storage and processing of sensor-motor links and threshold devices.
The second matrix stores the activation function for the corresponding
threshold unit.

**********/


    slot link_weight_matrix;

    ;;; This will be an (m+p+2) * (m+p+2) matrix; where m = the no. of sensors
    ;;;                                                 p = the no. of logic
    ;;;                                                     units requested
    ;;;                                         and the 2 = outputs to motors
    ;;; OR (m+p+1+2) where the 1 is the output to hand

    ;;; Links are specified by a value in the matrix, the value being the
    ;;; weighting of the link. Counting down a column (i.e. the row number),
    ;;; represents the source of the link and counting across a row (i.e. the
    ;;; column number) represents the target of each link.
    ;;;     e.g. a VALUE in row 5 column 4 is the WEIGHT for the link from
    ;;;         unit 5 to unit 4.

    ;;; NB. The first m units are the sensors on the vehicle. Thus, the first
    ;;; m columns should be empty (as the sensors do not take inputs from any
    ;;; other units, although this can be investigated).
    ;;;     Also, any value in the first m rows represent (weighted) links from
    ;;; the sensors to the unit of the column that the value is in.

    ;;;  OR IT WILL BE THE USER POP11 CONTROL PROCEDURE - (or a pointer to it)


    slot activation_function_matrix;

    ;;; This will be a  1 * (m+p+2) OR 1 * (m+p+1+2) matrix;  (as above).

    ;;; Each entry will consist of a list function names, each with associated
    ;;; characteristics and bounds. Thus, a complex activation function for a
    ;;; unit can be built up from more simple, general functions; each given
    ;;; the appropriate bounds.

    ;;; e.g. [
    ;;;     [[%straight% 0 x1 config_value1 config2] [%hyperbole% x1 x2 c1 c2]]
    ;;;     [[%straight% 0 x1 c1 c2] [%straight% x1 x2 c1 c2]]
    ;;;      [basic_unit]
    ;;;      [basic_unit]
    ;;;            etc... (one for each unit in the vehicle)
    ;;;      ]

    ;;; NB sensor units (first m units) do not have activation functions.
    ;;; Thus, first m units will be empty/non-functioning.
    ;;; The last two units represent the outputs to the motors (left then
    ;;; right).

    ;;; MAJOR NB!!! function name MUST have an % either side to instantiate
    ;;; a procedure_key instead of a simple word structure (which would then
    ;;; be unusable to call the math function procedures).
    ;;; FIXED

    ;;; Later, this list (or, more accurately: flattened matrix) may be stored
    ;;; in the agent's sim_data slot (internal database) and thus allow the
    ;;; threshold units' activation functions to be changed during runtime
    ;;; (facilitating learning, etc.)
    ;;;     Presently (3 Dec) I have not decided whether to do this or not.

    ;;; NB - IF MATRIX IS REPLACED BY USER PROC. THIS SHOULD BE - 'userproc'


    slot sim_data = prb_newdatabase(sim_dbsize, []);

    ;;; The internal database for the agent. This will contain a list stating
    ;;; the inputs for all of the units in the vehicle. The sensor values will
    ;;; be put into the first m places in this list. The list will then be
    ;;; multiplied with the activation_function_matrix to give the outputs for
    ;;; the units.

    ;;; This will then be multiplied with the link_weight matrix in a certain
    ;;; manner (see matrix_functions.p) that will produce a list of the new
    ;;; unit inputs (to which the sensor inputs are added before the process
    ;;; is repeated).

    ;;; Form for the unit-input and -output lists is:
    ;;; [unit_inputs [ val1 v2 v3 ...]] and [unit_outputs [v1 v2 ...]]

    ;;; Later, this slot may also contain the activation function matrix,
    ;;; along with other things.



    /**********

-- FOURTH, Sensors: ---------------------------------------------------
slots that define the sensors present and also extra slots to enable vehicles
to have attributes that other vehicles can detect.

    NB - All slots are visible to other agents/objects in the simulator,
        depending on their sim_run_sensors method. However, in this simulator,
        any attributes that VEHICLE SENSORS can detect will be held in slot
        source_info.

**********/


    slot sensors = [];
                    ;;; Each sensor is defined by its type and sensitivity
                    ;;; Its location is dictated by distance
                    ;;; and angle from the centre of the vehicle (angle
                    ;;; being anti-clockwise from 12 O'clock on the vehicle).
            ;;; e.g. sensor = [ light     40      15       0.8     ].
            ;;;               [  type, distance, angle, sensitiviy ].

                    ;;; NB vehicle agent creation procedure allows sensor to
                    ;;; defined by type, sensitivity and 'left' or 'right'.

            ;;; NB2 sensitivity is a multiplier and, as such, cannot be greater
            ;;; than 1 or smaller than 0. Having values above or below these
            ;;; would create sensors which amplified input signal or became
            ;;; active in greater absence of appropriate stimulus.
            ;;; I have decided such shenanigans to be silly and shall thus
            ;;; prevent them.
            ;;; If you must do these things, use additional logic units (or
            ;;; hack my code!).


                    ;;; Sensor and source types so far:
                    ;;; light, heat, sound, smell, proximity,

        ;;; NB NEW SENSOR TYPES ADDED - [odometer left], [odometer right],
        ;;; [compass].

    slot source_info;
                    ;;; Each entry in this list represents a stimulus -
                    ;;; that is detectable by VEHICLE SENSORS - that the
                    ;;; vehicle is producing. Each entry consists of the
                    ;;; stimulus type, strength, decay function (i.e. how
                    ;;; the strength changes over distance) and a value
                    ;;; that configures the decay function.

                    ;;; NB strength is a value between 0 and 100.

                ;;;e.g. [light    90     %exponential_decay%     20   ].
                ;;;     [ type, strength,     function,      configure].

    ;;; MAJOR NB!!! function name MUST have an % either side to instantiate
    ;;; a procedure_key instead of a simple word structure (which would then
    ;;; be unusable to call the math function procedures).
    ;;; FIXED


/**********

-- FIFTH, user controller procedure output slots ----------------------
- i.e. user controller procs can output values to these slots and the
simulator will look at them and assign them to units accordingly.

    **********/


    slot left_motor_speed = 0;
    slot right_motor_speed = 0;
    slot hand_activation = 0;


/**********

-- SEVENTH, Data-logging slots ----------------------------------------
- keep track of various attributes of vehicles - useful for user controller
procedures.

    **********/

    slot start_x;          ;;; initial values
    slot start_y;
    slot start_heading;

    slot max_x=0;
    slot min_x=9999;
    slot max_y=0;
    slot min_y=9999;

    slot rotations_left_wheel=0;
    slot rotations_right_wheel=0;

    slot total_dist_moved_by_left_wheel = 0;
    slot total_dist_moved_by_right_wheel = 0;
    slot total_dist_moved_by_vehicle = 0;
    slot total_turn_angle = 0;

    slot heading_relative_to_original = 0;

    slot speed = 0;
    slot max_speed =0;
    slot min_speed =9999;

    slot rate_of_sensor_change = [];
    ;;; NB must be a list because number of sensors on each vehicle can differ

    slot contact_with_boxes =0;
    slot contact_with_sources =0;
    slot contact_with_vehicles =0;
    slot contact_with_balls =0;
    slot contact_total =0;


/**********

-- SEVENTH, Miscellaneous; --------------------------------------------
Any other attributes the vehicle should have that do not fit into the other
categories

    **********/

    slot    sim_name;
    slot    sim_speed = 1;
                    ;;; This is the value for how many times the agent is
                    ;;; 'run' each cycle of sim_scheduler.


    slot    sim_rulesystem = vehicle_rulesystem;
                    ;;; The vehicle's rulesystems. These will be entirely
                    ;;; determinate rules that process the sensor data,
                    ;;; process the link_weight matrix, alter heading and
                    ;;; speed and move the vehicle (which will later
                    ;;; include collision detection and strategy).

                    ;;; also, will call user controller proc if this is specified
                    ;;; in place of link weight matrix


    slot pic_name = sim_name;
    slot rc_pic_lines;
    slot my_trace_colour;
    slot sim_status = [active];
                    ;;; [being_carried]

    slot hand;
                    ;;; [open] or [closed]
    slot hand_range;
    slot hand_threshold = 70;

                                        ;;;tracing stuff
    slot trace_graph_previous_pos=[];
    slot node_trace_list=[];            ;;;modes to trace activity of
    slot trace_windows=[];              ;;; windows to draw activation graphs
    slot trace_sensors = false;         ;;; when true, will update display
                                        ;;; showing sensor and motor activity

    slot sim_setup_done = false;

enddefine;

define :method sim_run_agent(object:vehicle, objects);
	;;; added by A.S.

	;;; dkf added unless call - stops mouse-selected obj's from moving
	returnif(object == rc_mouse_selected(brait_world));

	call_next_method(object, objects);

	;;; this is needed to run events suppressed by motion of vehicles
	false -> rc_in_event_handler;
	rc_run_deferred_events();
enddefine;


/******************************************************************************
-- TOOL METHODS -------------------------------------------------------
*****************************************************************************/

/*
-- METHOD   : print_vehicle_data_log (me) -----------------------------
INPUTS   : me is a vehicle object
OUTPUTS  : prints values in data log slots to output buffer
USED IN  :
CREATED  : 24 Aug 2000
PURPOSE  : utilty procedure - to print values in data log slots to output
            buffer, for checking data-logging is working correctly.

TESTS:

*/

define:method print_vehicle_data_log(me:vehicle);

    npr('');
    npr('Initial values:');
    pr('x = ');npr(start_x(me));
    pr('y = ');npr(start_y(me));
    pr('heading = ');npr(start_heading(me));

    npr('');
    npr('Movement extent:');
    pr('max_x = ');npr(max_x(me));
    pr('min_x = ');npr(min_x(me));
    pr('max_y = ');npr(max_y(me));
    pr('min_y = ');npr(min_y(me));

    npr('');
    npr('Wheel rotations:');
    pr('Left = ');npr(rotations_left_wheel(me));
    pr('Right = ');npr(rotations_right_wheel(me));

    npr('');
    npr('Total distances covered:');
    pr('Left wheel = ');npr(total_dist_moved_by_left_wheel(me));
    pr('Right wheel = ');npr(total_dist_moved_by_right_wheel(me));
    pr('Vehicle total = ');npr(total_dist_moved_by_vehicle(me));

    npr('');
    npr('Heading:');
    pr('Total change = ');npr(total_turn_angle(me));
    pr('Relative to original = ');npr(heading_relative_to_original(me));

    npr('');
    npr('Speed:');
    pr('Current = ');npr(speed(me));
    pr('Max = ');npr(max_speed(me));
    pr('Min = ');npr(min_speed(me));

    npr('');
    npr('Rate of sensor change:');
    pr('Current = ');npr(rate_of_sensor_change(me));

    npr('');
    npr('Contact with:');
    pr('Boxes = ');npr(contact_with_boxes(me));
    pr('Sources = ');npr(contact_with_sources(me));
    pr('Balls = ');npr(contact_with_balls(me));
    pr('Vehicles = ');npr(contact_with_vehicles(me));
    pr('Total = ');npr(contact_total(me));

enddefine;


/*
-- METHOD   : randomise_position (o, coord_limits) --------------------
INPUTS   : o, coord_limits
  Where  :
    o is any object
    coord_limits is a max. value for the x and y coords (min. is 0)
OUTPUTS  : directly updates
USED IN  : some experiments
CREATED  : 11 Mar 2000
PURPOSE  : to randomise the position of an object

TESTS:

*/

define:method randomise_position(o:sim_object, coord_limits);

    sim_move_to(o, random(coord_limits), random(coord_limits), true);
    if isvehicle(o) then
        random(360) -> heading(o);
        rc_set_axis(o, heading(o), true);
    endif;

enddefine;




/*
-- METHOD   : draw_activation_graph (v, node_trac_list, values_list, trace_colour)
INPUTS   : v, node_trac_list, values_list, trace_colour
  Where  :
    v is a vehicle agent
    node_trac_list is the list of nodes to trace
    values_list is a list of the activation levels of each node
    trace_colour is the colour to use (in the old version, which drew blobs)
OUTPUTS  : to trace windows - red line is the unit input, black line is the
                output
USED IN  : tracing
CREATED  : 14 Mar 2000
PURPOSE  : to show the activity of the nodes selected

TESTS:

*/

define:method draw_activation_graph(v:vehicle, node_trac_list, values_list, trace_colour);

    lvars node, y, trace_window_number;

    ;;;trace_windows==>; ;;;debug

    for node from 1 to length(node_trac_list) do
        5+ (values_list(node_trac_list(node))*2) -> y;
        (length(node_trac_list)-node)+1 -> trace_window_number;
        trace_windows(sim_myself)(trace_window_number) -> rc_current_window_object;

        ;;;rc_draw_blob(trace_cycle_number,  values_list(node_trac_list(node))*2, 1, trace_colour);

        if trace_colour = 'red' then
            ;;;rc_drawline(trace_graph_previous_pos(trace_window_number)(1)(1),
             ;;;trace_graph_previous_pos(trace_window_number)(1)(2) , trace_cycle_number,  y);
            rc_draw_blob(trace_cycle_number, y, 1, trace_colour);
            trace_cycle_number -> trace_graph_previous_pos(v)(trace_window_number)(1)(1);
            y -> trace_graph_previous_pos(v)(trace_window_number)(1)(2);

        elseif trace_colour = 'black' then
            rc_drawline(trace_graph_previous_pos(v)(trace_window_number)(2)(1),
              trace_graph_previous_pos(v)(trace_window_number)(2)(2) , trace_cycle_number,  y);
            ;;;rc_draw_blob(trace_cycle_number, y, 1, trace_colour);
            trace_cycle_number -> trace_graph_previous_pos(v)(trace_window_number)(2)(1);
            y -> trace_graph_previous_pos(v)(trace_window_number)(2)(2);

        endif;


        ;;;rc_drawline(rc_xposition, rc_yposition, trace_cycle_number,  y);
        ;;;rc_jumpto(trace_cycle_number, y  );
    endfor;

    brait_world -> rc_current_window_object;

enddefine;





/*
-- PROCEDURE: create_trace_windows (start_x, start_y, wlength) ---------
INPUTS   : start_x, start_y, wlength
  Where  :
    start_x is the window location to start making windows from
    start_y is the window location to start making windows from
    wlength is the length of the window
OUTPUTS  : creates as many windows as are needed (depending on number of nodes
        to be traced
USED IN  : tracing
CREATED  : 14 Mar 2000
PURPOSE  : create the windows in which node tracing will be drawn.

TESTS:

*/

define create_trace_windows(start_x, start_y, wlength);

    vars input_state, output_state, v;


    lvars node, node_name, windo, new_window;

    if not(null(all_trace_windows)) then
        for windo in all_trace_windows do
            rc_kill_window_object(windo);

        endfor;
        [] -> all_trace_windows;
    endif;

    0 -> trace_cycle_number;

    for v in sim_objects do
        if isvehicle(v) and not(null(node_trace_list(v))) then
            for node from 1 to length(node_trace_list(v)) do
                ;;;[Making new window]==>; ;;;debug
                clearproperty(gensym_property);
                repeat node_trace_list(v)(node) times
                    word_string(sim_name(v)) <> ' '<> word_string(gensym(" Node")) -> node_name;
                endrepeat;

                [%rc_new_window_object(start_x, start_y, wlength, 105, {0 105 1 -0.5},
                        node_name <>' Activity: Red=Input, Black=Output', newsim_picagent_window)%]
                    -> new_window;
                new_window <> trace_windows(v) ->  trace_windows(v);
                new_window <> sim_all_windows -> sim_all_windows;
                new_window <> all_trace_windows -> all_trace_windows;

                [[[0 0][0 0]]]<> trace_graph_previous_pos(v) -> trace_graph_previous_pos(v);

                start_y +130 -> start_y;
            endfor;
        endif;
    endfor;

    brait_world -> rc_current_window_object;


enddefine;



/*
NB _OLD _NEEDS UPDATING FOR NEW SENSORS

-- METHOD   : draw_vehicle_plus_sensors (v, x_loc, y_loc) -------------
INPUTS   : v, x_loc, y_loc
  Where  :
    v is a vehicle agent
    x_loc is x location of window
    y_loc is y location of window
OUTPUTS  : creates a screen on desktop, then draws vehicle plus sensors in it
USED IN  : tracing
CREATED  : 24 Mar 2000
PURPOSE  : draw vehicle and its sensors in a window which will then be updated
    by display_vehicle_activity.

TESTS:

*/


define:method draw_vehicle_plus_sensors(v:vehicle, x_loc, y_loc);

    lvars val1 = intof(Width(v)), val2 = intof(Length(v)),
    sensor, radius;

    if isundef(activity_window) then
    else
        rc_kill_window_object(activity_window);
    endif;

    sim_x(v) -> orig_x;
    sim_y(v) -> orig_y;

    rc_new_window_object(x_loc, y_loc, val1+200, val2+200, {%((val1+200)/2)-(orig_x*2) % %((val2+200)/2)+(orig_y*2)% 2 -2},
        word_string(sim_name(v)), newsim_picagent_window) -> activity_window;
    activity_window <> sim_all_windows -> sim_all_windows;

    rc_set_axis(v, 90, false);

    rc_jumpto(orig_x-val1/2-10, orig_y);
    rc_draw_rectangle(10, left_wheel_diameter(v));
    rc_jumpto(orig_x+val1/2, orig_y);
    rc_draw_rectangle(10, right_wheel_diameter(v));

    for sensor in sensors(v) do
        sensor(4) *2 -> radius;
        rc_jumpto(orig_x, orig_y);
        90 -> rc_heading;
        rc_turn(sensor(3));
        rc_jump(sensor(2));
        rc_draw_blob(rc_xposition, rc_yposition, radius, decide_colour(sensor));
        rc_jumpby(radius ,0);
        90 -> rc_heading;
        rc_arc_around(radius, 360);
        rc_print_here(word_string(sensor(1)));

    endfor;

    true -> trace_sensors(v);

    brait_world -> rc_current_window_object;

enddefine;



/*
NB _ AS ABOVE_ OLD _NEEDS UPDATING FOR NEW SENSORS - compass and odometers

-- METHOD   : display_vehicle_activity (v, activity_list) -------------
INPUTS   : v, activity_list
  Where  :
    v is a vehicle agent
    activity_list is the list of the activity of each node
OUTPUTS  : outputs to graphical screen
USED IN  : tracing
CREATED  : 24 Mar 2000
PURPOSE  : update graphic of vehicle plus sensors and motors (fill circles
    with colour dependent upon the level of activation)

TESTS:

*/


define:method display_vehicle_activity(v:vehicle, activity_list);

    lvars colours = ['dark green' 'blue' 'purple' 'red' 'orange' 'yellow']
        ,sensor, activ, motors, radius,
        val1 = intof(Width(v)), val2 = intof(Length(v));

    for sensor from 1 to length(sensors(v)) do
        activity_window -> rc_current_window_object;
        intof(activity_list(sensor)/17)+1-> activ;
        sensors(v)(sensor)(4) *2 -> radius;
        rc_jumpto(orig_x, orig_y);
        90 -> rc_heading;
        rc_turn(sensors(v)(sensor)(3));
        rc_jump(sensors(v)(sensor)(2));
        rc_draw_blob(rc_xposition, rc_yposition, radius, colours(activ));

    endfor;

    lastpair(activity_list) -> motors ;

    intof(hd(motors)/17)+1-> activ;
    rc_jumpto(orig_x-val1/2-5, orig_y);
    rc_draw_blob(rc_xposition, rc_yposition, radius, colours(activ));

    intof(hd(motors)/17)+1 -> activ;
    rc_jumpto(orig_x+val1/2+5, orig_y);
    rc_draw_blob(rc_xposition, rc_yposition, radius, colours(activ));

brait_world -> rc_current_window_object;

enddefine;





/*
-- PROCEDURE   : normalise_list (list) -> list ------------------------
INPUTS   : list
  Where  :
    list is a list of unit activations
OUTPUTS  : list is the normalised list
USED IN  : processing new unit input information
CREATED  : 10 Aug 2000
PURPOSE  : make sure that all unit's inputs are between 0 and 100.

TESTS:

normalise_list([-900.33 900 100 203 89 10 -235789])==>

*/


define normalise_list(list) -> list;

    lvars count;

    for count from 1 to length(list) do
        if isnumber(list(count)) then
            if list(count)> 100.0 then
                100.0 -> list(count);
            elseif list(count) < 0.0 then
                0.0 -> list(count);
            endif;
        endif;
    endfor;

enddefine;


/*****************************************************************************
-- METHODS ------------------------------------------------------------
sim_run_sensors
matrix_processing
plan_move_vehicle
check_for_obstruction

*****************************************************************************/

/*
-- METHOD   : sim_run_sensors (v, sim_objects) -> sensor_data ---------
INPUTS   : v, sim_objects
  Where  :
    v is a vehicle agent
    sim_objects is a list of the current objects in the simulator
OUTPUTS  : sensor_data is a list where each element corresponds to the total
            (relevant) stimulus strength at each sensor
USED IN  : sim_agent
CREATED  : 16 Jan 2000
PURPOSE  : to calculate activation-level of each sensor and pass on this
            information to the simulator

TESTS: n/a

*/



define:method sim_run_sensors(v:vehicle, sim_objects) -> sensor_data;

lvars input, strength_at_sensor, dist, function, strength, configure;
lvars xsensor, ysensor, input, closest, range;
lvars sensor, object, source, wallx1, wallx2, wally1, wally2, vertex;
lvars sensor_data= [new_sensor_data ] ;


if null(sensors(sim_myself)) then
else
    for sensor in sensors(sim_myself) do
                    ;;; check every sensor on vehicle for input

        0 -> input;
                    ;;; the stimulus strength from all relevant sources will
                    ;;; be added to this as they are checked.

/*
-- FOR ODOMETER OR COMPASS --------------------------------------------
*/
        if sensor matches [odometer left] then
            intof(rotations_left_wheel(v)) -> input;
        elseif sensor matches [odometer right] then
            intof(rotations_right_wheel(v)) -> input;
        elseif sensor matches [compass] then
            round(heading(v)/3.6) -> input;

/*
-- FOR THE PROXIMITY SENSORS ------------------------------------------
*/

        elseif sensor matches [proximity == ] then
            sensor(4)-> range;
            9999 -> closest;
            for object in sim_objects do
                if object == sim_myself
                or object isin sim_status(sim_myself) then

                else

    (sim_x(sim_myself) + (sensor(2) * (cos(heading(sim_myself) - (360 - sensor(3))))))
                    -> xsensor;
    (sim_y(sim_myself) + (sensor(2) * (sin(heading(sim_myself) - (360 - sensor(3))))))
                    -> ysensor;

            ;;; calculates the x and y coordinates of the sensor.

                    if isbox(object) then

/*
-- FOR WALLS (NB - UPRIGHT OR FLAT) -----------------------------------
*/
                        for vertex from 1 to length(vertices(object)) do
                            ;;; for each wall do ...
                            if vertex = length(vertices(object)) then
                                vertices(object)(vertex)(1) -> wallx1;
                                vertices(object)(1)(1) -> wallx2;
                                vertices(object)(vertex)(2) -> wally1;
                                vertices(object)(1)(2) -> wally2;
                            else
                                vertices(object)(vertex)(1) -> wallx1;
                                vertices(object)(vertex+1)(1) -> wallx2;
                                vertices(object)(vertex)(2) -> wally1;
                                vertices(object)(vertex+1)(2) -> wally2;
                            endif;


                            if wallx1 = wallx2 then
                                ;;;wall is upright!
                                if ysensor < min(wally1, wally2) then
                                 ;;;below lowest point on wall so...
                                    sqrt( ((ysensor - min(wally1, wally2)) **2) + ((xsensor - wallx1) **2) )
                                        -> dist;
                                elseif ysensor > max(wally1, wally2) then
                                 ;;;above highest point on wall so...
                                    sqrt( ((ysensor - max(wally1, wally2)) **2) + ((xsensor - wallx1) **2) )
                                        -> dist;
                                else
                                    max(xsensor, wallx1) - min(xsensor, wallx1)
                                        -> dist;
                                endif;

                            elseif wally1 = wally2 then
                                ;;;wall is horizontal!
                                if xsensor< min(wallx1, wallx2) then
                                 ;;; as above but in horizontal plane!
                                    sqrt( ((xsensor - min(wallx1, wallx2)) **2) + ((ysensor - wally1) **2) )
                                        -> dist;
                                elseif xsensor> max(wallx1, wallx2) then
                                 ;;; as before
                                    sqrt( ((xsensor - max(wallx1, wallx2)) **2) + ((ysensor - wally1) **2) )
                                        -> dist;
                                else
                                    max(ysensor, wally1) - min(ysensor, wally1)
                                        -> dist;
                                endif;
                            endif;

                            if dist < closest then
                                dist -> closest;
                            endif;

                        endfor;
/*
-- FOR OTHER OBJECTS --------------------------------------------------
*/

                    else
/*
-- CALCULATE THE DISTANCE BETWEEN SENSOR AND SOURCE -------------------
*/

 sqrt( ((xsensor - sim_x(object)) **2) + ((ysensor - sim_y(object)) **2) )
                    -> dist;

            ;;; calculates the distance between the sensor and source.

                    endif;
                    if dist < closest then
                        dist -> closest;
                    endif;

                endif;
            endfor;

;;;[closest = %closest%]==>; ;;;debug

            100 - (100 * ( closest/(range*1000))) -> input;

/*
-- ANY OTHER SENSORS --------------------------------------------------
*/
        else
            for object in sim_objects do
                if null(source_info(object)) then

                else
                    for source in source_info(object) do
                        if source(1) matches sensor(1) then

                    ;;; check each object in the simulator to see if it is
                    ;;; emitting a stimulus. If the stimulus matches what the
                    ;;; sensor can detect then ...

/*
-- CALCULATE THE DISTANCE BETWEEN SENSOR AND SOURCE -------------------
*/

    (sim_x(sim_myself) + (sensor(2) * (cos(heading(sim_myself) - (360 - sensor(3))))))
                    -> xsensor;
    (sim_y(sim_myself) + (sensor(2) * (sin(heading(sim_myself) - (360 - sensor(3))))))
                    -> ysensor;

            ;;; calculates the x and y coordinates of the sensor.


 sqrt( ((xsensor - sim_x(object)) **2) + ((ysensor - sim_y(object)) **2) )
                    -> dist;

            ;;; calculates the distance between the sensor and source.


    ;;;[Distance = %dist%] ==>;   ;;;debug line

/*
-- CALCULATE STIMULUS STRENGTH FROM SOURCE AT THIS DISTANCE -----------
*/
    recursive_valof(source(3)) -> function;
    source(2) -> strength;
    source(4) -> configure;


    function(dist, strength, configure) -> strength_at_sensor;


    (sensor(4) * strength_at_sensor) -> strength_at_sensor;

        ;;; sensor(4) is the sensitivity of the sensor and acts as a multiplier
        ;;; for the actual input strength.

;;;[strength = %strength_at_sensor%]==>;   ;;;debug
/*
-- ADD THIS VALUE TO ANY OTHER VALUES FROM SIMILAR SOURCES AND CLOSE ALL LOOPS
*/
        (input + strength_at_sensor) -> input;

                        endif;

                    endfor;
                endif;
            endfor;
        endif;

        if input > 100 then
            100-> input;
        elseif input < 0 then
            0 -> input;
        endif;

        sensor_data <> [^input] -> sensor_data;

    endfor;
endif;

;;;Add extra pair of brackets. For debug. Does not work otherwise.
[^sensor_data]-> sensor_data;
;;;sensor_data ==>;   ;;;debug

enddefine;

/****************************************************************************/


/*
-- METHOD   : matrix_processing (v) -----------------------------------
INPUTS   : v is a vehicle agent
OUTPUTS  : adds appropriate output (the list of the unit outputs) straight
            into vehicle agent's database.
USED IN  : vehicle rulesystem
CREATED  : 16 Jan 2000
PURPOSE  : To create a list of all unit outputs by merging sensor inputs with
        the previous unit outputs. This list is then passed through the
        matrix of link weights to produce a list of the inputs to all of the
        units.
            These values are then used with the list of unit activation
        functions to calculate the output for each unit, given their inputs.
        This will then be used to calculate the motor speeds and passed on for
        use in the next cycle of sim_scheduler.

TESTS:

*/


define :method matrix_processing(v:vehicle);

lvars sensor_inputs_list, unit_outputs_list, unit_inputs_list, value;
lvars count, function, function_name;
lvars parity = parity_check(link_weight_matrix(v));
lvars act_function_matrix = activation_function_matrix(v);

    ;;;[Matrix processing method called]==>; ;;;debug


/*
-- EXTRACT SENSOR AND UNIT OUTPUTS DATA FROM DATABASE -----------------
*/
    tl(prb_present([sensor_inputs ==])) -> sensor_inputs_list;

    tl(prb_present([unit_inputs ==])) -> unit_inputs_list;
    tl(prb_present([unit_inputs ==])) -> unit_outputs_list;


/*
-- INSERT SENSOR DATA INTO UNIT INPUTS LIST ---------------------------
*/
;;;sensor_inputs_list==>;;;;debug

    if not(sensor_inputs_list = [[]]) then
        for value in sensor_inputs_list do
            tl(unit_inputs_list) -> unit_inputs_list;
        endfor;

        sensor_inputs_list <> unit_inputs_list -> unit_inputs_list;

    endif;


/*
-- NOW MULTIPLY UNIT INPUTS WITH ACTIVATION FUNCTIONS TO GET UNIT OUTPUTS.
*/

	lconstant act_function_matrix_types = [[basic_unit] [motor] ];

    for count from 1 to length(unit_inputs_list) do

        if member(act_function_matrix(count), act_function_matrix_types) then
            unit_inputs_list(count) -> unit_outputs_list(count);
        elseif act_function_matrix(count) = [internal_energy] then
            100 -> unit_outputs_list(count);
        else

            ;;;[mult act func now] ==>; ;;;debug

        ;;;Find which math function to use by finding which bounds the input
        ;;;value is in.

            for function in act_function_matrix(count) do

                if (function(2) <= unit_inputs_list(count))
                    and( unit_inputs_list(count) <= function(3)) then

                    ;;;[func matched]==>; ;;;debug

        ;;;Matched function so calculate the value for the unit output, given
        ;;; the input and the function config values.
                    recursive_valof(function(1)) -> function_name;
                    function_name(unit_inputs_list(count), function(4), function(5))
                        -> unit_outputs_list(count);
                endif;

            endfor;
        endif;
    endfor;

/*
-- MULTIPLY UNIT OUTPUTS INTO LINK WEIGHT MATRIX TO GET UNIT INPUTS ---
*/

    multiply_with_matrix(unit_outputs_list, link_weight_matrix(v))
                -> unit_inputs_list;

        ;;;[matrix multiply results = %unit_inputs_list%]==>;  ;;;debug

/*
-- CHECK NO UNIT INPUT IS >100 OR <0 ----------------------------------
*/

    normalise_list(unit_inputs_list) -> unit_inputs_list;

/*
-- Do unit input and output tracing if necessary ----------------------
**/


	unless null(node_trace_list(sim_myself)) then

		trace_cycle_number + 1 -> trace_cycle_number;

		draw_activation_graph(sim_myself, node_trace_list(sim_myself), unit_inputs_list, 'red');
    	;;;draws graph for any traced nodes' inputs

		draw_activation_graph(sim_myself, node_trace_list(sim_myself), unit_outputs_list, 'black');
    	;;;draws graph for any traced nodes' outputs
	endunless;

	if trace_sensors(sim_myself) then
    	display_vehicle_activity(sim_myself, unit_outputs_list);
	endif;


/*
-- FINALLY, ADD NEW UNIT INPUTS + OUTPUT LISTS INTO INTERNAL DATABASE -
	*/

	prb_add([unit_outputs ^^unit_outputs_list]);
	prb_add([new_unit_inputs ^^unit_inputs_list]);


enddefine;



/****************************************************************************/


/*
-- METHOD   : plan_move_vehicle (vehicle, left_motor_input, right_motor_input)
INPUTS   : vehicle, left_motor_input, right_motor_input
  Where  :
    vehicle is a vehicle_agent
    left_motor_input is the output of the unit linked to the left motor
    right_motor_input is the output of the unit linked to the right motor
OUTPUTS  : NONE
USED IN  : vehicle_rulesystem
CREATED  : 27 Jan 2000
PURPOSE  : to plan the vehicles path.

TESTS:

*/

define:method plan_move_vehicle(me:vehicle, left_motor_input, right_motor_input);

lvars rps_left, rps_right, dist_moved_left, dist_moved_right,
        forward_dist, newx, newy, turn_angle, new_heading, calc;


if [being_carried] isin sim_status(sim_myself) then
    ;;;if being carried do nothing!

else

/*
-- CALCULATE DIST MOVED BY EACH WHEEL ---------------------------------
*/

    (max_rps_left_motor(me) * (left_motor_input/100) )-> rps_left;
    (max_rps_right_motor(me) * (right_motor_input/100) )-> rps_right;


    ( (rps_left * time_slice_duration) *
            (pi * left_wheel_diameter(me))
    )  -> dist_moved_left;


    ( (rps_right * time_slice_duration) *
            (pi * right_wheel_diameter(me))
    )  -> dist_moved_right;

;;;[left dist = %dist_moved_left%]  ==>; ;;;debug
;;;[Right dist = %dist_moved_right%] ==>; ;;;debug

/*
-- FORWARD DIST MOVED IS average OF THESE TWO -------------------------
*/

   (dist_moved_left + dist_moved_right)/2 -> forward_dist;

/*
-- CALCULATE HEADING CHANGE AND X AND Y CHANGE ------------------------
*/

    (cos(heading(me)) * forward_dist) + sim_x(me) -> newx;
    (sin(heading(me)) * forward_dist) + sim_y(me)-> newy;

(dist_moved_right - dist_moved_left) / (2.0 * Width(me)) ->calc;

    (2.0 * (arcsin(calc))) -> turn_angle;
    decomplex(turn_angle + heading(me)) -> new_heading;

    if new_heading < 0 then
        new_heading + 360 -> new_heading;
    elseif new_heading > 360 then
        new_heading - 360 -> new_heading;
    endif;


    ;;;[CALC = %calc% ]==>; ;;;debug
    ;;;[FORWARDS MOVEMENT = %forward_dist%]==>; ;;;debug
    ;;;[TURN = %turn_angle%]==>; ;;; debug

/*
-- INSERT PLANNED MOVE INTO DATABASE ----------------------------------
*/

    prb_add([planned_move %decomplex(newx)% %decomplex(newy)%
                    %decomplex(new_heading)%]);


/*
-- UPDATE VEHICLE'S DATA-LOG ------------------------------------------
*/


    rps_left * time_slice_duration + rotations_left_wheel(me) -> rotations_left_wheel(me);
    rps_right * time_slice_duration + rotations_right_wheel(me) -> rotations_right_wheel(me);

    total_dist_moved_by_left_wheel(me) + dist_moved_left -> total_dist_moved_by_left_wheel(me);
    total_dist_moved_by_right_wheel(me) + dist_moved_right -> total_dist_moved_by_right_wheel(me);
    total_dist_moved_by_vehicle(me) + forward_dist -> total_dist_moved_by_vehicle(me);

    total_turn_angle(me) + abs(turn_angle) -> total_turn_angle(me);
    start_heading(me) - new_heading -> heading_relative_to_original(me);

endif;


enddefine;





/****************************************************************************/


/*
-- METHOD   : check_path_for_obstruction (me, sim_objects, planx, plany, planheading)
INPUTS   : me, sim_objects, planx, plany, planheading
  Where  :
    me is the vehicle agent under scrutiny
    sim_objects is the list of all current objects in the simulator
    planx is the intended x coordinate
    plany is the intended y coordinate
    planheading is the intended heading
OUTPUTS  : NONE
USED IN  : vehicle-rulesystem
CREATED  : 28 Jan 2000
PURPOSE  : to check along a vehicles intended path for obstacles. If it finds
            any objects within a radius of diagonal/2 of the vehicle, it
            calculates the path possible for the vehicle and adds this to the
            database. If there are no obstructions, the possible_path is
            identical to the planned path.

TESTS:

*/


define:method check_path_for_obstruction(me:vehicle, sim_objects,
        planx, plany, planheading);

    lvars  direction = heading(me),
        m = tan(direction),                       ;;;the gradient of the path
        c = sim_y(me) - (sim_x(me) * m),        ;;;the C in 'y = Mx + C'
        radius = Diagonal(me)/2;
    lvars possible = [], x, y, dist, compare, count, object,
        stepper, start_val, end_val, step_value, checking;
    lvars vertex, wallx1, wallx2, wally1, wally2,
        direction_from_object, direction_to_object,
        collision_id = [];


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
-- FIND WHICH AXIS TO CHECK ALONG -------------------------------------
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
        if object /== me and not(object isin sim_status(sim_myself)) then


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
                            and (y+radius)> wally1
                            and (y-radius)< wally2
                            and (direction < 90 or direction > 270) then
                                ;;;check for corner
                                if (y < wally1
                                    and direction > 270)
                                or (y > wally2
                                    and direction < 90) then

                                else
                                    ;;;vehicle bumped it!
                                    possible <> [^stepper] -> possible;

                                    collision_id <> [[%sqrt((x - sim_x(me))**2 + (y-sim_y(me))**2)% ^object]] -> collision_id;

                                    if round(x) = round(sim_x(me))
                                    and round(y) = round(sim_y(me)) then
                                        quitloop(3);
                                    endif;

                                endif;

                            elseif x > wallx1 and x < (wallx1 + radius)
                            and (y+radius)> wally1
                            and (y-radius)< wally2
                            and (direction <270  and direction > 90) then
                                ;;;check for corner
                                if (y < wally1
                                    and direction > 180)
                                or (y > wally2
                                    and direction < 180) then

                                else
                                    ;;;vehicle bumped it!
                                    possible <> [^stepper] -> possible;

                                    collision_id <> [[%sqrt((x - sim_x(me))**2 + (y-sim_y(me))**2)% ^object]] -> collision_id;

                                    if round(x) = round(sim_x(me))
                                    and round(y) = round(sim_y(me)) then
                                        quitloop(3);
                                    endif;
                                endif;
                            endif;

                        elseif wally1 = wally2 then
                            ;;;wall is horizontal!
                            if y < wally1 and y > (wally1 - radius)
                            and (x+radius)> wallx1
                            and (x-radius)<  wallx2
                            and (direction < 180 and direction > 0) then
                                ;;;check for corner
                                if (x < wallx1
                                    and direction > 90)
                                or (x > wallx2
                                    and direction < 90) then

                                else
                                    ;;;vehicle bumped it!
                                    possible <> [^stepper] -> possible;

                                    collision_id <> [[%sqrt((x - sim_x(me))**2 + (y-sim_y(me))**2)% ^object]] -> collision_id;

                                    if round(x) = round(sim_x(me))
                                    and round(y) = round(sim_y(me)) then
                                        quitloop(3);
                                    endif;
                                endif;

                            elseif y > wally1 and y < (wally1 + radius)
                            and (x+radius)> wallx1
                            and (x-radius)< wallx2
                            and (direction > 180 and direction < 360) then
                                ;;;check for corner
                                if (x < wallx1
                                    and direction < 270)
                                or (x > wallx2
                                    and direction > 270) then

                                else
                                    ;;;vehicle bumped it!
                                    possible <> [^stepper] -> possible;

                                    collision_id <> [[%sqrt((x - sim_x(me))**2 + (y-sim_y(me))**2)% ^object]] -> collision_id;

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
                        and direction_from_object > 0 then
                            ;;;there is a vehicle collision on the cards!
                            possible <> [^stepper] -> possible;

                            collision_id <> [[%sqrt((x - sim_x(me))**2 + (y-sim_y(me))**2)% ^object]] -> collision_id;

                            if round(x) = round(sim_x(me))
                            and round(y) = round(sim_y(me)) then
                                quitloop(2);
                            endif;

                            quitloop;
                        endif;


                    elseif issource(object) then

                        ;;;[SOURCE DIST = %dist%]==>; ;;;debug
                        if dist < (radius + (Radius(object)))
                        and direction_from_object < 180
                        and direction_from_object > 0 then
                            ;;;there is a source in the way!
                            possible <> [^stepper] -> possible;

                            collision_id <> [[%sqrt((x - sim_x(me))**2 + (y-sim_y(me))**2)% ^object]] -> collision_id;

                            if round(x) = round(sim_x(me))
                            and round(y) = round(sim_y(me)) then
                                quitloop(2);
                            endif;
                            quitloop;
                        endif;

                    elseif isball_object(object) then

                        ;;;[BALL DIST = %dist%]==>; ;;;debug
                        if dist < (radius + (Radius(object)))
                        and direction_from_object < 180
                        and direction_from_object > 0 then
                            ;;;there is a ball in the way!
                            possible <> [^stepper] -> possible;

                            collision_id <> [[%sqrt((x - sim_x(me))**2 + (y-sim_y(me))**2)% ^object]] -> collision_id;

                            if round(x) = round(sim_x(me))
                            and round(y) = round(sim_y(me)) then
                                quitloop(2);
                            endif;
                            quitloop;
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
    ;;;collision_id==>


    if null(possible) then
        ;;;no obstructions

    elseif length(possible) = 1 then
        ;;;one obstruction
        if checking == "x" then
            hd(possible) -> planx;
            (m * planx) + c -> plany;
        elseif checking == "y" then
            hd(possible) -> plany;
            (plany- c) /m -> planx;
        endif;

        collision_id(1)(2) -> object;

        if isvehicle(object) then
            contact_with_vehicles(me) + 1 -> contact_with_vehicles(me);
            contact_total(me) + 1 -> contact_total(me);
            if halt_on_vehicle_collision = true then
                sim_stop_scheduler();
            endif;
        elseif issource(object) then
            contact_with_sources(me) + 1 -> contact_with_sources(me);
            contact_total(me) + 1 -> contact_total(me);
            if halt_on_source_collision = true then
                sim_stop_scheduler();
            endif;
            if isnumber(random_move_source_on_collision) then
				randomise_position(object, random_move_source_on_collision);
			endif;
        elseif isbox(object) then
            contact_with_boxes(me) + 1 -> contact_with_boxes(me);
            contact_total(me) + 1 -> contact_total(me);
        elseif isball_object(object) then
            contact_with_balls(me) + 1 -> contact_with_balls(me);
            contact_total(me) + 1 -> contact_total(me);
            (speed(me)*(Diagonal(me)/200)) +
            (speed(object) * (200/Diameter(object)))
            * bounciness(object) -> impulse(object);
            planheading -> heading(object);
        endif;
    else
        ;;;more than one obstruction, find closest one.
        for dist from 1 to length(collision_id) do
            0 -> count;
            for compare from 1 to length(collision_id) do

                if collision_id(dist)(1) <= collision_id(compare)(1) then
                    count+1 -> count;
                endif;

            endfor;
            if count = length(collision_id) then
                if checking == "x" then
                    possible(dist) -> planx;
                    (m * planx) + c -> plany;
                elseif checking == "y" then
                    possible(dist) -> plany;
                    (plany- c) /m -> planx;
                endif;

            collision_id(dist)(2) -> object;

            if isvehicle(object) then
                contact_with_vehicles(me) + 1 -> contact_with_vehicles(me);
                contact_total(me) + 1 -> contact_total(me);
                if halt_on_vehicle_collision = true then
                    sim_stop_scheduler();
                endif;
            elseif issource(object) then
                contact_with_sources(me) + 1 -> contact_with_sources(me);
                contact_total(me) + 1 -> contact_total(me);
                if halt_on_source_collision = true then
                    sim_stop_scheduler();
                endif;
				if isnumber(random_move_source_on_collision) then
				 	randomise_position(object, random_move_source_on_collision);
				endif;
            elseif isbox(object) then
                contact_with_boxes(me) + 1 -> contact_with_boxes(me);
                contact_total(me) + 1 -> contact_total(me);
            elseif isball_object(object) then
                contact_with_balls(me) + 1 -> contact_with_balls(me);
                contact_total(me) + 1 -> contact_total(me);
                (speed(me)*(Diagonal(me)/200)) +
                (speed(object) * (200/Diameter(object)))
                * bounciness(object) -> impulse(object);
                planheading -> heading(object);
            endif;

                quitloop;
            endif;

        endfor;

    endif;


    prb_add([possible_move %decomplex(planx)% %decomplex(plany)%
            %decomplex(planheading)%]);

/*
-- CALCULATE NEW SPEED ------------------------------------------------
*/

    (sqrt((planx - sim_x(me))**2 + (plany-sim_y(me))**2))/time_slice_duration -> speed(me);

    ;;;speed(me)==>;
    ;;;[possible_move ^planx ^plany ^planheading] ==>; ;;;debug


/*
-- UPDATE DATA-LOG SLOTS ----------------------------------------------
*/

    if planx > max_x(me) then
        planx -> max_x(me);
    endif;
    if planx < min_x(me) then
        planx -> min_x(me)
    endif;
    if plany > max_y(me) then
        plany -> max_y(me);
    endif;
    if plany < min_y(me) then
        plany -> min_y(me);
    endif;

    if speed(me) > max_speed(me) then
        speed(me) -> max_speed(me);
    endif;
    if speed(me) < min_speed(me) then
        speed(me) -> min_speed(me);
    endif;

enddefine;





/***************************************************************************/


/*
-- PROCEDURE: create_vehicle (vlength, width, coord_x, coord_y, direction, link_wt_matrix, act_function_matrix, sensor_list, vehicle_sourcing, motor_left, motor_right) -> newvehicle
INPUTS   : vlength, width, coord_x, coord_y, direction, link_wt_matrix, act_function_matrix, sensor_list, vehicle_sourcing
  Where  :
    vlength is the length of the vehicle
    width is the width of the vehicle
    coord_x is the initial x coordinate of the vehicle
    coord_y is the initial y coordinate of the vehicle
    direction is the initial heading of the vehicle
    link_wt_matrix is the link matrix of the vehicle
    act_function_matrix is the list of activation functions
    sensor_list is the list of sensors on the vehicle
    vehicle_sourcing is a list of the detectable stimuli that the vehicle is
            emmitting
OUTPUTS  : newvehicle is sim_agent instance
USED IN  : sim_scheduler
CREATED  : 16 Jan 2000
PURPOSE  : To create new vehicle agent instances as specified in the list of
    attributes.

TESTS:  in main.p

*/



define create_vehicle(vlength, width, coord_x, coord_y, direction,
        link_wt_matrix, act_function_matrix, sensor_list, vehicle_sourcing
        	) -> newvehicle;

    lvars first_input_list = [unit_inputs ];
    lvars parity, diagonal;
    lvars name = gensym("vehicle");


 /*
-- CHECK PARITY OF MATRIX AND ACT. FUNCTIONS LISTS --------------------
*/


    if islist(link_wt_matrix) then

        parity_check(link_wt_matrix) -> parity;

        if not(parity) then
            ['MATRIX PARITY ERROR']==>;
            return(false);

        elseif not(null(act_function_matrix)) and
                parity /= length(act_function_matrix) then
            ['ACTIVATION FUNCTION LIST PARITY DOES NOT MATCH MATRIX']==>;
            return(false);

        elseif parity < (length(sensor_list) + 2) then
            ['NOT ENOUGH ROOM IN MATRIX FOR SENSORS PLUS MOTOR OUTPUTS'] ==>;
            return(false);

        endif;
    elseif isprocedure(link_wt_matrix) then
        'user_proc' -> act_function_matrix;
    endif;

/*
-- SENSOR CHECKS ------------------------------------------------------
-- CALCULATE SENSOR LOCATIONS IF SHORTHAND IS USED --------------------
*/
    ;;; i.e. sensor location specified by distance and angle from vehicle centre.
    ;;;To facilitate quicker specification, left and right can be used and this
    ;;;segment will calculate the distance and angle.



	lblock;
	lvars sensor, sensor_num, sensor_type, sensor_location, sensor_sensitivity ;
	lvars angle;
    arctan(width/vlength) -> angle;
    ((width**2 + vlength**2)**0.5) -> diagonal;
    for sensor_num from 1 to length(sensor_list) do
		sensor_list(sensor_num) -> sensor;
		sensor(1) -> sensor_type;
		sensor(2) -> sensor_location;
		sensor(3) -> sensor_sensitivity;
		if isstring(sensor_location) then consword(sensor_location) -> sensor_location endif;
        unless sensor_type == odometer or sensor_type == compass then
            if sensor_location == "left" then
            ;;;[CALCULATING left sensor_num position]==>; ;;;debug

                sensor <> [%sensor_sensitivity%]
                    ->> sensor -> sensor_list(sensor_num);
                diagonal/2  -> sensor(2);
                angle -> sensor(3);

            elseif sensor_location == "right" then
            ;;;[CALCULATING right sensor_num position]==>; ;;;debug

                sensor <> [%sensor_sensitivity%]
                    ->> sensor -> sensor_list(sensor_num);
                diagonal/2    -> sensor(2);
                (360 - angle) -> sensor(3);
    		
	        elseif sensor_location == "centre" then
            ;;;[CALCULATING centre sensor_num position]==>; ;;;debug

                sensor <> [%sensor_sensitivity%]
                    ->> sensor -> sensor_list(sensor_num);
                vlength/2    ->> sensor_location -> sensor(2);
                0 ->> sensor_sensitivity -> sensor(3);

            elseif sensor_location == "rear" then
            ;;;[CALCULATING rear sensor_num position]==>; ;;;debug

                sensor <> [%sensor_sensitivity%]
                    ->> sensor -> sensor_list(sensor_num);
                vlength/2    ->> sensor_location -> sensor(2);
                180 -> sensor(3);

            endif;

        endunless
    endfor;

	endlblock;


 /*
-- MAKE SURE SENSOR SENSITIVITY IS BETWEEN 1 AND ZERO -----------------
*/
	lconstant sensor_types =
		[[odometer left] [odometer right] [compass]];

	lblock; lvars sensor;
    for sensor in sensor_list do
        unless member(sensor, sensor_types) then

            if length(sensor) /== 4 then
				mishap('SENSOR SPECIFICATION ERROR', [^sensor]);
            endif;

            if sensor(4) > 1 then
                1 -> sensor(4);

            elseif sensor(4) < 0 then
                0 -> sensor(4);
            endif;

        endunless;
    endfor;

	endlblock;

/*
-- SOURCE CHECKS ------------------------------------------------------
-- MAKE SURE STRENGTH IS BETWEEN 0 AND 100 ----------------------------
*/


	lblock; lvars source;
    for source in vehicle_sourcing do
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


        unless isprocedure(recursive_valof(source(3))) then
            mishap('VEHICLE SOURCE DECAY FUNCTION NOT RECOGNISED',
				[^(source(3))]);
        endunless;

    endfor;
	endlblock;


/*
-- ACTIVATION FUNCTION CHECKS -----------------------------------------
-- if null list given, make all [basic_unit] --------------------------
*/

    if islist(link_wt_matrix) then
        if null(act_function_matrix) then
            repeat parity times
                act_function_matrix <> [[basic_unit]] -> act_function_matrix;
            endrepeat
        endif;


  /*
-- MAKE SURE FUNCTION NAME IS A PROCEDURE_KEY -------------------------
*/
		lconstant function_types =
			[[basic_unit] [internal_energy] [sensor] [motor]];

		lblock
		lvars function;
        for function in act_function_matrix do
            unless member(function, function_types) then

				lvars ind_function ;
                for ind_function in function do
                    unless isprocedure(recursive_valof(ind_function(1))) then
						mishap(
                        	'ACTIVATION FUNCTION ERROR. FUNCTION NAME NOT RECOGNISED',
							[^ind_function]);
                    endunless;
                endfor;
            endunless;
        endfor;
		endlblock;
    endif;


/*
-- CREATE FIRST UNIT OUTPUTS LIST -------------------------------------
*/

	lblock; lvars item;
    if islist(link_wt_matrix) then
        for item in link_wt_matrix do
            [^^first_input_list 0] -> first_input_list;
        endfor;
    else
/*
        for item in sensor_list do
            [^^first_input_list 0] -> first_input_list;
        endfor;
            [^^first_input_list 0] -> first_input_list;
            [^^first_input_list 0] -> first_input_list;
*/
        repeat (length(sensor_list) + 2) times
            [^^first_input_list 0] -> first_input_list;
        endrepeat;
    endif;

	endlblock;
/*
-- CALCULATE COLOUR OF VEHICLE AND PICLINES ---------------------------
*/

	lvars picture_info =
    	[COLOUR %if null(vehicle_sourcing) then
                'black';
            else
                decide_colour(vehicle_sourcing(1));
            endif%


        ;;;[CIRCLE {0 0 %diagonal/2%}]

        	[RRECT {%-(vlength/2)% %width/2% %vlength% %width% }
            	{-40 %width/2+28% 80 25}
            	{-40 %-width/2-2% 80 25}]

    		;;; Draw sensors on - shows direction of vehicle!
    		[rc_draw_blob
        		%if null(sensor_list) then
            		{%(vlength/2) - (vlength/8)% 0 3 'black'}
        		else
					lblock; lvars sensor;
            			for sensor in sensor_list do
                			if sensor=[odometer left] then
                    			{0 %width/2+2+12.5%  3 'dark green'}
                			elseif sensor=[odometer right] then
                    			{0 %-width/2-2-12.5%  3 'dark green'}
                			elseif sensor=[compass] then
                    			{0 0 6 'dark green'}
                			else
                    			{%cos(sensor(3))*sensor(2)%
                     				%sin(sensor(3))*sensor(2)% 10 %decide_colour(sensor)%}
                			endif;
            			endfor;
					endlblock;
        		endif%    ]

    	];



/*
-- CREATE INSTANCE ----------------------------------------------------
*/

    instance vehicle;

        Length = vlength;
        Width = width;
        Diagonal = diagonal;
        hand_range = diagonal + (diagonal/3);

        rc_mouse_limit = diagonal/2;

        rc_pic_lines = picture_info;
        my_trace_colour = trace_colours(current_trace_colour);

        sim_x = coord_x;
        sim_y = coord_y;
        heading = direction;
        start_x = coord_x;
        start_y = coord_y;
        start_heading = direction;

        link_weight_matrix = link_wt_matrix;
        activation_function_matrix = act_function_matrix;

        sensors = sensor_list;
        source_info = vehicle_sourcing;
        sim_data = prb_newdatabase(sim_dbsize, [^first_input_list]);
        sim_name = name;

    endinstance -> newvehicle;

	;;; cycling of trace colour simplified. A.S.

    current_trace_colour + 1 -> current_trace_colour;
	if current_trace_colour > length(trace_colours) then
		1 -> current_trace_colour
	endif;

    if isundef(brait_world) or not(rc_islive_window_object(brait_world)) then
        create_window(500,500);
    endif;


	unless sim_running then
	    show_and_name_instance(name, newvehicle, brait_world);
	endunless;

    rc_set_axis(newvehicle, direction, true);

enddefine;






/*****************************************************************************
-- VEHICLE RULESYSTEM -------------------------------------------------
*****************************************************************************/


define :rulesystem vehicle_rulesystem;
    [DLOCAL [prb_allrules = true]];

include: processing

enddefine;


define move_vehicle(agent, newx, newy, newheading);
	;;; used below. Added AS 7 Oct 2000

	;;; prevent additional events being handled during drawing
	dlocal rc_in_event_handler = true;
    sim_move_to(agent, newx, newy, false);
    rc_set_axis(agent, newheading, true);
    newheading -> heading(agent);
enddefine;


define :ruleset processing;

RULE process_sensory
    [new_sensor_data ??vals]
        ==>
    [NOT sensor_inputs ==]
	[sensor_inputs ??vals]
    [NOT new_sensor_data ==]


RULE process_output_list
    [new_unit_inputs ??vals2]
        ==>
    [NOT unit_inputs ==]
    [unit_inputs ??vals2]
    [NOT new_unit_inputs ==]
    [NOT possible_move ==]
    [NOT planned_move ==]
	[NOT unit_outputs ==]


RULE apply_controller
    [sensor_inputs ??sensor_data]
    [unit_inputs ==]
        ==>
    [POP11 if islist(link_weight_matrix(sim_myself)) then
                matrix_processing(sim_myself);
           elseif isprocedure(link_weight_matrix(sim_myself)) then
                lvars new_list;
                link_weight_matrix(sim_myself)(sim_myself, sensor_data);
				prb_add([unit_outputs ^^sensor_data
								%if islist(hand(sim_myself)) then
                                    (hand_activation(sim_myself))
                                 endif;%
                                ^(left_motor_speed(sim_myself))
                                ^(right_motor_speed(sim_myself))]);
                normalise_list( [new_unit_inputs
                                %if islist(hand(sim_myself)) then
                                    (hand_activation(sim_myself))
                                 endif;%
                                ^(left_motor_speed(sim_myself))
                                ^(right_motor_speed(sim_myself))] )->new_list;
            	prb_add(new_list);
           endif;]


RULE dials_update
	 	==>
    [POP11  lvars item, sensor_vals, unit_vals;
            if sim_use_dial_panel and (sim_dial_panel_for = sim_myself) then
                tl(prb_present([unit_outputs ==])) -> unit_vals;
				for item from 1 to length(unit_vals) do
					unless rc_in_event_handler then
						 unit_vals(item) -> dial_value_of_name(dial_panel, "dials", item);
					;;;false -> rc_in_event_handler;
					endunless;
				endfor;
			endif; ]


RULE plan_movement
    [new_unit_inputs == ?left_motor ?right_motor]
        ==>
    [POP11 plan_move_vehicle(sim_myself, left_motor, right_motor);]


RULE obstruction_check
    [planned_move ?newx ?newy ?newheading]
        ==>
    [POP11
check_path_for_obstruction(sim_myself, sim_objects, newx, newy, newheading);]


RULE drop
    [new_unit_inputs == ?hand_act = =]
        ==>
    [POP11  lvars object, item;
        for object in sim_status(sim_myself) do
            if (isvehicle(object) or issource(object))
            and hand_act < hand_threshold(sim_myself) then

                sim_x(object) + 5 -> sim_x(object);
                sim_y(object) + 5 -> sim_y(object);
                setfrontlist(object, sim_status(sim_myself)) -> sim_status(sim_myself);
                tl(sim_status(sim_myself)) -> sim_status(sim_myself);
                [open] -> hand(sim_myself);

                [%hd(sim_status(object))%] -> sim_status(object);

        rc_print_pic_string(sim_x(sim_myself),sim_y(sim_myself), 'DROPPED');
;;;[DROPYA!]==>; ;;;debug

            endif;
        endfor;]



RULE carry_out_movement
    [possible_move ?newx ?newy ?newheading]
        ==>
    [POP11

     if use_window then
         if path_tracing = 'blob' then
             rc_draw_blob(sim_x(sim_myself), sim_y(sim_myself), 2, my_trace_colour(sim_myself));
         elseif path_tracing = 'line' then
             rc_draw_coloured_line(sim_x(sim_myself), sim_y(sim_myself), newx, newy,
				 my_trace_colour(sim_myself), false);
         endif;
     endif;

     if use_window then
		 move_vehicle(sim_myself, newx, newy, newheading);
		 ;;; added AS 7 Oct 2000
		 ;;; sleep for a while if necessary
		 if delay_time >= 0 then
			 syssleep(delay_time);
		 endif;
     else
         newx -> sim_x(sim_myself);
         newy -> sim_y(sim_myself);
         newheading -> heading(sim_myself);
         newheading -> rc_axis(sim_myself);
     endif;

     lvars item;
     for item in sim_status(sim_myself) then
         if (isvehicle(item) or issource(item)) then
             if use_window then
				 ;;; deleted A.S. 7 Oct 2000
                 ;;; (newx+1, newy+1) -> sim_coords(item);
                 sim_move_to(item, newx+1, newy+1, true);
             else
                 newx+1 -> sim_x(item);
                 newy+1 -> sim_y(item);
             endif;
         endif;
     endfor;]

RULE gotcha
    [new_unit_inputs == ?hand_act = =]
        ==>
    [POP11  lvars object;
        for object in sim_objects do
            if object /== sim_myself
            and not(isbox(object))
            and length(sim_status(sim_myself)) < 2
            and hand(sim_myself) = [open]
            and hand_act >= hand_threshold(sim_myself) then
                if sim_distance(sim_myself, object) <= hand_range(sim_myself) then
                    sim_status(sim_myself) <> [^object] -> sim_status(sim_myself);
                    sim_status(object) <> [[being_carried]]
                        -> sim_status(object);
                    [closed] -> hand(sim_myself);

                	rc_print_pic_string(sim_x(sim_myself),sim_y(sim_myself), 'GOTCHA');

        			;;;[GOTCHA!!]==>; ;;;debug
        			;;;sim_status(sim_myself )==>;
        			;;;hand_act ==>;

                endif;
            endif;
        endfor; ]

RULE hand
    [new_unit_inputs == ?hand_act = =]
        ==>
    [POP11
		if hand(sim_myself) = [closed]
        and hand_act < hand_threshold(sim_myself) then
            [open] -> hand(sim_myself);
        elseif hand(sim_myself) = [open]
        and hand_act >= hand_threshold(sim_myself) then
            [closed] -> hand(sim_myself);
        endif;]

enddefine;

/*
-- REVISION NOTES
*/
/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, 23 Jul 2002
	Added call of rc_run_deferred_events() in sim_run_agent

--- Aaron Sloman, Dec 24 2000
	Used new rc_draw_coloured_line procedure to make line trace use
		the vehicle's trace colour.

	added more trace colours in list held in global variable trace_colours

	Changed 'x' 'y' to be "x" "y", and replaced = with ==

	Much rationalisation of create_vehicle, including introduction
	of new lvars and lconstants, etc.

--- Aaron Sloman, Dec 23 2000
	Renamed file as vehicle_agent.p

--- Aaron Sloman, Oct  8 2000

	Fixed header, replaced smallest, largest with min, max.
	Added "define" index

--- Duncan K Fewkes, Sep 21 2000
Added new global variable "random_move_source_on_collision" in main file.
Altered collision checking method so that, if there is a collision with a
source, the source's position is randomised asccording to the value of global
var - random_move_source_on_collision.

--- Duncan K Fewkes, Sep  5 2000
Altered ruleset and matrix_processing method slightly for dials panel update
Now draws OUTPUT of each unit on dials.

--- Duncan K Fewkes, Sep  1 2000
changed hand rules so that only have to insert [open] or [closed] into
vehicle's hand slot to activate it
also, can pick up any object (except boxes) - do not need to specify [predator]
and [prey] etc.

--- Duncan K Fewkes, Aug 31 2000
Added new rule for dials_panel update

May add further rule to allow manipulation of dials to control units activity
(or may save this for user-proc - see remote control proc in tests.p)
--- Duncan K Fewkes, Aug 30 2000
converted to lib format

-- LIST OF PROCEDURES, CLASS DEFINITIONS, METHODS ETC

CONTENTS (Use ENTER gg)

 define:class vehicle; is rc_rotatable; is sim_movable_agent;
 define :method sim_run_agent(object:vehicle, objects);
 define:method print_vehicle_data_log(me:vehicle);
 define:method randomise_position(o:sim_object, coord_limits);
 define:method draw_activation_graph(v:vehicle, node_trac_list, values_list, trace_colour);
 define create_trace_windows(start_x, start_y, wlength);
 define:method draw_vehicle_plus_sensors(v:vehicle, x_loc, y_loc);
 define:method display_vehicle_activity(v:vehicle, activity_list);
 define normalise_list(list) -> list;
 define:method sim_run_sensors(v:vehicle, sim_objects) -> sensor_data;
 define :method matrix_processing(v:vehicle);
 define:method plan_move_vehicle(me:vehicle, left_motor_input, right_motor_input);
 define:method check_path_for_obstruction(me:vehicle, sim_objects,
 define create_vehicle(vlength, width, coord_x, coord_y, direction,
 define :rulesystem vehicle_rulesystem;
 define move_vehicle(agent, newx, newy, newheading);
 define :ruleset processing;

 */
