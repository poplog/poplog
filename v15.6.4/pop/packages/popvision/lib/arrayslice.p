/* --- Copyright University of Sussex 1998. All rights reserved. ----------
 > File:            $popvision/lib/arrayslice.p
 > Purpose:         Extract and update subspaces of arrays
 > Author:          David S Young, Aug 17 1998
 > Documentation:   HELP * ARRAYSLICE
 > Related Files:   See uses statements
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses boundslist_utils
uses arraysample

define lconstant adddim(bounds, dim, i) /* -> bounds */;
    ;;; Adds a dimension to a boundslist. A 1-pixel thick dimension
    ;;; with index i is added before the dim'th dimension.
    lvars x0, x1, d=1;
    [%
        until bounds == [] do
            dest(dest(bounds)) -> (x0, x1, bounds);
            if d == dim then i, i endif;
            x0, x1;
            d + 1 -> d
        enduntil;
        if d == dim then i, i endif
    %]
enddefine;

define lconstant remdim(bounds, dim) /* -> bounds */;
    ;;; Removes the dim'th dimension from the boundslist.
    lvars x0, x1, d=1;
    [%
        until bounds == [] do
            dest(dest(bounds)) -> (x0, x1, bounds);
            unless d == dim then x0, x1 endunless;
            d + 1 -> d
        enduntil;
    %]
enddefine;

define arrayslice(arr, dim, i, arrout, regionout) -> arrout;
    ;;; Extract an N-1 dimensional "slice" from an N-dimensional array.

    lvars ndimin = pdnargs(arr);
    checkinteger(dim, 1, ndimin);

    ;;; If arrout given, check and set up (N-1)-dim output region
    if arrout then
        unless pdnargs(arrout) == ndimin-1 then
            mishap(arrout, arr, 2,
                'Wrong number of dimensions for output')
        endunless;
        unless regionout then
            boundslist(arrout) -> regionout
        endunless;
    endif;

    ;;; Set up N-dim input region - same as output region but with
    ;;; the missing dimension present with thickness 1 pixel.
    lvars regionin;
    if regionout then       ;;; infer input region from output region
        adddim(regionout, dim, i) -> regionin;
        unless length(regionin) div 2 == ndimin then
            mishap(regionout, arr, dim, 3,
                'Wrong number of dimensions for output region')
        endunless
    else                    ;;; infer input region from input array bounds
        copylist(boundslist(arr)) -> regionin;
        (i, i) -> nthbounds(regionin, dim);
        remdim(regionin, dim) -> regionout      ;;; and set up output region
    endif;

    ;;; Set up N-dim output array
    lvars arroutp = false;
    if arrout then         ;;; construct N-dim array on arrout
        lvars boundsoutp, boundsout = boundslist(arrout);
        if regionout = boundsout then
            regionin -> boundsoutp
        else
            adddim(boundsout, dim, i) -> boundsoutp
        endif;
        lvars ( , off) = arrayvector_bounds(arrout);
        newanyarray(boundsoutp, arrout, off-1, arrout.isarray_by_row)
            -> arroutp
    endif;

    ;;; Copy the data. arraysample requires input and out to have same
    ;;; number of dimensions - in this case N.
    arraysample(arr, regionin, arroutp, regionin, "nearest") -> arroutp;

    ;;; If output array supplied it will now have the correct data.
    ;;; Otherwise need to build (N-1)-dim array on N-dim arroutp, which
    ;;; will already have regionout as its boundslist.
    unless arrout then
        newanyarray(regionout, arroutp, arroutp.isarray_by_row) -> arrout
    endunless
enddefine;

define updaterof arrayslice(arrin, regionin, arrout, dim, i);
    ;;; Insert an N-1 dimensional "slice" into N dimensional array.
    ;;; Simpler than the forward procedure because both input and output
    ;;; arrays must be provided.

    lvars ndimin = pdnargs(arrin), ndimout = pdnargs(arrout);
    unless ndimin+1 = ndimout then
        mishap(arrin, arrout, 2, 'Wrong number of dimensions')
    endunless;

    lvars boundsin = boundslist(arrin);
    unless regionin then
        boundsin -> regionin
    endunless;

    lvars regionout = adddim(regionin, dim, i);

    lvars boundsinp;
    if regionin = boundsin then
        regionout -> boundsinp
    else
        adddim(boundsin, dim, i) -> boundsinp
    endif;

    lvars arrinp,
        ( , off) = arrayvector_bounds(arrin);
    newanyarray(boundsinp, arrin, off-1, arrin.isarray_by_row) -> arrinp;

    arraysample(arrinp, regionout, arrout, regionout, "nearest") -> ;
enddefine;

endsection;
