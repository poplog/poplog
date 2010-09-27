/* --- Copyright University of Birmingham 1996. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/veddiscin.p
 > Purpose:			create character repeater for a VED buffer
 > Author:          Aaron Sloman, May 10 1996
 > Documentation:
 > Related Files:	REF CONSVEDDEVICE
 */

/*
test veddiscin

vedreadlinefrom('INTERACT', vedhelpdefaults, true) =>
vedreadlinefrom('sillyfile', false, false) =>
list =>

*/


section;

define veddiscin(filename) -> repeater;

	lvars dev = consveddevice(sysfileok(filename), 0, true);

	define lconstant newcharin(dev) -> char;
		lconstant string = '0';
		sysread(dev, string, 1) ->;
		fast_subscrs(1, string) -> char
	enddefine;

	newcharin(%dev%) -> repeater;
enddefine;

endsection;
