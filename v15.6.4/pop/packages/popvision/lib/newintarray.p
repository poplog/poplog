/* --- Copyright University of Sussex 2003. All rights reserved. ----------
 > File:            $popvision/lib/newintarray.p
 > Purpose:         Create packed arrays of integers
 > Author:          David S Young, Nov 15 1994 (see revisions)
 > Documentation:   HELP * NEWINTARRAY
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses oldarray

define global newintarray = newanyarray(% intvec_key %); enddefine;

define oldintarray = oldanyarray(% intvec_key %); enddefine;

define global isintarray(arr) /* -> result */;
    ;;; Returns false unless arr is an array with an arrayvector containing
    ;;; only signed integer values.
    lvars arr;
    lconstant (value_spec, ) = field_spec_info("int");
    arr.isarray and arr.arrayvector.datakey.class_spec == value_spec
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David Young, Jul 15 2003
        Made oldintarray a closure.
 */
