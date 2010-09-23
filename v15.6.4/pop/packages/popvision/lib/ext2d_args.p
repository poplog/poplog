/* --- Copyright University of Sussex 1994. All rights reserved. ----------
 > File:            $popvision/lib/ext2d_args.p
 > Purpose:         Simplify calling C procedures on regions of arrays
 > Author:          David S Young, Jan 25 1994
 > Documentation:   HELP * EXT2D_ARGS
 */

/*

This is a utility to help in applying an external procedure to regions of
POP11 arrays. The external procedure is assumed to iterate over a 2-D
region of the arrays.  The arguments are a list of arrays, and the region
to be processed in all of them.  The arrays must be ordered by row.

There are 3 cases:

    1.  The arrays are 2-D.  A single call will do.

    2.  The arrays are 1-D equivalent with respect to the region.
        (See HELP * IN_ARRAY for the definition of 1-D equivalence.
        A single call with a dummy second dimension will do.

    3.  The arrays have 3 or more dimensions and are not all 1-D
        equivalent.  Repeated calls are needed.

In cases 1 and 2 a vector of arguments is returned.  In case 3 a
repeater is returned which itself returns successive vectors of
arguments for the external procedure, and termin when finished.

The vector is of length 2 + N * 3 when there are N arrays. The entries
describe a 2-D region to process in the external procedure thus:

    xreg:       The size of the first dimension of the region
    yreg:       The size of the second dimension of the region
    av1:        The arrayvector of the first array
    start1:     The offset of the first element of the region
    jump1:      The increment between successive 1-D sections of
                    the region

with the last 3 entries repeated for successive arrays.

See LIB * ARRAYLOOKUP for how to use this.

*/

compile_mode:pop11 +strict;

section;

uses popvision
uses boundslist_utils;

define ext2d_args(arrlist, region) -> args;
    lvars arrlist, region, args;

    lvars arr,
        iarg,
        ndim = false,
        narrs = length(arrlist);

    initv(2 + 3 * narrs) -> args;   ;;; argument vector

    ;;; Check arrays organised by row, have same no. of dimensions
    ;;; and include region.
    for arr in arrlist do
        unless arr.isarray_by_row then
            mishap(arr, 1, 'Need array ordered by row')
        endunless;
        if ndim then
            unless pdnargs(arr) == ndim then
                mishap(arrlist, 1, 'Array dimensions differ')
            endunless;
        else
            pdnargs(arr) -> ndim
        endif;
        region_inclusion_check(arr, region);
    endfor;

    if ndim == 1 then
        ;;; Treat as special case - avoid overhead of getting
        ;;; indexers etc.
        lvars
            dstart, d0, d1,
            (r0, r1) = explode(region);
        r1 - r0 + 1 -> args(1);         ;;; xreg
        1 -> args(2);                   ;;; yreg
        3 -> iarg;
        for arr in arrlist do
            arrayvector(arr) -> args(iarg);     ;;; avi
            iarg + 1 -> iarg;
            explode(boundslist(arr)) -> (d0, d1);
            arrayvector_bounds(arr) -> ( , dstart);
            dstart - 1 + r0 - d0 -> args(iarg);     ;;; starti
            iarg + 1 -> iarg;
            d1 - d0 + 1 -> args(iarg);      ;;; jumpi
            iarg + 1 -> iarg;
        endfor

    elseif ndim == 2 then
        ;;; The case for which the external code is designed.
        lvars
            dstart, dx0, dx1, dy0, dy1, xdim,
            (rx0, rx1, ry0, ry1) = explode(region);
        rx1 - rx0 + 1 -> args(1);         ;;; xreg
        ry1 - ry0 + 1 -> args(2);                   ;;; yreg
        3 -> iarg;
        for arr in arrlist do
            arrayvector(arr) -> args(iarg);     ;;; avi
            iarg + 1 -> iarg;
            explode(boundslist(arr)) -> (dx0, dx1, dy0, dy1);
            arrayvector_bounds(arr) -> ( , dstart);
            dx1 - dx0 + 1 -> xdim;
            dstart - 1 + xdim * (ry0 - dy0) + rx0 - dx0
                -> args(iarg);     ;;; starti
            iarg + 1 -> iarg;
            xdim -> args(iarg);      ;;; jumpi
            iarg + 1 -> iarg;
        endfor

    else

        lvars ind, startpts, v0, vN,
            indexers = maplist(arrlist, array_indexer);

        ;;; Check for 1-D equivalence
        [%
            for ind in indexers do
                region_arrvec(ind, region) -> (v0, vN);
            quitunless(v0);
                v0;         ;;; on stack
            endfor
        %] -> startpts;

        if v0 then
            ;;; Have 1-D equivalence of all arrays
            vN -> args(1);      ;;; xreg
            1 -> args(2);       ;;; yreg
            3 -> iarg;
            for arr, v0 in arrlist, startpts do
                arrayvector(arr) -> args(iarg);     ;;; avi
                iarg + 1 -> iarg;
                v0 - 1 -> args(iarg);     ;;; starti
                iarg + 1 -> iarg;
                vN -> args(iarg);      ;;; jumpi (exact value unimportant)
                iarg + 1 -> iarg;
            endfor

        else
            ;;; General case - must loop over 2-D slices, so return a
            ;;; repeater.
            lvars bl,
                (rx0, rx1, ry0, ry1)
                = (region(1), region(2), region(3), region(4)),
                argvec = args;
            rx1 - rx0 + 1 -> argvec(1);       ;;; xreg
            ry1 - ry0 + 1 -> argvec(2);       ;;; yreg
            3 -> iarg;
            ;;; Fill arg vector apart from start points
            for arr in arrlist do
                arrayvector(arr) -> args(iarg);     ;;; avi
                iarg + 2 -> iarg;
                boundslist(arr) -> bl;
                bl(2) - bl(1) + 1 -> args(iarg);            ;;; jumpi
                iarg + 2 -> iarg;
            endfor;
            ;;; Set up region of start points, and repeater for coords from it
            lvars subreg = copylist(region);
            rx0 -> subreg(2);
            ry0 -> subreg(4);
            lvars startcoords,
                coordrep = region_rep(subreg);

            ;;; Now can provide procedure - each call returns the vector
            ;;; with the startpoints updated
            procedure /* -> argvec */;
                lvars startcoords = coordrep();
                if startcoords == termin then
                    termin      ;;; returned
                else
                    lvars iargs = 4;                ;;; starti is 4th element
                    for ind in indexers do
                        ind(explode(startcoords)) - 1 -> argvec(iargs);
                        iargs + 3 -> iargs
                    endfor;
                    argvec      ;;; returned
                endif
            endprocedure -> args;

        endif

    endif

enddefine;

endsection;
