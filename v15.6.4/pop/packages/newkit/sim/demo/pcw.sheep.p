/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/sim/demo/pcw.sheep.p
        Linked to TEACH sim_sheep.p
 > Purpose:         Sheepdog demo
 > Author:          Peter Waudby, Sep 13 1996 (see revisions)
 >                  Updated by Aaron Sloman Jan 1999
 > Documentation:   http://www.cs.bham.ac.uk/~axs/cog_affect/sim_agent.html
 > Related Files:
 */

/*

CONTENTS - (Use <ENTER> g to access required sections)

 -- Introduction and acknowledgement
 -- Load libraries required
 -- Global variables
 -- Class definitions
 -- Default tracing routines
 -- Utility functions and methods for sheep and dogs
 -- Printing methods for the agent classes
 -- The action routines
 -- Redefined sim_run_agent
 -- Button and drag methods for empty window space
 -- Button and drag methods for objects
 -- Rulesets for the agents
 -- . Ruleset for the dog
 -- . Rulesets and rulefamily for sheep
 -- . Rulesystems for dog and sheep
 -- Defining the objects (instances of the classes)
 -- Procedurs for setting up and running the demo
 -- Instructions to be printed out
 -- Index of classes, methods, procedures, rulesets, etc.

-- Introduction and acknowledgement

This was Peter Waudby's MSc project in the Summer of 1996

We are very grateful to him for making the code available
as a demonstration.

The demo was updated by Aaron Sloman in January and March 1999 to
make the code a little clearer and the demo easier to run.

In particular objects (dog, sheep, trees, posts) are now movable
by means of the mouse so that the default scenario can easily
be varied before the program starts.

Also, instead of the dog following the mouse pointer at all times, it now
goes to the last point at which mouse button 1 was clicked, or
constantly heads towards the mouse pointer while it is being dragged.

Originally based loosely on techniques shown in TEACH SIM_DEMO, which
provides additional information.

See also TEACH SIM_FEELINGS, TEACH SIM_AGENT

=======================================================================

To run this demo compile the file (ENTER l1), which will print out
instructions. There are two procedures.

    sheep_setup();

Starts the initial scenario as specified by the agent definitions below.

After the picture is complete mouse button 1 (left) can be used to move
the objects to form a new configuration, including the dog (square with
small triangle), the sheep (large and small circle) the trees (large
circles), and the posts forming the sheep pen (medium circles).

To get the program running then do this (possibly with a larger number
for a longer run.

     run_sheep(2000);

If you have not previously run sheep_setup, this will run it for
you then pause to allow rearrangement, after which you should press
RETURN.

The number specifies the number of cycles of the main interpreter (the
number of simulated time steps). If you still have not got the sheep into
the pen by the end, you can repeat that command.

To stop the program before it has finished press button 3. You can re-start
any time by re-doing the run_sheep command.

The sheep are represented by two circles, one smaller than the other.

The dog is the square object with a triangular "nose". It will follow
the mouse pointer as you move it. The further away the mouse is
the faster the dog will move.

The sheep become sensitive to the dog only when it gets within a certain
distance, at which point they try to move away from it. The two large
circles are trees. The "pen" is made of a collection of smaller circles.

To get rid of the window, either exit pop11, or do

    rc_kill_window_object(sheep_win);

========================
Aaron Sloman  20 Mar 1997 (Updated 23 Jan 1999 )

*/

/*
-- Load libraries required
*/

uses objectclass
uses poprulebase
uses sim_agent;
uses rc_linepic;
uses rc_mousepic;
uses rc_window_object;
uses sim_geom;


;;; Increase popmemlim to reduce garbage collection time.
;;; Experiment with the number.
max(popmemlim, 1000000) -> popmemlim;


/*
-- Global variables
*/

global vars

	;;; Window parameters
	;;; location of top left of window
    sheep_window_x = 600,
	sheep_window_y = 20,
	;;; width and height of window
    sheep_window_xsize = 500,
	sheep_window_ysize = 500,

    ;;; In case recompiling, get rid of old agents. Prepare global list.
    sheep_agents = [],

    ;;; Set the maximum visual range of the sheep
    trial_visual_range = 160,

    ;;; A global array to contain precalculated values used to determine
    ;;; how a perceived object's importance varies with distance.
    ;;; Importance associated with an object decreases exponentially
	;;; with distance

    zone_weighting =
        newarray([1 8], procedure(x); round(100*2**(-x+1)) endprocedure),

    ;;; The co-ordinates that the sheepdog heads towards initially.
    xdog = rc_window_xsize div 2 - 20,
    ydog = rc_window_ysize div 2 - 20,

    ;;; Size of selectable box in mouse-movable objects (40x40 square)
	;;; default value for rc_mouse_limit
    rc_select_distance = {-15 -15 15 15},

    ;;; Global variable to alter effect of mouse events
    demo_running = false,

    ;;; Made true by mouse button 3
    sheep_stopped = false,

    gromit,         ;;; The Dog defined below;
    sheep_win,      ;;; The window (instance of rc_window_object)

    ;;; If this variable is given a number > 0 that will slow
    ;;; down the running of the program. It is used by the procedure
    ;;; rc_sync_display.
    rc_sync_delay_time = 0,
    ;

;;; rulesystems defined below.
global vars
    trial_sheep_rulesystem,
    trial_dog_rulesystem;


/*
-- Class definitions
*/

define :class trial_agent;
    is rc_rotatable rc_linepic_movable rc_selectable sim_agent;
    ;;; The base class for all agents in the trial

    slot trial_heading == 0;        ;;; Which was the agent is pointing
    slot trial_size == 10;          ;;; The agent's physical size
    slot rc_picx == 0;              ;;; The x and y coordinates of the agent
    slot rc_picy == 0;              ;;; within the environment and picture
    slot sim_sensors = [];          ;;; List of which senses the agent has

enddefine;

define :class trial_sheep; is trial_agent;
    ;;; The class defining the sheep's attributes

    ;;; Maybe some of these should be randomised?
    slot trial_hunger == 1;         ;;; Between 0 (stuffed) and 3 (starving)
    slot trial_fatigue == 20;       ;;; Between 0 (fresh) and 100 (knackered)
    slot trial_speed == 0;          ;;; Speed = distance travelled per move
    slot trial_pspace == 30;        ;;; Limit of sheep's personal space
    slot trial_pack_range == 60;    ;;; Max satisfactory distance from other sheep
    slot trial_flock_range == 100;  ;;; Max range whilst remaining in flock
    slot trial_obstacle_range == 40; ;;; Distance when obstacles are first noticed

	;;; a vector defining a box for mouse sensitivity
    slot rc_mouse_limit == {-20 -20 20 20};

    slot rc_pic_lines ==            ;;; What the sheep looks like
          [
			WIDTH 3
            [CIRCLE {0 0 10}]       ;;; Round body
            [CIRCLE {13 0 5}]       ;;; Round head
          ];

    slot sim_rulesystem = trial_sheep_rulesystem;   ;;; Which rules to follow
    slot sim_sensors = [{sim_sense_agent ^trial_visual_range}]; ;;; Defines senses
enddefine;

define :class trial_dog;
    ;;; The class which defines the sheepdog's attributes

    is trial_agent;
    slot trial_speed == 0;          ;;; Speed = distance travelled per move
    slot rc_pic_lines ==            ;;; What the dog look like
          [
			WIDTH 3
            [CLOSED {-10 10}  {10 10} {10 -10}  {-10 -10}]   ;;; Square body
            [CLOSED {8 8}  {8 -8} {17 0}]                ;;; Triangular head
          ];
    slot sim_rulesystem = trial_dog_rulesystem;     ;;; Which rules to follow
enddefine;

define :class trial_obstacle;
    ;;; A mixin used by all static objects in the trial
    ;;; All obstacles should be circular if obstacle avoidance is to work
    is trial_agent;

    slot rc_pic_lines ==            ;;; What the obstacle looks like
          [
			WIDTH 3
            [CIRCLE {0 0 10}]       ;;; Circle with radius = trial_size
          ];
enddefine;

define :class trial_tree;
    is trial_obstacle;
    ;;; Trees are larger than the sheep
    slot trial_size == 15;          ;;; Size is larger than default

	;;; a vector defining a box for mouse sensitivity
    slot rc_mouse_limit == {-20 -20 20 20};
    slot rc_pic_lines ==
          [
			WIDTH 3
            [CIRCLE {0 0 15}]       ;;; Change graphics accordingly
          ];
enddefine;

define :class trial_post;
    is trial_obstacle;

    ;;; Posts are smaller than the sheep
    slot trial_size == 8;           ;;; Size is smaller than default
    slot rc_pic_lines ==
          [
			WIDTH 3
            [CIRCLE {0 0 8}]        ;;; Change graphics accordingly
          ];
enddefine;


/*
-- Default tracing routines
*/

;;; All relevant trace routines have been overridden to prevent
;;; large amounts of trace output. See LIB * SIM_HARNESS

define :method sim_agent_running_trace(object:trial_agent);
enddefine;

define :method sim_agent_messages_out_trace(agent:trial_agent);
enddefine;

define :method sim_agent_messages_in_trace(agent:trial_agent);
enddefine;

define :method sim_agent_actions_out_trace(object:trial_agent);
enddefine;

define :method sim_agent_rulefamily_trace(object:trial_agent, rulefamily);
enddefine;

define :method sim_agent_endrun_trace(object:trial_agent);
enddefine;

define :method sim_agent_terminated_trace(object:trial_agent, number_run, runs, max_cycles);
enddefine;

define vars procedure sim_scheduler_pausing_trace(objects, cycle);
    ;;; user definable
    ;;; Uncomment next line to get cycle numbers printed out
    ;;;pr('\n=== end of cycle ' >< cycle >< '===\n');
enddefine;

;;; The next procedure is run by sim_scheduler at the end of each
;;; time slice

define vars procedure sim_post_cycle_actions(objects, cycle);
    ;;; The variable sheep_stopped is made true by using mouse button 3
    if sheep_stopped then
        ;;; printf('\nSTOPPED by user.');
        vedputcommand(':run_sheep(2000)');
        vedputmessage('Press REDO to restart');
        exitfrom(sim_scheduler);
    endif;
enddefine;

/*
-- Utility functions and methods for sheep and dogs
*/

;;; These functions are used to perform specific calculations
;;; They are called by the more central procedures which make
;;; constructive use of the results.
;;; They are the 'shallow' part of the 'broad but shallow' design

define trial_coords(t) /* -> (x, y)*/;
    ;;; get two numbers representing current location of t
    rc_picx(t), rc_picy(t);
enddefine;

define :method sim_distance(a1:trial_agent, a2:trial_agent) ;
    ;;; Compute distance between agent a1 and another object.
    ;;; Used to determine whether the agent a1 can "sense" the object
    sim_distance_from(trial_coords(a1), trial_coords(a2));
enddefine;

define :method agent_bearing( agent:trial_agent, target:trial_agent) -> result;
    ;;; Calculates the direction of a target from the perspective
    ;;; of the specified agent

	round(
        sim_degrees_diff(
            sim_heading_from(trial_coords(agent), trial_coords(target)),
            trial_heading(agent)) ) -> result;
enddefine;

define weighted_sum(components) -> (sumx, sumy, sumw);
    ;;; Given a list of positions which have been weighted for significance this
    ;;; function calculates the average position.

    lvars l, mag, sumx = 0, sumy = 0, sumw = 0;

    ;;; Pattern variables
    lvars element, weighting, r, theta, components;

    ;;; Determine how many positions are to be averaged
    listlength(components) -> l;

    repeat (l-1) times;
        ;;; Extract the next position to be averaged
        components --> ! [?element ??components];

        ;;; Find its weighting and polar coordinates
        element --> ! [?weighting ?r ?theta];

        ;;; Use this variable instead of calculating its value twice
        weighting * r -> mag;

        ;;; Having converted to Cartesian coordinates include the contribution
        mag * cos(theta) + sumx -> sumx;
        mag * sin(theta) + sumy -> sumy;

        ;;; Keep a record of the total weighting so far
        weighting + sumw -> sumw;

    endrepeat;
enddefine;

define :method collision_course(bearing, arc) -> result;
    ;;; This function determines if the current bearing will lead to a possible
    ;;; collision.  This occurs when the specified bearing falls within the range
    ;;; given in the arc

    lvars start, finish;

    ;;; This effectively rotates the angles so that the bearing is at 0 degrees
    ( front(arc) - bearing ) mod 360 -> start;
    ( start + back(arc) ) mod 360 -> finish;

    ;;; Now calculate if the range of angles contained in the new arc includes 0
    if start == 0 or start >  finish then
        true -> result;
    else
        false -> result;
    endif;
enddefine;

define check_range( pair1, pair2, diff) -> result;
    ;;; Given two ranges of angles this function determines if the start of the
    ;;; second range overlaps the end of the first
    ;;; If the ranges intersect then the combined range is returned if not
    ;;; then an empty list is returned.

    lvars start1, span1, start2, span2, result = [];

    ;;; Destruct the pairs to obtain the starting angle and the span in degrees
    ;;; of each range
    destpair(pair1) -> (start1, span1);
    destpair(pair2) -> (start2, span2);

    ;;; If the ranges intersect then
    if diff < span1 then
        ;;; If the second range is a subset of the first then
        if span1 > span2 + diff then
            ;;; Forget the second range and just return the first
            pair1 -> result;
        else
            ;;; Return the union of the two ranges
            diff + span2 -> span1;
            conspair(start1, span1) -> result;
        endif;
    endif;
enddefine;

define compare_ranges( base, test ) -> (result,altered);
    ;;; Given any two ranges of angles this function determines if they intersect
    ;;; If so the combined range is returned otherwise just the first range is returned
    ;;; The function also returns a value indicating if the ranges intersected

    ;;; Each range is specified by a pair consisting of a starting angle and the
    ;;; size of the range.  The span goes from the start in the direction of
    ;;; increasing angle. (It should be noted that although the step from
    ;;; 359 degrees to 0 degrees is a numerical reduction it is still considered
    ;;; as an increase in the angle.)

    lvars d;

    ;;; Determine how far apart (in degrees) the beginning of each range are.
    -sim_degrees_diff( front(base), front(test)) -> d;

    ;;; If the test range comes after the base range then
    if d > 0 then
        ;;; Try to incorporate the test range into the base range
        check_range( base, test, d ) -> result;
    else
        -d -> d;
        ;;; Try to incorporate the base range into the test range
        check_range( test, base, d ) -> result;
    endif;

    ;;; If the two ranges do not intersect
    if result == [] then
        ;;; Return the base range unaltered
        base -> result;
        false -> altered;
    else
        ;;; Record that a change has been made
        true -> altered;
    endif;
enddefine;

define obscured_ranges(range_list ) -> result;
    ;;; Given a list of ranges this function returns a list of non-intersecting
    ;;; ranges which encompass all the ranges of the original list

    lvars
		range_list, base_list = [],
		base_range, new_range, result_range,
    	b, l, altered;

    ;;; Determine how many ranges are to be considered
    listlength(range_list) -> l;

    repeat l times
        ;;; Get the next range
        range_list --> ! [ ?new_range ??range_list ];

        ;;; Find how many ranges are already in the base list
        listlength(base_list) -> b;

        ;;; Compare the new range with each element of the base list
        repeat b times
            ;;; Get the next range in the base list
            base_list --> ! [ ??base_list ?base_range];

            ;;; Try to combine the two ranges
            compare_ranges( base_range, new_range ) -> (result_range,altered);

            ;;; If the ranges intersected
            if altered then
                ;;; Update new range for subsequent loops
                result_range -> new_range;
            else
                ;;; If there was no intersection then the base range can be
                ;;; added back into the base list unaltered
                result_range :: base_list -> base_list;
            endif;
        endrepeat;

        ;;; After being combined with any overlapping ranges previously in the
        ;;; base list the resulting new range can be added to the base list
        new_range :: base_list -> base_list;

    endrepeat;

    ;;; Return the 'normalised' list of ranges
    base_list -> result;
enddefine;

define get_range( heading, choice_list) -> result;
    ;;; The range_list contains a list of ranges.  This function determines
    ;;; which if any of these ranges includes the specified heading.

    lvars result;
    vars current_choice, choice_list;

    ;;; Get the first range in the list
    choice_list --> [?current_choice ??choice_list];

    ;;; Go through the list until the heading falls into one of the ranges or
    ;;; the list is empty
    while not( collision_course( heading, current_choice) ->> result ) and
          listlength(choice_list) /= 0 do
        choice_list --> [?current_choice ??choice_list];
    endwhile;

    ;;; If a suitable range is found then it is returned
    ;;; otherwise a false result is returned.
    if result then
        current_choice -> result;
    endif;
enddefine;


/*
-- Printing methods for the agent classes
*/

define :method print_instance(item:trial_sheep);
    ;;; Used to control the info printed for sheep

    dlocal pop_pr_places = 0;
    printf(
        '<agent %P at (%P %P) heading %P hunger %P urgency %P>',
        [% sim_name(item), trial_coords(item), trial_heading(item),
           trial_speed(item), trial_hunger(item)%])
enddefine;

define :method print_instance(item:trial_dog);
    ;;; Used to control the info printed for dogs

    dlocal pop_pr_places = 0;
    printf(
        '<agent %P at (%P %P) heading %P>',
        [% sim_name(item), trial_coords(item), trial_heading(item),
           trial_speed(item) %])
enddefine;

define :method print_instance(item:trial_obstacle);
    ;;; Used to control the info printed for obstacles

    dlocal pop_pr_places = 0;
    printf(
        '<agent %P at (%P %P) heading %P>',
        [% sim_name(item), trial_coords(item), trial_size(item) %])
enddefine;

/*
-- The action routines
*/

;;; These routines make changes to the state of the world
;;; or the state of an agent

define :method resting(agent:trial_sheep);
    ;;; Decreases an agents fatigue

	;;; reduce speed
    trial_speed(agent)*0.25 -> trial_speed(agent);

	;;; reduce fatigue, ensuring it is never negative
    max(0, trial_fatigue(agent) - 5) -> trial_fatigue(agent);

enddefine;

define :method sheep_graze(agent:trial_sheep);
    ;;; Since hunger is fixed, sheep just rests
    ;;; Can easily change to allow changing hunger levels

    resting(agent);
enddefine;

define :method exercise( agent:trial_sheep);
    ;;; Increases an agents fatigue in proportion to its speed

    trial_fatigue(agent) + trial_speed(agent) -> trial_fatigue(agent);

    ;;; Cap fatigue at 100%
    if trial_fatigue(agent) > 100 then
        100 -> trial_fatigue(agent);
    endif;
enddefine;

define :method forward(agent:trial_agent, speed);
    ;;; Moves the agent forward by a distance related to its speed

    lvars aimx, aimy, cos_angle, sin_angle, safe_range, other;


    speed -> trial_speed(agent);

    ;;; These are stored to prevent repeated evaluation during the rest of
    ;;; the procedure
    cos(rc_axis(agent)) -> cos_angle;
    sin(rc_axis(agent)) -> sin_angle;

    ;;; Calculate where the agent intends to move to
    round( rc_picx(agent) + speed*cos_angle) -> aimx;
    round( rc_picy(agent) + speed*sin_angle) -> aimy;

    ;;; Now check if this will mean bumping into other agents
    for other in sheep_agents do
        ;;; Ignore oneself
        if other /== agent then

            ;;; Calculate how close the centres of the pair of agents can get.
            ;;; This distance depends on large their bodies are.
            trial_size(agent) + trial_size(other) -> safe_range;

            ;;; Check if the agent impinges on the space occupied by the other.
            while sim_distance_from( aimx, aimy, trial_coords(other) ) <= safe_range do
                ;;; If so then readjust the agent's speed until the two
                ;;; do not collide.
                ;;; In effect the agent moves as far forward as it can.
                speed - 1 -> speed;
                round( rc_picx(agent) + speed*cos_angle ) -> aimx;
                round( rc_picy(agent) + speed*sin_angle ) -> aimy;
            endwhile;
        endif;
    endfor;

    ;;; Set the position of the sheep
    rc_move_to(agent, aimx, aimy, true);

enddefine;

define :method set_heading(agent:trial_agent, heading);
    ;;; Allows an agents heading to be specified explicitly

    ;;; Set the heading of the sheep
    heading -> trial_heading(agent);

    ;;; Set the graphical orientation of the sheep
    rc_set_axis(agent, heading, true);
enddefine;

define :method set_status(agent:trial_agent, x, y, heading);
    ;;; Allows an agent's location and heading to be specified explicitly
	;;; after creation

	;;; first move the agent right off the picture
	rc_move_to(agent, -10000, -1000, true);

	;;; Now set the heading and move the agent back
    set_heading(agent, heading);
    rc_move_to(agent, x, y, true);
enddefine;

define :method move( agent:trial_sheep, bearing, speed );
    ;;; Allows sheep to turn and move with one function call

    set_heading(agent, bearing);
    forward(agent, speed);
enddefine;

define :method wander(agent:trial_sheep);
    ;;; Move slowly in undirected fashion

    ;;; Moves the agent forward with a random element determining its exact heading
    move( agent, (trial_heading(agent) + random(70) - 35) mod 360, 1 );
enddefine;

define :method sim_sense_agent(a1:sim_object, a2:sim_object, dist);
    ;;; Default sensor for detecting other agents. Called at the
    ;;; beginning of a1's turn in each time slice
    lvars bearing, sector, speed;

    unless a1 == a2 then
        agent_bearing(a1, a2) -> bearing;
		
    	;;; Calculates which sector a2 falls into from the perspective
    	;;; of a1
    	;;; There are six sectors around sheep, labelled 0 to 5,
		;;; each 60 degrees
        (bearing+180) div 60 -> sector;
        ;;; Information regarding a2 will be stored in a1's database
        [new_sense_data ^a2 ^dist ^bearing ^sector]
    endunless
enddefine;


/*
-- Redefined sim_run_agent
*/

;;; Variable declared here so that it is accessable within sim_run_agent
lvars my_name = 'name_undef';

define :method sim_run_agent(agent:trial_sheep, agents);
    ;;; Sets up the agents internal database ready for the execution of
    ;;; its rules

    ;;; Stores the name of the currently active agent.  This can be
    ;;; accessed within the rules
    dlocal
        my_name = sim_name(agent);

    ;;; The agent has no memory of any previous time slices
    sim_clear_database( sim_data(agent) );

    ;;; Add data to be used by the rules into the database
    prb_add_list_to_db(
		[   [Hunger ^(agent.trial_hunger)]
    		[Fatigue ^(agent.trial_fatigue)]
    		[Urgency 3]
    		[NEWLIMIT 3]
    		[Personal ^(agent.trial_pspace)]
    		[Visible ^(agent.trial_obstacle_range)]
    		[Regard ^(agent.trial_flock_range)]
    		[Pack ^(agent.trial_pack_range)]
    		[Flock_impulse []]
    		[Flee_impulse []]
    		[O_list]
		],
		sim_data(agent) );

    ;;; Now run the generic version of the method sim_run_agent
    call_next_method(agent, sheep_agents);
enddefine;


/*
-- Button and drag methods for empty window space

;;; Methods added by Aaron Sloman 22 Jan 1999
*/

;;; Methods for empty window space
define :method sheep_button_1_up(pic:rc_window_object, x, y, modifiers);
    ;;; do nothing
enddefine;

define :method sheep_button_1_down(pic:rc_window_object, x, y, modifiers);
    ;;; Key pressed in empty space.
    x, y -> (xdog,ydog);
enddefine;

define :method sheep_button_3_up(pic:rc_window_object, x, y, modifiers);
    ;;; Use this to terminate run
    true -> sheep_stopped;
enddefine;


;;; Method for empty window space.
define :method sheep_button_1_drag(pic:rc_window_object, x, y, modifiers);
    ;;; No object currently under mouse, i.e. event in window
    unless sheep_stopped then
        x, y -> (xdog,ydog);
    endunless;
enddefine;


/*
-- Button and drag methods for objects
*/

define :method rc_button_1_down(pic:trial_agent, x, y, modifiers);
    ;;; Make sure it is at the front of the known objects list
    rc_set_front(pic);
enddefine;


define :method rc_button_1_up(pic:rc_selectable, x, y, modifiers);
    ;;; disable default method
enddefine;


define :method rc_button_1_drag(pic:trial_agent, x, y, modifiers);
    ;;; If demo_running is true then the run_sheep program is running,
    ;;; so do not drag the object.
    unless demo_running then
        ;;; Make sure it is at the front of the list, otherwise there may
        ;;; be unexpected results if it is dragged over another object.
        rc_set_front(pic);
        ;;; now move it
        rc_move_to(pic, x, y, true)
    endunless;
enddefine;




/*
-- Rulesets for the agents

-- . Ruleset for the dog
*/


define :ruleset dog_movement_rules;
    ;;; Only one rule for the dog ---> Move towards the cursor

    RULE shepherd
    ;;; No conditions
    ==>
    [POP11
        lvars dist, speed;

        ;;; syssleep(0);
        ;;; The next command will sleep for rc_sync_delay_time
        ;;; hundredths of a second, if its value is not false
        rc_sync_display();

/*
        ;;; Previous dog control method. Now not used
        ;;; Get the last coordinates of the mouse cursor
        rc_transxyin(XptVal[fast] rc_window(XtN mouseX, XtN mouseY))
                -> (xdog, ydog);
*/

        ;;; Calculate how far away the cursor is
        sim_distance_from(trial_coords(sim_myself), xdog, ydog) -> dist;

        ;;; Relate the dog's speed to the distance of the cursor
        round(dist / 10) -> speed;

        ;;; Don't bother moving the dog if its speed is zero
        if speed /== 0 then
            ;;; Turn it to face the right way and move it forward
            set_heading(
                sim_myself,
                sim_heading_from(trial_coords(sim_myself), xdog, ydog));
            forward(sim_myself, speed);
        endif;
    ]
enddefine;

/*
-- . Rulesets and rulefamily for sheep
*/

define :ruleset trial_perception_rules;
    ;;; These rules take the incoming sense data and process it.
    ;;; Objects in the environment can be classified as obstacles, other sheep
    ;;; or dogs

    RULE see_obstacle
    ;;; Applies to obstacles within a given range
    [new_sense_data ?object:istrial_obstacle ?dist ?bearing ==]
    [Visible ?disp]
    [WHERE dist < disp]
    ==>
    [DEL 1]
    [LVARS range]
    [POP11
        lvars start, span, berth;

        ;;; Determine how wide a berth to give it
        trial_size(sim_myself) + trial_size(object) -> berth;

        ;;; Calculate the range of angles which should be avoided to prevent
        ;;; collision with the obstacle
        round( arcsin( berth / dist ) ) -> span;
        round ( ( bearing + trial_heading(sim_myself) - span ) mod 360 ) -> start;
        2 * span -> span;
        conspair( start, span ) -> range;
    ]
    [Obstacle ?object ?dist ?range]
    [SAYIF perception ?my_name 'has seen an obstacle']

    RULE spy_one
    ;;; Applies to the first sighting of another sheep
    [new_sense_data ?company:istrial_sheep ?dist ?bearing ?sector ==]
    [Regard ?distance]
    [WHERE dist < distance]
    [NOT Friend = = = ?sector]
    ==>
    [DEL 1]
    [Friend ?company ?dist ?bearing ?sector]
    [SAYIF perception ?my_name 'spies' [$$sim_name(company)] 'in sector' ?sector]

    RULE spy_more
    ;;; Applies on subsequent sightings of sheep
    [new_sense_data ?rival:istrial_sheep ?dist ?bearing ?sector ==]
    [Friend ?company ?distance = ?sector]
    [WHERE dist < distance]
    ==>
    [DEL 1 2]
    [Friend ?rival ?dist ?bearing ?sector]
    [SAYIF perception ?my_name 'thinks' [$$sim_name(rival)] 'is closer than'
                      [$$sim_name(company)] 'in sector' ?sector]

    RULE alert
    ;;; Applies when a dog is spotted
    [new_sense_data ?foe:istrial_dog ?dist ?bearing ?sector ==]
    ==>
    [DEL 1]
    [Foe ?foe ?dist ?bearing ?sector]
    [SAYIF perception ?my_name 'is aware of' [$$sim_name(foe)] 'in sector' ?sector]

enddefine;

define :ruleset trial_obstacle_rules;
    ;;; This corresponds to the physical level of the design
    ;;; When not subsumed this level acts to constrain the movement of
    ;;; sheep to prevent collision with obstacles.

    ;;; The effect of these contraints is relative to the movement desired by
    ;;; the upper layers of the architecture.  Therefore at this early stage all
    ;;; that is done is to collect the info regarding obstacles into a single list

    RULE gather
    ;;; Collect all obstacles into a single list
    [Obstacle = = ?range]
    [O_list ??list]
    ==>
    [DEL 1 2]
    [O_list ??list ?range]

    RULE normalise
    ;;; Simplify list into a set of non-intersecting set of obscured ranges
    [O_list ??list]
    ==>
    [DEL 1]
    [O_list [$$obscured_ranges(list)] ]

    RULE activity
    ;;; Ensures that last turns movement causes changes in fatigue level
    ==>
    [POP11
         exercise(sim_myself);
    ]
enddefine;

define :ruleset trial_instinct_rules;
    ;;; This corresponds to the biological level of the design
    ;;; When not subsumed this level aims to satisfy some of the basic survival
    ;;; needs of the sheep
    ;;; These instincts include eating and fleeing from sheepdogs

    ;;; The rules are divided into two sets.  The directed rules and the undirected
    ;;; rules.

    ;;; The directed rules include eating and fleeing from sheep dogs.  The
    ;;; actions taken serve to fulfil a specific objective.  Whilst they are
    ;;; unable to subsume the social level 'above' they can signal a degree
    ;;; of urgency which acts to limit the amount of processing done by higher
    ;;; levels

    ;;; The undirected rules act as default behaviours.  They ensure that the sheep
    ;;; will always take some action in each time slice (even if this action is
    ;;; to do nothing!)

    RULE eat
    ;;; If hungry then produce the desire to eat
    ;;; Also let hunger level affect level of urgency
    [Hunger ?hunger]
    [WHERE hunger > 0]
    [Urgency ?value]
    ==>
    [DEL 2]
    [POP11
        if 4 - hunger < value then
            4 - hunger -> value;
        endif;
    ]
    [Eat]
    [Urgency ?value]
    [SAYIF eat ?my_name 'wants to chew the cud']

    RULE flee
    ;;; If enemy is visible then try to move away
    ;;; Also let fear affect level of urgency
    [Foe ?company ?dist ?angle ==]
    [Flee_impulse ??imp_list]
    [Urgency ?value]
    ==>
    [DEL 2]
    [DEL 3]
    [LVARS speed weight]
    [POP11
        ;;; Calculate which direction to flee
        ( angle + trial_heading(sim_myself) + 180 ) mod 360 -> angle;

        ;;; Determine speed relative to how far away the dog is
        round(dist / 20) -> dist;
        10 - dist -> speed;

        ;;; If this is the most urgent action to date then update the urgency value
        if intof(dist/3)+1 < value then
            intof(dist/3)+1 -> value;
        endif;

        ;;; Calculate the weighting to associate with this action
        zone_weighting(dist) -> weight;
    ]
    [Flee]
    [Flee_impulse [?weight ?speed ?angle] ??imp_list]
    [Urgency ?value]
    [SAYIF fear ?my_name 'wants to flee from' [$$sim_name(company)]]


    ;;; These act as defaults.  They get acted out when no other
    ;;; behaviour is called for

    RULE lonely
    [NOT Friend == ]
    [NOT Flee]
    [NOT Eat]
    ==>
    [Wander]
    [SAYIF wander ?my_name 'wants to wander free']

    RULE contented
    [Friend ?company ==]
    [NOT Flee]
    [NOT Eat]
    [NOT Idle]
    ==>
    [Idle]
    [SAYIF contented ?my_name 'is having a great time!']
enddefine;

define :ruleset avoidance;
    ;;; This ruleset is part of the rulefamily which constitutes the social
    ;;; level of the design
    ;;; The first rule allows the sheep to keep their distance from other sheep
    ;;; The second rule sets the cycle limit of the rulefamily based on the
    ;;; urgency indicated by the biological level. It then makes the center
    ;;; ruleset the current ruleset.

    RULE avoidance
    ;;; Don't get too close to other sheep
    [Friend ?company ?dist ?angle ==]
    [Flock_impulse ??imp_list]
    [Personal ?zone]
    [WHERE dist < zone]
    ==>
    [DEL 2]
    [LVARS weight speed]
    [POP11
        ;;; Calculate which direction to move in to avoid the
		;;; neighbouring sheep
        ( angle + trial_heading(sim_myself) + 240 - random(120))
			mod 360 -> angle;

        ;;; Set the speed of movement based on the separation of the two sheep
        round(dist / 10.0) -> dist;
        round(zone / 10.0) - dist + 1 -> speed;

        ;;; Calculate the weighting to associate with this action
        zone_weighting(dist+2) -> weight;
    ]
    [Flock_impulse [?weight ?speed ?angle] ??imp_list]
    [SAYIF avoid ?my_name 'is avoiding'  [$$sim_name(company)]
                 'at speed' ?speed]

RULE limit1
    ;;; Urgency will affect thinking time during NEXT time slice
    [NEWLIMIT ?setting]
    [Urgency ?value]
    [WHERE value < setting]
    ==>
    [DEL 1]
    [NEWLIMIT ?value]

RULE flipper1
    ;;; Switch to next social rule
    ==>
    [RESTORERULESET center]
enddefine;

define :ruleset center;
    ;;; This ruleset is part of the rulefamily which constitutes the social
    ;;; level of the design
    ;;; The first rule allows the sheep to stay close to their neighbours
    ;;; The second rule sets the cycle limit of the rulefamily based on the
    ;;; urgency indicated by the biological level. It then makes the imitate
    ;;; ruleset the current ruleset.

    RULE centre
    ;;; Try to keep the flock together
    [Friend ?company ?dist ?angle ==]
    [Flock_impulse ??imp_list]
    [Pack ?range]
    [WHERE dist > range]
    ==>
    [DEL 2]
    [LVARS aimx aimy weight speed]
    [POP11
        ;;; Calculate which direction to move in to avoid the neighbouring sheep
        ( angle + trial_heading(sim_myself) ) mod 360 -> angle;

        ;;; Set the speed of movement based on the separation of the two sheep
        round( dist / 10.0 ) -> dist;
        dist - round( range / 10.0 ) + 2 -> speed;

        ;;; Calculate the weighting to associate with this action
        zone_weighting(dist - 2) -> weight;
    ]
    [Flock_impulse [?weight ?speed ?angle] ??imp_list]
    [SAYIF center ?my_name 'is centering on'  [$$sim_name(company)]
                 'at speed' ?speed]

RULE limit2
    ;;; Urgency will affect thinking time during NEXT time slice
    [NEWLIMIT ?setting]
    [Urgency ?value]
    [WHERE value < setting]
    ==>
    [DEL 1]
    [NEWLIMIT ?value]

RULE flipper2
    ;;; Switch to next social rule
    ==>
    [RESTORERULESET imitate]


enddefine;

define :ruleset imitate;
    ;;; This ruleset is part of the rulefamily which constitutes the social
    ;;; level of the design
    ;;; The first rule allows a sheep to move along with its neighbours
    ;;; The second rule sets the cycle limit of the rulefamily based on the
    ;;; urgency indicated by the biological level. It then makes the avoidance
    ;;; ruleset the current ruleset.

    RULE imitate
    ;;; Try to keep sheeps movements synchronised
    [Friend ?company ?dist ==]
    [Flock_impulse ??imp_list]
    [Personal ?zone]
    [Pack ?range]
    [WHERE dist < range]
    [WHERE dist > zone]
    [WHERE trial_speed(sim_myself) >= 1]
    [WHERE trial_speed(company) > 1]
    [WHERE random(100) > 50]
    ==>
    [DEL 2]
    [LVARS weight angle speed]

    [POP11
        ;;; Calculate which direction and speed to move at to keep in step
        ;;; with a neighour
        trial_heading(company) -> angle;
        trial_speed(company) -> speed;

        ;;; Don't always copy neighbour
        if random(100) > 25 then speed - 1 -> speed; endif;

        ;;; Set the speed of movement based on the separation of the two sheep
        round(dist / 10) -> dist;

        ;;; Calculate the weighting to associate with this action
        zone_weighting(dist) -> weight;
    ]
    [Flock_impulse [?weight ?speed ?angle] ??imp_list]
    [SAYIF imitate ?my_name 'is imitating' [$$sim_name(company)]
                  'at speed' ?speed]

    RULE limit3
    ;;; Urgency will affect thinking time during NEXT time slice
    [NEWLIMIT ?setting]
    [Urgency ?value]
    [WHERE value < setting]
    ==>
    [DEL 1]
    [NEWLIMIT ?value]

    RULE flipper3
    ;;; Switch to next social rule
    ==>
    [RESTORERULESET avoidance]

enddefine;

define :ruleset trial_resolve_behaviour_rules;
    ;;; These rules resolve any conflicting behavioural impulses

    ;;; First deal with interaction between social and biological level

    RULE resolve_flocking_and_fleeing
    ;;; If fleeing impulse is weak it can be overridden otherwise
    ;;; the two impulses are combined
    [Flock_impulse ??flocking]
    [Flee_impulse ??fleeing]
    [NOT Wander]
    ==>
    [DEL 1 2]
    [POP11
        lvars flock_sumx, flock_sumy, flock_sumw,
              flee_sumx, flee_sumy, flee_sumw,
              speed, bearing, aimx, aimy;

        ;;; Convert impulses into cartesian coordinates combined with weighting
        weighted_sum(flocking) -> (flock_sumx, flock_sumy, flock_sumw);
        weighted_sum(fleeing) -> (flee_sumx, flee_sumy, flee_sumw);

        if flee_sumw < 3 and flock_sumw > flee_sumw then
            ;;; Take only the flocking impulse into account
            flock_sumx / flock_sumw -> aimx;
            flock_sumy / flock_sumw -> aimy;
        elseif flee_sumw > 0 or flock_sumw > 0 then
            ;;; Take both flocking and fleeing impulses into account
            (flock_sumx + flee_sumx ) / (flock_sumw + flee_sumw) -> aimx;
            (flock_sumy + flee_sumy ) / (flock_sumw + flee_sumw) -> aimy;
        else
            ;;; If there are no impulses then move a small random amount
            ;;; with a low probability
            if random(100) < 3 then
                random(2.0) - 1.0, random(2.0) - 1.0
            else
                0,0
            endif -> (aimx, aimy);
        endif;

        ;;; If needed then calculate new bearing otherwise use current heading.
        if aimx /= 0 or aimy /= 0 then
            round( sim_heading_from(0, 0, aimx, aimy) ) -> bearing;
        else
            trial_heading(sim_myself) -> bearing;
        endif;

        ;;; Set speed
        round( sim_distance_from(0, 0, aimx, aimy) ) -> speed;

        ;;; Add the intended move into database
        prb_add_to_db( [Intent ^speed ^bearing], sim_data(sim_myself) );
    ]

    RULE resolve_movement_and_eating
    ;;; Since sheep cannot move and eat at the same time one of
	;;; these behaviours must dominate
    [Intent ?speed ?bearing]
    [Hunger ?hunger]
    ==>
    [DEL 1 2]
    [POP11
        ;;; Combare movement and eating intensities
        if speed < hunger then
            ;;; Stop and eat
            prb_add_to_db( [Intent Eat], sim_data(sim_myself) );
        else
            ;;; Subsume eating behaviour
            prb_add_to_db( [Intent ^speed ^bearing], sim_data(sim_myself) );
        endif;
    ]

    RULE resolve_movement_and_idling
    ;;; Since sheep cannot move and do nothing at the same time it will move
    [Intent ?speed ?bearing]
    [Idle]
    ==>
    [DEL 2]

    ;;; Don't have to worry about comparing wandering impulses with any
    ;;; social impulses because the sheep won't wander if there are any
    ;;; other sheep around

    ;;; Now deal with conflicts between resultant movement impulses and
    ;;; any physical contraints imposed on the sheep.

    RULE resolve_movement_and_constraints
    ;;; Obstacles in environment can impose constraints on the movement of the
    ;;; sheep.  These constraints are NOT always observed!

    [O_list ?list]
    [Intent ?speed ?bearing]
    [Fatigue ?tiredness]
    ==>
    [DEL 1 2]
    [LVARS range]
    [POP11
        lvars offset, new_bearing;

        ;;; Ensure there are obstacles which are currently visible
        if list /= [] then
            ;;; Find the range of headings which are oscured by the obstacles ahead
            get_range( bearing, list) -> range;

            ;;; Only proceed if there are obstacles directly ahead
            if range then
                ;;; See how much to turn clockwise to avoid obstacles
                bearing - front(range) -> offset;
                if offset < 0 then
                    offset + 360 -> offset;
                endif;

                ;;; See if it's quicker to turn anti-clockwise
                if back(range) - offset < offset then
                    back(range) - offset -> offset;
                    ( front(range) + back(range) ) mod 360 -> new_bearing;
                else
                    front(range) -> new_bearing;
                endif;

                ;;; Compare the amount needed to turn with the required speed.
                ;;; Speed is an indication of urgency, so only turn if there is
                ;;; time.
                ;;; It will always be possible to make small adjustments to
                ;;; heading but, for example, if trapped the sheep may be
                ;;; unwilling to turn around toward an enemy.
                if offset / 30.0 < 10 - speed then
                    new_bearing -> bearing;
                endif;
            endif;
        endif;

        ;;; Fatigue can also constrain movement.
        if random(100) < tiredness and speed /== 0 then
            speed - 1 -> speed;
        endif;

        ;;; The resulting behaviour after contraints is added to database
        if speed == 0 then
            prb_add_to_db( [Idle], sim_data(sim_myself) );
        else
            prb_add_to_db( [Intent ^speed ^bearing], sim_data(sim_myself) );
        endif;
        ]

enddefine;

define :ruleset trial_action_rules;

    RULE default_wander_action
    [Wander]
    ==>
    [DEL 1]
    ;;; [POP11 wander(sim_myself); ]
	[do wander]
    [SAYIF report ?my_name 'decided to wander about']

    RULE default_idle_action
    [Idle]
    ==>
    [DEL 1]
    [POP11
        resting(sim_myself);
    ]
    [SAYIF report ?my_name 'decided to do nothing']

    RULE eat_action
    [Intent Eat]
    ==>
    [DEL 1]
    [POP11
        sheep_graze(sim_myself);
    ]
    [SAYIF report ?my_name 'decided to eat']

    RULE positive_action
    [Intent ?speed ?bearing]
    ==>
    [DEL 1]
    [POP11
        move( sim_myself, bearing, speed );
    ]
    [SAYIF report ?my_name 'decided to head' ?bearing 'at speed' ?speed]

enddefine;


define :rulefamily trial_social_rules;
    debug = true;

    ruleset: avoidance
    ruleset: center
    ruleset: imitate
enddefine;

/*
-- . Rulesystems for dog and sheep
*/


define :rulesystem trial_dog_rulesystem;
    debug = false;
    cycle_limit = 1;

    include: dog_movement_rules
enddefine;


define :rulesystem trial_sheep_rulesystem;
    [DLOCAL
        [prb_allrules = true ]];
    [LVARS
        my_name];
    debug = false;
    cycle_limit = 1;

    include: trial_perception_rules
    include: trial_obstacle_rules
    include: trial_instinct_rules
    include: trial_social_rules with_limit = 3;
    include: trial_resolve_behaviour_rules
    include: trial_action_rules
enddefine;



/*
-- Defining the objects (instances of the classes)
*/

;;; Create the sheep, sheep dogs, trees and posts

;;; First the sheep
define :instance sheepy:trial_sheep;
    trial_hunger = 0;
    rc_pic_strings = [[FONT '6x13' {0 0 'a'}]];
enddefine;

define :instance sleepy:trial_sheep;
    trial_hunger = 0;
    rc_pic_strings = [[FONT '6x13'{0 0 'b'}]];
enddefine;

define :instance sneezy:trial_sheep;
    rc_pic_strings = [[FONT '6x13' {0 0 'c'}]];
enddefine;

define :instance bashful:trial_sheep;
    rc_pic_strings = [[FONT '6x13' {0 0 'd'}]];
enddefine;

define :instance doc:trial_sheep;
    rc_pic_strings = [[FONT '6x13' {0 0 'e'}]];
    trial_hunger = 0;
enddefine;

;;; Now the sheep dog
define :instance gromit:trial_dog;
enddefine;

;;; Now the trees
define :instance tree1:trial_tree;
enddefine;

define :instance tree2:trial_tree;
enddefine;

;;; Now the fence posts
define :instance post1:trial_post;
enddefine;

define :instance post2:trial_post;
enddefine;

define :instance post3:trial_post;
enddefine;

define :instance post4:trial_post;
enddefine;

define :instance post5:trial_post;
enddefine;

define :instance post6:trial_post;
enddefine;

define :instance post7:trial_post;
enddefine;

define :instance post8:trial_post;
enddefine;

define :instance post9:trial_post;
enddefine;

define :instance post10:trial_post;
enddefine;

;;; Collect all participating agents into a list of names of the
;;; agents, later replaced by the class instances, inside procedure sheep_setup

[
 ;;; the sheep
 sheepy sleepy sneezy bashful doc

 ;;; The dog
 gromit

 ;;; The trees
 tree1 tree2

 ;;; Now posts making up the pen
 post1 post2 post3 post4 post5 post6
 post7 post8 post9 post10

] -> sheep_agents;



/*
-- Procedurs for setting up and running the demo
*/

;;; Prepare everything for running

global vars sheep_setup_done = false;

define sheep_setup();
    ;;; Create the window and the agents and obstacles, and show them in the
    ;;; window.

    ;;; Destroy previous window if necessary
    if isrc_window_object(sheep_win) then
        rc_kill_window_object(sheep_win);
        false -> sheep_win;
    endif;

    ;;; create new one
    rc_new_window_object(
        sheep_window_x, sheep_window_y,   ;;; top left hand corner
        sheep_window_xsize, sheep_window_ysize, true, 'Sheep') -> sheep_win;

    ;;; Make the window mouse sensitive
    rc_mousepic(sheep_win);

    ;;; Give sheep_min the right handlers.
    {sheep_button_1_down  ^false ^false}
        -> rc_button_down_handlers(sheep_win);

    {sheep_button_1_up ^false sheep_button_3_up};
        -> rc_button_up_handlers(sheep_win);

    {sheep_button_1_drag ^false ^false };
        -> rc_drag_handlers(sheep_win);

    ;;; create the agents
    maplist(sheep_agents,
        procedure(word) -> a;

            if isword(word) then
                valof(word) -> a;

                ;;; give the agent its name
                word -> sim_name(a);
            else
                ;;; Agents previously created
                word -> a;
                sim_name(a) -> word;

            endif;

            ;;; tell the window about it
            rc_add_pic_to_window(a, sheep_win, true);

        endprocedure) -> sheep_agents;

    ;;; Define the starting positions and headings for each agent

	;;; first the sheep
    set_status( sheepy, random(5), 25+random(5), random(360));
    set_status( sleepy, 20+random(5), -30+random(5), random(360));
    set_status( sneezy, 40+random(5), -60+random(5), random(360));
    set_status( bashful, -115+random(5), -70+random(5), random(360));
    set_status( doc, -135+random(5), -30+random(5), random(360));

	;;; then the dog
    set_status( gromit, 160, 0, 0);

	;;; the posts
    set_status( post1, -100, 100, 0);
    set_status( post2, -100, 130, 0);
    set_status( post3, -100, 160, 0);
    set_status( post4, -100, 190, 0);
    set_status( post5, -130, 190, 0);
    set_status( post6, -160, 190, 0);
    set_status( post7, -190, 190, 0);
    set_status( post8, -190, 160, 0);
    set_status( post9, -190, 130, 0);
    set_status( post10, -190, 100, 0);

	;;; the tree
    set_status( tree1, -70, -150, 0);
    set_status( tree2, 130, 160, 0);

	true -> sheep_setup_done;
enddefine;

define run_sheep(n);
    dlocal
        demo_running = true,
        sheep_stopped = false,
        ;
	unless sheep_setup_done then
		sheep_setup();
		printf('\nUse the mouse to rearrange the sheep, trees,');
		printf('\nthe pen and the dog,');
		printf('\nthen press RETURN to start the demo.');
		printf('\nPress button 3 in the window to stop.\n');
		readline() ->;
	endunless;	
	
    applist(sheep_agents, sim_setup);
    sim_scheduler(sheep_agents, n);
enddefine;

;;; By default there is no trace output
global vars prb_sayif_trace = [];


/*
;;; These items could now be managed via LIB SIM_HARNESS
;;; See HELP SIM_HARNESS

;;; This area allows different tracing parameters to be set manually
;;; This is not automatically run when the file is loaded
global vars prb_sayif_trace = [perception
                               eat fear wander contented
                               avoid imitate center
                               report];
global vars prb_sayif_trace = [perception];
global vars prb_sayif_trace = [eat fear wander contented];
global vars prb_sayif_trace = [avoid imitate center];
global vars prb_sayif_trace = [report];

false ->> prb_walk ->> prb_chatty ->> prb_show_conditions ->> pop_debugging
      ->> prb_show_ruleset ->> prb_pausing ->> demo_trace ->> demo_cycle_trace
      -> popgctrace;
false -> prb_tracing_on;
true  ->> popgctrace ->> prb_chatty ->> prb_show_conditions ->> pop_debugging
      ->> prb_show_ruleset ->> prb_pausing ->> demo_trace ->> demo_cycle_trace;
true  -> prb_walk;
false -> prb_walk;
*/

/*
;;; These are the two routines needed to run the demonstration

;;; Run this to set up environment
sheep_setup();    ;;; defined above

;;; Run this to start program execution
run_sheep(2000);
*/

/*
-- Instructions to be printed out
*/

printf('\nTo setup or restart the sheep window type\n\tsetup();\n');
printf('\nThen use mouse button 1 to rearrange items on the field\n');
printf('\nTo run for 2000 time steps do the following:');
printf('\nand use mouse button 3 to STOP\n\t run_sheep(2000);\n');

/*
-- Index of classes, methods, procedures, rulesets, etc.

CONTENTS - (Use <ENTER> gg to access required sections)

 define :class trial_agent;
 define :class trial_sheep; is trial_agent;
 define :class trial_dog;
 define :class trial_obstacle;
 define :class trial_tree;
 define :class trial_post;
 define :method sim_agent_running_trace(object:trial_agent);
 define :method sim_agent_messages_out_trace(agent:trial_agent);
 define :method sim_agent_messages_in_trace(agent:trial_agent);
 define :method sim_agent_actions_out_trace(object:trial_agent);
 define :method sim_agent_rulefamily_trace(object:trial_agent, rulefamily);
 define :method sim_agent_endrun_trace(object:trial_agent);
 define :method sim_agent_terminated_trace(object:trial_agent, number_run, runs, max_cycles);
 define vars procedure sim_scheduler_pausing_trace(objects, cycle);
 define vars procedure sim_post_cycle_actions(objects, cycle);
 define trial_coords(t) /* -> (x, y)*/;
 define :method sim_distance(a1:trial_agent, a2:trial_agent) ;
 define :method agent_bearing( agent:trial_agent, target:trial_agent) -> result;
 define weighted_sum(components) -> (sumx, sumy, sumw);
 define :method collision_course(bearing, arc) -> result;
 define check_range( pair1, pair2, diff) -> result;
 define compare_ranges( base, test ) -> (result,altered);
 define obscured_ranges(range_list ) -> result;
 define get_range( heading, choice_list) -> result;
 define :method print_instance(item:trial_sheep);
 define :method print_instance(item:trial_dog);
 define :method print_instance(item:trial_obstacle);
 define :method resting(agent:trial_sheep);
 define :method sheep_graze(agent:trial_sheep);
 define :method exercise( agent:trial_sheep);
 define :method forward(agent:trial_agent, speed);
 define :method set_heading(agent:trial_agent, heading);
 define :method set_status(agent:trial_agent, x, y, heading);
 define :method move( agent:trial_sheep, bearing, speed );
 define :method wander(agent:trial_sheep);
 define :method sim_sense_agent(a1:sim_object, a2:sim_object, dist);
 define :method sim_run_agent(agent:trial_sheep, agents);
 define :method sheep_button_1_up(pic:rc_window_object, x, y, modifiers);
 define :method sheep_button_1_down(pic:rc_window_object, x, y, modifiers);
 define :method sheep_button_3_up(pic:rc_window_object, x, y, modifiers);
 define :method sheep_button_1_drag(pic:rc_window_object, x, y, modifiers);
 define :method rc_button_1_down(pic:trial_agent, x, y, modifiers);
 define :method rc_button_1_up(pic:rc_selectable, x, y, modifiers);
 define :method rc_button_1_drag(pic:trial_agent, x, y, modifiers);
 define :ruleset dog_movement_rules;
 define :ruleset trial_perception_rules;
 define :ruleset trial_obstacle_rules;
 define :ruleset trial_instinct_rules;
 define :ruleset avoidance;
 define :ruleset center;
 define :ruleset imitate;
 define :ruleset trial_resolve_behaviour_rules;
 define :ruleset trial_action_rules;
 define :rulefamily trial_social_rules;
 define :rulesystem trial_dog_rulesystem;
 define :rulesystem trial_sheep_rulesystem;
 define :instance sheepy:trial_sheep;
 define :instance sleepy:trial_sheep;
 define :instance sneezy:trial_sheep;
 define :instance bashful:trial_sheep;
 define :instance doc:trial_sheep;
 define :instance gromit:trial_dog;
 define :instance tree1:trial_tree;
 define :instance tree2:trial_tree;
 define :instance post1:trial_post;
 define :instance post2:trial_post;
 define :instance post3:trial_post;
 define :instance post4:trial_post;
 define :instance post5:trial_post;
 define :instance post6:trial_post;
 define :instance post7:trial_post;
 define :instance post8:trial_post;
 define :instance post9:trial_post;
 define :instance post10:trial_post;
 define sheep_setup();
 define run_sheep(n);

*/

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Mar 14 1999
	Replaced SWI*TCHRULESET with RESTORERULESET
	Introduced the variable sheep_setup_done and if its value is
	false made the procedure run_sheep invoke sheep_setup.
	Slightly altered instructions printed out.
	Removed set_*location
--- Aaron Sloman, Jan 23 1999
    Made all objects mouse sensitive, so that they can be moved
    after sheep_setup(); When run_sheep is running only dog is sensitive to
    the mouse, when button 1 is clicked or when the mouse is dragged.
    Button 3 can be used to stop a run.
    The REDO key will re start.
    The sheep now move slightly at random when there's no specific
    motive for moving.
    Introduced new headings and table of contents, and slightly modified
    the instructions.
--- Aaron Sloman, Mar 21 1997
    Had to add a call to rc_setup_linefunction()
--- Aaron Sloman, Mar 20 1997
    Made a number of revisions to make this work with the latest
    rclib. Also slightly randomised initial situation produced by
    sheep_setup, and added the procedure run_sheep.
 */
