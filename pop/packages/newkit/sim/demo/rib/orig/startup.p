;;; Instructions to run the code for the ijcai95 paper (Sloman & Poli)
;;; Assumes poprulebase and sim_agent directories are in relevant paths
;;; Set up the robot described in the paper. When the go(N) command
;;; is given (N = number of cycles) the robot will try to get close to the
;;; nearest wall and then follow it to the left, using the mechanisms
;;; described in the paper.
;;; See the rules in ijcai95.p (Look for "define :rule")
;;; NB typo: "novely" should have been "novelty" throughout!

;;; Code is mainly by Riccardo Poli, with some bits by Aaron Sloman

uses sim_agent;
load ijcai95.p

load wall_following_net5.p
flush([network [= [example ==]]]);
database -> wall_following_net;

;;; Now set initial state of RIBOT ("robot in box"-ot)
;;; Box has side of length 1.0
;;; Numbers are: x co-ord, y co-ord, x vel, y vel
set_state(ribot,0.3,0.75,0.03,0);
go(20);
go_for(200);

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
