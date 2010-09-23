/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/sim/auto/sim_control_panel.p
 > Purpose:         Make a control panel for boolean control variables
 > Author:          Aaron Sloman, Mar  2 1999 (see revisions)
 > Documentation:	HELP SIM_CONTROL_PANEL, SIM_HARNESS
 > Related Files:	LIB RC_CONTROL_PANEL, LIB SIM_HARNESS
 */
/*

;;; TEST

    /*
    A possible list of boolean trace switching variables which could go
    into sim_alltracevars. For the current default list see
    LIB * SIM_HARNESS

    Users can modify the list, addding new control variables.
	See examples in TEACH * SIM_FEELINGS/sim_alltracevars

    */
global vars

    ;;; sim_alltracevars can be given as fourth argument
	;;; 	to run_simulation_withvars.
    ;;; All these variables will have their values set false.

    sim_alltracevars =
        [
			;;; Poprulebase variables (See HELP POPRULEBASE)
			prb_walk prb_chatty prb_show_conditions

			;;; SIM_HARNESS variables defined below
			demo_startrules_trace demo_endrules_trace
			demo_data_trace demo_message_trace
			demo_actions_trace
			demo_cycle_trace demo_cycle_pause
			demo_end_sim_trace
			demo_check_popready

			;;; Make this true, or 1,  to show garbage collections
			popgctrace];

length(sim_alltracevars) =>

sim_control_panel(10,10,sim_alltracevars,2,'Control');


*/

section;

uses rclib
uses rc_buttons
uses rc_control_panel


global
	vars sim_panel,	;;; the control panel

	sim_delay = 0, 	;;; delay in 100ths of a second at the end of each cycle

	sim_terminate_simulation, ;;; if true, terminate simulation
	
	sim_pause_demo, 	;;; if true pause simulation
	
	sim_demo_maxcycles,	;;; maximum number of cycles allowed
;

if isundef(sim_demo_maxcycles) then 1000 -> sim_demo_maxcycles endif;

global vars
	;;; default number of cycles to go on slider
	sim_demo_cycles = 20,
	mintracevars;

define sim_control_panel(x, y, tracevars, cols, title);

	;;; allow optional extra container argument.
	lvars container = false;

	if isrc_window_object(title) then
		(x, y, tracevars, cols, title) -> (x, y, tracevars, cols, title, container);
	endif;

	dlocal rc_button_font_def =
		;;;; '-*-helvetica-bold-r-normal-*-14-*-*-*-*-*-*-*'
		'*helvetica-bold-r-normal-*-14*'
		;;; '*lucida*-r-*sans-12*'
		;;; '*lucida*-r-*sans-14*'
		;;; '8x13'
		;

	lvars fields =
		[
	  	{bg 'grey1'}
	  	{fg 'grey90'}
	  	{font '10x20'}
	  	[TEXT {align centre}: 'Control buttons' 'for simulations']

	  	[ACTIONS
			{width 200}
			{height 30}
			{cols ^cols} :
			%
				lvars tracevar;
			for tracevar in tracevars do
				{toggle ^tracevar ^(identof(tracevar))}
			endfor
			%
			;;; increment delay in steps of 1/20th of a second
			{counter 'DELAY' ^(ident sim_delay) 5 }
		]
		[SLIDERS
			{height 50}
			{width 340} :
			[sim_demo_cycles {1 ^(max(sim_demo_cycles, sim_demo_maxcycles))}  round [[{0 15 'Cycles to run'}][]] ]
		]

        [ACTIONS
			{gap 5}
			{bg 'gray10'} {fg 'white'}
			{align centre}
            {width 150} {cols 2}:
			['RUN' [POP11
    				continue_run(sim_demo_cycles, []);
				]]
			['PAUSE DEMO' [POP11 true -> sim_pause_demo]]
			['STOP DEMO' [POP11 true -> sim_terminate_simulation]]
			['KILL WINDOWS' killwindows]
            ['KILL PANEL' rc_kill_menu]
		]
		[ACTIONS
			{width 180}
			{fg 'red'} {bg 'blue'}:
            {blob 'EXIT POPLOG' sysexit}
        ]
	];

	rc_control_panel(x, y, fields, title, if container then container endif) -> sim_panel;

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Nov 21 2000
	Added sim_demo_maxcycles and made sim_control_panel respect it
	Also, if sim_demo_cycles is greater than sim_demo_maxcycles, the former
	will be used to determine the slider range.

--- Aaron Sloman, Jul  6 2000
	Changes suggested by Matthias Scheutz: extra control facilities on panel
--- Aaron Sloman, May 19 1999
	Extended to allow optional extra container argument
 */
