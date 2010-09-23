/*
TEACH ARMYSIM.P                                   Aaron Sloman July 1995
                                                     Updated 27 Jun 1999

In June 999 this file was made consistent with define :ruleset
notation, and other changes introduced in 1996 and 1997!

NOTE: this tutorial is superseded by TEACH SIM_DEMO

This file has been left for testing purposes and checking backward
compatibility. A number of things have changed, as described in HELP PRB_NEWS
and HELP SIM_AGENT_NEWS


[This file is executable in POP11]
(Draft documentation, to be extended)

The original idea for this file was developed in collaboration with
Richard Hepplewhite and Brian Roberts (DRA Malvern) and Riccardo Poli
at Birmingham.

    For changes see end of file.

-- Pre-requisites

This file provides a mixture of comments and code showing how to use
    LIB SIM_AGENT

To understand this you will need to be familiar with Objectclass

See
    HELP * OBJECTCLASS
    TEACH * OBJECTCLASS_EXAMPLE
        - Tutorial example using lib objectclass
    REF * OBJECTCLASS
        - Definitive reference of the objectclass library

You will also need to be familiar with POPRULEBASE
See
    HELP * POPRULEBASE
        - Full documentation
    TEACH * PRBRIVER
        - An extended example, showing how to create a planning system

You should also look at the comments in lib sim_agent

    SHOWLIB * SIM_AGENT

NOTE: to indicate slots and classes etc. introduced in this teach file,
the prefix 'asim_' (short for army_sim) is used instead of 'sim_' which
the generic library LIB SIM_AGENT uses.


NOTE: there are some infelicities in LIB POPRULEBASE, which may be
extended to improve the syntax allowed here, and also to reduce
spurious trace print out.

In particular the SAY and PAUSE actions need to be extended with
an optional trace facility.

CONTENTS - (Use <ENTER> g to access required sections)
[This index created using "<ENTER> indexify"
 -- Pre-requisites
 -- INTRODUCTION
 -- HOW IT WORKS
 -- -- Resource allocation between agents or sub-mechanisms
 -- -- This file is executable
 -- PATTERN FORMS TO BE USED IN THE DATABASE (First Draft)
 -- -- New sensory input
 -- -- New messages received
 -- -- Beliefs
 -- -- Goals
 -- -- Plans
 -- -- Actions to be executed
 -- -- Messages to be sent
 -- INDEX OF METHODS PROCEDURES CLASSES AND RULES
 -- THE DEFAULT RULE-TYPES
 -- THE SET OF RULESETS FOR EACH AGENT TYPE
 -- NEW SUB_CLASSES FOR THIS DEMO
 -- -- class asim_army_agent
 -- -- class asim_tank_agent
 -- -- helicopter agent to be added later?
 -- -- mixin asim_commander
 -- -- A subclass for commanding tanks
 -- METHODS FOR "ARMY" AGENTS
 -- -- Global variables set in sim_run_agent for army agents
 -- BEHAVIOUR RULES FOR ARMY AGENTS
 -- -- asim_perception_rules
 -- -- asim_message_in_rules
 -- -- asim_deliberate_rules
 -- -- asim_action_rules
 -- -- Utilities for action rules
 -- -- asim_message_out_rules
 -- -- asim_commander_rules
 -- NOW CREATE THE INSTANCES
 -- -- the red army
 -- -- The blue army
 -- Set up the demo
 -- TESTING THE PACKAGE
 -- -- Preliminary information about tracing
 -- -- Reduce tracing
 -- -- Run it much faster, by sending output to a file
 -- RECORD OF CHANGES

-- INTRODUCTION -------------------------------------------------------

This package is based on the new LIB SIM_AGENT package. It demonstrates
how to use the latter, by constructing a small simulated army, in which
a commander sends messages to subordinates who then move to a specified
location and stop.

It includes unused code that could be the basis for having two sets
of tanks in some sort of conflict.

Many of the ideas here come from the Attention and Affect Project at
the University of Birmingham. The sim_agent package is designed to
provide a very flexible tool for exploring the design of individual
agent architectures or multi-agent architectures. For an explanation of
the key ideas of the mechanism: SHOWLIB * sim_agent

In particular we can define a hierarchy of classes of agents, each of
which has a collection of rulesets defining its behaviour. E.g. in the
example below, the rulesets for the agents include

    asim_perception_rules
            - for dealing with sensor inputs
    asim_message_in_rules
            - for processing new messages
    asim_deliberate_rules
            - for deciding which goals to adopt
    asim_planning_rules
            - for making plans
    asim_action_rules
            - for doing next steps in actions
    asim_message_out_rules
            - for generating messages out
    asim_tank_rules
            - for tank drivers
    asim_commander_rules
            - special rules for commanders

Different classes of agents can have different combinations of rulesets,
and may process them in different orders.

Note that in the example below the agents are merely a few tanks and
their commanders. There are no inanimate objects. However it would be
possible to treat inanimate objects using this mechanism: they would
be objects with data but no rulesets.

It would also be possible to have some sort of global map-like database
of the world, e.g. a 2-D array. At present the only truly global
database is the list of all agents, which is short enough to be scanned
repeatedly.


-- HOW IT WORKS -------------------------------------------------------

There is a scheduler defined in LIB SIM_AGENT which is given a list
of agents and a number N of cycles, e.g.

    sim_scheduler(all_agents 50);

It then repeatedly does the following (A, then B) N times:
    A.
      For each agent:
      1. Set up sensory detector inputs for the agent, using the method
            sim_run_sensors
         which may be different for different agent classes.
         This may insert new sensory information into the agent's
         database.
      2. For each of the agent's rulsets run the agent with that
         ruleset (using prb_run, as defined in LIB POPRULEBASE).
         This will typically change the agent's local database.
      3. Set up output actions to be performed during B below.
      4. Set up output messages to be sent during B below.

    B.
      For each agent:
      1. Transmit its output messages to their targets, and clear the
         output buffer.
      2. Perform the actions, which may change location or do other
         things to change the world.

-- -- Resource allocation between agents or sub-mechanisms

The scheduler includes additional facilities to allow some agents to run
faster than others, by using a "slowness" value associated with each
agent to run it only in a subset of cycles.

It is possible for an agent to give some of its mechanisms different
resources by including the relevant ruleset more than once in its list
of rulesets.


-- -- This file is executable
This is an executable file. It will take some time to load the first
time because it compiles LIB OBJECTCLASS and LIB POPRULEBASE


-- PATTERN FORMS TO BE USED IN THE DATABASE (First Draft)
The database for each agent acts as a sort of blackboard for its
rules. For some purposes it may be useful to use sub-databases.

The following pattern forms will be used.

These are merely first draft suggestions and may change. Eventually we
must have a proper grammar for the different forms. Wherever possible
use a logical structure for anything with propositional content.

The items marked with an asterisk are used by methods defined in the
generic library, LIB SIM_AGENT.

-- -- New sensory input
* [new_sense_data ...]
    E.g. [new_sense_data ?object ?distance]    - produced by sim_sense_agent
    (We need to agree on permitted formats for the sensory data)
-- -- New messages received
    (Compare message_out format below)
* [message_in ...]
    Format
        [message_in ?sender ?number <message content>]
    E.g. [message_in ?sender ?number instruct goal at ?x ?y]
    (The number is the message_id and if not false means acknowledgement
    is wanted.)
    Possible formats for the <message content>, e.g.
        ask <propositional form>
        inform <propositional form>
        instruct <action/goal form>
        suggest <action/goal form>
        acknowledge <message_id>
        etc.
-- -- Beliefs
    (Need to agree on format. Use a well defined logic.)
  [belief ... ]
    E.g. [belief at ?object ?location]
-- -- Goals
    (Need to agree on a format. Should share structure with beliefs.)
  [goal ... ]
      E.g. [goal at x y]
-- -- Plans
    (A plan will have information about what it is for, and a suggestion
    of actions or sub-goals, plus possibly other information, e.g.
    how far execution has gone, etc.)
  [plan ...]
-- -- Actions to be executed
The actions will be created by the rules in asim_action_rules. At the
end of each cycle, the scheduler takes all these from the agent's database
and executes them.
* [do ....]
    Format
        [do procedure arg1 arg2 ...]
    E.g. [do asim_move_to ?x ?y ?my_xloc ?my_yloc]

-- -- Messages to be sent
Created by the rules in asim_message_out_rules. At the end of each
cycle the scheduler takes these and transfers them to the recipients,
after suitable modification.
* [message_out ...]
    Format
    [message_out ?recipient ?number <message content>]
    E.g. [message_out ?recipient ?number instruct goal at ?x ?y]
    The formats for the <message content> are the same as for the
    [messages_in ...] items.


-- INDEX OF METHODS PROCEDURES CLASSES AND RULES
(Use "<ENTER> g define" to access required item)
(Recreate this index by "<ENTER> indexify define")

 define asim_army_rulesets();
 define asim_tank_rulesets();
 define asim_tank_commander_rulesets();
 define :class asim_army_agent; is sim_agent;
 define :class asim_tank_agent; is asim_army_agent;
 define :class asim_helicopter_agent; is sim_agent;
 define :mixin asim_commander;
 define :class asim_tank_commander;
 define :class asim_heli_commander; ;;; Not yet used
 define :method sim_distance(a1:sim_object, a2:sim_object) -> dist;
 define :method print_instance(item:asim_tank_agent);
 define :method sim_run_agent(agent:asim_army_agent, agents);
 define TRACE_proc(obj, action);
 define :ruleset asim_perception_rules;
 define :ruleset asim_message_in_rules;
 define coord_distance(x1, y1, x2, y2) -> dist;
 define :ruleset asim_deliberate_rules;
 define asim_angleof (dx,dy) ->angle;
 define asim_heading_to (x, y, oldx, oldy);
 define asim_move_to(agent, newx, newy, oldx, oldy);
 define asim_set_speed_zero(agent);
 define :ruleset asim_action_rules;
 define asim_trace_messages_out();
 define :ruleset asim_message_out_rules;
 define asim_commander_tell_go(location);
 define :ruleset asim_commander_rules;
 define :instance red_tank_commander:asim_tank_commander;
 define :instance red1:asim_tank_agent;
 define :instance red2:asim_tank_agent;
 define :instance blue_tank_commander:asim_tank_commander;
 define :instance blue1:asim_tank_agent;
 define :instance blue2:asim_tank_agent;
 define :method sim_agent_running_trace(agent: sim_object);
 define :method sim_agent_messages_out_trace(agent:sim_agent);
 define :method sim_agent_actions_out_trace(agent:sim_object);
 define :method sim_agent_ruleset_trace(agent:sim_agent, ruleset);
 define :method sim_agent_endrun_trace(agent:sim_object);

*/

;;; LOAD REQUIRED LIBRARIES IF NOT ALREADY LOADED
;;; 1 -> popgctrace;
;;; Increase popmemlim to reduce GC time
max(popmemlim, 800000) -> popmemlim;
uses objectclass
uses poprulebase
uses prb_extra
uses sim_agent;
false -> popgctrace;


/*
-- THE DEFAULT RULE-TYPES
*/

;;; a first shot set of rulesets for simple army agents, etc.
global vars
    asim_perception_rules = [],        ;;; for dealing with sensor inputs
    asim_message_in_rules = [],        ;;; for processing new messages
    asim_deliberate_rules = [],    ;;; for deciding which goals to adopt
    asim_planning_rules = [],        ;;; for making plans
    asim_action_rules = [],            ;;; for doing next steps in actions
    asim_message_out_rules = [],        ;;; for generating messages out
    asim_tank_rules    = [],            ;;; for tank drivers
    asim_commander_rules = [],        ;;; special rules for commanders
;

/*

-- THE SET OF RULESETS FOR EACH AGENT TYPE

For each type of agent, define the corresponding collection of rulesets,
to be run on each activation. Different agent types may have different
collections of rulesets. It is possible for an individual agent's
rulesets to be different from those of the class, and it is possible
for an agent's rulesets to change dynamically, e.g. to implement some
forms of learning, or development of an architecture over time.

The lists of rulesets are not directly stored in the sim_rulesystem slot
(See LIB SIM_AGENT). Instead they are represented by a procedure which can
compute them when required (e.g. on each cycle of the scheduler).
This provides more flexibility and easier development.
*/

;;; A default collection of rulesets for an agent.
define asim_army_rulesets();
    [asim_perception_rules asim_message_in_rules asim_deliberate_rules
     asim_planning_rules asim_action_rules asim_message_out_rules]
enddefine;

define asim_tank_rulesets();
    [asim_perception_rules asim_message_in_rules asim_deliberate_rules
     asim_planning_rules asim_tank_rules asim_action_rules
     asim_message_out_rules]
enddefine;

define asim_tank_commander_rulesets();
    [asim_perception_rules asim_message_in_rules asim_deliberate_rules
     asim_planning_rules asim_commander_rules asim_tank_rules
     asim_action_rules asim_message_out_rules]
enddefine;

/*

-- NEW SUB_CLASSES FOR THIS DEMO

-- -- class asim_army_agent

*/

define :class asim_army_agent; is sim_agent;
    slot sim_status == "alive";        ;;; could be "dead", "ill", etc.

    ;;; Assume (for now) that each agent has a heading and a speed,
    slot asim_heading == 0;
    slot asim_speed == 0;

    slot asim_location = conspair(0,0);

    ;;; Information about the agent's role in the battle scenario
    slot asim_army;    ;;; e.g. could be "red_army", "blue_army", etc.
    slot asim_commander;    ;;; could be false for top level commander

    ;;; Information about rules to be obeyed. Rules defined below.
    slot sim_rulesystem = asim_army_rulesets;
enddefine;

/*
-- -- class asim_tank_agent
*/

define :class asim_tank_agent; is asim_army_agent;
    slot asim_gun_heading == 0;
    ;;; e.g. if there may be big, medium & small tanks, then...
    slot asim_size = "medium";
    slot rulesets = asim_tank_rulesets;
enddefine;

/*
-- -- helicopter agent to be added later?

define :class asim_helicopter_agent; is sim_agent;
    asim_location = conspair(0,0);
    slot asim_max_speed == 100;
    slot asim_load;
enddefine;

*/

/*
-- -- mixin asim_commander
*/
;;; Now a mixin type which can be combined with a class to produce
;;; a commander for that class. (See REF * OBJECTCLASS/Mixins )
define :mixin asim_commander;
    slot asim_startgoals == [];        ;;; initial goals
    slot asim_subordinates == [];    ;;; agents to which commands can be given
    slot asim_commander == false;
enddefine;


/*
-- -- A subclass for commanding tanks
*/
define :class asim_tank_commander;
    is asim_tank_agent asim_commander;
    slot sim_rulesystem = asim_tank_commander_rulesets;
enddefine;


/*


define :class asim_heli_commander; ;;; Not yet used
    is asim_helicopter_agent asim_commander;
    slot sim_rulesystem = asim_heli_commander_rulesets;
enddefine;

*/


/*
-- METHODS FOR "ARMY" AGENTS
*/

define :method sim_distance(a1:sim_object, a2:sim_object) -> dist;
	;;; Compute distance between two agents.
	lvars a1, a2, dist;
	lvars x1, y1, x2, y2;
	destpair(asim_location(a1)) ->(x1, y1);
	destpair(asim_location(a2)) ->(x2, y2);
	sqrt((x1-x2)**2 + (y1-y2)**2) -> dist;
enddefine;

/*
-- -- Global variables set in sim_run_agent for army agents
*/
global vars my_commander, my_xloc, my_yloc;

;;; Specialise the print method
define :method print_instance(item:asim_tank_agent);
/*
    ;;; A possible more elaborate printing function
    printf(
        '<agent name:%P status:%P at(%P %P) heading:%P>',
        [% sim_name(item), sim_status(item),
            destpair(asim_location(item)), asim_heading(item)%])
*/
    ;;; But for now just print the name
    printf(
        '<agent %P >', [% sim_name(item) %])
enddefine;


;;; Specialise the sim_run_agent method, to set some additional
;;; global variables, and then run the normal sim_run_agent method.

define :method sim_run_agent(agent:asim_army_agent, agents);
    ;;; Set up environment for running the army agent.
    ;;; This will be extended when the next method runs
    ;;; I.e. the generic sim_run_agent
    dlocal
        my_commander = asim_commander(agent),
        (my_xloc, my_yloc) = destpair(asim_location(agent));

    ;;; Now run the generic version of the method
    call_next_method(agent, agents);
enddefine;

/*
-- BEHAVIOUR RULES FOR ARMY AGENTS

-- -- asim_perception_rules

*/

;;; **** some rules missing here ****

;;; TRACE actions with keys in this list will be run.
global vars ptrace_list = [sense acting comms ];

define TRACE_proc(obj, action);
	;;; for running [TRACE ... ] actions
	vars keyword, stuff;
	if action matches #_< [TRACE ?keyword ??stuff] >_#
	and lmember(keyword, ptrace_list)
	then
		prb_instance(stuff) ==>
	endif
enddefine;

;;; Link that procedure with the action type keyword.
TRACE_proc -> prb_action_type("TRACE");

define :ruleset asim_perception_rules;

  RULE see_last  ;;; in asim_perception_rules

      ==>

    [TRACE sense 'deleting sense input:' [$$ (prb_database("new_sense_data"))]]
    [NOT new_sense_data ==]
    [POP11 prb_print_database()]
    [STOP]
enddefine;

/*
-- -- asim_message_in_rules
*/

;;; If prb_repeating is not false, the next rule will have to have
;;; an action to prevent itself being invoked repeatedly!


define :ruleset asim_message_in_rules;

  RULE mess_in_ack1  ;;; in asim_message_in_rules

    ;;; to acknowledge messages requiring acknowledgement
    ;;; NB acknowledgements should not be acknowledged
    [message_in ?source ?mess_id ??contents]
    [WHERE mess_id == false]
	==>
    ;;; acknowledge only those messages with a non-false mess_id
    [DEL 1]
    [TRACE comms 'Received message from' [$: sim_name ?source] ?contents]

  RULE mess_in_ack2  ;;; in asim_message_in_rules

    ;;; to acknowledge messages requiring acknowledgement
    ;;; NB acknowledgements should not be acknowledged
    [message_in ?source ?mess_id ??contents]
	[->> Mess]
    [WHERE mess_id]        ;;; I.e. non-false
	[NOT acknowledged ?Mess]
    ==>
    ;;; acknowledge only those messages with a non-false mess_id
    ;;; prepare acknowledgement message. Doesn't need a goal??
        [message_out ?source ^ false acknowledge ?mess_id]
		[acknowledged ?Mess]
		[LVARS [source_name = sim_name(source)]]
        [TRACE comms 'Acknowledging' ?mess_id from ?source_name ?contents]

/*
;;; The above two replace this horrible beast, which was meant to be
;;; More efficient. But it's not worth it!

	RULE mess_in_ack ;;; Now not used
    ;;; to acknowledge messages requiring acknowledgement
    ;;; NB acknowledgements should not be acknowledged
    [message_in ==]
	==>
    ;;; acknowledge only those messages with a non-false mess_id
    ;;; This is messy. Could do with improved syntax.
    [POP11
        prb_forevery([[message_in ?source ?mess_id ??contents]],
            procedure(vec, num); lvars vec, num;    ;;; ignore args
                if mess_id then
                    ;;; prepare acknowledgement message. Doesn't need a goal??
                    prb_eval(
                        [message_out ?source ^false acknowledge ?mess_id]);
                    prb_eval(
                        [TRACE comms acknowledging ?mess_id from
                            ^(sim_name(source)) ?contents])
                endif
            endprocedure)]
enddefine;

*/


  RULE mess_in1  ;;; in asim_message_in_rules

    [message_in ?commander ?mess_id instruct stop]
    ;;; could add check that ?commander == my_commander
 	==>
    [DEL 1]
    [goal do stop]

  RULE mess_in2  ;;; in asim_message_in_rules

    [message_in ?commander ?mess_id instruct ??command]
    ;;; could add check that ?commander == my_commander
    ==>
    [DEL 1]
    [??command]


  RULE mess_in_last  ;;; in asim_message_in_rules

    ;;; run when no more [message_in ... ] items exist
    [NOT message_in ==]
    ==>
    [STOP 'Finished processing messages']
enddefine;

/*
-- -- asim_deliberate_rules
*/


define coord_distance(x1, y1, x2, y2) -> dist;
    lvars x1, y1, x2, y2, dist;
    sqrt((x1-x2)**2 + (y1-y2)**2) -> dist;
enddefine;


define :ruleset asim_deliberate_rules;

  RULE sim_check_at  ;;; in asim_deliberate_rules

    ;;; if already within a step of a goal location, then stop and
    ;;; tell commander
    [ goal at ?x ?y]
    [WHERE
		coord_distance(x, y, my_xloc, my_yloc) <= asim_speed(sim_myself)]
    ==>
	[VARS my_xloc my_yloc]
	[SAY Reached ?x ?y at ?my_xloc ?my_yloc ]
    [DEL 1]
    [goal asim_stop]
	[LVARS [commander = my_commander]]
    [tell ?commander at ?x ?y]
    ;;; ?????that should trigger a message_out action.

  RULE deliberate_last  ;;; in asim_deliberate_rules

    ;;; no more goals to process
      ==>
    [STOP]
enddefine;



/*
-- -- asim_action_rules

-- -- Utilities for action rules

*/

define asim_angleof (dx,dy) ->angle;
    ;;; used in asim_heading_to
    if abs(dx) >= abs(dy) then
        round(arctan(abs(dy/dx)))
    else 90 - round(arctan(abs(dx/dy)))
    endif ->angle;
    if dx > 0
    then if dy < 0 and angle /== 0
        then 360 -angle->angle
        endif
    else
        if dy <0
        then 180 + angle
        else 180 - angle
        endif -> angle
    endif
enddefine;

define asim_heading_to (x, y, oldx, oldy);
    ;;; used in next rule
    lvars x, y, oldx, oldy;
    asim_angleof (x-oldx, y-oldy)
enddefine;

define asim_move_to(agent, newx, newy, oldx, oldy);
    lvars newx, newy, oldx, oldy, agent;
    lvars speed = asim_speed(agent),
        loc = asim_location(agent),
        heading = asim_heading_to(newx, newy, oldx, oldy);
        if speed = 0 then
            ;;; start moving
            ;;; funny defaults
            1 ->> speed -> asim_speed(agent);
        endif;
        oldx + (speed * cos(heading)) ->> front(loc) ->my_xloc;
        oldy + (speed * sin(heading)) ->> back(loc) -> my_yloc;
    fill(my_xloc, my_yloc, loc) ->;
	;;; suppress the indication that the goal has been noted
	sim_delete_data([noted [goal at ^newx ^newy]], sim_data(sim_myself));
enddefine;

define asim_set_speed_zero(agent);
    lvars agent;
    ;;; causes agent to stop moving
    0 -> asim_speed(agent);
enddefine;


define :ruleset asim_action_rules;

  RULE asim_move_to  ;;; in asim_action_rules

    [ goal at ?x ?y]
	[->> Goal]
	[NOT noted ?Goal]
    ==>
	;;; prevent goal being noticed twice in one time-slice
	[noted ?Goal]
    [TRACE acting 'moving to' ?x ?y]
	[LVARS [xloc = my_xloc] [yloc = my_yloc]]
    [do asim_move_to ?x ?y ?xloc ?yloc]

  RULE asim_do_stop  ;;; in asim_action_rules

    [goal asim_stop]
    ==>
    [DEL 1]
    [do asim_set_speed_zero]


  RULE act_last  ;;; in asim_action_rules

      ==>
    [STOP 'action rules done']
enddefine;

/*

-- -- asim_message_out_rules

*/

define asim_trace_messages_out();
    lvars item messages;
    [Outgoing messages ^(prb_database("message_out"))] ==>
enddefine;

define :ruleset asim_message_out_rules;

  RULE tell_goals  ;;; in asim_message_out_rules

    [goal tell ?target ??rest]
	==>
    [DEL 1]
    [message_out ?target ^false ??rest]

  RULE tell_last  ;;; in asim_message_out_rules

      ==>
    [POP11 asim_trace_messages_out()]
    [STOP]
enddefine;

/*
-- -- asim_commander_rules
*/

;;; Make sure it starts from 1 each time this file is recompiled
1 -> gensym("commander");

define asim_commander_tell_go(location);
    ;;; prepare message to tell all subordinates to go to the location
    lvars
		other,
		;;; list of names of subordinates
		others = asim_subordinates(sim_myself);
    for other in others do
        prb_add([message_out ^(valof(other))
                    ^(gensym("commander"))    ;;; message id
                        instruct goal at ^^location])
    endfor;
enddefine;


define :ruleset asim_commander_rules;

  RULE comm1  ;;; in asim_commander_rules

    [goal my_army at ??location]
    [NOT my_army informed where]
	==>
    [NULL [$: asim_commander_tell_go ?location]]
	;;; could be [POP11 asim_commander_tell_go(location)]
    [TRACE comms 'told subordinates to go to' ??location]
    [my_army informed where]
enddefine;



/*
-- NOW CREATE THE INSTANCES

-- -- the red army

*/

define :instance red_tank_commander:asim_tank_commander;
    asim_army = "red_army";
    asim_location = conspair(0,0);
    asim_startgoals = [[goal blue_army dead]];
    asim_subordinates = [red1] ;;; [red1 red2];
enddefine;

define :instance red1:asim_tank_agent;
    asim_commander = red_tank_commander;
    asim_location = conspair(1,0);
enddefine;

define :instance red2:asim_tank_agent;
    asim_commander = red_tank_commander;
    asim_location = conspair(2,0);
enddefine;

/*
-- -- The blue army
*/


define :instance blue_tank_commander:asim_tank_commander;
    asim_army = "blue_army";
    asim_location = conspair(100,0);
    asim_startgoals = [[goal my_army at 50 100]];
    asim_subordinates = [blue1]    ;;; [blue1 blue2];
enddefine;

define :instance blue1:asim_tank_agent;
    asim_commander = blue_tank_commander;
    asim_location = conspair(101,0);
	asim_speed = 3;
enddefine;

define :instance blue2:asim_tank_agent;
    asim_commander = blue_tank_commander;
    asim_location = conspair(102,0);
enddefine;
/*
-- Set up the demo
*/

;;; This list could have been built automatically, by using a different
;;; syntax above.
global vars all_agents =
    [blue_tank_commander  blue1 ;;; blue2
;;;    red_tank_commander red1 ;;; red2
    ]

;

;;;; Give each instance its name
lvars item;
    [%for item in all_agents do
        item-> sim_name(valof(item)); valof(item) endfor
    %] -> all_agents;

all_agents ==>

;;; initialise the goals for commander agents
for item in all_agents do
    if isasim_commander(item) then
        sim_add_list_to_db(asim_startgoals(item), sim_data(item))
    endif;
endfor;

define :method sim_agent_running_trace(agent: sim_object);
    '------------------------------------------------------' =>
    [running ^(sim_name(agent)) with data:] ==>
	prb_print_table(sim_data(agent));
enddefine;


/*

-- TESTING THE PACKAGE
-- -- Preliminary information about tracing
;;; If prb_walking is set true, then
;;; Press RETURN when given the prompt
;;;     Walking>
;;; See HELP POPRULEBASE for other interactive options
;;; Abort with CTRL C

;;; for the next two see HELP POPRULEBASE
true -> prb_chatty;
false -> prb_chatty;

;;; Make it pause before each action if true
true -> prb_walk;
false -> prb_walk;
true -> prb_show_conditions;
false -> prb_show_conditions;
[sim_check_at] -> prb_show_conditions;

;;; things that can be traced if necessary
untrace sim_sense_agent sim_run_sensors;
untrace prb_add;
untrace prb_flush;

;;; The second argument specifies the number of top level cycles.
;;; Use a small number for now. Can interrupt with CTRL-C
;;; Hit return after each pause.
;;; During pause type .data to see database for current agent.
;;; See HELP POPRULEBASE for other options
;;; Remember, messages sent will be received only in the following cycle
;;; So to test anything interesting you need at least two cycles

sim_scheduler(all_agents, 4);

-- -- Reduce tracing

Here are modified versions of trace functions.
*/

define :method sim_agent_messages_out_trace(agent:sim_agent);
	lvars agent;
/*
	lvars messages = sim_out_messages(agent);
	[New messages ^(sim_name(agent)) ^messages] ==>
*/
enddefine;

define :method sim_agent_actions_out_trace(agent:sim_object);
	lvars agent;
/*
	lvars actions = sim_actions(agent);
	[New actions ^(sim_name(agent)) ^actions] ==>
*/
enddefine;

define :method sim_agent_ruleset_trace(agent:sim_agent, ruleset);
	lvars agent, ruleset;
/*
	['Try ruleset' ^ruleset 'with agent' ^(sim_name(agent))]==>
	'With Data: ' =>
	prb_print_table(sim_data(agent));
*/
enddefine;

define :method sim_agent_endrun_trace(agent:sim_object);
	['Data in' ^(sim_name(agent)):]==>
	prb_print_table(sim_data(agent));
enddefine;

/*
-- -- Run it much faster, by sending output to a file
;;; Most of the slowness is in the output to terminal. Instead save the
;;; output to a disc file and it goes very much faster (but makes a big
;;; file):
lib save;        ;;; See HELP * SAVE

;;; Run with 50 cycles, saving output in a file called sim.out, which
;;; can later be read in the editor. (It can grow quite large, so
;;; beware of disk overflow.)
save('sim.out.tmp', sim_scheduler(% all_agents, 50 %));
;;; Or do it with only 5 cycles.
save('sim.out.tmp', sim_scheduler(% all_agents, 5 %));

;;; Then ENTER ved sim.out.tmp

;;; to have garbage collections recorded do
true -> popgctrace;
;;; turn off
false -> popgctrace;
*/


/* --- Revision History ---------------------------------------------------
-- RECORD OF CHANGES
--- Aaron Sloman, July 1999
	Fixed to work properly with latest toolkit. Fixed minor bugs.

--- Aaron Sloman, May 26 1996
	Removed spurious global declarations, not needed since pattern variables
	are now all lexical.

--- Aaron Sloman, 30 Aug 1995
	Changed to prevent spurious repetition of some actions in the
	same time slice. Introduced use of [->> ..] conditions.

--- Aaron Sloman, 10 July 1995
	Changed to use prb_print_table
	Changed to use and other new features of poprulebase V2.

--- Aaron Sloman, 10 Jan 1995
	Because sim_location is no longer one of the default slots, introduced
		asim_location as a slot in asim_agent

	Replaced tracing procedures by methods, to reflect changes in main
		library
--- Aaron Sloman, Oct 17 1994
	Changed to use LIB POPRULEBASE and new version of SIM_AGENT
	(Nothing significant yet)
--- Aaron Sloman, Sep 14 1994
    1. Fixed some minor bugs
    2. Added asim_set_speed_zero. (Omitted by accident)
    3. Replaced complex and messy version of rule
        :rule mess_in_ack in asim_message_in_rules
      with these two, requiring one cycle of prb_run for each message
        :rule mess_in_ack1 in asim_message_in_rules
        :rule mess_in_ack2 in asim_message_in_rules
    4. Added more information about testing and tracing, and
        showed how to send output to a file, to speed up tests.

--- $poplocal/local/sim/teach/armysim.p
--- The University of Birmingham 1994.  --------------------------------
--- Copyright University of Birmingham 1999. All rights reserved. ------

 */
