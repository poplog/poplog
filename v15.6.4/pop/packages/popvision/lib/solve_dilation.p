/* --- Copyright University of Sussex 1997. All rights reserved. ----------
 > File:            $popvision/lib/solve_dilation.p
 > Purpose:         Least-squares estimate dilating flow-field parameters
 > Author:          David S Young, Apr 11 1994 (see revisions)
 > Documentation:   HELP * SOLVE_DILATION
 */

compile_mode:pop11 +strict;

section;

define lconstant solve_dilation_arrays(U, V) -> (D, x0, y0);
    lvars U, V, D, x0, y0;
    ;;; Returns least-squares estimates of the flow parameters, assuming
    ;;; a simple dilational flow-field. D is dilation, x0 and y0 FoE
    lvars
        (x0, x1, y0, y1) = explode(boundslist(U)),
        xc = (x0 + x1) / 2.0,
        yc = (y0 + y1) / 2.0,
        x, y, u, v, xy, N = 0.0,
        sx = 0, sy = 0, sxx = 0, syy = 0, su = 0, sv = 0, sxu = 0, syv = 0;
    for u, v with_index xy in_array U, V do
        explode(xy) -> (x, y);
        x - xc -> x;        ;;; centre coords for better numerical stability
        y - yc -> y;
        sx + x      -> sx;              sy + y      -> sy;
        sxx + x*x   -> sxx;             syy + y*y   -> syy;
        su + u      -> su;              sv + v      -> sv;
        sxu + x*u   -> sxu;             syv + y*v   -> syv;
        N + 1.0 -> N;
    endfor;
    ((su*sx + sv*sy)/N - sxu - syv) / ((sx*sx +sy*sy)/N - sxx - syy) -> D;
    (sx - su/D)/N + xc -> x0;
    (sy - sv/D)/N + yc -> y0
enddefine;

define lconstant solve_dilation_list(UV) -> (D, x0, y0);
    lvars UV, D, x0, y0;
    ;;; Returns least-squares estimates of the flow parameters, assuming
    ;;; a simple dilational flow-field. D is dilation, x0 and y0 FoE.
    ;;; UV should be a list of vectors in form (x, y, u, v)
    lvars xyuv, xc, yc,
        x, y, u, v, xy, N = number_coerce(length(UV), 0.0s0),
        sx = 0, sy = 0, sxx = 0, syy = 0, su = 0, sv = 0, sxu = 0, syv = 0;
    for xyuv in UV do
        explode(xyuv) -> (x, y, , );
        sx + x -> sx;       sy + y -> sy;
    endfor;
    sx/N -> xc;         sy/N -> yc;
    0.0 -> sx;          0.0 -> sy;
    for xyuv in UV do
        explode(xyuv) -> (x, y, u, v);
        x - xc -> x;        ;;; centre coords for better numerical stability
        y - yc -> y;
        sx + x      -> sx;              sy + y      -> sy;
        sxx + x*x   -> sxx;             syy + y*y   -> syy;
        su + u      -> su;              sv + v      -> sv;
        sxu + x*u   -> sxu;             syv + y*v   -> syv;
    endfor;
    ((su*sx + sv*sy)/N - sxu - syv) / ((sx*sx +sy*sy)/N - sxx - syy) -> D;
    (sx - su/D)/N + xc -> x0;
    (sy - sv/D)/N + yc -> y0
enddefine;

define solve_dilation(UV) /* -> (D, x0, y0) */;
    if UV.islist then
        solve_dilation_list(UV)
    elseif UV.isarray then
        solve_dilation_arrays(/* U, */ UV)
    else
        mishap(UV, 1, 'List or array expected')
    endif
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David S Young, Feb 20 1997
        Changed to accept input in form of list of vectors as an alternative
        to arrays.
 */
