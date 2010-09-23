/* --- Copyright University of Sussex 2001. All rights reserved. ----------
 > File:            $popvision/lib/rgb_arrays.p
 > Purpose:         RGB array conversions for 24-bit X window systems
 > Author:          David Young, Sep  3 2001 (see revisions)
 > Documentation:   HELP * RGB_ARRAYS
 > Related Files:   LIB * RCG_ARRAY.C; see also uses statements below
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses newbytearray
uses newintarray
uses newsfloatarray
uses objectfile
uses boundslist_utils
uses ext2d_args

lconstant macro extname = 'rgb_arrays',
    obfile = objectfile(extname);

exload extname [^obfile] lconstant
    EXT_rgb8_to_32(14)                   <- rgb8_to_32,
    EXT_rgbsfloat_to_32(14)              <- rgbsfloat_to_32,
    EXT_rgb32_to_8(14)                   <- rgb32_to_8,
    EXT_rgb32_to_sfloat(14)              <- rgb32_to_sfloat,
    EXT_rgb8_to_24(14)                   <- rgb8_to_24,
    EXT_rgbsfloat_to_24(14)              <- rgbsfloat_to_24,
    EXT_rgb24_to_8(14)                   <- rgb24_to_8,
    EXT_rgb24_to_sfloat(14)              <- rgb24_to_sfloat,
    EXT_rgb32_to_24(8)                   <- rgb32_to_24,
    EXT_rgb24_to_32(8)                   <- rgb24_to_32
endexload;

defclass vec24 :24;

define lconstant coerce_array(arr, region, tag) /* -> newarr */;
    lvars k = arr.arrayvector.datakey.class_spec;
    if k.isinteger and k > 0 then
        oldbytearray(tag, region, arr <> nonop fi_>> (% k-8 %))
    else
        oldsfloatarray(tag, region, arr)
    endif
enddefine;

define rgbsep_to_32(r, g, b, region, arr) -> arr;
    ;;; Constructs an array of 32-bit words of which the first 24 bits
    ;;; are used for the r, g and b values.
    ;;; Assumes that "int" arrays are 32 bits.
    ;;; If inputs are integer arrays then data assumed to lie in range
    ;;; supported by array; else data assumed to be floats in range 0.0-1.0.

    unless region then
        region_intersect(r, region_intersect(g, b)) -> region
    endunless;

    lvars
        test = if r.isbytearray then isbytearray else issfloatarray endif;
    unless r.test and g.test and b.test then
        ;;; need to coerce type of array
        lconstant tagr = consref(0), tagg = consref(0), tagb = consref(0);
        coerce_array(r, region, tagr) -> r;
        coerce_array(g, region, tagg) -> g;
        coerce_array(b, region, tagb) -> b;
    endunless;

    if arr.isarray then
        unless arr.arrayvector.datakey.class_spec.abs == 32 then
            mishap(arr.arrayvector.datakey, 1, 'Integer array required for output')
        endunless
    elseif arr then
        oldintarray(arr, region) -> arr
    else
        newintarray(region) -> arr
    endif;

    lvars extargs = ext2d_args([% r, g, b, arr %], region);
    if r.isbytearray then
        exacc EXT_rgb8_to_32(explode(extargs));
    else
        exacc EXT_rgbsfloat_to_32(explode(extargs));
    endif;
enddefine;

define rgb32_to_sep(arr, region, r, g, b) -> (r, g, b);
    ;;; reverses rgbsep_to_32
    unless region then
        boundslist(arr) -> region
    endunless;
    unless arr.arrayvector.datakey.class_spec.abs == 32 then
        mishap(arr.arrayvector.datakey, 1, 'Integer array expected for input')
    endunless;
    lvars outsfloat = r.issfloatarray or r == "sfloat";
    if r.isarray then
        lvars test = if outsfloat then issfloatarray else isbytearray endif;
        unless r.test and g.test and b.test then
            mishap(r.arrayvector.datakey,
                g.arrayvector.datakey,b.arrayvector.datakey,3,
                'Output arrays must be byte or float')
        endunless
    else
        lvars create = if outsfloat then newsfloatarray else newbytearray endif;
        create(region) -> r; create(region) -> g; create(region) -> b
    endif;

    lvars extargs = ext2d_args([% arr, r, g, b %], region);
        if outsfloat then
            exacc EXT_rgb32_to_sfloat(explode(extargs));
        else
            exacc EXT_rgb32_to_8(explode(extargs));
        endif;
    enddefine;

define rgbsep_to_24(r, g, b, region, arr) -> arr;
    ;;; Like rgbsep_to_32, but uses 24-bit representation.

    unless region then
        region_intersect(r, region_intersect(g, b)) -> region
    endunless;

    lvars
        test = if r.isbytearray then isbytearray else issfloatarray endif;
    unless r.test and g.test and b.test then
        ;;; need to coerce type of array
        lconstant tagr = consref(0), tagg = consref(0), tagb = consref(0);
        coerce_array(r, region, tagr) -> r;
        coerce_array(g, region, tagg) -> g;
        coerce_array(b, region, tagb) -> b;
    endunless;

    if arr.isarray then
        unless arr.arrayvector.datakey.class_spec == 24 then
            mishap(arr.arrayvector.datakey, 1,
                '24-bit array required for output')
        endunless
    elseif arr then
        oldanyarray(arr, region, vec24_key) -> arr
    else
        newanyarray(region, vec24_key) -> arr
    endif;

    lvars extargs = ext2d_args([% r, g, b, arr %], region);
        if r.isbytearray then
            exacc EXT_rgb8_to_24(explode(extargs));
        else
            exacc EXT_rgbsfloat_to_24(explode(extargs));
        endif;
    enddefine;

define rgb24_to_sep(arr, region, r, g, b) -> (r, g, b);
    ;;; reverses rgbsep_to_32
    unless region then
        boundslist(arr) -> region
    endunless;
    unless arr.arrayvector.datakey.class_spec == 24 then
        mishap(arr.arrayvector.datakey, 1, '24 bit array expected for input')
    endunless;
    lvars outsfloat = r.issfloatarray or r == "sfloat";
    if r.isarray then
        lvars test = if outsfloat then issfloatarray else isbytearray endif;
        unless r.test and g.test and b.test then
            mishap(r.arrayvector.datakey,
                g.arrayvector.datakey,
                b.arrayvector.datakey, 3,
                'Output arrays must be byte or float')
        endunless
    else
        lvars create = if outsfloat then newsfloatarray else newbytearray endif;
        create(region) -> r; create(region) -> g; create(region) -> b
    endif;

    lvars extargs = ext2d_args([% arr, r, g, b %], region);
        if outsfloat then
            exacc EXT_rgb24_to_sfloat(explode(extargs));
        else
            exacc EXT_rgb24_to_8(explode(extargs));
        endif;
    enddefine;

define rgb24_to_32(arr24, region, arr) -> arr;
    ;;; Like rgb_to_32 but input is a 24-bit array as returned by e.g.
    ;;; *sunrasterfile.

    unless region then boundslist(arr24) -> region endunless;

    unless arr24.arrayvector.datakey.class_spec == 24 then
        mishap(arr24.arrayvector.datakey, 1, 'Expecting 24-bit input array')
    endunless;

    if arr.isarray then
        unless arr.arrayvector.datakey.class_spec.abs == 32 then
            mishap(arr.arrayvector.datakey, 1,
                'Integer array required for output')
        endunless
    elseif arr then
        oldintarray(arr, region) -> arr
    else
        newintarray(region) -> arr
    endif;

    lvars extargs = ext2d_args([% arr24, arr %], region);
        exacc EXT_rgb24_to_32(explode(extargs));
    enddefine;

define rgb32_to_24(arr, region, arr24) -> arr24;
    ;;; reverses rgb24_to_32
    lconstant key24 = conskey("array24", 24);

    unless region then boundslist(arr) -> region endunless;

    unless arr.arrayvector.datakey.class_spec.abs == 32 then
        mishap(arr.arrayvector.datakey, 1, 'Integer array expected for input')
    endunless;
    if arr24.isarray then
        unless arr24.arrayvector.datakey.class_spec == 24 then
            mishap(arr24.arrayvector.datakey, 1, 'Expecting 24-bit array')
        endunless
    else
        newanyarray(region, key24) -> arr24
    endif;

    lvars extargs = ext2d_args([% arr, arr24 %], region);
    exacc EXT_rgb32_to_24(explode(extargs));
enddefine;

global vars rgb_arrays = true;

endsection;

/* --- Revision History ---------------------------------------------------
--- David Young, Oct  2 2001
        Declared rgb_arrays to avoid reloading.
 */
