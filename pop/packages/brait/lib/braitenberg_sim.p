/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/brait/lib/braitenberg_sim.p
 > Purpose:         main file to compile (calls all relevant files and libraries)
 > Author:          Duncan K Fewkes, 3 Dec 1999 (see revisions)
                    - edited procedures written by Aaron Sloman
 > Documentation:
 > Related Files:

matrix_functions.p
activation_functions.p
decay_functions.p
tools.p
box_object.p
source_object.p
vehicle_agent.p
ball_object.p
mousehandlers.p
interface.p
tutorialsupplement.p

 */

 /*

         CONTENTS - (Use <ENTER> g to access required sections)

 -- CALL LIBRARIES
 -- GLOBAL VARIABLES
 -- CALL FILES
 -- TURN OFF ALL TRACING
 -- MAIN PROCEDURES
 -- SHORTCUT
 -- REVISION NOTES
 -- LIST OF PROCEDURES

*/

/*****************************************************************************

FILE:            /home/students/csai97/dkf/brait/braitenberg_sim.p
AUTHOR:          Duncan K Fewkes - edited procedures written by Aaron Sloman
CREATION DATE:  3 Dec 1999
COURSE:          AI/Philosophy
PURPOSE:         main file to compile (calls all relevant files and libraries)
LAST MODIFIED:  30/8/2000

******************************************************************************/
/*
-- CALL LIBRARIES -----------------------------------------------------
*/

;;; Order changed by AS. 8 Oct 2000

uses rclib;
uses rc_mouse;
uses rc_mousepic;
uses rc_window_object;
uses rc_dial;
uses rc_control_panel;

uses simlib;
uses sim_picagent;

uses time;
uses compilehere;

sys_unlock_heap();
sysgarbage();
30000000 -> popmemlim;

/*
-- GLOBAL VARIABLES ---------------------------------------------------
*/

;;; Link "do_stop" used here to new variable in lib sim_agent
syssynonym("do_stop", "sim_stopping_scheduler");

global vars
    time_slice_duration = 0.02,    		;;;length of time slice in seconds.
    sim_time = 0,                       ;;;global clock - kept by sys_real_time
    sim_start_time,                     ;;; instantiated to sys_real_time at start os sim_scheduler call
    ;;; initialisation added AS 7 Oct 2000
    delay_time = 0,                     ;;; not the best way of reducing flickering
    do_stop = false,                    ;;; true if demo is to stop
    do_finish = false,                  ;;; true of panels are to be removed

    halt_on_source_collision = false,
    halt_on_vehicle_collision = false,
    random_move_source_on_collision = false,
    path_tracing = false,
    use_window = true,                  ;;;draw agent movement in window

	;;; Possible colours for tracing.
	trace_colours = ['blue' 'green' 'red' 'orange' 'pink' 'black'],
    current_trace_colour = 1,

    create_source_coords = 100,         ;;; coords to put new sources - 100,100
    sim_running=false,
    sim_use_dial_panel = false,
    sim_dial_panel_for = false,           ;;; assigned to the vehicle to trace
    procedure(kill_windows, isball_object, brait_sim),

    brait_world,
    brait_control_panel,                ;;; main control panel
    remote_control_panel,               ;;; panel with sliders
    dial_panel,                         ;;; panel with dials

    activity_window,
    all_trace_windows = [],
    sim_all_windows  = [],
    trace_cycle_number = 0,

    orig_x, orig_y,
    Diameter,
    vehicle_rulesystem,
    ball_rulesystem,
    impulse, bounciness,

    demo_startrules_trace = false,
    demo_endrules_trace = false,
    demo_data_trace = false,
    demo_message_trace = false,
    demo_actions_trace = false,
    demo_cycle_trace = false,
    demo_cycle_pause = false,
    demo_end_sim_trace = false,
    demo_check_popready = false,

	;;; replaced calls of consword here. A.S. 23 Dec 2000
    sound = "sound",
    light = "light",
    heat = "heat",
    smell = "smell",
    proximity = "proximity",
    odometer = "odometer",
    left = "left",
    right = "right",
    centre = "centre",
    rear = "rear",
    compass = "compass",

    vehicle, vehicle1, vehicle2, vehicle3, vehicle4,
	vehicle5, vehicle6, vehicle7,
    vehicle8, vehicle9, vehicle10, vehicle11,
	vehicle12, vehicle13, vehicle14,

    source, source1, source2, source3, source4,

    box, box1, box2, box3, box4, box5, box6, box7, box8,

    ball1, ball2, ball3,

    ;;; declare some vars for dial control variables - NB more than 20 units in a
    ;;; vehicle will mean that more of these need to be declared to avoid 'declaring
    ;;; such and such' messages in output buffer
    dial1, dial2, dial3, dial4, dial5, dial6, dial7, dial8, dial9,
    dial10, dial11, dial12, dial13, dial14, dial15, dial16, dial17,
    dial18, dial19, dial20,
    leftmotordial, rightmotordial;


/*
-- CALL FILES ---------------------------------------------------------
*/

compilehere
    matrix_functions.p
    activation_functions.p
    decay_functions.p
    tools.p
    box_object.p
    source_object.p
    vehicle_agent.p
    ball_object.p
    mousehandlers.p
    interface.p
    tutorialsupplement.p
    ;

/*
-- TURN OFF ALL TRACING -----------------------------------------------
*/

false -> popradians;
false -> prb_chatty;
false -> prb_walk;
false -> prb_show_conditions;
false -> prb_show_ruleset;

define :method sim_agent_rulefamily_trace(object:sim_object, rulefamily);
enddefine;

define :method sim_agent_running_trace(object:sim_object);
enddefine;

define :method sim_agent_messages_out_trace(agent:sim_agent);
enddefine;

define :method sim_agent_messages_in_trace(agent:sim_agent);
enddefine;

define :method sim_agent_actions_out_trace(object:sim_object);
enddefine;

define :method sim_agent_action_trace(object:sim_object);
enddefine;

define :method sim_agent_ruleset_trace(object:sim_object, rulefamily);
enddefine;

define :method sim_agent_endrun_trace(object:sim_object);
enddefine;

define vars procedure sim_scheduler_pausing_trace(objects, cycle);
enddefine;


define vars procedure sim_post_cycle_actions(objects, cycle);
enddefine;

false -> pop_pr_ratios;

/*
'line' -> path_tracing;
'blob' -> path_tracing;
*/

/*
-- MAIN PROCEDURES ----------------------------------------------------
*/

/*
PROCEDURE: sim_edit_object_list (objects, cycle) -> objects
INPUTS   : objects, cycle
  Where  :
    objects is the current list of objects in the simulator
    cycle is the current sim_cycle number
OUTPUTS  : objects is the edited object list (with appropriate objects added
            or removed)
USED IN  : sim_scheduler
CREATED  : 7 Jul 2000
PURPOSE  : to edit the list of objects at the end of each cycle.
dkf - altered so that it also removes object graphic from display window


*/

define vars procedure sim_edit_object_list(objects, cycle) -> objects;

    unless sim_object_delete_list == [] then
        lvars obj;
        [% for obj in objects do
            if member(obj, sim_object_delete_list) then
                ;;;[DELETED ^obj]==>;  ;;;debug
                if isvehicle(obj) then
                    rc_remove_container(obj,brait_world);
                    dlocal rc_active_window_object = brait_world;
                    rc_undraw_linepic(obj);
                else
                    rc_remove_container(obj,brait_world);
                endif;
            else
                obj
            endif;
          endfor %] -> objects
    endunless;

    ;;;[new sim_objects = ^objects]==>;
   objects <> sim_object_add_list -> objects;

;;; MAY BE NEEDED FOR OBJECTS CREATED VIA MENU DURING RUNTIME
    for obj in sim_object_add_list do
        show_and_name_instance(sim_name(obj), obj, brait_world);
    endfor;

enddefine;




/*
PROCEDURE: sim_setup_scheduler (objects, number)
INPUTS   : objects, number
  Where  :
    objects is the current list of objects/agents
    number is the current cycle number
OUTPUTS  : NONE
USED IN  : sim_scheduler on every cycle
CREATED  : AS, 8 Oct 2000
PURPOSE  :
	Some commands, previously in sim_schedulder moved here

*/

define global vars procedure sim_setup_scheduler(objects, number);

	;;; The heap should not be repeatedly locked and unlocked, if X is being
	;;; used. Unfortunately that causes a memory leak. Hence this part
	;;; runs only once
	if sim_lock_heap then
		sys_unlock_heap();
		sysgarbage();
		sys_lock_heap();
		false -> sim_lock_heap;
		if isinteger(sim_minmemlim_after_lock) then
			sim_minmemlim_after_lock -> popminmemlim
		endif;
	endif;

	;;; moved here from sim_scheduler, by A.S.
	;;; dkf added - sim_dial_panel initiation - if needed
    if member(sim_dial_panel_for, sim_objects) then
        if not(rc_islive_window_object(dial_panel)) then
            make_dial_panel(sim_dial_panel_for);
        endif;
        true -> sim_use_dial_panel;
    else
        false -> sim_dial_panel_for;
        false -> sim_use_dial_panel;
    endif;
	;;; Moved by AS to brait/lib/vehicle_agent.p in RULE carry_out_movement
    ;;; syssleep(delay_time);

    ;;; dkf added - increment clock
    sys_real_time() - sim_start_time -> sim_time;

    ;;;dkf added - time tracing stuff
    ;;;rc_print_at(20, 20, round(sim_time) >< '');
    ;;;[duration ^time_slice_duration] ==>
            ;;;[clock ^sim_time] ==>
enddefine;



/*
PROCEDURE: sim_scheduler_finished (objects, cycle)
INPUTS   : objects, cycle
  Where  :
    objects is the current list of objects/agents
    cycle is the cycle number
OUTPUTS  : NONE
USED IN  : sim_scheduler
CREATED  : AS, 8 Oct 2000
PURPOSE  : Tidy up after demo ends.


*/

define vars procedure sim_scheduler_finished(objects, cycle);
    ;;; This is modified for brait to ensure everything finishes cleanly.
	;;; Invoked after sim_stop_scheduler (called in sim_setup_scheduler)
	;;; has run.

    /*
    lvars objects, cycle;

    ;;;pr(cycle >< ' \n');

    */

    false -> rc_mouse_selected(brait_world);

	;;; No longer needed: AS 7 Oct 2000
	;;; dkf added - for async control panel
    ;;; false -> do_stop;


    if do_finish then
        killwindows();
        false-> do_finish;
    endif;

enddefine;



/*

;;; TEMPORARY
PROCEDURE: rc_process_event_queue ()
INPUTS   : NONE
OUTPUTS  : NONE
USED IN  :	Event handlers in LIB rc_mousepic
CREATED  : A.Sloman 8 Oct 2000
PURPOSE  : Slightly modified here to prevent event handling
			while a picture is being drawn.


*/


/*
-- SHORTCUT -----------------------------------------------------------
*/

/*
PROCEDURE: brait_sim (lim)
INPUTS   : lim is the number of cycles to run the simulator for
OUTPUTS  : NONE
USED IN  :
CREATED  : 29 Aug 2000
PURPOSE  : to call sim_scheduler and run it with the current contents of the
brait_world window.


*/

define brait_sim(lim);

    lvars
       objects = copytree(rc_window_contents(brait_world));

	dlocal
    	;;; Moved here from sim_scheduler, by A.Sloman
        sim_running=true,
        delay_time=3,
        sim_start_time = sys_real_time();

    ;;; dkf added - slows down cycles - makes graphics smoother.
	lvars object;
    for object in objects do
        if isvehicle(object) or isball_object(object) then
            delay_time -1 -> delay_time;
        endif;
    endfor;
    if delay_time < 0 then
        0 -> delay_time;
    endif;
    ;;;[delay = ^delay_time]==>;

    sim_scheduler(objects, lim);

enddefine;


;;; for "uses"
global constant braitenberg_sim = true;

/*
-- REVISION NOTES
*/

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Dec 24 2000
	Added global variable trace_colours

	Replaced string constants with words, here and in other files.
	Changed names of some of the subsidiary files to use underscore

--- Aaron Sloman, Oct  8 2000

Made several changes to make this more compatible with SimAgent,
e.g. moved stuff out of sim_scheduler into other methods and procedures,
so that the redefined sim_scheduler is no longer needed.
Put some of the code into brait_sim, some into sim_setup_scheduler, etc.

Removed definitions of rc_draw_lines_rotated, sim_scheduler

Added temporary new version of rc_process_event_queue();
(Main definition is in LIB rc_mousepic)

Made do_stop a synonum for sim_stopping_scheduler, now handled
in LIB sim_agent

--- Duncan K Fewkes, Sep 25 2000
Altered rc_draw_lines_rotated.

Previously used "dlocal rc_sole_active_widget = brait_world" to avoid messy
graphics. This led to bugs and crashing out when mouse over control panel
(seemed to think control panel was sim_multiwin and so tried to get rc_coords
using sim_picframe call, which caused fail_generic.)

Currently, graphics seem fine (?), fingers crossed.
--- Duncan K Fewkes, Sep 21 2000
added global var "random_move_source_on_collision" = FALSE or a numeric value.
If it is assigned a value, whenever a vehicle collides with a source, the
procedure randomise_position is called using the value.

--- Duncan K Fewkes, Aug 31 2000
added global vars "sim_use_dial_panel", "sim_dial_panel_for"
and added check in sim_scheduler to make sure they are assigned the correct
values - (sim_dial_panel_for is the object to have units traced,
sim_use_dial_panel is true or false)

--- Duncan K Fewkes, Aug 30 2000
converted to lib format


-- LIST OF PROCEDURES
	(created by "ENTER indexify define")
	(Use <ENTER> gg to access required sections)

 define :method sim_agent_rulefamily_trace(object:sim_object, rulefamily);
 define :method sim_agent_running_trace(object:sim_object);
 define :method sim_agent_messages_out_trace(agent:sim_agent);
 define :method sim_agent_messages_in_trace(agent:sim_agent);
 define :method sim_agent_actions_out_trace(object:sim_object);
 define :method sim_agent_action_trace(object:sim_object);
 define :method sim_agent_ruleset_trace(object:sim_object, rulefamily);
 define :method sim_agent_endrun_trace(object:sim_object);
 define vars procedure sim_scheduler_pausing_trace(objects, cycle);
 define vars procedure sim_post_cycle_actions(objects, cycle);
 define vars procedure sim_edit_object_list(objects, cycle) -> objects;
 define global vars procedure sim_setup_scheduler(objects, number);
 define vars procedure sim_scheduler_finished(objects, cycle);
 define brait_sim(lim);

 */
