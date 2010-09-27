/* --- Copyright University of Birmingham 2003. All rights reserved. ------
 > File:            $poplocal/local/newkit/sim/lib/sim_agent.p
 > File:            $poplocal/local/sim/lib/sim_agent.p
 > Purpose:			Uses poprulebase and objectclass
 >					To provide simulations for sophisticated agents
 > 						Sim_agent toolkit Version 6.0
 > Author:          Aaron Sloman, Jul  3 1999 (see revisions)
 > Originally:          Aaron Sloman, Oct 17 1994
 > Documentation:	HELP SIM_AGENT, HELP NEWKIT, HELP RULESYSTEMS
 > 					HELP * POPRULEBASE *OBJECTCLASS
 >					HELP * RULESYSTEMS, TEACH * SIM_DEMO
 > Related Files:	LIB * POPRULEBASE, PRB_EXTRA, PRB_FILTER * OBJECTCLASS
 >					LIB * RULEFAMILY, * SETUP_RULESYSTEM
 */

/*

TODO

	Update news about disabled sim_*ruleset_limit(rulesetname)
	Update news about sim_shared_data and other changes

*/

/*

CONTENTS - (Use <ENTER> g to access required sections)
[This index produced with "ENTER indexify"]
 -- VERSION SPEC
 -- GLOBAL VARIABLES
 -- UTILITY PROCEDURES
 -- DEFINE CLASS SIM_OBJECT
 -- DEFINE CLASS SIM_AGENT
 -- FACILITIES FOR AGENTS WITH SHARED DATABASES
 -- UTILITIES FOR MANIPULATING THE DATABASE IN AN OBJECT
 -- SOME USER DEFINABLE FACILITIES (E.G. FOR TRACING)
 -- INTERFACE PROCEDURES, CALLED ONCE PER CYCLE
 -- PROCEDURE TO EDIT THE AGENT LIST
 -- OPTIONAL EXTENSION FOR SOME AGENTS USING A STACK OF DATABASES, ETC.
 -- NOW THE MAIN PROCESS MANAGEMENT PROCEDURES
 -- SOME AGENT UTILITIES FOR SENSING
 -- RUNNING AN OBJECT
 -- ABORTING AN AGENT'S RULESYSTEM
 -- POST-PROCESSING MESSAGES AND ACTIONS
 -- THE MAIN SCHEDULER
 -- PROCEDURES FOR "ABNORMAL" STOPPING
 -- REVISION NOTES
 -- Version 5: July 4th 1999
 -- Version 3
 -- Version 2

*/

section;

;;; Increase popmemlim if necessary

max(2000000, popmemlim) -> popmemlim;

;;; In order to access objectclass in V14.5 it may be necessary
;;; to do
;;; 	load $popproto/objectclass/objectclass.p

uses objectclass;

uses prblib;
uses poprulebase;

uses simlib;


;;; Make this true if you want each rule to have its current
;;; section recorded, and then reinstated at run time.
;;; controls IFSECTIONS. Default is false.
global vars prb_use_sections;

unless isboolean(prb_use_sections) then
	false -> prb_use_sections
endunless;


;;; This is about to become redundant because of the new mixin
;;; sim_shared_data_object and the method sim_get_data

global vars sim_use_shared_data;
unless isboolean(sim_use_shared_data) then
	false -> sim_use_shared_data
endunless;


;;; This can be used to turn off mechanisms for sections at compile time
;;; See prb/include/IFSECTIONS.ph
;;; controlled by prb_use_sections. Default false
include IFSECTIONS

/*
-- VERSION SPEC
*/

;;; Version is a list, with major version name, and date last changed
global constant sim_version = ['V6.0' '00.07.30'];

/*
-- GLOBAL VARIABLES
*/

global vars
	;;; When sim_scheduler is run, it assigns its first argument to this.
	sim_objects,

	;;; When an object is being processed it is assigned to this variable
	sim_myself,

	;;; Variable set and incremented in sim_scheduler
	sim_cycle_number,

	;;; variable specifying number of milliseconds of simulated time
	;;; per scheduler cycle.
	sim_cycle_milliseconds = false,

	;;; Make this false if you don't want heap locked by
	;;; sim_setup_scheduler(objects, number);
	sim_lock_heap = true,

	;;; If a number this is assigned to popminmemlim after the heap
	;;; is locked. E.g. try 4000000
	sim_minmemlim_after_lock = false,

	;;; make this true to replace all rulesets by their names
	;;; or make it false to replace none of them by their names
	;;; or make it a list of names to selectively replace some by
	;;; their names. Default set true, below
	sim_use_ruleset_names,

	;;; Keys to be suppressed during calls of prb_print routines
	sim_noprint_keys = [RULE_SYSTEM RULE_CLUSTER RULE_SYSTEM_STARTUP
		%
			IFSECTIONS
			"RULE_SYSTEM_SECTION";
		%],

	;;; Default value for size of sim_data property for internal
	;;; object/agent databases. See declaration of sim_object to see use.
	;;; The default reflects the likely number of distinct TYPES of
	;;; database items for each instance of class sim_object.
	;;; default value assigned below
	sim_dbsize,

	;;; Make this true to enforce termination at end of current
	;;; time slice
	sim_stopping_scheduler = false,

	;;; if true will make unique names for rulefamilies and rulesets
	;;; make it false to leave names unchanged.
	sim_unique_cluster_name,

	;;; make this true to get trace printout when a rulecluster is
	;;; added to the database in sim_setup. Default is false
	sim_add_rulecluster_trace,

	;;; make this true to get trace printout when a rulesystem is
	;;; added to the database in sim_setup. Default is false
	sim_add_rulesystem_trace,
;

;;; default size of database hash table?
if isundef(sim_dbsize) then 23 -> sim_dbsize; endif;

if isundef(sim_use_ruleset_names) then true -> sim_use_ruleset_names endif;

if isundef(sim_unique_cluster_name) then true -> sim_unique_cluster_name endif;

if isundef(sim_add_rulecluster_trace) then false -> sim_add_rulecluster_trace endif;

if isundef(sim_add_rulesystem_trace) then false -> sim_add_rulesystem_trace endif;


/*
-- UTILITY PROCEDURES
*/

/*
;;; TESTS for sim_interval_test

;;; This should come out true about once every 5 times.
repeat 100 times sim_interval_test(5.0, 1) endrepeat=>

;;; Half day. This should produce alternating true/false
	1000*60*60*12-> sim_cycle_milliseconds;
	vars cycle;
	for cycle from 1 to 10 do
		sim_interval_test("day", cycle)
	endfor=>


;;; 10 Minutes. This should produce 1 true in every 6
	1000*60*10-> sim_cycle_milliseconds;
	vars cycle;
	for cycle from 1 to 24 do
		sim_interval_test("hour", cycle)
	endfor=>

*/

define vars procedure sim_interval_test(interval, cycle_number) -> boole;
	;;; user definable check for whether it is time to run an agent,
	;;; rulesystem or rulecluster with an activation interval.

	lconstant errstring = 'Unrecognized interval type';

	if isdecimal(interval) then
		if interval <= 1.0 then
		 	random(1.0) < interval
		else
			mishap('Decimal valued interval should be < 1.0', [^interval]);
		endif;
	elseif sim_cycle_milliseconds then
		lconstant
			secs = 1000,
			mins = secs*60,
			hours = mins*60,
			days = hours*24;

		if interval == "second" then
			cycle_number mod round(secs/sim_cycle_milliseconds) == 0
		elseif interval == "minute" then
			cycle_number mod round(mins/sim_cycle_milliseconds) == 0
		elseif interval == "hour" then
			cycle_number mod round(hours/sim_cycle_milliseconds) == 0
		elseif interval == "day" then
			cycle_number mod round(days/sim_cycle_milliseconds) == 0
		else
			mishap(errstring, [^interval]);
		endif;
	else
		mishap(errstring, [^interval]);
	endif -> boole;
enddefine;
	

define lconstant procedure sim_stack_check(object, len, name, cycle);
	lvars object, len, name, cycle, inc, mess, vec = {};
	stacklength() - len -> inc;
	returnif(inc == 0);

	if inc fi_> 0 then
		consvector(inc) -> vec;
		'Stack increased by ',
	else
		'Stack decreased by '
	endif sys_>< abs(inc) sys_>< ' items in cycle ' sys_>< cycle -> mess;
	;;; Reduce call stack before calling mishap
	chain(mess, ['In' ^name, ^object %explode(vec)%], mishap)
enddefine;

/*
;;; NO LONGER NEEDED
    define sim_remove_all(patterns, data) -> (prb_database, found);
*/

define global vars syntax ^ with_nargs 1;
	;;; redefine this so that we can use [apply ^ xxx] to get the
	;;; valof("xxx")
	if $-prb$-in_prb_instance then
		recursive_valof();
	else
		mishap('USE OF ^ OUTSIDE STRUCTURE EXPRESSION', [])
	endif
enddefine;

define updaterof ^ with_nargs 2;
	-> valof();
enddefine;

define global vars syntax >^ with_nargs 2;
	;;; define this so that we can use [apply >^ 3 xxx] to do
	;;; 3 -> valof("xxx")
	if $-prb$-in_prb_instance then
		-> valof();
	else
		mishap('USE OF >^ OUTSIDE STRUCTURE EXPRESSION', [])
	endif
enddefine;

define global vars syntax *^ with_nargs 1;
	;;; redefine this so that we can use [apply *^ xxx] to get the
	;;; effect of xxx(sim_myself)
	if $-prb$-in_prb_instance then
		lvars word;
		-> word;
		recursive_valof(word)(sim_myself);
	else
		mishap('USE OF *^ OUTSIDE STRUCTURE EXPRESSION', [])
	endif
enddefine;

define global vars syntax >*^ with_nargs 1;
	;;; redefine this so that we can use [apply >*^ 3 xxx] to get the
	;;; effect of 3 -> xxx(sim_myself)
	if $-prb$-in_prb_instance then
		lvars word;
		-> word;
		-> (recursive_valof(word))(sim_myself);
	else
		mishap('USE OF >*^ OUTSIDE STRUCTURE EXPRESSION', [])
	endif
enddefine;

/*
-- DEFINE CLASS SIM_OBJECT
Define generic object class for the simulation. Other object and agent
classes will be subclasses of this.

Slots provided:

- the agent's name
- information available to detectors in other agents,
- information used by or updated by the scheduler,
- an action buffer for actions to be done on the current cycle,
  which will be performed for all objects after they have been given
  a time-slice by the scheduler.

In addition there are slots for
- the agent's private database
- the agent's default ruleset (which may invoke other rulesets).
- stacks recording the currently saved contexts, if necessary.

Other fields may be added later, e.g. for sets of rules used by the
agent, or some kind of preferred ordering of rulesets (contexts).

Note:
In the original version it was assumed that prb_repeating should be false,
preventing the same rule from being fired on the same database items. This
carried a memory management load and was withdrawn in poprulebase V2.

*/

define :class sim_object;
	;;; The top level simulation agent class
	slot sim_name = gensym("object");

	;;; The object is given a word based on its name, to be used as the
	;;; argument for gensym in sim_setup
	slot sim_component_root == false;

	;;; A table for mapping words to rulesets, etc.
	slot sim_valof = newproperty([], 17, false, "tmparg");

	;;; If an agent has speed N, then it runs N times in every cycle
	;;; of the scheduler.
	slot sim_speed == 1;

	;;; Default third argument for prb_run, for each ruleset.
	;;; Determines default number of cycles per ruleset, per time slice.
	;;; overridden by "with_limit" in rulesystem definitions.
	slot sim_cycle_limit == 1;

	;;; Interval at which this object will run. Default - every cycle
	slot sim_interval == 1;

	slot sim_status == undef;	;;; could be "alive" "dead", "ill", etc.

	;;; Each object has a database of local information
	;;;		held in a property table
	;;; and a default collection of rulesets set up on each cycle
	;;; by sim_run_agent. NB must be "=", not "==".
	slot sim_data = prb_newdatabase(sim_dbsize,[]);

	;;; make this non-false if the agent is to have a shared database
	slot sim_shared_data == false;

	;;; Initial list of rulesets, etc. defining the processing architecture
	;;; for this agent. Replaced by database entries in sim_setup
    slot sim_rulesystem == [];    ;;; A list of rulesets and rulefamilies

	;;; Save original rulesystem here in sim_setup
	slot sim_original_rulesystem == false;

    ;;; A list of sensors that will be run in each time-slice to get new
    ;;; sensory data. Each item in the list could be of the form
    ;;; {procedure range} The procedure is applied to every object
    ;;; within the range from this object. Default uses sim_sense_agent
    ;;; and a very large range
    slot sim_sensors = [{sim_sense_agent %1.0e33%}];

	;;; Slot for sensory input in formats defined by application,
	;;; e.g. [new_sense_data ?object ?range ....]
	;;; New data inserted after running sensor methods. Then transferred
	;;; to internal database.
	slot sim_sensor_data == [];

	;;; Slots for actions to be done in the world
	;;; Action specifications transferred here from internal database, then
	;;; run at end of each time-slice.
	slot sim_actions == [];

	;;; Made true by the sim_setup method
	slot sim_setup_done = false;
enddefine;




;;; Previously provided for backward compatibility. use only in TEACH ARMYSIM
;;; syssynonym("sim_rulesets", "sim_rulesystem");

/*
-- DEFINE CLASS SIM_AGENT

Define generic agent class for the simulation. Other agent classes will
be subclasses of this.
Agent slots contain information accessible from "outside" the agent,
e.g.
*/


define :class sim_agent; is sim_object;
	;;; The top level simulation agent class

	slot sim_name = gensym("agent");

	;;; slots for incoming and outgoing messages, and actions to be done
	;;; in the world. (Not in class sim_object)
	slot sim_in_messages == [];
	slot sim_out_messages == [];
enddefine;

/*

-- FACILITIES FOR AGENTS WITH SHARED DATABASES

*/

;;; Use same default as sim_dbsize, by default

global vars sim_shared_db_size;

if isundef(sim_shared_db_size) then sim_dbsize -> sim_shared_db_size endif;

define :mixin sim_shared_data_object;
	;;; allow individuals sometimes not to share data ??
	slot sim_using_shared_data == true;
	slot sim_shared_data == prb_newdatabase(sim_shared_db_size, []);
enddefine;


/*
-- UTILITIES FOR MANIPULATING THE DATABASE IN AN OBJECT
	represented as a property held in sim_data(object)
	or possibly in sim_shared_data(object)
*/

/*

;;; This is replaced by the new method, below
global constant procedure sim_get_data
		= if sim_use_shared_data then sim_shared_data else sim_data endif;

*/

;;; The method sim_get_data should be used rather than sim_data, since
;;; it behaves differently for objects with and without shared
;;; databases.

define :method sim_get_data(obj:sim_object)-> data;
	sim_data(obj) -> data;
enddefine;

define :method updaterof sim_get_data(obj:sim_object);
	-> sim_data(obj);
enddefine;

define :method sim_get_data(obj:sim_shared_data_object) -> data;
	sim_shared_data(obj) -> data
enddefine;


define :method updaterof sim_get_data(obj:sim_shared_data_object);
	-> sim_shared_data(obj)
enddefine;


define sim_delete_data( pattern, prb_database );

	dlocal prb_database;

	;;; delete ONE instance of the pattern from the database
	prb_flush1(pattern)
enddefine;

define sim_flush_data(pattern, prb_database);
	lvars pattern;
	dlocal prb_database;
	;;; delete all instances of the pattern from the database
	prb_flush(pattern)
enddefine;

define sim_add_data( /*item, dbtable*/) with_nargs 2;
	;;; redefined by AS to use prb_add_to_db
	prb_add_to_db(/*item, dbtable*/);
enddefine;

;;; Add all datalist to given property table
;;; DNDavis: Fri Jun 30 09:53:52 BST 1995
;;; Modified by A.Sloman
define sim_add_list_to_db( /* list, dbtable */ ) with_nargs 2;
	prb_add_list_to_db(/* list, dbtable */ )
enddefine;

define sim_clear_database(dbtable);

	;;; Before clearing the database, save the clusters and rulesystem
	lvars
		system = dbtable("RULE_SYSTEM"),
		clusters = dbtable("RULE_CLUSTER"),
		startupinfo = dbtable("RULE_SYSTEM_STARTUP"),
		;

	IFSECTIONS
		lvars sectioninfo = dbtable("RULE_SYSTEM_SECTION");

	;;; clear the database	
	clearproperty(dbtable);

	;;; restore the clusters and rulesystem, etc.
	system -> dbtable("RULE_SYSTEM");
	clusters -> dbtable("RULE_CLUSTER");
	startupinfo -> dbtable("RULE_SYSTEM_STARTUP");

	IFSECTIONS
	sectioninfo -> dbtable("RULE_SYSTEM_SECTION");

enddefine;


;;; Given object of class sim_object, how many items in
;;; its database (sim_data) under given key
;;; could be in autoloadable directory.

define :method sim_countdatabase(obj:sim_object, key) -> count;
	listlength( sim_get_data(obj)(key) ) -> count;
enddefine;


/*
-- SOME USER DEFINABLE FACILITIES (E.G. FOR TRACING)
*/
;;; These are user-defined procedures to be applied to
;;; something, e.g. an agent or list of agents.

global vars procedure(

	;;; Applied to agent before running its rules. Default do nothing.
	sim_agent_running_trace,

	;;; a procedure to show the output messages produced
	sim_agent_messages_out_trace,

	;;; a procedure to show the actions produced
	sim_agent_actions_out_trace,

	;;; applied to agent during post-processing
	sim_agent_action_trace ,

	;;; run after each cycle. Applied to list of agents run, and cycle no
	sim_scheduler_pausing_trace,

	;;; run at end, with list of objects and cycle no
	sim_scheduler_finished,

)
;

;;; SOME OPTIONAL DEFAULT TRACING METHODS
;;; Several of these are too verbose, and will need to be redefined.


define :method sim_agent_running_trace(object:sim_object);

enddefine;

define :method sim_agent_messages_out_trace(agent:sim_agent);

	['New messages OUT' ^(sim_name(agent)) ^(sim_out_messages(agent)) ] ==>

enddefine;

define :method sim_agent_messages_in_trace(agent:sim_agent);
	
	['New messages IN' ^(sim_name(agent)) ^(sim_in_messages(agent))] ==>

enddefine;

define :method sim_agent_actions_out_trace(object:sim_object);

	['New actions' ^(sim_name(object)) ^(sim_actions(object))] ==>

enddefine;


define :method sim_agent_action_trace(object:sim_object);

enddefine;


define :method sim_agent_rulefamily_trace(object:sim_object, rulefamily);
	lvars message =
			if isprb_rulefamily(recursive_valof(rulefamily)) then
				'Try rulefamily'
			else
				'Try ruleset'
			endif;

	[^message ^rulefamily 'with object' ^(sim_name(object))]==>
	pr('With Data:\n');
	prb_print_table( sim_get_data(object) );
enddefine;

;;; for backward compatibility
syssynonym("sim_agent_ruleset_trace", "sim_agent_rulefamily_trace");

define :method sim_agent_endrun_trace(object:sim_object);
	['Data in' ^(sim_name(object)): ]==>
	prb_print_table( sim_get_data(object) );
enddefine;

define vars procedure sim_scheduler_pausing_trace(objects, cycle);
	;;; user definable
	pr('\n======================= end of cycle ' >< cycle >< ' ==================\n');
enddefine;

define vars procedure sim_scheduler_finished(objects, cycle);
	;;; user definable
	pr('\n===================== Finished. Cycle ' >< cycle >< ' =================\n');
enddefine;

global vars
	procedure sim_run_agent, 		;;;; defined below
	sim_stop_this_agent = false,
;

define :method sim_agent_terminated_trace(object:sim_object, number_run, runs, max_cycles);
	;;; After each rulesystem is run, this procedure is given the object, the
	;;; number of actions run other than STOP and STOPIF actions, the number of times
	;;; the rulesystem has been run, the maximum possible number (sim_speed).
	if number_run == 0 then
		[object ^object performed ^number_run actions] ==>
		true -> sim_stop_this_agent;
	endif;
enddefine;

define vars procedure no_objects_runnable_trace(objects, cycle);
	;;; user definable trace procedure invoked if
	;;; no object was runnable in the cycle.
enddefine;

/*
-- INTERFACE PROCEDURES, CALLED ONCE PER CYCLE

Inserted at request of Jeremy Baxter and Ian Wright
*/

;;; Allow user-definable setup, e.g. for graphics
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
enddefine;

define vars procedure sim_post_cycle_actions(objects, cycle);
enddefine;

/*
-- PROCEDURE TO EDIT THE AGENT LIST
*/

global vars sim_object_delete_list = [], sim_object_add_list = [];

define vars procedure sim_edit_object_list(objects, cycle) -> objects;

	unless sim_object_delete_list == [] then
		lvars obj;
		[% for obj in objects do
			unless lmember(obj, sim_object_delete_list) then obj
			endunless
		  endfor %] -> objects
	endunless;	

	objects <> sim_object_add_list -> objects

enddefine;



/*
-- OPTIONAL EXTENSION FOR SOME AGENTS USING A STACK OF DATABASES, ETC.
Define :mixin sim_agent_with_stacks;
	;;; Facilities for agents that use the PUSHRULES and PUSHDATA actions
	;;; to save stacks of rules and data
	;;; ???? are these necessary ????
	slot sim_ruleset_stack = [];
	slot sim_database_stack= [];
enddefine;
*/

;;; Default printing procedure. Could be specialised for subclasses.
define :method print_instance(item:sim_object);
	printf(
		'<object name:%P status:%P>', [% sim_name(item), sim_status(item) %])
enddefine;


/*
-- NOW THE MAIN PROCESS MANAGEMENT PROCEDURES

In every time slot an agent gets a chance to
	- read and process incoming messages,
	- analyse sensor information,
	- take decisions about what to do,
etc.
This is done by switching rulesets. The switching is done within rules.

Each run of sim_run_agent should last a short time, as it corresponds
to one time-slice in the scheduler.

Initially we have rulesets in global variables, and use the PUSHRULES
and POPRULES action types in PRB_EXTRA. Later we may associate rulesets
with classes.

*/

/*
-- SOME AGENT UTILITIES FOR SENSING
*/

define :method sim_distance(a1:sim_object, a2:sim_object) -> dist;
	;;; Compute distance between two agents.
	lvars a1, a2, dist = 0;
/*
	;;; how it might be defined.
	lvars x1, y1, x2, y2;
	destpair(sim_location(a1)) ->(x1, y1);
	destpair(sim_location(a2)) ->(x2, y2);
	sqrt((x1-x2)**2 + (y1-y2)**2)
*/
enddefine;

;;; This should probably not be in the generic library, as not
;;; all applications will want it.
define :method sim_sense_agent(a1:sim_object, a2:sim_object, dist);
	;;; Default sensor for detecting other agents
	;;; return information about name of other agent and distance
	;;; Users will probably want to redefine this. E.g. it might
	;;; include a test for direction - using cone of visibility.
	;;; If a2 is not to be detected, then return nothing
	unless a1 == a2 then 	;;; don't detect oneself
		[new_sense_data ^(sim_name(a2)) ^dist]
	endunless
enddefine;

define :method sim_run_sensors(agent:sim_object, agents) -> sensor_data;
	;;; Default method for running all the sensors associated with an
	;;; agent. Done just before an agent is "run" by the scheduler.
	lvars
		other, sensor, sensor_proc, sensor_range,
		sensors = sim_sensors(agent), dist;

	if null(sensors) then []->sensor_data;
	else
		;;; make a list of records of detected agents
		[%
			for other in agents do
				sim_distance(agent,other) -> dist;
				for sensor in sensors do
					;;; assume each sensor is a vector in format
					;;; {sensorname range}, where sensorname is name of a method
					;;; of form: sensor(agent1, agent2, distance)
					;;; ??? should this use recursive_valof on the args ???
					appdata(sensor, recursive_valof)
						-> (sensor_proc, sensor_range);
					if dist <= sensor_range then
						;;; this may leave result on stack, a list to go into
						;;; the database, later
						sensor_proc(agent, other, dist);
					endif;
				endfor
			endfor
		%] -> sensor_data
	endif
enddefine;

/*
-- RUNNING AN OBJECT

First some lexical globals and utilities
*/

lvars some_agent_ran = false;

global vars
	prb_actions_run = 0,
;

define lconstant restore_dlocal(dlocal_vars, dlocal_vals);
	lvars var, val;
	for var, val in dlocal_vars, dlocal_vals do
		val -> valof(var)
	endfor;
;;;	sys_grbg_list(dlocal_vals)
enddefine;
		

define sim_database_assoc(word) -> found;
	prb_database(word) -> found;
	if found == [] then false
	else
		;;; get second item of database entry
		fast_front(fast_back(fast_front(found)))
	endif -> found;
enddefine;


;;; This should have an integer value in sim_run_agent
;;; USED by prb_STOPAGENT
lvars sim_run_agent_stackloc = 'not_in_sim_run_agent';

define :method sim_run_rulesystem(object:sim_object, rulesystem, action_limit, cycle_limit, len);
	;;; Run user definable trace procedure

	returnif(rulesystem == []);

	lvars rulesysname = false;

	if isref(fast_front(rulesystem)) then
		;;; It contains the name
		fast_cont(fast_destpair(rulesystem) -> rulesystem) -> rulesysname;
	endif;

	sim_agent_running_trace(object);
	sim_stack_check(object, len, sim_agent_running_trace, sim_cycle_number);

	;;; remember popmatchvars
	lvars oldmatchvars = popmatchvars;

	;;; give this object/agent its share of this time slice.
	lvars count = 1;

	until count fi_> action_limit do
		count fi_+ 1 -> count;

		;;;; dlocal declarations of prb_actions_run and sim_stop_this_agent
		;;;; moved back into sim_run_agent, below.

		lvars rulefamily_name;

		0 -> prb_actions_run;

		for rulefamily_name in rulesystem do

			;;; If necessary reset section, possibly changed by rules
			IFSECTIONS
			unless current_section == oldsection then
				oldsection -> current_section
			endunless;

			lvars
				templim = false,
				control_info = false,
				rulefamily = false;

			;;; Find the rulefamily and control information
            ;;; Save garbage: re-use the pattern
			lconstant pattern = [RULE_CLUSTER 0 ==];
			rulefamily_name -> fast_front(fast_back(pattern));

			unless prb_in_database(pattern) then
				mishap('Missing ruleset/family named '>< rulefamily_name, [^object])
			endunless;

			dl(fast_back(fast_back(prb_found))) -> (rulefamily, control_info);

			if control_info then
				;;; it should be a vector defining a cycle limit or interval
				lvars (type, val) = explode(control_info);

				if type == "limit" then
					val -> templim;
				else
					;;; it must specify an interval for this ruleset
					;;; or rulefamily, or possibly both interval and limit if held in a pair

					if ispair(val) then fast_destpair(val) -> (val, templim) endif;

					if isinteger(val) then
						;;; only do it once in that number of cycles
						nextunless((sim_cycle_number mod val) == 0);
					else
						nextunless(sim_interval_test(val, sim_cycle_number));
					endif;
				endif;
            endif;

			;;; rulefamily could be a list of rules, or a prb_rulefamily
			if isprb_rulefamily(rulefamily) then
				lvars temp = prb_family_limit(rulefamily);
				if isinteger(temp) then
					temp -> templim;
				endif;
			endif;

			sim_agent_rulefamily_trace(object, rulefamily);
			sim_stack_check(object, len, sim_agent_rulefamily_trace, rulefamily);

			lvars rules = recursive_valof(rulefamily);

			unless islist(rules) or isprb_rulefamily(rules) then
				mishap('RULESET OR RULEFAMILY NEEDED', [^rules ^object])
			endunless;

			;;; Normal poprulebase tracing facilities can be used in prb_run
			;;; Use version of prb_run that does not re-set popmatchvars
			oldmatchvars -> popmatchvars;

			prb_run_with_matchvars(
				;;; decide whether to use names of rulesets or the rulesets
				if sim_use_ruleset_names then
					;;; if pop_debugging is false, use the rulesets, unless
					;;; sim_use_ruleset_names is a list containing the name
					if ispair(sim_use_ruleset_names) then
						if lmember(rulefamily, sim_use_ruleset_names) then
							rulefamily
						else
							rules
						endif
					elseif pop_debugging then
						;;; use the name if sim_use_ruleset_names is false,
						;;; and pop_debugging is true
						rulefamily
					else
						rules
					endif;
				else
					;;; if sim_use_ruleset_names is false, don't use the name,
					;;; no matter what pop_debugging is
					rules
				endif,
				sim_get_data(object),	;;; may be sim_data or sim_shared_data
				if templim then templim else cycle_limit endif);

			;;; NB if there's an abnormal exit (e.g. [STOPAGENT], no more code
			;;; after this point will be run

			sim_stack_check(object, len, prb_run_with_matchvars, sim_cycle_number);

		endfor;

		unless prb_actions_run == 0 then true -> some_agent_ran endunless;
		;;;; Not run if there has been an abnormal exit
		sim_agent_terminated_trace(object, prb_actions_run, count, action_limit);
		quitif(sim_stop_this_agent);

	enduntil;

enddefine;


define :method sim_run_agent(object:sim_object, objects);
	;;; More specialised versions of this method may be defined for
	;;; sub-classes of sim_agent

	returnif(
		sim_rulesystem(object) == [] and sim_sensors(object) == []);

	procedure(object);

		lvars
			;;; Variables set in DLOCAL expression and saved values
			dlocal_vars = [],
			dlocal_vals = [],
			;

		;;; Set some global variables that may be changed by rules
		dlocal
			prb_actions_run = 0, sim_stop_this_agent = false;

		;;; Set up this agent's database for prb_ utilities to operate, while
		;;; inserting rulesystem conents.
		;;; A different database may be used when the rules run, i.e.
		;;; for objects with shared databases, sim_shared_data(object) will be accessed
		;;; by sim_get_data, below. Here sim_data must be used, as that is where
		;;; the rulesets, etc. are stored.

		dlocal prb_database = sim_data(object);

		;;; save len for stack checks
		dlvars len = stacklength();

		;;; This is used for abnormal exits, sim_stop_agent
		dlocal
			sim_run_agent_stackloc = callstacklength(0);


		lvars
			;;; There could be another cycle limit or interval spec in the
			;;; rulesystem, below.
			;;; Default third argument for prb_run_with_matchvars
			cycle_limit = sim_cycle_limit(object),
			cycle_interval = sim_interval(object),

			;;; Let sim_speed control how much internal processing is done
			action_limit = sim_speed(object),
		;

		;;; cycle_interval must specify an activation interval for this rulesystem
		if cycle_interval == 1 then
			;;; run every time
		elseif isinteger(cycle_interval) then
			;;; only run rulesystem once in that number of cycles
			returnunless((sim_cycle_number mod cycle_interval) == 0);
		else
			;;; use a user-defined procedure to check whether to run this time
			returnunless(sim_interval_test(cycle_interval, sim_cycle_number))
		endif;


		IFSECTIONS
		lvars orig_section = current_section;

		;;; reset section if it changes
		IFSECTIONS
		dlocal 0
			%, (if current_section /== orig_section and issection(orig_section)
			and dlocal_context < 3
			then orig_section -> current_section endif)%;

		IFSECTIONS
		lvars
			the_section = sim_database_assoc("RULE_SYSTEM_SECTION"),
			;;; Section may get changed in individual ruleclusters. Remember it
			oldsection = the_section;

		;;; Set new section if necessary
		IFSECTIONS
		if issection(the_section) then
			the_section -> current_section
		endif;

		;;; Check if rulesystem started with control info:
		lvars
	 		control_info = sim_database_assoc("RULE_SYSTEM_STARTUP"),

			dlocal_spec = false,
			limit_spec = false,
			lvars_spec = false,
			interval_spec = false,
		;;; debug_spec = false,		;;; ignored for now
		;

		if isvector(control_info) then
			destvector(control_info)
				-> (dlocal_spec, lvars_spec, limit_spec, interval_spec, /* N */);

			if dlocal_spec then
				fast_destpair(fast_back(dlocal_spec)) -> (dlocal_spec, dlocal_vars);
				;;; dlocal_spec is now the procedure
				;;; save the values
				maplist(dlocal_vars, valof)-> dlocal_vals;
				;;; set tne new values
				dlocal_spec();
			endif;

			sim_stack_check(object, len, 'set_DLOCAL', sim_cycle_number);

			;;; Check if rulesystem included limit count or vars_vec etc.
			;;; This may reset popmatchvars
			if lvars_spec then prb_check_vars_vec(lvars_spec) -> ; endif;
			sim_stack_check(object, len, 'set_LVARS', sim_cycle_number);

			;;; Give rulesystem limit priority over the default object limit
			if limit_spec then
				;;; should be a two-element vector specifying cycle limit
				lvars (freqtype, val) = explode(limit_spec);
				if freqtype == "limit" then
					val -> cycle_limit
				else ;;; should not occur?
					mishap('Unexpected cycle limit in rulesystem ', [^limit_spec in ^object]);
				endif;
			endif;

			if interval_spec then
				;;; should be a two-element vector
				lvars (freqtype, val) = explode(interval_spec);
				if freqtype == "rulesystem_interval" then
					val -> cycle_interval;
					else
					mishap('Unexpected vector in rulesystem ', [^interval_spec in ^object]);
				endif;
			endif;

		endif;

		;;; Find out in which order to run rulesets.
		lvars rulesystem = prb_database("RULE_SYSTEM");
		
		;;; returnif(rulesytem == []);	;;; decision now left to sim_run_rulesystem

		;;; rulesystem should be a list possibly empty or containing one list, starting with
		;;; "RULE_SYSTEM", then possibly the name of the rulesystem in a reference
		;;; then possibly control information
		;;; then the ruleclusters or rulecluster names.

		unless rulesystem == [] then back(fast_front(rulesystem)) -> rulesystem endunless;


		;;; Automatic exit action
		;;; Set dlocal to restore values, changed by [DLOCAL
		dlocal 0
			%, (if dlocal_spec and dlocal_context < 3 then
			restore_dlocal(dlocal_vars, dlocal_vals) endif)%;

		if cycle_interval /== 1 then
			;;; It must specify an interval for this rulesystem
			if isinteger(cycle_interval) then
				;;; only run rulesystem once in that number of cycles
				returnunless((sim_cycle_number mod cycle_interval) == 0);
			else
				returnunless(sim_interval_test(cycle_interval, sim_cycle_number))
			endif;
		endif;

		;;; Setup sensory input buffers
		sim_run_sensors(object, objects) -> sim_sensor_data(object);
		sim_stack_check(object, len, sim_run_sensors, sim_cycle_number);


		;;; Setup new database with sensor data
		sim_add_list_to_db( sim_sensor_data(object) , sim_get_data(object) );

		;;; Do all the internal processing required by the rulesystem
		sim_run_rulesystem(object, rulesystem, action_limit, cycle_limit, len );
		;;; No more code should come here, as abnormal exits from sim_run_rulesystem
		;;; will bypass it.
	endprocedure(object);

	;;; NB. may have exited abnormally
	;;; exit to sim_run_agent comes out here

		;;; Reset sensory buffers (SHOULD THIS BE DONE EARLIER??)
		[] -> sim_sensor_data(object);

	sim_agent_endrun_trace(object);

	;;; Prepare output actions  of form [do ....]
	(sim_get_data(object))("do") -> sim_actions(object);

	;;; Clear internal list of things to do
	[] -> (sim_get_data(object))("do");

	unless prb_actions_run == 0 then true -> some_agent_ran endunless;

	;;; Optionally show stuff that is in action output buffers
	sim_agent_actions_out_trace(object);

	;;; sim_actions(object) will be performed by the main scheduler after
	;;; all objects have been processed
enddefine;


define :method sim_run_agent(agent:sim_agent, agents);
	lvars agent, agents;
	;;; More specialised version, for sim_agent.

	;;; Insert messages
	sim_add_list_to_db( sim_in_messages(agent), sim_get_data(agent) );
	sim_agent_messages_in_trace(agent);

	;;; run the generic method for objects
	call_next_method(agent, agents);

	;;; clear input message buffer and reset sensory buffers
	[] -> sim_in_messages(agent);

	;;; prepare output messages
	lvars procedure dbtable = sim_get_data(agent);

	;;; Prepare output messages of form [message_out ...]
	dbtable("message_out") -> sim_out_messages(agent);
	;;; clear them
    []-> dbtable("message_out");

	;;; optionally show stuff that is in output buffers
	sim_agent_messages_out_trace(agent);

enddefine;

/*
-- ABORTING AN AGENT'S RULESYSTEM
*/
define lconstant prb_STOPAGENT(rule_instance, action);
	lvars rest = fast_back(action);
	if ispair(rest) then rest==> endif;
	unless prb_actions_run == 0 then true -> some_agent_ran endunless;
	exitto(sim_run_agent_stackloc);
enddefine;

prb_STOPAGENT -> prb_action_type("STOPAGENT");

define lconstant prb_STOPAGENTIF(rule_instance, action);
	lvars rest = fast_back(action);
	if ispair(rest) then
		if recursive_valof(fast_front(rest)) then
			if ispair(fast_back(rest)) then fast_back(rest) ==> endif;
			unless prb_actions_run == 0 then true -> some_agent_ran endunless;
			exitto(sim_run_agent_stackloc);
		endif
	else
		mishap('MISSING ITEM AFTER STOPAGENTIF', [^action])
	endif;
enddefine;

prb_STOPAGENTIF -> prb_action_type("STOPAGENTIF");


/*
-- POST-PROCESSING MESSAGES AND ACTIONS
*/

;;; The post processing actions are done by method sim_do_actions,
;;; defined below.

;;; The next method is called on each active object after all objects have
;;;	been run by the scheduler. It will normally be given one of the next
;;; two methods as its third argument.
define :method sim_post_process(object:sim_object, list, procedure action);
	;;; list could be a list of actions, or list of outgoing messages
	;;; action could be sim_send_message, sim_do_action
	lvars item, len = stacklength();
	for item in list do
		action(object, item);
		sim_stack_check(object, len, action, sim_cycle_number);
	endfor
enddefine;

;;; The next method generalised, following a suggestion by
;;; Brian Logan 31 Mar 1999
define :method sim_send_message(sender:sim_agent, message);
	;;; When an agent runs it can create some messages for sending.
	;;; The scheduler will send all the messages at the end of each
	;;; cycle, using this method. More specialised versions can be
	;;; defined for subclasses of sim_agent

	;;; Assume output message format is
	;;; 	[message_out ?target ?number ??message_contents]
	;;; When transferring, change it to
	;;; 	[message_in ?sender ?number ??message_contents]
	;;; reusing the list structure.
	;;; Where the ?target is a LIST it is assumed to be a list of
	;;; targets, and the message is sent to each one.

	define lconstant transmit(message, target);
		;;; Add the message to the target's input buffer
		[^message ^^(sim_in_messages(target))] -> sim_in_messages(target);
	enddefine;

	;;; Work out recipient or recipients.
	lvars target = message(2);

	;;; Transform outgoing messages to form [message_in ...]
	"message_in" -> front(message);

	;;; replace target with sender
	sender -> message(2);

	if ispair(target) then
		lvars item;
		for item in target do
			transmit(message, item);
			;;; Safer alternative
			;;; transmit(copylist(message), item)
		endfor
	else
		;;; Only one target.
		;;; If in doubt use copylist for safety.
		transmit(message, target)
	endif;

enddefine;
	

define :method sim_do_action(agent:sim_object, action);
	;;; After an agent has run it creates a list of actions
	;;; the scheduler runs the actions at the end of each scheduler
	;;; cycle, using this method. More specialised versions of
	;;; sim_do_actoin can be defined for subclasses of sim_agent.
	lvars do_proc, args, len = stacklength();

	;;; assume the action is of the form	*** IMPROVE THIS
	;;;		[do ?procedure ??args]
	;;; drop the "do"
	destpair(back(action)) -> (do_proc, args);

	recursive_valof(do_proc) -> do_proc;

	;;; apply the procedure to the arguments
	;;; e.g. this may change the agent's location or heading, shoot
	;;; another agent, pick something up, etc.
	do_proc(agent, dl(args));
	sim_stack_check(agent, len, do_proc, sim_cycle_number);
enddefine;


;;; The next method is run in the second pass of the scheduler.
;;; For objects of type sim_agent it does slightly more complex
;;; processing.

define :method sim_do_actions(object:sim_object, objects, cycle);
	lvars object, objects, cycle;

	lvars len = stacklength();
	;;; run user definable trace procedure
	sim_agent_action_trace(object);
	sim_stack_check(object, len, sim_agent_action_trace, cycle);

	;;; Perform new pending actions in the object's action output buffer
	sim_post_process(object, sim_actions(object), sim_do_action);
	sim_stack_check(object, len, sim_do_action, cycle);

	;;; For efficiency can do this, to restore lists to free list
	;;; and reduce garbage collection time.
	;;; sys_grbg_list(sim_actions(object));

	;;; re-set output message lists and actions
	[] -> sim_actions(object)
enddefine;

define :method sim_do_actions(object:sim_agent, objects, cycle);
	lvars object, objects, cycle;

	lvars len = stacklength();
	;;; run user definable trace procedure
	sim_agent_action_trace(object);
	sim_stack_check(object, len, sim_agent_action_trace, cycle);

	;;; Transmit messages from the object to their targets
	sim_post_process(object, sim_out_messages(object), sim_send_message);
	sim_stack_check(object, len, sim_send_message, cycle);

	;;; Perform new pending actions in the object's action output buffer
	sim_post_process(object, sim_actions(object), sim_do_action);
	sim_stack_check(object, len, sim_do_action, cycle);

	;;; For efficiency can do this, to restore lists to free list
	;;; and reduce garbage collection time.
	;;; sys_grbg_list(sim_out_messages(object));
	;;; sys_grbg_list(sim_actions(object));

	;;; re-set output message lists and actions
	[] ->> sim_out_messages(object) -> sim_actions(object)
enddefine;

/*
-- THE MAIN SCHEDULER
*/
;;; Utility used by sim_scheduler

define new_component_name(object) -> name;
	;;; Create a name to be mapped onto rule-families, etc.
	;;; For cases where there is not already a name.
	lvars root = sim_component_root(object);
	unless root then
		consword('RULES_' sys_>< sim_name(object)) ->> root
			-> sim_component_root(object)
	endunless;
	gensym(root) -> name;
enddefine;

define :method sim_post_setup(object:sim_object);
	;;; can be invoked just before sim_setup ends
enddefine;

define :method sim_add_rule_cluster(object:sim_object, name, cluster, control_info);
	lvars cluster_info = [RULE_CLUSTER ^name ^cluster ^control_info];
	prb_add(cluster_info);
	if sim_add_rulecluster_trace then
		[ADDING IN %sim_name(object)% ^cluster_info] =>
	endif;
enddefine;

define :method sim_add_rule_system(object:sim_object, system);
	lvars system_info = [RULE_SYSTEM ^^system];
	prb_add(system_info);
	if sim_add_rulesystem_trace then
		[ADDING IN %sim_name(object)% ^system_info] =>
	endif;
enddefine;

define :method sim_add_rule_system_startup(object:sim_object, dlocal_spec, lvars_spec, limit_spec, interval_spec);
	lvars system_info =
		[RULE_SYSTEM_STARTUP {^dlocal_spec ^lvars_spec ^limit_spec ^interval_spec}];

	prb_add(system_info);

	if sim_add_rulesystem_trace then
		[ADDING IN %sim_name(object)% ^system_info] =>
	endif;
enddefine;


define :method sim_setup(object:sim_object);
	;;; make sure rulefamily names are replaced by a new copy of the
	;;; rulefamily

	dlocal prb_database;

	unless sim_setup_done(object) then
		;;; get ready to add rulesets, etc. to the agent's database
		lvars
			system  = sim_rulesystem(object),
			system_name = false;

		;;; Do nothing if rulesystem is empty
		if system == [] then
			true -> sim_setup_done(object);
			return();
		endif;
	

		sim_data(object) -> prb_database;

		;;; Make sure the rulesystem is a list
		;;; See LIB define_rulesystem, to find how they are created
		if isword(system) then
			system -> system_name;
			;;; dereference
			recursive_valof(system) -> system;
		endif;

		if isprocedure(system) then
			;;; Run procedure to create the rulesystem.
			system() -> system
		endif;

		;;; system should be a list. Copy and instantiate it
		lvars
			item,
			rulesysname = false,
			dlocal_spec = false,
			lvars_spec = false,
			;;; debug_spec = false,		;;; ignored for now
			limit_spec = false,
			interval_spec = false;
		
		IFSECTIONS
		lvars the_section = false;

		if ispair(system) and isref(fast_front(system)) then
			destpair(system) -> (rulesysname, system);
		endif;

		[%
         if rulesysname then rulesysname endif,
		
		 for item in system do
			lvars fam=false, famname=false, control_info = false;
			if item == false then
				mishap('FALSE ITEM IN RULESYSTEM', [^rulesysname])
			endif;
			if item matches [DLOCAL ==] then
				item -> dlocal_spec;
				nextloop();
			IFSECTIONS
			elseif issection(item) then
				item -> the_section, nextloop();
		  	elseif ispair(item) and isvector(fast_back(item)) then
				destpair(item) -> (famname, control_info);
				;;; the front should represent a ruleset or rulefamily or its name
				;;; and the back a limit or interval
				copy(control_info) -> control_info;	;;; make it unique
				if isword(famname) then
					valof(famname) -> fam;
					if islist(fam) then ;;; its a ruleset
					elseif isprb_rulefamily(fam) then
						;;; make a unique copy
						copydata(fam) -> fam;
						if sim_unique_cluster_name then
							gensym(famname) -> famname;
							ident_declare(famname, 0, false);
							fam -> valof(famname);
						endif;
					else
						mishap('Ruleset or Rulefamily needed in rulesystem',
							[%valof(fam), object %])
					endif
				elseif isprb_rulefamily(famname) then
					;;; should this be copy or copydata???
					copydata(famname) -> fam;
					;;; change this to use new_component_name ???
					gensym("rulefamily") -> famname;
					ident_declare(famname, 0, false);
					fam -> valof(famname);
				elseif islist(famname) then
					;;; It's an anonymous ruleset. Make it unique
					copydata(famname) -> fam;
					gensym("ruleset") -> famname;
					ident_declare(famname, 0, false);
					fam -> valof(famname);
				else
					mishap('Ruleset or Rulefamily needed in rulesystem', [%fam, object %])
				endif;
			elseif isprb_rulefamily(item) then
				copydata(item) -> fam;
				;;; change this to use new_component_name ???
				gensym("rulefamily") -> famname;
				ident_declare(famname, 0, false);
				fam -> valof(famname);
			elseif isword(item) then
				item -> famname; valof(item) -> fam;
				if islist(fam) then
					;;; it's a named ruleset. save its name
					if sim_use_ruleset_names then
						unless ispair(sim_use_ruleset_names)
							and not(member(famname, sim_use_ruleset_names))
						then
							famname -> fam;
						endunless;
					endif;
				elseif isprb_rulefamily(fam) then
					;;; make a unique copy, with a unique name
					copydata(fam) -> fam;
					if sim_unique_cluster_name then
						gensym(famname) -> famname;
						ident_declare(famname, 0, false);
						fam -> valof(famname);
					endif;
				else
					mishap('Ruleset or Rulefamily needed in rulesystem',
						[%valof(item), object %])
				endif
			elseif isvector(item) then
				lvars words, proc;
				;;; it is an lvars spec or a limit or interval specification
				if datalength(item) == 2
				and (explode(item) ->(words, proc); islist(words))
				and isprocedure(recursive_valof(proc) ->> proc)
				then
					item -> lvars_spec
				elseif item(1) == "limit" then
					item -> limit_spec
				else
					item -> interval_spec
				endif;
				nextloop
			else
				mishap('Unexpected item in rulesystem ', [^item ^object]);
			endif;
			;;; Previously prb_add([RULE_CLUSTER ^famname ^fam ^control_info]);
			sim_add_rule_cluster(object, famname, fam, control_info);
			;;; keep the name to go into the rulesystem control list
			famname;
		endfor%] -> system;

		unless system == [] then

			;;; store the rulesystem
			;;; was prb_add([RULE_SYSTEM ^^system]);
			sim_add_rule_system(object, system);

			;;; Need to generate a mishap if old programs attempt
			;;; to access rulesystem as a list.
			'Rulesystem in database'  -> sim_rulesystem(object);
			system -> sim_original_rulesystem(object);

	 		if dlocal_spec or lvars_spec or interval_spec or limit_spec then
				;;; previously prb_add([RULE_SYSTEM_STARTUP {^dlocal_spec ^lvars_spec ^limit_spec ^interval_spec}]);
				sim_add_rule_system_startup(object, dlocal_spec, lvars_spec, limit_spec, interval_spec);
			endif;

			IFSECTIONS
			if the_section then prb_add([RULE_SYSTEM_SECTION ^the_section]) endif;

;;; 			[Rulesystem for ^object]==>
;;; 			[startup_info %prb_database("RULE_SYSTEM_STARTUP")%]==>
;;; 			[section_info %prb_database("RULE_SYSTEM_SECTION")%]==>
;;; 			prb_database("RULE_SYSTEM")==>
;;; 			prb_database("RULE_CLUSTER")==>
		endunless;
		true -> sim_setup_done(object);

		;;; invoke user definable method
		sim_post_setup(object);

	endunless;
enddefine;

;;; sim_scheduler(agents, Lim) runs the full set of agents Lim times
;;; though those with speed K will run K times on each cycle.
;;; If Lim == false, it will run forever.


global vars procedure sim_stop_scheduler; ;;; defined below

;;; This variable is used in sim_scheduler_objects, below

lvars final_objects = [];

define sim_scheduler(objects, lim);
	lvars objects, object, speed, lim, messages, messagelist = [];
	
	;;; clear any previously saved objects.
	[] -> final_objects;

	;;; make the list of objects globally accessible, to methods, etc.
	dlocal
		some_agent_ran,

		popmatchvars,
		sim_objects = objects,
		sim_myself ,		;;; used so that rules can access self
		sim_cycle_number = 0,	;;; incremented below
		sim_object_delete_list = [],
		sim_object_add_list = [],
		;;; supppress printing of rulesystem information
		prb_noprint_keys = sim_noprint_keys,
		sim_stopping_scheduler = false
		;

	;;; First ensure that rulesystems are all analysed and rulesets stored in
	;;; databases, etc.


	procedure();	;;; exitto(sim_scheduler), will exit this
	  lvars len = stacklength();

	    ;;; make sure all agents have been setup before anything
		;;; starts
	  applist(sim_objects, sim_setup);

	  repeat
		;;; check whether to abort
		quitif(sim_cycle_number == lim);		;;; never true if lim = false
		sim_cycle_number fi_+ 1 -> sim_cycle_number;

		;;; Allow user-definable setup, e.g. for graphics
		sim_setup_scheduler(sim_objects, sim_cycle_number);

		false -> some_agent_ran;	;;; may be set true in sim_run_agent

		;;; go through all objects running their rules, then do
		;;; post-processing to update world
		for object in sim_objects do

			;;;; XXXX should do interval check here?
			;;; Must check if agent needs to be set up, in case it is
			;;; new or has been given a new rulesystem
			unless sim_setup_done(object) then sim_setup(object) endunless;
			object -> sim_myself;
            [] -> popmatchvars;
			;;; NOW LET THE AGENT DO ITS INTERNAL STUFF
			sim_run_agent(object, sim_objects);
			sim_stack_check(object, len, sim_run_agent, sim_cycle_number);

		endfor;

		if some_agent_ran then

			;;; now distribute messages and perform actions to update world
			for object in sim_objects do;
				object -> sim_myself;
				sim_do_actions(object, sim_objects, sim_cycle_number);
			endfor;

		else
			;;; no rules were fired in any object
			no_objects_runnable_trace(sim_objects, sim_cycle_number)
		endif;

		sim_scheduler_pausing_trace(sim_objects, sim_cycle_number);

		;;; This can add new objects or delete old ones
		sim_edit_object_list(sim_objects, sim_cycle_number) -> sim_objects;

		;;; This can be used for updating a connected simulation, etc.
		sim_post_cycle_actions(sim_objects, sim_cycle_number);

		;;; Moved after call to sim_post_cycle_actions at suggestion of BSL
		[] ->> sim_object_delete_list -> sim_object_add_list;

		;;; Added 8 Oct 2000
        if sim_stopping_scheduler then sim_stop_scheduler() endif;

	  endrepeat
	endprocedure();

	sim_scheduler_finished(sim_objects, sim_cycle_number);

	sim_objects -> final_objects;

enddefine;

define sim_scheduler_objects(objects, lim) -> objects;
	;;; run sim_scheduler and return the final set of objects

	sim_scheduler(objects, lim);

	final_objects -> objects;

enddefine;

/*
-- PROCEDURES FOR "ABNORMAL" STOPPING
*/

define procedure sim_stop_agent();
	exitto(sim_run_agent_stackloc);
enddefine;

define procedure sim_stop_scheduler();
	exitto(sim_scheduler)
enddefine;

global vars sim_agent = true;	;;; for uses

endsection;

nil -> proglist;
/*
-- REVISION NOTES
*/

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jan 12 2003
		
		At suggestion of Brian logan
		Moved this line after call to sim_post_cycle_actions
		[] ->> sim_object_delete_list -> sim_object_add_list;

		At suggestion of Nick Hawes
		Made sim_agent_rulefamily_trace print different things for
		rulefamilies and rulesets

--- Aaron Sloman, Nov 22 2002
		fixed minor typo reported by Brian Logan
--- Aaron Sloman, Nov  4 2000
	Added sim_add_rulecluster_trace, and new method
		sim_add_rule_cluster(object, famname, fam, control_info);
	likewise
		sim_add_rulesystem_trace and methods
		sim_add_rule_system(object, system);
		sim_add_rule_system_startup(object, dlocal_spec, lvars_spec, limit_spec, interval_spec);
--- Aaron Sloman, Oct 31 2000
	Added sim_unique_cluster_name, default true, to overcome
	problem reported by Catriona Kennedy

--- Aaron Sloman, Oct  8 2000
	Added sim_stopping_scheduler

--- Aaron Sloman 18 Aug 2000
	The code for handling the interval specification for a ruleset (as
	describedi n HELP NEWKIT now allows both the interval and the cycle limit
	to be used. Previously the documented behaviour was not supported.

--- Aaron Sloman, Aug  8 2000
	[to be rewritten]
	Various changes to cope with the fact that [STOPAGENT] could cause abnormal
	exits to skip some instructions after code was move to sim_run_rulesystem

	changes imply that [STOPAGENT] will prevent this running
		sim_agent_terminated_trace(object, prb_actions_run, count, action_limit);

--- Aaron Sloman, Aug  7 2000

	sim_shared_db_size;

	:mixin sim_shared_data_object;
	sim_minmemlim_after_lock = false,
	sim_use_ruleset_names
	sim_get_data turned into a method

--- Aaron Sloman, VERSION 6.0,  30 Jul 2000
	sim_post_setup(object:sim_object);
	sim_shared_data
	sim_use_shared_data
	sim_get_data
	sim_version = ['V6.0' '00.07.30'];
	slot sim_original_rulesystem
		sim_rulesystem(object) == [] and sim_sensors(object) == []);

	new method sim_run_rulesystem

--- Aaron Sloman, Jul  6 2000
	Added sim_scheduler_objects(objects, lim) -> objects;

	Suggested by Matthias Scheutz

--- Aaron Sloman, Dec  6 1999
	Fixed location of dlocal_vars dlocal_vals to ensure they are set before
	method sim_run_agent can return (Bug reported by Catriona Kennedy)
--- Aaron Sloman, Nov  7 1999
	Changed to ensure that sim_run_agent(object) is done even if sim_rulesystem
	is empty.
--- Aaron Sloman, Nov  2 1999
	Added calls of sim_setup into the inner loop of the scheduler, before
	sim_run_agent. So users don't need to setup agents added to the list.
--- Aaron Sloman, Jul 17 1999
	Changed interpretation of decimal interval: now it should be a
	decimal <= 1.0
--- Aaron Sloman, Jul 10 1999
	Reset popmatchvars to [] before sim_run_agent
--- Aaron Sloman, Jul  6 1999
	Cleared sim_rulesystem at end of sim_setup

	Added support for symbolic activation intervals "second" "day", etc.
	via sim_cycle_milliseconds

--- Aaron Sloman, Jul  5 1999
	Check for rulesystem = [] before calling sim_run_agent

-- Version 5: July 4th 1999
;;; NB SEVERAL MAJOR CHANGES JULY 1999 TO ENABLE AGENTS TO GAIN ACCESS
;;; MORE EASILY TO THEIR OWN ARCHITECTURE AND TO UPDATE IT ETC.
--- Aaron Sloman, Jul  4 1999

	Added sim_noprint_keys

	Changed sim_clear_database to save the rulesystem and rulesets and
	restore after clearing everything else.

	Added IFSECTIONS tests, to control compilation
	Removed sim_rulesets as a synonym for sim_rulesystem

	Gave objects default name using gensym
	Increased the default sim_dbsize from 8 to 23.
--- Aaron Sloman, Mar 31 1999
	sim_send_message generalised to cope with message addressed to multiple
	targets, following a suggestion by Brian Logan.
--- Aaron Sloman, Nov 14 1997
	fixed bug which caused with_limit in connection with a ruleset
	or rulefamily not to be localised properly.
--- Aaron Sloman, Mar 20 1997
	Introduced sim_lock_heap to make sim_setup_scheduler
	do heap locking.
--- Aaron Sloman,  23 Jul 1996
	Made prb_run_agent see if there's an integer in prb_family_limit
	and if so use that. Suggested by Peter Waudby
--- Aaron Sloman, Jun  4 1996
	Changed STOPAGENT to get round exitto problem. Had to use callstacklength
--- Aaron Sloman,  25 May 1996
	Added :method sim_agent_messages_in_trace(agent:sim_agent);
	slot sim_setup_done added, and rulesystems and rulefamilies
	copied in default setup.

	Modified control of cycle limits. Restricted to rulesystems and
	sim_cycle_limit

--- Aaron Sloman, May 22 1996
	added prb_actions_run, and redefined sim_agent_terminated_trace

--- Aaron Sloman,  10 May 1996
added checks on rulesystem being a list
removed redundant section checking code

--- Aaron Sloman, Apr 30 1996
fixed problem with orig_section not being a section

Allowed optional vars_vec arg in sim_scheduler.
	(removed  25 May 1996 because superseded by [DLOCAL ...] forms.)

	Draft new field, sim_matchvars for objects (two element vector)
	(removed  25 May 1996 because superseded by [DLOCAL ...] forms.)

	code still commented out. Search for sim_matchvars & object_matchvars

-- Version 3

--- Aaron Sloman,  9 Apr 1996
	Following a suggestion from Ian Wright, added procedure
	sim_edit_object_list called at the end of each scheduler time slice,
	with associated user changeable lists:
		sim_object_delete_list, sim_object_add_list = [];

--- Aaron Sloman,  8 Apr 1996
	Added sim_cycle_number, and tidied up various other things.
--- Aaron Sloman, Mar 31 1996
	Moved the extraction of sim_rulesystem out of the inner loop in
	sim_run_agent.
	Rationalised the selection of cycle limits to conform to
		HELP * RULESYSTEMS
--- Aaron Sloman, Mar 24 1996 (v3.1)
	Various changes to accommodate rulesystems
	Altered test for being in prb_instance to avoid iscaller
--- Aaron Sloman, Jan 31 1996
	Version V3
	Introduced sim_version
	Used prb_*rule_found, to prevent wasted calls to prb_run
	Took account of new prb_rulesystem structure to
    	allow new options in prb_run,
		allow more control (?)
	Added facilities to record if no rules were fired in an object
		in a cycle, and in that case run
			sim_agent_terminated_trace
	If a ruleset has run a STOP action then don't run that ruleset again
		for that object in that timeslice.
	If NO object has any rule fired in a cycle of sim_scheduler, then run
		no_objects_runnable_trace
	

--- Aaron Sloman 30th Aug 1995
	Removed local definition of prb_finish from sim_run_agent

	Fixed buggy definition of sim_flush_data, which was defined in
		terms of prb_del1 instead of prb_flush, and buggy definition
		of sim_delete_data, which was defined in terms of prb_del1
		instead of prb_flush1

	Added printing of extra newline in sim_agent_*ruleset_trace.
--- Aaron Sloman 17th July 1995
		Removed false prb_*repeating default. It's an unnecessary overhead
		and makes no sense in the context of restricted runs of
		prb_run.
--- Darryl Davis, and Aaron Sloman 7 July 1995
-- Version 2
	New procedures
	sim_delete_data( /* pattern, data */ );
	sim_add_data( /*item, dbtable*/);
	sim_add_list_to_db( /* list, dbtable */ );
	sim_clear_database(/*dbtable*/);

	Changed sim_data slot (on class sim_object) so it is a property table
		makes it comptabible with property tables in new poprulebase
		removed sim_remove_all : no longer used
		added sim_dbsize: default size of property table

--- Aaron Sloman, May 19 1995
	Changed
		define :method sim_do_action(agent:sim_agent, action);
	to
		define :method sim_do_action(agent:sim_object, action);
	to avoid problems when attempts are made to apply the method
	to objects that are not agents, e.g. in sim_post_process
--- Aaron Sloman, Apr 26 1995
	Introduced sim_do_actions method so as not to look at messages
	of non-agents in the second pass of the scheduler.

	Redefined :method sim_post_process so that first arg is of type
	sim_object

--- Aaron Sloman, Mar 27 1995
	Changed :method print_instance(item:sim_object), to print
		<object ....> instead of <agent ....>
--- Aaron Sloman, Jan 10 1995
	Made sim_object the top level class, not including messages.
	Made sim_agent a sub-class, including slot for messages.
	Changed the trace procedures to be methods, so that they can
		be redefined differently for different sub-classes
	Removed sim_location from the top level definition. Not all
		objects will have a location (at least not as a pair).
	Following on from the above made sim sim_distance return 0 by default.
	Added sim_stop_agent and sim_stop_scheduler
	Put an extra layer of procedure call in sim_scheduler and
		sim_run_agent, so that sim_stop_agent, and sim_stop_scheduler
		could use exitto.
	Defined procedure sim_stack_check(object, len, name, cycle);
		and planted calls of it.
	Removed the slot sim_class_information. Users can put it in their
		agent classes if required.
	At request of Jeremy Baxter added:
		sim_post_cycle_actions(sim_objects, cycle);

--- Aaron Sloman, Dec  2 1994
	Allowed agents to sense themselves
--- Aaron Sloman, Nov 24 1994
	Changed default value for
		slot sim_sensors == [{sim_sense_agent %1.0e33%}];
		i.e. the default is now a very large number.
	Changed sim_run_sensors so as to remove check
		nextif(other == agent)
	Changed method sim_sense_agent to do the check, instead

--- Aaron Sloman, Nov 13 1994

	No longer needs to load LIB PRB_EXTRA as prb_remove_all has been made
		autoloadable.

	Replaced global variable sim_cycle_limit with a slot in the class agent.

	Also allow sim_*ruleset_limit(rulesetname) to determine the number of cycles in
		prb_run for that ruleset. This helps to allow more fine-grained speed control.
	
	Moved documentation out to help file.

	Moved the use of sim_speed to sim_run_agent, where it makes more sense.

--- Aaron Sloman, Oct 17 1994
		Changed to use POPRULEBASE and PRB_EXTRA
		Changed to allow a maximum number of cycles for each run of
		prb_run. (Should be made class specific or ruleset specific.)
		Some minor tidying up. More to come.
--- Aaron Sloman, Oct 10 1994
		Removed the "slowness" measure and replaced it with speed measure.
		Also removed agents_run
--- Aaron Sloman, Sep 14 1994
	Moved place where sim_repeating is set false to sim_run_agent
	Altered sim_scheduler to re-initialise agents_run to [] in repeat
	loop.
	Extended tracing options in sim_run_agent
--- Aaron Sloman, Sep 13 1994
	Changed scheduler to run the set of rulesets explicitly itself.
	Changed [new_message ...] to [message_in ...] throughout


[This index produced with "ENTER indexify define"]

CONTENTS - (Use "ENTER gg" to access required sections)

 define vars procedure sim_interval_test(interval, cycle_number) -> boole;
 define lconstant procedure sim_stack_check(object, len, name, cycle);
 define global vars syntax ^ with_nargs 1;
 define updaterof ^ with_nargs 2;
 define global vars syntax >^ with_nargs 2;
 define global vars syntax *^ with_nargs 1;
 define global vars syntax >*^ with_nargs 1;
 define :class sim_object;
 define :class sim_agent; is sim_object;
 define :mixin sim_shared_data_object;
 define :method sim_get_data(obj:sim_object)-> data;
 define :method updaterof sim_get_data(obj:sim_object);
 define :method sim_get_data(obj:sim_shared_data_object) -> data;
 define :method updaterof sim_get_data(obj:sim_shared_data_object);
 define sim_delete_data( pattern, prb_database );
 define sim_flush_data(pattern, prb_database);
 define sim_add_data( /*item, dbtable*/) with_nargs 2;
 define sim_add_list_to_db( /* list, dbtable */ ) with_nargs 2;
 define sim_clear_database(dbtable);
 define :method sim_countdatabase(obj:sim_object, key) -> count;
 define :method sim_agent_running_trace(object:sim_object);
 define :method sim_agent_messages_out_trace(agent:sim_agent);
 define :method sim_agent_messages_in_trace(agent:sim_agent);
 define :method sim_agent_actions_out_trace(object:sim_object);
 define :method sim_agent_action_trace(object:sim_object);
 define :method sim_agent_rulefamily_trace(object:sim_object, rulefamily);
 define :method sim_agent_endrun_trace(object:sim_object);
 define vars procedure sim_scheduler_pausing_trace(objects, cycle);
 define vars procedure sim_scheduler_finished(objects, cycle);
 define :method sim_agent_terminated_trace(object:sim_object, number_run, runs, max_cycles);
 define vars procedure no_objects_runnable_trace(objects, cycle);
 define global vars procedure sim_setup_scheduler(objects, number);
 define vars procedure sim_post_cycle_actions(objects, cycle);
 define vars procedure sim_edit_object_list(objects, cycle) -> objects;
 define :method print_instance(item:sim_object);
 define :method sim_distance(a1:sim_object, a2:sim_object) -> dist;
 define :method sim_sense_agent(a1:sim_object, a2:sim_object, dist);
 define :method sim_run_sensors(agent:sim_object, agents) -> sensor_data;
 define lconstant restore_dlocal(dlocal_vars, dlocal_vals);
 define sim_database_assoc(word) -> found;
 define :method sim_run_rulesystem(object:sim_object, rulesystem, action_limit, cycle_limit, len);
 define :method sim_run_agent(object:sim_object, objects);
 define :method sim_run_agent(agent:sim_agent, agents);
 define lconstant prb_STOPAGENT(rule_instance, action);
 define lconstant prb_STOPAGENTIF(rule_instance, action);
 define :method sim_post_process(object:sim_object, list, procedure action);
 define :method sim_send_message(sender:sim_agent, message);
 define :method sim_do_action(agent:sim_object, action);
 define :method sim_do_actions(object:sim_object, objects, cycle);
 define :method sim_do_actions(object:sim_agent, objects, cycle);
 define new_component_name(object) -> name;
 define :method sim_post_setup(object:sim_object);
 define :method sim_setup(object:sim_object);
 define sim_scheduler(objects, lim);
 define sim_scheduler_objects(objects, lim) -> objects;
 define procedure sim_stop_agent();
 define procedure sim_stop_scheduler();

 */
