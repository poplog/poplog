/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/vedreadlinefrom.p
 > Purpose:			Get a line of text from a ved buffer, and turn it into a list
 > Author:          Aaron Sloman, Apr 23 1997
 > Documentation:
 > Related Files:
 */

/*
vedreadlinefrom(filename, defaults, save) -> list;
	filename: a string
	defaults: false or vedhelpdefaults, or vedveddefaults ,etc.
	save:     if true, then save the buffer, otherwise quit


vedreadlinefrom('INTERACT', false, false) =>
vedreadlinefrom('INTERACT', false, true) =>
*/

section;

define vars vedreadlinefrom(filename, defaults, save) -> list;

	;;; default is for the file not to be iswriteableable

	unless defaults then vedhelpdefaults -> defaults endunless;

	vededit(filename, defaults);

	lvars item, list,
		newcharin = veddiscin(filename),
		procedure rep = incharitem(newcharin);		;;; item repeater

	dlocal popnewline = true, popprompt = pop_readline_prompt;
	
	;;; Make a list items to next newline
	[% until (rep() ->> item) == newline do item enduntil %] -> list;

	unless save then
		if vedwriteable then ved_wq() else ved_q() endif;
	endunless;
enddefine;

endsection;
