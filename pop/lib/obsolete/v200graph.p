/*  --- Copyright University of Sussex 1996.  All rights reserved. ---------
 >  File:           C.all/lib/obsolete/v200graph.p
 >  Purpose:        Facilities for driving the Visual200 in VT-52 mode.
 >  Author:         Aaron Sloman, Jul 26 1980 (see revisions)
 >  Documentation:  See below
 >  Related Files:  LIB * ACTIVE
 */

/*
Including facilities for scrolling below a window area, defined by Scrollrow.
Assumes user function will draw the window as necessary, and set Displayed
true when it has done so.

VISUAL-200, or VT-52 codes used-
	<esc> to set 'code' mode
	Y   precedes screen co-ordinates Row,Col
	t   clear line
	v   clear screen
	M   delete line
	N + 32  represents code for co-ordinate N
	F   change to graphic mode
	G   reset from graphic

*/

section;

vars Vcode;
vedscreenescape -> Vcode;

define procedure Vpage();
	sysflush(popdevout);  ;;; flush charout
	;;;clear the screen
	vedscreencontrol(vvedscreenclear);
	sysflush(poprawdevout);
enddefine;

define procedure Vnum(n);
	;;; output character code representing a row or column number
	lvars n;
	rawcharout(32 + n)
enddefine;

lvars Vpointcount=0;

define procedure Vpoint(x,y);
	;;; move cursor to column x row y (down from top)
	lvars x,y;
	sysflush(popdevout);  ;;; flush charout
	vedscreencontrol('\^[Y');
	Vnum(y); Vnum(x);
	if Vpointcount == 10 then
		sysflush(poprawdevout);	;;; Added A.S. Aug 1986
		1 -> Vpointcount;
	else
		Vpointcount fi_+ 1 -> Vpointcount
	endif;
enddefine;

define procedure Vcl(y);
	;;; clear row y
	lvars y;
	Vpoint(0,y);
	vedscreencontrol(vvedscreencleartail);
enddefine;

define procedure Vdl(y);
	;;; delete row y
	lvars y;
	Vpoint(0,y);
	vedscreencontrol('\^[M');
	sysflush(poprawdevout);
enddefine;

define procedure Vgraph();
	sysflush(popdevout);  ;;; flush charout
	;;; set graphic mode
	vedscreencontrol('\^[F')
enddefine;

define procedure Vnograph();
	vedscreencontrol('\^[G')
enddefine;

;;; Facilities for using only space below picture,
;;; defined by Scrolrow
vars Scrolling;
unless Scrolling=false then true->Scrolling endunless;

vars Scrolled Justin Justout Scrolrow Lout;
false ->> Scrolled->>Justin->>Justout->Lout;

vars Displayed; false -> Displayed;
	;;; user function should set this true after displaying window.

define procedure Scroll();
	;;; delete the line below picture, to cause scrolling
	if Scrolling then Vdl(Scrolrow) endif;
	Vpoint(0,22);
	if Justin and poplastchar == `\n` then vedscreencleartail() endif;
	true -> Scrolled; false -> Displayed;
enddefine;


define procedure Vin()->c;
	;;;To be used as character repeater, through which to compile
	lvars c;
	if  Displayed then
		if Justout or not(Scrolled) then Scroll(); false -> Displayed
		else Vpoint(0,22)
		endif
	endif;
	if  Scrolling
	then
		if  poplastchar == `\n and (not(Justout) or Lout == `\n)
		then    Scroll();
		endif;
	endif;
	sysflush(poprawdevout);
	charin() ->c;
	true -> Justin;
	false -> Justout;
enddefine;

define procedure Vout(c);
	;;; make all printing go through this
	lvars c;
	if  Scrolling
	then
		if  Displayed
		or  (Lout == `\n and not(Scrolled)
		and poplastchar == `\n) then
			Scroll()
		endif;
		if c == `\n then Scroll() endif;
	endif;
	sysflush(poprawdevout);
	c.charout;
	true -> Justout;
	false ->> Displayed-> Justin;
	c -> Lout;
enddefine;

endsection;

nil->proglist;

/* --- Revision History ---------------------------------------------------
--- John Williams, Jan  3 1996
		Moved from C.all/lib/lib to C.all/lib/obsolete
--- Jason Handby, Jul 28 1989
	replaced -vedscreenscape- with -vedscreencontrol-
--- John Gibson, Nov 11 1987
		Replaced -popdevraw- with -poprawdevin- and -poprawdevout-
--- Aaron Sloman, Aug 19 1986
	Lvarsed
	Replaced charout(0) with sysflush(popdevout)
	Flush(poprawdevout) from time to time in Vpoint to cure problems with V55
	Removed POP-2-isms
	Defined procedures as 'procedure'
*/
