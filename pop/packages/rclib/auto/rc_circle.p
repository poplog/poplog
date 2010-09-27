/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_circle.p
 > Purpose:         Obsolete. Now use rc_draw_circle
 > Author:          Aaron Sloman, Apr  4 1996 (see revisions)
 > Documentation:	rc_circle(x,y,radius)
 > Related Files:
 */

uses rc_draw_circle

syssynonym("rc_circle", "rc_draw_circle");

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul 25 1997
	made a synonym for rc_draw_circle
--- Aaron Sloman, Apr 21 1997
	Fixed another scaling bug. Did not handle positive yscale properly.
--- Aaron Sloman, Apr 12 1996
    Fixed scaling bug. Switched to use XpwDrawArc directly
 */
