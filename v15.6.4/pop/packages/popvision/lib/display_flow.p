/* --- Copyright University of Sussex 2000. All rights reserved. ----------
 > File:            $popvision/lib/display_flow.p
 > Purpose:         Display of flow-vectors
 > Author:          David S Young, Apr  8 1994 (see revisions)
 > Documentation:   HELP * DISPLAY_FLOW
 > Related Files:   LIB * RCI_SHOW, LIB * RC_GRAPHIC
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses rci_show
uses rc_filledcircle
uses first_order_flow

define display_flow(u, v, scale, skip, win) -> win;
    lvars u, v, scale, skip, win;
    dlocal rc_window, rc_xorigin, rc_yorigin, rc_xscale, rc_yscale;
    rci_show(boundslist(u), win) ->> win -> rc_window;
    rci_show_setcoords(u);
    lvars x, y,
        (x0, x1, y0, y1) = explode(boundslist(u)),
        xgo = x0 + ((x1 - x0) mod skip) div 2,
        ygo = y0 + ((y1 - y0) mod skip) div 2;
    for y from ygo by skip to y1 do
        for x from xgo by skip to x1 do
            rc_filledcircle(x, y, 1);
            rc_jumpto(x, y);
            rc_drawto(x + scale * u(x, y), y + scale * v(x, y))
        endfor
    endfor
enddefine;

define display_flowproc(proc, bounds, scale, skip, win) -> win;
    lvars procedure proc, bounds, scale, skip, win;
    dlocal rc_window, rc_xorigin, rc_yorigin, rc_xscale, rc_yscale;
    rci_show(bounds, win) ->> win -> rc_window;
    if bounds.isarray then boundslist(bounds) -> bounds endif;
    rci_show_setcoords(bounds);
    lvars x, y, u, v,
        (x0, x1, y0, y1) = explode(bounds),
        xgo = x0 + ((x1 - x0) mod skip) div 2,
        ygo = y0 + ((y1 - y0) mod skip) div 2;
    for y from ygo by skip to y1 do
        for x from xgo by skip to x1 do
            rc_filledcircle(x, y, 1);
            rc_jumpto(x, y);
            proc(x, y) -> (u, v);
            rc_drawto(x + scale * u, y + scale * v)
        endfor
    endfor
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David Young, Mar 20 2000
        display_flowproc now allows background image to be given
 */
