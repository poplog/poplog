/* --- Copyright University of Birmingham 2003. All rights reserved. ------
 > File:			$poplocal/local/rclib/auto/print_to_strings.p
 > Purpose:			Make a procedure print into a collection of strings, left on the stack
 >					(Useful for displaying program output in a graphic window)
 > Author:			Aaron Sloman, Jul 20 2003
 > Documentation:	HELP RCLIB/print_to_strings
 > Related Files:
 */

/*
uses rclib
uses print_to_strings

define testit();
	lvars x, row;

	[%  'CLICK TO DISMISS',
		for row from 5 to 20 do
		[%for x from 30 to 30 + row do x endfor%]
	  endfor %] ==>

enddefine;

;;; test the procedure below. It should produce 20 strings

vars strings = [% print_to_strings(testit) %];

length(strings) =>
applist(strings, npr);

Example of use

uses rc_message;
rc_message(300,300,strings,1, true, '9x15', false, false)->;
rc_message(300,300,strings,2, false, '9x15', false, false)->;
rc_message(300,300,strings,2, "right", '8x13bold', 'black', 'gray90')->;
rc_message(300,300,strings,2, "right", '8x13', 'black', 'gray90')->;
rc_message("right", "top", strings, 2, "right", '12x24', 'blue', 'yellow')->;
rc_message("left", "top", strings, 2, "left", '12x24', 'blue', 'red')->;

*/


define print_to_strings(procedure print_command);
	;;; run the print command, but instead of sending
	;;; characters to the terminal, make set of strings,
	;;; one string per line of output.

    lvars len = stacklength();

	;;; Leave strings on stack. Could interfere with
	;;; some printing procedures...

	define dlocal cucharout(char);
		if char == `\n` then
			;;; it's a newline so make a string from characters so far.
			consstring(stacklength() - len);
			stacklength() -> len;
		else char
		endif
	enddefine;
		
	print_command();

	;;; check whether any characters added since last string created.
	lvars newlen;
	if (stacklength() ->> newlen) > len then
			consstring(newlen - len);
	endif;
	

enddefine;



	
