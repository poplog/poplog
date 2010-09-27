/* --- Copyright University of Birmingham 1996. All rights reserved. ------
 > File:            $poplocal/local/sim/newsimlib.p
 > Purpose:			Set up access to Simulation library
 > Author:          Aaron Sloman, Oct 30 1994 (see revisions)
 > Documentation:	HELP * SIM_AGENT (later)
 > Related Files:	LIB * SIM_AGENT
 */


#_TERMIN_IF identprops("simlib") /= undef ;

section;

;;; Use pop-11 global variable if it exists
global vars popsimdir ;
;;; global vars popsimdir = sysfileok('~axs/cogaff/newsim/');

;;; or use environment variable if it exists
lconstant SIM_VAR = systranslate('sim');


lconstant
	sim_dir =
		if isstring(popsimdir) then popsimdir
		elseif isstring(SIM_VAR) then SIM_VAR
		else '$poplocal/local/newsim'
		endif;

lconstant sim_auto =    sim_dir dir_>< 'auto/';
lconstant sim_lib =     sim_dir dir_>< 'lib/';
;;; lconstant sim_include = sim_dir dir_>< 'include/';

;;; Load and show from sim_ directory
extend_searchlist(sim_auto, popautolist) -> popautolist;
extend_searchlist(sim_lib, popuseslist) -> popuseslist;
;;; extend_searchlist(sim_include, popuseslist) -> popuseslist;

;;; And extend ved's teach and help and ref lists
lconstant
	sim_teach = [[% sim_dir dir_>< 'teach/' % teach]],
	sim_help = [[% sim_dir dir_>< 'help/' % help]],
	sim_ref = [[% sim_dir dir_>< 'ref/' % ref]],
;

extend_searchlist(sim_help, vedhelplist) -> vedhelplist;
;;; and put the teach file at the end
extend_searchlist(sim_teach, vedhelplist, true) -> vedhelplist;
extend_searchlist(sim_teach, vedteachlist) -> vedteachlist;
;;; and put the help file at the end
extend_searchlist(sim_help, vedteachlist, true) -> vedteachlist;
;;; extend_searchlist(sim_ref, vedreflist) -> vedreflist;
extend_searchlist(sim_help, vedreflist, true) -> vedreflist;

global constant simlib = true;
global constant newsimlib = true;
endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Mar 24 1996
	Further slight rearrangement of search lists
--- Aaron Sloman, Jul  7 1995
	Rearranged search lists.
 */
