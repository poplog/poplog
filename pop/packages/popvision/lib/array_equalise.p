/* --- Copyright University of Sussex 1994. All rights reserved. ----------
 > File:            $popvision/lib/array_equalise.p
 > Purpose:         Histogram equalisation of arrays
 > Author:          David S Young, Feb 20 1994
 > Documentation:   HELP * ARRAY_EQUALISE
 > Related Files:   See uses lines below
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses array_mxmn
uses array_hist
uses arraylookup
uses boundslist_utils

define array_equalise(arrin, region, outvals, arrout) /* -> arrout */;
    lvars arrin, region, outvals, arrout;
    ;;; Outvals can be an integer: outputs are 0 to outvals - 1
    ;;; A list of two integers: outputs are from one to the other
    ;;; A vector of values: outputs are mapped onto these

    ;;; The next constant defines how accurate the process is - we
    ;;; assume that 256 bins will give adequate resolution.
    lconstant nbins = 256;

    ;;; Sort out arguments
    lvars ival, outvec;
    if outvals.isinteger then
        {% for ival from 0 to outvals-1 do ival endfor %} -> outvec
    elseif outvals.islist then
        {% for ival from hd(outvec) to hd(tl(outvec)) do ival endfor %}
            -> outvec;
    elseif outvals.isvector then
        ;;; OK
    else
        mishap(outvals, 1, 'Unrecognised form for equalisation outputs')
    endif;
    unless region then
        boundslist(arrin) -> region
    endunless;

    ;;; Get histogram, distinguishing byte arrays from other arrays
    lvars low, high, isbyte = false;
    if class_spec(datakey(arrayvector(arrin))) == 8 then
        ;;; its a byte array, so get the exact histogram
        0 -> low;
        256 -> high;
        true -> isbyte
    else
        array_mxmn(arrin, region) -> (high, low);
        if low.isintegral and high.isintegral then
            high + 1 -> high
        elseif high - low >= 2 then
            ;;; assume we want to count integral values
            low - 0.5 -> low;
            high + 0.5 -> high
        endif
    endif;
    lvars ndone, hist, nabv;
    array_hist(arrin, region, low, nbins, high) -> (ndone, hist, nabv);

    ;;; Convert histogram to quantisation table, using linear
    ;;; interpolation within bins to improve accuracy at little
    ;;; extra cost.
    lvars ithresh, thr,
        ihist = 1,                          ;;; input bin number
        nvals = length(outvec),
        thresh = initv(nvals - 1),
        val = low,                          ;;; lower threshold for input bin
        valinc = (high - low) / nbins,      ;;; input bin size
        nlast = ndone,                      ;;; number in current input bin
        ntotal = region_size(region),
        nperbin = ntotal / nvals,           ;;; number per output bin
        ntarget = nperbin;                  ;;; no to have done in output
    for ithresh from 1 to nvals - 1 do
        until ndone >= ntarget do
            if ihist > nbins then
                ;;; only come here if high - low < 2 and rounding errors!
                nabv -> nlast       ;;; must reach total now
            else
                hist(ihist) -> nlast;
                ihist + 1 -> ihist
            endif;
            ndone + nlast -> ndone;
            val + valinc -> val
        enduntil;
        val - valinc * (ndone - ntarget) / nlast -> thr;
        ;;; Round threshold for byte arrays
        if isbyte then round(thr) else thr endif -> thresh(ithresh);
        ntarget + nperbin -> ntarget
    endfor;

    ;;; Do transformation
    arraylookup(arrin, region, [% thresh, outvec %], arrout) /* -> arrout */
enddefine;

endsection;
