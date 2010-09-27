/* --- Copyright University of Sussex 1997. All rights reserved. ----------
 > File:            $popvision/lib/array_halfsize.p
 > Purpose:         Reduce the dimensions of an array to half
 > Author:          David S Young, Feb 17 1997
 > Documentation:   HELP * ARRAY_HALFSIZE
 > Related Files:   See "uses" statements
 */

/* Reduce an array to half the linear size by averaging, discarding a row
and/or a column if necessary. */

compile_mode:pop11 +strict;

section;

uses popvision
uses arraysample
uses oldarray

define lconstant even(x); x && 1 == 0 enddefine;

define lconstant newbounds(x0, x1, option) -> (x0, x1, X0, X1);
    lvars x0, x1, option, X0, X1;
    if option == "average" then
        if even(x0) then
            if even(x1) then x1-1 -> x1 endif;
            x0 div 2 -> X0;  (x1-1) div 2 -> X1
        else
            if not(even(x1)) then x1-1 -> x1 endif;
            (x0+1) div 2 -> X0; x1 div 2 -> X1
        endif
    else        ;;; option = sample
        if even(x0) then
            if not(even(x1)) then x1-1 -> x1 endif;
            x0 div 2 -> X0;  x1 div 2 -> X1
        else
            if even(x1) then x1-1 -> x1 endif;
            (x0+1) div 2 -> X0; (x1+1) div 2 -> X1
        endif
    endif
enddefine;

define array_halfsize(array, region, arrout, option) -> arrout;
    lvars array, region, arrout, option;
    unless region then boundslist(array) -> region endunless;
    unless option then "average" -> option endunless;
    lvars x0, x1, X0, X1, y0, y1, Y0, Y1, inbounds = [], outbounds = [];

    if option == "average" or option == "sample" then
        until region == [] do
            dest(dest(region)) -> (x0, x1, region);
            newbounds(x0, x1, option) -> (x0, x1, X0, X1);
            conspair(x1, conspair(x0, inbounds)) -> inbounds;
            conspair(X1, conspair(X0, outbounds)) -> outbounds;
        enduntil;
        fast_ncrev(inbounds) -> inbounds;
        fast_ncrev(outbounds) -> outbounds;

        if option == "sample" then "nearest" -> option endif;
        arraysample(array, inbounds, arrout, outbounds, option) -> arrout

    elseif option == "field1" or option == "field2" then
        unless pdnargs(array) == 2 then
            mishap(option, array, 2, '2-D array needed for this option')
        endunless;
        explode(region) -> (x0, x1, y0, y1);
        if option == "field2" then y0 + 1 -> y0 endif;  ;;; 2nd set of lines
        newbounds(y0, y1, "sample") -> (y0, y1, Y0, Y1);
        lvars
            interkey = datakey(arrayvector(arrout or array)),
            interarr = oldanyarray(array_halfsize, [^(x0,x1,Y0,Y1)], interkey);
        arraysample(array, [% x0, x1, y0, y1 %], interarr,
            false, "nearest") -> ;
        newbounds(x0, x1, "average") -> (x0, x1, X0, X1);
        arraysample(interarr, [% x0, x1, Y0, Y1 %],
            arrout, [% X0, X1, Y0, Y1 %], "average") -> arrout

    else
        mishap(option, 1, 'Unrecognised sampling option')
    endif
enddefine

endsection
