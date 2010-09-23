/* --- Copyright University of Sussex 1998. All rights reserved. ----------
 > File:            $popvision/lib/array_random.p
 > Purpose:         Set a region of an array to random values
 > Author:          David S Young, Jul  8 1996 (see revisions)
 > Documentation:   HELP * ARRAY_RANDOM
 > Related Files:   LIB * ARRAY_RANDOM.C, LIB * ERANDOM
 */


compile_mode:pop11 +strict;

section;

uses popvision
uses objectfile
uses ext2d_args
uses newbytearray
uses newsfloatarray


lconstant macro extname = 'array_random',
    obfile = objectfile(extname);

exload extname [^obfile] lconstant
                    array_random_set(1),
                    array_random_get(1),
                    array_random_u_2d_f(7),
                    array_random_ui_2d_f(7),
                    array_random_g_2d_f(7),
                    array_random_u_2d_b(7)
endexload;

define lconstant clockseed /* -> (s1, s2, s3) */;
    ;;; Tries to come up with a random seed. Hard to get 48 bits from the
    ;;; clock though, so tacks on a couple of other randomish things,
    ;;; and divides the bits roughly equally amongst 3 integers.
    lvars
        seed = popmemused,
        rt = sys_real_time(),
        st = systime();
    (seed << (integer_length(rt)-1)) ||/& rt -> seed;
    (seed << (integer_length(st)-1)) ||/& st -> seed;
    lvars
        shift = integer_length(seed) div 3;
    seed /* -> s1 */;
    (seed >> shift ->> seed) /* -> s2 */;
    (seed >> shift) /* -> s3 */;
enddefine;

defclass lconstant ushortvec :ushort;
lconstant seedvec = initushortvec(3),
    shortbits = 2**SIZEOFTYPE(:ushort,:1) - 1;

define active:3 array_random_seed /* -> s1, s2, s3 */;
    ;;; Returns 3 integers giving the current seeds.
    ;;; External generator should be a 3*16bit generator such
    ;;; as drand48 (see the C code for more information).
    exacc array_random_get(seedvec);
    explode(seedvec)
enddefine;

lvars seed_setup = false;

define updaterof active:3 array_random_seed(s1, s2, s3);
    lvars s1, s2, s3;
    ;;; Sets the seeds for the external generator.
    unless s1 and s2 and s3 then clockseed() -> (s1, s2, s3) endunless;
    exacc array_random_set(
        fill(s1 && shortbits, s2 && shortbits, s3 && shortbits, seedvec)
    );
    true -> seed_setup;
enddefine;

define array_random_spec(spec, arr) -> (type, p0, p1);
    ;;; Sort out the random spec, which can be abbreviated in
    ;;; various ways, and check it makes sense.
    lvars spec, arr,
        type = "uniform", p0 = false, p1 = false;

    ;;; Deal with short forms of the spec
    if spec then
        if spec.isreal then     ;;; upper end of range for uniform
            spec -> p1
        elseif spec == "uniform" or spec == "gaussian" then
            spec -> type
        elseif (spec.islist or spec.isvector) and length(spec) == 3 then
            explode(spec) -> (type, p0, p1);
            unless (type == "uniform" or type == "gaussian")
            and p0.isreal and p1.isreal then
                mishap(spec, 1,
                    'Unexpected elements in distribution spec list')
            endunless
        else
            mishap(spec, 1, 'Unexpected distribution specification')
        endif
    endif;

    ;;; Deal with defaults for p0 and p1
    if arr.isbytearray then
        if type == "uniform" then
            p0 or 0 -> p0;
            p1 or 256 -> p1
        else
            mishap(0,
                'Need full or floating point array for gaussian dist')
        endif;
        unless p0.isinteger and p1.isinteger then
            mishap(p0, p1, 2, 'Need integer bounds for byte array')
        endunless
    else
        p0 or (p1.isinteger and 0) or 0.0 -> p0;
        p1 or (p0.isinteger and 1) or 1.0 -> p1
    endif;

    ;;; Check on sensible spec
    if type == "uniform" and p1 <= p0 then
        mishap(p0, p1, 2, 'Upper bound < lower bound')
    elseif type == "gaussian" and p1 <= 0 then
        mishap(p1, 1, 'Std dev not positive')
    endif;
enddefine;

global vars procedure array_random = identfn; ;;; so erandom does not reload
uses erandom

define array_random(spec, arr, region) -> arr;
    ;;; Fill a region of the array with random numbers, in the specified range.
    ;;; Distributions are uniform and approximate Gaussian.
    ;;; Optimised for 2-D byte and single precision float arrays, but almost
    ;;; optimal for any number of dimensions with these types.
    lvars spec, arr, region;

    define lconstant todouble; number_coerce(0.0d0) enddefine;

    ;;; Random initialisation of seeds.
    unless seed_setup then
        clockseed() -> array_random_seed
    endunless;

    ;;; Deal with case where arr is given as a boundslist
    if arr.islist then
        (false, arr) -> (arr, region)
    endif;

    ;;; Sort out specification
    ;;; p0 and p1 specify range for uniform, mean and sd for gaussian
    lvars (type, p0, p1) = array_random_spec(spec, arr);

    ;;; Make output array if needed
    unless arr then
        if type == "uniform"
        and p0.isinteger and p0 >= 0
        and p1.isinteger and p1 <= 256 then
            newbytearray(region) -> arr
        else
            newsfloatarray(region) -> arr
        endif
    endunless;
    unless region then      ;;; set up region if needed
        boundslist(arr) -> region
    endunless;

    ;;; Either its a byte or float array and can use
    ;;; an external proc for speed or its not and have to do it in POP-11.

    lvars extargs, argvec;
    if arr.isbytearray then
        ext2d_args([% arr %], region) -> extargs;
        if extargs.isvector then
            exacc array_random_u_2d_b(explode(extargs), round(p0), round(p1));
        else
            for argvec from_repeater extargs do
                exacc array_random_u_2d_b(explode(argvec),
                    round(p0), round(p1));
            endfor
        endif

    elseif arr.issfloatarray then
        if type == "uniform" then
            if p0.isinteger and p1.isinteger then
                ext2d_args([% arr %], region) -> extargs;
                if extargs.isvector then
                    exacc array_random_ui_2d_f(explode(extargs),
                        todouble(p0), todouble(p1));
                else
                    for argvec from_repeater extargs do
                        exacc array_random_u_2d_f(explode(argvec),
                            todouble(p0), todouble(p1));
                    endfor
                endif
            else     ;;; type uniform, but limits not integers
                ext2d_args([% arr %], region) -> extargs;
                if extargs.isvector then
                    exacc array_random_u_2d_f(explode(extargs),
                        todouble(p0), todouble(p1));
                else
                    for argvec from_repeater extargs do
                        exacc array_random_u_2d_f(explode(argvec),
                            todouble(p0), todouble(p1));
                    endfor
                endif
            endif
        else            ;;; pseudo-Gaussian
            ext2d_args([% arr %], region) -> extargs;
            if extargs.isvector then
                exacc array_random_g_2d_f(explode(extargs),
                    todouble(p0), todouble(p1));
            else
                for argvec from_repeater extargs do
                    exacc array_random_g_2d_f(explode(argvec),
                        todouble(p0), todouble(p1));
                endfor
            endif
        endif

    else     ;;; do it in POP-11
        lvars v, procedure rand = erandom(spec);
        for v in_array arr updating_last in_region region do
            rand() -> v
        endfor
    endif

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David S Young, Aug 13 1998
        Removed redundant procedures.
--- David S Young, Aug  9 1996
        No longer uses Pop-11 generators. Tie-in with LIB * ERANDOM added.
 */
