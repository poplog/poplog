/* --- Copyright University of Sussex 1999. All rights reserved. ----------
 > File:            $popvision/lib/apppolygon.p
 > Purpose:         Apply a procedure to every point in a polygonal region
 > Author:          David S Young, Apr  5 1998 (see revisions)
 > Documentation:   HELP APPPOLYGON
 */

compile_mode:pop11 +strict;

section;

;;; Record class for a line - low and high y points, current x value,
;;; x_increment for a unit y increase. Also x2 just to deal with
;;; points on top boundary.

defclass lconstant Line {L_y1, L_y2, L_x, L_xincr, L_x2};

define lconstant ceil(n1) -> n2; ;;; standard ceiling function
    intof(n1) -> n2;
    if n1 > 0 and n1 /= n2 then
        n2 fi_+ 1 -> n2
    endif
enddefine;

define lconstant coords_to_line(x1, y1, x2, y2) /* -> line */;
    ;;; Converts two coord pairs to line record, with x initialised
    ;;; for the first integer y value greater than y1
    if y2 < y1 then
        (x1, y1, x2, y2) -> (x2, y2, x1, y1)    ;;; low point first
    endif;
    lvars x, xincr;
    if y1 = y2 then         ;;; horizontal line
        x1 -> x;
        false -> xincr
    else                    ;;; other line
        (x2 - x1) / (y2 - y1) -> xincr;
        x1 + (ceil(y1) - y1) * xincr -> x
    endif;
    consLine(y1, y2, x, xincr, x2)
enddefine;

define lconstant mergex(xs1, xs2) /* -> xs */;
    ;;; xs1 specifies parts of a raster to process, as alternating
    ;;; on and off points. So does xs2. This procedure generates their union.
    ;;; This is really only needed to fill in points that are on an upper
    ;;; edge of the boundary, but it also avoids repeating points when
    ;;; parts of a region meet exactly on integer coordinates.
    lvars on0 = false, on1 = false, on2 = false, x;
    [% until xs1 == [] and xs2 == [] do
            ;;; Make xs1 the next to consider
            if xs1 == [] or (xs2 /== [] and hd(xs1) > hd(xs2)) then
                (xs1, on1,  xs2, on2) -> (xs2, on2,  xs1, on1)
            endif;
            ;;; make transition for xs1
            dest(xs1) -> (x, xs1);
            not(on1) -> on1;
            ;;; if transition affects main state then record it;
            ;;; if this and the previous transition cancel out
            ;;; (i.e. off and on) delete previous one
            if (not(on0) and on1) or (on0 and not(on1) and not(on2)) then
                on1 -> on0;
                ;;; dup relies on popstackmark on first iteration
                if on0 and dup() = x then ;;; omit off-on pair
                    erase()
                else
                    x      ;;; on stack
                endif
            endif
        enduntil %] /* -> xs */
enddefine;

define apppolygon(n, proc);
    ;;; Applies proc to each pixel enclosed by the polygon.
    lvars procedure proc;

    ;;; Convert coordinates on the stack into line representations
    lvars lines = [];
    subscr_stack(2*n); subscr_stack(2*n);   ;;; complete circuit
    repeat n times
        coords_to_line(subscr_stack(4), subscr_stack(4)) :: lines -> lines;
    endrepeat;
    erase(); erase();

    ;;; sort into order of increasing low y
    syssort(lines, false,
        procedure(l1, l2); l1.L_y1 < l2.L_y1 endprocedure) -> lines;

    lvars x, x1, x2, xs, extra_xs, line, act_lines,
        y = ceil((hd(lines)).L_y1),
        pending = lines;    ;;; pending is unconsidered lines

    until lines == [] do    ;;; loop over rasters

        ;;; transfer lines to the active set (= lines - pending)
        until pending == [] or (hd(pending)).L_y1 > y do
            tl(pending) -> pending
        enduntil;

        lines -> act_lines;
        [] -> extra_xs;
        [% until act_lines == pending do      ;;; loop over active lines
                dest(act_lines) -> (line, act_lines);

                if line.L_y2 <= y then  ;;; remove finished line
                    delete(line, lines, nonop ==, 1) -> lines;

                    ;;; next part is so that points on the upper boundary do
                    ;;; not get omitted
                    if line.L_y2 = y then   ;;; ends exactly on the raster
                        if line.L_xincr then  ;;; it is not horizontal
                            conspair(conspair(dup(line.L_x2), extra_xs))
                                -> extra_xs;        ;;; maybe point
                        else                    ;;; it is horizontal
                            conspair(line.L_x, conspair(line.L_x2, extra_xs))
                                -> extra_xs     ;;; maybe plateau
                        endif
                    endif

                else  ;;; update x, leave old x (intersection point) on stack
                    dup(line.L_x) + line.L_xincr -> line.L_x
                endif
            enduntil %] -> xs;

        ;;; sort out intersections with the raster line
        syssort(xs, false, nonop <) -> xs;  ;;; increasing order of x
        syssort(extra_xs, false, nonop <) -> extra_xs;
        mergex(xs, extra_xs) -> xs;

        ;;; scan the raster
        until xs == [] do
            dest(dest(xs)) -> (x1, x2, xs);
            for x from ceil(x1) to x2 do proc(x, y) endfor
        enduntil;

        ;;; next raster
        y + 1 -> y
    enduntil
enddefine;

endsection;


/* ----------------------------------------------------------------------

Test examples, particularly to check handling of extreme integer y points.

These need popvision, though apppolygon itself is independent of the rest
of popvision. Load the procedures and libraries below and then load each call
to "test" separately. Correct functioning should be obvious.

Click on the graphics window to remove it after use.

-----------

uses popvision
uses apppolygon
uses rci_show
uses rc_graphplot
uses rc_filledcircle

false -> rc_window;

define setup;
    rci_show([1 300 1 300], rc_window) -> rc_window;
    [0 10 0 10] -> rcg_usr_reg;
    10 -> rcg_mk_no;
    false -> rcg_tk_no;
    'black' -> rc_window("foreground");
    rc_graphplot([], nullstring, [], nullstring) -> ;
    lvars index;
    for index in_region [1 10 1 10] do
        rc_filledcircle(explode(index), 0.1)
    endfor
enddefine;

define test(n);
    define lconstant plot(x, y); rc_filledcircle(x, y, 0.2) enddefine;
    setup();
    lvars index = 2*n;
    rc_jumpto(subscr_stack(index), subscr_stack(index));
    for index from 2 by 2 to 2*n do
        rc_drawto(subscr_stack(index), subscr_stack(index))
    endfor;
    'red' -> rc_window("foreground");
    apppolygon(n, plot)
enddefine;

test(2,2, 2,4, 4,4, 4,2,  4);       ;;; should be 3x3 square

test(1,2, 7,2, 4,5,  3);            ;;; should be triangle - not truncated

;;; Upper boundaries of next lot should be marked
test(1,1, 3,1, 4,4, 7,4, 8,1, 10,5, 8,10, 6,6, 3,6, 3,9, 1,9,  11);
test(1,1, 3,1, 4,4, 7,4, 8,1, 5,5, 8,9, 6,6, 3,6, 3,9, 1,9,  11);

test(2,2, 3,2, 4,9, 5,2, 9,2, 9,9, 8,9, 7,2, 6,9, 2,9,  10);

*/

/* --- Revision History ---------------------------------------------------
--- David Young, Aug 17 1999
        Simplified the procedure structure - no functional change.
--- David S Young, Apr  6 1998
        Minor tidying.
 */
