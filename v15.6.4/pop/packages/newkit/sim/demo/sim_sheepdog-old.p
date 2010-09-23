/* --- Copyright University of Birmingham 2003. All rights reserved. ------
 > File:            $poplocal/local/newkit/sim/demo/sim_sheepdog.p
 > Linked to        $poplocal/local/newkit/sim/teach/sim_sheepdog.p
 > Purpose:			Demonstrate sim_agent toolkit with sheepdog scenario
 > Author:          Various: see below (see revisions)
 > Documentation: 	See below
 > Related Files:   TEACH sim_agent, HELP sim_agent, TEACH sim_feelings
 */

/*
TEACH SIM_SHEEPDOG.P                           Tom Carter et al. Sept 1999
*/
/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/newkit/sim/demo/sim_sheepdog.p
        			Linked to TEACH sim_sheepdog.p
 > Purpose:         Sheepdog demo No 2
 > Authors:
                    Peter Waudby, Sep 13 1996 (see revisions)
                        Main Author of TEACH SIM_SHEEP.P
						(sheepdog is mouse-driven)
                        Updated by Aaron Sloman Jan 1999, July 2000
                    Tom Carter Sep 2 1999
                        Extended to give sheepdog the ability to pen the sheep
                        unaided
  Documentation:   http://www.cs.bham.ac.uk/~axs/cog_affect/sim_agent.html
            Tom Carter's Cognitive Science MSc thesis,
            Cognitive Science Research Centre, The University of Birmingham
  Related Files:   TEACH sim_sheep.p  TEACH sim_feelings

*/

/*

         CONTENTS - (Use <ENTER> g to access required sections)

 -- Introduction and acknowledgement
 -- Running the demo
 -- More detailed overview
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
 -- . Rulesets for the dog
 -- . . Behaviour rulesets for rulefamily dog_activity_rulecluster
 -- . Rulesets and rulefamily for sheep
 -- . Rulesystems for dog and sheep
 -- Defining the objects (instances of the classes)
 -- Procedurs for setting up and running the demo
 -- Instructions to be printed out
 -- Index of classes, methods, procedures, rulesets, etc.

-- Introduction and acknowledgement

This file is Tom Carter's 1999 MSc summer project. It is based upon a
previous summer project by Peter Waudby, which had subsequently been
updated by Aaron Sloman. Much of this original code remains, but the
extensions have been marked by the initials TC.

Peter Waudby's original version was developed while the Sim_agent
toolkit and the graphical RCLIB toolkit were still in fairly early
stages of development. So some of this should now be reimplemented
using the current toolkit facilities.

-- Running the demo

To run the initial file type <ENTER> l1 <RETURN>

Instructions will be printed.

then <ESC> D on the line

	run_sheep(2000)


-- More detailed overview

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

The dog is the square object with a triangular "nose". It will sequentially
herd the sheep into the pen of its own accord.

The sheep become sensitive to the dog only when it gets within a certain
distance, at which point they try to move away from it. The two large
circles are trees. The "pen" is made of a collection of smaller circles.

To get rid of the window, either exit pop11, or do

    rc_kill_window_object(sheep_win);

========================
Tom Carter 2 Sept 1999 adapted from...
Aaron Sloman  20 Mar 1997 (Updated 23 Jan 1999 )
Further Modified by Aaron Sloman: July 2000

*/

/*
-- Load libraries required
*/

uses objectclass
uses newkit
uses poprulebase
uses sim_agent;
uses rclib
uses rc_linepic;
uses rc_mousepic;
uses rc_window_object;
uses rc_control_panel;
uses sim_geom;


;;; Increase popmemlim to reduce garbage collection time.
;;; Experiment with the number. See HELP POPMEMLIM
;;; The number is in machine words. Multiply by 4 or 8 to get bytes
max(popmemlim, 2000000) -> popmemlim;

/*
-- Global variables
*/

global vars

    ;;; Window parameters
    ;;; location of demo window
    sheep_window_x = "right",
    sheep_window_y = "top",

    ;;; Width and height of window
    ;;;     (Reduce these if you hae a low resolution screen)
    sheep_window_xsize = 750,
    sheep_window_ysize = 750,

    ;;; In case recompiling, get rid of old agents. Prepare global list.
    all_agents = [],

    ;;; Set the maximum visual range of the sheep and dog

    sheep_visual_range = 160,
    dog_visual_range = 160,

    ;;; A global array to contain precalculated values used to determine
    ;;; how a perceived object's importance varies with distance.
    ;;; Importance associated with an object decreases exponentially
    ;;; with distance. (Peter Waudby)

    procedure zone_weighting =
        newarray([1 8], procedure(x); round(100*2**(-x+1)) endprocedure),

    ;;; Size of selectable box in mouse-movable objects (40x40 square)
    ;;; default value for rc_mouse_limit
    rc_select_distance = {-15 -15 15 15},

    ;;; Made true by mouse button 3
    sheep_stopped = false,

    gromit,
    rover,          ;;; The Dog defined below;
    sheep_win,      ;;; The window (instance of rc_window_object)
	sheep_control_panel,

    ;;; If this variable is given a number > 0 that will slow
    ;;; down the running of the program.
	sim_sheep_delay = 1,

	;;; default speed for traversing long distances.

	dog_default_speed = 15,
    ;

;;; set to 0 for maxmim speed. Increase to slow demo down

global vars	sim_agentsleep = 0;

;;; rulesystems defined below.
global vars
    trial_sheep_rulesystem,
    trial_dog_rulesystem,
    pen, post1, post4;

/*
-- Class definitions
*/

define :class trial_agent;
    is rc_rotatable_picsonly	;;; Don't rotate strings
	   rc_linepic_movable sim_agent;
    ;;; The base class for all agents in the trial

    slot trial_heading == 0;        ;;; Which was the agent is pointing
    slot trial_size == 10;          ;;; The agent's physical size
    slot rc_picx == 0;              ;;; The x and y coordinates of the agent
    slot rc_picy == 0;              ;;; within the environment and picture
    slot sim_sensors = [];          ;;; List of which senses the agent has

    ;;; a vector defining a box for mouse sensitivity
    slot rc_mouse_limit = rc_select_distance;
enddefine;





define :class trial_sheep; is trial_agent rc_selectable ;
    ;;; The class defining the sheep's attributes

    ;;; Maybe some of these should be randomised?
    slot trial_hunger == 1;         ;;; Between 0 (stuffed) and 3 (starving)
    slot trial_fatigue == 20;       ;;; Between 0 (fresh) and 100 (knackered)
    slot trial_speed == 0;          ;;; Speed = distance travelled per move
    slot trial_pspace == 30;        ;;; Limit of sheep's personal space
    slot trial_pack_range == 60;    ;;; Max satisfactory distance from other sheep
    slot trial_flock_range == 100;  ;;; Max range whilst remaining in flock
    slot trial_obstacle_range == 40; ;;; Distance when obstacles are first noticed


    slot rc_pic_lines ==            ;;; What the sheep looks like
          [
            WIDTH 3
            [CIRCLE {0 0 10}]       ;;; Round body
            [CIRCLE {13 0 5}]       ;;; Round head
          ];

    slot sim_rulesystem = trial_sheep_rulesystem;   ;;; Which rules to follow
    slot sim_sensors = [{sim_sense_agent ^sheep_visual_range}]; ;;; Defines senses

	;;; make sheep a bit harder to move
    slot rc_mouse_limit = rc_select_distance;
enddefine;

define :class trial_dog;

    ;;; EXTENDED BY Tom Carter...
    ;;; The class which defines the sheepdog's attributes

    is trial_agent rc_selectable ;
    slot trial_speed == 0;          ;;; Speed = distance travelled per move
    slot rc_pic_lines ==            ;;; What the dog look like
          [
            WIDTH 3
            [CLOSED {-10 10}  {10 10} {10 -10}  {-10 -10}]   ;;; Square body
            [CLOSED {8 8}  {8 -8} {17 0}]                ;;; Triangular head
          ];
    slot sim_rulesystem = trial_dog_rulesystem;     ;;; Which rules to follow
    slot sim_sensors = [{sim_sense_agent ^dog_visual_range}]; ;;; Defines senses
    slot trial_list == [];
    slot trial_current == [];
    slot trial_goal == [];
    slot trial_leftpost == [];
    slot trial_rightpost == [];
    slot trial_postlist == [];
    slot trial_sector = [];
    slot trial_side = [];
    slot trial_sheepside = [];
    slot trial_in_pen = false;
    slot trial_deshead = false;
    slot trial_problempost = false;
    slot trial_problemtree = false;
    slot trial_personalspace = 30;
    slot trial_behav = [];
    slot trial_trees = [];

enddefine;

define :class trial_obstacle;
    ;;; All obstacles should be circular if obstacle avoidance is to work
    is trial_agent;

    slot rc_pic_lines ==            ;;; What the obstacle looks like
          [
            WIDTH 3
            [CIRCLE {0 0 10}]       ;;; Circle with radius = trial_size
          ];
enddefine;

define :class trial_tree;
    is trial_obstacle rc_selectable ;
    ;;; Trees are larger than the sheep
    slot trial_size == 15;          ;;; Size is larger than default

    slot rc_pic_lines ==
          [
            WIDTH 3 COLOUR 'green'
            [CIRCLE {0 0 15}]       ;;; Change graphics accordingly
          ];
enddefine;

define :class trial_post;
    is trial_obstacle;

    ;;; Posts are smaller than the sheep
    slot trial_size == 9;           ;;; Size is smaller than default
    slot rc_pic_lines ==
          [
            WIDTH 3 COLOUR 'blue'
            [CIRCLE {0 0 9}]        ;;; Change graphics accordingly
          ];
enddefine;


/*
CLASS    : trial_target
CREATED  : 26 Jul 1999, TC
PURPOSE  : used by the dog in order to help it guide the sheep into
           the pen, as a positional device

*/

define :class trial_target;
    is trial_obstacle;

    slot rc_pic_lines == [];

enddefine;


define :class trial_pen;

    slot size = 0;
    slot locx = 0;
    slot locy = 0;
    slot orientation = 0;
	slot rc_pic_lines = [];

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

define :method sim_agent_rulefamily_trace(object:trial_dog, rulefamily);
enddefine;

define :method sim_agent_endrun_trace(object:trial_agent);

	if sim_agentsleep /== 0 and random(10) < 5 then
		syssleep(sim_agentsleep);
	endif;

enddefine;

define :method sim_agent_terminated_trace(object:trial_agent, number_run, runs, max_cycles);
enddefine;

define vars procedure sim_scheduler_pausing_trace(objects, cycle);
    ;;; user definable
	if cycle mod 10 == 0 then
    	;;; Uncomment next line to get cycle numbers printed out
    	pr('\n=== end of cycle ' >< cycle >< '===\n');
    	 ;;; readline()->;
	endif;

enddefine;

;;; The next procedure is run by sim_scheduler at the end of each
;;; time slice

define vars procedure sim_post_cycle_actions(objects, cycle);
    ;;; The variable sheep_stopped is made true by using mouse button 3
    if sheep_stopped then
        ;;; printf('\nSTOPPED by user.');
        vedputcommand(':run_sheep(20000)');
		'Press REDO to restart'=>
        exitfrom(sim_scheduler);
    endif;
	if sim_sheep_delay >= 0 then
		syssleep(sim_sheep_delay)
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


define agent_now_at(agent, xloc, yloc) -> boole;
	lvars (x,y) = trial_coords(agent);
	xloc = x and yloc = y -> boole;
enddefine;

define approach_speed(dist) -> newspeed;
	;;; Added by A.S. 19 Jul 2000
	;;; Speed at which dog should approach sheep
	;;; reduce speed when getting close.
	if dist > 70 then dog_default_speed else round(dist/8.0) endif -> newspeed;
enddefine;


/*
METHOD   : set_coords (pen, x, y)
INPUTS   : pen, x, y
  Where  :
    pen is a pen
    x is a coordinate
    y is a coordinate
OUTPUTS  : NONE
USED IN  : ???
CREATED  : 26 Jul 1999 TC
PURPOSE  : sets the coordinates of the pen. Since the pen is now always p
           placed at (0,0) this isn't stricly needed any more, but comes in useful
           if one wants to randomly place the pen. See section in the report about
           how i have set up the sheep world.


*/

define :method set_coords(pen:trial_pen, x, y);

x -> pen.locx;
y -> pen.locy;

enddefine;

;;; set_coords(pen, 3, 4);


/*
PROCEDURE: rotate_by (ang, oldx, oldy) -> (newx, newy)
INPUTS   : ang, oldx, oldy
  Where  :
    ang is a angle
    oldx is a coordinate
    oldy is a coordinate
OUTPUTS  : newx, newy
  Where  :
    newx is a coord
    newy is a coord
USED IN  : ???
CREATED  : 26 Jul 1999 provided, I think by Aaron Sloman
PURPOSE  : Given the old coordinates, it rotates them by the angle given,
           around the origin. This is used to rotate the pen, where the
           old coordinates are relative to, and then rotated around the
           centre of the pen, which is used as the origin.

TESTS:
rotate_by (90, 1, 1) -> (x, y)
[^x  ^y] ==>;
** [-1.0 1.0]
*/

define rotate_by(ang,oldx,oldy) -> (newx,newy);

    dlocal popradians = false;

    lvars
        rc_rotate_cos = cos(ang),
        rc_rotate_sin = sin(ang);

    oldx * rc_rotate_cos - oldy * rc_rotate_sin ->newx;
    oldx * rc_rotate_sin + oldy * rc_rotate_cos ->newy;

enddefine;


define :method set_heading(agent:trial_agent, heading);

    ;;; Provided by PW
    ;;; Allows an agent's heading to be specified explicitly

    ;;; Set the heading of the sheep
    heading -> trial_heading(agent);

    ;;; Set the graphical orientation of the sheep
    rc_set_axis(agent, heading, true);
enddefine;

define :method set_status(agent:trial_agent, x, y, heading);

    ;;; Provided by AS
    ;;; Allows an agent's location and heading to be specified explicitly
    ;;; after creation

    ;;; first move the agent right off the picture
    rc_move_to(agent, -10000, -1000, true);

    ;;; Now set the heading and move the agent back
    set_heading(agent, heading);
    rc_move_to(agent, x, y, true);
enddefine;


/*
PROCEDURE: set_random_status (obj, x, y)
INPUTS   : obj, x, y
  Where  :
    obj is an agent
    x is a coord
    y is a coord
OUTPUTS  : NONE
USED IN  : ???
CREATED  : 26 Jul 1999 TC
PURPOSE  : Used to set up the sheep world in such a way,
           that given a distance from the centre (pen) <ie a set of coords>
           the object is randomly rotated around that centre. This is used
           so that the world has a random element when it is started.

TESTS:

set_random_status(gromit, 0, 400)
trial_coords(gromit)->(x,y)
[^x ^y]==>
** [-103.528 -386.37]
*/

define set_random_status(obj, x,y);

    lvars newx, newy;

	if member(obj, all_agents) then

	    rotate_by(random(360), x, y) -> (newx, newy);

	    set_status(obj, newx, newy, 0);
	endif;

enddefine;

/*
METHOD   : set_rel_status (pen, post, addx, addy)
INPUTS   : pen, post, addx, addy
  Where  :
    pen is the pen
    post is a post
    addx is a the relative position on the x - axis of the post from the pen
    addy is a the relative position on the y - axis of the post from the pen ???
OUTPUTS  : NONE
USED IN  : ???
CREATED  : 28 Jul 1999 TC
PURPOSE  : used in setting the pen to a random 'rotation'. The relative
           coordinates addx and addy are worked out previously and then the
           post is put in this relative position.
TESTS:
set_rel_status(pen, post1, 30, 0)
pen.locx =>
** 0
pen.locy =>
** 0
pen.orientation=>
** 264
trial_coords(post1)=>
** -3.13585 -29.8357
set_rel_status(pen, post1, 50, 0)
trial_coords(post1)=>
** -5.22642 -49.7261
 -5.22642* (30/50) =>
** -3.13585
*/

define :method set_rel_status(pen:trial_pen, post, addx, addy);

    lvars actx, acty;
    rotate_by(pen.orientation, addx, addy)->(actx, acty);
    set_status(post, pen.locx+actx, pen.locy+acty, 0);

enddefine;



/*
METHOD   : setup_pen (pen)
INPUTS   : pen is a pen
OUTPUTS  : NONE
USED IN  : ???
CREATED  : 28 Jul 1999 TC
PURPOSE  : used to set up the pen...

TESTS:

*/

define :method setup_pen(pen:trial_pen);

	;;;pen.locx ==>;
	;;;pen.locy ==>;

	;;;first create instances of all the posts,
	;;; -- and 2 targets

	define :instance post1:trial_post;
		rc_pic_strings = [FONT '6x13' {-3 -3 '1'}];
	enddefine;

	define :instance post2:trial_post;
		rc_pic_strings = [FONT '6x13' {-3 -3 '2'}];
	enddefine;

	define :instance post3:trial_post;
		rc_pic_strings = [FONT '6x13' {-3 -3 '3'}];
	enddefine;

	define :instance post4:trial_post;
		rc_pic_strings = [FONT '6x13' {-3 -3 '4'}];
	enddefine;

	define :instance post5:trial_post;
		rc_pic_strings = [FONT '6x13' {-3 -3 '5'}];
	enddefine;

	define :instance post6:trial_post;
		rc_pic_strings = [FONT '6x13' {-3 -3 '6'}];
	enddefine;

	define :instance post7:trial_post;
		rc_pic_strings = [FONT '6x13' {-3 -3 '7'}];
	enddefine;

	define :instance post8:trial_post;
		rc_pic_strings = [FONT '6x13' {-3 -3 '8'}];
	enddefine;

	define :instance post9:trial_post;
		rc_pic_strings = [FONT '6x13' {-3 -3 '9'}];
	enddefine;

	define :instance post10:trial_post;
		rc_pic_strings = [FONT '6x13' {-5 -3 '10'}];
	enddefine;

	define :instance target:trial_target;
	enddefine;

	define :instance target2:trial_target;
	enddefine;

	;;; Then set the position of the posts and targets, relative to the
	;;; position and orientation of the "pen".

	set_rel_status(pen, post1, 45, -45);

	set_rel_status(pen, post2, 45, -15);
	set_rel_status(pen, post3, 45, 15);
	set_rel_status(pen, post4, 45, 45);
	set_rel_status(pen, post5, 15, 45);

	set_rel_status(pen, post6, -15, 45);
	set_rel_status(pen, post7, -45, 45);
	set_rel_status(pen, post8, -45, 15);
	set_rel_status(pen, post9, -45, -15);
	set_rel_status(pen, post10, -45, -45);
	set_rel_status( pen, target, pen.locx, pen.locy);
	set_rel_status( pen, target2, pen.locx, pen.locy+45);

enddefine;




/*
METHOD   : make_post_list (agent, objects) -> list
INPUTS   : agent, objects
  Where  :
    agent is a dog
    objects is a list of all objects in the world (E-semantics)
OUTPUTS  : list
	a list of the posts
USED IN  : variousfind_new_sheep
CREATED  : 28 Jul 1999
PURPOSE  : Used by the dog, when  it is sorting all the objects in the world
           into different types. This enables it to efficiently search for
           the posts in the world


TESTS:

make_post_list(gromit, all_agents) =>
** {[<agent post1 at (-5 -50) heading 8>
     <agent post2 at (-20 -43) heading 8>
     <agent post3 at (10 -46) heading 8>
     <agent post4 at (40 -49) heading 8>
     <agent post5 at (43 -20) heading 8>
     <agent post6 at (46 10) heading 8> <agent post7 at (49 40) heading
    8>
     <agent post8 at (20 43) heading 8>
     <agent post9 at (-10 46) heading 8>
     <agent post10 at (-40 49) heading 8>]}

*/

define :method make_post_list(agent:trial_dog, objects) -> list;
    ;;; used by the dog to get a list of all the posts in the world.

    lvars x;
	[%
    for x in objects do
         if istrial_post(x) then x endif;
    endfor %] -> list;

enddefine;

/*
TESTS
make_tree_list(gromit, all_agents)
gromit.trial_trees=>
** [<agent tree1 at (-264 56) heading 15> <agent tree2 at (-81 -236) heading
    15>]
*/


define :method make_tree_list(agent:trial_dog, objects) -> list;
    ;;; used by the dog to get a list of all the trees in the world.

    lvars x;
    [%for x in objects do
         if istrial_tree(x) then x endif;
    endfor%] -> list

enddefine;


;;; removed arctan_rev, A.S. 16 Jul 2000

/*
PROCEDURE: sim_direction (x1, y1, x2, y2) -> heading
INPUTS   : x1, y1, x2, y2
  Where  :
    x1,y1 are the coordinates of one object
    x2, y2 are the coordinates of another one
OUTPUTS  : heading
USED IN  : ???
CREATED  : 28 Jul 1999 TC
PURPOSE  : gives the direction of one object from another, with 0 at the top.
           Needs to be re-done to use sim_heading_from throughout.

TESTS:
sim_direction(0, 0, 1, 0)=>
sim_heading_from(0, 0, 1, 0)=>
sim_direction(0, 0, 0, 1)=>
sim_heading_from(0, 0, 0, 1)=>
sim_direction(0, 0, 1, 1)=>
sim_heading_from(0, 0, 1, 1)=>
sim_direction(0, 0, -1, 1)=>
sim_heading_from(0, 0, -1, 1)=>
sim_direction(0, 0, -1, -1)=>
sim_heading_from(0, 0, -1, -1)=>
sim_direction(0, 0, 1, -1)=>
sim_heading_from(0, 0, 1, -1)=>
*/

define sim_direction(x1,y1,x2,y2) -> heading;

	 (450 - sim_heading_from(x1, y1, x2, y2)) mod 360 -> heading;

enddefine;


;;; another version of the above, adjusted so that 0 degrees is at the top
;;; and the range of degrees stretches either side (positive and negative)
;;; to 180
define sim_direction_two(x1,y1,x2,y2);
    if sim_direction(x1,y1,x2,y2) > 180 then
    	sim_direction(x1,y1,x2,y2) - 360;
    else
    	sim_direction(x1,y1,x2,y2);
    endif;
enddefine;



/*
PROCEDURE: rel_direction (x1, y1, x2, y2, x3, y3) -> rel_dir
INPUTS   : x1, y1, x2, y2, x3, y3
  Where  : x1 y1 x2 y2 x3 y3
    	are all coordinates of three different objects
OUTPUTS  : rel_dir
USED IN  : ???
CREATED  : 28 Jul 1999 TC
PURPOSE  : gives the direction from one object to another,
           if 0 degrees is centred on the third object. Thus
           rel_direction(trial_coords(gromit), trial_coords(sheepy), trial_coords(post2))
           tells us what the difference is in direction of sheepy from gromit as
           opp[osed to the direction of post1. This is used extensively, as it tells
           us whether sheepy appears to the left or right of the post for gromit
           amongst many other things

TESTS:

    rel_direction(trial_coords(gromit), trial_coords(sheepy), trial_coords(post2))=>
    ** -44.0394
    ie sheepy appears to the left of the post
*/

define rel_direction(x1,y1,x2,y2,x3,y3) -> rel_dir;
    lvars dir_diff;
    sim_direction_two(x1,y1,x2,y2) - sim_direction_two(x1,y1,x3,y3)->dir_diff;
    if dir_diff > 180 then
        dir_diff - 360;
    elseif dir_diff < -180 then
        dir_diff + 360;
    else
        dir_diff
    endif -> rel_dir
enddefine;

define :method sim_distance(a1:trial_agent, a2:trial_agent) -> dist;
    ;;; Compute distance between agent a1 and another object.
    ;;; Used to determine whether the agent a1 can "sense" the object
    sim_distance_from(trial_coords(a1), trial_coords(a2)) -> dist;
enddefine;


/*
METHOD   : get_pen_limits (agent) -> (lower, higher)
INPUTS   : agent is a dog
OUTPUTS  : lower, higher
  Where  :
    lower is an angle
    higher is a angle
USED IN  : ???
CREATED  : 28 Jul 1999 TC
PURPOSE  : Vital method. Gets the range of angles relative to the target that the
           pen occupies for the dog... in other words what directions are
           obscured by the pen

TESTS:

get_pen_limits(gromit)=>
** -146.204 72.4063
NB in this case the dog is actually in the pen...

The fact that iff the dog is in the pen, the limits of the pen are greater than
180 degrees suggests that this could have been used to write a method for
telling when the dog is in the pen...
*/

define :method get_pen_limits(agent:trial_dog) -> (lower, higher);

    lvars
		post, edgeang,
		goal = trial_goal(agent),
		(goalx,goaly) = trial_coords(goal),
		(dogx,dogy) = trial_coords(agent),
		agent_space = agent.trial_personalspace,
	;

    0 ->lower;
    0 ->higher;

    for post in agent.trial_postlist do
        ;;; work out the direction of the edge of the extreme edge of the post
        ;;; ie furtherst away from the target

		lvars
			(postx,posty) = trial_coords(post),
			dist = sim_distance(agent, post),
			obscure_ang = arctan2(dist, agent_space+trial_size(post)),
			rel_dir = rel_direction(dogx,dogy, postx,posty, goalx,goaly),
			;

        if rel_dir > 0 then
            rel_dir + obscure_ang -> edgeang;
        else

            rel_dir - obscure_ang -> edgeang;

        endif;

        ;;;sort these edges to find highest and lowest

        if edgeang > higher then

            edgeang -> higher;

        elseif edgeang < lower then

            edgeang -> lower;

        endif;

    endfor;
enddefine;

/*
get_pen_limits(gromit)
arcsin(((gromit.trial_personalspace)+trial_size(post1)) / (sim_distance(gromit, post1)))
trial_personalspace(gromit)
*/



/*
METHOD   : sect (agent)
INPUTS   : agent is a dog
OUTPUTS  : sector
USED IN  : ???
CREATED  : 28 Jul 1999 TC
PURPOSE  : Another vital procedure, used to decide what the dog should do.
           Described in depth in the report, this divides up the world around
           the dog relative to the target (at the centre of the pen), into 5 s
           sectors-- front and back left, front and back right, and obscured
           by the pen

sect(gromit)=>

** 5


*/

define :method sect(agent:trial_dog) -> sector;

    lvars
		lower, higher
		sheep = trial_current(agent),
		(sheepx,sheepy) = trial_coords(sheep),
		goal = trial_goal(agent),
		(goalx,goaly) = trial_coords(goal),
		(dogx,dogy) = trial_coords(agent),
		rel_dir = rel_direction(dogx,dogy, sheepx,sheepy, goalx,goaly),
		;

    get_pen_limits(agent) -> (lower, higher);

    if rel_dir < higher + 10 and rel_dir > lower + 10 then
        5;
    else
        round((rel_dir + 45)/ 90.0) + 2;
    endif -> sector;

enddefine;



/*
PROCEDURE: left_line (lp1, lp2, obj)
INPUTS   : lp1, lp2, obj
  Where  :
    lp1 is a point(object) on a line
    lp2 is a ditto
    obj is an object
OUTPUTS  : NONE
USED IN  : ???
CREATED  : 28 Jul 1999 TC
PURPOSE  :

TESTS: left_line(post1, post10, gromit)=>
** <true>
NB obviously, this test doesn't make much sense without the image that it
describes

*/

define left_line_tolerance(lp1, lp2, obj, tolerance) -> boole;

	;;;returns true iff obj is on the left of a line from lp1 to lp2
	;;;(and its extensions to infinity)

	rel_direction(
		trial_coords(lp1),
		trial_coords(obj), trial_coords(lp2)) < tolerance -> boole;

enddefine;

define left_line(lp1, lp2, obj) -> boole;

	left_line_tolerance(lp1, lp2, obj, 0) -> boole;

enddefine;


/*
PROCEDURE: pen_sector (object) -> ps
INPUTS   : object is an object in the sheepworld
OUTPUTS  : ps is a sector
USED IN  : ???
CREATED  : 28 Jul 1999 TC
PURPOSE  : divides the world into four sectors around the pen, allowing the
           dog to modify it's behaviour depending upon which sector it is in,
           and which one the sheep is in. The sectors are defined by lines
           cut diagonally across the pen from each corner post.

TESTS:

pen_sector(gromit)=>
** [front]

See previous method..

*/

define pen_sector(object)->ps;

    if left_line(post1, post7, object) then

        if left_line(post4, post10, object) then
           "front"
        else
           "right"
        endif

    else

        if left_line(post4, post10, object) then
            "left"
        else
            "back"
        endif;

    endif -> ps;

enddefine;

/*
METHOD   : closest_angle_to (agent) -> ang
INPUTS   : agent is a dog
OUTPUTS  : ang is a angle
USED IN  : ???
CREATED  : 28 Jul 1999 TC
PURPOSE  : works out the heading of the post whose heading from the dog
           is closest to the current sheep. Used to decide which direction
           the dog should travel in if it has to go round the pen.

TESTS:
closest_angle_to(gromit)=>
** -76.5085

*/

define :method closest_angle_to(agent:trial_dog) -> ang;

    lvars
		sheep = trial_current(agent),
		(sheepx,sheepy) = trial_coords(sheep),
		goal = trial_goal(agent),
		(goalx,goaly) = trial_coords(goal),
		(dogx,dogy) = trial_coords(agent),
		post,
		hang = 0,
		lang = 0,
        ;

    for post in agent.trial_postlist do
		lvars
			(postx,posty) = trial_coords(post),
			rel_dir = rel_direction(dogx,dogy, postx,posty, sheepx,sheepy);

        if rel_dir > hang then
            rel_dir -> hang;
        elseif rel_dir < lang then
            rel_dir -> lang;
        endif;

    endfor;

    if abs(hang) > abs(lang) then
        lang -> ang;
    else
        hang -> ang;
    endif;

enddefine;


define :method close_angle_to(agent:trial_dog) -> (ang, dpost);

    ;;;Another Version of above, which takes into account the size of the post and
    ;;; the personal space the dog requires, and also keeps track of which post it
    ;;; is to avoid. (dpost)

    /*
    close_angle_to(gromit)=>
    ** 115.556 <agent post2 at (-47 -44) heading 8>
    */

    lvars
		sheep = trial_current(agent),
		(sheepx,sheepy) = trial_coords(sheep),
		goal = trial_goal(agent),
		(goalx,goaly) = trial_coords(goal),
		(dogx,dogy) = trial_coords(agent),
		agent_space = agent.trial_personalspace,
		post,
    	hang = 0,
    	lang = 0,
    	hpost,
    	lpost;

    for post in agent.trial_postlist do
		lvars
			(postx,posty) = trial_coords(post),
			dist = sim_distance(agent, post),
            rel_dir = rel_direction(dogx,dogy, postx,posty, sheepx,sheepy),
			obscure_ang = arctan2(dist, agent_space+trial_size(post))
			;

        if rel_dir + obscure_ang > hang then
            rel_dir + obscure_ang -> hang;
            post -> hpost;
        elseif rel_dir - obscure_ang < lang then
            rel_dir - obscure_ang ->lang;
            post -> lpost;
    	endif;

    endfor;

	;;; now find which is bigger
    if abs(hang) > abs(lang) then
        lang -> ang;
        lpost -> dpost;
    else
        hpost -> dpost;
        hang -> ang;
    endif;

enddefine;


/*
METHOD   : get_deshead (agent) -> heading
INPUTS   : agent is a dog
OUTPUTS  : heading
USED IN  : ???
CREATED  : 28 Jul 1999 TC
PURPOSE  : returns the heading which dog must follow to avoid the pen
           and get to the sheep.

TESTS:

get_deshead(gromit)=>
** 241.718

*/

define :method get_deshead(agent:trial_dog) -> heading;

    lvars
		(ang,post) = close_angle_to(agent);

    if istrial_post(post) then

		lvars
			c,
			(dogx,dogy) = trial_coords(agent),
			(postx,posty) = trial_coords(post),
			heading = sim_heading_from(dogx,dogy, postx,posty),
			dist = sim_distance(agent, post),
		;

        if dist > 30 then
        	arctan2(dist, agent.trial_personalspace + trial_size(post))->c;

        	if ang > 0 then heading - c else heading + c endif;
        else

        	arctan2(dist, agent.trial_personalspace + trial_size(post)) + 15 -> c;

        	if ang > 0 then heading - c else heading + c endif;

        endif;

        post -> agent.trial_problempost;

    else

    	false;

    endif -> heading;

enddefine;

/*

close_angle_to(gromit) =>

*/


define :method in_pen(agent:trial_dog) -> boole;

    ;;; One of two methods used to detect when the dog is in the pen

    if sim_distance(agent, agent.trial_goal ) < 65 then

        ;;;This distance is approximate and causes some problems.

        sect(agent) == 5 -> boole;

    else
        false -> boole;
    endif;
enddefine;





/*
METHOD   : am_in_front (agent) -> boole
INPUTS   : agent is a dog
OUTPUTS  : boole is a boolean
USED IN  : ???
CREATED  : 29 Jul 1999 TC
PURPOSE  :Returns true if the dog is in front of a line from the two
          front posts. Defined by whether one post is to the left of the other
          This is used in deciding whether to switch from steering
          behaviour to taking behaviour.

TESTS:

am_in_front(gromit)=>
** <true>

*/

define :method am_in_front(agent:trial_dog)-> boole;


    unless agent.trial_leftpost == [] or agent.trial_rightpost == [] then

    rel_direction(trial_coords(agent), trial_coords(agent.trial_leftpost), trial_coords(agent.trial_goal)) > rel_direction(trial_coords(agent), trial_coords(agent.trial_rightpost), trial_coords(agent.trial_goal))->boole;
    endunless;
enddefine;



/*
METHOD   : current_in_front (agent) -> boole
INPUTS   : agent is a dog
OUTPUTS  : boole is a boolean
USED IN  : ???
CREATED  : 29 Jul 1999
PURPOSE  : similar to above, but deals with the dog's current sheep.

TESTS:

*/

define :method current_in_front(agent:trial_dog)->boole;

    unless agent.trial_leftpost == [] or agent.trial_rightpost == [] then
    rel_direction(trial_coords(agent.trial_current), trial_coords(agent.trial_leftpost), trial_coords(agent.trial_goal)) > rel_direction(trial_coords(agent.trial_current), trial_coords(agent.trial_rightpost), trial_coords(agent.trial_goal))->boole;
    endunless;

enddefine;

/*
current_in_front(gromit)=>
** <true>
*/


/*
PROCEDURE: tree_range (agent, tree) -> (upper, lower)
INPUTS   : agent, tree
  Where  :
    agent is a dog
    tree is a tree
OUTPUTS  : upper, lower
  Where  :
    upper is a heading
    lower is a heading
USED IN  : ???
CREATED  : 29 Jul 1999 TC
PURPOSE  : returns the range of angles which are to be avoided because of the
            presence of tree.

TESTS:

tree_range(gromit, tree1) -> (a, b)
a=>
** 95.0303
b=>
** 86.4844
*/

define tree_range(agent, tree) -> (upper, lower);

	lvars heading;

	;;;Get the heading of the tree from the dog.

	sim_heading_from(trial_coords(agent), trial_coords(tree)) -> heading;

	;;;Calculate range of angles by adding and subtracting a 'berth' from
	;;;this heading.

	lvars berth =
		arctan2(sim_distance(agent, tree), trial_size(agent) + trial_size(tree));

	heading + berth -> upper;
	heading - berth -> lower;

enddefine;


/*
METHOD   : tree_detect (agent) -> answer
INPUTS   : agent is a dog
OUTPUTS  : answer
USED IN  : ???
CREATED  : 29 Jul 1999 TC. Modified AS 16 Jul 2000
PURPOSE  : Used to detect whether the current sheep falls within the range of
           any tree. Finds the nearest problem tree.

*/

define :method tree_detect(agent:trial_dog) -> answer;
    lvars tree, upper, lower,
		sheep = agent.trial_current,
		nearest = false;

	false -> answer;

	;;; If no sheep selected, return
	returnunless(sheep);

	lvars
		dist = 100000,
		heading = trial_heading(agent),
		rel_dir = sim_heading_from(trial_coords(agent), trial_coords(sheep)),
		sheep_dist = sim_distance(agent, sheep);


    for tree in agent.trial_trees do

		lvars tree_dist = sim_distance(agent, tree);
		if tree_dist < sheep_dist then

        	;;; Get the tree's range of directions blocked

        	tree_range(agent, tree)->(upper, lower);

        	;;;See if sheep is within range

        	if rel_dir > lower and rel_dir < upper then
				if tree_dist < dist then
					tree_dist -> dist;
					tree -> nearest;
            		if tree_dist < 100 then
						
                		true -> answer;

                		tree -> agent.trial_problemtree;
            		endif;
				endif;
        	endif;

        	;;; Also see if the dog is heading for disaster.

        	if heading < upper and heading > lower then

            	if tree_dist < 40 then
					if tree_dist < dist then
						tree_dist -> dist;
						tree -> nearest;
                		true -> answer;
						tree -> agent.trial_problemtree;
					endif;
            	endif;
        	endif;
		endif;
    endfor;

    if not(answer) then
        false -> agent.trial_problemtree;
    endif;

enddefine;



define :method get_adj(agent:trial_dog) -> ang;

    ;;;Finds the best angle for the dog to turn in some circumstances
    ;;;With a minimum of 40 and maximum of 60
	;;; Turn less when closer to the goal

    lvars
		dist=
    		sim_distance(agent, agent.trial_goal);

    max(25 + round (dist / 10.0), 40) -> ang;

	min(ang, 60) -> ang;

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

define obscured_ranges(range_list) -> result;
    ;;; Given a list of ranges this function returns a list of non-intersecting
    ;;; ranges which encompass all the ranges of the original list

    lvars
        range_list, base_list = [],
        base_range, new_range, result_range,
        b, altered;

	for new_range in range_list do

        ;;; Find how many ranges are already in the base list
        listlength(base_list) -> b;
[%
        ;;; Compare the new range with each element of the base list
        repeat b times
            ;;; Get the next range in the base list
            base_list --> ! [ ?base_range ??base_list];
            ;;; base_list --> ! [ ??base_list ?base_range];

            ;;; Try to combine the two ranges
            compare_ranges( base_range, new_range ) -> (result_range,altered);

            ;;; If the ranges intersected
            if altered then
                ;;; Update new range for subsequent loops
                result_range -> new_range;
            else
                ;;; If there was no intersection then the base range can be
                ;;; added back into the base list unaltered
                ;;;; result_range :: base_list -> base_list;
                result_range,
            endif;
        endrepeat;
%] -> base_list;

        ;;; After being combined with any overlapping ranges previously in the
        ;;; base list the resulting new range can be added to the base list
        new_range :: base_list -> base_list;

    endfor;

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
        '<%P at (%P %P)>',
        [% sim_name(item), trial_coords(item)%])
enddefine;

define :method print_instance(item:trial_dog);
    ;;; Used to control the info printed for dogs

    dlocal pop_pr_places = 0;
    printf(
        '<%P at (%P %P) heading %P>',
        [% sim_name(item), trial_coords(item), trial_heading(item)%])
enddefine;

define :method print_instance(item:trial_obstacle);
    ;;; Used to control the info printed for obstacles

    dlocal pop_pr_places = 0;
    printf(
        '<OBS %P at (%P %P)>',
        [% sim_name(item), trial_coords(item) %])
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


/*
METHOD   : quoi (agent) -> boole
INPUTS   : agent is a dog
OUTPUTS  : boole, is a boolean
USED IN  : ???
CREATED  : 29 Jul 1999     TC
PURPOSE  : Returns true if the sheep appears to the left of the centre of the
           range of the pen. Used to decide whether the dog should go to the left
           or right of the sheep if the sheep is in front of the pen.
*/

define :method quoi(agent:trial_dog) -> boole;

    lvars a, b, c;

    get_pen_limits(agent) -> (a,b);
    (a+b)/2.0 -> c;

	rel_direction (trial_coords(agent), trial_coords(agent.trial_current), trial_coords(agent)) > c
		-> boole;
enddefine;


/*
METHOD   : wise (agent)
INPUTS   : agent is a dog
OUTPUTS  : NONE
USED IN  : ???
CREATED  : 29 Jul 1999 TC
PURPOSE  : Works out what heading the dog should take if the sheep is between
           it and the pen.


*/

define :method wise(agent:trial_dog);

    lvars ang, a, b;
    get_pen_limits(agent) -> (a,b);
    if quoi(agent) then
        a -> ang;
    else
        b -> ang;
    endif;
    (ang + rel_direction(trial_coords(agent), trial_coords(agent.trial_current), trial_coords(target)))/2;
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

	returnif(rc_under_mouse_control(agent));


    speed -> trial_speed(agent);

    ;;; These are stored to prevent repeated evaluation during the rest of
    ;;; the procedure
    cos(rc_axis(agent)) -> cos_angle;
    sin(rc_axis(agent)) -> sin_angle;

    ;;; Calculate where the agent intends to move to
    round( rc_picx(agent) + speed*cos_angle) -> aimx;
    round( rc_picy(agent) + speed*sin_angle) -> aimy;

    ;;; Now check if this will mean bumping into other agents
    for other in all_agents do
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




define :method set_rel_heading(agent:trial_dog, relheading);
    ;;; A relativised version of the above, designed to deal with
    ;;; the direction from the dog to its goal...

    lvars heading;

    sim_heading_from(trial_coords(agent), trial_coords(agent.trial_goal))->heading;

    heading - relheading ->trial_heading(agent);

    rc_set_axis(agent, (heading - relheading), true);


enddefine;

/*
TESTS
set_rel_heading(gromit, -18)
*/



define :method move( agent:trial_sheep, bearing, speed );
    ;;; Allows sheep to turn and move with one function call

	returnif(rc_under_mouse_control(agent));
    set_heading(agent, bearing);
    forward(agent, speed);
enddefine;

define :method move_dog(agent:trial_dog, speed, bearing);
    ;;; ditto for the dog

    rc_sync_display();
    if speed /== 0 then
        set_heading(
            agent,bearing
        );
		returnif(rc_under_mouse_control(agent));
        forward(agent, speed);
    endif;

enddefine;

define :method wander(agent:trial_sheep);
    ;;; Move slowly in undirected fashion

    ;;; Moves the agent forward with a random element determining its exact heading
    move( agent, (trial_heading(agent) + random(70) - 35) mod 360, 1 );
enddefine;


/*
TESTS
rel_direction(trial_coords(post1), trial_coords(post4), trial_coords(gromit))=>;
** 90.404
left_line(post1, post4, gromit)=>
** <true>
*/




/*
PROCEDURE: is_in_pen (object) -> boole
INPUTS   : object is a sheep agent
OUTPUTS  : boole, is a boolean
USED IN  : ???
CREATED  : 29 Jul 1999 TC
PURPOSE  : To test whether an object is within the confines of the pen
           Returns T if the object is to the left of each line from corner post
           to corner post
*/



define close_to_pen(object, tolerance) -> boole;
	left_line(post1, post4, object) and
        left_line(post4, post7, object) and
        left_line(post7, post10, object) and
        left_line_tolerance(post10, post1, object, tolerance)
			-> boole
enddefine;

define is_in_pen(object);
	close_to_pen(object, 4);
enddefine;


/*
METHOD   : make_sheep_list (agent, objects) -> list
INPUTS   : agent, objects
  Where  :
    agent is a dog
    objects is the list of agents in the world
OUTPUTS  : list is a list of the sheep in the world
USED IN  : ???
CREATED  : 26 Jul 1999   TC
PURPOSE  : Used by the dog as it divides the world up into sheep, posts and
           trees. This process enables the dog to deal with different types
           of agent in different ways.
           NOTE. It only lists the sheep which are outside of the pen, because
           that way it can know about only those sheep it needs to deal
           with. This means it can be re-used, whenever a sheep is driven
           into the pen, to recreate a list of those sheep that still need
           to be sorted out-- even if they yhave escaped from the pen!
TESTS:
make_sheep_list(gromit, all_agents)->list
list ==>;
** [<agent sheepy at (28 -129) heading 354 hunger 8 urgency 0>
    <agent sleepy at (5 102) heading 301 hunger 0 urgency 0>
    <agent sneezy at (-13 131) heading 47 hunger 0 urgency 1>
    <agent bashful at (-205 54) heading 142 hunger 0 urgency 1>
    <agent doc at (118 -122) heading 358 hunger 0 urgency 0>]
*/

define :method make_sheep_list(agent:trial_dog, objects)->list;
    ;;; used by the dog to get a list of all the sheep in the world.

    lvars x;
    [%for x in objects do
         if istrial_sheep(x) and not(is_in_pen(x)) then
           x
         endif;
    endfor%] -> list;
enddefine;
/*
in_pen(gromit)
*/

define same_side_of_line(lp1, lp2, o1, o2);
    ;;;returns true iff o1 & o2 are on the same side of a line from lp1 to lp2
    ;;;(and it's extensions to infinity) TC

	left_line(o1, lp1, lp2) == left_line(lp1, lp2, o2)


enddefine;

/*

same_side_of_line(post1, post7, gromit, gromit.trial_current)

*/
define :method get_outside_posts(agent:trial_dog)-> (hpost, lpost);

    ;;; retrieves the post at the outside limits of the pen, as the dog "looks"
    ;;; at the current sheep. BEWARE, will only work if the sheep is within
    ;;; the range of the pen!! TC

    lvars
		hpost, lpost, post,
    	hang = 0,
		lang = 0,
		goal = trial_goal(agent),
		(goalx,goaly) = trial_coords(goal),
		(dogx,dogy) = trial_coords(agent);

    for post in agent.trial_postlist do
		lvars
			(postx,posty) = trial_coords(post),
			rel_dir = rel_direction(dogx,dogy, postx,posty, goalx,goaly);
		;

        if rel_dir > hang then
            rel_dir -> hang;
            post -> hpost;
        elseif rel_dir < lang then
            rel_dir -> lang;
            post -> lpost;
        endif;

    endfor;

enddefine;

/*
get_outside_posts(gromit)->(hpost, lpost)
hpost ==>
lpost ==>
*/


define :method in_front_of_pen(agent:trial_dog) -> boole;

    ;;;returns T iff the sheep is directly between the dog and the pen TC

    lvars lpost, hpost;

    if sect(agent) < 5 then

        false;

    else

        get_outside_posts(agent)->(hpost, lpost);

        not(is_in_pen(agent.trial_current)) and
            not(is_in_pen(agent)) and
            (sect(agent) == 5) and
            same_side_of_line(lpost, hpost, agent, agent.trial_current)
    endif -> boole;
enddefine;

define :method behind_pen(agent:trial_dog) -> boole;

    ;;;returns T iff the sheep is directly behind the pen (from the dog)

    lvars
		lpost, hpost
		sheep = trial_current(agent);

    get_outside_posts(agent) -> (hpost, lpost);

	sect(agent) == 5
	and not(is_in_pen(sheep))
	and not(is_in_pen(agent))
	and not(same_side_of_line(lpost, hpost, agent, sheep))
					-> boole;
enddefine;

/*
in_front_of_pen(gromit)
behind_pen(gromit)
is_in_pen(gromit)
sect(gromit)

*/


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
    call_next_method(agent, all_agents);

enddefine;



/*
METHOD   : sim_run_agent (agent, agents)
INPUTS   : agent, agents
  Where  :
    agent is a dog
    agents is the sheep agents
OUTPUTS  : NONE
USED IN  : ???
CREATED  : 29 Jul 1999 TC

*/

define :method sim_run_agent(agent:trial_dog, agents);
    ;;; Sets up the agents internal database ready for the execution of
    ;;; its rules

    ;;; Stores the name of the currently active agent.  This can be
    ;;; accessed within the rules
    dlocal
        my_name = sim_name(agent);

    ;;; The agent has no memory of any previous time slices

	;;; Now done in forgetting ruleset
    ;;; sim_clear_database( sim_data(agent) );

    ;;;Previously used tracing routines
    ;;;agent.trial_current==>;
    ;;;agent.trial_goal==>;
    ;;;agent.trial_side==>;
    ;;;agent.trial_sheepside==>;
    ;;;agent.trial_sector ==>;
    ;;;agent.trial_deshead  ==>;

    prb_add_list_to_db(
        [
            ;;; [current 	^(agent.trial_current)]
            [target 	^(agent.trial_goal)]
            [side 		^(agent.trial_side)]
            [sheepside 	^(agent.trial_sheepside)]
            [target_sector 		^(agent.trial_sector)]
            [desheading ^(agent.trial_deshead)]
            ;;; [behaviour 	^(agent.trial_behav)]
        ],
        sim_data(agent) );

    if agent.trial_in_pen then
    prb_add_list_to_db(
        [
             [in_pen]
        ],
        sim_data(agent) );

    endif;

	;;;Possible debugging information
	;;;[IN SHEEPDOG cycle ^sim_cycle_number] =>
	;;;if sim_cycle_number mod 20 == 0 then
	;;;	prb_print_table(sim_data(agent));
	;;;	readline() ->;
	;;;endif;
    ;;; Now run the generic version of the method sim_run_agent
    call_next_method(agent, all_agents);

enddefine;




/*
-- Button and drag methods for empty window space

;;; Methods added by Aaron Sloman 22 Jan 1999
*/

;;; Methods for empty window space
define :method sheep_button_1_up(pic:rc_window_object, x, y, modifiers);
	false ->
    ;;; do nothing
enddefine;


vars procedure run_sheep;	;;; defined later

define :method sheep_button_3_up(pic:rc_window_object, x, y, modifiers);
	if sheep_stopped then

		rc_async_apply(run_sheep(%20000%), true);
	
	else
	    ;;; Use this to terminate run
	    true -> sheep_stopped;
	endif;
enddefine;


/*
-- Button and drag methods for objects
*/

define :method rc_button_1_down(pic:trial_agent, x, y, modifiers);
    ;;; Make sure it is at the front of the known objects list
    rc_set_front(pic);
	pic -> rc_mouse_selected(rc_active_window_object);
enddefine;


define :method rc_button_1_up(pic:rc_selectable, x, y, modifiers);
    ;;; disable default method
enddefine;


define :method rc_button_1_drag(pic:trial_agent, x, y, modifiers);
	;;; This could have additional information.
	;;; For now, just call the default procedure
	call_next_method(pic, x, y, modifiers);
enddefine;


/*
-- Rulesets for the agents


-- . Rulesets for the dog
*/


/*
RULESET  : dog_perception_rules
CREATED  : 29 Jul 1999
PURPOSE  : utility rules

*/

define :ruleset dog_perception_rules;
	[DLOCAL [prb_allrules = true]];

    RULE goal_check

    ;;;Check whether the current sheep has reached the goal
    ;;;where "reach" is equivalent to being within a certain distance.
    ;;;PLay with alternative ranges to test their effectiveness
    [current ?sheep:istrial_agent]
    [target ?targ:istrial_agent]
    [WHERE sim_distance(sheep, targ) < 35
		and is_in_pen(sheep) and
			close_to_pen(sim_myself, 25)]
	==>
	[POP11
		[] ->> trial_current(sim_myself)
			-> trial_behav(sim_myself) ]
    [SAY ?sheep 'now in pen.']
	[DEL 1 2]
	[current []]
	[target []]
	[behaviour []]


RULE no_more_sheep
	[current []]
	[WHERE
    	(make_sheep_list(sim_myself, all_agents) ->> trial_list(sim_myself))
	 	== []]
	==>
	;;; Remove information that might prevent a restart if
	;;; sheep move out
	[NOT behaviour ==]
	[NOT lastbehaviour ==]
	[behaviour finished]
	[SAY 'Stopping: no more sheep']
	[POP11
		[] -> sim_myself.trial_current;
		[] -> trial_behav(sim_myself);
		sim_stop_scheduler();]
enddefine;


/*
RULESET  : dog_target_rules
CREATED  : 29 Jul 1999
PURPOSE  : Determines which of the dog's sectors the sheep is in

*/

define :ruleset dog_target_rules;
	[DLOCAL [prb_allrules = false]];
	[LVARS [sheep = trial_current(sim_myself)] ];

RULE startup
    ;;;start up rule
    [target []]
        ==>
    [SAY 'no targets yet']
	[STOP]


RULE stop_if_nosheep
	[NOT current ?sheep:istrial_agent]
	==>
	[SAY 'No current selected sheep']
	[STOP]

RULE sheepontarget
    [side front]
    [sheepside front]
    [WHERE
		lvars
			goal = sim_myself.trial_goal,
			goal_dir =
				rel_direction(
					trial_coords(sim_myself),
						trial_coords(sheep), trial_coords(goal)),
			;

		goal_dir >
        	rel_direction(
				trial_coords(sim_myself),
					trial_coords(sim_myself.trial_rightpost),
						trial_coords(goal))
        and

		goal_dir <
        	rel_direction(
				trial_coords(sim_myself),
					trial_coords(sim_myself.trial_leftpost),
						trial_coords(goal)) ]
        ==>

    [POP11
        "on_target" -> sim_myself.trial_sector;
    ]
	[target_sector on_target]
	;;; [SAY 'Aiming for "on_target" sector']

RULE sheepobscure

    [desheading ?deshead][->> It]
    [WHERE not(deshead)
		and behind_pen(sim_myself)]
        ==>
    [POP11
        "near_sheep" -> sim_myself.trial_sector;
        get_deshead(sim_myself) ->> sim_myself.trial_deshead
			-> deshead;
    ]
	[DEL ?It]
	[desheading ?deshead]
	[target_sector near_sheep]
	;;; [SAY 'Aiming for "near_sheep" sector']

RULE sheepstillobscure
    [desheading ?deshead]
    [WHERE deshead
		and
		istrial_agent(sim_myself.trial_problempost)]
        ==>

    [POP11
		lvars
			rel_heading =
				sim_heading_from(
					trial_coords(sim_myself),
					trial_coords(sim_myself.trial_problempost));

        if rel_heading < (deshead + 90) and rel_heading > (deshead - 90) then
        	"near_sheep" -> sim_myself.trial_sector;
        	[sheep still obscure]==>
        else
        	false -> sim_myself.trial_deshead;
        	false -> sim_myself.trial_problempost;
        endif;
    ]

RULE sheepinfront
    [WHERE
		in_front_of_pen(sim_myself)]
        ==>
    [POP11
        "infront" -> sim_myself.trial_sector;
    ]
	[target_sector infront]
	;;; [SAY 'Aiming for "infront" sector']

RULE sheepbackleft
    [WHERE sect(sim_myself) = 1]
        ==>
    [POP11
        "backleft" -> sim_myself.trial_sector;
    ]
	[target_sector backleft]
	;;; [SAY 'Aiming for "backleft" sector']


RULE sheepfrontleft
    [WHERE sect(sim_myself) = 2]
        ==>
    [POP11
        "frontleft" -> sim_myself.trial_sector;
    ]
	[target_sector frontleft]
	;;; [SAY 'Aiming for "frontleft" sector']

RULE sheepbackright
    [WHERE sect(sim_myself) = 4]
        ==>
    [POP11
        "backright" -> sim_myself.trial_sector;
    ]
	[target_sector backright]
	;;; [SAY 'Aiming for "backright" sector']

RULE sheepfrontright
    [WHERE sect(sim_myself) = 3]
        ==>
    [POP11
        "frontright" -> sim_myself.trial_sector;
    ]
	[target_sector frontright]
	;;; [SAY 'Aiming for "frontright" sector']

enddefine;


/*
RULESET  : behaviour_rules
CREATED  : 29 Jul 1999 TC
PURPOSE  : Regulates the dog's behaviour. eg when the sheep and dog are in
           the front sector of the pen, the behaviour is steering

*/

define :ruleset behaviour_rules;

RULE steerinpen
    [sheepside front]
    [side front]
    ==>
	[NOT behaviour ==]
	[behaviour steer]
	;;; [SAY 'setup steer']

RULE join_sheep
    [sheepside ?sheepside]
    [side ?side]
    [WHERE sheepside /== side ]
    ==>
	[NOT behaviour ==]
	[behaviour join]
	;;; [SAY 'setup join']

RULE take_sheep
    [sheepside ?sheepside]
    [side ?sheepside]
    [WHERE sheepside /== "front"]
    ==>
	[NOT behaviour ==]
	[behaviour take]
	;;; [SAY 'setup take']

enddefine;


/*
RULESET  : dog_side_rules
CREATED  : 29 Jul 1999
PURPOSE  : Evaluates where the dog is in relation to the pen

*/

define :ruleset dog_side_rules;

RULE start

    [target []]
    ==>
    [SAY 'side rules not yet started']

RULE inpendetect
    [WHERE is_in_pen(sim_myself)]
    ==>
    [
    POP11
	    "pen" -> sim_myself.trial_side;
    ]

RULE pensector
    [WHERE not(in_pen(sim_myself))]
    ==>
    [POP11
    	pen_sector(sim_myself) -> sim_myself.trial_side;
    ]


enddefine;

/*
RULESET  : dog_sheepside_rules
CREATED  : 29 Jul 1999
PURPOSE  : Evaluates where the sheep is in relation to the pen

*/

define :ruleset dog_sheepside_rules;

RULE start
    [target []]
    ==>
    [SAY 'sheepside rules not yet started']

RULE sheeppensector

    ==>
	[LVARS [sector = pen_sector(sim_myself.trial_current)]]
    [POP11
		sector -> sim_myself.trial_sheepside;
    ]
	[sheepside ?sector]

enddefine;


/*
RULESET  : dog_pen_rules
CREATED  : 29 Jul 1999
PURPOSE  : Deals with situations where the dog is in the pen

*/

define :ruleset dog_pen_rules;
    [DLOCAL [prb_allrules = false]];
	
RULE start
    [target []]
    ==>
    [SAY 'not yet started']
	[STOP]


RULE inpendetect
    [WHERE is_in_pen(sim_myself)]
    ==>
    [POP11
    	true -> sim_myself.trial_in_pen;]
    [SAY 'I\'m in the pen']
    [in_pen]

RULE counterpen
    [in_pen]
    [WHERE sect(sim_myself) < 5]
    ==>
    [DEL 1]
    [POP11
        false -> sim_myself.trial_in_pen;
    ]
	[SAY 'I\'m not in the pen']

enddefine;


/*
RULESET  : dog_tracing
CREATED  : 29 Jul 1999
PURPOSE  : Used for testing and debugging

*/

define :ruleset dog_tracing;
RULE tracer
    ==>
	;;; [SAY tracing]
    [POP11
    	;;; prb_print_database();
		;;; readline() ->;
    ]
enddefine;



define :ruleset find_new_sheep;
	[DLOCAL [prb_allrules = false]];

RULE finished
	[behaviour finished]
        ==>
    [SAY 'Fetching all finished']

RULE test_if_finished
    ;;; First make a list of sheep not in the pen, in random order
    [WHERE
		sim_myself.trial_current == []
		and
		(make_sheep_list(sim_myself, all_agents) ->> sim_myself.trial_list)
				== []
	]
        ==>
        ;;;If all the sheep are in the pen then do nothing
	[NOT behaviour ==]
	[behaviour finished]
    [SAY 'Fetching finished']

RULE select_sheep
    [WHERE sim_myself.trial_current == []
		and
		sim_myself.trial_list /== []
	]
	==>
	[SAY 'selecting a sheep to fetch']
	[LVARS sheep]
	[POP11
		lvars list = sim_myself.trial_list;
		oneof(list) -> sheep;
        delete(sheep, list) -> sim_myself.trial_list;
		sheep -> sim_myself.trial_current;
    ]
	[NOT current ==]
	[current ?sheep]
	[SAY 'Starting to fetch' ?sheep]

RULE get_target

    [target []]

        ==>

    [LVARS targ]

    [POP11
        lvars x;
        for x in all_agents do
        	if istrial_target(x) then
        		x -> targ;
        		x ->sim_myself.trial_goal;
        	endif;
        endfor;
        post1 -> sim_myself.trial_leftpost;
        post10 -> sim_myself.trial_rightpost;
        make_post_list(sim_myself, all_agents) -> sim_myself.trial_postlist;
        make_tree_list(sim_myself, all_agents) -> sim_myself.trial_trees;
    ]
	[NOT target ==]
	[target ?targ]
	;;; [SAY TARGET now ?targ]


enddefine;

;;; Accidentally removed by Tom? re-inserted by AS.
;;; Or should this be removed from the rulesystem

define :ruleset otherside_perception;
	[DLOCAL [prb_allrules = false]];

RULE notyet

    [NOT sameside]
    [NOT otherside]
    [NOT notyet]
     	==>
    [notyet]

RULE otherside

    [OR [sameside][notyet] ]
    [side ?side]
    [sheepside ?sheepside]
	[current ?sheep]
    [WHERE side /== sheepside
		and
		sim_distance(sim_myself, sheep) > 30]
    	==>
    [NOT sameside]
	[NOT notyet]
    [otherside]

RULE sameside
    [OR[otherside][notyet]]
    [side ?side]
    [sheepside ?sheepside]
    [WHERE side == sheepside]
     	==>
    [DEL 1]
    [sameside]

enddefine;

/*
RULESET  : memory_testing
CREATED  : 29 Jul 1999
PURPOSE  : Enables the dog to work out if it has moved since the previous turn
           and if not, to take evasive action from any obstacle it may be
           impeded by. viz turn randomly left or right to avoid it

*/

define :ruleset memory_testing;
	[DLOCAL [prb_allrules = false]];

RULE counterhit
    [counter 2]
    	==>
	;;; In same place for two cycles
	;;; reset counter and move in new direction
	[DEL 1]
	[counter 0]
	[LVARS
		[heading =
    		round(
				(sim_myself.trial_heading
					+ if random(2) == 1 then 90 else - 90 endif)
					+ (5 - random(10)) ) mod 360]]
    [POP11
    	lvars speed = 35;
    	move_dog(sim_myself, speed, heading);
    ]

	[SAY 'Stuck for two steps. Turning to heading ' ?heading]
	;;; now record this location
	[NOT lastloc ==]
	[LVARS [[lastx lasty] = trial_coords(sim_myself)]]
	[lastloc ?lastx ?lasty]
	;;; [PAUSE]

RULE test_if_moved

	[lastloc ?lastx ?lasty]
    [WHERE agent_now_at(sim_myself, lastx, lasty)]
	[counter ?counterval][->>It]
    	==>
	[DEL ?It]
	[LVARS [newval = counterval + 1]]
	[counter ?newval]

RULE reset_counter
	[counter ?counterval]
    	==>
	[DEL 1]
	[NOT lastloc ==]
	[LVARS [[lastx lasty] = trial_coords(sim_myself)]]
	[lastloc ?lastx ?lasty]
	[counter 0]
	;;; [SAY resetting counter to 0]
	;;; [PAUSE]

RULE start_counter
	;;; initially there's no counter value, so start it
	
	==>
	[counter 0]
	[LVARS [[lastx lasty] = trial_coords(sim_myself)]]
	[lastloc ?lastx ?lasty]

enddefine;


define :ruleset forget_recent;
	[DLOCAL [prb_allrules = true]];

	RULE forget_most_things
		==>
		;;; forget everything except counter, lastloc and a few other things.
		[NOT new_sense_data ==]
    	[NOT target_sector ==]
    	[NOT sheepside ==]
    	[NOT side ==]
    	[NOT target ==]
    	[NOT desheading ==]
    	;;; [NOT behaviour ==]
		[NOT in_pen]
    	;;; [NOT current ==]


RULE behaviour_changed
	[behaviour ?behaviour]
	[last_behaviour ?last]
	[WHERE last /== behaviour]
	==>
	[SAY 'Behaviour is now:' ?behaviour]

RULE behaviour_new
	[NOT last_behaviour ==]
	[behaviour ?behaviour]
	==>
	[SAY 'Behaviour is now:' ?behaviour]

RULE remember_behaviour
	[behaviour ?behaviour]
	==>
	[NOT last_behaviour ==]
	[last_behaviour ?behaviour]
	
    	
enddefine;

/*
-- . . Behaviour rulesets for rulefamily dog_activity_rulecluster
*/

/*
RULESET  : join
CREATED  : 29 Jul 1999
PURPOSE  : Directs the dog to the sheep

*/

define :ruleset join;
	[DLOCAL [prb_allrules = false]];
	[LVARS [sheep = trial_current(sim_myself)] ];

;;;Some Context flipping Rules

RULE notready
	;;; added by A.S.	
    [WHERE sim_myself.trial_goal == [] or sheep == []]
	==>
	[STOP]

RULE flipjtotd
    [WHERE tree_detect(sim_myself)]
    ==>
	[SAY 'switch to tree']
    [RESTORERULESET treedetection]

RULE flipjtos
    [behaviour steer]
    [WHERE sim_distance(sim_myself, sheep) < 100]
    ==>
	[SAY 'switch to steer']
    [RESTORERULESET steer]

RULE flipjtot
    [behaviour take]
    [WHERE sim_distance(sim_myself, sheep) < 80]
    ==>
	[SAY 'switch to take']
    [RESTORERULESET take]

RULE inpen
    [side pen]
    ==>
    [SAY Now in pen]
    [POP11
        lvars speed, heading, dist;
        sim_distance(sim_myself, sheep ) -> dist;

		;;; This bit inserted by A.Sloman
		if dist > 50 then 10 else round(dist/25.0) endif -> speed;
        pen.orientation - 90 -> heading;
		[Escaping from pen: heading ^heading]=>
        move_dog( sim_myself, speed, heading );
    ]

    ;;;Then some rules to cover various situations

RULE curinf

    [WHERE current_in_front(sim_myself)
		and am_in_front(sim_myself)]
    [OR
		[target_sector near_sheep]
		[target_sector frontleft]
		[target_sector frontright]]

    ==>

    [POP11
        lvars dist, speed, heading;

    	sim_distance(sim_myself, sheep ) -> dist;

		approach_speed(dist) -> speed;

    	sim_heading_from(
				trial_coords(sim_myself), trial_coords(sheep))
		+
   			if left_line(target, target2, sheep) then
				- get_adj (sim_myself)
   			else
				get_adj (sim_myself)
   			endif  -> heading;

        move_dog(sim_myself, speed, heading);

    ]


RULE noproblem

    [NOT target_sector near_sheep]
    [WHERE sim_distance(sim_myself, sheep) > 100]
    ==>
    [POP11
        lvars dist, speed, heading;

    	dog_default_speed ->	speed;

    	sim_heading_from(
			trial_coords(sim_myself), trial_coords(sheep) ) -> heading;

		move_dog(sim_myself, speed, heading);

    ]

;;;The next two prevent the dog from going all the way around the pen with the
;;;sheep if it is far from the pen

RULE noproblem2

    [NOT target_sector near_sheep]
    [NOT target_sector frontleft]
    [NOT target_sector frontright]
    [WHERE
		sim_distance (sim_myself.trial_goal, sheep)> 130
		and left_line(target, target2, sheep)
		and sim_distance(sim_myself, sheep) > 80]
    ==>
    [POP11
        lvars dist, speed = dog_default_speed, heading;

    sim_distance(sim_myself, sheep) -> dist;

    sim_heading_from(
		trial_coords(sim_myself), trial_coords(sheep)
                        ) - get_adj(sim_myself) -> heading;

        move_dog(sim_myself, speed, heading);
    ]


RULE noproblem3

    [NOT target_sector near_sheep]
    [NOT target_sector frontleft]
    [NOT target_sector frontright]
    [WHERE sim_distance (sim_myself.trial_goal, sheep) > 130
		and not(left_line(target, target2, sheep))
		and sim_distance(sim_myself, sheep) > 80]
    ==>
    [POP11
        lvars speed = dog_default_speed, heading;

    	sim_heading_from(
			trial_coords(sim_myself), trial_coords(sheep)
                        ) + get_adj(sim_myself) -> heading;

        move_dog(sim_myself, speed, heading);

    ]

;;;Avoid the pen

RULE rearon
    [target_sector near_sheep]
    [desheading ?deshead]
    [WHERE deshead]

    ==>
    [POP11
        lvars dist, speed, heading;
        sim_distance(sim_myself, sheep) -> dist;

		approach_speed(dist) -> speed;

        move_dog(sim_myself, speed, deshead);
    ]

;;;At a distance

RULE rearfar

    [WHERE sim_distance(sim_myself, sheep) > 30]
    ==>
    [POP11
        lvars
			dist = sim_distance(sim_myself, sheep),
			speed, heading;

		approach_speed(dist) -> speed;

        sim_heading_from(
			trial_coords(sim_myself), trial_coords(sheep) ) -> heading;

        move_dog(sim_myself, speed, heading);
    ]

RULE tracej
    ==>
    [SAY 'No join rules fired']
enddefine;


/*
RULESET  : steer
CREATED  : 29 Jul 1999
PURPOSE  : tells the dog how to behave if it is in front of the pen, and
            therefore in a position to steer the sheep in.

*/

define :ruleset steer;
	[DLOCAL [prb_allrules = false]];
	[LVARS [sheep = trial_current(sim_myself)] ];

;;;Firstly some flipping rules


RULE flipstoj
    [OR [behaviour join] [current []]]
        ==>
	[SAY 'switch to join -2']
    [RESTORERULESET join]

RULE flipstotd
    [WHERE tree_detect(sim_myself)]
    ==>
	[SAY 'tree detected']
    [RESTORERULESET treedetection]


RULE flipstoj2
    [WHERE istrial_agent(sheep)
		and sim_distance(sim_myself, sheep) > 100]
        ==>
	[SAY 'switch to join -3']
    [RESTORERULESET join]

RULE flipstot
    [behaviour take]
        ==>
	[SAY 'switch to take 2']
    [RESTORERULESET take]


RULE inpen

    ;;; If the dog is in the pen, get out of it!!! Also in join and steer

    [side pen]

        ==>
    [POP11
        lvars
			speed, heading;

		;;; reduce speed to prevent overshooting.
        dog_default_speed*0.5 -> speed;
        pen.orientation - 90 -> heading;

        move_dog( sim_myself, speed, heading );
    ]
    [SAY 'In pen -- moving out']

RULE steeron

    ;;;Where the sheep is in the direction of the mouth of the pen, head
    ;;;straight for it

    [target_sector on_target]
	[WHERE istrial_agent(sheep)]
        ==>
	;;; [SAY HEADING FOR PEN]
    [POP11
        lvars
			heading, speed,
			(dogx,dogy) = trial_coords(sim_myself),
			(sheepx,sheepy) = trial_coords(sheep),
			dist = sim_distance_from(dogx, dogy, sheepx, sheepy);

		approach_speed(dist) -> speed;

        sim_heading_from(dogx, dogy, sheepx, sheepy) -> heading;

        move_dog(sim_myself, speed, heading)
    ]

RULE infront

    ;;;Where the sheep is between the dog and the pen, drive it towards
    ;;;the mouth of the pen

    [target_sector infront]
	[WHERE istrial_agent(sheep)]
        ==>
    [POP11
        lvars
			speed, heading,
			(dogx,dogy) = trial_coords(sim_myself),
			(sheepx,sheepy) = trial_coords(sheep),
        	rel_heading = sim_heading_from(dogx, dogy, sheepx, sheepy),
			dist = sim_distance_from(dogx, dogy, sheepx, sheepy);

		approach_speed(dist) -> speed;

        if left_line(target, target2, sheep) then
		 	rel_heading + get_adj(sim_myself) ->heading;
        else

			rel_heading - get_adj(sim_myself) ->heading;
        endif;
        move_dog(sim_myself, speed, heading)
    ]

RULE frontleft

    ;;; Turn the sheep to towards the mouth, from the left hand side.
    ;;; Ie aim to it's right.. Frontright is a variation of this.

    [target_sector frontleft]
        ==>
    [POP11
        lvars dist, speed, heading;

        sim_distance(sim_myself, sheep ) -> dist;

		approach_speed(dist) -> speed;

        sim_heading_from(
        	trial_coords(sim_myself),
        	trial_coords(sheep)) + get_adj(sim_myself) ->heading;

        move_dog(sim_myself, speed, heading)
    ]


RULE backleft
    [target_sector backleft]
    [WHERE sim_distance(sim_myself, sheep) < 120]
        ==>
    [POP11
        lvars dist, speed, heading;

        sim_distance(sim_myself, sheep) -> dist;

		approach_speed(dist) -> speed;

        sim_heading_from(
        	trial_coords(sim_myself),
        	trial_coords(sheep))
        		+ get_adj(sim_myself) -> heading;

        move_dog(sim_myself, speed, heading);
    ]

RULE frontright
    [target_sector frontright]
    [WHERE sim_distance(sim_myself, sheep) < 100]
        ==>
    [POP11
        lvars dist, speed, heading;

        sim_distance(sim_myself, sheep) -> dist;

		approach_speed(dist) -> speed;

        sim_heading_from(
        	trial_coords(sim_myself),
        	trial_coords(sheep))
			-get_adj(sim_myself) -> heading;

        move_dog(sim_myself, speed, heading);
    ]


RULE backright
    [target_sector backright]
    [WHERE sim_distance(sim_myself, sheep) < 100]
        ==>
    [POP11
        lvars dist, speed, heading;

        sim_distance(sim_myself, sheep ) -> dist;

		approach_speed(dist) -> speed;

        sim_heading_from(
	        trial_coords(sim_myself),
	        trial_coords(sheep) )
				- get_adj(sim_myself) -> heading;

        move_dog(sim_myself, speed, heading);
    ]


RULE traces

    ;;;tracing proc
        ==>
	[SAY steering]

enddefine;



/*
RULESET  : take
CREATED  : 29 Jul 1999
PURPOSE  : When the dog has arrived at the sheep, it must take it to the front...

*/

define :ruleset take;
	[DLOCAL [prb_allrules = false] ];
	[VARS [sheep = trial_current(sim_myself)]];

;;;Some Flipping Rules

RULE flipttotd
    [WHERE tree_detect(sim_myself)]
        ==>
	[SAY 'Switching to tree detection']
    [RESTORERULESET treedetection]

RULE flipttoj
	[OR
		[current []]
    	[behaviour join]
    	[side pen]
    	[target_sector near_sheep]
    	[WHERE
			istrial_agent(sheep) and sim_distance(sim_myself, sheep) > 100 ]
	]
        ==>
	[SAY 'switch to join - 4']
    [RESTORERULESET join]

RULE flipttos
    [behaviour steer]
        ==>
	[SAY 'switch to steer']
    [RESTORERULESET steer]

RULE inpen
	;;; in pen, so move out
    [side pen]
        ==>
    [SAY 'in pen']
    [POP11
        lvars speed, heading;

        dog_default_speed*0.5 -> speed;

        pen.orientation - 90 -> heading;
        move_dog( sim_myself, speed, heading );
    ]
	[SAY 'In pen -- moving out']

;;;At a distance...Approach the sheep directly

RULE noproblem
    [NOT target_sector on_target]
    [NOT target_sector near_sheep]
    [WHERE istrial_agent(sheep) and sim_distance(sim_myself, sheep) > 100 ]
        ==>
    [POP11
        lvars dist, speed, heading;
        sim_distance_from(
        	trial_coords(sim_myself), trial_coords(sheep) ) -> dist;

		approach_speed(dist) -> speed;

        sim_heading_from(
			trial_coords(sim_myself), trial_coords(sheep)
        		) -> heading;

	    move_dog(sim_myself, speed, heading);

    ]

RULE rearfrontleft

    [target_sector frontleft]
    [WHERE sim_distance(sim_myself, sheep) < 100]
        ==>
    [POP11
        lvars dist, speed, heading;
        sim_distance(sim_myself, sheep) -> dist;

		approach_speed(dist) -> speed;

        sim_heading_from(
        	trial_coords(sim_myself), trial_coords(sheep) )
			-> heading;

        move_dog(sim_myself, speed, heading);
    ]

RULE rearfrontright

    [target_sector frontright]
    [WHERE sim_distance(sim_myself, sheep) < 100]
        ==>
    [POP11
        lvars dist, speed, heading;
        sim_distance(sim_myself, sheep ) -> dist;

		approach_speed(dist) -> speed;

        sim_heading_from(
			trial_coords(sim_myself), trial_coords(sheep) )
				-> heading;

        move_dog(sim_myself, speed, heading);
    ]


RULE infront

    [target_sector infront]
    [WHERE sim_distance(sim_myself, sheep) < 100]
        ==>
    [POP11
        lvars speed, heading
			dist = sim_distance(sim_myself, sheep),
			rel_heading=
        		sim_heading_from(trial_coords(sim_myself), trial_coords(sheep));

		approach_speed(dist) -> speed;

        if quoi(sim_myself) then
		;;; [QUOI -]=>
			rel_heading - get_adj(sim_myself)
        else
		;;; [QUOI +]=>
			rel_heading + get_adj(sim_myself)
        endif -> heading;
        move_dog(sim_myself, speed, heading);
    ]


RULE rearbackleft

    [target_sector backleft]
    [WHERE sim_distance(sim_myself, sheep) < 100]
        ==>
    [POP11
        lvars dist, speed, heading;
        sim_distance(sim_myself, sheep ) -> dist;

		approach_speed(dist) -> speed;

        sim_heading_from(
        	trial_coords(sim_myself),
        	trial_coords(sheep) )
        		+ get_adj(sim_myself) -> heading;

        move_dog(sim_myself, speed, heading);
    ]
RULE rearbackright

    [target_sector backright]
    [WHERE sim_distance(sim_myself, sheep) < 100]
        ==>
    [POP11
        lvars dist, speed, heading;
        sim_distance(sim_myself, sheep ) -> dist;

		approach_speed(dist) -> speed;

        sim_heading_from(
        	trial_coords(sim_myself), trial_coords(sheep) )
        		- get_adj(sim_myself) -> heading;

        move_dog(sim_myself, speed, heading);
    ]

;;;Tracing rule.

RULE tracet
        ==>
	[SAY 'default take']
enddefine;


/*
RULESET  : treedetection
CREATED  : 29 Jul 1999

Tells the dog how to react to any troublesome trees

*/

define :ruleset treedetection;
	[DLOCAL [prb_allrules = false]];

	[LVARS
		[problem_tree = tree_detect(sim_myself)]
		[tree = sim_myself.trial_problemtree]
		[sheep = trial_current(sim_myself)]
	];

RULE flipstoj_fromtree
    [current []]
	==>
	[SAY 'Switch to join - []']
	;;; [PAUSE]
    [RESTORERULESET join]

RULE switchtdtos
    [behaviour steer]
    [WHERE not(problem_tree)]
    	==>
	[SAY 'Switch to steer']
	;;; [PAUSE]
    [RESTORERULESET steer]

RULE switchtdtot
    [behaviour take]
    [WHERE not(problem_tree)]
    	==>
	[SAY 'Switch to take 1']
	;;; [PAUSE]
    [RESTORERULESET take]

RULE switchtdtoj
    [behaviour join]
    [WHERE not(problem_tree)]
    	==>
	[SAY 'Switch to join - 1']
	;;; [PAUSE]
    [RESTORERULESET join]

RULE treefurther
    [WHERE
		problem_tree
		and istrial_agent(tree) and istrial_agent(sheep)
		and
		sim_distance(sim_myself, tree) > sim_distance(sim_myself, sheep) ]

    	==>

    [POP11
        lvars heading, speed,
			dist = sim_distance(sim_myself, tree);

		approach_speed(dist) -> speed;

		;;; if the tree is further should there be any heading change?
        sim_heading_from(
        	trial_coords(sim_myself), trial_coords(sheep)) -> heading;
			;;; 	- get_adj(sim_myself) ->heading;

        move_dog(sim_myself, speed, heading)
    ]

RULE treenearer
    [WHERE
		istrial_agent(tree) and istrial_agent(sheep)
		and
		sim_distance(sim_myself, tree) < sim_distance(sim_myself, sheep) ]
	
    	==>

    [POP11
        lvars
			heading,
			speed = dog_default_speed*0.5,
			tree_heading =
	        	sim_heading_from(trial_coords(sim_myself), trial_coords(tree));

		;;; target and target2 are locations in the pen
    	if left_line(target, target2, tree) then
			;;; [TREELEFT -75]=>
			tree_heading - 75
       	else
			;;; [TREERIGHT + 75]=>
			tree_heading + 75
        endif -> heading;

        move_dog(sim_myself, speed, heading)
    ]

enddefine;



/*
RULEFAMILY: dog_activity_rulecluster
CREATED  : 29 Jul 1999 TC
PURPOSE  : Rulefamily used so that the dog can only be engaged in
	one type of behaviour at any time
*/

define :rulefamily dog_activity_rulecluster;

    ruleset: join
    ruleset: steer
    ruleset: take
    ruleset: treedetection
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
		if berth < dist then
	        round(arcsin( berth / dist ) )
		else
			95		;;; ????? is this right? Added by A.S. 16 Jul 2000
		endif
			-> span;
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
    ;;; Ensures that last turn's movement causes changes in fatigue level
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
    [WHERE not(is_in_pen(sim_myself)
			and sim_distance(sim_myself, gromit) > 50)]
    ==>
    [DEL 2]
    [DEL 3]
    [LVARS speed weight]
    [POP11
        ;;; Calculate which direction to flee
        ( angle + trial_heading(sim_myself) + 180 ) mod 360 -> angle;

        ;;; Determine speed relative to how far away the dog is
        round(dist / 20.0) -> dist;
        10 - dist -> speed;

        ;;; If this is the most urgent action to date then update the urgency value
        if intof(dist/3.0)+1 < value then
            intof(dist/3.0)+1 -> value;
        endif;

        ;;; Calculate the weighting to associate with this action
		;;; make sure that dist is within range 1 to 8.
		max(1, min(8, dist)) -> dist;
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
    [Intent ?speed = ]
    [Hunger ?hunger]
	;;; Compare movement and eating intensities
	[WHERE speed < hunger]
    ==>
    [DEL 1 2]
	[Intent Eat]

    RULE resolve_movement_and_idling
    ;;; Since sheep cannot move and do nothing at the same time it will move
    [Idle]
    [Intent == ==]
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
        if list /== [] then
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



/*
RULESYSTEM: trial_dog_rulesystem
CREATED  : 29 Jul 1999 TC
*/

define :rulesystem trial_dog_rulesystem;
	[DLOCAL [prb_allrules = false]];

    debug = false;
    cycle_limit = 1;

;;;    include: dog_pen_rules
    include: find_new_sheep
    include: dog_perception_rules
    include: dog_target_rules
    include: dog_side_rules
    include: dog_sheepside_rules
    ;;; Not sure whether this should be included A.S.
    ;;; include: otherside_perception
    include: dog_tracing
    include: behaviour_rules
    include: dog_activity_rulecluster
    include: memory_testing
	include: forget_recent

enddefine;



define :rulesystem trial_sheep_rulesystem;
    [DLOCAL [prb_allrules = true ]];
    [LVARS my_name];
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


/*
SOME OTHER DOGS, if you want!!!!
	define :instance rover:trial_dog;
	enddefine;
	define :instance hound:trial_dog;
	enddefine;
	define :instance mutt:trial_dog;
	enddefine;
	define :instance ganzo:trial_dog;
	enddefine;
*/

;;; Now the trees
define :instance tree1:trial_tree;
enddefine;

define :instance tree2:trial_tree;
enddefine;

define :instance tree3:trial_tree;
enddefine;

define :instance tree4:trial_tree;
enddefine;

;;; Now the fence posts
/*
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

define :instance target:trial_target;
enddefine;
*/
define :instance pen:trial_pen;
enddefine;

;;; Collect all participating agents into a list of names of the
;;; agents, later replaced by the class instances, inside procedure sheep_setup

[
 ;;; the sheep
 sheepy sleepy sneezy bashful doc

 ;;; The dog
 gromit ;;;rover hound mutt ganzo

 ;;; The trees
 tree1 tree2 tree3 tree4

 ;;; The target
 target

 ;;; Now posts making up the pen
 post1 post2 post3 post4 post5 post6
 post7 post8 post9 post10

] -> all_agents;



/*
-- Procedurs for setting up and running the demo
*/

define :method rc_add_pic_to_window(pic:trial_obstacle, win_obj:rc_window_object, atfront);
	;;; make the window mouse sensitive
	if rc_event_types(win_obj) == [] then
		rc_mousepic(win_obj)
	endif;

	rc_do_addpic_to_window(pic, win_obj, atfront);
enddefine;

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
        sheep_window_x, sheep_window_y,
        sheep_window_xsize, sheep_window_ysize, true, 'Sheep') -> sheep_win;

    ;;; Make the window mouse sensitive
    rc_mousepic(sheep_win);


    ;;;{^false ^false sheep_button_3_up};
	"sheep_button_3_up" -> rc_button_up_handlers(sheep_win)(3);

    set_coords(pen, 0, 0);
    random(360)->pen.orientation;
    setup_pen(pen);
    ;;; create the agents
    maplist(all_agents,
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

			;;;if isrc_selectable(a) then
	            ;;; tell the window about it
	            rc_add_pic_to_window(a, sheep_win, true);
			;;;endif;

        endprocedure) -> all_agents;

    ;;; Define the starting positions and headings for each agent

    ;;; first the sheep
    set_random_status( sheepy, pen.locx, pen.locy + 100 );
    set_random_status( sleepy, pen.locx, pen.locy + 120 );
    set_random_status( sneezy, pen.locx, pen.locy + 140 );
    set_random_status( bashful, pen.locx, pen.locy + 160 );
    set_random_status( doc, pen.locx, pen.locy + 180 );

    ;;;set_status(target, 140, 0, 0);
    ;;; then the dog
    ;;;set_status( rover, -180, -100, 0);
    set_random_status( gromit, pen.locx, pen.locy + 200 );
    ;;;set_random_status( hound, pen.locx, pen.locy + 200 );
    ;;;set_random_status( mutt, pen.locx, pen.locy + 200 );
    ;;;set_random_status( ganzo, pen.locx, pen.locy + 200 );
    ;;; the posts
    /*
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
    */
    ;;; the tree

    set_random_status( tree1, pen.locx-100, pen.locy + 120 );
    set_random_status( tree2, pen.locx, pen.locy + 115 );
    set_random_status( tree3, pen.locx -30, pen.locy - 150 );
    set_random_status( tree4, pen.locx, pen.locy -200 );
    true -> sheep_setup_done;
enddefine;



define killsheepwindows();
    ;;; Get rid of windows.
    false -> rc_current_window_object;

    if not(isundef(sheep_win)) and rc_widget(sheep_win) then
        rc_kill_window_object(sheep_win);
    endif;

    if not(isundef(sheep_control_panel)) and rc_widget(sheep_control_panel) then
        rc_kill_window_object(sheep_control_panel);
    endif;


enddefine;

define sheepdog_panel();
    ;;; This sets up the main control panel

	if rc_islive_window_object(sheep_control_panel) then
     	rc_kill_window_object(sheep_control_panel);
 	endif;

    rc_control_panel("left", "bottom",
        [
			;;; added by AS to prevent spurious move effects. 7 Oct 2000
			;;; See HELP rc_control_panel
    		{events [button motion]}

            {font '8x13bold'}       ;;; font specification
            {bg 'black'}            ;;; background black  (try brown)
            {fg 'white'}            ;;; foreground white  (try yellow)
            ;;; try {cols 2}
            [TEXT : 'Sheepdog Controls']
            ;;; Now button definitions.
            [ACTIONS
				{width 120}
                {cols 1}        ;;; orientation vertical, 2 columns
                {bg 'grey20'}:
                ['START'
					[POP11 false -> sheep_stopped ;
                        sheep_win->rc_current_window_object;
						;;; Added AS 7 Oct 2000
						;;; prevent interference by mouse moves
						true -> rc_drag_only(sheep_win);
						rc_async_apply(run_sheep(%20000%), true);
                        ]]
                ['STOP' [POPNOW true -> sheep_stopped]]
				['SLOW DOWN' [POP11 sim_sheep_delay + 1 -> sim_sheep_delay]]
				['SPEED UP'
					[POP11 max(-1, sim_sheep_delay) - 1 -> sim_sheep_delay]]
            ]


            [TEXT
            {gap 2}:
            'Window Management:' ]

            [ACTIONS
				{width 120}
                {cols 1}:
                ['Redraw Window'
					[DEFER POP11 dlocal rc_in_event_handler = true;
                        rc_redraw_window_object(sheep_win)
                    ]]

                ['DISMISS PANEL'
					[POP11
                        true -> sheep_stopped;
                        rc_hide_panel();
					]]

				['DISMISS SHEEPWIN'
					[POP11
                        true -> sheep_stopped;

        				rc_kill_window_object(sheep_win);
					]]

                ['Kill Windows'
                    [POP11
                        true -> sheep_stopped;
                        killsheepwindows();
					]]
            ]
        ],
    'Control Panel') -> sheep_control_panel;
enddefine;

define run_sheep(n);
    dlocal
        sheep_stopped = false,
        ;
    unless sheep_setup_done then
        sheep_setup();
;;;	endunless;

    applist(all_agents, sim_setup);

	sheepdog_panel();

;;;    unless sheep_setup_done then
        printf('\nUse the mouse to rearrange the sheep, the green trees,');
        printf('\nand the dog,');
        printf('\nthen press RETURN to start the demo.');
        printf('\nPress button 3 in the window to stop.\n');
        readline() ->;
    endunless;

    sim_scheduler(all_agents, n);

	pr('\nrun_sheep('><n><');');
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
run_sheep(20000);
*/

/*
-- Instructions to be printed out
*/

printf('\nThen use mouse button 1 to rearrange items on the field\n');
printf('\nTo run for 20000 time steps do the following:');
printf('\nand use mouse button 3 to STOP or RESTART\n\t run_sheep(20000);\n');

/*
-- Index of classes, methods, procedures, rulesets, etc.

To rebuild this index, do: ENTER indexify define

CONTENTS - (Use <ENTER> gg to access required sections)

 define :class trial_agent;
 define :class trial_sheep; is trial_agent rc_selectable ;
 define :class trial_dog;
 define :class trial_obstacle;
 define :class trial_tree;
 define :class trial_post;
 define :class trial_target;
 define :class trial_pen;
 define :method sim_agent_running_trace(object:trial_agent);
 define :method sim_agent_messages_out_trace(agent:trial_agent);
 define :method sim_agent_messages_in_trace(agent:trial_agent);
 define :method sim_agent_actions_out_trace(object:trial_agent);
 define :method sim_agent_rulefamily_trace(object:trial_agent, rulefamily);
 define :method sim_agent_rulefamily_trace(object:trial_dog, rulefamily);
 define :method sim_agent_endrun_trace(object:trial_agent);
 define :method sim_agent_terminated_trace(object:trial_agent, number_run, runs, max_cycles);
 define vars procedure sim_scheduler_pausing_trace(objects, cycle);
 define vars procedure sim_post_cycle_actions(objects, cycle);
 define trial_coords(t) /* -> (x, y)*/;
 define agent_now_at(agent, xloc, yloc) -> boole;
 define approach_speed(dist) -> newspeed;
 define :method set_coords(pen:trial_pen, x, y);
 define rotate_by(ang,oldx,oldy) -> (newx,newy);
 define :method set_heading(agent:trial_agent, heading);
 define :method set_status(agent:trial_agent, x, y, heading);
 define set_random_status(obj, x,y);
 define :method set_rel_status(pen:trial_pen, post, addx, addy);
 define :method setup_pen(pen:trial_pen);
 define :method make_post_list(agent:trial_dog, objects) -> list;
 define :method make_tree_list(agent:trial_dog, objects) -> list;
 define sim_direction(x1,y1,x2,y2) -> heading;
 define sim_direction_two(x1,y1,x2,y2);
 define rel_direction(x1,y1,x2,y2,x3,y3) -> rel_dir;
 define :method sim_distance(a1:trial_agent, a2:trial_agent) -> dist;
 define :method get_pen_limits(agent:trial_dog) -> (lower, higher);
 define :method sect(agent:trial_dog) -> sector;
 define left_line_tolerance(lp1, lp2, obj, tolerance) -> boole;
 define left_line(lp1, lp2, obj) -> boole;
 define pen_sector(object)->ps;
 define :method closest_angle_to(agent:trial_dog) -> ang;
 define :method close_angle_to(agent:trial_dog) -> (ang, dpost);
 define :method get_deshead(agent:trial_dog) -> heading;
 define :method in_pen(agent:trial_dog) -> boole;
 define :method am_in_front(agent:trial_dog)-> boole;
 define :method current_in_front(agent:trial_dog)->boole;
 define tree_range(agent, tree) -> (upper, lower);
 define :method tree_detect(agent:trial_dog) -> answer;
 define :method get_adj(agent:trial_dog) -> ang;
 define :method agent_bearing( agent:trial_agent, target:trial_agent) -> result;
 define weighted_sum(components) -> (sumx, sumy, sumw);
 define :method collision_course(bearing, arc) -> result;
 define check_range( pair1, pair2, diff) -> result;
 define compare_ranges( base, test ) -> (result,altered);
 define obscured_ranges(range_list) -> result;
 define get_range( heading, choice_list) -> result;
 define :method print_instance(item:trial_sheep);
 define :method print_instance(item:trial_dog);
 define :method print_instance(item:trial_obstacle);
 define :method resting(agent:trial_sheep);
 define :method quoi(agent:trial_dog) -> boole;
 define :method wise(agent:trial_dog);
 define :method sheep_graze(agent:trial_sheep);
 define :method exercise( agent:trial_sheep);
 define :method forward(agent:trial_agent, speed);
 define :method set_rel_heading(agent:trial_dog, relheading);
 define :method move( agent:trial_sheep, bearing, speed );
 define :method move_dog(agent:trial_dog, speed, bearing);
 define :method wander(agent:trial_sheep);
 define close_to_pen(object, tolerance) -> boole;
 define is_in_pen(object);
 define :method make_sheep_list(agent:trial_dog, objects)->list;
 define same_side_of_line(lp1, lp2, o1, o2);
 define :method get_outside_posts(agent:trial_dog)-> (hpost, lpost);
 define :method in_front_of_pen(agent:trial_dog) -> boole;
 define :method behind_pen(agent:trial_dog) -> boole;
 define :method sim_sense_agent(a1:sim_object, a2:sim_object, dist);
 define :method sim_run_agent(agent:trial_sheep, agents);
 define :method sim_run_agent(agent:trial_dog, agents);
 define :method sheep_button_1_up(pic:rc_window_object, x, y, modifiers);
 define :method sheep_button_3_up(pic:rc_window_object, x, y, modifiers);
 define :method rc_button_1_down(pic:trial_agent, x, y, modifiers);
 define :method rc_button_1_up(pic:rc_selectable, x, y, modifiers);
 define :method rc_button_1_drag(pic:trial_agent, x, y, modifiers);
 define :ruleset dog_perception_rules;
 define :ruleset dog_target_rules;
 define :ruleset behaviour_rules;
 define :ruleset dog_side_rules;
 define :ruleset dog_sheepside_rules;
 define :ruleset dog_pen_rules;
 define :ruleset dog_tracing;
 define :ruleset find_new_sheep;
 define :ruleset otherside_perception;
 define :ruleset memory_testing;
 define :ruleset forget_recent;
 define :ruleset join;
 define :ruleset steer;
 define :ruleset take;
 define :ruleset treedetection;
 define :rulefamily dog_activity_rulecluster;
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
 define :instance tree3:trial_tree;
 define :instance tree4:trial_tree;
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
 define :instance target:trial_target;
 define :instance pen:trial_pen;
 define :method rc_add_pic_to_window(pic:trial_obstacle, win_obj:rc_window_object, atfront);
 define sheep_setup();
 define killsheepwindows();
 define sheepdog_panel();
 define run_sheep(n);

*/

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Aug 28 2003
	Changes to create control panel, e.g. to alter speed
--- Aaron Sloman, 19 May 2002
	A syntactic test added to poprulebase revealed some spurious closing
	parentheses in some conditions. Fixed.
--- Aaron Sloman, Jan 29 2001
	Following a suggestion of Brian logan, made button 3 restart
	the demo.
--- Aaron Sloman, Jul 19 2000
	Made it stop when all sheep detected. More rationalisation of code.
--- Aaron Sloman, Jul 17 2000
	Removed demo_running global variable. Additional tidying up.
	Still more to do.
--- Aaron Sloman, Jul 16 2000
	Fixed many minor bugs, and did a lot of reorganising and cleaning up
	Fixed dragging problem by fixing button_1_down method.
--- Aaron Sloman, Jul 15 2000
	Made the "targets" invisible.
	Made the dog use a database for counter
	Replaced sheep_agents with all_agents, as a step towards change
	to using sim_harness

--- Aaron Sloman, Jul  8 2000
	Made bits of the pen non-selectable
	Removed some redundant code.
	Reduced default size of window, to fit on smaller displays, e.g. 1024x768
	Introduced sim_agentsleep, with default value 1, and changed the method
	sim_agent_endrun_trace(object:trial_agent) to pause 50% of the time if
	the value is not 0.

--- A.Sloman 11 Nov 1999
	Changed to slow down dog near sheep

--- Tom Carter May - September 1999
    Added intelligent rulesets for the dog

--- Previous revision history from TEACH sim_sheep.p
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

--- $poplocal/local/newkit/sim/demo/sim_sheepdog.p
--- Copyright University of Birmingham 2002. All rights reserved. ------

 */
