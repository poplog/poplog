/* --- Copyright University of Sussex 2000. All rights reserved. ----------
 > File:            $popvision/lib/arrayshift.p
 > Purpose:         Shift coordinates of array by specified vector
 > Author:          David S Young, Nov 16 1994 (see revisions)
 > Documentation:   HELP * ARRAYSHIFT
 */

compile_mode:pop11 +strict;

section;

define arrayshift(arr, shift /* [, shiftcrds]*/) /* -> newarr */;
    lvars arr, shift, shiftcrds = false;

    if shift.isboolean then
        (arr, shift) -> (arr, shift, shiftcrds)
    endif;

    lvars s, b1, b2, newb,
        5 op = shiftcrds and nonop - or nonop +,
        b = arr.isarray and boundslist(arr) or arr;

    [%
        if shift.islist then
            for s in shift do
                dest(dest(b)) -> (b1, b2, b);
                b1 op s, b2 op s
            endfor
        elseif shift.isvector then
            for s in_vector shift do
                dest(dest(b)) -> (b1, b2, b);
                b1 op s, b2 op s
            endfor
        elseif shift.isnumber then
            until b == [] do
                dest(dest(b)) -> (b1, b2, b);
                b1 op shift, b2 op shift
            enduntil
        else
            mishap(shift, 1, 'List, vector or number needed')
        endif
    %] -> newb;
    unless b == [] then
        mishap(shift, 1, 'Shift list or vector too short')
    endunless;

    if arr.isarray then
        lvars ( , off) = arrayvector_bounds(arr);
        newanyarray(newb, arr, off-1, arr.isarray_by_row)
    else
        newb
    endif
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David Young, Mar 28 2000
        Changed fi_+ and fi_- to + and - to ensure mishap if non-integer
        shifts applied to array argument. Allowed shift to be a general
        number.
 */
