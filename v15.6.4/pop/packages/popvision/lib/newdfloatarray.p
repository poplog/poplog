/* --- Copyright University of Sussex 2003. All rights reserved. ----------
 > File:            $popvision/lib/newdfloatarray.p
 > Purpose:         Create arrays of packed double precision floats
 > Author:          David S Young, Nov 15 1994 (see revisions)
 > Documentation:   HELP * NEWDFLOATARRAY
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses oldarray

defclass dfloatvec :dfloat;

define global newdfloatarray = newanyarray(% dfloatvec_key %); enddefine;

define olddfloatarray = oldanyarray(% dfloatvec_key %); enddefine;

define global isdfloatarray(arr) /* -> result */;
    ;;; Returns false unless arr is an array with an arrayvector containing
    ;;; only double precision floating point values.
    lvars arr;
    lconstant (value_spec, ) = field_spec_info("dfloat");
    arr.isarray and arr.arrayvector.datakey.class_spec == value_spec
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David Young, Jul 15 2003
        Made olddfloatarray a closure.
 */
