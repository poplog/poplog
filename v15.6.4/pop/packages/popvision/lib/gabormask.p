/* --- Copyright University of Sussex 2000. All rights reserved. ----------
 > File:            $popvision/lib/gabormask.p
 > Purpose:         Generate arrays containing sampled Gabor functions
 > Author:          David S Young, Jun 17 1995 (see revisions)
 > Documentation:   HELP * GABORMASK
 > Related Files:   See "uses" list
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses newsfloatarray
uses pop_radians

vars gabormask_limit_ratio = 2.575;         ;;; < 1% in the Gaussian

define gabormask_limit(sigma) /* -> size */;
    lvars sigma;
    round(sigma * gabormask_limit_ratio) /* -> size */
enddefine;

define gabormask1(sigma, period) -> (cmask, smask);
    lvars sigma, period, cmask, smask;
    dlocal pop_radians = true;
    lvars i, g, a,
        limit = gabormask_limit(sigma),
        k = -1.0 / (2.0 * sigma * sigma),
        omega = #_< 2*pi >_# / period,
        c = 1.0,
        s = 0.0,
        cinc = cos(omega),
        sinc = sin(omega),
        cnorm = 0,
        snorm = 0;

    newsfloatarray([%-limit, limit%]) -> cmask;
    newsfloatarray([%-limit, limit%]) -> smask;
    1.0 -> cmask(0);
    0.0 -> smask(0);
    fast_for i from 1 to limit do
        (c * cinc - s * sinc,  s * cinc + c * sinc) -> (c, s);
        exp(k * i * i) -> g;
        c * g ->> a ->> cmask(i) -> cmask(-i);
        c * a + cnorm -> cnorm;
        s * g ->> a ->> smask(i); .negate -> smask(-i);
        s * a + snorm -> snorm
    endfor;

    2 * cnorm + 1 -> cnorm;
    2 * snorm -> snorm;
    ;;; normalise so that convolution with a harmonic curve of the right
    ;;; frequency gives unity peaks
    for c, s, c, s in_array cmask, smask, cmask, smask updating_last 2 do
        c/cnorm -> c;
        s/snorm -> s
    endfor
enddefine;

define gabormask2(sigma, period, orient) -> (cmask, smask);
    lvars sigma, period, orient, cmask, smask;
    dlocal pop_radians;
    ;;; Get cos and sine of orientation with current popradians, and
    ;;; adjust to give correct phase when multiplied
    lvars
        omega = #_< 2*pi >_# / period,
        cs = omega * cos(orient),
        sn = omega * sin(orient);
    true -> pop_radians;
    lvars
        i, x, y, xp, cx, sx, g, h, c, s,
        k = -1.0 / (2.0 * sigma * sigma),
        limit = gabormask_limit(sigma),
        snorm = 0,
        cnorm = 0;

    newsfloatarray([% -limit, limit, -limit, limit %]) -> cmask;
    newsfloatarray([% -limit, limit, -limit, limit %]) -> smask;

    for c, s with_index i in_array cmask, smask updating_last 2 do
        explode(i) -> (x, y);
        ;;; Gaussian envelope
        exp(k * (x*x + y*y)) -> g;
        ;;; rotate and get phase
        x * cs + y * sn -> xp;
        ;;; set mask values
        cos(xp) -> cx;
        g * cx -> c;
        c * cx + cnorm -> cnorm;
        sin(xp) -> sx;
        g * sx -> s;
        s * sx + snorm -> snorm;
    endfor;

    ;;; normalise so that convolution with a harmonic curve of the right
    ;;; frequency gives unity peaks
    for c, s, c, s in_array cmask, smask, cmask, smask updating_last 2 do
        c/cnorm -> c;
        s/snorm -> s
    endfor
enddefine;

vars gabormask = true;

endsection;

/* --- Revision History ---------------------------------------------------
--- David Young, Apr  3 2000
        Changed popradians to pop_radians for consistency.
 */
