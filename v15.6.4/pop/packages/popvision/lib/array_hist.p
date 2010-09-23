/* --- Copyright University of Sussex 1994. All rights reserved. ----------
 > File:            $popvision/lib/array_hist.p
 > Purpose:         Obtain histograms of values in regions of arrays
 > Author:          David S Young, Jan 27 1994
 > Documentation:   HELP * ARRAY_HIST
 > Related Files:   LIB * ARRAY_HIST.C
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses objectfile
uses ext2d_args

lconstant macro extname = 'array_hist',
    obfile = objectfile(extname);

exload extname [^obfile]
        constant    array_hist_f(11),
                    array_hist_b(11)
endexload;

define lconstant check_vec_takes_ints(v);
    lvars v;
    lvars spec = v.datakey.class_spec;
    unless spec.isinteger or spec == "full" then
        mishap(spec, 1, 'Vector must accept integers')
    endunless
enddefine;

define array_hist(arr, region, lo, nbins, hi) -> (nblo, hist, nabv);
    lvars arr, region, lo, nbins, hi, nblo = 0, hist, nabv = 0;
    ;;; Get a histogram of the values in the specified region of the array.

    ;;; Array info
    lvars
        arrspec = arr.arrayvector.datakey.class_spec,
        use_extfloats = arrspec == "decimal",
        use_extbytes = arrspec == 8 and lo.isinteger and hi.isinteger;

    ;;; Default region
    unless region then
        boundslist(arr) -> region
    endunless;

    unless hi > lo then
        mishap(lo, hi, 2, 'Require high bound greater than low bound')
    endunless;

    ;;; Deal with nbins argument options (needed to allow updating
    ;;; of arbitrary part of existing vector)
    lvars
        startindex = 1,
        veclen = nbins,
        procedure inithist = initv;
    ;;; Want intvectors in case of external calls
    if use_extfloats or use_extbytes then
        initintvec -> inithist
    endif;
    if nbins.islist then
        dl(nbins) -> (startindex, nbins, veclen);
        checkinteger(startindex, 1, false);
        if veclen.isvectorclass then
            veclen -> hist;
            length(hist) -> veclen;
            check_vec_takes_ints(hist);
        else
            inithist(veclen) -> hist
        endif;
        checkinteger(startindex + nbins - 1, 1, veclen);
    elseif nbins.isvectorclass then
        nbins -> hist;
        length(hist) ->> nbins -> veclen;
        check_vec_takes_ints(hist);
    else
        nbins -> veclen;
        inithist(nbins) -> hist
    endif;
    ;;; Make sure we start from 0 in all cases
    set_subvector(0, startindex, hist, nbins);

    ;;; Either its a byte or float array and can use
    ;;; an external proc for speed or its not and have to do it in POP-11.

    if use_extbytes or use_extfloats then
        ;;; Make sure hist is an intvec
        lvars keephist = false, keepstart = false;
        unless hist.isintvec then
            hist -> keephist;  startindex -> keepstart;
            initintvec(nbins) -> hist;
            1 -> startindex;
        endunless;

        ;;; Initialise counts for below and above
        lconstant bloabv = initintvec(2);
        fill(0, 0, bloabv) -> ;

        lvars extargs, argvec, results;

        if use_extbytes then
            ext2d_args([% arr %], region) -> extargs;
            if extargs.isvector then
                exacc array_hist_b(explode(extargs),
                    lo, hi, hist, startindex-1, nbins, bloabv);
            else
                for argvec from_repeater extargs do
                    exacc array_hist_b(explode(argvec),
                        lo, hi, hist, startindex-1, nbins, bloabv);
                endfor
            endif

        elseif use_extfloats then
            lconstant tofloat = number_coerce(% 0.0s0 %);
            ext2d_args([% arr %], region) -> extargs;
            if extargs.isvector then
                exacc array_hist_f(explode(extargs),
                    lo.tofloat, hi.tofloat,
                    hist, startindex-1, nbins, bloabv);
            else
                for argvec from_repeater extargs do
                    exacc array_hist_f(explode(argvec),
                        lo.tofloat, hi.tofloat,
                        hist, startindex-1, nbins, bloabv);
                endfor
            endif
        endif;

        ;;; Get back results
        bloabv(1) -> nblo;
        bloabv(2) -> nabv;
        if keephist then
            move_subvector(1, hist, keepstart, keephist, nbins);
            keephist -> hist
        endif

    else    ;;; do it in POP-11

        lvars val, ibin,
            procedure sub = class_fast_subscr(datakey(hist)),
            binsizeinv = nbins / (hi - lo),
            endindex = startindex + nbins - 1;
        for val in_array arr in_region region do
            ;;; k1 must be added before taking intof, as otherwise
            ;;; get problems with e.g. intof(-0.5) = 0
            intof(binsizeinv * (val - lo) + startindex) -> ibin;
            if ibin fi_< startindex then
                nblo fi_+ 1 -> nblo
            elseif ibin fi_> endindex then
                nabv fi_+ 1 -> nabv
            else
                sub(ibin, hist) fi_+ 1 -> sub(ibin, hist)
            endif
        endfor

    endif

enddefine;

endsection;
