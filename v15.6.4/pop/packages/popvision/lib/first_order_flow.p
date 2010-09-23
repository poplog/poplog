/* --- Copyright University of Sussex 1994. All rights reserved. ----------
 > File:            $popvision/lib/first_order_flow.p
 > Purpose:         Calculates first-order flow vectors given parameters
 > Author:          David S Young, Apr  8 1994
 > Documentation:   HELP * FIRST_ORDER_FLOW
 */

compile_mode:pop11 +strict;

section;

define first_order_flow(x, y, xc, yc, D, R, S, Theta) -> (vx, vy);
    ;;; Returns the differential optic flow at a point (x, y) relative
    ;;; to the fixed point. D is the rate of dilation, R is the rate of
    ;;; rotation, S is the shear rate, and Theta is the angle of
    ;;; shear expansion to the x-axis.
    lvars x, y, xc, yc, D, R, S, Theta, vx, vy;
    lvars c, s;
    if Theta.isreal then
        cos(Theta) -> c; sin(Theta) -> s
    else
        explode(Theta) -> (c, s)
    endif;
    ;;; Shift relative to fixed point
    x - xc -> x;
    y - yc -> y;
    ;;; Rotate into shear axes
    lvars p, q;
    x * c + y * s -> p;
    y * c - x * s -> q;
    ;;; Get the flow in these axes
    lvars vp, vq;
    p * (D + S) - q * R -> vp;
    q * (D - S) + p * R -> vq;
    ;;; Rotate back again
    vp * c - vq * s -> vx;
    vq * c + vp * s -> vy;
enddefine;

endsection;
