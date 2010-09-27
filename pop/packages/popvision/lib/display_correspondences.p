/* --- Copyright University of Sussex 1996. All rights reserved. ----------
 > File:            $popvision/lib/display_correspondences.p
 > Purpose:         Show stereo correspondences
 > Author:          David S Young, Mar  5 1996 (see revisions)
 > Documentation:   HELP * SHOW_CORRESPONDENCES
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses rci_show
uses rc_filledcircle

vars display_correspondences_marksize;

define lconstant dc_filledcircle(x, y);
    lvars x, y;
    rc_filledcircle(x, y, display_correspondences_marksize)
enddefine;

define lconstant dc_circle(x, y);
    lvars x, y;
    lconstant circle = 64 * 360;
    lvars xdir = sign(rc_xscale), ydir = sign(rc_yscale);
    rc_draw_arc(
        x - xdir * display_correspondences_marksize,
        y - ydir * display_correspondences_marksize,
        dup(2 * display_correspondences_marksize), 0, circle)
enddefine;

define lconstant dc_square(x, y);
    lvars x, y;
    rc_jumpto(x-display_correspondences_marksize, y-display_correspondences_marksize);
    rc_drawto(x+display_correspondences_marksize, y-display_correspondences_marksize);
    rc_drawto(x+display_correspondences_marksize, y+display_correspondences_marksize);
    rc_drawto(x-display_correspondences_marksize, y+display_correspondences_marksize);
    rc_drawto(x-display_correspondences_marksize, y-display_correspondences_marksize);
enddefine;

define lconstant dc_cross(x, y);
    lvars x, y;
    dlocal rc_linewidth = 2;
    rc_jumpto(x - display_correspondences_marksize,     y);
    rc_drawto(x + display_correspondences_marksize,     y);
    rc_jumpto(x,     y + display_correspondences_marksize);
    rc_drawto(x,     y - display_correspondences_marksize);
enddefine;

vars                ;;;; user-definable variables
    display_correspondences_marksize = 3,
    display_correspondences_colours
        = ['red' 'yellow' 'green' 'blue' 'cyan' 'magenta'],
    display_correspondences_drawers
        = [% dc_filledcircle, dc_circle, dc_square, dc_cross %];

define display_correspondences(im1, im2, region, corresps, win) -> win;
    ;;; Displays im1 and im2 beside one another and marks corresponding
    ;;; points with features of different shape and colour.
    ;;; If region is non-false, it specifies the part of the image
    ;;; to display.
    lvars im1, im2, region, corresps, win;
    dlocal rc_window, rc_xorigin, rc_yorigin, rc_xscale, rc_yscale;
    unless boundslist(im1) = boundslist(im2) then
        mishap(im1, im2, 2, 'Different size arrays')
    endunless;
    unless region then
        boundslist(im1) -> region
    endunless;
    ;;; Calculate the area of rc coordinates for both images
    lvars (x0, x1, y0, y1) = explode(region),
        xsize = x1 - x0 + 1,
        doublesize = conslist( #| x0, x1+xsize, y0, y1 |#);

    ;;; Make a window if necessary, and set the current coordinates
    unless win.xt_islivewindow then
        rci_show(doublesize) ->> win -> rc_window
    else
        win -> rc_window
    endunless;
    rci_show_setcoords(doublesize); ;;; set the coordinate system

    ;;; Display the images. The second one is shifted right
    rc_array(im1, region, false, false, false);
    lvars tmp = rc_xorigin;
    rc_xorigin + xsize * rc_xscale -> rc_xorigin;
    rc_array(im2, region, false, false, false);
    tmp -> rc_xorigin;

    ;;; Order the matches according to position on the y-coordinate
    define lconstant orderby_y(m1, m2); lvars m1, m2;
        m1(2) < m2(2)
    enddefine;
    syssort(corresps, orderby_y) -> corresps;

    ;;; Plot the correspondences. The rc coordinate system looks
    ;;; after any effects due to rci_show_scale. Cycle through the
    ;;; drawing procedures, and then through the colours.
    lvars corr, col, draw;
    repeat
        for draw in display_correspondences_drawers do
            for col in display_correspondences_colours do
                dest(corresps) -> (corr, corresps);
                lvars (xl, yl, xr, yr) = explode(corr);
                col -> rc_window("foreground");
                if xl >= x0 and xl <= x1 and yl >= y0 and yl <= y1 then
                    draw(xl, yl)
                endif;
                if xr >= x0 and xr <= x1 and yr >= y0 and yr <= y1 then
                    draw(xr + xsize, yr)
                endif;
            quitif(corresps == [])(3)       ;;; finished
            endfor
        endfor
    endrepeat
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David S Young, Mar  7 1996
        Declared arguments as lvars to avoid warnings in pre-V.15 Poplog
--- David S Young, Mar  6 1996
        Introduced display_correspondences_marksize, _colours, _drawers
 */
