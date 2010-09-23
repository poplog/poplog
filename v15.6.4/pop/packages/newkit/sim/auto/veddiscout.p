/* --- Copyright University of Birmingham 2001. All rights reserved. ------
 > File:            $poplocal/local/auto/veddiscout.p
 > File:            $poplocal/local/rclib/auto/veddiscout.p
 > File:            $poplocal/local/newkit/sim/auto/veddiscout.p
 > Purpose:			create character consumer for a VED buffer
 > Author:          Aaron Sloman, May 10 1996 (see revisions)
 > Documentation:
 > Related Files:	REF CONSVEDDEVICE
 */

/*
test veddiscout

define testproc(files, list, n);
	;;; create consumers for the files in files (list of strings)
	;;; repeatedly print the list into each file in turn, and a counter.
	;;; then pause half a second. Do all this n times.
	lvars
		counter,
		consumers = maplist(files, veddiscout);

	dlocal cucharout, vedautowrite = false;

	for counter from 1 to n do
		lvars consumer;
		for consumer in consumers do
			consumer -> cucharout;
			spr(list); spr(counter);
			pr(newline);
		endfor;
		syssleep(50);
	endfor;
enddefine;

testproc(['test1' 'test2' 'test3'], [mary had a little lamb], 1000);

*/





section;

define veddiscout(filename) -> consumer;

	lvars dev = consveddevice(sysfileok(filename), 1, true);

	define lconstant newcharout(char, dev);
		lconstant string = '0';
		unless char == termin then
			char -> fast_subscrs(1, string);
			syswrite(dev, string, 1)
		endunless;
	enddefine;

	newcharout(%dev%) -> consumer;
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Nov 18 2001
	Fixed to deal with termin properly
--- Aaron Sloman, Jul 21 1997
	copied to $poplocal/local/rclib/auto
 */
