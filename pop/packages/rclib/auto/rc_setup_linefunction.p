/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_setup_linefunction.p
 > Purpose:			Ensure that Glinefunction has the right value
					either GXxor or GXequiv, depending on screen
 > Author:          Aaron Sloman, Mar 24 1997 (see revisions)
 > Documentation:	TEACH * RC_LINEPIC
 > Related Files:	LIB * rc_black_white_inverted, rc_linepic
 */

/*
A procedre that needs to ensure that the right linefunction is
used can do something like this:

	unless Glinefunctionsetup then rc_setup_linefunction() endunless;

or, at slightly greater cost:

	rc_setup_linefunction()

*/

compile_mode :pop11 +strict;

section;
exload_batch;
uses popxlib;
uses xlib;
;;; load graphic operations as permanent identfiers
loadinclude xpt_xgcvalues;
uses XlibMacros;
uses XpwGraphic;
uses rclib

/*
define Glinefunction and Gdrawprocedure
*/

/*
Normally the assumption will be that rc_linefunction will be set to
GXxor or for some terminals GXequiv. A consequence is that on coloured
windows choosing the right foreground colour to give desired appearance
when xor-ed with the background colour can be tricky.

*/


global vars Glinefunction;
;;; set up defaults

if isundef(Glinefunction) then
	;;; default, for suns etc, can be overridden by rc_setup_linefunction()
	GXxor -> Glinefunction;
	;;; This is the default in lib rc_linepic
	;;; rc_xor_drawpic -> Gdrawprocedure;
endif;

;;; Default value set below is rc_xor_drawpic. May need to be set to
;;; rc_equiv_drawpic, for use with DEC Alpha terminals, and some others.

global vars Glinefunctionsetup = false;

;;; These are defined in LIB * RC_LINEPIC
global vars procedure( Gdrawprocedure, rc_equiv_drawpic, rc_xor_drawpic );


define rc_setup_linefunction();

	unless Glinefunctionsetup then
		unless XptDefaultDisplay then XptDefaultSetup(); endunless;
		useslib("rc_linepic");

		lvars
			screendepth = XDefaultDepth(XptDefaultDisplay, 0),
			whitepixel = XWhitePixel(XptDefaultDisplay, 0);

		if whitepixel == 1  then
			GXequiv -> Glinefunction;
			rc_equiv_drawpic -> Gdrawprocedure;	
		else
			rc_xor_drawpic -> Gdrawprocedure;
			if whitepixel == 0 then
				GXxor
			elseif whitepixel == 2**screendepth - 1 then
				GXequiv
			else
				mishap('Cannot identify drawing procedure for screen',[])
			endif -> Glinefunction;
		endif;
		
		true -> Glinefunctionsetup;
	endunless;
enddefine;

endexload_batch;
endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Dec 25 1999
	Changed to do more exhaustive checks.
 */
