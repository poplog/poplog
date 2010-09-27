/* --- Copyright University of Birmingham 1996. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_seen.p
 > Purpose:			Mark current message as "Seen".
 > Author:          Aaron Sloman, Sep 22 1996
 > Documentation:	Below for now
 > Related Files:
 */


/*
    ENTER seen
        Marks the current message, by adding a line of the form
            Seen: <date>
        to the header
*/

section;

define ved_seen();

	lconstant Seenstart = 'Seen: ';

	lvars startline = vedline;

	dlocal
		vvedmarkprops = false, 	;;; prevents marking being visible
		ved_search_state;

	vedpositionpush();			;;; remember location
	vedmarkpush();				;;; save "mark" information
	ved_mcm();					;;; this marks whole message

	vedmarkfind(); 				;;; go to top of message

	;;; Look for first line after Received lines
	repeat
		vedchardown();
		lvars line = vedthisline();
		if isstartstring('Received:', line)
			or (datalength(line) > 4 and
				(isstartstring('\s\s\s\s', line) or isstartstring('\t', line)))
		then nextloop()
		elseif isstartstring(Seenstart, line) then
			;;; Already seen. Do nothing
			quitloop()
		else
			vedlineabove();
			vedinsertstring(Seenstart);
			vedinsertstring(sysdaytime());
			quitloop()
		endif;
	endrepeat;

	vedpositionpop();
	;;; Go back into message if necessary
	if vedline < startline then vedchardown() endif;
	vedmarkpop();
enddefine;
endsection;
