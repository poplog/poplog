/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/auto/rc_window_coords.p
 > Purpose:			Get or update rc_graphic window dimensions
 > Author:          Aaron Sloman, Oct 23 1995
 > Documentation:	See example below
 > Related Files:	LIB * rc_window_dimensions
 */

/*
From Aaron Sloman Thu Oct 19 21:39:33 BST 1995
To: C.J.Paterson@cs.bham.ac.uk
Subject: Re: rc_graphics
Cc: pop-forum@hplb.hpl.hp.com

Christian,

> How do I get the x window coordinates for a live rc_graphic window?

I assume you mean after the window has been manually moved, since, the
teach and help files tell you about rc_window_x and rc_window_y.

I am copying my answer to pop-forum (comp.lang.pop) in case someone else
has a better answer. It is incredibly difficult to find out simple
things like this from the Poplog online X documentation (much of which
quite unreasonably assumes users are going to have X manuals on their
desks).

After much fruitless searching of online documentation, I eventually
made a guess that I had to use XptShellOfObject to get XptWidgetCoords
to do what I expected, and found that this worked. A procedure (with
updater) to access and update current window location of the rc_graphic
window.

*/
/*
rc_start();
;;; move window around and check this
rc_window_coords() =>

600,800 -> rc_window_coords();

vars x;
for x from 1 by 10 to 700 do
	x, 100 -> rc_window_coords()
endfor;

*/

section;

compile_mode :pop11 +strict;

define vars procedure rc_window_coords() -> (x, y);
	;;; Return x and y position of rc_window on screen
	lvars x,y;
	XptWidgetCoords(XptShellOfObject(rc_window)) ->(x, y, , );
enddefine;

define updaterof rc_window_coords(x, y);
	;;; integers x and y should be on the stack
	x,y,false,false ->
		XptWidgetCoords(XptShellOfObject(rc_window));
enddefine;

endsection;
