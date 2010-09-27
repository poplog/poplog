/* --- Copyright University of Birmingham 1998. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_backspace.p
 > Purpose:         Make backspace delete character to left
 > Author:          Aaron Sloman, Jul  4 1998
 > Documentation:	Below
 > Related Files:	HELP * VEDKEYS, HELP * VEDSETKEY, HELP * VEDSET
 */

/*
To make the backspace key delete the character to the left do
	ENTER backspace

or put into your vedinit.p file

	uses ved_backspace

*/

section;

define global ved_backspace();
	vedsetkey('\^H', "vedchardelete");
enddefine;

if vedsetupdone then
	ved_backspace();
else
	define :ved_runtime_action;
		ved_backspace();
	enddefine;
endif;

endsection;
