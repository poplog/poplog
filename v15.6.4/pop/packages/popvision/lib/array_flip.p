/* --- Copyright University of Sussex 2001. All rights reserved. ----------
 > File:            $popvision/lib/array_flip.p
 > Purpose:         Flip a 2-D array top-bottom, left-right or both
 > Author:          David Young, Apr 10 2001
 > Documentation:   HELP * ARRAY_FLIP
 > Related files:   LIB * ARRAYSAMPLE
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses arraysample

define array_flip(arr, region, lr, ud, arrout) -> arrout;
    unless region then
        boundslist(arr) -> region
    endunless;
    lvars regout = copylist(region);
    if lr then
        (regout(1), regout(2)) -> (regout(2), regout(1))
    endif;
    if ud then
        (regout(3), regout(4)) -> (regout(4), regout(3))
    endif;
    arraysample(arr, region, arrout, regout, "nearest") -> arrout
enddefine;

endsection;
