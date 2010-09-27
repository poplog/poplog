/* --- Copyright University of Sussex 1998. All rights reserved. ----------
 > File:            $popvision/lib/appline.p
 > Purpose:         Apply a procedure to integer coordinates on a straight line
 > Author:          David S Young, Feb 16 1998
 > Documentation:   HELP * APPLINE
 */

define appline(x0, y0, x1, y1, proc);
    ;;; Calls proc(x,y) for integer (x,y) pairs on the straight line
    ;;; from (x0, y0) to (x1, y1)
    lvars procedure proc;
    lvars k, r, incr, xdiff = abs(x0-x1), ydiff = abs(y0-y1);
    if xdiff > ydiff then
        y0 -> r;
        (y1 - y0)/xdiff -> incr;
        for k from round(x0) by intof(sign(x1-x0)) to round(x1) do
            proc(k, round(r));
            r + incr -> r
        endfor
    else
        x0 -> r;
        (x1 - x0)/ydiff -> incr;
        for k from round(y0) by intof(sign(y1-y0)) to round(y1) do
            proc(round(r), k);
            r + incr -> r
        endfor
    endif
enddefine;
