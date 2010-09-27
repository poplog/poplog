/* --- Copyright University of Sussex 1997. All rights reserved. ----------
 > File:            $popvision/lib/line_intersection.p
 > Purpose:         Find intersection point of two lines
 > Author:          David S Young, Feb 21 1997
 > Documentation:   HELP * LINE_INTERSECTION
 */

compile_mode:pop11 +strict;

section;

define line_intersection(a1, a2, b1, b2, c1, c2, d1, d2) -> (s1, s2);
    lvars a1, a2, b1, b2, c1, c2, d1, d2, s1, s2;
    lvars
        ab1 = a1 - b1,  ab2 = a2 - b2,
        cd1 = c1 - d1,  cd2 = c2 - d2,
        D = ab1 * cd2 - ab2 * cd1;
    if D = 0 then       ;;; parallel (should this use a tolerance?)
        false ->> s1 -> s2
    else
        lvars
            r1 = a1 * b2 - a2 * b1,
            r2 = c1 * d2 - c2 * d1;
        (cd1 * r1 - ab1 * r2) / D -> s1;
        (cd2 * r1 - ab2 * r2) / D -> s2;
    endif
enddefine;

endsection;
