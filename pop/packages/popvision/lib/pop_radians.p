/* --- Copyright University of Sussex 2002. All rights reserved. ----------
 > File:            $popvision/lib/pop_radians.p
 > Purpose:         Definition of angular quantities
 > Author:          David Young, Apr  3 2000 (see revisions)
 > Documentation:   HELP * POP_RADIANS
 > Related Files:   Documentation for *popradians
 */

/* If pop_radians is used instead of popradians, then the angular measures
defined here will always be set to the correct numerical values. */

compile_mode:pop11 +strict;

section;

global vars pop_circle, pop_semicircle, pop_rightangle,
    pop_degree, pop_radian, pop_arcminute, pop_arcsecond;

define active pop_radians;
    popradians
enddefine;

define updaterof active pop_radians(b);
    unless b == pop_radians then
        b -> popradians;
        lconstant twopi = 2 * pi;
        if b then
            twopi -> pop_circle;
            #_< twopi / 360.0 >_# -> pop_degree;
            1.0 -> pop_radian
        else
            360.0 -> pop_circle;
            1.0 -> pop_degree;
            #_< 360.0 / twopi >_# -> pop_radian
        endif;
        pop_circle / 2.0 -> pop_semicircle;
        pop_circle / 4.0 -> pop_rightangle;
        pop_degree / 60.0 -> pop_arcminute;
        pop_degree / 3600.0 -> pop_arcsecond;
    endunless
enddefine;

not(popradians) -> pop_radians;      ;;; set up initial values
not(popradians) -> pop_radians;      ;;; (need to force change)

endsection;

/* --- Revision History ---------------------------------------------------
--- David Young, Jun 13 2002
        Put in test for whether setting has changed, for efficiency
 */
