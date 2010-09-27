/*
TEACH SIM_SHEEPDOG.P                           Marek Kopicki et al. Dec 2003
*/
/* --- Copyright University of Birmingham 2004. All rights reserved. ------
 > File:            $poplocal/local/newkit/sim/lib/hybrid_sheepdog.p
 > Purpose:			Demonstrate sim_agent toolkit with sheepdog scenario
					This is an extended version of the sim_sheepdog.p
					program, with deliberative capabilities added.
 > Author:          Marek Kopicki
					Building on work by Peter Waudby, Tom Carter and
					Aaron Sloman
 > Documentation: 	See below
					See also
						http://www.cs.bham.ac.uk/research/cogaff/0-INDEX04.html
						http://www.cs.bham.ac.uk/~axs/cogaff/simagent.html
						http://www.cs.bham.ac.uk/research/cogaff/talks/#simagent
 > Related Files:   TEACH sim_sheepdog.p TEACH sim_sheep.p
					TEACH sim_agent, HELP sim_agent, TEACH sim_feelings
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
					Dean Petters produced a version in Sept 2001 in which
						the dog could move several sheep at once.
					Marek Kopicki Dec 29 2003
						A new paradigm - agent planning

*/

/*

         CONTENTS - (Use <ENTER> g to access required sections)


 -- Introduction and acknowledgement
 -- Running the demo
 -- More detailed overview
 -- Load libraries required
 -- Global variables and constants
 -- Agent class definitions
 -- Helper class definitions
 -- Printing methods for classes
 -- Window utility methods
 -- Miscellaneous functions for transformation of coordinates
 -- Routines for path checking
 -- Routines for graph search algorithm
 -- Routines operating on waypoints
 -- Routines for visualization of planning algorithms
 -- Miscellaneous utility methods of Pen, Dog and trial_sheep classes
 -- Rulesets and rulefamily for dog
 -- Rulesystem for dog
 -- Default tracing routines
 -- Utility functions and methods for sheep
 -- The action routines for sheep
 -- Redefined sim_run_agent for sheep
 -- Button and drag methods for empty window space
 -- Button and drag methods for objects
 -- Rulesets and rulefamily for sheep
 -- Rulesystem for sheep
 -- Procedurs for setting up and running the demo
 -- Instructions to be printed out
 -- Index of classes, methods, procedures, rulesets, etc.
 -- Revision notes

-- Introduction and acknowledgement

This file is based on Tom Carter's 1999 MSc summer project, which in
turn is based upon a previous summer project by Peter Waudby, which had
subsequently been updated by Aaron Sloman. Tom Carter's version is
included in the SimAgent toolkit as TEACH sim_sheepdog.p


Peter Waudby's original version was developed while the Sim_agent
toolkit and the graphical RCLIB toolkit were still in fairly early
stages of development. So some of it has since been reimplemented
using the current toolkit facilities. The original version is still
available as TEACH sim_sheep.p

-- Running the demo

To run the initial file type <ENTER> l1 <RETURN>

Instructions will be printed.

then <ESC> D on the line

	run_sheep(20000)


-- More detailed overview

To run this demo compile the file (ENTER l1), which will print out
instructions. There are two procedures.

    sheep_setup();

Starts the initial scenario as specified by the agent definitions below.

After the picture is complete mouse button 1 (left) can be used to move
the objects to form a new configuration, including the dog (circle with
small triangle and tail), the sheep (large and small circle) the trees
(large circles), and the posts forming the sheep pen (medium circles).

To get the program running then do this (possibly with a larger number
for a longer run.

     run_sheep(20000);

If you have not previously run sheep_setup, this will run it for
you then pause to allow rearrangement, after which you should press
RETURN.

The number specifies the number of cycles of the main interpreter (the
number of simulated time steps). If you still have not got the sheep into
the pen by the end, you can repeat that command.

To stop the program before it has finished press button 3. You can re-start
any time by re-doing the run_sheep command.

The sheep are represented by two circles, one smaller than the other.

The dog is the circular object with a triangular "nose" and a tail. It will
sequentially herd the sheep into the pen of its own accord.

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
-- Global variables and constants

Some parameters reduced by A.Sloman to work on smaller screens.
*/

global vars

    ;;; Window parameters
    ;;; location of demo window
    sheep_window_x = "right",
    sheep_window_y = "top",
    ;;; Width and height of window
    ;;;     (Change if required)
    sheep_window_xsize = 850,
    sheep_window_ysize = 750,
	;;; The window (instance of rc_window_object)
    sheep_win,
	sheep_control_panel,
    ;;; Size of selectable box in mouse-movable objects (40x40 square)
    ;;; default value for rc_mouse_limit
    rc_select_distance = {-15 -15 15 15},
    ;;; Made true by mouse button 3
    sheep_stopped = false,
	;;; set to 0 for maxmim speed. Increase to slow demo down
	sim_agentsleep = 0,

	;;; Parameters used for initialization of agents in disperseAgents()
	;;; Minimal distance from the pen
	agentRMin = 100,
	;;; Width of the area around the pen
	agentRWidth = 250,
	;;; Minimal distance to any other agents
	agentSpace = 30,
	
	;;; Size of agents and generated path
	agentDfltSize = 10,
	treeDfltSize = 15,
	postDfltSize = 9,
	;;; Minimal width of path (excluding agent and obstacle size)
    pathWidthMin = 10,
	;;; Minimal width of "passage" to waypoint (excluding agent and obstacle size)
    waypointWidthMin = pathWidthMin,

    ;;; Parameters used by path checking algorithms
	;;; Maximal size of obstacle
	searchDO = treeDfltSize,
	;;; Maximal size of agent
	searchDA = agentDfltSize,
	;;; Minimal width of path (excluding obstacle size)
	searchDAPath = searchDA + pathWidthMin,
	;;; Minimal width of "passage" to waypoint (excluding obstacle size)
	searchDAWaypoint = searchDA + waypointWidthMin,

	;;; Parameters used by probabilistic roadmap rutines and search algorithm
	;;; Maximum number of nodes (waypoints) of a search graph
	waypointMax = 250,
	;;; Number of generated waypoints per obstacle for global and local planner
	waypointGenNum = 2,
	waypointGenLocalNum = 2,
	;;; Number of generated waypoints around searched sheep
	waypointGenSheepNum = 5,
	;;; Minimal distance of generated waypoints to obstacles
	;;; for global and local planner
	waypointORLocalMin = searchDA,
	waypointORMin = searchDO + searchDA,
	;;; Minimal width of an area for global planner
	waypointORWidth = 6*pathWidthMin,
	;;; Minimal "cost" distance between waypoints on path
	waypointCostDelta = 5.0,
	;;; Search horizon for waypoints
	;;; Increased by A.S. to improve 'opportunism'
	waypointSearchHorizon = 150,

	;;; Parameters of visualisation procedures
	showVertices = true,
	showEdges = true,
	showDirection = true,
	;;; Maximum number of vertices of displayed graph and its colour
	vertexMax = waypointMax,
	vertexColour = 'dark violet',
	;;; Maximum number of edges of displayed path and its colour
	edgeMax = 50,
	edgeColour = 'gold',
	;;; A colour of a line displaying move direction
	directionColour = 'aquamarine',
	
    ;;; Sheep profile
    ;;; A global array to contain precalculated values used to determine
    ;;; how a perceived object's importance varies with distance.
    ;;; Importance associated with an object decreases exponentially
    ;;; with distance. (Peter Waudby)
    procedure zone_weighting =
        newarray([1 8], procedure(x); round(100*2**(-x+1)) endprocedure),
    ;;; If this variable is given a number > 0 that will slow
    ;;; down the running of the program.
	sim_sheep_delay = 10,
	;;; Put upper limit on sheep speed (added 16 Nov 2003)
	max_sheep_speed = 4,
    ;;; Set the maximum visual range of the sheep
    sheep_visual_range = 150,
	;;; Minimal "safe" distance to dog controlled by integer factor
	sheepSafeDistFac = 3,
	sheepSafeDistMin = sheep_visual_range/sheepSafeDistFac,
	;;; "Disperse" parameters used by moveSheep()
	sheepDispAngleDelta = 15,
	sheepDispAngleSteps = 7,

    ;;; Dog profile
    ;;; Visual range
	;;; Increased by A.Sloman to improve dog's reactive responses
    dogVisualRange = 200,
    ;;; Optimal and maximal distance to steered sheep
    dogSheepDist = 30,
    dogSheepDistMax = 70,
    ;;; Minimal distance to obstacles
    dogObstacleDistMin = 5,
    ;;; Maximal number of local planning trials
    dogPlanLocalTrials = 5,
    ;;; Minimal and maximal speed of movement
    dogSpeedMin = 1,
    dogSpeedMax = 10,
    ;;; Optimal steering speed
    dogSheepSteerSpeed = max_sheep_speed - 1,
    ;;; Maximal level of barking <0..dogBarkMax>
    dogBarkMax = 4,
    ;;; Minimal "threshold" distance to a current waypoint
    ;;; for Find and Steer activities.
	dogFindDistMin = searchDAPath - searchDAWaypoint + 1,
	dogSteerDistMin = searchDAPath - searchDAWaypoint + max_sheep_speed,

	;;; These globals are left for sake of compatibility to the old demo version
    ;;; the dog and the pen
    Miszka, ;;; my dog name ;-)
    pen,
	;;; declaration of rulesystems
    trial_sheep_rulesystem,
    rulesystemDog,
    ;;; In case recompiling, get rid of old agents. Prepare global list.
    all_agents = [],
    ;

constant
	INF = 32767,
	IDX_ROOT = 1,
	IDX_GOAL = 2,
	;
	
/*
-- Agent class definitions
*/

;;; The base class for all agents in the trial
define :class trial_agent;
    is rc_rotatable_picsonly	;;; Rotatable, but don't rotate strings
	   rc_linepic_movable rc_selectable sim_agent;

    slot trial_size == agentDfltSize;          ;;; The agent's physical size
    slot rc_picx == 0;              ;;; The x and y coordinates of the agent
    slot rc_picy == 0;              ;;; within the environment and picture
    slot sim_sensors = [];          ;;; List of which senses the agent has
	slot sim_name = false;

    ;;; a vector defining a box for mouse sensitivity
    slot rc_mouse_limit = rc_select_distance;
enddefine;


define :class Animal;
	is trial_agent;

enddefine;


define :class trial_sheep;
	is Animal;
    ;;; The class defining the sheep's attributes

    slot trial_heading == 0;        ;;; Which way the agent is pointing

    ;;; Maybe some of these should be randomised?
    slot trial_hunger == 1;         ;;; Between 0 (stuffed) and 3 (starving)
    slot trial_fatigue == 20;       ;;; Between 0 (fresh) and 100 (knackered)
    slot trial_speed == 0;          ;;; Speed = distance travelled per move
    slot trial_pspace == 30;        ;;; Limit of sheep's personal space
    slot trial_pack_range == 60;    ;;; Max satisfactory distance from other sheep
    slot trial_flock_range == 100;  ;;; Max range whilst remaining in flock
    slot trial_obstacle_range == 40; ;;; Distance when obstacles are first noticed


	;;; Appearance changed, A.S. 16 Nov 2003
    slot rc_pic_lines ==            ;;; What the sheep look like
          [
        	[rc_draw_blob {0 0  10 'pink'} {13 0 5 'red'}]
          ];

    slot sim_rulesystem = trial_sheep_rulesystem;   ;;; Which rules to follow
    slot sim_sensors = [{sim_sense_agent ^sheep_visual_range}]; ;;; Defines senses

	;;; make sheep a bit harder to move
    slot rc_mouse_limit = rc_select_distance;
enddefine;


define :class Dog;
	is	Animal;

	;;; Appearance changed, A.S. 16 Nov 2003
    slot rc_pic_lines =            ;;; What the dog look like
		[
			[rc_draw_filled_triangle {12 9 12 -9 20 0 'black'}] ;;; head
			[rc_draw_blob {0 0  12 'brown'}]	;;; circular body
			[rc_drawline_relative {-12 0 -19 0 'black' 3}]	;;; tail
		];

    slot sim_rulesystem = rulesystemDog;

	;;; An array of graph nodes
	slot wpGList == false;
	slot wpGNum = 0;
	;;; A waypoint array which constitutes a path
	slot wpPList = false;
	slot wpPNum = 0;
	;;; A temporary waypoint array used in calculations
	slot wpTmpList = false;
	slot wpTmpNum = 0;
	
	;;; Visual objects lists
	;;; Vertices of a graph
	slot vtList = false;
	slot vtNum = 0;
	;;; Edges of a graph defining a path to a goal
	slot edList = false;
	slot edNum = 0;
	slot direction = false;
	
	;;; Dog profile
	slot visualRange = dogVisualRange;
	slot speed = 0;
	slot bark = 0;
	;;; Not used yet
	slot fatigue = 0;
	slot mood = 0;

	;;; A pointer to current root and goal
	slot currentRoot = false;
	slot currentGoal = false;
	;;; List of all obstacles
	slot obstacleList = [];
	;;; List of all local (within visual range) obstacles visible from
	;;; the dog and a current sheep perspectives
	slot obstacleLocalListDog = [];
	slot obstacleLocalListSheep = [];
	
	;;; Pointer to the pen
	slot sheepPen = false;
	;;; List of all sheep staying out of the pen
	slot sheepOutOfPenList = [];
	;;; Pointer to a current sheep, and
	slot sheepCurrent = false;
	;;; its recent coordinates,
	slot sheepCurrentX = 0;
	slot sheepCurrentY = 0;
	;;; distance,
	slot sheepCurrentDist = 0;
	;;; speed, and
	slot sheepCurrentSpeed = 0;
	;;; "visibility" (false if there is no direct, not obscured path to it)
	slot sheepCurrentVisible = false;

	;;; Components used by the dog during its activities
	;;; Every time the dog starts a new activity a timer is reset
	slot timer = 0;
	;;; If the dog encounters a path problem sets this variable to
	;;; a current timer value
	slot pathProblemTm = 0;
	;;; Plan index is a "merging" waypoint between old and new local path
	slot wpIdx = 0;
enddefine;


define :class Obstacle;
	is trial_agent;
	
enddefine;


define :class Tree;
	is	Obstacle;
	
    ;;; Trees are larger than the sheep
    slot trial_size == treeDfltSize;

	;;; Appearance changed, A.S. 16 Nov 2003
    slot rc_pic_lines ==
		[
			[rc_draw_blob {0 0  16 'green'}]
			[rc_draw_bar  {-3 -16 10 8 'brown'}]
		];

    slot sim_name = gensym("Tree");
enddefine;


define :mixin immobile;
	;;; for things that don't move and cannot be moved, e.g. pen posts.
enddefine;


define :class Post;
	is	Obstacle
		immobile;

    ;;; Posts are smaller than the sheep
    slot trial_size == postDfltSize;
    slot rc_pic_lines ==
		[
			WIDTH 5 COLOUR 'blue'	;;; increased to 5 16 Nov 2003
			[CIRCLE {0 0 9}]
		];

    slot sim_name = gensym("Post");
enddefine;


/*
-- Helper class definitions
*/

define :class Pen;

    slot size = 50;
    slot rc_picx = 0;
    slot rc_picy = 0;
    slot orientation = 0;
enddefine;

define :class Waypoint;
	;;; Coordinates of this waypoint
    slot x = 0;
    slot y = 0;
    ;;; Cost of reaching a current goal from the waypoint
    slot cost = 0;
    ;;; This component indicates if the waypoint belongs to a graph
    slot isNode = false;
enddefine;

define :class VisualObj;
    is	rc_rotatable_picsonly
		rc_linepic_movable
		rc_selectable;

    slot rc_picx = 0;
    slot rc_picy = 0;
    slot rc_pic_lines = [];
    slot name = false;
enddefine;

;;; Represents a path area between two waypoints. The path area consists of
;;; two parts: a rectangular one defined by 4 linear equations, and
;;; a circular one defined by a pair of coordinates and a square of radius.
define :class Path;
	;;; Parameters of 4 equations of a path area edges: fn(x) = an*x + bn
    slot a1 = 0;
    slot b1 = 0;
    slot a2 = 0;
    slot b2 = 0;
    slot a3 = 0;
    slot b3 = 0;
    slot a4 = 0;
    slot b4 = 0;
    ;;; Coordinates of a destination waypoint and
    ;;; a square of radius of a circular part
    slot x  = 0;
    slot y  = 0;
    slot rr = 0;
    ;;; True if the path area is an "inclined" rectangle
    slot isInclined = false;
enddefine;


/*
-- Printing methods for classes
*/

define :method print_instance(this:Animal);
    ;;; Used to control the info printed for Animals

	dlocal pop_pr_places = 0;
	printf(
		'<%P at (%P %P)>',
		[%this.sim_name, this.rc_picx, this.rc_picy%])
enddefine;

define :method print_instance(this:Obstacle);
    ;;; Used to control the info printed for Obstacles

	dlocal pop_pr_places = 0;
    printf(
		'<%P at (%P %P)>',
		[%this.sim_name, this.rc_picx, this.rc_picy%])
enddefine;

define :method print_instance(this:Waypoint);
    dlocal pop_pr_places = 0;

	printf(
		'<Waypoint at (%P %P) cost=%P isNode=%P>',
		[%this.x, this.y, this.cost, this.isNode%]);
enddefine;

/*
-- Window utility methods
*/

define :method rc_move_to(this:trial_agent, x, y, boole);
    dlocal rc_in_event_handler;
    if rc_in_event_handler then

		;;; run it later.
        rc_defer_apply(rc_move_to(%this, x, y, boole%))

    else
        ;;; run any deferred events
        rc_run_deferred_events();

		true -> rc_in_event_handler;
        call_next_method(this, x, y, boole);

    endif;
enddefine;

define :method rc_set_axis(this:trial_agent, heading, boole);
    dlocal rc_in_event_handler;
    if rc_in_event_handler then

		;;; run it later.
        rc_defer_apply(rc_set_axis(%this, heading, boole%))

    else
        ;;; run any deferred events
        rc_run_deferred_events();

		true -> rc_in_event_handler;
        call_next_method(this, heading, boole);

    endif;
enddefine;

define :method getCoords(this:rc_linepic) -> (x, y);
    this.rc_picx, this.rc_picy -> (x, y);
enddefine;

define :method getCoords(this:Pen) -> (x, y);
    this.rc_picx, this.rc_picy -> (x, y);
enddefine;

define :method getCoords(this:Waypoint) -> (x1, y1);
    this.x, this.y -> (x1, y1);
enddefine;

define addAgentToWindow(inList, winObj) -> outList;
    maplist(inList,
        procedure(word) -> a;
			if isword(word) then valof(word) else word endif -> a;
			;;; give the agent its name
			if not(sim_name(a)) then
				word -> sim_name(a);
			endif;
			
			;;; tell the window about it
			if rc_event_types(winObj) == [] then
				rc_mousepic(winObj)
			endif;
			rc_do_addpic_to_window(a, winObj, true);
			
			rc_move_to(a, getCoords(a), true);
        endprocedure) -> outList;
enddefine;

/*
-- Miscellaneous functions for transformation of coordinates
*/

define getDistance(o1, o2) -> d;
	sim_distance_from(getCoords(o1), getCoords(o2)) -> d;
enddefine;

;;; Transforms polar coordinates into cartesian ones
define radialFunc(a, r) -> (x, y);
	r*cos(a), r*sin(a) -> (x, y);
enddefine;

;;; Transforms cartesian coordinates into polar ones
define radialFuncInv(x, y) -> (a, r);
	arctan2(x, y), sqrt(x*x + y*y) -> (a, r);
enddefine;

define distribLinear(rMin, rWidth) -> x;
	rMin + random(rWidth) -> x;
enddefine;

define distribSquare(rMin, rWidth) -> x;
	lvars w = random(rWidth*rWidth);
	rMin + sqrt(w) -> x;
enddefine;

;;; Generates a random point within (rMin, rMin + rWidth) circular area with
;;; uniform probability density.
define generatePoint(rMin, rWidth) -> (x, y);
	lvars a, r;

	distribLinear(0, 360) -> a;
	distribSquare(rMin, rWidth) -> r;
	radialFunc(a, r) -> (x, y);
enddefine;

;;; Checks if a point (x, y) lies closer than r to any obstacle from list.
define collisionCheck(list, x, y, r) -> bool;
	lvars o;

	false -> bool;
	for o in list do
		if sim_distance_from(getCoords(o), x, y) < o.trial_size + r then
			true -> bool;
			return();
		endif;
	endfor;
enddefine;

;;; Transforms objects from inList:
;;; 1) rotate by aInitTrn angle
;;; 2) move to a position defined by polar coords (aTrn, rTrn)
;;; and then stores transformed objects on outList
define trnAgentList(inList, aInitTrn, aTrn, rTrn) -> outList;
	lvars a, r, x, y, xTrn, yTrn;

	radialFunc(aTrn, rTrn) -> (xTrn, yTrn);
    maplist(inList,
		procedure(inObj) -> outObj;
			if isword(inObj) then valof(inObj) else inObj endif -> outObj;

			radialFuncInv(getCoords(outObj)) -> (a, r);
			radialFunc((a + aInitTrn) mod 360, r) -> (x, y);
			rc_move_to(outObj, x + xTrn, y + yTrn, false);
		endprocedure) -> outList;
enddefine;

;;; Spreads uniformly objects from inList within (rMin, rMin + rWidth)
;;; circular area avoiding obstacles from oList, and
;;; stores transformed objects on outList.
define disperseAgents(rMin, rWidth, aList, oList) -> outList;
	lvars list, o, a, r, x, y;

	aList -> outList;
	[] -> list;

	for o in aList do
		valof(o) -> o;
		while true do
			distribLinear(0, 360) -> a;
			distribSquare(rMin, rWidth) -> r;
			radialFunc(a, r) -> (x, y);
			round(x), round(y) -> (o.rc_picx, o.rc_picy);
			if	not(collisionCheck(oList, getCoords(o), agentSpace)) and
				not(collisionCheck(list, getCoords(o), agentSpace))
			then
				[^o] <> list -> list;
				quitloop(1);
			endif;
		endwhile;
	endfor;
enddefine;

/*
-- Routines for path checking
*/

;;; Creates a path area defined by coordinates of two waypoints and parameter r,
;;; where r is a "width" of a path or a radius of a circular part of a path.
define :method create(
	p:Path,
	x1, y1,
	x2, y2,
	r);
	
	lvars dx, dy, tmp;
	
	;;; {x1, y1, x2, y2} must be integers
	round(x1), round(y1), round(x2), round(y2) -> (x1, y1, x2, y2);
	;;; Store coordinates of a destination waypoint and
	;;; a square of a "width" of a path
	x2, y2, r*r -> (p.x, p.y, p.rr);
	
	;;; Perform a transformation of an area
	;;; There can be 4 cases of non inclined rectangular path, and
	;;; 4 cases of inclined one
	
	if x1 = x2 then
		;;; Non inclined path, cases #1-2
		
		if y1 > y2 then y1, y2 -> (y2, y1); endif;
		y1     ->> p.b1 -> p.b4;
		y2     ->> p.b2 -> p.b3;
		x1 - r ->> p.a1 -> p.a2;
		x1 + r ->> p.a3 -> p.a4;

		false
	elseif y1 = y2 then
		;;; Non inclined path, case #3-4
		
		if x1 > x2 then x1, x2 -> (x2, x1); endif;
		x1     ->> p.a1 -> p.a2;
		x2     ->> p.a3 -> p.a4;
		y1 - r ->> p.b1 -> p.b4;
		y1 + r ->> p.b2 -> p.b3;

		false
	else
		;;; Inclined path, cases #1-4
		;;; Determine the parameters of equation fn(x) = an*x + bn
		;;; for four edges (a1, b1) ... (a4, b4)
		
		x2 - x1 -> dx; ;;; cannot be 0
		y2 - y1 -> dy; ;;; cannot be 0
		sqrt(dx*dx + dy*dy) -> tmp;
		r*dx/tmp -> dx;
		r*dy/tmp -> dy;

		x1 - dy, y1 + dx,
		x2 - dy, y2 + dx,
		x2 + dy, y2 - dx,
		x1 + dy, y1 - dx ->
			if dx > 0 then
				if dy > 0 then
					(p.a1, p.b1, p.a2, p.b2, p.a3, p.b3, p.a4, p.b4)
				else
					(p.a2, p.b2, p.a3, p.b3, p.a4, p.b4, p.a1, p.b1)
				endif
			else
				if dy > 0 then
					(p.a4, p.b4, p.a1, p.b1, p.a2, p.b2, p.a3, p.b3)
				else
					(p.a3, p.b3, p.a4, p.b4, p.a1, p.b1, p.a2, p.b2)
				endif
			endif;

		;;; A divisor nor tmp will never be equal 0
		realof(p.b2 - p.b1)/(p.a2 - p.a1) -> tmp;

		;;; fn(x) = an*x + bn
		tmp   , p.b1 - tmp*p.a1 -> (p.a1, p.b1);
		-1/tmp, p.b2 + p.a2/tmp -> (p.a2, p.b2);
		tmp   , p.b3 - tmp*p.a3 -> (p.a3, p.b3);
		-1/tmp, p.b4 + p.a4/tmp -> (p.a4, p.b4);

		true
	endif -> p.isInclined;
enddefine;

;;; Checks if the rectangular part of the path contains a point (x, y)
define :method contains1(
	p:Path,
	x, y) -> bool;
	
	if p.isInclined then
		y < p.a1*x + p.b1 and y < p.a2*x + p.b2 and y > p.a3*x + p.b3 and y > p.a4*x + p.b4
	else
		x > p.a1 and x < p.a3 and y > p.b1 and y < p.b3
	endif -> bool;
enddefine;

;;; Checks if the circular part of the path contains a point (x2, y2)
define :method isInArea2(
	p:Path,
	x2, y2) -> bool;
	
	x2 - p.x, y2 - p.y -> (x2, y2);
	x2*x2 + y2*y2 < p.rr -> bool;
enddefine;

;;; Checks if both the rectangular and the circular part of the path
;;; contains a point (x, y). This is the most frequently called function, mostly
;;; by graph search rutines. As it is a bottleneck of the system, the method
;;; must be as fast as possible.
define :method contains2(
	p:Path,
	x, y) -> bool;
	
	if p.isInclined then
		y < p.a1*x + p.b1 and y < p.a2*x + p.b2 and y > p.a3*x + p.b3 and y > p.a4*x + p.b4 or
		isInArea2(p, x, y)
	else
		x > p.a1 and x < p.a3 and y > p.b1 and y < p.b3 or
		isInArea2(p, x, y)
	endif -> bool;
enddefine;

;;; Checks if there is a passage between waypoints (x1, y1) and (x2, y2).
;;; oList is an obstacle list.
;;; dA and dO are suitably an agent and a maximal obstacle size.
define :method isExpandable(
	this:Animal,
	oList,
	x1, y1,
	x2, y2,
	dA, dO) -> bool;
	
	lconstant p1 = instance Path;
	endinstance;
	lconstant p2 = instance Path;
	endinstance;
	lvars o;

	;;; To speed up calculations a search is carried out for a path,
	;;; which has the "largest" possible size, defined by a maximal obstacle size.
	;;; If any obstacle lies within this path (p1), a new "smaller" one (p2) is
	;;; created basing on a real size of the found obstacle.

	create(p1, x1, y1, x2, y2, dA + dO);

	true -> bool;
	for o in oList do
		if contains2(p1, getCoords(o)) then
			create(p2, x1, y1, x2, y2, dA + o.trial_size);
			if contains2(p2, getCoords(o)) then
				;;; It means that obstacle o lies within p2.
				;;; A path from (x1, y1) to (x2, y2) is not passable
				false -> bool;
				return();
			endif;
		endif;
	endfor;
enddefine;

;;; Finds the distance to the nearest obstacle, which lies on a path
;;; from (x1, y1) to (x2, y2).
;;; oList is an obstacle list.
;;; dA and dO are suitably an agent and a maximal obstacle size.
define :method getNearest(
	this:Animal,
	oList,
	x1, y1,
	x2, y2,
	dA, dO) -> dist;
	
	lconstant p1 = instance Path;
	endinstance;
	lconstant p2 = instance Path;
	endinstance;
	lvars o, d;
	
	;;; To speed up calculations a search is carried out for a path,
	;;; which has the "largest" possible size, defined by a maximal obstacle size.
	;;; If any obstacle lies within this path (p1), a new "smaller" one (p2) is
	;;; created basing on a real size of the found obstacle.

	create(p1, x1, y1, x2, y2, dA + dO);

	INF -> dist;
	for o in oList do
		if contains2(p1, getCoords(o)) then
			create(p2, x1, y1, x2, y2, dA + o.trial_size);
			if contains2(p2, getCoords(o)) then
				;;; o lies within a path area, calculate the distance
				sim_distance_from(x1, y1, getCoords(o)) - (dA + o.trial_size) -> d;
				;;; and check if it is not smaller then the previously stored
				if d < dist then
					d -> dist;
				endif;
			endif;
		endif;
	endfor;
enddefine;


;;; Finds the nearest obstacle, which lies on a path from (x1, y1) to (x2, y2).
;;; oList is an obstacle list.
define :method getNearestObject(
	this:Animal,
	oList,
	x, y) -> obj;
	
	lvars o, d, dist;

	false -> obj;
	INF -> dist;
	for o in oList do
		sim_distance_from(x, y, getCoords(o)) -> d;
		if d < dist then
			d -> dist;
			o -> obj;
		endif;
	endfor;
enddefine;

/*
-- Routines for graph search algorithm
*/

;;; The simplified heuristic function f(n) = g(n) + h(n), where h(n) = 0.
;;; Here f() calculates the relative cost of a move from (x1, y1) to (x2, y2).
;;; The function must satisfy the triangle inequality.
define :method graphHeuristicFunc(
	this:Animal,
	x1, y1,
	x2, y2) -> c;
	
	;;; simplified
	round(sim_distance_from(x1, y1, x2, y2)) -> c;
enddefine;

;;; A modified version of A* graph search algorithm, where:
;;; oList is an obstacle list,
;;; dA and dO are suitably an agent and a maximal obstacle size,
;;; wpL1 is an initial search graph, containing wpNum1 nodes (waypoints), and
;;; wpL2 is a result set of wpNum2 waypoints, which constitutes
;;; an outcoming path. If wpNum2 is equal 0 no path has been found.
define :method graphSearchA(
	this:Animal,
	oList,
	dA, dO,
	wpL1, wpNum1,
	wpL2) -> wpNum2;
	
	lvars procedure
		C		= newanyarray([1 ^wpNum1 1 ^wpNum1], initshortvec, subscrshortvec),
		Open	= newanyarray([1 ^wpNum1], initshortvec, subscrshortvec),
		Close	= newanyarray([1 ^wpNum1], initshortvec, subscrshortvec);
	lvars
		rCurrent, nCurrent, cCurrent, j, c, k, wpn, wpj;

	;;; C, Open and Close must be initialised with zeroes.
	;;; nCurrent is the current node.
	;;; rCurrent is the node, through which passes the best path to nCurrent.
	;;; cCurrent is a cost of reaching nCurrent.

	IDX_ROOT ->> rCurrent -> nCurrent;
	0 -> cCurrent;
	while true do
		;;; The best path to nCurrent goes through rCurrent.
		rCurrent -> Close(nCurrent);
	
		;;; Break the loop if nCurrent is the goal.
		if nCurrent = IDX_GOAL then
			quitloop(1);
		endif;
		
		;;; then remove nCurrent from Open.
		0 -> Open(nCurrent);
		
		;;; Expand the current node nCurrent,
		;;; iterate for all possible destination nodes j
		for 1 -> j step j + 1 -> j till j > wpNum1 do
			;;; Do not expand if the destination node j is:
			;;; equal the expanded node n, or is already on Close.
			if nCurrent /= j and Close(j) = 0 then
				wpL1(nCurrent) -> wpn;
				wpL1(j) -> wpj;
				
				;;; Check if j is expandable.
				if isExpandable(
					this,
					oList,
					getCoords(wpn),
					getCoords(wpj),
					dA, dO)
				then
					;;; Calculate the cost of reaching j through nCurrent.
					graphHeuristicFunc(
						this,
						getCoords(wpn),
						getCoords(wpj)) + cCurrent -> c;
					
					;;; Extract a node, through which passes the best path to j.
					Open(j) ->	k;
					;;; Redirect the best path to j if there was no
					;;; path to j before, or the new path is less costly.
					if k = 0 or C(k, j) > c then
						nCurrent -> Open(j);
					endif;
					
					c
				else

					INF
				endif -> C(nCurrent, j);
		    endif;
		endfor;
		
		;;; Find a node nCurrent with the lowest cost value.
		0 -> nCurrent;
		INF -> cCurrent;
		for 1 -> j step j + 1 -> j till j > wpNum1 do
			Open(j) ->	k;
			if k > 0 then
				C(k, j) -> c;
				if c < cCurrent then
					c, k, j -> (cCurrent, rCurrent, nCurrent);
				endif;
			endif;
		endfor;
		
		;;; Break the loop if Open is empty.
		if nCurrent = 0 then
			quitloop(1);
		endif;
	endwhile;

	;;; Build a outcoming path as an array of wpNum2 waypoints by
	;;; simple iteration Close(n) -> n until n points the root.
	0 -> wpNum2;
	if nCurrent > 0 then
		for 1 -> j step j + 1 -> j till j > waypointMax do
			Close(nCurrent) -> rCurrent;
			wpL1(nCurrent) -> wpn;
			wpL2(j) -> wpj;
			getCoords(wpn), C(rCurrent, nCurrent) -> (wpj.x, wpj.y, wpj.cost);
			if nCurrent = IDX_ROOT then
				j -> wpNum2;
				quitloop(1);
			endif;
			rCurrent -> nCurrent;
		endfor;
	endif;
enddefine;


/*
-- Routines operating on waypoints
*/

;;; Creates an array of pointers to Waypoint object instances.
define waypointInitArray(wpMax) -> wpList;
	lvars j;

	newarray([1 ^wpMax], 0) -> wpList;
	for 1 -> j step j + 1 -> j till j > wpMax do
		instance Waypoint;
		endinstance -> wpList(j);
	endfor;
enddefine;

;;; Initializes 3 arrays:
;;; The array of graph nodes, the waypoint array constituting a path, and
;;; the temporary waypoint array used in calculations
define :method waypointInit(this:Dog);
	waypointInitArray(waypointMax) -> this.wpGList;
	waypointInitArray(waypointMax) -> this.wpPList;
	waypointInitArray(waypointMax) -> this.wpTmpList;
enddefine;

;;; The probabilistic roadmap method generating an initial configuration of
;;; nodes (waypoints) indexed IDX_ROOT and IDX_GOAL.
define :method graphGenerateInit(
	this:Animal,
	x1, y1,
	x2, y2,
	wpL) -> wpNum;
	
	lvars wp;

	wpL(IDX_ROOT) -> wp;
	round(x1), round(y1) -> (wp.x, wp.y);
	wpL(IDX_GOAL) -> wp;
	round(x2), round(y2) -> (wp.x, wp.y);
	2 -> wpNum;
enddefine;

;;; The probabilistic roadmap method that generates nCount of random nodes
;;; (waypoints) and stores them in array wpL starting from index wpIdx + 1.
;;; All random nodes are uniformly distributed within (rMin, rMin + rWidth)
;;; circular area avoiding obstacles from oList.
;;; The method returns the total number of random nodes in wpL.
define :method graphGenerate(
	this:Animal,
	oList,
	obj,
	nCount, rMin, rWidth,
	wpL, wpIdx) -> wpNum;
	
	lconstant MAX_TRIALS = 100;
	lvars wp, j;

	wpIdx -> wpNum;
	repeat nCount times
		wpNum + 1 -> wpNum;
		wpL(wpNum) -> wp;

		for 1 -> j step j + 1 -> j till j > MAX_TRIALS do
			generatePoint(rMin, rWidth) -> (wp.x, wp.y);
			intof(wp.x) + obj.rc_picx, intof(wp.y) + obj.rc_picy -> (wp.x, wp.y);
			
			if not(collisionCheck(oList, getCoords(wp), rMin)) then
				quitloop(1);
			endif;
		endfor;
	endrepeat;
enddefine;

;;; The probabilistic roadmap method that generates nCount of random nodes
;;; (waypoints) for each obstacle from oList, and stores them in array wpL
;;; starting from index wpIdx + 1.
;;; All random nodes are uniformly distributed within (rMin, rMin + rWidth)
;;; circular area avoiding obstacles from oList.
;;; The method returns the total number of random nodes in wpL.
define :method graphGenerateList(
	this:Animal,
	oList,
	nCount, rMin, rWidth,
	wpL, wpIdx) -> wpNum;
	
	lvars o;

	wpIdx -> wpNum;
	for o in oList do
		graphGenerate(
			this,
			oList,
			o,
			nCount, rMin, rWidth,
			wpL, wpNum) -> wpNum;
	endfor;
enddefine;

;;; The key path optimisation method. Given wpL1 array of
;;; waypoints of length wpNum1 which constitutes an initial path, the method
;;; adds new waypoints to this path by making wpL1 more "dense".
;;; An outcoming set of waypoints of size wpNum2 is stored in wpL1 starting
;;; from index wpIdx2 + 1. In other words to the old "dense" path wpL2 is
;;; concatenated a new one generated from wpL1, but only if wpIdx2 is greater than 1.
;;; The element wpL1(wpIdx2) is then a "merging" waypoint.
define :method waypointTransform(
	this:Animal,
	wpL1, wpNum1,
	wpL2, wpIdx2) -> wpNum2;
	
	lvars
		dc, j, wp1, wp2, costDelta, x1, y1, c1, x2, y2, c2, dx, dy;
		
	;;; Check if there is enough free space (waypoints) in wpL2.
	if wpNum1 = 0 or wpNum1 > waypointMax - wpIdx2 + 1 then
		0 -> wpNum2;
		return();
	endif;
	wpIdx2 -> wpNum2;
	
	;;; root: j = wpNum1, cost = cost(wpL1(wpNum1)) = minimum
	;;; goal: j = 1, cost = cost(wpL1(1)) = maximum
	
	wpL1(1) -> wp1;
	getCoords(wp1), wp1.cost -> (x1, y1, c1);
	
	wpL2(wpNum2) -> wp2;
	if wpNum2 > 1 then wp2.cost - wp1.cost else 0 endif -> costDelta;
	x1, y1, c1 -> (wp2.x, wp2.y, wp2.cost);
    true -> wp2.isNode;
	
	;;; If wpIdx2 > 1 then all cost values from the remaining old path wpL2
	;;; must be "rescaled" in order to avoid potentially harmful discontinuities
	;;; in the "merging" waypoint.
	if costDelta < 0 then
		for 1 -> j step j + 1 -> j till j >= wpNum2 do
			(wpL2(j)).cost - costDelta -> (wpL2(j)).cost;
		endfor;
	endif;

	;;; Find a delta cost value which determines the distance between waypoints.
	;;; The value cannot be smaller than waypointCostDelta.
	max(realof(c1)/(waypointMax - wpNum1 - wpNum2), waypointCostDelta) -> dc;

	;;; Create a new "dense" set of waypoints basing on wpL1, and add them to wpL2.
	for 2 -> j  step j + 1 -> j till j > wpNum1 do
		wpL1(j) -> wp1;
		getCoords(wp1), wp1.cost -> (x2, y2, c2);
		
		dc*(x2 - x1)/(c2 - c1), dc*(y2 - y1)/(c2 - c1) -> (dx, dy);
		;;; Calculate the cost value of a new waypoint
		c1 - dc -> c1;
		;;; Keep adding to wpL2 all newly generated waypoints lying "before"
		;;; (in a cost sense) a next waypoint (x2, y2, c2) from wpL1.
		while c1 > c2 do
			wpNum2 + 1 -> wpNum2;
			wpL2(wpNum2) -> wp2;
			x1 - dx, y1 - dy -> (x1, y1);
			round(x1), round(y1), round(c1) -> (wp2.x, wp2.y, wp2.cost);
		    false -> wp2.isNode;

			c1 - dc -> c1;
		endwhile;

		;;; The waypoints from wpL1 which constitutes an initial path are
		;;; always being added to wpL2.
		wpNum2 + 1 -> wpNum2;
		wpL2(wpNum2) -> wp2;
		x2, y2, c2 -> (wp2.x, wp2.y, wp2.cost);
	    true -> wp2.isNode;

		x2, y2, c2 -> (x1, y1, c1);
	endfor;
enddefine;

;;; Basing on the initial random graph (wpL1 array of length wpNum1),
;;; the method produces the complete path to a goal - wpL2 array containig
;;; a "dense" set of wpNum2 waypoints. If wpIdx2 > 1 the resulting path is
;;; merged to the old one in a "merging" point index wpIdx2.
define :method routeFind(
	this:Dog,
	oList,
	wpL1, wpNum1,
	wpL2, wpIdx2) -> wpNum2;

	graphSearchA(
		this,
		oList,
		searchDAPath, searchDO,
		wpL1, wpNum1,
		this.wpTmpList) -> this.wpTmpNum;
	waypointTransform(
		this,
		this.wpTmpList, this.wpTmpNum,
		wpL2, wpIdx2) -> wpNum2;
enddefine;

;;; Searches for the farthest visible waypoint index (wpNextIdx) from (x, y).
;;; The search starts from the current waypoint index (wpPrevIdx) and within
;;; a horizon of waypointSearchHorizon waypoints but no further then r, and where:
;;; wpL is an array of waypoints of size wpNum,
;;; dA and dO are an agent and a maximal obstacle size, and
;;; oList is a list of obstacles.
define :method waypointFindNext(
	this:Animal,
	x, y, r,
	oList,
	dA, dO,
	wpL, wpNum,
	wpPrevIdx) -> wpNextIdx;
	
	lvars jMax, jMin, j, wp;

	;;; Determine upper and lower limit of the search.
	min(wpPrevIdx + waypointSearchHorizon, wpNum) -> jMax;
	max(wpPrevIdx - waypointSearchHorizon, 1	) -> jMin;
	;;; Index 0 means that no waypoint is visible.
	0 -> wpNextIdx;

	;;; Simple iteration over wpL. The smaller index j, the closer to the goal
	;;; (index 1).
	for jMax -> j step j - 1 -> j till j < jMin do
		wpL(j) -> wp;
		if sim_distance_from(x, y, getCoords(wp)) < r and
		   isExpandable(
			this,
			oList,
			x, y,
			getCoords(wp),
			dA, dO)
		then
			j -> wpNextIdx;
		endif;
	endfor;
enddefine;

;;; Basically this method works similary to waypointFindNext().
;;; The result is a last farthest visible waypoint wp,
;;; and a distance d between it and obj. As before oList is a list of obstacles.
define :method waypointFind(
	this:Dog,
	obj,
	oList) -> (wp, d);
	
	lvars wpNextIdx;

	waypointFindNext(
		this,
		getCoords(this.currentRoot), this.visualRange,
		oList,
		searchDAWaypoint, searchDO,
		this.wpPList, this.wpPNum,
		this.wpIdx
	) -> wpNextIdx;

	if wpNextIdx > 0 then
		wpNextIdx -> this.wpIdx;
	endif;
	
	(this.wpPList)(this.wpIdx) -> wp;
	
	;;; Return 0 if there is no any visible waypoint.
	if wpNextIdx > 0 then
		getDistance(obj, wp)
	else
		0
	endif -> d;
enddefine;

define :method waypointPlanIndex(
	this:Dog,
	range) -> index;
	
	lvars wpL, cLim, c, jHi, jLo;
	
	(this.wpPList) -> wpL;
	
	this.wpIdx -> index;
	(wpL(index)).cost -> c;
	c + range -> cLim;
	index, 1 -> (jHi, jLo);
	
	;;; binary search, wpPList is sorted in order of increasing cost value
	while true do
		intof((jHi + jLo)/2) -> index;
	
		if jHi <= jLo + 1 then
			quitloop(1);
		endif;
		
		(wpL(index)).cost -> c;
		index -> if c < cLim then jHi else jLo endif;
	endwhile;
enddefine;


/*
-- Routines for visualization of planning algorithms
*/

define :method verticesInit(
	this:Dog,
	winObj:rc_window_object);
	
	lvars j, str, vt;

	newarray([1 ^vertexMax], 0) -> vtList(this);

	for 1 -> j step j + 1 -> j till j > vertexMax do
		sprintf('%p', [^j]) -> str;
		instance VisualObj;
			rc_pic_lines = [WIDTH 1 COLOUR ^vertexColour [CIRCLE {0 0 2}]];
			rc_pic_strings = [FONT '5x8' COLOUR ^vertexColour {-5 -15 ^str}];
			name = str;
		endinstance -> vt;
		
		rc_do_addpic_to_window(vt, winObj, true);
		rc_move_to(vt, 10000, 0, false);
	    vt -> (vtList(this))(j);
	endfor;
enddefine;

define :method verticesShow(
	this:Animal,
	winObj:rc_window_object,
	show,
	wpL, wpNum);

	lvars j, vt, wp;

	min(vertexMax, wpNum) -> vtNum(this);
	
	for 1 -> j step j + 1 -> j till j > vertexMax do
		(this.vtList)(j) -> vt;
		wpL(j) -> wp;
		if j > vtNum(this) then
		    rc_move_to(vt, 10000, 0, true);
	    else
		    rc_move_to(vt, getCoords(wp), show);
	    endif;
	endfor;
enddefine;


define :method egdesInit(
	this:Dog,
	winObj:rc_window_object);
	
	lvars j, str, ed;

	newarray([1 ^edgeMax], 0) -> edList(this);

	for 1 -> j step j + 1 -> j till j > edgeMax do
		sprintf('%p', [^j]) -> str;
		instance VisualObj;
			name = str;
		endinstance -> ed;
		
		rc_do_addpic_to_window(ed, winObj, true);
		rc_move_to(ed, 10000, 0, false);
	    ed -> (edList(this))(j);
	endfor;
enddefine;

define :method egdesShow(
	this:Animal,
	winObj:rc_window_object,
	show,
	wpL, wpNum);
	
	lvars j, k, ed, wp, x1, y1, x2, y2;

	wpL(1) -> wp;
	getCoords(wp) -> (x1, y1);
	0 -> k;
	for 2 -> j step j + 1 -> j till j > wpNum do
		wpL(j) -> wp;
		
		if wp.isNode then
	 		getCoords(wp) -> (x2, y2);

	    	k + 1 -> k;
			(this.edList)(k) -> ed;
	    	rc_move_to(ed, 10000, 0, true);
	      	[ [WIDTH 2 COLOUR ^edgeColour {^x1 ^y1} {^x2 ^y2}] ] -> ed.rc_pic_lines;
	    	rc_move_to(ed, 0, 0, show);

		    x2, y2 -> (x1, y1);
		endif;
	endfor;

	k -> this.edNum;
	
	for k + 1 -> j step j + 1 -> j till j > edgeMax do
		(this.edList)(j) -> ed;
	    rc_move_to(ed, 10000, 0, true);
	endfor;
enddefine;


define :method directionInit(
	this:Dog,
	winObj:rc_window_object);
	
	instance VisualObj;
	endinstance -> this.direction;
		
	rc_do_addpic_to_window(this.direction, winObj, true);
	rc_move_to(this.direction, 10000, 0, false);
enddefine;

define :method directionShow(
	this:Dog,
	winObj:rc_window_object,
	show,
	x1, y1,
	x2, y2);
	
   	rc_move_to(this.direction, 10000, 0, true);
   	if show then
	   	[ [WIDTH 2 COLOUR ^directionColour {^x1 ^y1} {^x2 ^y2}] ]
	   		-> this.direction.rc_pic_lines;
	   	rc_move_to(this.direction, 0, 0, show);
   	endif;
enddefine;


/*
-- Miscellaneous utility methods of Pen, Dog and trial_sheep classes
*/

define :method isInPen(
	this:Pen,
	x, y) -> bool;
	
	lconstant p = instance Path;
	endinstance;
	lvars dx, dy;
	
	radialFunc(this.orientation, this.size) -> (dx, dy);
	
	create(
		p,
		this.rc_picx - dx, this.rc_picy - dy,
		this.rc_picx + dx, this.rc_picy + dy,
		this.size);
		
	contains1(p, x, y) -> bool;
enddefine;


define :method selectSheep(this:Dog) -> sheep;
	if this.sheepOutOfPenList = [] then
		false
	else
		oneof(this.sheepOutOfPenList)
	endif -> sheep;
enddefine;

define :method collectObjects(
	this:Dog,
	allAgents);
	
	lvars o;
	
	[%	for o in allAgents do
			if isObstacle(o)
			then
				o
			endif;
		endfor	%] -> this.obstacleList;

	[%	for o in allAgents do
			if  o /= this and o /= this.sheepCurrent and
				getDistance(o, this.currentRoot) < this.visualRange
			then
				o
			endif;
		endfor	%] -> this.obstacleLocalListDog;
	
	[%	for o in this.obstacleLocalListDog do
			if  not(istrial_sheep(o))
			then
				o
			endif;
		endfor	%] -> this.obstacleLocalListSheep;
	
	[%	for o in allAgents do
			if istrial_sheep(o) and not(isInPen(this.sheepPen, getCoords(o)))
			then
				o
			endif;
		endfor	%] -> this.sheepOutOfPenList;
enddefine;

define :method speedFind(this:Dog) -> speed;
	min(dogSpeedMax,
		dogSpeedMin + (dogSpeedMax - dogSpeedMin)*
		((this.sheepCurrentDist/this.visualRange)**2)) -> speed;
enddefine;

define :method moveDog(
	this:Dog,
	x, y,
	s);
	
	lvars dx, dy, d;

	rc_sync_display();
	returnif(rc_under_mouse_control(this));
	
	x - this.rc_picx, y - this.rc_picy -> (dx, dy);
	sqrt(dx*dx + dy*dy) -> d;
	min(s, d) -> s;
	s -> this.speed;
	if s > 0 then
		s/d -> d;
		dx*d, dy*d -> (dx, dy);
		rc_move_to(this, this.rc_picx + dx, this.rc_picy + dy, true);
		
		sim_degrees_diff(arctan2(dx, dy), this.rc_axis) -> d;
		if abs(d) > 90 then
			sign(d)*90 -> d;
		endif;
		rc_set_axis(this, (this.rc_axis + d/3) mod 360, true);
	endif;
enddefine;


define :method sheepSafeDist(
	this:trial_sheep,
	dog:Dog) -> d;
	
	sheepSafeDistMin*(
		(sheepSafeDistFac - 1)*(dog.speed/dogSpeedMax) +
		(sheepSafeDistFac - 1)*(dog.bark/dogBarkMax) +
		1) -> d;
enddefine;

define :method moveSheep(
	this:trial_sheep,
	angle,
	speed);
	
	lvars o, list, s, a, b, da, j, angleTest, d, x, y;

    rc_sync_display();
	returnif(rc_under_mouse_control(this));
	
	[%
		for o in all_agents do
			if o /= this and not(isDog(o)) then o endif;
		endfor
	%] -> list;

	0 -> s;
	angle ->> angleTest -> a;
	isInPen(pen, getCoords(this)) -> b;
	if b then searchDA else searchDAPath endif -> da;
	-1 -> j;

	while true do
		this.rc_picx + speed*cos(angleTest) -> x;
		this.rc_picy + speed*sin(angleTest) -> y;
	
		getNearest(
			this,
			list,
			getCoords(this),
			x, y,
			da, searchDO) -> d;
			
		if b and not(isInPen(pen, x, y)) then
			0
		else
			min(intof(max(d, 0)), speed)
		endif -> d;
		
		if s < d then
			angleTest, d -> (a, s);
		endif;
		if s = speed or j >= sheepDispAngleSteps then
			quitloop(1);
		endif;
		
		(angle + j*sheepDispAngleDelta) mod 360 -> angleTest;
		if j > 0 then -(j + 1) else -j endif -> j;
	endwhile;
	
	a, s -> (angle, speed);
	
	if speed > 0 then
	    angle -> this.trial_heading;
	    rc_set_axis(this, angle, true);
		rc_move_to(
			this,
			this.rc_picx + speed*cos(angle),
			this.rc_picy + speed*sin(angle),
			true);
    endif;
enddefine;


/*
-- Rulesets and rulefamily for dog
*/

define :ruleset rulesetDogPerception;
	[DLOCAL [prb_allrules = true]];
	[LVARS [this = sim_myself][name = this.sim_name]];

	;;; Sense all obstacles, including these local ones within visual range.
	;;; Find all sheep staying out of the pen.
	RULE watchObjects
	==>
		[POP11
			collectObjects(this, all_agents);
		]

	RULE watchCurrentSheep
		[WHERE this.sheepCurrent]
	==>
		[POP11
			lvars x, y, d;
		
			this.sheepCurrentX, this.sheepCurrentY -> (x, y);
			getCoords(this.sheepCurrent) -> (this.sheepCurrentX, this.sheepCurrentY);
			if this.sheepCurrentVisible then
				sim_distance_from(x, y, this.sheepCurrentX, this.sheepCurrentY)
			else
				0
			endif -> this.sheepCurrentSpeed;
		
			getDistance(
				this,
				this.sheepCurrent
			) -> this.sheepCurrentDist;
			
			this.sheepCurrentDist < this.visualRange and
			isExpandable(
				this,
				this.obstacleLocalListDog,
				getCoords(this),
				getCoords(this.sheepCurrent),
				searchDA, searchDO
			) -> this.sheepCurrentVisible;
			
;;;[Perception d %this.sheepCurrentDist% s %this.sheepCurrentSpeed% v %this.sheepCurrentVisible%]=>
		]

	RULE checkGoal
	    [WHERE this.sheepOutOfPenList = []]
	==>
	    [SAY ?name 'is very happy to complete all the tasks']
		[POP11
			sim_stop_scheduler();
		]

	RULE updateTimer
	==>
		[POP11
			this.timer + 1 -> this.timer;
		]
enddefine;


define :ruleset rulesetDogBehaviour;
	[LVARS [this = sim_myself]];

	RULE init
	    [NOT initBehaviour]
	==>
	    [initBehaviour]
		[LVARS index done activity]
		[POP11
			1, false -> (index, done);
			"rulesetDogFind" -> activity;
		]
	    [behaviour plan ?index ?done]
	    [behaviour ?activity]
	
	RULE find
	    [behaviour ?activity][->> item1]
	    [WHERE activity = "rulesetDogFind"]
	    [behaviour plan ?index ?done][->> item2]
	    [WHERE done = true]
	==>
		[POP11
			if this.sheepCurrentVisible and this.sheepCurrentDist < dogSheepDistMax then
				printf(
					'Behaviour find, current sheep: visible = %P distance = %P\n',
					[%this.sheepCurrentVisible, this.sheepCurrentDist%]);
					
				1, false -> (index, done);
				"rulesetDogSteer" -> activity;
			else
				0 -> this.bark;
			endif;
		]
		[DEL ?item1 ?item2]
	    [behaviour ?activity]
	    [behaviour plan ?index ?done]
	
	RULE steer
	    [behaviour ?activity][->> item1]
	    [WHERE activity = "rulesetDogSteer"]
	    [behaviour plan ?index ?done][->> item2]
	    [WHERE done = true]
	==>
		[POP11
			lvars b;
			isInPen(this.sheepPen, getCoords(this.sheepCurrent)) -> b;
			if not(this.sheepCurrentVisible) or b then
				printf(
					'Behaviour steer, current sheep: visible = %P is in pen = %P\n',
					[%this.sheepCurrentVisible, b%]);
					
				1, false -> (index, done);
				"rulesetDogFind" -> activity;
				if b then
					false ->> this.sheepCurrent -> this.sheepCurrentVisible;
				endif;
			elseif this.sheepCurrentSpeed then
				if this.sheepCurrentSpeed < dogSheepSteerSpeed then
					if this.bark < dogBarkMax then this.bark + 1 else dogBarkMax endif
				else
					if this.bark > 0 then this.bark - 1 else 0 endif
				endif -> this.bark;
			endif;
		]
		[DEL ?item1 ?item2]
	    [behaviour ?activity]
	    [behaviour plan ?index ?done]
enddefine;


define :ruleset rulesetDogPlan;
	[DLOCAL [prb_allrules = true]];
	[LVARS [this = sim_myself][name = this.sim_name]];

	RULE problem
		[WHERE this.pathProblemTm > 0]
	    [behaviour plan ?index ?done][->> item1]
	==>
		[POP11
			if this.timer > this.pathProblemTm + dogPlanLocalTrials + 1 then
				0 -> this.pathProblemTm;
				1
			else
				waypointPlanIndex(this, this.visualRange - searchDAPath)
			endif -> index;
			
			false -> done;
		]
		[DEL ?item1]
	    [behaviour plan ?index ?done]
	    [SAY ?name 'needs a new plan ...']

	RULE plan
	    [behaviour plan ?index ?done][->> item1]
	    [WHERE done = false]
	    [behaviour ?activity]
	==>
	    [SAY 'searching for the plan ( index =' ?index ') ...']
		[POP11
			lvars range, isLocal, goal, list;
			
			if activity = "rulesetDogFind" then
				if this.sheepCurrent = false then
					selectSheep(this) -> this.sheepCurrent;
				endif;
				this, this.sheepCurrent, this.obstacleLocalListDog
			else
				this.sheepCurrent, this.sheepPen, this.obstacleLocalListSheep
			endif -> (this.currentRoot, this.currentGoal, list);
			
			this.visualRange - searchDAPath -> range;
			getDistance(this.currentRoot, this.currentGoal) < range and
			this.pathProblemTm > 0 or
			index > 1 -> isLocal;
			
			if not(isLocal) then
				this.obstacleList -> list;
			endif;

			if index > 1 then
				(this.wpPList)(index)
			else
				this.currentGoal
			endif -> goal;

;;;[isLocal ^isLocal problemTm (%this.timer% %this.pathProblemTm%)]=>

			graphGenerateInit(
				this,
				getCoords(this.currentRoot),
				getCoords(goal),
				this.wpGList
			) -> this.wpGNum;

			if isLocal then
				graphGenerate(
					this,
					list,
					this.currentRoot,
					waypointGenLocalNum*length(list), waypointORLocalMin, range,
					this.wpGList, this.wpGNum
				) -> this.wpGNum;
			else
				graphGenerateList(
					this,
					list,
					waypointGenNum, waypointORMin, waypointORWidth,
					this.wpGList, this.wpGNum
				) -> this.wpGNum;
				/*graphGenerate(
					this,
					list,
					pen,
					waypointGenNum*length(list),
					waypointORLocalMin,
					min(sheep_window_xsize, sheep_window_ysize)/2,
					this.wpGList, this.wpGNum
				) -> this.wpGNum;*/
				graphGenerate(
					this,
					list,
					this.sheepCurrent,
					waypointGenSheepNum, waypointORLocalMin, waypointORWidth,
					this.wpGList, this.wpGNum
				) -> this.wpGNum;
			endif;

			routeFind(
				this,
				list,
				this.wpGList, this.wpGNum,
				this.wpPList, index
			) -> this.wpPNum;
			
			this.wpPNum > 0 -> done;

			if done then
				this.wpPNum -> this.wpIdx;
				0 -> this.pathProblemTm;
				
				verticesShow(
					this,
					sheep_win,
					showVertices,
					this.wpGList, this.wpGNum);
				egdesShow(
					this,
					sheep_win,
					showEdges,
					this.wpPList, this.wpPNum);
			endif;
		]
		[DEL ?item1]
	    [behaviour plan ?index ?done]
	
	RULE switch
		[behaviour plan ?index ?done]
		[WHERE done = true]
		[behaviour ?activity]
	==>
		[POP11
			0 -> this.timer;
		]
		[SAY 'switching to' ?activity]
		[RESTORERULESET ?activity]
enddefine;

define :ruleset rulesetDogFind;
	[LVARS [this = sim_myself]];

	RULE switch
	    [behaviour ?activity]
	    [WHERE activity /= "rulesetDogFind"]
	==>
		[RESTORERULESET rulesetDogPlan]

	RULE main
	    [WHERE this.pathProblemTm = 0]
	==>
		[LVARS x y s]
		[POP11
			lvars wp, d;

			waypointFind(
				this,
				this,
				this.obstacleLocalListDog) -> (wp, d);
			
			if d < dogFindDistMin then
				printf('Find path problem: distance = %P\n', [%d%]);
				this.timer -> this.pathProblemTm;
			endif;
			
			getCoords(wp), speedFind(this) -> (x, y, s);
		]
		[exec ?x ?y ?s]

	RULE problem
		[WHERE this.pathProblemTm > 0]
	==>
		[RESTORERULESET rulesetDogPlan]
enddefine;

define :ruleset rulesetDogSteer;
	[LVARS [this = sim_myself]];

	RULE switch
	    [behaviour ?activity]
	    [WHERE activity /= "rulesetDogSteer"]
	==>
		[RESTORERULESET rulesetDogPlan]

	RULE main
	    [WHERE this.pathProblemTm = 0]
	==>
		[LVARS x y s]
		[POP11
			lvars wp, d, l, xS, yS;

			waypointFind(
				this,
				this.sheepCurrent,
				this.obstacleLocalListSheep) -> (wp, d);

			if d < dogSteerDistMin then
				printf('Steer path problem: distance = %P\n', [%d%]);
				this.timer -> this.pathProblemTm;
			endif;
			
			if d > 0 then
				dogSheepDist/d -> l;
				getCoords(wp) -> (x, y);
				getCoords(this.sheepCurrent) -> (xS, yS);
				xS + l*(xS - x), yS + l*(yS - y) -> (x, y);
				
				getNearest(
					this,
					this.obstacleLocalListDog,
					xS, yS,
					x, y,
					searchDA, searchDO) -> l;
				min(dogSheepDist, max(0, l - dogObstacleDistMin))/dogSheepDist -> l;
	
				xS + l*(x - xS), yS + l*(y - yS), dogSpeedMax
			else
				0, 0, 0
			endif -> (x, y, s);
		]
		[exec ?x ?y ?s]
	
	RULE problem
		[WHERE this.pathProblemTm > 0]
	==>
		[RESTORERULESET rulesetDogPlan]
enddefine;

define :rulefamily rulefamilyDogActivity;

    ruleset: rulesetDogPlan
    ruleset: rulesetDogFind
    ruleset: rulesetDogSteer
enddefine;


define :ruleset rulesetDogExec;
	[LVARS [this = sim_myself]];

	RULE exec
		[exec ?x ?y ?s][->> item1]
	    [behaviour ?activity]
	==>
		[POP11
			moveDog(this, x, y, s);
			
			directionShow(
				this,
				sheep_win,
				showDirection,
				getCoords(if activity = "rulesetDogFind" then this else this.sheepCurrent endif),
				getCoords((this.wpPList)(this.wpIdx)));
		]
		[DEL ?item1]

	RULE default
	==>
		[POP11
			0 -> this.speed;
		]
enddefine;


/*
-- Rulesystem for dog
*/

define :rulesystem rulesystemDog;
	[DLOCAL [prb_allrules = false]];
	
    debug = false;
    cycle_limit = 1;

	include: rulesetDogPerception
	include: rulesetDogBehaviour
	include: rulefamilyDogActivity
	include: rulesetDogExec
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

define :method sim_agent_rulefamily_trace(object:Dog, rulefamily);
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
-- Utility functions and methods for sheep
*/

;;; These functions are used to perform specific calculations
;;; They are called by the more central procedures which make
;;; constructive use of the results.
;;; They are the 'shallow' part of the 'broad but shallow' design

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
           rel_direction(getCoords(Miszka), getCoords(sheepy), getCoords(post2))
           tells us what the difference is in direction of sheepy from Miszka as
           opp[osed to the direction of post1. This is used extensively, as it tells
           us whether sheepy appears to the left or right of the post for Miszka
           amongst many other things

TESTS:

    rel_direction(getCoords(Miszka), getCoords(sheepy), getCoords(post2))=>
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
    sim_distance_from(getCoords(a1), getCoords(a2)) -> dist;
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

TESTS: left_line(post1, post10, Miszka)=>
** <true>
NB obviously, this test doesn't make much sense without the image that it
describes

*/

define left_line_tolerance(lp1, lp2, obj, tolerance) -> boole;

	;;;returns true iff obj is on the left of a line from lp1 to lp2
	;;;(and its extensions to infinity)

	rel_direction(
		getCoords(lp1),
		getCoords(obj), getCoords(lp2)) < tolerance -> boole;

enddefine;

define left_line(lp1, lp2, obj) -> boole;

	left_line_tolerance(lp1, lp2, obj, 3) -> boole;

enddefine;


define :method agent_bearing( agent:trial_agent, target:trial_agent) -> result;
    ;;; Calculates the direction of a target from the perspective
    ;;; of the specified agent

    round(
        sim_degrees_diff(
            sim_heading_from(getCoords(agent), getCoords(target)),
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

	;;; A.S. re-written 16 Nov 2003
	for element in components do
		quitif(element == []);
        ;;; Extract the next position to be averaged

        ;;; Find its weighting and polar coordinates
        element --> ! [?weighting ?r ?theta];

        ;;; Use this variable instead of calculating its value twice
        weighting * r -> mag;

        ;;; Having converted to Cartesian coordinates include the contribution
        mag * cos(theta) + sumx -> sumx;
        mag * sin(theta) + sumy -> sumy;

        ;;; Keep a record of the total weighting so far
        weighting + sumw -> sumw;
	endfor;
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
-- The action routines for sheep
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

define :method wander(agent:trial_sheep);
    ;;; Move slowly in undirected fashion

    ;;; Moves the agent forward with a random element determining its exact heading
    moveSheep( agent, (trial_heading(agent) + random(70) - 35) mod 360, 1 );
enddefine;


/*
TESTS
rel_direction(getCoords(post1), getCoords(post4), getCoords(Miszka))=>;
** 90.404
left_line(post1, post4, Miszka)=>
** <true>
*/


define same_side_of_line(lp1, lp2, o1, o2);
    ;;;returns true iff o1 & o2 are on the same side of a line from lp1 to lp2
    ;;;(and it's extensions to infinity) TC

	left_line(o1, lp1, lp2) == left_line(lp1, lp2, o2)


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

;;; Variable declared here so that it is accessable within sim_run_agent
lvars
	my_name = 'name_undef';


/*
-- Redefined sim_run_agent for sheep
*/

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
-- Button and drag methods for empty window space

;;; Methods added by Aaron Sloman 22 Jan 1999
*/

;;; Methods for empty window space
define :method sheep_button_1_up(pic:rc_window_object, x, y, modifiers);
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

define :method rc_button_1_down(pic:rc_selectable, x, y, modifiers);
    ;;; Make sure it is at the front of the known objects list
    rc_set_front(pic);
	pic -> rc_mouse_selected(rc_active_window_object);
enddefine;

define :method rc_button_1_down(pic:immobile, x, y, modifiers);
	;;; do nothing to immobile entities.
	;;; [BUTTON ^pic] =>
enddefine;


define :method rc_button_1_up(pic:rc_selectable, x, y, modifiers);
    ;;; disable default method
enddefine;


define :method rc_button_1_drag(pic:immobile, x, y, modifiers);
	;;; immobile obstacles are not draggable
enddefine;


/*
-- Rulesets and rulefamily for sheep
*/

define :ruleset sheep_perception_rules;
    ;;; These rules take the incoming sense data and process it.
    ;;; Objects in the environment can be classified as obstacles, other sheep
    ;;; or dogs

    RULE see_obstacle
    ;;; Applies to obstacles within a given range
    [new_sense_data ?object:isObstacle ?dist ?bearing ==]
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
			oneof([95 -95])
			;;; ????? is this right? Added by A.S. 16 Jul 2000
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
    [new_sense_data ?foe:isDog ?dist ?bearing ?sector ==]
    ==>
    [DEL 1]
    [Foe ?foe ?dist ?bearing ?sector]
    [SAYIF perception ?my_name 'is aware of' [$$sim_name(foe)] 'in sector' ?sector]

enddefine;

define :ruleset sheep_obstacle_rules;
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

define :ruleset sheep_instinct_rules;
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
		[Foe ?company:isDog ?dist ?a ==]
		[Flee_impulse ??imp_list][->> item1]
		[Urgency ?urgency][->> item2]
	==>
		[DEL ?item1 ?item2]
		[LVARS w s]
		[POP11
			lvars d, n, u;

			sheepSafeDist(sim_myself, company) -> d;
			round(min(8, 8*dist/d)) -> n;

			(a + sim_myself.trial_heading + 180) mod 360 -> a;
			min(max_sheep_speed, 8 - n) -> s;
			zone_weighting(max(1, min(8, n))) -> w;
			intof(n/3.0) + 1 -> u;
			if u < urgency then
			    u -> urgency;
			endif;
		]
		[Flee]
		[Flee_impulse [?w ?s ?a] ??imp_list]
		[Urgency ?urgency]


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
    ;;; Try to keep sheep movements synchronised
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


define :ruleset sheep_resolve_behaviour_rules;
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

		;;; added A.S. 16 Nov 2003
		min(speed, max_sheep_speed) -> speed;

		;;; for tracing
		;;; [SPEED ^my_name ^speed] =>
		;;; readline()=>

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

define :ruleset sheep_action_rules;

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
    [do resting]
    [SAYIF report ?my_name 'decided to do nothing']

    RULE eat_action
    [Intent Eat]
    ==>
    [DEL 1]
    [do sheep_graze]
    [SAYIF report ?my_name 'decided to eat']

    RULE positive_action
    [Intent ?speed ?bearing]
    ==>
    [DEL 1]
    [do moveSheep ?bearing ?speed]
    [SAYIF report ?my_name 'decided to head' ?bearing 'at speed' ?speed]

enddefine;


define :rulefamily sheep_social_rules;
    debug = true;

    ruleset: avoidance
    ruleset: center
    ruleset: imitate
enddefine;

/*
-- Rulesystem for sheep
*/

define :rulesystem trial_sheep_rulesystem;
    [DLOCAL [prb_allrules = true ]];
    [LVARS my_name];
    debug = false;
    cycle_limit = 1;

    include: sheep_perception_rules
    include: sheep_obstacle_rules
    include: sheep_instinct_rules
    include: sheep_social_rules with_limit = 3;
    include: sheep_resolve_behaviour_rules
    include: sheep_action_rules
enddefine;

/*
-- Procedures for setting up and running the demo
*/

define :method setupPen(this:Pen, winObj:rc_window_object, inList) -> outList;
	;;; first create instances of all the posts
	
	define :instance post1:Post;
		rc_pic_strings = [FONT '6x13' {-3 -3 '1'}];
		rc_picx = size(this);	rc_picy = -size(this);
	enddefine;

	define :instance post2:Post;
		rc_pic_strings = [FONT '6x13' {-3 -3 '2'}];
		rc_picx = size(this);	rc_picy = -size(this)/3;
	enddefine;

	define :instance post3:Post;
		rc_pic_strings = [FONT '6x13' {-3 -3 '3'}];
		rc_picx = size(this);	rc_picy = size(this)/3;
	enddefine;

	define :instance post4:Post;
		rc_pic_strings = [FONT '6x13' {-3 -3 '4'}];
		rc_picx = size(this);	rc_picy = size(this);
	enddefine;

	define :instance post5:Post;
		rc_pic_strings = [FONT '6x13' {-3 -3 '5'}];
		rc_picx = size(this)/3;	rc_picy = size(this);
	enddefine;

	define :instance post6:Post;
		rc_pic_strings = [FONT '6x13' {-3 -3 '6'}];
		rc_picx = -size(this)/3;	rc_picy = size(this);
	enddefine;

	define :instance post7:Post;
		rc_pic_strings = [FONT '6x13' {-3 -3 '7'}];
		rc_picx = -size(this);	rc_picy = size(this);
	enddefine;

	define :instance post8:Post;
		rc_pic_strings = [FONT '6x13' {-3 -3 '8'}];
		rc_picx = -size(this);	rc_picy = size(this)/3;
	enddefine;

	define :instance post9:Post;
		rc_pic_strings = [FONT '6x13' {-3 -3 '9'}];
		rc_picx = -size(this);	rc_picy = -size(this)/3;
	enddefine;

	define :instance post10:Post;
		rc_pic_strings = [FONT '6x13' {-5 -3 '10'}];
		rc_picx = -size(this);	rc_picy = -size(this);
	enddefine;

	;;; Then set the orientation of the "pen"
	random(360) -> this.orientation;

	;;; Now posts making up the pen
	addAgentToWindow(
		trnAgentList(
			[ post1 post2 post3 post4 post5 post6 post7 post8 post9 post10 ],
			this.orientation,
			0, 0),
		winObj) <> inList -> outList;
enddefine;


define createTreeGroup1(size, a1, a2, rMin, rWidth, inList) -> outList;
	lvars j, tree, x, y;

	1 -> j;
	inList -> outList;
	while j <= size do
		instance Tree;
		endinstance -> tree;

		radialFunc(distribLinear(a1, a2), distribSquare(rMin, rWidth)) -> (x, y);
		rc_move_to(
			tree,
			x, y,
			false);

		if outList = [] or not(collisionCheck(outList, getCoords(tree), tree.trial_size)) then
			j + 1 -> j;
			[ ^tree ] <> outList -> outList;
		endif;
	endwhile;
enddefine;

define :method setupTrees(this:Pen, winObj:rc_window_object, inList) -> outList;
	lvars list1, l1, list2, l2/*, list3, l3*/;

	280 -> l1;
	trnAgentList(
		createTreeGroup1(18, 0, l1, 140, 20, []),
		(this.orientation - l1/2 + 270) mod 360, 0, 0) -> list1;
		
	280 -> l2;
	trnAgentList(
		createTreeGroup1(30, 0, l2, 240, 20, []),
		(this.orientation - l2/2 + 90) mod 360, 0, 0) -> list2;
	
/*	280 -> l3;
	trnAgentList(
		createTreeGroup1(40, 0, l3, 340, 20, []),
		(this.orientation - l3/2 + 270) mod 360, 0, 0) -> list3;
*/		
	addAgentToWindow(
		list1 <> list2/* <> list3*/,
		winObj) <> inList -> outList;
enddefine;


define :method setupDog(this:Dog, pen:Pen, winObj:rc_window_object);
	waypointInit(this);
	verticesInit(this, winObj);
	egdesInit(this, winObj);
	directionInit(this, winObj);
	this -> this.currentRoot;
	pen -> this.sheepPen;
enddefine;

define :method setupAnimals(this:Pen, winObj:rc_window_object, inList) -> outList;
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
	

	;;; Now the sheepdog
	define :instance Miszka:Dog;
	enddefine;
	setupDog(Miszka, this, winObj);
	
	disperseAgents(
		agentRMin, agentRWidth,
		[sheepy sleepy sneezy bashful doc Miszka],
		inList) -> outList;

	addAgentToWindow(
		outList,
		winObj
	) <> inList -> outList;
enddefine;




;;; Prepare everything for running

global vars sheep_setup_done = false;

define :instance pen:Pen;
enddefine;

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

    ;;; Make the window mouse sensitive, but not motion sensitive
	;;; except when dragging
    rc_mousepic(sheep_win, [button dragonly]);

	"sheep_button_3_up" -> rc_button_up_handlers(sheep_win)(3);
	
    ;;; the pen
    setupPen(pen, sheep_win, []) -> all_agents;

    ;;; the trees
    setupTrees(pen, sheep_win, all_agents) -> all_agents;

    ;;; the animals
    setupAnimals(pen, sheep_win, all_agents) -> all_agents;

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

    rc_control_panel("left", "top",
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
        printf('\nUse the mouse to rearrange\nthe sheep, the green trees,');
        printf('\nand the dog,');
        printf('\nthen press RETURN to start the demo.');
        printf('\nPress button 3 in\n\s\s the window to stop.\n');
        readline() ->;
    endunless;

    sim_scheduler(all_agents, n);

	pr('\nrun_sheep('><n><');');
enddefine;

;;; By default there is no trace output
global vars prb_sayif_trace = [];

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

printf('\nUse mouse button 1\n to rearrange items on the field\n');
printf('\nTo run for 20000 time steps\n do the following:');
printf('\nand use mouse button 3\n  to STOP or RESTART\n\t run_sheep(20000);\n');

/*
-- Index of classes, methods, procedures, rulesets, etc.

To rebuild this index, do: ENTER indexify define

CONTENTS - (Use <ENTER> gg to access required sections)

 define :class trial_agent;
 define :class Animal;
 define :class trial_sheep;
 define :class Dog;
 define :class Obstacle;
 define :class Tree;
 define :mixin immobile;
 define :class Post;
 define :class Pen;
 define :class Waypoint;
 define :class VisualObj;
 define :class Path;
 define :method print_instance(this:Animal);
 define :method print_instance(this:Obstacle);
 define :method print_instance(this:Waypoint);
 define :method rc_move_to(this:trial_agent, x, y, boole);
 define :method rc_set_axis(this:trial_agent, heading, boole);
 define :method getCoords(this:rc_linepic) -> (x, y);
 define :method getCoords(this:Pen) -> (x, y);
 define :method getCoords(this:Waypoint) -> (x1, y1);
 define addAgentToWindow(inList, winObj) -> outList;
 define getDistance(o1, o2) -> d;
 define radialFunc(a, r) -> (x, y);
 define radialFuncInv(x, y) -> (a, r);
 define distribLinear(rMin, rWidth) -> x;
 define distribSquare(rMin, rWidth) -> x;
 define generatePoint(rMin, rWidth) -> (x, y);
 define collisionCheck(list, x, y, r) -> bool;
 define trnAgentList(inList, aInitTrn, aTrn, rTrn) -> outList;
 define disperseAgents(rMin, rWidth, aList, oList) -> outList;
 define :method create(
 define :method contains1(
 define :method isInArea2(
 define :method contains2(
 define :method isExpandable(
 define :method getNearest(
 define :method getNearestObject(
 define :method graphHeuristicFunc(
 define :method graphSearchA(
 define waypointInitArray(wpMax) -> wpList;
 define :method waypointInit(this:Dog);
 define :method graphGenerateInit(
 define :method graphGenerate(
 define :method graphGenerateList(
 define :method waypointTransform(
 define :method routeFind(
 define :method waypointFindNext(
 define :method waypointFind(
 define :method waypointPlanIndex(
 define :method verticesInit(
 define :method verticesShow(
 define :method egdesInit(
 define :method egdesShow(
 define :method directionInit(
 define :method directionShow(
 define :method isInPen(
 define :method selectSheep(this:Dog) -> sheep;
 define :method collectObjects(
 define :method speedFind(this:Dog) -> speed;
 define :method moveDog(
 define :method sheepSafeDist(
 define :method moveSheep(
 define :ruleset rulesetDogPerception;
 define :ruleset rulesetDogBehaviour;
 define :ruleset rulesetDogPlan;
 define :ruleset rulesetDogFind;
 define :ruleset rulesetDogSteer;
 define :rulefamily rulefamilyDogActivity;
 define :ruleset rulesetDogExec;
 define :rulesystem rulesystemDog;
 define :method sim_agent_running_trace(object:trial_agent);
 define :method sim_agent_messages_out_trace(agent:trial_agent);
 define :method sim_agent_messages_in_trace(agent:trial_agent);
 define :method sim_agent_actions_out_trace(object:trial_agent);
 define :method sim_agent_rulefamily_trace(object:trial_agent, rulefamily);
 define :method sim_agent_rulefamily_trace(object:Dog, rulefamily);
 define :method sim_agent_endrun_trace(object:trial_agent);
 define :method sim_agent_terminated_trace(object:trial_agent, number_run, runs, max_cycles);
 define vars procedure sim_scheduler_pausing_trace(objects, cycle);
 define vars procedure sim_post_cycle_actions(objects, cycle);
 define sim_direction(x1,y1,x2,y2) -> heading;
 define sim_direction_two(x1,y1,x2,y2);
 define rel_direction(x1,y1,x2,y2,x3,y3) -> rel_dir;
 define :method sim_distance(a1:trial_agent, a2:trial_agent) -> dist;
 define left_line_tolerance(lp1, lp2, obj, tolerance) -> boole;
 define left_line(lp1, lp2, obj) -> boole;
 define :method agent_bearing( agent:trial_agent, target:trial_agent) -> result;
 define weighted_sum(components) -> (sumx, sumy, sumw);
 define :method collision_course(bearing, arc) -> result;
 define check_range( pair1, pair2, diff) -> result;
 define compare_ranges( base, test ) -> (result,altered);
 define obscured_ranges(range_list) -> result;
 define get_range( heading, choice_list) -> result;
 define :method resting(agent:trial_sheep);
 define :method sheep_graze(agent:trial_sheep);
 define :method exercise( agent:trial_sheep);
 define :method wander(agent:trial_sheep);
 define same_side_of_line(lp1, lp2, o1, o2);
 define :method sim_sense_agent(a1:sim_object, a2:sim_object, dist);
 define :method sim_run_agent(agent:trial_sheep, agents);
 define :method sheep_button_1_up(pic:rc_window_object, x, y, modifiers);
 define :method sheep_button_3_up(pic:rc_window_object, x, y, modifiers);
 define :method rc_button_1_down(pic:rc_selectable, x, y, modifiers);
 define :method rc_button_1_down(pic:immobile, x, y, modifiers);
 define :method rc_button_1_up(pic:rc_selectable, x, y, modifiers);
 define :method rc_button_1_drag(pic:immobile, x, y, modifiers);
 define :ruleset sheep_perception_rules;
 define :ruleset sheep_obstacle_rules;
 define :ruleset sheep_instinct_rules;
 define :ruleset avoidance;
 define :ruleset center;
 define :ruleset imitate;
 define :ruleset sheep_resolve_behaviour_rules;
 define :ruleset sheep_action_rules;
 define :rulefamily sheep_social_rules;
 define :rulesystem trial_sheep_rulesystem;
 define :method setupPen(this:Pen, winObj:rc_window_object, inList) -> outList;
 define createTreeGroup1(size, a1, a2, rMin, rWidth, inList) -> outList;
 define :method setupTrees(this:Pen, winObj:rc_window_object, inList) -> outList;
 define :method setupDog(this:Dog, pen:Pen, winObj:rc_window_object);
 define :method setupAnimals(this:Pen, winObj:rc_window_object, inList) -> outList;
 define :instance pen:Pen;
 define sheep_setup();
 define killsheepwindows();
 define sheepdog_panel();
 define run_sheep(n);

*/

/*
-- Revision notes
*/

/* --- Revision History ---------------------------------------------------
--- Marek Kopicki 12 Jan 2004
	Extended the sheepdog by giving it a fast planning capapbility combined
		with reactive plan execution and plan modification.

	Major revisions and reorganisation.

--- Aaron Sloman, 16 Nov 2003
	Introduced null drag method for obstacles, to prevent mishaps when mouse is
	dragged over the post. Also added "dragonly" to calls of rc_mousepic
	Changed appearance of objects to improve display.

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
