/* --- Copyright University of Sussex 2003. All rights reserved. ----------
 > File:            $popvision/lib/newrfloatarray.p
 > Purpose:         Create packed real floating-point arrays
 > Author:          David Young, Oct  1 2003
 > Documentation:   HELP * NEWRFLOATARRAY
 > Related Files:   LIB * NEWSFLOATARRAY, LIB * NEWDFLOATARRAY
 */


compile_mode:pop11 +strict;

section;

uses popvision, newsfloatarray, newdfloatarray;

define newrfloatarray with_nargs 1;
    if popdprecision then
        newdfloatarray()
    else
        newsfloatarray()
    endif
enddefine;

define oldrfloatarray with_nargs 2;
    if popdprecision then
        olddfloatarray()
    else
        oldsfloatarray()
    endif
enddefine;

define global isrfloatarray(arr) /* -> result */;
    lconstant
        (value_spec_s, _) = field_spec_info("sfloat"),
        (value_spec_d, _) = field_spec_info("dfloat");
    if arr.isarray then
        lvars spec = arr.arrayvector.datakey.class_spec;
        if popdprecision then
            spec == value_spec_d
        else
            spec == value_spec_s
        endif
    else
        false
    endif
enddefine;

endsection;
