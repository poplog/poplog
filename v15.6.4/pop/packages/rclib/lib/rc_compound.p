/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/lib/rc_compound.p
 > Purpose:			Creating compound pictures
 > Author:          Aaron Sloman, May 18 1997
 > Documentation:
 > Related Files:
 */



section;
uses objectclass
uses rclib
uses rc_linepic

define :mixin rc_compound is rc_linepic;
	slot rc_components ==[];
enddefine;

define :mixin rc_component is rc_linepic;
	slot rc_part_of;
enddefine;

define :method rc_draw_linepic(p: rc_compound);

	dlocal
		rc_xorigin = rc_xorigin + rc_picx(p)*rc_xscale,
		rc_yorigin = rc_yorigin + rc_picy(p)*rc_yscale;

	applist(rc_components(p), rc_draw_linepic)
enddefine;

define :method rc_undraw_linepic(p: rc_compound);

	dlocal
		rc_xorigin = rc_xorigin + rc_picx(p)*rc_xscale,
		rc_yorigin = rc_yorigin + rc_picy(p)*rc_yscale;

	applist(rc_components(p), rc_undraw_linepic)
enddefine;

define :method rc_move_by(p:rc_compound, dx, dy, draw);

	lvars part;

	for part in rc_components(p) do rc_move_by(part, dx, dy, draw)
	endfor;

	rc_picx(p) + dx -> rc_picx(p);
	rc_picy(p) + dy -> rc_picy(p);

enddefine;

define :method rc_move_to(p:rc_compound, x, y, draw);

	rc_move_by(p, x - rc_picx(p), y - rc_picy(p), draw)

enddefine;



endsection;
