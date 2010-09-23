/* --- Copyright University of Sussex 2002. All rights reserved. ----------
 > File:            $popvision/lib/array_adjoin.p
 > Purpose:         Adjoin arrays
 > Author:          David Young, Aug 30 2002
 > Documentation:   HELP * ARRAY_ADJOIN
 > Related Files:   See "uses" statements
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses arraysample
uses boundslist_utils

define lconstant array_adjoin_check(c1, c2);
    unless c1 == c2 then
        mishap(c1, c2, 2, 'Array dimensions do not match along adjoining side')
    endunless
enddefine;

define array_adjoin(i1, r1, i2, r2, side, i3) -> i3;
    ;;; Adjoin region r2 of i2 to region r1 of i1 on the side specified.
    ;;; All arrays 2-D.
    ;;; Data from i1 stays in the same bounds. Data from i2 is shifted
    ;;; to lie in a region the same size as r2 but in the correct position
    ;;; to be next to r1.
    ;;; Side can be one of the words "top" "bottom" "left" "right" "t" "b"
    ;;; "l" "r" to say which side of i1 to adjoin on. Also can be an integer:
    ;;; side mod 4 = 0,1,2,3 means t,r,b,l respectively.
    ;;; T,b,l,r refer to the sides as seen on the screen when the array
    ;;; array is displayed conventionally as an image on the screen.
    ;;; r1 and r2 dimensions must match along the respective side.

    ;;; Sort out arguments
    unless r1 then boundslist(i1) -> r1 endunless;
    unless r2 then boundslist(i2) -> r2 endunless;
    lvars sidelist;
    if side.isinteger then
        side mod 4 -> side
    elseif lmember(side, [top left bottom right t l b r]) ->> sidelist then
        length(sidelist) mod 4 -> side
    else
        mishap(side, 1, 'Unrecognised side argument')
    endif;

    ;;; Do some checks
    unless pdnargs(i1) == 2 and length(r1) == 4
    and pdnargs(i2) == 2 and length(r2) == 4 then
        mishap(i1,r1,i2,r2, 4, '2-D arrays and regions needed')
    endunless;
    region_nonempty_check(r1);
    region_nonempty_check(r2);

    ;;; Get output region for r2 and combined region
    lvars outreg2, outreg3,
        (x10, x11, y10, y11) = explode(r1),
        x1 = x11-x10+1, y1 = y11-y10+1,
        (x20, x21, y20, y21) = explode(r2),
        x2 = x21-x20+1, y2 = y21-y20+1;
    switchon side ==
    case 0 then
        array_adjoin_check(x1, x2);
        [% x10, x11, y10-y2, y10-1 %] -> outreg2;
        [% x10, x11, y10-y2, y11 %] -> outreg3;
    case 1 then
        array_adjoin_check(y1, y2);
        [% x11+1, x11+x2, y10, y11 %] -> outreg2;
        [% x10, x11+x2, y10, y11 %] -> outreg3;
    case 2 then
        array_adjoin_check(x1, x2);
        [% x10, x11, y11+1, y11+y2 %] -> outreg2;
        [% x10, x11, y10, y11+y2 %] -> outreg3;
    case 3 then
        array_adjoin_check(y1, y2);
        [% x10-x2, x10-1, y10, y11 %] -> outreg2;
        [% x10-x2, x11, y10, y11 %] -> outreg3;
    endswitchon;

    ;;; Check the output array
    if i3 then
        region_inclusion_check(i3, outreg3)
    else
        newanyarray(outreg3, datakey(arrayvector(i1))) -> i3
    endif;

    ;;; Do the copy
    arraysample(i1, r1, i3, r1, "nearest") -> ;
    arraysample(i2, r2, i3, outreg2, "nearest") -> ;
enddefine;

endsection;
