/* --- Copyright University of Sussex 2000. All rights reserved. ----------
 > File:            $popvision/lib/array_wrap.p
 > Purpose:         Extend an array with periodic boundary conditions
 > Author:          David Young, Nov 12 1992 (see revisions)
 > Documentation:   HELP *ARRAY_WRAP
 > Related Files:   LIB *ARRAYSAMPLE
 */

/* Extend an array or region by wrapping it round as necessary.
Works for any number of dimensions. */

compile_mode:pop11 +strict;

section;

uses popvision
uses arraysample
uses arrayset
uses boundslist_utils

define lconstant array_wrap_1d(dim, arrin, regionin, arrout, regionout);
    ;;; Wrap on dimension dim. Updates arrout.
    ;;; Regionin and regionout should be identical apart from one dimension.
    lvars
        (s0, s1) = nthbounds(arrin, dim),
        (r0, r1) = nthbounds(regionin, dim),
        (d0, d1) = nthbounds(regionout, dim),
        dend = d1 + 1,
        N = r1 - r0 + 1;

    ;;; Next two lines mean that data outside regionin is not used
    max(r0, s0) -> s0;
    min(r1, s1) -> s1;

    lvars ntodom1,
        sN = s0 + N,
        sNm1 = sN - 1,
        rin = copylist(regionin),           ;;; will be
        rout = copylist(regionout);         ;;; updated
    s0 + (d0-s0) mod N -> s0;               ;;; starting point for copy
    until d0 == dend do
        if s0 <= s1 then
            min(s1-s0, d1-d0) -> ntodom1;
            (s0, s0+ntodom1) -> nthbounds(rin, dim);
            (d0, d0+ntodom1) -> nthbounds(rout, dim);
            arraysample(arrin, rin, arrout, rout, "nearest") -> ;
        else
            min(sNm1-s0, d1-d0) -> ntodom1;
            (d0, d0+ntodom1) -> nthbounds(rout, dim);
            arrayset(0, arrout, rout);
        endif;
        s0 + ntodom1 + 1 -> s0;
        d0 + ntodom1 + 1 -> d0;
        if s0 == sN then s0 - N -> s0 endif
    enduntil
enddefine;

define array_wrap(arrin, regionin, arrout, regionout) -> arrout;

    ;;; Sort out arguments
    unless regionin then boundslist(arrin) -> regionin endunless;
    unless regionout then boundslist(arrout) -> regionout endunless;
    ;;; Also need non-inverted regions
    region_nonempty_check(regionin);
    region_nonempty_check(regionout);
    ;;; Create output array now if needed
    lvars key;
    unless arrout then
        datakey(arrayvector(arrin)) -> key;
        newanyarray(regionout, datakey(arrayvector(arrin))) -> arrout
    else
        datakey(arrayvector(arrout)) -> key;
        region_inclusion_check(arrout, regionout);
    endunless;

    ;;; Loop over dimensions of the array, extending the array
    ;;; along each one in turn.
    lconstant tag1 = consref(0), tag2 = consref(0);
    lvars dim, r0, r1, temparr, t1 = tag1, t2 = tag2,
        rin = region_intersect(arrin, regionin),  ;;; current input region
        rout = copylist(rin);            ;;; will be current output region
    for dim from 1 to pdnargs(arrin) do
        nthbounds(regionin, dim) -> nthbounds(rin, dim);
        nthbounds(regionout, dim) -> (r0, r1);
        (r0, r1) -> nthbounds(rout, dim);
        if rout = regionout then
            array_wrap_1d(dim, arrin, rin, arrout, rout);
            quitloop
        else
            oldanyarray(t1, copylist(rout), key) -> temparr;
            array_wrap_1d(dim, arrin, rin, temparr, rout);
            temparr -> arrin;
            (r0, r1) -> nthbounds(rin, dim);
            (t2, t1) -> (t1, t2)
        endif
    endfor
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David Young, Feb 22 2000
        Completely rewritten to remove restrictions on the output and input
        regions.
--- David S Young, Nov 26 1992
        Installed
 */
