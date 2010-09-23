/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/brait/teach/tests.p
 > Purpose:         test vehicles and experiments.
 > Author:          Duncan K Fewkes, Aug 30 2000
 > Documentation:
 > Related Files:	$poplocal/local/brait/lib/tests.p
 */

;;; include ~msc38dkf/working.dir/brait/lib/braitenberg_sim.p;
;;; uses brait
;;; uses braitenberg_sim

compilehere
	../lib/braitenberg_sim.p
	;

/*

define:method controller(me:vehicle, sensor_data);

    ;;;sensor_data==>;

    1-> left_motor_speed(me);
    20-> right_motor_speed(me);

enddefine;

create_vehicle(
    200.0 , 120.0,
    1000, 1000, 90,
    controller,
    [],
    [[sound 'left' 1][sound 'right' 1]
        [odometer left][odometer right][compass]],
    [])->vehicle;

control_panel();


*/


/*
define:method controller(me:vehicle, sensor_data);

    ;;;sensor_data==>;

    if left_motor_speed(me) <= 0 then
        100 -> left_motor_speed(me);
    else
        left_motor_speed(me) - 1 -> left_motor_speed(me);
    endif;

    10 -> right_motor_speed(me);

enddefine;

create_vehicle(
200.0 , 120.0,
1000, 1000, 90,
controller,
[],
[[odometer left][odometer right][compass]],
[])->vehicle;

control_panel();
*/



/*

create_window(500,500);


create_vehicle(
200.0 , 120.0,
400, 400, 90,
[[0 0 1 -0.1] [0 0 -0.1 1]
[0 0 0 0][0 0 0 0]],
[[basic_unit] [basic_unit]
[basic_unit]
[basic_unit]],
[[proximity 'left' 0.7][proximity 'right' 0.7] ],
[])->vehicle;

create_source( 1500, 1500, [[sound 100.00 %exponential_decay% 200.00]]) -> source1;
create_source( 1500, 500, [[smell 100.00 %exponential_decay% 200.00]]) -> source2;

control_panel();


*/
/*
create_vehicle(
200.0 , 120.0,
1000, 1000, 90,
[[0 0 -0.2 1][0 0 1 -0.2]
[0 0 0 0][0 0 0 0]],
[[basic_unit]
    [basic_unit]
    [basic_unit]
    [basic_unit]],
[[light 'left' 1][light 'right' 1] ],
[])->vehicle;

create_simple_ball(200,200, sound) ->ball1;
control_panel();

*/

/*
create_ball(200,200,150,[])->ball1;
control_panel();

35 -> heading(ball1);
2000 -> speed(ball1);

1 -> bounciness(ball1);

*/

/*

create_vehicle(
200.0 , 120.0,
1000, 1000, 90,
[[0 0 -0.2 1][0 0 1 -0.2]
[0 0 0 0][0 0 0 0]],
[[basic_unit]
    [basic_unit]
    [basic_unit]
    [basic_unit]],
[[sound 'left' 1][sound 'right' 1] ],
[])->vehicle;

create_ball(200,200, 150, [[sound 100 exponential_decay 200]] ) ->ball1;
;;;create_ball(200,200, 400, [[sound 100 exponential_decay 200]] ) ->ball1;

create_box([[100 100] [1900 100] [1900 1900] [100 1900]])->box1;

control_panel();

print_vehicle_data_log(vehicle);
*/


/*
    define:method obstacle_avoider(me:vehicle, sensor_data);

        lvars left = 0, right = 0;

        if sensor_data(3) > sensor_data(1) then
            sensor_data(3) - sensor_data(1) + right -> right;
        elseif sensor_data(1) > sensor_data(3) then
            sensor_data(1) - sensor_data(3) + left -> left;
        endif;

        if sensor_data(2) > sensor_data(4) then
            sensor_data(2) - sensor_data(4) + left -> left;
        elseif sensor_data(4) > sensor_data(2) then
            sensor_data(4) - sensor_data(2) + left -> left;
            sensor_data(4) - sensor_data(2) + right -> right;
        endif;

		left -> left_motor_speed(me);
		right -> right_motor_speed(me);

    enddefine;

    create_vehicle(
    200.0 , 120.0,
    1000, 1000, 90,
    obstacle_avoider,
    [],
    [[proximity 'left' 1][proximity 'centre' 1]
    [proximity 'right' 1][proximity 100 180 1]],
    [])->vehicle;

    create_simple_source(200,200,light)-> source;
    create_simple_source(700,700,light)-> source;
    create_box([[100 100] [1900 100] [1900 1900] [100 1900]])->box1;

    control_panel();


*/

/*
define:method remote(me:vehicle, sensor_data);

    slider_value_of_name(remote_control_panel, "sliders", 1) -> left_motor_speed(me);
    slider_value_of_name(remote_control_panel, "sliders", 2) -> right_motor_speed(me);

enddefine;

create_vehicle(
    200.0 , 120.0,
    1000, 1000, 90,
    remote,
    [],
    [],
    [])->vehicle;

create_box([[100 100] [1900 100] [1900 1900] [100 1900]])->box1;

control_panel();

remote_control();
*/

/*

create_vehicle(
200.0 , 150.0,
1000, 1000, 90,
[[0 0.2 0.4]
[0 0 0]
[0 0 0]],
[],
[[compass]],
[])->vehicle;

control_panel(); make_dial_panel(vehicle);

*/

/*
    create_vehicle(
    200.0 , 150.0,
    1000, 1000, 90,
    [[0 0 0 0 0 0]
     [0 0 0 0 0 0]
     [0 0 0 0 0 0]
     [0 0 0 0 0.1 0.2]
     [0 0 0 0 0 0]
     [0 0 0 0 0 0]],
    [[basic_unit]
    [basic_unit]
    [basic_unit]
    [internal_energy]
    [basic_unit]
    [basic_unit]],
    [[compass][odometer left][odometer right]],
    [])->vehicle;

create_vehicle(
200.0 , 150.0,
1000, 1000, 90,
[[0 0.2 0.4]
[0 0 0]
[0 0 0]],
[],
[[compass]],
[])->vehicle2;


    control_panel();
    make_dial_panel(vehicle);
	make_dial_panel(vehicle2);

*/
/*

define:method controller(me:vehicle, sensor_data);

    max(sensor_data(1), sensor_data(2)) -> left_motor_speed(me);
    min(sensor_data(1), sensor_data(2))-> right_motor_speed(me);

enddefine;

create_vehicle(
    200.0 , 120.0,
    1000, 1000, 90,
    controller,
    [],
    [[sound 'left' 1][sound 'right' 1]],
    [])->vehicle;

control_panel();

*/
/*
define:method controller(me:vehicle, sensor_data);

    sensor_data(2) * (random(1.0))-> left_motor_speed(me);
    sensor_data(1) * (random(1.0))-> right_motor_speed(me);

enddefine;

create_vehicle(
    200.0 , 120.0,
    1000, 1000, 90,
    controller,
    [],
    [[sound 'left' 1][sound 'right' 1]],
    [])->vehicle;

control_panel();
*/


/*
define:method controller(me:vehicle, sensor_data);

   	if sensor_data(2)>sensor_data(1) or
	sensor_data(3)>sensor_data(4) then

		1 -> left_motor_speed(me);
        6 -> right_motor_speed(me);

	elseif sensor_data(1)>sensor_data(2) or
	sensor_data(4)>sensor_data(3) then

        6 -> left_motor_speed(me);
        1 -> right_motor_speed(me);

	else
		0 -> left_motor_speed(me);
		0 -> right_motor_speed(me);
    endif;

enddefine;

create_vehicle(
    200.0 , 120.0,
    1000, 1000, 90,
    controller,
    [],
    [[sound 'left' 1][sound 'right' 1]
	 [light 'left' 1][light 'right' 1]],
    [])->vehicle;

    create_simple_source(200,200,light)-> source;
    create_simple_source(700,700,sound)-> source;
    create_box([[100 100] [1900 100] [1900 1900] [100 1900]])->box1;

control_panel();
*/
/*
define:method controller(me:vehicle, sensor_data);

   	if sensor_data(2)>sensor_data(1) and
	sensor_data(4)>sensor_data(3) then

		6 -> left_motor_speed(me);
        1 -> right_motor_speed(me);

	elseif sensor_data(1)>sensor_data(2) and
	sensor_data(4)>sensor_data(3) then

        1 -> left_motor_speed(me);
        6 -> right_motor_speed(me);

	else
		0 -> left_motor_speed(me);
		0 -> right_motor_speed(me);
    endif;

enddefine;

create_vehicle(
    200.0 , 120.0,
    1000, 1000, 90,
    controller,
    [],
    [[sound 'left' 1][sound 'right' 1]
	 [light 'centre' 1][light 'rear' 1]],
    [])->vehicle;

    create_simple_source(200,200,light)-> source;
    create_simple_source(700,700,sound)-> source;
    create_box([[100 100] [1900 100] [1900 1900] [100 1900]])->box1;

control_panel();

*/



/*

vars list = [light sound smell sound], current =1;


define:method controller(me:vehicle, sensor_data);

	lvars target;

	if current <= length(list) then
   		list(current) -> target;
    else
		false -> target;	
	endif;

	if target = sound then
		if sensor_data(1) + sensor_data(2) > 170 then
			current + 1 -> current;
		else
            sensor_data(1) - 0.1 * sensor_data(2) -> right_motor_speed(me);
			sensor_data(2) - 0.1 * sensor_data(1)-> left_motor_speed(me);
		endif;
	elseif target = light then
	    if sensor_data(3) + sensor_data(4) > 170 then
			current + 1 -> current;
		else
            sensor_data(3) - 0.1 * sensor_data(4)-> right_motor_speed(me);
			sensor_data(4) - 0.1 * sensor_data(3)-> left_motor_speed(me);
		endif;
	elseif target = smell then
		if sensor_data(5) + sensor_data(6) > 170 then
			current + 1 -> current;
		else
            sensor_data(5) - 0.1 * sensor_data(6)-> right_motor_speed(me);
			sensor_data(6) - 0.1 * sensor_data(5)-> left_motor_speed(me);
		endif;
	else
		0 -> left_motor_speed(me);
		0 -> right_motor_speed(me);
	endif;

enddefine;

create_vehicle(
    200.0 , 120.0,
    1700, 1000, 180,
    controller,
    [],
    [[sound 'left' 1][sound 'right' 1]
	 [light 'left' 1][light 'right' 1]
	 [smell 'left' 1][smell 'right' 1]],
    [])->vehicle;

    create_source(200,1000,[[light 100 exponential_decay 200]])-> source;
    create_source(850,1600,[[sound 100 exponential_decay 200]])-> source;
    create_source(850,400,[[smell 100 exponential_decay 200]])-> source;

control_panel();
*/


/*
define:method fast_light_follower(me:vehicle, sensor_data);

    if sensor_data(4)>=sensor_data(2) then
        if sensor_data(3)>sensor_data(1) then
            100 -> left_motor_speed(me);
            0 ->right_motor_speed(me);
        elseif sensor_data(1)>sensor_data(3) then
            100 -> right_motor_speed(me);
            0 ->left_motor_speed(me);
		else
            1->left_motor_speed(me);
            0->right_motor_speed(me);
        endif;
    else
        if sensor_data(3)>sensor_data(1) then
            100 -> left_motor_speed(me);
            100 - ((sensor_data(3) - sensor_data(1))*20 ) ->right_motor_speed(me);
        elseif sensor_data(1)>sensor_data(3) then
            100 -> right_motor_speed(me);
            100 - ((sensor_data(1) - sensor_data(3))*20 )->left_motor_speed(me);
		else
            10->left_motor_speed(me);
            10->right_motor_speed(me);
        endif;
    endif;

enddefine;

create_vehicle(
    200.0 , 120.0,
    1000, 1000, 90,
    fast_light_follower,
    [],
    [[light 'left' 1][light 'centre' 1][light 'right' 1][light 'rear' 1] ],
    [])->vehicle;

create_simple_source(200,200,light)-> source;
create_simple_source(700,700,light)-> source;

control_panel();


create_vehicle(
200.0 , 120.0,
1000, 1000, 90,
[[0 0 -0.2 1][0 0 1 -0.2]
[0 0 0 0][0 0 0 0]],
[],
[[light 'left' 1][light 'right' 1] ],
[])->vehicle;


make_dial_panel(vehicle);
*/

/*

2000 -> random_move_source_on_collision;
false -> random_move_source_on_collision;

print_vehicle_data_log(vehicle);

make_dial_panel(vehicle);


*/

/*

define:method maze_robot(me:vehicle, sensor_data);
                     	
	(sensor_data(3)/2)-sensor_data(1) -> left_motor_speed(me);
	(sensor_data(4)/2)-sensor_data(2) -> right_motor_speed(me);

enddefine;

create_vehicle(
    200.0 , 120.0,
    130, 130, 90,
   	maze_robot,
    [],
    [[sound 'left' 1][sound 'right' 1]
	[proximity 'left' 1][proximity 'right' 1] ],
    [])->vehicle;

maze2();

create_source(1800,1800,[[sound 100 exponential_decay 200]])-> source;	

control_panel();

*/

/*

vars turning_left = false, turning_right = false, straight = true;

define:method maze_robot(me:vehicle, sensor_data);

	if straight then

    	if sensor_data(3) > 95 then
		;;;running into wall
			false -> straight;
			if sensor_data(4) > sensor_data(5) then
				true -> turning_right;
	    		8 -> left_motor_speed(me);
				3 -> right_motor_speed(me);
	
			elseif sensor_data(5) > sensor_data(4) then	
				true -> turning_left;
				3 -> left_motor_speed(me);
				8 -> right_motor_speed(me);
			endif;

		elseif sensor_data(4) < sensor_data(3) or
		sensor_data(5) < sensor_data(3) then
		;;;corner detected

		else
		;;; go straight	
           	100 -((sensor_data(5)+sensor_data(3))/2) -> left_motor_speed(me);
			100 -((sensor_data(4)+sensor_data(3))/2) -> right_motor_speed(me);
		endif;
    	
	elseif turning_left then

        if sensor_data(3) > 80 then
		;;;running into wall
			false -> turning_left;
			true -> straight;
	
		else
		;;;turn left
           	3 -> left_motor_speed(me);
			8 -> right_motor_speed(me);
		endif;

	elseif turning_right then

		if sensor_data(3) > 80 then
		;;;running into wall
			false -> turning_right;
			true -> straight;
	
		else
		;;;turn right
           	8 -> left_motor_speed(me);
			3 -> right_motor_speed(me);
		endif;

	else	
    	0 -> left_motor_speed(me);
		0 -> right_motor_speed(me);
	endif;


enddefine;

create_vehicle(
    200.0 , 120.0,
    130, 130, 90,
   	maze_robot,
    [],
    [[sound 'left' 1][sound 'right' 1]
	[proximity 200 0 1][proximity 100 90 1][proximity 100 270 1] ],
    [])->vehicle;
                           ;;;(4)left        ;;;(5)right
maze2();

create_source(1800,1800,[[sound 100 exponential_decay 200]])-> source;	

control_panel();

make_dial_panel(vehicle);




 sensor_data(3)-5 < sensor_data(4) and
		sensor_data(3)-5 < sensor_data(5) then
			100 -((sensor_data(5)+sensor_data(3))/2) -> left_motor_speed(me);
			100 -((sensor_data(4)+sensor_data(3))/2) -> right_motor_speed(me);
	
		elseif sensor_data(4) > sensor_data(5) then	
	    	8 -> left_motor_speed(me);
			3 -> right_motor_speed(me);
	
		elseif sensor_data(5) > sensor_data(4) then	
			3 -> left_motor_speed(me);
			8 -> right_motor_speed(me);

		else
			0 -> left_motor_speed(me);
			0 -> right_motor_speed(me);

*/




define maze1();

create_box([[400 1000] [400 1990] [10 1990] [10 1000]])->box1;
create_box([[770 1470] [770 1100] [1990 1100] [1990 1470]])-> box2;
create_box([[1700 300] [1700 700] [1300 700] [1300 300]])-> box3;
create_box([[1000 300] [1000 700] [300 700] [300 300]])-> box4;
create_box([[10 10] [1990 10] [1990 1990] [10 1990]])-> box5;

enddefine;

define maze2();

create_box([[400 1000] [400 1990] [10 1990] [10 1000]])->box1;
create_box([[770 1470] [770 1100] [1700 1100] [1700 1470]])-> box2;
create_box([[1990 300] [1990 700] [1300 700] [1300 300]])-> box3;
create_box([[1000 300] [1000 700] [300 700] [300 300]])-> box4;
create_box([[10 10] [1990 10] [1990 1990] [10 1990]])-> box5;

enddefine;

/*
--- $poplocal/local/brait/teach/tests.p
--- Copyright University of Birmingham 2000. All rights reserved. ------
*/
