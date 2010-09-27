/*  --- Copyright University of Sussex 1995.  All rights reserved. ---------
 >  File:           C.all/lib/obsolete/ginread.p
 >  Purpose:        facilities for reading in pictures from the tektronix 4012
 >  Author:         Aaron Sloman, Jan 4 1978 (see revisions)
 >  Documentation:  DOC * GINREAD
 >  Related Files:
 */

#_TERMIN_IF DEF POPC_COMPILING

;;; --------------------------------------------------------------------------
;;; WARNING: This program is liable to be removed or substatially altered in
;;; future version of POPLOG.  If you find a use for it then you are advised
;;; to make a private copy.
;;; ---------------------------------------------------------------------------
pr('WARNING: PLEASE READ WARNING NOTICE IN SHOWLIB GINREAD.P\n');

vars gxyout;
unless isprocedure(gxyout) then popval([lib graphic;]) endunless;

vars gxscale;
unless gxscale.isnumber then 1 ->gxscale endunless;


;;; the fuss in the middle of the next procedure is to do with
;;;  problems of noise on the line. if you dont get the cross-hairs when
;;;  expected, this is probably due to noise. typing carriage return will
;;;  output code 13 , causing appgin to cycle again.

define appgin dofn;
 vars wd i key;
 until key = `.` do
   .setgin;
   .inascii ->wd; wd->key;
	for i from 1 to  5 do
	   wd;
	  if wd=13 then repeat i times .erase; endrepeat; goto l endif;
	 .inascii ->wd;
		l:
	endfor;
   .gincoords.dofn;
   .clrinputbuff;
 enduntil;
enddefine;

cancel wd i key dofn;


vars pictolerance; 5->pictolerance;

vars conspoint destpoint;
unless conspoint.isprocedure then cons -> conspoint endunless;
unless destpoint.isprocedure then dest -> destpoint endunless;

vars distance;
unless distance.isprocedure then
	define distance(p1,p2);
		vars x1 y1 x2 y2;
		destpoint(p1) ->y1 ->x1;
		destpoint(p2) ->y2 ->x2;
		0.0 + (y2 - y1) ->y1;
		0.0 + (x2 - x1) ->x1;
		sqrt( x1 * x1 + y1 * y1)
	enddefine;
endunless;

define ginread;
	;;; read in a list of lists of points. when cross appears,
	;;;    set it and type a character: a dot for end of picture, a comma for
	;;;    beginning of new sub-picture(i.e. do a jump, a question
	;;;    mark to redo the last point, and a hash symbol to restart the
	;;;    current sub-picture, from current coordinates
	vars l; nil ->l;

	define dofn wd xin yin;
		vars pt; conspoint(xin,yin) ->pt;
		if wd= `, then l.rev;
			pt::nil ->l;
			jumpto(xin ,yin);drawto(xin,yin);
		elseif wd=`? then
			pt ->hd(l);
			jumpto(destpoint(hd(tl(l))));
			drawto(xin,yin);
		elseif wd=`# or wd=`  and l=nil then
			pt::nil ->l;jumpto(xin,yin);drawto(xin,yin);
		elseif wd = `  then
			if atom(l) or distance(pt,hd(l)) > pictolerance/gxscale then
				pt::l ->l;
			endif;
			drawto(xin,yin);
		else .clrinputbuff;         ;;; ignore spurious signal
		endif;
		if wd=`.  and l /= nil then l.rev; endif;
	enddefine;
	jumpto(graphx,graphy);
	[%appgin(dofn)%];
	.setvdu;
enddefine;

define helpgin;
'\
space   = drawto current point\
,       = jumpto  c.p.\
?       = cancel last point\
#       = restart since last jump\
.       = finish picture\
'.pr;
enddefine;

define drawlist l;
	if l=nil then return endif;
	jumpto(l.hd.destpoint);
	applist(l.tl, drawto)
enddefine;

define drawpic l;
	;;; l is a list of lists of points
	applist(l,drawlist);
	1.nl;
	.setvdu;
enddefine;


/* --- Revision History ---------------------------------------------------
--- Robert John Duncan, May 22 1995
		Moved to obsolete lib
 */
