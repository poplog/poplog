/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/auto/ved_sgsl.p
 > Purpose:         silent global subs in line
 > Author:          Aaron Sloman, Jan 21 1995
 > Documentation:
 > Related Files:
 */

;;; $poplocal/local/menu/auto/auto/ved_sgsl.p

section;

define global ved_sgsl();
	dlocal vedediting = false;			;;; suppress counting on status line
    ved_gsl();
    chain(vedrefresh);
enddefine;

endsection;
