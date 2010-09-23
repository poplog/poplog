/* --- Copyright University of Birmingham 2009. All rights reserved. ------
 > File:			$usepop/pop/x/pop/auto/rc_sleep.p
 > Purpose:			Insert a delay, determined by the value of
 >						rc_graphic_delay (default false)
 > Author:			Aaron Sloman, Sep  1 2009
 > Documentation:
 > Related Files:
 */

/*

TESTS

false -> rc_graphic_delay

repeat 20 times rc_sleep(); pr('.\n'); endrepeat;

20-> rc_graphic_delay;

repeat 20 times rc_sleep(); pr('.\n'); endrepeat;

0.75 -> rc_graphic_delay;

repeat 20 times rc_sleep(); pr('.\n'); endrepeat;

*/


uses-now popxlib;

section;

;;; can be false or integer or decimal number
global vars rc_graphic_delay;

	if isundef(rc_graphic_delay) then
	    false -> rc_graphic_delay
	endif;

define rc_sleep();

	sysflush(poprawdevout);
	sysflush(popdevout);
    if isinteger(rc_graphic_delay) then
		;;; sleep for that number of hundredths of a second
        syssleep(rc_graphic_delay);
    elseif isdecimal(rc_graphic_delay) then
		;;; sleep for that number of seconds.
        syssleep(round(100*rc_graphic_delay));
    endif

enddefine;

endsection;
