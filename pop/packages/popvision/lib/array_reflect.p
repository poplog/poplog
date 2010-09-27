/* --- Copyright University of Sussex 1992. All rights reserved. ----------
 > File:            $popvision/lib/array_reflect.p
 > Purpose:         Extend an array with symmetric boundary conditions
 > Author:          David Young, Nov 12 1992 (see revisions)
 > Documentation:   HELP *ARRAY_REFLECT
 > Related Files:   LIB *ARRAYSAMPLE
 */

/* Extend an array or region by reflecting it as necessary.
Works for any number of dimensions. */

compile_mode:pop11 +strict;

section;

uses popvision
uses arraysample
uses boundslist_utils

define array_reflect(arrin, regionin, arrout, regionout) -> arrout;
    lvars arrin, regionin, arrout, regionout;
    unless regionin then boundslist(arrin) -> regionin endunless;
    unless regionout then boundslist(arrout) -> regionout endunless;
    ;;; Can only extend an array, so output region must include input region
    region_inclusion_check(regionout, regionin);
    ;;; Also need non-inverted regions
    region_nonempty_check(regionin);
    region_nonempty_check(regionout);
    ;;; Have to create output array now if needed, as arraysample does
    ;;; not know final dimensions till later.
    unless arrout then
        newanyarray(regionout, datakey(arrayvector(arrin))) -> arrout
    endunless;
    ;;; Copy main part of array (arraysample correctly handles the case
    ;;; where no copy is needed, so no need to check here)
    arraysample(arrin, regionin, arrout, regionin, "nearest") -> arrout;

    ;;; Now loop over dimensions of the array, extending the array
    ;;; along each one in turn.
    lvars
        regionfrom = copylist(regionin),    ;;; protect boundslists
        regionto = copylist(regionin),
        dim, i0, origi0, i1, o0, o1, istart, oend, t;
    for dim from 1 to pdnargs(arrin) do
        nthbounds(regionin, dim) -> (i0, i1);
        nthbounds(regionout, dim) -> (o0, o1);
        i0 -> origi0;

        ;;; Use loop in case need multiple copies.
        until o0 == i0 do
            ;;; Need to add an extra i0-o0 elements - so start from
            ;;; i0 + (i0-o0) - 1, checking we stay inside current data
            2 * i0 - 1 -> t;
            min(t - o0, i1) -> istart;
            t - istart -> oend;
            (i0, istart) -> nthbounds(regionfrom, dim);
            (i0-1, oend) -> nthbounds(regionto, dim);
            arraysample(arrout, regionfrom, arrout, regionto, "nearest")
                -> arrout;
            oend -> i0;
            ;;; OK to change origi0 if the increase was by a whole frame
            if istart == i1 then i0 -> origi0 endif;
        enduntil;

        ;;; Important to use i0 corresponding to frame boundary
        until o1 == i1 do
            2 * i1 + 1 -> t;
            max(t - o1, origi0) -> istart;
            t - istart -> oend;
            (i1, istart) -> nthbounds(regionfrom, dim);
            (i1+1, oend) -> nthbounds(regionto, dim);
            arraysample(arrout, regionfrom, arrout, regionto, "nearest")
                -> arrout;
            oend -> i1
        enduntil;

        ;;; finished this dimension - update bounds for other dimensions
        (i0, i1) -> nthbounds(regionfrom, dim);
        (i0, i1) -> nthbounds(regionto, dim);

    endfor
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David S Young, Nov 26 1992
        Installed
 */
