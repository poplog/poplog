/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/newkit/sim/demo/rib/ijcai95.p
 > Purpose:			Robot in a box, demonstrating Sim_agent
 > Author:          Ricardo Poly (and Aaron Sloman), Dec 1994
 > Documentation:	
		A. Sloman and R. Poli,
			SIM_AGENT: A toolkit for exploring agent designs,
			Intelligent Agents Vol II (ATAL-95), Springer-Verlag,
			pp. 392--407, 1996,
			Ed. Mike Wooldridge, Joerg Mueller and MilindTambe,
		Presented at IJCAI 1995
 > Related Files:	LIB SIM_AGENT, HELP SIM_AGENT, HELP POPRULEBASE
 */

;;; $poplocal/local/sim/demo/rib/ijcai95.p

;;;
;;; Program:        ijcai95.p
;;;
;;; Author:         Riccardo Poli and Aaron Sloman
;;;
;;; Creation date:  Dec 1994
;;;
;;; Description:    Robot In a Box (RIB)
;;;
;;;
;;;
;;; Load required libraries if not already loaded
;;; 1 -> popgctrace;
;;; Increase popmemlim to reduce GC time
;;;

max(popmemlim, 2000000) -> popmemlim;
uses objectclass
uses poprulebase
uses prb_extra
uses sim_agent;
false -> popgctrace;

;;; compile emacsreadline if it exists (for Birmingham)
;;; uses emacsreadline;
subsystem_libcompile('emacsreadline', popuseslist) -> ;

uses rc_graphic;

;;; uses ann_with_examples; A.S. Sat Dec 10 17:31:09 GMT 1994
compilehere
	ann_with_examples.p;

;;;
;;; The default rule-types
;;;

global vars
	rib_rules = [],
	box_rules = [];

;;; Reduce default trace printing
define :method sim_agent_messages_out_trace(agent:sim_agent);
	lvars messages = sim_out_messages(agent);
	if messages /== [] then
		[New messages ^(sim_name(agent)) ^messages] ==>
	endif;

enddefine;

define :method sim_agent_messages_in_trace(agent:sim_agent);
	lvars messages = sim_in_messages(agent);
	if messages /== [] then
		[New messages ^(sim_name(agent)) ^messages] ==>
	endif;

enddefine;

define :method sim_agent_actions_out_trace(agent:sim_agent);

;;;	lvars actions = sim_actions(agent);
;;;	[New actions ^(sim_name(agent)) ^actions] ==>
enddefine;

define :method sim_agent_endrun_trace(agent:sim_agent);

	;;;['Data in' ^(sim_name(agent)) ]==>
	;;; prb_print_database();
enddefine;

define :method sim_agent_terminated_trace(object:sim_object, number_run, runs, max_cycles);
	;;; After each rulesystem is run, this procedure is given the object, the
	;;; number of actions run other than STOP and STOPIF actions, the number of times
	;;; the rulesystem has been run, the maximum possible number (sim_speed).
	
enddefine;

;;;
;;; Rulesystems, defined later
;;;

vars
	rib_rulesets,
	box_rulesets;

;;;
;;; The Robot In a Box (RIB) sub-class
;;;

define :class rib_agent; isa sim_agent;
    slot rib_x_pos   == 0;
    slot rib_y_pos   == 0;
    slot rib_x_velocity == 0;
    slot rib_y_velocity == 0;
	;;; values of sensors in last cycle
    slot rib_old_sensor == newassoc([
				     [sensor0 undef]
				     [sensor45 undef]
				     [sensor90 undef]
				     [sensor135 undef]
				     [sensor180 undef]
				     [sensor225 undef]
				     [sensor270 undef]
				     [sensor315 undef]]);

    ;;; information about rules to be obeyed. Rules defined below.
    slot sim_rulesystem = rib_rulesets;
    slot sim_sensors == [{rib_sense_box 10000000}];
enddefine;

;;; A utility method A.S. 13 Sep 2000

define :method rib_coords(agent:sim_agent) -> (x, y);
	
	rib_x_pos(agent) -> x;
    rib_y_pos(agent) -> y;

enddefine;

define :method updaterof rib_coords(x,y, agent:sim_agent);
	
	x -> rib_x_pos(agent);
    y -> rib_y_pos(agent);

enddefine;

;;;
;;; The box sub-class (environment for RIB)
;;;

define :class box_agent; is sim_agent;
    slot box_walls       == [
			     [[0 0] [1 0] 1]   ;;; Origin + unit-vector + length
			     [[1 0] [0 1] 1]   ;;; Counter-clock-wise for emply boxes
			     [[1 1] [-1 0] 1]  ;;; Clock-wise for solid boxes
			     [[0 1] [0 -1] 1]
			     ];

    ;;; Information about rules to be obeyed. Rules defined below.
    slot sim_rulesystem = box_rulesets;
    slot sim_sensors == [{box_sense_rib 10000000}];
enddefine;

;;;
;;; A new TRACE action for poprulebase
;;;

global vars ptrace_list = [yes no ptrace];

define TRACE_proc(Instance, action);
	lvars keyword, stuff;
	if action matches ! [TRACE ?keyword ??stuff]
	and member(keyword, ptrace_list)
	then
		stuff =>
	endif
enddefine;

TRACE_proc -> prb_action_type("TRACE");

;;;
;;; Some procedures needed for perception
;;;

;;;
;;; Procedure that gives a 2-D point belonging to a straight line
;;; given the origin and the unit vector representing the line and
;;; the position (coordinate) along the line
;;;

define straight_line_point( coordinate, unit_vector, origin ) -> point;

    [%
      origin(1) + unit_vector(1) * coordinate;
      origin(2) + unit_vector(2) * coordinate;
      %] -> point;
enddefine;

;;;
;;; Procedure that finds the intersection between two straight lines
;;; and returns the intersection point and the coordinates along the lines
;;;

define crossing_point( P, unit_vectorP, Q, unit_vectorQ ) -> ( point, coordinateP, coordinateQ );

    if ( unit_vectorP(1) * unit_vectorQ(2) -
	 unit_vectorP(2) * unit_vectorQ(1) /= 0.0 ) then
    	( unit_vectorQ(2) * ( Q(1) - P(1) ) - unit_vectorQ(1) *
	  ( Q(2) - P(2) ) ) /
	( unit_vectorP(1) * unit_vectorQ(2) -
	  unit_vectorP(2) * unit_vectorQ(1) ) -> coordinateP;
     	straight_line_point( coordinateP, unit_vectorP, P ) -> point;
	if ( unit_vectorQ(1) /= 0.0 ) then
	    (point(1) - Q(1)) / unit_vectorQ(1) -> coordinateQ;
	else
	    (point(2) - Q(2)) / unit_vectorQ(2) -> coordinateQ;
	endif;
    else
	undef -> point;
	undef -> coordinateP;
	undef -> coordinateQ;
    endif;
enddefine;

/*
crossing_point( [0 0], [0 1], [1 1], [1 0] ) =>
crossing_point( [0 0], [0 1], [1 1], [0.707 0.707] ) =>
*/

;;;
;;; Method that, given an angle, evaluate the (approximate) average distance
;;; between a RIB and the segments that make up a box, in the direction
;;; represented by such an angle. The average is evaluated considering a
;;; sector of 45 degrees about the angle.
;;;

define :method eval_sensor(angle, a1:rib_agent, a2:box_agent ) -> value;
    lvars
		origin = [^(rib_coords(a1))],
		alpha, unit_vector,
		value = 0,
		count = 0,
		min_distance,
    	distance, pos, line,
		point,
		alpha_min = angle-22.5,
		alpha_max = angle+22.5;

    for alpha from alpha_min by 3.0 to alpha_max  do
	1.0 -> min_distance;
	[ ^(cos(alpha)) ^(sin(alpha))] -> unit_vector;
	fast_for line in box_walls(a2) do
	    crossing_point(origin,unit_vector,line(1),line(2)) ->
	    ( point, distance, pos );
	    if ( distance > 0 and pos >= 0 and pos <= line(3) and
		 distance < min_distance ) then
		distance -> min_distance;
	    endif;
	endfor;
	value + min_distance -> value;
	count + 1 -> count;
    endfor;
    value / count -> value;
enddefine;

/*
define :instance a:rib_agent;
    sim_name = "RIB";
    rib_x_pos = 0.5;
    rib_y_pos = 0.01;
enddefine;

define :instance b:box_agent;
    sim_name = "The_Box";
enddefine;

eval_sensor(0,a, b) =>
eval_sensor(90,a, b) =>
*/

;;;
;;; Method that provides a set of sensory data for a RIB.
;;; The data consist of 8 measurements of the average distance between
;;; the RIB and the surrounding walls in 8 different directions
;;; 		(0, 45, ..., 315
;;; degrees) and a variable number (0-8) of proximity/contact data in the same
;;; directions
;;;

define :method rib_sense_box(a1:sim_agent, a2:sim_agent, dist);
    lvars angle, sensor_value, sensor, old_sensor_value;

    if isrib_agent( a1 ) and isbox_agent( a2 ) then
	fast_for angle in [0 45 90 135 180 225 270 315] do
	    consword(concat_strings([sensor ^angle])) -> sensor;

	    eval_sensor(angle,a1,a2) -> sensor_value;
	    [new_sense_data range ^sensor ^sensor_value];

    	    if sensor_value <= 0.03 then
	    	[new_sense_data touch ^sensor]
	    endif;

	    rib_old_sensor(a1)(sensor) -> old_sensor_value;
	    if old_sensor_value /= undef then
		[new_sense_data motion ^sensor ^(sensor_value - old_sensor_value)];
	    endif;

	    ;;; sensor_value -> rib_old_sensor(a1)(sensor);

	endfor;
    elseif isrib_agent( a1 ) and isrib_agent( a2 ) and a1 == a2 then
		[new_sense_data velocity x ^(rib_x_velocity(a1))];
		[new_sense_data velocity y ^(rib_y_velocity(a1))];
    endif
enddefine;

;;;
;;; Method that make the box react immediately to any RIB that
;;; attempts to enter one of its walls. The reaction consists of moving back
;;; the RIB that has crossed a wall and changing the direction and the
;;; amplitude of the component of the speed orthogonal to such a wall.
;;; NOTE: This is run among the sensory methods, but it is not clear if it should.
;;;

define :method box_sense_rib(a1:sim_agent, a2:sim_agent, dist);
    lvars distance, pos, line, robot_pos, normal_x, normal_y, point;

    if isbox_agent( a1 ) and isrib_agent( a2 ) then

		fast_for line in box_walls(a1) do
 	    	;;; Sense the current position of the RIB
	    	[^(rib_coords(a2))] -> robot_pos;

	    	;;; Find the vector orthogonal to the wall
	    	explode(line(2)) -> (normal_y, normal_x);
	    	- normal_y -> normal_y;

	    	;;; Find the projection of the RIB on the wall and the related parms
	    	crossing_point(line(1),line(2), robot_pos, [^normal_x ^normal_y]) ->
	    	( point, pos, distance );
			
	    	;;; Check if the wall has been hit or trespassed
	    	if ( pos >= 0 and pos <= line(3) and distance <= 0.01
		 		and distance >= -0.05 ) then

				;;; React, by changing the components of RIB velocity
				;;; by putting the object back (with respect to the wall)
				lvars velocity_along_wall, velocity_orthog_wall, new_position;

				rib_x_velocity(a2) * line(2)(1) + rib_y_velocity(a2) * line(2)(2) ->
				velocity_along_wall;
				
				rib_x_velocity(a2) * normal_x + rib_y_velocity(a2) * normal_y ->
				velocity_orthog_wall;

				- 0.1 * velocity_orthog_wall -> velocity_orthog_wall;

				line(2)(1) * velocity_along_wall + normal_x * velocity_orthog_wall ->
				rib_x_velocity(a2);
				
				line(2)(2) * velocity_along_wall + normal_y * velocity_orthog_wall ->
				rib_y_velocity(a2);

				straight_line_point( -0.01, [^normal_x ^normal_y], point ) -> new_position;
				explode(new_position) -> rib_coords(a2);
	    	endif;
		endfor;
    endif
enddefine;

;;;
;;; Method that draws a RIB in the rc_graphic window
;;;

define :method draw_me(a:rib_agent);
	;;; changed drawing procedure. A.S. 13 Sep 2000
	;;; rc_draw_blob(rib_x_pos(a)*400, rib_y_pos(a)*400, 6, 'red');
	rc_draw_coloured_circle(rib_x_pos(a)*400, rib_y_pos(a)*400, 6, 'red', 2);

enddefine;

;;;
;;; Method that draws a box in the rc_graphic window
;;;

define :method draw_me(a:box_agent);
    lvars line;

    fast_for line in box_walls(a) do
		arctan2(line(2)(1), line(2)(2) ) -> rc_heading;
		rc_jumpto(line(1)(1)*400,line(1)(2)*400);
		rc_draw(line(3)*400);
    endfor;
enddefine;

;;;
;;; Method that prints a RIB
;;;

define :method print_instance(item:rib_agent);
    printf(
	   '<agent name:%p (x,y)=(%p, %p) (vx,vy)=(%p, %p)>',
	   [% sim_name(item), rib_coords(item),
	      rib_x_velocity(item), rib_y_velocity(item) %])
enddefine;

;;;
;;; Some tracing stuff
;;;

define :method sim_agent_running_trace(agent:sim_agent);
/*
    '------------------------------------------------------' =>
    [running ^(sim_name(agent))] ==>
	prb_print_database();
*/
/*
	lvars len = stacklength();
	[DEBUG running stacklength ^len] =>
*/
enddefine;

define :method sim_agent_ruleset_trace(agent:sim_agent, ruleset);
	
/*
	['Try ruleset' ^ruleset 'with agent' ^(sim_name(agent)) 'with data:']==>
	prb_print_database();
*/
enddefine;


define sim_scheduler_pausing_trace(agents, cycle);
	;;; 'DRAWING' =>
	applist(agents, draw_me);
	pr('\n================= end of cycle ' >< cycle >< ' =================\n');
enddefine;

;;;
;;; Variable containing an already-trained neural net for obstacle avoidance
;;;

vars obstacle_avoidance_net =
     [
      [prudence 0.9]
      [network [obstacle_avoidance_net [network_type backpropagation ]]]
      [network [obstacle_avoidance_net [epsilon 0.5 ]]]
      [network [obstacle_avoidance_net [random_scale 0.5 ]]]
      [network [obstacle_avoidance_net [already_taught]]]
      [network [obstacle_avoidance_net [iterations_number 10000 10000 100 ]]]
      [network [obstacle_avoidance_net [tss 1.00606 ]]]
      [network [obstacle_avoidance_net [tss_limit 0.001 ]]]
      [network [obstacle_avoidance_net [unit s0 input sigmoid 0 0 0 0 ]]]
      [network [obstacle_avoidance_net [unit s45 input sigmoid 0 0 0 0 ]]]
      [network [obstacle_avoidance_net [unit s90 input sigmoid 0 0 0 0 ]]]
      [network [obstacle_avoidance_net [unit s135 input sigmoid 0 0 0 0 ]]]
      [network [obstacle_avoidance_net [unit s180 input sigmoid 0 0 0 0 ]]]
      [network [obstacle_avoidance_net [unit s225 input sigmoid 0 0 0 0 ]]]
      [network [obstacle_avoidance_net [unit s270 input sigmoid 0 0 0 0 ]]]
      [network [obstacle_avoidance_net [unit s315 input sigmoid 0 0 0 0 ]]]
      [network [obstacle_avoidance_net [unit hid1 hidden sigmoid 0 0 0 2.02509 ]]]
      [network [obstacle_avoidance_net [unit hid2 hidden sigmoid 0 0 0 -3.97371 ]]]
      [network [obstacle_avoidance_net [unit hid3 hidden sigmoid 0 0 0 -0.664199 ]]]
      [network [obstacle_avoidance_net [unit hid4 hidden sigmoid 0 0 0 -2.4641 ]]]
      [network [obstacle_avoidance_net [unit out1 output sigmoid 0 0 0 4.2977 ]]]
      [network [obstacle_avoidance_net [unit out2 output sigmoid 0 0 0 -4.7661 ]]]
      [network [obstacle_avoidance_net [unit out3 output sigmoid 0 0 0 -6.39415 ]]]
      [network [obstacle_avoidance_net [unit out4 output sigmoid 0 0 0 -3.81816 ]]]
      [network [obstacle_avoidance_net [threshold out1 0.7 ]]]
      [network [obstacle_avoidance_net [threshold out2 0.7 ]]]
      [network [obstacle_avoidance_net [threshold out3 0.7 ]]]
      [network [obstacle_avoidance_net [threshold out4 0.7 ]]]
      [network [obstacle_avoidance_net
		[connection hid1 [s0 s45 s90 s135 s180 s225 s270 s315]
 		 [-5.09873 -0.299104 5.84031 5.37842 0.710461
		  -9.67387 -5.12095 -9.65697] ]]]
      [network [obstacle_avoidance_net
		[connection hid2 [s0 s45 s90 s135 s180 s225 s270 s315]
 		 [5.98406 5.34389 -2.42444 6.88658 -6.03678
		  0.216472 1.33844 1.0098] ]]]
      [network [obstacle_avoidance_net
		[connection hid3 [s0 s45 s90 s135 s180 s225 s270 s315]
 		 [3.27399 7.83451 5.46345 2.46087 -4.43878
		  -2.99069 -0.572822 -0.990682] ]]]
      [network [obstacle_avoidance_net
		[connection hid4 [s0 s45 s90 s135 s180 s225 s270 s315]
 		 [0.288599 -3.34813 0.780455 -1.09771 4.46592
		  -1.86496 7.21859 4.73541] ]]]
      [network [obstacle_avoidance_net
		[connection out1 [hid1 hid2 hid3 hid4]
 		 [7.28923 -6.705 -14.7134 -8.22489] ]]]
      [network [obstacle_avoidance_net
		[connection out2 [hid1 hid2 hid3 hid4]
 		 [-11.8416 10.7207 0.620431 -0.785414] ]]]
      [network [obstacle_avoidance_net
		[connection out3 [hid1 hid2 hid3 hid4]
 		 [9.86573 -2.57715 4.74645 -11.294] ]]]
      [network [obstacle_avoidance_net
		[connection out4 [hid1 hid2 hid3 hid4]
 		 [-9.97808 -7.74123 -3.78862 10.2219] ]]]
      [network [obstacle_avoidance_net [example [0 0 0 0 0 0 0 1] [0 0 0 1] ]]]
      [network [obstacle_avoidance_net [example [0 0 0 0 0 0 1 0] [0 0 0 1] ]]]
      [network [obstacle_avoidance_net [example [0 0 0 0 0 1 0 0] [1 0 0 0] ]]]
      [network [obstacle_avoidance_net [example [0 0 0 0 1 0 0 0] [1 0 0 0] ]]]
      [network [obstacle_avoidance_net [example [0 0 0 1 0 0 0 0] [0 0 1 0] ]]]
      [network [obstacle_avoidance_net [example [0 0 1 0 0 0 0 0] [0 0 1 0] ]]]
      [network [obstacle_avoidance_net [example [0 1 0 0 0 0 0 0] [0 0 1 0] ]]]
      [network [obstacle_avoidance_net [example [1 0 0 0 0 0 0 0] [0 1 0 0] ]]]
      [network [obstacle_avoidance_net [example [0 0 0 0 0 1 1 0] [0 0 0 1] ]]]
      [network [obstacle_avoidance_net [example [0 0 0 0 1 0 0 1] [0 0 0 1] ]]]
      [network [obstacle_avoidance_net [example [0 0 0 1 0 0 0 1] [0 1 0 0] ]]]
      [network [obstacle_avoidance_net [example [0 0 0 1 0 1 0 0] [0 1 0 0] ]]]
      [network [obstacle_avoidance_net [example [0 0 0 1 1 0 0 0] [1 0 0 0] ]]]
      [network [obstacle_avoidance_net [example [0 0 1 0 1 0 0 0] [0 1 0 0] ]]]
      [network [obstacle_avoidance_net [example [0 1 0 0 0 0 0 1] [0 1 0 0] ]]]
      [network [obstacle_avoidance_net [example [0 1 0 0 0 0 1 0] [0 1 0 0] ]]]
      [network [obstacle_avoidance_net [example [0 1 0 0 1 0 0 0] [0 0 1 0] ]]]
      [network [obstacle_avoidance_net [example [0 1 0 1 0 0 0 0] [0 0 1 0] ]]]
      [network [obstacle_avoidance_net [example [0 1 1 0 0 0 0 0] [0 0 1 0] ]]]
      [network [obstacle_avoidance_net [example [1 0 0 0 0 0 0 1] [0 1 0 0] ]]]
      [network [obstacle_avoidance_net [example [1 0 0 0 0 0 1 0] [0 1 0 0] ]]]
      [network [obstacle_avoidance_net [example [1 0 0 0 1 0 0 0] [0 0 0 1] ]]]
      [network [obstacle_avoidance_net [example [1 0 0 1 0 0 0 0] [0 0 1 0] ]]]
      [network [obstacle_avoidance_net [example [1 0 1 0 0 0 0 0] [0 0 1 0] ]]]
      [network [obstacle_avoidance_net [example [1 1 0 0 0 0 0 0] [0 1 0 0] ]]]
      ];


;;;
;;; Variable containing a neural net for wall-following. The net has not been
;;; trained yet.
;;;

vars wall_following_net =
     [
[network [wall_following_net [user_interactor rib_interactor]]]
[number_of_examples wall_following_net 1304]
[prudence 0.5]
[network [wall_following_net [network_type backpropagation]]]
[network [wall_following_net [epsilon 1]]]
[network [wall_following_net [random_scale 0.1]]]
[network [wall_following_net [already_taught]]]
[network [wall_following_net [iterations_number 1000 1000 1000]]]
[network [wall_following_net [tss 1.09391]]]
[network [wall_following_net [tss_limit 0.001]]]
[network [wall_following_net [unit vx input sigmoid 0 0 0 0]]]
[network [wall_following_net [unit vy input sigmoid 0 0 0 0]]]
[network [wall_following_net [unit s0 input sigmoid 0 0 0 0]]]
[network [wall_following_net [unit s45 input sigmoid 0 0 0 0]]]
[network [wall_following_net [unit s90 input sigmoid 0 0 0 0]]]
[network [wall_following_net [unit s135 input sigmoid 0 0 0 0]]]
[network [wall_following_net [unit s180 input sigmoid 0 0 0 0]]]
[network [wall_following_net [unit s225 input sigmoid 0 0 0 0]]]
[network [wall_following_net [unit s270 input sigmoid 0 0 0 0]]]
[network [wall_following_net [unit s315 input sigmoid 0 0 0 0]]]
[network [wall_following_net [unit hid1 hidden sigmoid 0 0 0 -6.60755]]]
[network [wall_following_net [unit hid2 hidden sigmoid 0 0 0 -7.95852]]]
[network [wall_following_net [unit hid3 hidden sigmoid 0 0 0 -5.16184]]]
[network [wall_following_net [unit hid4 hidden sigmoid 0 0 0 -4.49216]]]
[network [wall_following_net [unit hid5 hidden sigmoid 0 0 0 -10.0618]]]
[network [wall_following_net [unit hid6 hidden sigmoid 0 0 0 -3.27062]]]
[network [wall_following_net [unit hid7 hidden sigmoid 0 0 0 -6.17249]]]
[network [wall_following_net [unit hid8 hidden sigmoid 0 0 0 -0.669802]]]
[network [wall_following_net [unit hid9 hidden sigmoid 0 0 0 -3.853]]]
[network [wall_following_net [unit hid10 hidden sigmoid 0 0 0 -3.64311]]]
[network [wall_following_net [unit ax output sigmoid 0 0 0 0.141148]]]
[network [wall_following_net [unit ay output sigmoid 0 0 0 0.059711]]]
[network [wall_following_net [connection hid1 [s0 s45 s90 s135 s180 s225 s270 s315 vx vy] [-9.76561 -2.50229 -0.683223 4.39233 1.65536 -5.70715 7.98716 6.53387 -7.14152 -0.062346]]]]
[network [wall_following_net [connection hid2 [s0 s45 s90 s135 s180 s225 s270 s315 vx vy] [-6.65232 3.24245 -0.058204 4.74465 -2.72697 3.60912 5.37343 1.46272 11.5197 -5.24728]]]]
[network [wall_following_net [connection hid3 [s0 s45 s90 s135 s180 s225 s270 s315 vx vy] [-2.0617 7.56035 3.01422 -3.46583 -1.73969 11.785 -7.2023 -2.48849 0.366625 1.47064]]]]
[network [wall_following_net [connection hid4 [s0 s45 s90 s135 s180 s225 s270 s315 vx vy] [2.57591 -11.9923 17.2947 1.04707 -14.0294 -0.68774 3.99187 11.8849 5.51283 1.07625]]]]
[network [wall_following_net [connection hid5 [s0 s45 s90 s135 s180 s225 s270 s315 vx vy] [-4.60893 9.68056 2.69316 2.88245 1.04207 8.33268 -1.07976 -0.524123 -3.92323 9.72734]]]]
[network [wall_following_net [connection hid6 [s0 s45 s90 s135 s180 s225 s270 s315 vx vy] [1.8728 -1.29978 -4.95859 -0.617939 -0.928202 2.82443 -0.244241 -2.97372 3.82727 27.1123]]]]
[network [wall_following_net [connection hid7 [s0 s45 s90 s135 s180 s225 s270 s315 vx vy] [3.1733 -5.79059 -3.26095 9.0703 -6.8273 -6.10824 9.44549 -3.73538 -20.5882 9.06818]]]]
[network [wall_following_net [connection hid8 [s0 s45 s90 s135 s180 s225 s270 s315 vx vy] [-2.2557 -0.87794 1.59909 -6.00038 -1.0042 3.64614 -2.06068 -1.58912 9.01521 -9.68156]]]]
[network [wall_following_net [connection hid9 [s0 s45 s90 s135 s180 s225 s270 s315 vx vy] [0.607022 -3.87469 -1.28751 0.573758 3.14436 -4.65316 0.884741 1.67946 12.1052 6.66163]]]]
[network [wall_following_net [connection hid10 [s0 s45 s90 s135 s180 s225 s270 s315 vx vy] [1.99738 -2.52996 0.193929 1.18704 -3.54298 3.93179 -1.33016 -0.277606 -5.25301 -5.92017]]]]
[network [wall_following_net [connection ax [hid1 hid2 hid3 hid4 hid5 hid6 hid7 hid8 hid9 hid10] [1.07006 -2.98458 -0.672061 -0.201309 0.849293 -6.28495 6.8044 1.38914 -5.14957 3.24073]]]]
[network [wall_following_net [connection ay [hid1 hid2 hid3 hid4 hid5 hid6 hid7 hid8 hid9 hid10] [-0.290224 0.967176 -0.02786 -0.170044 -0.457602 -7.39155 -3.51529 1.15638 1.72924 3.55404]]]]
      ];
	
;;;
;;; Neural predicate (filter) for obstacle avoidance.
;;; Only proximity (touch) sensors are used in the related rule.
;;;

define ann_ob_avoid_predicate( rule_conditions, condition_pattern ) -> action_pattern;
    lvars one_true;

	;;; is the database used???
    dlocal database = obstacle_avoidance_net;
    ;;; A.S. Sat Dec 10 17:32:06 GMT 1994
	;;;;[DEBUG obstacle ^condition_pattern] ==>

    fast_for one_true in condition_pattern do
	if ( one_true ) then
    	    binary2boolean(ann_predicate(boolean2binary(condition_pattern),
				 "obstacle_avoidance_net" )) -> action_pattern;
	    return;
	endif;
    endfor;
    false -> action_pattern;
enddefine;


;;; Approach procedure added A.S.Sun Dec 11 00:11:38 GMT 1994
define which_min( input_list ) -> (index, min_value);
    lvars
		min_value = 1e30,
		item,
		i = 1,
		index = false;

    fast_for item in input_list do
		if item < min_value then
	    	item -> min_value;
			i -> index;
      	endif;
		i fi_+ 1 -> i;
    endfor;
enddefine;

global vars approach_threshold = 0.1;

define ann_wall_approaching_predicate( rule_conditions, condition_pattern )
    		-> action_pattern;
	;;; condition pattern should have items matching
	;;; [new_sense_data range sensor0 =]
	;;; [new_sense_data range sensor45 =]
	;;;  ... etc/
	;;; unless within close proximity, go to nearest wall, and turn left

    ;;; [DEBUG condition_pattern ^condition_pattern] ==>

	;;; ignore velocities
	lvars item, index, min_value, sensor_values;
		[%
			 fast_for item in condition_pattern do
			     item(1)(4);
			 endfor
			 %] -> sensor_values;
	which_min(sensor_values) -> (index, min_value);

	if min_value >  approach_threshold then
		;;; say in which direction to accelerate
		maplist(
			[1 2 3 4 5 6 7 8],
			procedure(item); item == index endprocedure)
	else
		false
	endif -> action_pattern;

enddefine;


;;;
;;; Neural predicate (filter) for wall following.
;;; Only range data are used in the related rule.
;;;

;;; A.S. added net_output lvars. Also got rid of uninitialised ^network
define ann_wall_following_predicate( rule_conditions, condition_pattern )
    			-> action_pattern;

    lvars item, net_output;

    dlocal database = wall_following_net;


    ;;; [DEBUG condition_pattern ^condition_pattern] ==>

    ;;; If there are more than min_example_num_for_using examples just use the net
	;;;;    if present( [network [^network [already_taught]]]) then ;;; A.S.Sat Dec 10 13:37:33 GMT 1994
    if present( [network [wall_following_net [already_taught]]]) then
		lvars sensor_values;		;;; A.S. added Sat Dec 10 23:52:07 GMT 1994
		[%
			fast_for item in condition_pattern do
			    item(1)(4);
			endfor
		%] -> sensor_values;
		if abs(sensor_values(1)) > 0.001 or abs(sensor_values(2)) > 0.001 then
			;;; already moving so react only if near something
		    if find_min(back(back(sensor_values))) > 0.2 then
				false -> action_pattern;
				;;;;;;				return();
			endif;
		endif;

    	eval_network( sensor_values, "wall_following_net" ) -> net_output;
		[acceleration ^((net_output(1) - 0.5) * 0.1) ^((net_output(2) - 0.5) * 0.1)] ->

		action_pattern;
		
    else
		;;; Otherwise ask for an example, and use it
		
    	lvars example_number;
    	flush( ![number_of_examples wall_following_net ?example_number]);
    	eval_network( [%
			 	fast_for item in condition_pattern do
			     	item(1)(4);
			 	endfor
			%], "wall_following_net" )
    		-> net_output;
		[acceleration ^((net_output(1) - 0.5) * 0.1) ^((net_output(2) - 0.5) * 0.1)] ->
		action_pattern;
		add([number_of_examples wall_following_net ^(example_number+1)]);

    endif;
	;;; [DEBUG 'wall_following' action_pattern ^action_pattern] ==>
    database -> wall_following_net;
enddefine;

define ann_wall_following_map( the_variable, something, something_else );

	;;; [DEBUG 'wall_following addition' ^the_variable] ==>
    prb_add(the_variable);
enddefine;

;;;
;;; Rules for RIBs
;;;

;;; max_distance is the a distance from the endge beyond which this
;;; 	rule won't fire
;;; min_motion is the minimum change that must be detected in the sensor
;;; 	for the rule to fire
;;; min_following is the minimum speed along the surface for this
;;; 	rule to fire.
vars max_distance = 0.125, min_motion = 0.1, min_following = 0.005;

define :ruleset startup_rib;
	;;; cleanup records of previous firing
	RULE start_cycle
	==>
	[NOT == fired]
enddefine;

define :ruleset rib_rules;


	;;; reduced pulses to fit better with others
  RULE novelty_detection0  ;;; in rib_rules

	;;; [VARS x vy]
    [NOT novelty_detection0 rule fired]
    [new_sense_data motion sensor0 ?x]
    [new_sense_data velocity y ?vy]
    [WHERE x > min_motion and vy > min_following and
     rib_old_sensor(sim_myself)("sensor0") < max_distance]
      ==>
    ;;; [acceleration 0.02 -0.015]
    [acceleration 0.02 -0.018]
    [novelty_detection0 rule fired]
    [SAY 'novelty 0']

  RULE novelty_detection90  ;;; in rib_rules

	;;; [VARS x vx]
    [NOT novelty_detection90 rule fired]
    [new_sense_data motion sensor90 ?x]
    [new_sense_data velocity x ?vx]
    [WHERE x > min_motion and vx < -min_following and
     rib_old_sensor(sim_myself)("sensor90") < max_distance ]
      ==>
    ;;; [acceleration 0 0.02]
    ;;; [acceleration 0.015 0.02]
    [acceleration 0.018 0.02]
    [novelty_detection90 rule fired]
    [SAY 'novelty 90']

  RULE novelty_detection180  ;;; in rib_rules

	;;; [VARS x vy]
    [NOT novelty_detection180 rule fired]
    [new_sense_data motion sensor180 ?x]
    [new_sense_data velocity y ?vy]
    [WHERE x > min_motion and vy < -min_following and
     rib_old_sensor(sim_myself)("sensor180") < max_distance ]
      ==>
    ;;; [acceleration -0.02 0]
    ;;; [acceleration -0.02 0.015]
    [acceleration -0.02 0.018]
    [novelty_detection180 rule fired]
    [SAY 'novelty 180']

  RULE novelty_detection270  ;;; in rib_rules

	;;; [VARS x vx]
    [NOT novelty_detection270 rule fired]
    [new_sense_data motion sensor270 ?x]
    [new_sense_data velocity x ?vx]
    [WHERE x > min_motion and vx > min_following and
     rib_old_sensor(sim_myself)("sensor270") < max_distance ]
      ==>
    ;;; [acceleration 0 -0.02]
    ;;; [acceleration -0.015 -0.02]
    [acceleration -0.018 -0.02]
    [novelty_detection270 rule fired]
    [SAY 'novelty 270']

  RULE obstacle_avoidance  ;;; in rib_rules

    [NOT obstacle_avoidance rule fired]
    [FILTER ann_ob_avoid_predicate -> ann_ob_avoid_output
     [new_sense_data touch sensor0]
     [new_sense_data touch sensor45]
     [new_sense_data touch sensor90]
     [new_sense_data touch sensor135]
     [new_sense_data touch sensor180]
     [new_sense_data touch sensor225]
     [new_sense_data touch sensor270]
     [new_sense_data touch sensor315]
     ]
      ==>
    [SELECT ?ann_ob_avoid_output
	;;; A.S. reduced accelerations from +/- 0.0025
	;;; also added tangential accelerations to help wall following
     [acceleration 0.006 -0.01] 	;;; sensor 180 touched
     [acceleration -0.006 0.01]		;;; sensor 0 touched
     [acceleration -0.01 -0.006]	;;; sensor 90 touched
     [acceleration 0.01 0.006]		;;; sensor 270 touched
     ]
    [obstacle_avoidance rule fired]
	;;; A.S. Sat Dec 10 17:35:40 GMT 1994
	;;; [SAY 'Bounced']
	;;; [POP11 prb_present([new_sense_data touch ==])=>
	;;;		prb_present([acceleration ==]) =>]

  RULE wall_approaching  ;;; in rib_rules

    [NOT wall_approaching rule fired]
    [FILTER ann_wall_approaching_predicate -> ann_wall_approaching_output
     [new_sense_data range sensor0 =]
     [new_sense_data range sensor45 =]
     [new_sense_data range sensor90 =]
     [new_sense_data range sensor135 =]
     [new_sense_data range sensor180 =]
     [new_sense_data range sensor225 =]
     [new_sense_data range sensor270 =]
     [new_sense_data range sensor315 =]
     ]
	;;; [POP11 'Approaching needed'=> ]
      ==>
    [SELECT ?ann_wall_approaching_output
		[acceleration 0.007 0.0025 ]
		[acceleration 0.003 0.006 ]
		[acceleration -0.0025  0.007]
		[acceleration -0.006  0.003]
		[acceleration -0.007 -0.0025]
		[acceleration -0.003 -0.006]
		[acceleration 0.0025 -0.007]
		[acceleration 0.006 -0.003]
     ]
    [wall_approaching rule fired]
    ;;; [SAY 'wall_approaching rule fired' ]

	;;; [POP11 prb_print_database() ]


  RULE wall_following  ;;; in rib_rules

    [NOT wall_following rule fired]
    [FILTER ann_wall_following_predicate -> ann_wall_following_output
     [new_sense_data velocity x =]
     [new_sense_data velocity y =]
     [new_sense_data range sensor0 =]
     [new_sense_data range sensor45 =]
     [new_sense_data range sensor90 =]
     [new_sense_data range sensor135 =]
     [new_sense_data range sensor180 =]
     [new_sense_data range sensor225 =]
     [new_sense_data range sensor270 =]
     [new_sense_data range sensor315 =]
     ]
	;;;	[POP11 'following test passed' =>]
      ==>
    [MAP ?ann_wall_following_output ann_wall_following_map
     [NULL]
     ]
    [wall_following rule fired]
    ;;; [SAY 'wall_following rule fired']


  RULE apply_pulse  ;;; in rib_rules
     [acceleration ?ax ?ay]
	;;;	 [POP11 [accelerating ?ax ?ay] => ]
       ==>
     [DEL 1]
     [POP11
		;;; A.S. Made one action. Sat Dec 10 23:49:10 GMT 1994
		ax + rib_x_velocity(sim_myself) -> rib_x_velocity(sim_myself);
     	ay + rib_y_velocity(sim_myself) -> rib_y_velocity(sim_myself)]

	;;; [SAY pulse ?ax ?ay]


  RULE motion  ;;; in rib_rules

    [NOT motion rule fired]
      ==>
	
    [POP11
	 ;;; 'Firing motion rule' =>
	 ;;; [Old pos %rib_coords(sim_myself)%]=>
	 rib_x_pos(sim_myself) + rib_x_velocity(sim_myself),
	 rib_y_pos(sim_myself) + rib_y_velocity(sim_myself) ->
     		rib_coords(sim_myself);
	 ;;; [New pos %rib_coords(sim_myself)%]=>
	]
    [motion rule fired]

  RULE sense_last  ;;; in rib_rules

    [NOT acceleration ==]
      ==>
    [POP11 lvars sensor, value;
		prb_foreach(![new_sense_data range ?sensor ?value],
		       procedure();
					value -> rib_old_sensor(sim_myself)(sensor);
		       endprocedure )]
    [NOT new_sense_data ==]
    [NOT = rule fired]
    [STOP]
enddefine;


;;;
;;; Now the processing architectures
;;; A.S. 13 Sep 2000
;;;

define :rulesystem rib_rulesets;
	include: startup_rib
    include: rib_rules
enddefine;

define :rulesystem box_rulesets;
	;;; empty by default
	include: box_rules
enddefine;


;;;
;;; A procedure for setting the state of a RIB
;;;

define set_state( rib, x, y, vx, vy );

    x -> rib_x_pos(rib);
    y -> rib_y_pos(rib);
    vx -> rib_x_velocity(rib);
    vy -> rib_y_velocity(rib);
enddefine;

define set_maze( rib, box );
    [
     [[0 0] [1 0] 1]
     [[1 0] [0 1] 0.6]
     [[1 0.8] [0 1] 0.2]
     [[1 1] [-1 0] 1]
     [[0 1] [0 -1] 1]
     [[0.2 0] [0 1] 0.6]
     [[0.2 0.6] [1 0] 0.1]
     [[0.3 0.6][0 -1] 0.6]
     [[0.7 1][0 -1] 0.6]
     [[0.7 0.4][-1 0] 0.1]
     [[0.6 0.4][0 1] 0.6]
     ] -> box_walls(box);

    0.1 -> rib_x_pos(rib);
    0.2 -> rib_y_pos(rib);
    0.0 -> rib_x_velocity(rib);
    0 -> rib_y_velocity(rib);
enddefine;



;;;
;;; Instance of a RIB
;;;

define :instance ribot:rib_agent;
    sim_name = "RIB";
    sim_cycle_limit = 20;
    rib_x_pos = 0.65;
    rib_y_pos = 0.6;
    rib_x_velocity = -0.01;
    rib_y_velocity = 0.00;
enddefine;

;;;
;;; Instance of the box (environment)
;;; Different box_walls. Select by commenting and uncommenting
;;;

define :instance the_box:box_agent;
    sim_name = "The_Box";
/*
    box_walls = [
		 [[0 0] [1 0] 1]
		 [[1 0] [0 1] 0.5]
		 [[1 0.5] [-1 0] 0.3]
		 [[0.7 0.5] [0 1] 0.3]
		 [[0.7 0.8] [1 0] 0.3]
		 [[1 0.8] [0 1] 0.2]
		 [[1 1] [-1 0] 1]
		 [[0 1] [0 -1] 1]

		 [[0.2 0.2] [0 1] 0.2]
		 [[0.2 0.4] [1 0] 0.2]
		 [[0.4 0.4] [0 -1] 0.2]
		 [[0.4 0.2] [-1 0] 0.2]
		 ];

*/
/*
    box_walls = [
		 [[0 0] [1 0] 1]
		 [[1 0] [0 1] 0.6]
		 [[1 0.8] [0 1] 0.2]
		 [[1 1] [-1 0] 1]
		 [[0 1] [0 -1] 0.6]
		 [[0 0.2] [0 -1] 0.2]
		 ];
*/
    box_walls = [
		 [[0 0] [1 0] 1]
		 [[1 0] [0 1] 0.5]
		 [[1 0.5] [-1 0] 0.2]
		 [[0.8 0.5] [0 1] 0.2]
		 [[0.8 0.7] [1 0] 0.2]
		 [[1 0.7] [0 1] 0.3]
		 [[1 1] [-1 0] 1]
		 [[0 1] [0 -1] 1]

		 [[0.25 0.25] [0 1] 0.2]
		 [[0.25 0.45] [1 0] 0.2]
		 [[0.45 0.45] [0 -1] 0.2]
		 [[0.45 0.25] [-1 0] 0.2]
		 ];
enddefine;


;;;
;;; Main procedure that starts the simulation
;;;

define go_for(steps);

    vars all_agents = [^ribot ^the_box];

    sim_scheduler(all_agents, steps);

	pr('To continue do\ngo_for(' >< steps ><');');
enddefine;

define go(steps);
    lvars agnt;

    rc_start();
    50 -> rc_xorigin;
    450 -> rc_yorigin;
    global vars all_agents = [^ribot ^the_box];

    for agnt in all_agents do
	draw_me(agnt)
    endfor;

    true -> prb_chatty;
    false -> prb_chatty;

    true -> prb_walk;
    false -> prb_walk;

    go_for(steps);
enddefine;

;;;
;;; A procedure for the automatic training of a RIB
;;;

vars global_curve_store =[];

define rib_interactor(input_list, network) -> output_list;

    lvars sensors = tl(tl(input_list));

    ;;; [DEBUG sensors ^sensors]==>

    [%
       front(hd(global_curve_store)) * 10 + 0.5;
       back(hd(global_curve_store))  * 10 + 0.5;
       %] -> output_list;

    tl(global_curve_store) -> global_curve_store;
enddefine;


;;;
;;; Fire all the fireable rules
;;;

/*
define prb_sortrules(inrules) -> outrules;

    inrules -> outrules;
enddefine;
*/

;;;
;;; Simple procedure to train the RIB
;;;

;;; defined below A.S. Sat Dec 10 17:37:49 GMT 1994
vars procedure (get_curve, sample, smoothcurve, eval_accelerations);

define rib_train(ncurves);
    lvars rib, velocity, curve, polyline;

    rc_start();
    50 -> rc_xorigin;
    450 -> rc_yorigin;
    draw_me(the_box);

    repeat ncurves times
	get_curve(the_box,false) -> polyline;
	for velocity from 8 by 4 to 16 do
    	    smoothcurve(sample(polyline, velocity ),0.75) -> curve;
	
	    eval_accelerations( curve, velocity ) -> global_curve_store;
	    set_state(ribot,front(hd(curve))/400,back(hd(curve))/400,
    	    	      (front(hd(tl(curve))) - front(hd(curve))) / 400,
    	    	      (back(hd(tl(curve))) - back(hd(curve))) / 400 );
	    go_for(length(curve)-1);
	endfor;
    endrepeat;
enddefine;

;;;
;;; User interaction procedure for example acquisition
;;;

uses rc_mouse;

;;;
;;; Procedure to sample a polyline
;;;

define sample(lines, step_len ) -> points;
    lvars
		start_point, end_point, coordinate, line_len,
	  	point, dx, dy;

    [%
      hd(lines) -> start_point;
      tl(lines) -> lines;
      fast_for end_point in lines do
	  sqrt( (front(start_point) - front(end_point))**2 +
	      	(back(start_point) - back(end_point))**2 ) -> line_len;
	  nextif( line_len == 0 );
	  (front(end_point) - front(start_point)) / line_len -> dx;
	  (back(end_point) - back(start_point)) / line_len -> dy;
	  for coordinate from 0 by step_len to line_len do
	      destlist(straight_line_point( coordinate,
					    [^dx ^dy],
					    [% destpair(start_point) %] )) ->;
	      conspair();
	  endfor;
	  end_point -> start_point;
      endfor;
      end_point;
      %] -> points;
enddefine;

;;;
;;; Draw a list of points as a polyline
;;;

define drawcurve(pointlist);
    lvars pointlist, point;

    ;;; Jump to the first point
    rc_jumpto(front(pointlist));

    ;;; Draw the successive following points
    for point in pointlist do rc_drawto(point) endfor
enddefine;

;;;
;;; Smooth curve (list of points)
;;;

define smoothcurve(pointlist,alpha) -> smoothed_curve;
    lvars point, smoothed_point;
    lvars oneminusalpha = 1.0 - alpha;

    [%
      hd(pointlist) -> smoothed_point;
      ;;; Smooth the successive following points
      for point in pointlist do
	  conspair(front(point) * oneminusalpha +
		   front(smoothed_point) * alpha,
		   back(point) * oneminusalpha +
		   back(smoothed_point) * alpha)
	  ->> smoothed_point;
      endfor;
      %] -> smoothed_curve;
enddefine;

;;;
;;; Get an hand-drawn curve
;;;

define get_curve(box, redraw ) -> list_of_lines;
    lvars example;

    if redraw then
	rc_start();
    	50 -> rc_xorigin;
    	450 -> rc_yorigin;
	draw_me(box);
    endif;

    rc_mouse_draw(true,3) -> list_of_lines;
enddefine;

/*
drawcurve(get_curve(the_box,true));
*/

;;;
;;; Given an initial velocity (the length of the velocity vector),
;;; the following procedure evaluates the accelerations
;;; needed to stay as near as possible to the given trajectory
;;;

define eval_accelerations( trajectory, distance ) -> accelerations;
    lvars vx, vy, prev_position, position, new_position, new_vx, new_vy;

    hd(trajectory) -> prev_position;
    tl(trajectory) -> trajectory;
    hd(trajectory) -> position;
    tl(trajectory) -> trajectory;
    (front(position) - front(prev_position)) / 400  -> vx;
    (back(position)  - back(prev_position) ) / 400  -> vy;

    [%
      conspair(0,0);
      fast_for new_position in trajectory do
    	  (front(new_position) - front(position)) / 400 -> new_vx;
    	  (back(new_position)  - back(position) ) / 400 -> new_vy;
    	  conspair(new_vx - vx, new_vy - vy);
	  new_vx -> vx;
	  new_vy -> vy;
	  new_position -> position;
      endfor;
      %] -> accelerations;
enddefine;
