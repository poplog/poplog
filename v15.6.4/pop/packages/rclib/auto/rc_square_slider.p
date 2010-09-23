/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_square_slider.p
 > Purpose:         Define sliders with square blbs
 > Author:          Aaron Sloman, Jul  7 1997 (see revisions)
 > Documentation:
 > Related Files:	LIB * RC_SLIDER
 */


section;
compile_mode
            :pop11 +varsch +defpdr -defcon -lprops -constr +global
            :vm +prmfix
            :popc -wrdflt -wrclos;


uses rclib
uses rc_slider


global vars
	rc_slider_square_thickness_def= 2;

define :class vars rc_square_slider; is rc_slider;
	slot rc_draw_slider_blob == "rc_draw_slider_square";
	slot rc_slider_square_thickness = rc_slider_square_thickness_def;
enddefine;

define :method rc_draw_slider_square(s:rc_square_slider);
	;;; for non-circular blobs
	lvars
		scale = max(abs(rc_xscale), abs(rc_yscale))+0.0,
		rx = rc_slider_blobradius(s)/abs(rc_xscale),
		ry = rc_slider_blobradius(s)/abs(rc_yscale),
		colour = rc_slider_blobcol(s),
		thick = round(rc_slider_square_thickness(s)/scale);
	
	dlocal
		%rc_foreground(rc_window)%,
		rc_linewidth;

	if colour then colour -> rc_foreground(rc_window) endif;
	if thick then thick -> rc_linewidth endif;
	rc_draw_centred_square(0, 0, rx+ry, colour, thick);
	rc_drawline(-rx+thick, -ry+thick, rx-thick, ry-thick);
	rc_drawline(-rx+thick, ry-thick, rx-thick, -ry+thick);

enddefine;

define rc_square_slider(x1, y1, x2, y2, range, radius, linecol, slidercol, strings) -> slider;
	lvars spec, wid;

	;;; see if word or identifier argument is provided.
	if isword(strings) or isident(strings) then
		(x1, y1, x2, y2, range, radius, linecol, slidercol, strings) ->
			(x1, y1, x2, y2, range, radius, linecol, slidercol, strings, wid)
	else
		false -> wid
	endif;

	;;; see if optional featurespec argument has been provided
	if isvector(strings) then
		x1, y1, x2, y2, range, radius, linecol, slidercol, strings
        ->
		(x1, y1, x2, y2, range, radius, linecol, slidercol, strings, spec)
	else
		false -> spec
	endif;

	if wid then
		create_rc_slider_with_ident
	else
		create_rc_slider
	endif(
		x1, y1, x2, y2, range, radius, linecol, slidercol, strings, spec, newrc_square_slider,
			if wid then wid endif) -> slider;
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep  9 2002
		Changed compile mode
--- Aaron Sloman, Aug  6 2002
		Changed compile mode from strict
--- Aaron Sloman, Jul 28 2002
		Made the class vars
--- Aaron Sloman, Oct 29 1999
	Introduced a fix to rc_draw_slider_square(s:rc_square_slider);
	to work with solaris 2.7 by dlocalising linewidth and colour.
	I don't know why this is needed.
--- Aaron Sloman, Nov  1 1997
	Introduced rc_slider_square_thickness_def

--- Aaron Sloman, Aug  3 1997
	Added a cross on the square, and made the drawing procedure a
	method
 */
