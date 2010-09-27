/* --- Copyright University of Birmingham 2003. All rights reserved. ------
 > File:            $poplocal/local/sim/lib/sim_harness.p
 > Purpose:			Provide basic classes and test harness for sim_agent,
					for simple demonstrations.
 > Author:          Aaron Sloman, Feb 24 1999 (see revisions)
 > 					with help from Brian Logan
 > Documentation:	HELP SIM_HARNESS
					HELP SIM_AGENT, TEACH SIM_AGENT, TEACH SIM_FEELINGS
 > Related Files:	LIB * SIM_AGENT, LIB * POPRULEBASE

CONTENTS

 -- Load required libraries
 -- define lists of variables to control tracing and pausing
 -- Define utilities for printing, etc.
 -- Modified versions of tracing procedures
 -- Procedures to set up and run the simulation
 -- Setup simulation
 -- Procedures continue_run, run_simulation

 */

section;

/*
-- Load required libraries

*/
uses simlib
uses sim_picagent
uses sim_control_panel

global vars
	all_agents,
	sim_all_windows = [],
;


/*
-- define lists of variables to control tracing and pausing
*/

global vars

    ;;; sim_alltracevars can be given as fourth argument
	;;; 	to run_simulation_withvars.
    ;;; All these variables will have their values set false.
	;;; This list can be extended by users, as in TEACH SIM_FEELINGS

    sim_alltracevars =
        [
			;;; Poprulebase variables (See HELP POPRULEBASE)
			prb_walk prb_chatty prb_show_conditions

			;;; SIM_HARNESS variables (defined below).
			demo_startrules_trace demo_endrules_trace
			demo_data_trace demo_message_trace
			demo_actions_trace
			demo_cycle_trace demo_cycle_pause
			demo_end_sim_trace
			demo_check_popready

			;;; switch garbage collection tracing on or off
			popgctrace],

    ;;; Use mintracevars for the tracevars argument to run_simulation_withvars.
	;;; Their values will be set true. Add more items from the above list
	;;; sim_alltracevars to get more trace output.

    mintracevars = [demo_endrules_trace demo_cycle_trace demo_cycle_pause ],

	;

;;; Individual variables for controlling tracing and pausing
global vars

	demo_pause_delay = 5, ;;; pause every demo_pause_delay cycles

	demo_startrules_trace,
	demo_endrules_trace,
	demo_data_trace,	;;; Has more effect if one of previous two on
	demo_message_trace,
	demo_actions_trace,
	demo_cycle_pause,
	demo_cycle_trace,
	demo_end_sim_trace,
	demo_check_popready,
	/* See
		HELP POPRULEBASE/prb_sayif_trace
		This is a user definable list of words which are associated
		with SAYIF poprulebase actions.
	*/
	prb_sayif_trace = [],

	;;; number of decimal points in printing
	sim_pr_places = 2,

	;;; show entities as they are created in setup_simulation
	sim_show_entities = true,

    ;;; set this false to disable PAUSE actions
    prb_pausing = true,
	;

/*
;;; Other things that can be traced and untraced as required
;;; These are just examples. See HELP POPRULEBASE

;;; Compile these lines as needed.
trace sim_sense_agent sim_run_sensors;
untrace sim_sense_agent sim_run_sensors;

trace prb_add;
untrace prb_add;

trace prb_flush;
untrace prb_flush;
*/


/*
-- Define utilities for printing, etc.

*/
define print_loc_heading(type, name, x, y, heading);
	;;; Useful printing utility for objects with a location and
	;;; a heading, e.g. used in TEACH SIM_FEELINGS
	;;; See HELP PRINTF

    dlocal
		pop_pr_places = sim_pr_places,
		pop_pr_quotes = false;

    printf(
        '<%P %P at (%P %P) heading %P>', [% type, name, x,y, heading%])

enddefine;

define print_loc(type, name, x, y);
	;;; Useful printing utility for objects without a heading

    dlocal
		pop_pr_places = sim_pr_places,
		pop_pr_quotes = false;

    printf(
        '<%P %P at (%P %P)>', [% type, name, x, y%])
enddefine;


define check_finish(cycle);
    ;;; A utility which can be invoked to give the user the option
	;;; to abort, invoke popready (See HELP POPREADY) or continue
    lconstant
		yeslist = [y Y yes YES],
		nolist = [n N no NO];

    [Finished cycle ^cycle] =>
    repeat
        'Stop? (y/n), p = popready' =>
        lvars reply = readline();
        if reply == [] or member(hd(reply), nolist) then
            ;;; do nothing
            quitloop();
        elseif member(hd(reply), yeslist) then
            'Stopping' =>
            sim_stop_scheduler();
        elseif reply = [p] then
            popready();
        else pop11_compile(reply);
        endif;
    endrepeat;

enddefine;

;;; A utility procedure to exit from a popready break, instead
;;; of typing ENTER end_im (See HELP POPREADY)

define ved_cont();
    ;;; "continue"
    ;;; do "ENTER cont" to finish a Popready break in VED.
    ved_end_im();
enddefine;

/*
;;; A utility function to obey a list in the form
;;;	[<proc> <arg1> <arg2> ....]
;;; where <proc> is the name of a procedure or the procedure

;;; Tests:

obey_list([+ 3 8])=>
obey_list([member cat [pig cat dog mouse]])=>
obey_list([member 999 [pig cat dog mouse]])=>
*/

define lconstant obey_list(list);
	;;; apply the head of the list to the things in the tail,
	;;; but de-reference the head
	recursive_valof(hd(list))(explode(tl(list)))
enddefine;

/*
;;; A utility function to obey a list in the form
;;;	[<proc> <arglist1> <arglist2> ....]
;;; where <proc> is the name of a procedure or the procedure
;;; and each arglist is a list of arguments for proc

;;; Tests:

define addall(list);
	if null(list) then 0
	else hd(list)+addall(tl(list))
	endif;
enddefine;

applyto_all("addall", [[3 8] [4 9] [16 25 36 49]])=>
applyto_all(maplist(%sqrt<>round%), [[3 8] [4 9] [16 25 36 49]])=>
applyto_all("rev", [[pig cat dog mouse] [1 2 3 ]])=>
*/


define lconstant applyto_all(proc, list);
	;;; Apply proc separately to to each item in list.
	;;; proc may be a procedure the name of a procedure
	lvars
		item,
		procedure proc_val = recursive_valof(proc);
	
	for item in list do
		proc_val(item)
	endfor;
enddefine;
	


/*
-- Modified versions of tracing procedures ----------------------------

The SIM_AGENT toolkit provides a large collection of methods and
procedures which can be redefined by the user to provide a lot of
"tracing" or debugging information, by printing to the terminal, or
drawing something on the screen, or allowing users to interact with
programs. By default most of the trace procedures are defined to do
nothing.

Some of them are redefined below to be controlled by global variables, which
the user can make true or false to turn the tracing on or off. The second
argument of run_simulation is a list of variables to be made true.

These methods and procedures are defined in the same order as in
LIB * SIM_AGENT.
(Some of the methods are not redefined: the definitions have been
copied for convenience.)

*/

define :method sim_agent_running_trace(agent:sim_agent);
    ;;; This is applied to each sim_agent (but not object) before running its
    ;;; rules, and after incoming messages and sensor data have beeb added
	;;; to the agent's database.
	;;; Default is to do nothing unless the variable demo_data_trace
    ;;; is made true, in which case the whole database is printed out.
	;;; Redefine for individual subclasses to make printing more selective.

    if demo_data_trace then
        [STARTING ^(sim_name(agent)) with data:] ==>
        prb_print_table(sim_get_data(agent));
    endif

enddefine;

define :method sim_agent_messages_out_trace(agent:sim_agent);
    ;;; At the end of the time slice show the messages waiting to
    ;;; be delivered from this agent to other agents.
    if demo_message_trace then
        lvars messages = sim_out_messages(agent);
        ['New messages out' ^(sim_name(agent)) ^messages] ==>
    endif
enddefine;


define :method sim_agent_messages_in_trace(agent:sim_agent);
    ;;; If demo_message_trace is true, show the incoming messages waiting
    ;;; to be processed just before the agent runs its rulesystem
    if demo_message_trace then
        '------------------------------------------------------' =>
        lvars messages = sim_in_messages(agent);
        ['New messages in' ^(sim_name(agent)) ^messages] ==>
    endif
enddefine;

/*
;;; Removed. See revision note
define :method sim_agent_actions_out_trace(object:sim_object);
	;;; By default, no tracing for static objects
enddefine;
*/

define :method sim_agent_actions_out_trace(object:sim_object);
    ;;; Called at the end of each object's time slice, to show which
    ;;; actions have been transferred from the object's database to its
    ;;; sim_actions slot, so that they can be run at the end of the
    ;;; time slice.
    if demo_actions_trace then
        lvars actions = sim_actions(object);
        [New actions ^(sim_name(object)) ^actions] ==>
    endif;
enddefine;

define :method sim_agent_action_trace(object:sim_object);
    if demo_actions_trace then
        lvars actions = sim_actions(object);
        [Doing actions ^(sim_name(object)) ^actions] ==>
    endif;
enddefine;

/*
Removed empty versions of sim_agent_rulefamily_trace and other trace
methods.
See revision notes

*/

define :method sim_agent_rulefamily_trace(object:sim_object, rulefamily);
    ;;; In each time slice, for each agent or object, before each
    ;;; ruleset or rulefamily is run, print out the ruleset or
    ;;; rulefamily contents, and also the contents of the database,
    ;;; but only if demo_startrules_trace is true.
    if demo_startrules_trace then
		lvars message =
			if isprb_rulefamily(recursive_valof(rulefamily)) then
				'Try rulefamily'
			else
				'Try ruleset'
			endif;

		[^message ^rulefamily 'in object' ^(sim_name(object))]==>
		if demo_data_trace then
        	'DATABASE: ' =>
        	prb_print_table(sim_get_data(object));
		endif;
    endif
enddefine;


define :method sim_agent_endrun_trace(object:sim_object);
    ;;; After an object or agent has had its rulesystem run
    ;;; this can be used to print out information such as its
    ;;; current database contents.
    if demo_endrules_trace then
        ['Finished rulesystem:' ^(sim_name(object)). Cycle ^sim_cycle_number]==>
        if demo_data_trace then
            'DATABASE:'=>
            prb_print_table(sim_get_data(object));
        endif;
        readline()->;
    endif
enddefine;

global vars
	;;; If this made true, sim_scheduler_pausing_trace will cause the
	;;; simulation to exit
	sim_terminate_simulation = false,
	;;; if this is made true the simulation will pause at the end of
	;;; the current time-slice
	sim_pause_demo = false,
	;;; if this is an integer > 0 pause that number of hundredths of a
	;;; second at the end of each cycle
	sim_delay = 0;

define sim_scheduler_pausing_trace(objects, cycle);
    ;;; Invoked by sim_scheduler at the end of each time slice.
    ;;; It allows arbitrary tracing or pausing mechanisms defined by the
    ;;; user to run, e.g. to interrogate the internal databases of
    ;;; selected objects, or to save the state of the pictures on the
    ;;; screen, etc.

	if sim_terminate_simulation then sim_stop_scheduler() endif;

    if demo_cycle_trace then
        pr('==== end of cycle ' >< cycle >< '=====\n');
    endif;

	if sim_pause_demo then
		'Press RETURN to continue'=>
		readline()-> ;
		false -> sim_pause_demo
	elseif demo_check_popready and sim_cycle_number mod demo_pause_delay == 0 then
        check_finish(cycle);
	elseif demo_cycle_pause then
		readline() ->;
	elseif isinteger(sim_delay) and sim_delay > 0 then
			syssleep(sim_delay)
    endif;
enddefine;


define sim_scheduler_finished(objects, cycle);
	if demo_end_sim_trace then
	 	pr('\n==== Finished. Cycle ' >< cycle >< ' ==== \n');
	endif;
enddefine;


/*
;;; Removed. See revision note
define :method sim_agent_terminated_trace(object:sim_object
        						number_run, runs, max_cycles);

    ;;; After an agent's rulesystem is run, this procedure is given the
    ;;; agent, the number of actions run, the number of times the
    ;;; rulesystem has been run, the maximum possible number
    ;;; (max_cycles). It runs before the actions trace and the
    ;;; messages out trace procedures.

enddefine;
*/


define no_objects_runnable_trace(objects, cycle);
	;;; user definable trace procedure invoked if
	;;; no object was runnable in the cycle.
enddefine;


/*
-- Procedures to set up and run the simulation

*/

;;; a utility to find out which variables are true
define true_vars(list) -> newlist;
	lvars word;
	[%
		for word in list do
			if valof(word) then word endif
		endfor;
	%] -> newlist;
enddefine;



;;; Procedure to be defined by users. E.g. See TEACH SIM_FEELINGS
global vars
    sim_demo_cycles,	;;; defined in sim_control_panel
	procedure setup_simulation;

define run_simulation_withvars(agents, num, file, notracevars, tracevars, showedit);
    ;;; Beginners can ignore the details of this procedure.

	;;; this is used to set the slider
	num -> sim_demo_cycles;

    ;;; Run the scheduler on the agents for num cycles

    ;;; If file is a string, store the output in the file
    ;;; If notracevars is a non-empty list of words their values
    ;;;     will be made false

    ;;; If tracevars is a non-empty list of words their values
    ;;;     will be made true

    ;;; There is no check for overlap between the two lists!

    ;;; If showedit is false, output to VED will not be shown till the
    ;;; end (this can speed things up considerably).

    ;;; record initial editing state
    lvars wasediting = vedediting;

	;;; Specify decimal places when printing numbers
    dlocal pop_pr_places = sim_pr_places;

	;;; do not use dlocal because of process switching, e.g. in Ved
	;;; and event handlers
	false ->> sim_terminate_simulation -> sim_pause_demo;

	if isrc_window_object(sim_panel) and rc_widget(sim_panel) then
		;;; let this override tracevars
		true_vars(notracevars) -> tracevars;
	elseif tracevars /== [] then
		;;; If tracevars non-empty, then use notracevars and tracevars
		;;; to control which variables are true and which false.
		;;; before recreating the panel.
    	lvars word;
    	for word in notracevars do false -> valof(word) endfor;
    	for word in tracevars do true -> valof(word) endfor;
	endif;

    ;;; set up tracing and control panel

	if isrc_window_object(sim_panel) and rc_widget(sim_panel) then
		rc_redraw_panel(sim_panel)
	else
		lvars oldwin_obj = rc_current_window_object;
		;;; create control panel
    	sim_control_panel(10,10,sim_alltracevars,2,'Control');
		oldwin_obj -> rc_current_window_object;
	endif;

    unless ispair(all_agents) then
        ;;; create the agents and display the world
        setup_simulation();
    endunless;

    dlocal
        cucharout,   ;;; default print output consumer
        vedediting = showedit;

    if isstring(file) then
        ;;; re-direct print output to file
        discout(file) -> cucharout;
    elseif isprocedure(file) then
        ;;; could be erase, for no output, or a character consumer
        file -> cucharout
    endif;

	lvars
		windows = rc_pic_containers(hd(all_agents)),
		win_obj = if windows == [] then false else hd(windows) endif;

	;;; re_draw all windows, in case corrupted before pause
	applist(windows, rc_redraw_window_object);

	;;; Prepare window for objects. (Should not be necessary)
	if win_obj then win_obj -> rc_current_window_object endif;

    ;;; Run the demo for num cycles. Return new list of agents,
	;;; in case running the program had changed the list.
    sim_scheduler_objects(all_agents, num) -> all_agents;

    ;;; Sort out output to file.
    if file then
        ;;; finalise the output and close the file
        pr(newline);
        cucharout(termin)
    elseif wasediting and not(vedediting) then
        chain(vedrefresh)
    endif;

enddefine;



/*

-- Setup simulation

*/


define killwindows();
    ;;; Get rid of old windows if necessary.
	;;; Assumes sim_all_windows is a list of names of windows
	;;; or windows.

	lvars win_name, win;
	for win_name in sim_all_windows do
		recursive_valof(win_name) -> win;
    	if isrc_window_object(win) then
        	rc_kill_window_object(win);
			if isword(win_name) then
    			false -> valof(win_name);
			endif;
    	endif;
	endfor;
	[] -> sim_all_windows;
	false -> rc_current_window_object;
enddefine;


define setup_simulation(setup_info);

    ;;; Get rid of old windows if necessary.
    killwindows();

	lvars spec, instructions, final, startwin = false;

	for spec in setup_info do
		;;; uncomment for debugging
		;;;[spec ^spec]==>

		lvars key, rest;
		dest(spec) -> (key, rest);
		if key == "WINDOW" then

			lvars win_info;
			for win_info in rest do
				lvars win_name, win_spec, win_frame, win;
				win_info --> ! [?win_name ?win_spec];
				
				;;; make sure the name is declared as a variable
				sysVARS(win_name, 0);

				unless startwin then win_name -> startwin endunless;
				
				if isrc_window_object(win_spec) then
					win_spec -> win
				else
					
					;;; Create new scenario window using win_spec, which should
					;;; be a list or vector of arguments for rc_new_window_object

    				;;; First two numbers give location, then width and height, then
    				;;; vector with location of origin and Xscale and Yscale,
    				;;; then window title, then vector with 4 numbers representing
					;;; transformation from sim to pic coords.

    				rc_new_window_object(
						explode(win_spec) ->win_frame, newsim_picagent_window) -> win;
						fill(explode(win_frame), sim_picframe(win)) ->;
						;;;; [win_frame ^win_frame] ==>
						
				endif;
				win -> valof(win_name);
				;;; [window ^win_name ^(sim_picframe(win))] ==>

    			;;; Make the window mouse and key sensitive
    			rc_mousepic(win);

				;;; keep a record of newly created windows.
				[^^sim_all_windows ^win] -> sim_all_windows;
			endfor;

		elseif key == "STARTWINDOW" then
			hd(rest) -> startwin;

		elseif key == "ENTITIES" then

			[%
    			;;; Use the lists of specifications of types of
				;;; entities to create lists of actual instances
				lvars entity_spec;

				for entity_spec in rest do
					;;; entity_spec is of form
					;;; [<type_name> <windows> <creator> <entity> <entity> .....]
					lvars type_name, win, proc;

					destpair(destpair(destpair(entity_spec)))
						-> (type_name, win, proc, entity_spec);

					recursive_valof(proc) -> proc;
					recursive_valof(win) -> win;
					if islist(win) then
						maplist(win, recursive_valof) -> win;
						hd(win)
					else win
					endif -> ; ;;;rc_current_window_object;

					;;; declare the type name as a global variable
					sysVARS(type_name, 0);

					;;; make a list of the new entities and assign it
					;;; to that variable
					[%	lvars spec;
						for spec in entity_spec do
							proc(spec, win)
						endfor
					%] -> valof(type_name);

					;;; and put the entities in the global list all_agents
					explode(valof(type_name));
					if sim_show_entities then
						[^type_name ^(valof(type_name))]==>
					endif;
				endfor
		  	%] -> all_agents;

		elseif key == "DO" then
			lvars action;
			for action in rest do
				obey_list(action)
			endfor;

		elseif key == "INSTRUCTIONS" then
			rest -> instructions;

		elseif key == "FINAL" then
			rest -> final;

		else
			mishap('UNRECOGNIZED SETUP KEY', [^key ^rest])
		endif;
    endfor;

	if startwin then
		lvars win = recursive_valof(startwin);
		if isrc_window_object(win)
		and rc_widget(win)
		then
			win -> rc_current_window_object
		endif;
	endif;

	;;; Now run the final setup procedures

	maplist(final, recursive_valof<>apply);

	;;; print instructions:
	pr(newline);
	lvars string;			
	for string in instructions do string => endfor;

enddefine;

/*
-- Procedures continue_run, run_simulation
*/

;;; A run program, with default pausing and graphics.

define continue_run(num, tracevars);
	;;; assumes that the setup procedure has been run
	;;; can be used to continue running after interrupting.

    run_simulation_withvars(
		all_agents, num, false, sim_alltracevars, tracevars, true);

    pr('\nTo continue do this:\n\tcontinue_run('
        	>< sim_demo_cycles >< ', []);\n');
enddefine;


;;; A procedure to run setup_simulation, pause, then continue_run

global vars sim_setup_info = []; ;;; to be created by user

define run_simulation(setup_info, num, tracevars);

	;;; needed to set control panel
	num -> sim_demo_cycles;

    ;;; set up tracing and control panel
    lvars word;
    for word in sim_alltracevars do false -> valof(word) endfor;
    for word in tracevars do true -> valof(word) endfor;

	if isrc_window_object(sim_panel) and rc_widget(sim_panel) then
		rc_redraw_panel(sim_panel)
	else
		lvars oldwin_obj = rc_current_window_object;
		;;; create control panel
    	sim_control_panel(10,10,sim_alltracevars,2,'Control');
		oldwin_obj -> rc_current_window_object;
	endif;

    setup_simulation(setup_info);

    ;;; Readline will pause until user presses RETURN
    readline() -> ;

	;;; find which tracevars are still true, as user may have
	;;; changed some using the panel
	lvars newtracevars = true_vars(sim_alltracevars);

    continue_run(num, newtracevars);
enddefine;


global vars sim_harness = true; 	;;; for uses

endsection;


/*
CONTENTS

 define print_loc_heading(type, name, x, y, heading);
 define print_loc(type, name, x, y);
 define check_finish(cycle);
 define ved_cont();
 define lconstant obey_list(list);
 define addall(list);
 define lconstant applyto_all(proc, list);
 define :method sim_agent_running_trace(agent:sim_agent);
 define :method sim_agent_messages_out_trace(agent:sim_agent);
 define :method sim_agent_messages_in_trace(agent:sim_agent);
 define :method sim_agent_actions_out_trace(object:sim_object);
 define :method sim_agent_actions_out_trace(object:sim_object);
 define :method sim_agent_action_trace(object:sim_object);
 define :method sim_agent_rulefamily_trace(object:sim_object, rulefamily);
 define :method sim_agent_endrun_trace(object:sim_object);
 define sim_scheduler_pausing_trace(objects, cycle);
 define sim_scheduler_finished(objects, cycle);
 define :method sim_agent_terminated_trace(object:sim_object
 define no_objects_runnable_trace(objects, cycle);
 define true_vars(list) -> newlist;
 define run_simulation_withvars(agents, num, file, notracevars, tracevars, showedit);
 define killwindows();
 define setup_simulation(setup_info);
 define continue_run(num, tracevars);
 define run_simulation(setup_info, num, tracevars);

*/

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jan 12 2003
		At the suggestion of Nick Hawes altered
			sim_agent_rulefamily_trace
		To print different information for rulesets and rulefamilies.

		Also fixed some methods that were wrongly defined only for agents,
		to apply at a higher level, i.e. to objects.

--- Aaron Sloman, May 13 2002
	On the suggestion of Manuela Viezzer made tracing for sim_object instances
	more consistent with that in LIB sim_agent, e.g.
	removed new definitions for these procedures which stopped them
	performing their default actions.
		define :method sim_agent_actions_out_trace(object:sim_object);
	    define :method sim_agent_rulefamily_trace(object:sim_object, rulefamily);
		define :method sim_agent_endrun_trace(object:sim_object);

	This one had a change that could cause bugs. Re-set to system default
		define :method sim_agent_terminated_trace(object:sim_object
        									number_run, runs, max_cycles);

--- Aaron Sloman, Jul 30 2000
	Made to use sim_get_data
--- Aaron Sloman, Jul  6 2000
	Changed to use sim_scheduler_objects, following a suggestion by
	Matthias Scheutz. This saves the current set of agents in all_agents.
	Also changed to use sim_demo_cycles, defined in sim_control_panel
--- Aaron Sloman, Feb 27 1999
	Added more trace procedures/methods and more trace variables to
	control them.
 */
