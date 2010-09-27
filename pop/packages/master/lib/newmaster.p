/* --- Copyright University of Sussex 1992. All rights reserved. ----------
 > File:            $poplocal/local/lib/newmaster.p
 > Purpose:         Maintenance of the Poplog master tree
 > Author:          Robert John Duncan, Mar 10 1992
 > Documentation:   HELP * NEWMASTER
 > Related Files:
 */

compile_mode:pop11 +strict;

vedputmessage('Please wait');

section;

lconstant
	BASICS = [
		params
		utils
		vedcomms
	],
	COMMANDS = [
		delete
		get
		header
		history
		install
		mark
		recover
		unlock
	],
;

define lconstant file_name(f);
	lvars f;
	'newmaster/' dir_>< (f sys_>< '.p');
enddefine;

lvars f;
for f in BASICS do
	unless syslibcompile(file_name(f), popuseslist) then
		mishap(file_name(f), 1, 'LIBRARY FILE NOT FOUND');
	endunless;
endfor;
for f in COMMANDS do
	syslibcompile(file_name(f), popuseslist) -> ;
endfor;

global vars
	newmaster = true,
;

endsection;		/* $- */
