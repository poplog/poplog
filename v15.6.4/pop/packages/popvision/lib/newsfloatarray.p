/* --- Copyright University of Sussex 2003. All rights reserved. ----------
 > File:            $popvision/lib/newsfloatarray.p
 > Purpose:         Create arrays of packed floating point
 > Author:          David S Young, Jun  3 1992 (see revisions)
 > Documentation:   HELP NEWSFLOATARRAY
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses oldarray

defclass sfloatvec :sfloat;

define global newsfloatarray = newanyarray(% sfloatvec_key %); enddefine;

define oldsfloatarray = oldanyarray(% sfloatvec_key %); enddefine;

define global issfloatarray(arr) /* -> result */;
    ;;; Returns false unless arr is an array with an arrayvector containing
    ;;; only single precision floating point values.
    lvars arr;
    lconstant (value_spec, ) = field_spec_info("sfloat");
    arr.isarray and arr.arrayvector.datakey.class_spec == value_spec
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David Young, Jul 15 2003
        Made oldsfloatarray a closure.
--- David S Young, Nov 15 1994
        Added oldsfloatarray to reduce need for garbage collections, and
        changed class from sfloat to sfloatvec for consistency with
        intvec etc.
--- David S Young, Jul 13 1993
        Name changed from newfloatarray to avoid clash with *VEC_MAT package
--- David S Young, Aug 10 1992
        -newfloatarray- no longer declared constant
--- David S Young, Jul 28 1992
        -isfloatarray- now uses -class_spec- instead of -class_field_spec-
        and returns <false> if not given an array instead of mishapping.
--- David S Young, Jun 19 1992
        Added recogniser -isfloatarray-
 */
