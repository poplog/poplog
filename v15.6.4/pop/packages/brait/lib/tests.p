/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/brait/lib/tests.p
 > Purpose:         test vehicles and experiments.
 > Author:          Duncan K Fewkes, Aug 30 2000
 > Documentation:
 > Related Files:
 */

compilehere
	braitenberg_sim.p
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
[[sound 'left' 1][sound 'right' 1] ],
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
create_box([[100 100] [1900 100] [1900 1900] [100 1900]])->box1;

control_panel();

print_vehicle_data_log(vehicle);
*/


/*
define:method light_follower(me:vehicle, sensor_data);

    if sensor_data(2) > 90 then
        0->left_motor_speed(me);
        0->right_motor_speed(me);
        return();
    endif;

    if sensor_data(4)>=sensor_data(2) then
        if sensor_data(3)>sensor_data(1) then
            100 -> left_motor_speed(me);
            0 ->right_motor_speed(me);
        elseif sensor_data(1)>sensor_data(3) then
            100 -> right_motor_speed(me);
            0 ->left_motor_speed(me);
        else
            0->left_motor_speed(me);
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
            0->left_motor_speed(me);
            0->right_motor_speed(me);
        endif;
    endif;

enddefine;

create_vehicle(
    200.0 , 150.0,
    1000, 1000, 90,
    light_follower,
    [],
    [[light 125 45 1][light 125 0 1][light 125 315 1][light 125 180 1] ],
    [])->vehicle;

create_simple_source(200,200,light)-> source;
create_simple_source(700,700,light)-> source;

control_panel();

control_panel();
make_dial_panel(vehicle);
*/


/*
define:method obstacle_avoider(me:vehicle, sensor_data);

if sensor_data(2) > 90 then
    0->left_motor_speed(me);
    100->right_motor_speed(me);
    return();
elseif sensor_data(3)>sensor_data(1) then
    0 -> left_motor_speed(me);
    100 ->right_motor_speed(me);
elseif sensor_data(1)>sensor_data(3) then
    0 -> right_motor_speed(me);
    100->left_motor_speed(me);
else
    0->left_motor_speed(me);
    0->right_motor_speed(me);
endif;


enddefine;

create_vehicle(
200.0 , 120.0,
1000, 1000, 90,
obstacle_avoider,
[],
[[proximity 125 45 1][proximity 125 0 1][proximity 125 315 1] ],
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

control_panel();
make_dial_panel(vehicle);

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

	if sensor_data(1) > 5 then
		10 -> left_motor_speed(me);
		20 -> right_motor_speed(me);
	else
	    20 -> left_motor_speed(me);
		10 -> right_motor_speed(me);
	endif;
	
enddefine;

create_vehicle(
200.0 , 120.0,
1000, 1000, 90,
controller,
[],
[[sound centre 1]],
[]) -> vehicle;

create_simple_source(300, 300, sound) -> source;

control_panel();
make_dial_panel(vehicle);
*/
