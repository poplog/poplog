/* --- Copyright University of Sussex 2002. All rights reserved. ----------
 > File:            $popvision/lib/snakes.p
 > Purpose:         Demonstration of active contours
 > Author:          David S Young, Feb 24 1995 (see revisions)
 > Documentation:   HELP * SNAKES
 > Related Files:   See "uses" list below
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses rc_graphic
uses rc_mouse
uses rci_show


defclass snake {snake_len, snake_x, snake_y};

define lconstant pr_circular_list(l); lvars l;
    lvars l1;
    cucharout(`[`);
    pr(destpair(l) -> l1);
    until l1 == l do
        cucharout(`\s`);
        pr(destpair(l1) -> l1)
    enduntil;
    cucharout(`]`)
enddefine;

define lconstant prsnake(snake); lvars snake;

    define dlocal pr(item); lvars item;
        if item.ispair then
            pr_circular_list(item)
        else
            syspr(item)
        endif
    enddefine;

    sys_syspr(snake)
enddefine;

prsnake -> class_print(snake_key);

define lconstant clist_=(l0, l1) /* -> bool */;
    lvars l0g = l0;
    repeat
        unless (destpair(l0) -> l0) = (destpair(l1) -> l1) then
            return(false)
        endunless;
    quitif (l0 == l0g) endrepeat;
    return(true)
enddefine;

define lconstant snake_=(s0, s1) /* -> bool */;
    s0.snake_len == s1.snake_len
    and clist_=(s0.snake_x, s1.snake_x)
    and clist_=(s0.snake_y, s1.snake_y)
enddefine;

snake_= -> class_=(snake_key);


define coords_to_snake(/* crds */, n) /* -> snake */;
    ;;; Args are x1, y1, x2, y2, ... , xn, yn, n
    lvars x0, xlist, y0, ylist;
    checkinteger(n, 1, false);
    conspair(/* yn */, []) ->> y0 -> ylist;
    conspair(/* xn */, []) ->> x0 -> xlist;
    repeat n-1 times
        conspair(/* yi */, ylist) -> ylist;
        conspair(/* xi */, xlist) -> xlist;
    endrepeat;
    ;;; Make lists circular
    xlist -> back(x0);
    ylist -> back(y0);
    conssnake(n, xlist, ylist) /* -> snake */
enddefine;

define interp_snake(snake, newn, newstep) /* -> newsnake */;
    lvars x, y, xlast, ylast,
        steplen, steplens, len = 0,
        (n, xlist, ylist) = explode(snake);

    ;;; get the lengths of the steps of the current snake
    destpair(xlist) -> (x, xlist); destpair(ylist) -> (y, ylist);
    [%
        repeat n times
            (x, y) -> (xlast, ylast);
            destpair(xlist) -> (x, xlist); destpair(ylist) -> (y, ylist);
            sqrt((x - xlast) ** 2 + (y - ylast) ** 2) ->> steplen;      ;;; on stack
            steplen + len -> len
        endrepeat
    %] -> steplens;

    ;;; get the step size
    if newn then
        len / newn -> newstep
    else
        round(len / newstep) -> newn;
        len / newn -> newstep
    endif;

    ;;; go round again, interpolating along straight lines
    lvars frac1, frac2, stepused = 0;
    x, y;       ;;; first point on stack
    destpair(steplens) -> (steplen, steplens);
    (x, y) -> (xlast, ylast);
    destpair(xlist) -> (x, xlist); destpair(ylist) -> (y, ylist);
    repeat newn - 1 times
        stepused + newstep -> stepused;
        until stepused <= steplen do
            stepused - steplen -> stepused;
            destpair(steplens) -> (steplen, steplens);
            (x, y) -> (xlast, ylast);
            destpair(xlist) -> (x, xlist); destpair(ylist) -> (y, ylist)
        enduntil;
        stepused / steplen -> frac1;
        1 - frac1 -> frac2;
        frac1 * x + frac2 * xlast;      ;;; x on stack
        frac1 * y + frac2 * ylast       ;;; y on stack
    endrepeat;

    coords_to_snake(newn) /* -> newsnake */
enddefine;

vars snake_gamma;      ;;; used for communication with snake_emergency_imforce

define lconstant snake_params(snake) -> (snake, eta, alpha, beta, gamma);
    ;;; Get control parameters if supplied.
    0 ->> eta ->> alpha ->> beta -> gamma;
    if snake.isnumber then snake -> (snake, gamma) endif;
    if snake.isnumber then snake -> (snake, beta) endif;
    if snake.isnumber then snake -> (snake, alpha) endif;
    if snake.isnumber then snake -> (snake, eta) endif;
enddefine;

define adjust_snake(extforce) -> (newsnake, adj) with_nargs 5;
    lvars procedure extforce,
        (snake, eta, alpha, beta, gamma) = snake_params();
    0 -> adj;
    lvars
        xm2, xm1, x, xp1, xp2,   ym2, ym1, y, yp1, yp2,
        (n, xlist, ylist) = explode(snake);

    dlocal snake_gamma = gamma;       ;;; not nice - see snake_emergency_imforce

    ;;; Initialise coordinates for current location and 2 each side
    xlist, repeat 5 times destpair() endrepeat
        -> (xm2, xm1, x, xp1, xp2, xlist);
    ylist, repeat 5 times destpair() endrepeat
        -> (ym2, ym1, y, yp1, yp2, ylist);

    lvars xf, yf, xa, ya;
    repeat n times
        extforce(x, y) -> (xf, yf);        ;;; external force

        ;;; Add weighted internal forces and external force to get motion
        alpha * ((xm1 + xp1) - 2 * x)
        + beta * (4 * (xm1 + xp1) - 6 * x - (xm2 + xp2))
        + eta * (yp1 - ym1)
        + gamma * xf -> xa;
        alpha * ((ym1 + yp1) - 2 * y)
        + beta * (4 * (ym1 + yp1) - 6 * y - (ym2 + yp2))
        + eta * (xm1 - xp1)
        + gamma * yf -> ya;

        adj + (xa * xa) + (ya * ya) -> adj;  ;;; squared adjustment

        ;;; leave adjusted coordinates on stack
        (x + xa,     y + ya);

        ;;; shift one position round the snake
        (xm1, x, xp1, xp2, destpair(xlist)) -> (xm2, xm1, x, xp1, xp2, xlist);
        (ym1, y, yp1, yp2, destpair(ylist)) -> (ym2, ym1, y, yp1, yp2, ylist);
    endrepeat;

    coords_to_snake(n) -> newsnake;
    sqrt(adj / n) -> adj;               ;;; rms adjustment
enddefine;

define display_snake(snake, bounds, lcol, pcol, win) -> win;
    dlocal rc_window, rc_xorigin, rc_yorigin, rc_xscale, rc_yscale;
    if win.xt_islivewindow then
        win -> rc_window;
    else
        rci_show(bounds, win) ->> win -> rc_window
    endif;
    lvars winforeground = win("foreground");        ;;; save
    rci_show_setcoords(bounds);

    ;;; Draw lines between points
    lcol -> win("foreground");
    lvars x, y, (n, xlist, ylist) = explode(snake);
    destpair(xlist) -> (x, xlist);
    destpair(ylist) -> (y, ylist);
    rc_jumpto(x, y);
    repeat n times
        destpair(xlist) -> (x, xlist);
        destpair(ylist) -> (y, ylist);
        rc_drawto(x, y)
    endrepeat;

    ;;; Mark control points
    unless pcol = lcol then
        pcol -> win("foreground");
        repeat n times
            destpair(xlist) -> (x, xlist);
            destpair(ylist) -> (y, ylist);
            rci_drawpoint(x, y)
        endrepeat;
    endunless;

    winforeground -> win("foreground")      ;;; restore
enddefine;

define get_snake(im, n, stp, lcol, pcol, win) -> (snake, win);
    dlocal
        rc_mousing = true,    ;;; make sure window is safe
        rc_window, rc_xorigin, rc_yorigin, rc_xscale, rc_yscale;
    rci_show(im, win) ->> win -> rc_window;
    rci_show_setcoords(im);
    lvars winforeground = win("foreground");    ;;; save
    lcol -> win("foreground");
    lvars list = rc_mouse_draw(true, -3);   ;;; stop button must be negative
    coords_to_snake( #| applist(list, explode) |# div 2) -> snake;
    if n or stp then
        interp_snake(snake, n, stp) -> snake;
        rci_show(im, win) -> ;
    endif;
    display_snake(snake, im, lcol, pcol, win) -> ;
    winforeground -> win("foreground")      ;;; restore
enddefine;

define snake_nullforce(x, y) /* -> 0, 0 */; lvars x, y;
    0, 0
enddefine;

define lconstant snake_emergency_imforce(x0, x1, y0, y1, x, y, im)
        -> (xf, yf);
    ;;; Have gone outside the image. Return a force that brings us
    ;;; back. Needs to know gamma - communicates via a file local
    ;;; variable because this need was not anticipated when the
    ;;; interface to the procedures was set up.
    ;;; Assumes x and y integers.
    if x fi_<= x0 then
        (x0 fi_- x) / snake_gamma -> xf
    elseif x fi_>= x1 then
        (x1 fi_- x) / snake_gamma -> xf
    else
        0 -> xf
    endif;
    if y fi_<= y0 then
        (y0 fi_- y) / snake_gamma -> yf
    elseif y fi_>= y1 then
        (y1 fi_- y) / snake_gamma -> yf
    else
        0 -> yf
    endif;
enddefine;

define snake_imforce(x, y, im) -> (xf, yf);
    lvars (x0, x1, y0, y1) = explode(boundslist(im));
    round(x) -> x; round(y) -> y;
    if x fi_> x0 and x fi_< x1 and y fi_> y0 and y fi_< y1 then
        im(x fi_+ 1, y) - im(x fi_- 1, y) -> xf;
        im(x, y fi_+ 1) - im(x, y fi_- 1) -> yf;
    else
        snake_emergency_imforce(x0, x1, y0, y1, x, y, im) -> (xf, yf)
    endif
enddefine;

define evolve_snake(/* im, snake, alpha, beta, gamma, */ lcol, pcol,
        minadj, maxiter, bounds, win) -> snake;
    lvars (snake, eta, alpha, beta, gamma) = snake_params();
    lvars im = identfn();
    lvars adj, extforce, iter = 0;
    if im.isarray then
        snake_imforce(% im %)
    elseif im.isprocedure then
        im
    else
        snake_nullforce
    endif -> extforce;
    repeat
        iter + 1 -> iter;
        adjust_snake(snake, eta, alpha, beta, gamma, extforce) -> (snake, adj);
        if win then
            display_snake(snake, bounds, lcol, pcol, win) -> win;
        endif;
    quitif (adj < minadj or iter > maxiter) endrepeat;
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David Young, Feb  9 2002
        Added class_= procedure for snake class.
        Added expansion force and new optional argument eta to control it.
--- David Young, Mar 28 2001
        snake_emergency_imforce added so that snakes that go out of arrays
        do not cause mishaps. (Partly in response to bug in PC Poplog which
        causes system crash after invalid array subscript mishap, but
        this behaviour preferable anyway.)
--- David S Young, Feb 23 1999
        Fixed window bug in evolve_snake (local variable win was not updated
        on return from display_snake).
 */
