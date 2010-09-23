/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/brait/lib/tutorialsupplement.p
 > Purpose:         Supplementary procedures for tutorial files. mostly bring
	up pictures, create specific vehicle objects or run simulator with
	specific objects
 > Author:          Duncan K Fewkes, Aug 1 2000 (see revisions)
 > Documentation:
 > Related Files:
 */

/*

CONTENTS - (Use <ENTER> gg to access required sections)

 define create_vehicle3()->vehicle3;
 define create_vehicle4()->vehicle4;
 define example1();
 define picture1();
 define picture2();
 define picture3();
 define showvehicle1();
 define showvehicle2();
 define answer_to_vehicle3();
 define answer_to_vehicle4();
 define sensor_example();
 define vehicle_chase_example();


*/

define create_vehicle3()->vehicle3;

    create_vehicle(
        200 , 120,
        600, 600, 45,
        [[0 0 0 1]                  ;;; Matrix
         	[0 0 1 0]
         	[0 0 0 0]
         	[0 0 0 0]],
        [[basic_unit]              ;;; Unit-types
         	[basic_unit]
         	[basic_unit]
         	[basic_unit]],
        [[proximity 'left' 0.6]     ;;; Sensor 1
         	[proximity 'right' 0.6] ], ;;; Sensor 2
        [])->vehicle3;

enddefine;




define create_vehicle4()->vehicle4;

    create_vehicle(
        200 , 120,
        600, 600, 45,
        [[0 0 0 -1 0]
         	[0 0 0 0 -1]
         	[0 0 0 0.05 0.05]
         	[0 0 0 0 0]
         	[0 0 0 0 0]],
        [[basic_unit]
         	[basic_unit]
         	[internal_energy]
         	[basic_unit]
         	[basic_unit]],
        [[proximity 'left' 0.7]
         	[proximity 'right' 0.7] ],
        [])->vehicle4;

enddefine;




define example1();

	create_window(1000, 500);

	create_vehicle(
		200.0 , 120.0,
		100, 1000, 0,
		[[0 1 1] [0 0 0][0 0 0]],
		[[basic_unit]
			[basic_unit]
			[basic_unit]],
		[[heat 130 0 1.0]],
		[])->vehicle1;

	create_source( 400, 1200, [[heat 100.00 %exponential_decay% 200.00]]) -> source1;
	create_source( 1700, 700, [[heat 100.00 %exponential_decay% 200.00]]) -> source2;
	create_source( 3000, 1400, [[heat 100.00 %exponential_decay% 200.00]]) -> source3;

	'blob' -> path_tracing;

	brait_sim(150);

enddefine;



define picture1();

    if isundef(brait_world) then
    else
    	rc_kill_window_object(brait_world);
    endif;

    rc_new_window_object(5, 5, 250, 400, {0 400 0.25 -0.25}, 'A simple vehicle', newsim_picagent_window) -> brait_world;

    rc_jumpto(300,500);
    rc_draw_rectangle(150, 400);
    rc_jumpto(175, 1200);
    rc_draw_rectangle(400, 900);
    rc_draw_blob(375, 300, 74,'white');

    rc_draw_blob(375, 1350 ,20,'red');
    rc_drawline(375, 1350, 375, 500);

    rc_print_at(390, 1400, 'Heat sensor');
    rc_print_at(620, 1150, 'Vehicle body');
    rc_print_at(480, 80, 'Wheel/Motor');
    rc_print_at(400, 800, 'Sensor-motor link');

enddefine;


define picture2();

    if isundef(brait_world) then
    else
    	rc_kill_window_object(brait_world);
    endif;

    rc_new_window_object(5, 5, 300, 400, {0 400 0.25 -0.25}, 'Sensor locations', newsim_picagent_window) -> brait_world;

    rc_jumpto(150,550);
    rc_draw_rectangle(149, 400);
    rc_jumpto(800,550);
    rc_draw_rectangle(149, 400);
    rc_jumpto(300, 1200);
    rc_draw_rectangle(500, 900);

    rc_draw_blob(300, 1200 ,20,'purple');
    rc_draw_blob(800, 1200 ,20,'purple');

    rc_print_at(180, 1300, 'Left sensor');
    rc_print_at(690, 1300, 'Right sensor');
    rc_print_at(825, 800, 'Vehicle body');
    rc_print_at(120, 80, 'Left wheel');
    rc_print_at(750, 80, 'Right wheel');

enddefine;


define picture3();

    if isundef(brait_world) then
    else
    	rc_kill_window_object(brait_world);
    endif;

    rc_new_window_object(5, 5, 300, 400, {0 400 0.25 -0.25}, 'Sensor locations', newsim_picagent_window) -> brait_world;

    rc_jumpto(150,550);
    rc_draw_rectangle(149, 400);
    rc_jumpto(800,550);
    rc_draw_rectangle(149, 400);
    rc_jumpto(300, 1200);
    rc_draw_rectangle(500, 900);

    rc_draw_blob(375, 1350 ,20,'purple');
    rc_drawline(375, 1350, 375, 500);
    rc_drawline(375, 500, 300, 425);

    rc_draw_blob(725, 1350 ,20,'purple');
    rc_drawline(725, 1350, 725, 500);
    rc_drawline(725, 500, 800, 425);
    rc_drawline(725, 500, 300, 400);

    rc_print_at(250, 1400, 'Left sensor');
    rc_print_at(620, 1400, 'Right sensor');
    rc_print_at(825, 1150, 'Vehicle body');
    rc_print_at(120, 80, 'Left wheel');
    rc_print_at(750, 80, 'Right wheel');
    rc_print_at(400, 750, 'Sensor-motor');
    rc_print_at(500, 700, 'links');



enddefine;



define showvehicle1();

    if isundef(brait_world) then
    else
    	rc_kill_window_object(brait_world);
    endif;

    rc_new_window_object(5, 5, 300, 400, {0 400 0.25 -0.25},
		'Experiment 1: Vehicle 1', newsim_picagent_window) -> brait_world;

    rc_jumpto(150,550);
    rc_draw_rectangle(149, 400);
    rc_jumpto(800,550);
    rc_draw_rectangle(149, 400);
    rc_jumpto(300, 1200);
    rc_draw_rectangle(500, 900);

    rc_draw_blob(375, 1350 ,20,'purple');
    rc_drawline(375, 1350, 375, 500);
    rc_drawline(375, 500, 300, 425);

    rc_draw_blob(725, 1350 ,20,'purple');
    rc_drawline(725, 1350, 725, 500);
    rc_drawline(725, 500, 800, 425);

    rc_print_at(425, 1400, 'Heat sensors');
    rc_print_at(825, 1150, 'Vehicle body');
    rc_print_at(120, 80, 'Left wheel');
    rc_print_at(750, 80, 'Right wheel');
    rc_print_at(450, 800, 'Excitatory');
    rc_print_at(400, 750, 'sensor-motor');
    rc_print_at(500, 700, 'links');

enddefine;



define showvehicle2();

    if isundef(brait_world) then
    else
    	rc_kill_window_object(brait_world);
    endif;

    rc_new_window_object(5, 5, 300, 400, {0 400 0.25 -0.25},
		'Experiment 1: Vehicle 2', newsim_picagent_window)
			-> brait_world;

    rc_jumpto(150,550);
    rc_draw_rectangle(149, 400);
    rc_jumpto(800,550);
    rc_draw_rectangle(149, 400);
    rc_jumpto(300, 1200);
    rc_draw_rectangle(500, 900);

    rc_draw_blob(375, 1350 ,20,'purple');
    rc_drawline(375, 1350, 375, 850);
    rc_drawline(375, 850, 800, 425);

    rc_draw_blob(725, 1350 ,20,'purple');
    rc_drawline(725, 1350, 725, 850);
    rc_drawline(725, 850, 300, 425);

    rc_jumpto(525, 400);
    rc_draw_rectangle(50, 50);
    rc_drawline(525, 375, 300, 375);
    rc_drawline(575, 375, 800, 375);

    rc_print_at(425, 1400, 'Heat sensors');
    rc_print_at(825, 1150, 'Vehicle body');
    rc_print_at(120, 80, 'Left wheel');
    rc_print_at(750, 80, 'Right wheel');
    rc_print_at(450, 1000, 'Inhibitory');
    rc_print_at(400, 950, 'sensor-motor');
    rc_print_at(500, 900, 'links');
    rc_print_at(400, 425, 'Internal energy');

enddefine;




define answer_to_vehicle3();

    if isundef(brait_world) then
    else
    	rc_kill_window_object(brait_world);
    endif;

    rc_new_window_object(5, 5, 610, 400, {0 400 0.25 -0.25},
		'Experiment 2: Vehicle 3', newsim_picagent_window)
			-> brait_world;

    rc_jumpto(150,550);
    rc_draw_rectangle(149, 400);
    rc_jumpto(800,550);
    rc_draw_rectangle(149, 400);
    rc_jumpto(300, 1200);
    rc_draw_rectangle(500, 900);

    rc_draw_blob(375, 1350 ,20,'purple');
    rc_drawline(375, 1350, 375, 850);
    rc_drawline(375, 850, 800, 425);

    rc_draw_blob(725, 1350 ,20,'purple');
    rc_drawline(725, 1350, 725, 850);
    rc_drawline(725, 850, 300, 425);

    rc_print_at(425, 1400, 'Heat sensors');
    rc_print_at(825, 1150, 'Vehicle body');
    rc_print_at(120, 80, 'Left wheel');
    rc_print_at(750, 80, 'Right wheel');
    rc_print_at(450, 1000, 'Excitatory');
    rc_print_at(400, 950, 'sensor-motor');
    rc_print_at(500, 900, 'links');

    XpwSetFont(rc_window,'8x13bold');
    rc_print_at(1300, 1300, 'The vehicle has EXCITATORY links');
    rc_print_at(1250, 1230, 'so that if the vehicle is near an');
    rc_print_at(1250, 1160, 'obstacle, the motor on the OPPOSITE');
    rc_print_at(1250, 1090, 'SIDE to the obstacle will be running');
    rc_print_at(1250, 1020, 'FASTER than the other, resulting in ');
    rc_print_at(1250, 950,  'the vehicle turning TOWARDS the');
    rc_print_at(1250, 880,  'obstacle. It also causes the vehicle');
    rc_print_at(1250, 810,  'to SPEED UP as it gets nearer to the');
    rc_print_at(1250, 740,  'obstacle.');
    rc_print_at(1300, 650,  'Some of you may have seen the');
    rc_print_at(1250, 580,  'vehicle seem to orbit the obstacle -');
    rc_print_at(1250, 510,  'Why do you think it does this?');

    ;;;NB keep last question?

    rc_print_at(1300, 420,  'The matrix should have looked like:');
    rc_print_at(1500, 330,  '[[0 0 0 1]');
    rc_print_at(1500, 260,  ' [0 0 1 0]');
    rc_print_at(1500, 190,  ' [0 0 0 0]');
    rc_print_at(1500, 120,  ' [0 0 0 0]]');

enddefine;


define answer_to_vehicle4();

    if isundef(brait_world) then
    else
    	rc_kill_window_object(brait_world);
    endif;

    rc_new_window_object(5, 5, 610, 400, {0 400 0.25 -0.25},
		'Experiment 2: Vehicle 4', newsim_picagent_window) -> brait_world;

    rc_jumpto(150,550);
    rc_draw_rectangle(149, 400);
    rc_jumpto(800,550);
    rc_draw_rectangle(149, 400);
    rc_jumpto(300, 1200);
    rc_draw_rectangle(500, 900);

    rc_draw_blob(375, 1350 ,20,'purple');
    rc_drawline(375, 1350, 375, 500);
    rc_drawline(375, 500, 300, 425);

    rc_draw_blob(725, 1350 ,20,'purple');
    rc_drawline(725, 1350, 725, 500);
    rc_drawline(725, 500, 800, 425);

    rc_jumpto(525, 400);
    rc_draw_rectangle(50, 50);
    rc_drawline(525, 375, 300, 375);
    rc_drawline(575, 375, 800, 375);

    rc_print_at(425, 1400, 'Heat sensors');
    rc_print_at(825, 1150, 'Vehicle body');
    rc_print_at(120, 80, 'Left wheel');
    rc_print_at(750, 80, 'Right wheel');
    rc_print_at(450, 1000, 'Inhibitory');
    rc_print_at(400, 950, 'sensor-motor');
    rc_print_at(500, 900, 'links');
    rc_print_at(400, 425, 'Internal energy');

    XpwSetFont(rc_window,'8x13bold');
    rc_print_at(1300, 1300, 'The vehicle has INHIBITORY links');
    rc_print_at(1250, 1230, 'so that if the vehicle is near an');
    rc_print_at(1250, 1160, 'obstacle, the motor on the SAME');
    rc_print_at(1250, 1090, 'SIDE to the obstacle will be running');
    rc_print_at(1250, 1020, 'SLOWER than the other, resulting in ');
    rc_print_at(1250, 950,  'the vehicle turning TOWARDS the');
    rc_print_at(1250, 880,  'obstacle. It also causes the vehicle');
    rc_print_at(1250, 810,  'to SLOW DOWN as it gets nearer to');
    rc_print_at(1250, 740,  'the obstacle.');

    rc_print_at(1300, 650,  'The matrix should have looked like:');
    rc_print_at(1500, 560,  '[[0 0 0 -1 0]');
    rc_print_at(1500, 490,  ' [0 0 0 0 -1]');
    rc_print_at(1500, 420,  ' [0 0 0 0.05 0.05]');
    rc_print_at(1500, 350,  ' [0 0 0 0 0]');
    rc_print_at(1500, 280,  ' [0 0 0 0 0]]');

enddefine;



define sensor_example();

	create_window(500, 500);

	create_vehicle(
		200.0 , 120.0,
		1000, 1000, 0,
		[[0 0 1 0] [0 0 0 1][0 0 0 0][0 0 0 0]],
		[[basic_unit]
			[basic_unit]
			[basic_unit]
			[basic_unit]],
		[[light 'left' 1][light 'right' 1]],
		[])->vehicle1;

	create_source( 400, 1200, [[heat 100.00 %exponential_decay% 100.00]]) -> source1;
	create_source( 1700, 700, [[light 100.00 %exponential_decay% 100.00]]) -> source2;
	create_source( 300, 400, [[sound 100.00 %exponential_decay% 100.00]]) -> source3;

	control_panel();

enddefine;

define vehicle_chase_example();

	create_window(500, 500);

	create_vehicle(
		200.0 , 120.0,
		500, 500, 0,
		[[0 0 -0.1 1] [0 0 1 -0.1][0 0 0 0][0 0 0 0]],
		[[basic_unit]
			[basic_unit]
			[basic_unit]
			[basic_unit]],
		[[light 'left' 1][light 'right' 1]],
		[])->vehicle1;

	create_vehicle(
		200.0 , 120.0,
		1200, 1300, 0,
		[[0 0 1 0] [0 0 0 1][0 0 0 0][0 0 0 0]],
		[[basic_unit]
			[basic_unit]
			[basic_unit]
			[basic_unit]],
		[[proximity 'left' 0.6][proximity 'right' 0.6]],
		[[light 100.00 %exponential_decay% 180.00]])->vehicle2;

	create_box([[100 100] [1900 100] [1900 1900] [100 1900]])->box1;

	control_panel();

enddefine;


;;; for "uses"
global constant tutorialsupplement = true;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Oct  8 2000

	Tidied procedures with ENTER jcp

	Fixed header and and added "define" index.

--- Duncan K Fewkes, Aug 30 2000
converted to lib format

 */
