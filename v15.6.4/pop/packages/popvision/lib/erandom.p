/* --- Copyright University of Sussex 1996. All rights reserved. ----------
 > File:            $popvision/lib/erandom.p
 > Purpose:         Pseudo-random number generation using external routines
 > Author:          David S Young, Aug  9 1996
 > Documentation:   HELP * ERANDOM
 > Related Files:   LIB * ARRAY_RANDOM
 */

compile_mode:pop11 +strict;

section;

uses popvision

global vars procedure erandom = identfn;  ;;; so array_random does not reload
uses array_random

lconstant buflen = 1024,
    bufbounds = [1 ^buflen];

define erandom(spec) /* -> rand */;
    lvars spec;
    lvars
        buffer = newsfloatarray(bufbounds),
        ptr = buflen,
        (type, p0, p1) = array_random_spec(spec, buffer);

    define lconstant erandom1 /* -> val */;
        ptr fi_+ 1 -> ptr;
        if ptr fi_> buflen then
            array_random(spec, buffer, bufbounds) -> ;
            1 -> ptr
        endif;
        buffer(ptr)
    enddefine;

    define lconstant erandom2 /* -> val */;
        ptr fi_+ 1 -> ptr;
        if ptr fi_> buflen then
            array_random(spec, buffer, bufbounds) -> ;
            1 -> ptr
        endif;
        round(buffer(ptr))  ;;; rounding version for integer spec
    enddefine;

    if type == "uniform" and p0.isinteger and p1.isinteger then
        erandom2
    else
        erandom1
    endif
enddefine;

endsection;
