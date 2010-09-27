/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_coloured_panel.p
 > Purpose:			Produce a coloured panel which can be moved around
 > 					inside another panel
 > Author:          Aaron Sloman, May 22 1999
 > Documentation:	HELP * RCLIB, HELP * RC_CONTROL_PANEL
 > Related Files:
 */

/*

;;; test it

vars panel1 = rc_coloured_panel(400, 300, 200, 150, 'red', [], false);

vars panel2 = rc_coloured_panel(
	10, 10, 40, 40, 'blue', [[TEXT {bg 'blue'}: 'blue']], panel1);

vars panel3 = rc_coloured_panel(
	"middle", "middle", 40, 40, 'blue', [[TEXT {bg 'blue'}: 'mid']], panel1);


*/

section;

uses rclib
uses rc_control_panel

define rc_coloured_panel(x, y, width, height, colour, contents, container) -> panel;

	rc_control_panel(x, y,
		[{width ^width} {height ^height} {bg ^colour}
			^^contents], colour,  if container then container endif) -> panel;

enddefine;

endsection;
