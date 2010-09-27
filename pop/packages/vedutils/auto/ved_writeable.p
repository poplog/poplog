/* --- The University of Birmingham 1994.  --------------------------------
 > File:            $poplocal/local/auto/ved_writeable.p
 > Purpose:         Toggle the value of vedwriteable for the current file
 > Author:          Aaron Sloman, Oct  6 1994
 > Documentation:
 > Related Files:
 */

section;

define ved_writeable;
	;;; toggle vedwriteable;
	not(vedwriteable) -> vedwriteable;
	vedputmessage('vedwriteable: ' sys_>< vedwriteable)
enddefine;

endsection;
