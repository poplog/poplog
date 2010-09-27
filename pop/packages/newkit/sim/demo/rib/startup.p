/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/newkit/sim/demo/rib/startup.p
 > Purpose:			 Compile and start up RIB demo
 > Author:          Aaron Sloman, Sep 13 2000 (see revisions)
 > Documentation:
 > Related Files:
 */

;;; Instructions to run the code for the ijcai95 paper (Sloman & Poli)
;;; Assumes poprulebase and sim_agent directories are in relevant paths
;;;
;;; Set up the robot described in the paper. When the go(N) command
;;; is given (N = number of cycles) the robot will try to get close to the
;;; nearest wall and then follow it to the left, using the mechanisms
;;; described in the paper.
;;; See the rules in ijcai95.p (Look for "define :ruleset")

;;; Code is mainly by Riccardo Poli, with some bits by Aaron Sloman

uses rclib;
uses sim_agent;
uses compilehere;

compilehere
	ijcai95.p
	wall_following_net5.p
;

flush([network [= [example ==]]]);
database -> wall_following_net;

/*
;;; Possible tests.

;;; Now set initial state of RIBOT ("robot in box"-ot)
;;; Box has side of length 1.0
;;; Numbers are: x co-ord, y co-ord, x vel, y vel
rc_start();
set_state(ribot,0.3,0.75,0.03,0);
draw_me(ribot);
ribot =>
go(5);
go_for(200);

*/

;;; the previous command can be repeated any number of times
/*

;;; Other example initial states
	set_state(ribot,0.96,0.47,-0.03,0);
	set_state(ribot,0.3,0.75,-0.03,0);
	set_state(ribot,0.3,0.5,0,-0.0001);
	set_state(ribot,0.3,0.5,0,-0.01);
;;; try this repeatedly in each state.
	go(20)  =>
or this
	go(200)  =>
	
*/

/*
;;; for timing
timediff() ->; go(50); timediff() =>
*/

pr('Try\
set_state(ribot,0.5,0.95,0.03,-0.01);\
;;; followed by\
go(N), followed by go_for(K) to continue, e.g. \n\ngo(200);');

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep 13 2000
	Updated for define :rulset, and define :rulesystem formats,
	and made to use lvars and "!" pattern prefix throughout.
 */
