/* --- The University of Birmingham 1994.  --------------------------------
 > File:            $poplocal/local/auto/ved_sgsr.p
 > Purpose:			"silent" global substitute in a range
 > Author:          Aaron Sloman, Oct 19 1994
 > Documentation: 	below
 > Related Files:	Lib ved_sgs.p, sgsl.p
 */



/*
From Aaron Sloman Sat Apr 18 16:30:39 BST 1992
To: johnw@cogs.sussex.ac.uk
Subject: LIB VED_SGSR
John,

Many times I've wanted this when doing a global substitution in a large
marked range. Finally I've done it. I suspect others have felt the same
need, so if you agree, it might as well go into the system. I append
the library file, with draft REF and NEWS entries embedded in a comment.

I've noticed that REF * ved_gs doesn't work (in V14.1) because the format
for the entry is wrong. Could you fix that?

Thanks
Aaron

=============================================================================
*/
/* --- Copyright University of Sussex 1992. All rights reserved. ------
 > File:            C.all/lib/ved/ved_sgsr.p
 > Purpose:			"Silent" global substitute in a range
 > Author:          Aaron Sloman, Apr 18 1992
 > Documentation:	REF * VEDCOMMS (entry below)
 > Related Files:	LIB * VED_SGS
 */

/*
REF VEDCOMMS entry
ved_sgsr                                                     [procedure]
        Like -ved_gsr-  but "silent",  i.e. doesn't record  progress  on
        status line, and therefore faster.
		Compare * ved_gs and * ved_sgs

HELP NEWS entry
Apr 18 (Aaron Sloman and John Williams)
    --- VED's family of global search and replace commands has been
		extended with another "silent" one, i.e. LIB * VED_SGSR. It
		does not report progress on the status line. See REF * ved_sgsr
		and compare * ved_sgs and * ved_gsr.
*/


section;

define global ved_sgsr();
	dlocal vedediting = false;			;;; suppress counting on status line
    ved_gsr();
    true -> vedediting;
    vedrefresh();
enddefine;

endsection;
