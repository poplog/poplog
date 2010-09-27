/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/self_caller.p
 > Purpose:			Report whether a procedure is calling itself
 > Author:          Aaron Sloman, Mar 26 1999
 > Documentation:	See TEACH RC_CONSTRAINED_PANEL for an example
 > Related Files:
 */

section;

compile_mode :pop11 +strict;

define self_caller() -> boolean;
    ;;; Is the caller of this procedure (caller(1)) in the calling
    ;;; chain above itself
    iscaller(caller(1), 2) -> boolean;
enddefine;

endsection;
