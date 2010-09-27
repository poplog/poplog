/* --- Copyright University of Sussex 2000. All rights reserved. ----------
 > File:            $popvision/lib/logsample.p
 > Purpose:         Logarithmic resampling of image arrays
 > Author:          David S Young, Jul 28 1994 (see revisions)
 > Documentation:   HELP * LOGSAMPLE
 > Related Files:   LIB * LOGSAMPLE.C and as in "uses" statements
 */

/* Logarithmic resampling of images

Version for single precision float or byte inputs, single precision
float outputs for CSI -> LSI.    LSI -> CSI just sp float.
*/

compile_mode:pop11 +strict;

section;

/* General libraries */

uses popvision
uses objectfile
uses ext2d_args
uses boundslist_utils
uses newsfloatarray
uses newbytearray
uses pop_radians

/* Load external procedures */

lconstant macro extname = 'logsample',
    obfile = objectfile(extname);

unless obfile then
    mishap(0, 'Cannot find object file')
endunless;

exload extname [^obfile]
    resamp_gb(xsize, ysize, arrin, offin, xdimin,
             nr, nw, arrout, offout, xdimout,
             rmin<SF>, rmax<SF>, xc<SF>, yc<SF>,
             ratp<SF>, ratn<SF>, minsig<SF>, sigwin<SF>,
             costab, sintab),
    resamp_nb(xsize, ysize, arrin, offin, xdimin,
             nr,    nw,    arrout, offout, xdimout,
             rmin<SF>, rmax<SF>, xc<SF>, yc<SF>, sigwin<SF>,
             costab, sintab),
    resamp_sb(xsize, ysize, arrin, offin, xdimin,
             nr,    nw,    arrout, offout, xdimout,
             rmin<SF>, rmax<SF>, xc<SF>, yc<SF>, sigwin<SF>,
             costab, sintab),
    resamp_gf(xsize, ysize, arrin, offin, xdimin,
             nr, nw, arrout, offout, xdimout,
             rmin<SF>, rmax<SF>, xc<SF>, yc<SF>,
             ratp<SF>, ratn<SF>, minsig<SF>, sigwin<SF>,
             costab, sintab),
    resamp_nf(xsize, ysize, arrin, offin, xdimin,
             nr,    nw,    arrout, offout, xdimout,
             rmin<SF>, rmax<SF>, xc<SF>, yc<SF>, sigwin<SF>,
             costab, sintab),
    resamp_sf(xsize, ysize, arrin, offin, xdimin,
             nr,    nw,    arrout, offout, xdimout,
             rmin<SF>, rmax<SF>, xc<SF>, yc<SF>, sigwin<SF>,
             costab, sintab),
    desamp(nr,    nw,    arrin,  offin,  xdimin,
           xsize, ysize, arrout, offout, xdimout,
           rmin<SF>, rmax<SF>, xc<SF>, yc<SF>)
endexload;

/* Utility to avoid calculating cos and sin in loop */

define /*lconstant*/ cos_sin_table(nw) -> (ctable, stable);
    ;;; Return cosine and sine values for a complete circle with
    ;;; nw wedges.  Saves up answers so efficient on later calls.
    lvars nw, ctable, stable;
    lconstant
        ctables = newproperty([], 10, false, "perm"),
        stables = newproperty([], 10, false, "perm");
    unless (ctables(nw) ->> ctable) and (stables(nw) ->> stable) then
        newsfloatarray([0 ^(nw-1)]) ->> ctables(nw) -> ctable;
        newsfloatarray([0 ^(nw-1)]) ->> stables(nw) -> stable;
        lconstant twopi = 2 * pi;
        dlocal pop_radians = true;
        lvars ctab, stab,
            c = 1.0,
            s = 0.0,
            cinc = cos(twopi/nw),
            sinc = sin(twopi/nw);
        for ctab, stab in_array ctable, stable updating_last 2 do
            c -> ctab;      s -> stab;          ;;; current values
            ctab * cinc - stab * sinc -> c;
            ctab * sinc + stab * cinc -> s
        endfor
    endunless
enddefine;

/* The main procedure. Basically an interface to the C procedures */

define logsample(array, rmin,rmax, xc,yc, winwid, opt, nr,nw, result)
        -> result;
    ;;; Returns a log-sampled version of array.
    ;;; rmin and rmax are the inner and outer
    ;;; radii of the sampling pattern, xc and yc are the coordinates
    ;;; in the input array at which the pattern is to be sampled,
    ;;; winwid is the width of the Gaussian function with which to
    ;;; window the input. winwid specifies the width relative to rmax;
    ;;; 0.5 is a good value; if winwid is false there is no windowing.
    ;;; Opt may be the word "nearest", for taking the nearest point,
    ;;; "smooth" for taking linear interpolation/averaging as appropriate,
    ;;; or "gaussian" for Gaussian interpolation with a sigma equal to
    ;;; the sampling radius.
    ;;; For more control over Gaussian interpolation, a list may be
    ;;; given with "gaussian" as its head and the value of sigma divided
    ;;; by the sample radius as its second element. For a difference of
    ;;; Gaussians, the second element should specify sigma for the positive
    ;;; part and the third element sigma for the negative part.
    ;;; nr and nw are the numbers of rings and wedges in the result.
    ;;; result is an array in which to store the result or false
    ;;; to create a new array, which will have bounds [0 nr-1 0 nw-1],
    ;;; or a list to create a new array of specified bounds.

    lvars array rmin rmax xc yc winwid opt nr nw result;
    lvars ratp = 1.0s0, ratn = -1.0s0;

    lconstant
        tofloat = number_coerce(% 0.0s0 %),
        minsig = 0.5s0;     ;;; fixed minimum sigma for Gaussians

    ;;; Fix the arguments - first the arrays
    checkinteger(nr, 1, false);
    checkinteger(nw, 1, false);
    lvars bres,
        b = [0 ^(nr-1) 0 ^(nw-1)],
        barr = boundslist(array),
        (x0, , y0, ) = explode(barr);
    if islist(result) then
        result -> bres;
        newsfloatarray(bres) -> result;
        region_inclusion_check(bres, b)
    elseif isarray(result) then
        boundslist(result) -> bres;
        region_inclusion_check(bres, b)
    else
        b -> bres;
        newsfloatarray(bres) -> result
    endif;

    ;;; Check the array types
    lvars bytein = array.isbytearray;
    unless bytein or array.issfloatarray then
        mishap(array, 1, 'Byte or single precision float array needed')
    endunless;
    unless result.issfloatarray then
        mishap(result, 1, 'Single precision float array needed')
    endunless;

    ;;; Now the numerical ones to the right form, noting that
    ;;; xc and yc have to be relative to the top left pixel for
    ;;; the external procedure.
    tofloat(rmax) -> rmax; tofloat(rmin) -> rmin;
    tofloat(xc-x0) -> xc; tofloat(yc-y0) -> yc;
    tofloat(if winwid then rmax * winwid else -1.0 endif) -> winwid;

    ;;; And the option - if Gaussian get widths
    if opt.islist then
        dest(opt) -> (opt, ratp);
        if ratp == [] then
            1.0s0 -> ratp
        else
            dest(ratp) -> (ratp, ratn);
            tofloat(ratp) -> ratp;
            if ratn == [] then
                tofloat(-1.0) -> ratn
            else
                tofloat(hd(ratn)) -> ratn
            endif
        endif
    endif;

    ;;; Get cosine and sine tables
    lvars (costab, sintab) = cos_sin_table(nw);

    ;;; Set up arguments for ext procedure
    (explode(ext2d_args([^array], barr)),
        explode(ext2d_args([^result], b)),
        rmin, rmax, xc, yc,
        if opt == "gaussian" then ratp, ratn, minsig endif,
        winwid, arrayvector(costab), arrayvector(sintab));

    ;;; Call external procedure
    if opt == "nearest" then    ;;; nearest point
        if bytein then
            exacc resamp_nb()
        else
            exacc resamp_nf()
        endif
    elseif opt == "smooth" then     ;;; interpolate/average
        if bytein then
            exacc resamp_sb()
        else
            exacc resamp_sf()
        endif
    elseif opt == "gaussian" then   ;;; Gaussian interpolation
        if bytein then
            exacc resamp_gb()
        else
            exacc resamp_gf()
        endif
    else
        mishap(opt, 1, 'Unrecognised option')
    endif

enddefine;

/* The reverse procedure. Note far fewer options */

define logsampback(logarr, nr, nw, rmin, rmax, xc, yc, result) -> result;
    ;;; Reverses logsample as far as possible, using linear
    ;;; interpolation. rmin is radius of ring 0, rmax of ring nr-1,
    ;;; regardless of bounds of logarr.
    lconstant tofloat = number_coerce(% 0.0s0 %);
    lvars logarr nr nw rmin rmax xc yc result;
    unless isarray(result) then
        newsfloatarray(result) -> result
    endunless;
    lvars
        nrm1 = nr - 1,   nwm1 = nw - 1,
        b = region_intersect(logarr, [0 ^nrm1 0 ^nwm1]),
        (r0, r1, w0, w1) = explode(b),
        (x0, , y0, ) = explode(boundslist(result));

    ;;; Check all wedges present, deal with missing rings
    unless w0 == 0 and w1 == nwm1 then
        mishap(logarr, 1, 'Wedges missing from log-sampled array')
    endunless;
    if r0 > 0 or r1 < nrm1 then
        ;;; Missing rings. It is correct to just fix rmin & rmax - strictly
        ;;; both b and the boundslist of the array should be changed
        ;;; as rmin is supposed to refer to ring 0, but because
        ;;; of the way the call to desamp is made, it is OK to leave
        ;;; them both alone.
        rmin * (rmax/rmin) ** (tofloat(r0)/nrm1),
        rmin * (rmax/rmin) ** (tofloat(r1)/nrm1) -> (rmin, rmax)
    endif;

    tofloat(rmin) -> rmin; tofloat(rmax) -> rmax;
    tofloat(xc-x0) -> xc; tofloat(yc-y0) -> yc;
    ;;; Call external fortran procedure
    exacc desamp(
        explode(ext2d_args([^logarr], b)),
        explode(ext2d_args([^result], boundslist(result))),
        rmin, rmax, xc, yc)
enddefine;

/* Procedures to convert between conventional and log coordinates.
Closures of contolog and logtocon can be made corresponding to a given
call of logsample so that corresponding positions in the two arrays
can be found. */

define contorth(x, y, xc, yc) -> (rho, theta);
    ;;; Converts conventional (Cartesian) to polar coordinates.
    lvars x y xc yc rho theta;
    x - xc -> x; y - yc -> y;
    sqrt(x*x + y*y) -> rho;
    arctan2(x,y) -> theta   ;;; POP has opposite order to Fortran/C atan2!
enddefine;

define rthtocon(rho, theta, xc, yc) -> (x, y);
    ;;; Reverses contorth
    lvars x y xc yc rho theta;
    xc + rho*cos(theta) -> x;
    yc + rho*sin(theta) -> y
enddefine;

define logtorth(r, w, rmin, rmax, nr, nw) -> (rho, theta);
    ;;; Converts ring and wedge coordinates in a log-sampled array to
    ;;; r and theta. Assumes ring 0 is at radius rmin.
    ;;; Theta is returned in radians or degrees depending on pop_radians.
    lvars r w rmin rmax nr nw rho theta;
    rmin * (rmax/rmin) ** (r/(nr-1)) -> rho;
    pop_circle * w / nw -> theta
enddefine;

define rthtolog(rho, theta, rmin, rmax, nr, nw) -> (r, w);
    ;;; Reverses logtorth.
    lvars r w rmin rmax nr nw rho theta;
    (nr-1) * log(rho/rmin) / log(rmax/rmin) -> r;
    mod(theta * nw / pop_circle, nw) -> w;
enddefine;

define contolog(x, y, rmin, rmax, xc, yc, nr, nw) /* -> (r, w) */;
    ;;; Converts x and y coordinates in a conventional image to
    ;;; coordinates in a log-sampled image. xc and yc are the
    ;;; centre of interest coords in the conventional image,
    ;;; nr and nw are the dimensions of the log-sampled
    ;;; image which correspond to the two-pi points.
    lvars x y xc yc rmin rmax nr nw;
    rthtolog(contorth(x, y, xc, yc), rmin, rmax, nr, nw)
enddefine;

define logtocon(r, w, rmin, rmax, xc, yc, nr, nw) /* -> (x, y) */;
    lvars xc yc rmin rmax nr nw r w;
    rthtocon(logtorth(r, w, rmin, rmax, nr, nw), xc, yc)
enddefine;

define expansion(rshift, rmin, rmax, nr) /* -> e */;
    ;;; Returns the expansion factor corresponding to an r-shift in
    ;;; a log sampled image
    lvars rshift rmin rmax nr e;
    (rmax/rmin) ** (rshift/(nr-1)) /* -> e */
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David Young, Apr  3 2000
        Changed from popradians to pop_radians.
--- David Young, Mar  2 2000
        Moved from Sussex local vision libraries to popvision.
--- David S Young, Oct  2 1995
        logsampback now allows missing rings in its input
--- David S Young, Nov 16 1994
        Now accepts byte arrays as input.
 */
