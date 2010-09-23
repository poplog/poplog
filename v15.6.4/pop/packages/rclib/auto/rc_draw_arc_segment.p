/* --- Copyright University of Birmingham 2001. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_draw_arc_segment.p
 > Purpose:			Draw part of an arc
 > Author:          Aaron Sloman, Aug 22 2000 (see revisions)
 > Documentation:	HELP RCLIB
 > Related Files:	LIB rc_draw_blob_sector
 */

section;

compile_mode :pop11 +strict;

uses rclib;


define rc_draw_arc_segment(xcentre, ycentre, radius, startangle, incangle, width, colour);

	lvars
		frame_ang = rc_frame_angle,
		diam = radius+radius,
		clock = -sign(rc_yscale);

	dlocal
		rc_linewidth,
		%rc_foreground(rc_window)% = colour;

		if width then width -> rc_linewidth endif;

	dlocal rc_frame_angle;
	0 -> rc_frame_angle;

	;;; [unrotated ^xcentre ^ycentre ang ^rc_frame_angle]=>
	;;; [trans %rc_transxyout(xcentre,ycentre)% ] =>
	;;; rc_transxyout(xcentre,ycentre) ->(xcentre,ycentre);
	rc_rotate_coords_rounded(xcentre,ycentre) ->(xcentre,ycentre);

	;;; [rotated ^xcentre ^ycentre ang ^rc_frame_angle]=>

	;;; Angle units are 1/64 degree

	XpwDrawArc(rc_window,
		round(xcentre - abs(radius*rc_xscale)),
		round(ycentre - abs(radius*rc_yscale)),
		round(abs(diam*rc_xscale)),
		round(abs(diam*rc_yscale)),
		round((startangle+frame_ang)*64*clock),
		round(incangle*64*clock));

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Mar 20 2001
	Made to work with rotated rc_frame_angle
 */
