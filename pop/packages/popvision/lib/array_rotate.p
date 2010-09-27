/* --- Copyright University of Sussex 2000. All rights reserved. ----------
 > File:            $popvision/lib/array_rotate.p
 > Purpose:         Circularly shift data in an array region
 > Author:          David Young, Feb 22 2000
 > Documentation:   HELP * ARRAY_ROTATE
 > Related Files:   LIB * ARRAY_WRAP, LIB * ARRAYSHIFT
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses arrayshift
uses array_wrap

define array_rotate(arrin, region, shift, arrout) -> arrout;
    unless region then boundslist(arrin) -> region endunless;
    arrayshift(arrin, shift) -> arrin;
    lvars newregin = arrayshift(region, shift);
    array_wrap(arrin, newregin, arrout, region) -> arrout
enddefine;

endsection
