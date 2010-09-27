/* --- Copyright University of Sussex 2000. All rights reserved. ----------
 > File:            $popvision/include/mlp.ph
 > Purpose:         Include file for LIB * MLP and LIB * MLP_DATA
 > Author:          David S Young, Aug 14 1998 (see revisions)
 */

/* Data vector */

defclass lconstant mlpsvec :sfloat;     ;;; ought to be iconstant, but
                                        ;;; does not work
defclass lconstant mlpivec :int;

/* Array and vector type check */

define iconstant issfloatvec(vec) /* -> result */;
    lconstant (sfloat_spec, ) = field_spec_info("sfloat");
    class_spec(datakey(vec)) == sfloat_spec
enddefine;

define iconstant issfloatarr(arr) /* -> result */;
    issfloatvec(arrayvector(arr))
enddefine;

/* Array coercion to sfloat */

define iconstant array_to_sfloat(arr) -> arr;
    ;;; Copy array to non-offset sfloat array if necessary
    lvars ( , offset) = arrayvector_bounds(arr);
    unless arr.issfloatarr and offset == 1 then
        newanyarray(boundslist(arr), arr, mlpsvec_key) -> arr
    endunless
enddefine;

/* Compile-time procedure */

define iconstant mlp_upd_coerce; enddefine;
define updaterof mlp_upd_coerce(type, proc);
    ;;; Updates the updater of the procedure proc so that it subsequently
    ;;; coerces values to the type of 'type'. The updater must take just
    ;;; two arguments. Also changes booleans to 0 or 1.
    lvars orig_updater = updater(proc);
    unless pdnargs(orig_updater) == 2 then
        mishap(proc, 1, 'Updater must take exactly 2 arguments')
    endunless;

    procedure(value,target); lvars value target;
        if value.isboolean then
            if value then 1 else 0 endif -> value
        endif;
        orig_updater(number_coerce(value, type), target)
    endprocedure -> updater(proc)
enddefine;

/* Macros */

define:inline iconstant tofloat(x);
    number_coerce(x, 0.0s0)
enddefine;

/* --- Revision History ---------------------------------------------------
--- David Young, Mar  2 2000
        Moved from Sussex local vision libraries to popvision.
--- David S Young, Aug 26 1998
        Removed redundant procedures and added array_to_sfloat.
 */
