/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/auto/ved_sgsp.p
 > Purpose:         Silent global substitute in a procedure
 > Author:          Aaron Sloman, Jan 21 1995
 > Documentation:
 > Related Files:
 */

section;

define global ved_sgsp();
	dlocal vedediting = false;			;;; suppress counting on status line
    ved_gsp();
    chain(vedrefresh);
enddefine;

endsection;
