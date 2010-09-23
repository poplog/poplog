/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/newkit/newkit.p
 > Purpose:         Load new version of toolkit
 > Author:          Aaron Sloman, Jul  4 1999 (see revisions)
 > Documentation:	HELP sim_agent, poprulebase, newkit
 > Related Files:	LIB simlib, prblib
 */

global constant newkit;

section;

unless isundef(newkit) then [endsection;] -> proglist endunless;

lconstant this_dir = sys_fname_path(popfilename);

compile(this_dir <> 'prb/prblib.p');
compile(this_dir <> 'sim/simlib.p');

vars newkit = this_dir;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Aug  5 2000
	Modified to use current directory, so that it can be invoked any
	where
 */
