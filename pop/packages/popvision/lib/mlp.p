/* --- Copyright University of Sussex 2000. All rights reserved. ----------
 > File:            $popvision/lib/mlp.p
 > Purpose:         Multi-layer perceptron neural nets
 > Author:          David S Young, Aug 14 1998 (see revisions)
 > Documentation:   HELP * MLP, TEACH * MLP
 > Related Files:   LIB MLP_DATA, LIB MLP.C, INCLUDE MLP
 */

/* POP-11 interface to C implementation */

/*

         CONTENTS - (Use <ENTER> g to access required sections)

 -- External loads
 -- Random number seed interface
 -- General purpose utilities
 -- Records to hold networks
 -- Building net structures
 -- Net creation and resetting
 -- Weight access and update
 -- Data check
 -- Net execution and training
 -- Net printing
 -- Net copying
 -- Miscellaneous and experimental

*/

compile_mode:pop11 +strict;

section;

uses popvision
uses objectfile

uses mlp_data

include mlp

/*
-- External loads -----------------------------------------------------
*/

lconstant macro extname = 'mlp',
    obfile = objectfile(extname);

unless obfile then mishap(extname, 1, 'Object file not found') endunless;

exload extname [^obfile]
lconstant
    MLP_random_set(s)                                   <- mlp_random_set,
    MLP_random_get(s)                                   <- mlp_random_get,
    MLP_sumsquares(arr, n): float                       <- mlp_sumsquares,
    MLP_randomvec(arr, n, x0<SF>, x1<SF>)               <- mlp_randomvec,
    MLP_scalevec(factor<SF>, arr, n)                    <- mlp_scalevec,
    MLP_fillvec(value<SF>, arr, n)                      <- mlp_fillvec,
    MLP_forward(stims, stimstarts, ndim, negs, stimoffs,
        nin, nunits, nlevels, tranfns, activs, biases,
        ntunits, weights, nweights, outs, outstarts, outoffs,
            nout): int                                  <- mlp_forward,
    MLP_intotarg(weights, nweights, activs, nactivs, nlowest,
        stims, stimstarts, ndim, negs, stimoffs, nin)   <- mlp_intotarg,
    MLP_forback(stims, stimstarts, ndim, negs, stimoffs,
        nin, nunits, nlevels, tranfns, activs, biases, ntunits,
        weights, nweights, bschange, wtchange, etas, etbs,
        alpha<SF>, decay<SF>, targs, targstarts, targoffs,
        nout, niter, nbatch, ransel, err, errvar): int  <- mlp_forback
endexload;

/*
-- Random number seed interface ---------------------------------------
*/

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

define active:3 mlp_random_seed /* -> s1, s2, s3 */;
    ;;; Returns 3 integers giving the current seeds.
    ;;; External generator should be a 3*16bit generator such
    ;;; as drand48 (see the C code for more information).
    exacc MLP_random_get(seedvec);
    explode(seedvec)
enddefine;

lvars seed_setup = false;

define updaterof active:3 mlp_random_seed(s1, s2, s3);
    lvars s1, s2, s3;
    ;;; Sets the seeds for the external generator.
    unless s1 and s2 and s3 then clockseed() -> (s1, s2, s3) endunless;
    exacc MLP_random_set(
        fill(s1 && shortbits, s2 && shortbits, s3 && shortbits, seedvec)
    );
    true -> seed_setup;
enddefine;

/*
-- General purpose utilities ------------------------------------------
*/

define lconstant mlp_sumsquares(vec) /* -> sum */;
    exacc MLP_sumsquares(vec, datalength(vec))
enddefine;

define lconstant mlp_randomvec; enddefine;
define updaterof mlp_randomvec(x0, x1, vec);
    unless seed_setup then clockseed() -> mlp_random_seed endunless;
    exacc MLP_randomvec(vec, datalength(vec), tofloat(x0), tofloat(x1))
enddefine;

define lconstant mlp_scalevec; enddefine;
define updaterof mlp_scalevec(factor, vec);
    exacc MLP_scalevec(tofloat(factor), vec, datalength(vec))
enddefine;

define lconstant mlp_fillvec; enddefine;
define updaterof mlp_fillvec(value, vec);
    exacc MLP_fillvec(tofloat(value), vec, datalength(vec))
enddefine;

define lconstant mlp_coparr; enddefine;
define updaterof mlp_coparr(arr1, arr2);
    ;;; Copies arr1 into arr2, item for item
    lvars arr1 arr2;
    lvars vec1 vec2 base1 base2 top1 top2;
    arrayvector(arr1) -> vec1;
    arrayvector(arr2) -> vec2;
    arrayvector_bounds(arr1) -> base1 -> top1;
    arrayvector_bounds(arr2) -> base2 -> top2;
    if (top1 - base1 + base2) > top2 then
        mishap('Not room in new arrayvector', [^arr1 ^arr2])
    endif;
    move_subvector(base1, vec1, base2, vec2, top1 - base1 + 1);
enddefine;

/*
-- Records to hold networks -------------------------------------------

A network record has the following:

a name
a vector of the weight arrays (one element per level)
the combined weight vector
a vector of the weight change arrays
the combined weight change vector
a vector of the bias arrays
the combined bias vector
a vector of the bias change arrays
the combined bias change vector
a vector of the transfer function arrays
the combined transfer function vector
a vector of the activation arrays
the combined activation vector
the no of input units
an array giving the numbers of units per layer from the lowest
    hidden layer to the output layer
the no of output units
eta, the global learning rate
etas, the learning rates for weights (as a vector of arrays)
the combined etas vector
etbs, the learning rates for biases (as a vector of arrays)
the combined etbs vector
clamped, a flag to say whether any weights are clamped
alpha, the learning inertia
decay, the rate of weight decay
the no of levels
the total no of weights
the total no of units (not counting input units)

*/


defclass lconstant mlp_arrvec;      ;;; ordinary vector

/*
;;; Vector of arrays should be non-updateable - but this messes up
;;; reading using datainout, so disabled for now.
false -> updater(subscrmlp_arrvec);     ;;; no updater for subscriptor
subscrmlp_arrvec -> class_apply(mlp_arrvec_key);   ;;; needed
*/

;;; Need to recompile the recordclass if the procedures that fiddle
;;; with its updaters are to work
#_IF DEF mlp_net_record_key
    syscancel("mlp_net_record_key");
#_ENDIF

/* The net record structure. */

defclass procedure mlp_net_record
       {mlp_name,
        mlp_weights, mlp_wtvec,
        mlp_wtchange, mlp_wtchvec,
        mlp_biases, mlp_bsvec,
        mlp_bschange, mlp_bschvec,
        mlp_tranfns, mlp_tranfnvec,
        mlp_activs, mlp_actvec,
        mlp_ninunits, mlp_nhunits, mlp_noutunits,
        mlp_eta,
        mlp_etas, mlp_etavec,
        mlp_etbs, mlp_etbvec,
        mlp_clamped,
        mlp_alpha,
        mlp_decay,
        mlp_nlevels,
        mlp_nweights, mlp_ntunits};

lconstant mlp_vecarr_access =
    [% mlp_weights, mlp_wtchange, mlp_biases, mlp_bschange, mlp_tranfns,
       mlp_activs,  mlp_etas,     mlp_etbs %];
lconstant mlp_vec_access =
    [% mlp_wtvec,   mlp_wtchvec,  mlp_bsvec,  mlp_bschvec,  mlp_tranfnvec,
       mlp_actvec,  mlp_etavec,   mlp_etbvec %];

/* Fix the updaters of the array access procedures. Do not allow
the vectors of arrays to be updated, and build new vectors if the
underlying vector representations are updated */

define lconstant mlp_newarrvec(uvec, arrvec) /* -> newvec */;
    ;;; uvec is underlying vector of numbers. arrvec is vector of arrays.
    lvars arr base;
    consmlp_arrvec(#|
            for arr in_vectorclass arrvec do
                arrayvector_bounds(arr) -> ( , base);
                newanyarray(boundslist(arr), uvec, base-1)
            endfor |#)
enddefine;

define lconstant accessfixer(uvecacc, avecacc) /* -> procedure */;
    lvars
        olduvecupd = updater(uvecacc),       ;;; access to underlying vec
        oldavecupd = updater(avecacc);       ;;; access to vec of arrays

    procedure(newuvec, net);
        lvars
            olduvec = net.uvecacc,
            oldavec = net.avecacc;
        unless class_spec(datakey(newuvec))
            == class_spec(datakey(olduvec)) then
            mishap(datakey(newuvec), 1, 'Wrong kind of vector')
        endunless;
        unless datalength(newuvec) == datalength(olduvec) then
            mishap('Wrong size of vector for updater')
        endunless;
        newuvec, /* -> */ net.olduvecupd;
        mlp_newarrvec(newuvec, oldavec), /* -> */ net.oldavecupd
    endprocedure /* -> procedure */

enddefine;

lblock
    lvars arracc, vecacc;
    for arracc, vecacc in mlp_vec_access, mlp_vecarr_access do
        accessfixer(arracc, vecacc) -> updater(arracc);
        false -> updater(vecacc)
    endfor;
endlblock;

/* And now fix other updaters */

false ->> updater(mlp_ninunits) ->> updater(mlp_nhunits)
      ->> updater(mlp_noutunits) ->> updater(mlp_nlevels)
      ->> updater(mlp_nweights) -> updater(mlp_ntunits);

0.0s0 ->> mlp_upd_coerce(mlp_alpha) -> mlp_upd_coerce(mlp_decay);

define lconstant oldmlp_eta; enddefine;
define updaterof oldmlp_eta = updater(mlp_eta) enddefine;

define updaterof mlp_eta(eta, net);
    ;;; Set all the learning rates to eta, except for those clamped.

    ;;; Could avoid uncertainty about whether some weights clamped by
    ;;; keeping a count in mlp_clamped field, but this involves extra
    ;;; work when individual weights are clamped or unclamped, and
    ;;; therefore probably less efficient overall.

    tofloat(eta) -> eta;
    eta -> net.oldmlp_eta;

    lvars clamp = false,
        etavec = net.mlp_etavec,
        etbvec = net.mlp_etbvec;

    ;;; Deal with case where some of net may or may not be clamped

    define lconstant check_clamped(v); lvars v;
        if v < 0.0 then true -> clamp; exitfrom(appdata) endif
    enddefine;

    if net.mlp_clamped == "maybe" then
        appdata(etavec, check_clamped);
        unless clamp then
            appdata(etbvec, check_clamped)
        endunless;
        clamp -> net.mlp_clamped
    endif;

    ;;; Set etas for non-clamped weights

    if net.mlp_clamped then
        lvars e;
        for e, e in_array etavec, etavec updating_last do
            if e >= 0.0 then eta -> e endif
        endfor;
        for e, e in_array etbvec, etbvec updating_last do
            if e >= 0.0 then eta -> e endif
        endfor;
    else
        eta -> mlp_fillvec(etavec);
        eta -> mlp_fillvec(etbvec)
    endif

enddefine;

/*
-- Building net structures --------------------------------------------
*/

define lconstant actarrtovec(vector, nunits) /* -> vec */;
    ;;; Returns a vector of separate level
    ;;; arrays mapped onto an underlying activations vector
    lvars ncurrent, cpos = 0;
    consmlp_arrvec(#|
            for ncurrent in_vector nunits do
                newanyarray([1 ^ncurrent], vector, cpos);  ;;; on stack
                cpos + ncurrent -> cpos
            endfor |#)
enddefine;

define lconstant actarrvec(nunits,ntunits) /* -> (vec, arr) */;
    ;;; Returns a vector and also a vector of separate level
    ;;; arrays mapped onto it. Optional third argument can be
    ;;; "integer" or "float" to set type of vector.
    lvars vector, type = "float";
    unless ntunits.isinteger then
        (nunits, ntunits) -> (nunits, ntunits, type)
    endunless;
    if type == "float" then
        initmlpsvec(ntunits)
    elseif type == "integer" then
        initmlpivec(ntunits)
    else
        mishap(type, 1, 'unknown type for net vector')
    endif -> vector;
    actarrtovec(vector,nunits), vector    ;;; left on stack in this order
enddefine;

define lconstant wtarrtovec(array,nin,nunits) /* -> vec */;
    ;;; Like actarrtovec but for weights etc
    lvars ncurrent, nlower = nin, cpos = 0;
    consmlp_arrvec(#|
            for ncurrent in_vector nunits do
                newanyarray([1 ^nlower 1 ^ncurrent],array,cpos); ;;; on stack
                cpos + ncurrent * nlower -> cpos;
                ncurrent -> nlower
            endfor |#)
enddefine;

define lconstant wtarrvec(nin,nunits,nweights) /* -> arr -> vec */;
    ;;; Like actarrvec but for weights etc
    lvars array;
    initmlpsvec(nweights) -> array;
    wtarrtovec(array,nin,nunits), array
enddefine;

;;; This must match the usage in mlp.c
constant mlp_transfuncs
    = newproperty([
           [identity 1]
            [logistic 2]
            [tanh 3]
            [logistic_fast 4]
        ], 10, false, "perm");

lconstant maxtrf = datalength(mlp_transfuncs);

define lconstant set_tranfns; enddefine;
define updaterof set_tranfns(nunits,tranfns);
    lvars layer_spec, layer_tranfns, ninlayer, layertype, unit, unit_type;

    define lconstant tfcheck(tf);
        unless tf.isinteger and tf >= 1 and tf <= maxtrf then
            mishap(nunits, 1, 'unknown transfer function')
        endunless
    enddefine;

    for layer_spec, layer_tranfns in_vectorclass nunits, tranfns do
        if layer_spec.isinteger then
            "logistic" -> layertype
        else
            layer_spec(2) -> layertype;
            layer_spec(1) -> layer_spec;
        endif;
        if layertype.isword then
            mlp_transfuncs(layertype) -> layertype;
        endif;
        if layertype.isinteger then
            tfcheck(layertype);
            for unit from 1 to layer_spec do
                layertype -> layer_tranfns(unit)
            endfor
        elseif layertype.isvector and length(layertype) == layer_spec then
            for unit from 1 to layer_spec do
                layertype(unit) -> unit_type;
                if unit_type.isword then
                    mlp_transfuncs(unit_type) -> unit_type
                endif;
                tfcheck(unit_type);
                unit_type -> layer_tranfns(unit)
            endfor
        else
            mishap(nunits, 1, 'Incorrect transfer function spec')
        endif
    endfor
enddefine;

/*
-- Net creation and resetting -----------------------------------------
*/

define:inline lconstant getnetargs;
    ;;; Gets alpha and decay if they are passed.
    ;;; A macro - assumes variable names as given.
    unless nunits.isvectorclass then
        (nunits, wtrange, eta) -> (nunits, wtrange, eta, alpha)
    endunless;
    unless nunits.isvectorclass then
        (nunits, wtrange, eta, alpha) -> (nunits, wtrange, eta, alpha, decay)
    endunless;
enddefine;

define mlp_makenet(/* nin, */ nunits, wtrange, eta) -> machine with_nargs 5;

    ;;; nin is the number of input units

    ;;; nunits is the no of units in each layer, numbered from 1 upwards,
    ;;; starting at the lowest hidden layer, and including the
    ;;; output units but not the input units.

    ;;; Optionally, each entry in the nunits vector can contain information
    ;;; about what transfer function to use. The possibilities are stored
    ;;; in the property MLP_TRANSFUNCS. The default is the logistic
    ;;; function. The entry in the vector should be a vector; the first
    ;;; element of this should be an integer giving the no of units.
    ;;; If the second element is an integer or word then it specifies all
    ;;; the transfer functions for the layer; otherwise it must be
    ;;; a vector giving the transfer function for each unit in the layer.

    ;;; The weights get set randomly - wtrange determines the range.

    ;;; Momentum and decay are optional. On the assumption that some momentum
    ;;; but no decay is the most common case, pdnargs is set to 5.

    ;;; see if momentum and decay given
    lvars nin, alpha = 0.0, decay = -1.0;    ;;; defaults - none of either
    getnetargs();         ;;; set alpha and decay if given
    /* nin */ -> nin;     ;;; remaining arg now nin

    lvars level, nlevels, ntunits, nweights, nlower, ncurrent, simple_nunits;

    length(nunits) -> nlevels;

    ;;; convert the nunits vector to a vector of integers (i.e.
    ;;; ignoring the type information
    mapdata(nunits,
        procedure(n) /* -> n */; lvars n;
            if n.isinteger then n else n(1) endif
        endprocedure) -> simple_nunits;

    0 ->> ntunits -> nweights;
    nin -> nlower;
    for level from 1 to nlevels do
        simple_nunits(level) -> ncurrent;
        ntunits + ncurrent -> ntunits;
        nweights + ncurrent*nlower -> nweights;
        ncurrent -> nlower
    endfor;

    consmlp_net_record(
        'mlp',
        wtarrvec(nin,simple_nunits,nweights),  ;;; weights
        wtarrvec(nin,simple_nunits,nweights),  ;;; wt change
        actarrvec(simple_nunits,ntunits),      ;;; biases
        actarrvec(simple_nunits,ntunits),      ;;; bs change
        actarrvec(simple_nunits,ntunits,"integer"),    ;;; trans fn.
        actarrvec(simple_nunits,ntunits),      ;;; activs
        nin,
        consmlpivec(#| explode(simple_nunits) |#),
        simple_nunits(nlevels),
        tofloat(eta),
        wtarrvec(nin,simple_nunits,nweights),   ;;; etas
        actarrvec(simple_nunits,ntunits),       ;;; etbs
        eta < 0.0,                              ;;; clamped
        tofloat(alpha),
        tofloat(decay),
        nlevels, nweights, ntunits)
        -> machine;

    ;;; set initial weights randomly, uniform distribution
    if wtrange > 0 then
        lvars w1 = wtrange/2, w0 = -w1;
        (w0, w1) -> mlp_randomvec(machine.mlp_wtvec);
        (w0, w1) -> mlp_randomvec(machine.mlp_bsvec);
    endif;

    ;;; set up transfer function information
    nunits -> set_tranfns(machine.mlp_tranfns);

    ;;; Set the learning rate arrays
    eta ->> mlp_fillvec(machine.mlp_etavec)
        -> mlp_fillvec(machine.mlp_etbvec);
enddefine;

define updaterof mlp_resetnet(wtrange, machine);
    ;;; Randomise weights and biases, set other arrays to zero.
    if wtrange > 0 then
        lvars w1 = wtrange/2, w0 = -w1;
        (w0, w1) -> mlp_randomvec(machine.mlp_wtvec);
        (w0, w1) -> mlp_randomvec(machine.mlp_bsvec)
    else
        0 -> mlp_fillvec(machine.mlp_wtvec);
        0 -> mlp_fillvec(machine.mlp_bsvec)
    endif;
    0 -> mlp_fillvec(machine.mlp_wtchvec);
    0 -> mlp_fillvec(machine.mlp_bschvec);
    0 -> mlp_fillvec(machine.mlp_actvec)
enddefine;

/*
-- Weight access and update -------------------------------------------
*/

define mlp_weight(level, unitfrom, unitto, net) /* -> weight */;
    if not(unitfrom) or unitfrom = 0 then
        (net.mlp_biases)(level)(unitto)
    else
        (net.mlp_weights)(level)(unitfrom,unitto)
    endif
enddefine;

define updaterof mlp_weight(value, level, unitfrom, unitto, net);
    if not(unitfrom) or unitfrom = 0 then
        value -> (net.mlp_biases)(level)(unitto)
    else
        value -> (net.mlp_weights)(level)(unitfrom,unitto)
    endif
enddefine;

define mlp_clamp(level, unitfrom, unitto, net) /* -> bool */;
    ;;; Is the weight clamped?
    if not(unitfrom) or unitfrom = 0 then
        (net.mlp_etbs)(level)(unitto)
    else
        (net.mlp_etas)(level)(unitfrom,unitto)
    endif < 0.0
enddefine;

define updaterof mlp_clamp(value, level, unitfrom, unitto, net);
    ;;; Clamp the weight specified.
    lconstant clampval = -1.0s0;
    if value then
        (true, clampval)
    else
        ("maybe", net.mlp_eta)
    endif -> (net.mlp_clamped, value);
    if not(unitfrom) or unitfrom = 0 then
        value -> (net.mlp_etbs)(level)(unitto)
    else
        value -> (net.mlp_etas)(level)(unitfrom,unitto)
    endif;
enddefine;

/*
-- Data check ---------------------------------------------------------
*/

define lconstant mlp_checkdata(machine,stims,outputs);
    ;;; Mishaps if there are certain problems with the input data or
    ;;; output or target arrays.
    lvars machine stims outputs;

    unless stims.mlpdata_nunits == machine.mlp_ninunits then
        mishap('input - machine mismatch',[])
    endunless;
    unless outputs.mlpdata_nunits == machine.mlp_noutunits then
        mishap('output/target - machine mismatch',[])
    endunless;

    ;;; Possibly the next two tests should really check that the
    ;;; no of samples on each dimension is the same
    unless stims.mlpdata_negs == outputs.mlpdata_negs then
        mishap('input - output/target no. examples mismatch', [])
    endunless;
    unless stims.mlpdata_ndim == outputs.mlpdata_ndim then
        mishap('input - output/target dimension mismatch', [])
    endunless;

    if stims.mlpdata_niter < 0 or outputs.mlpdata_niter < 0 then
        mishap('negative number of iterations', [])
    endif;

    ;;; Check that the first and last samples do not go outside the
    ;;; data area in the arrays - only for case of full index arrays
    define lconstant baddatarec(dat) -> result;
        ;;; Check that lengths of offset masks match the network
        lvars i0, i1, j, t, t1, t2, o1, o2, mask, origs, result = false;
        arrayvector_bounds(dat.mlpdata_data) -> i0 -> i1;
        ;;; subtract 1 to allow for zero-offset C indexing
        i0 - 1 -> i0;
        i1 - 1 -> i1;
        dat.mlpdata_offset_mask -> mask;
        dat.mlpdata_mask_origs -> origs;
        origs(1) -> o1;
        origs(dat.mlpdata_negs) -> o2;
        for j from 1 to datalength(mask) do
            mask(j) -> t;
            o1 + t -> t1; o2 + t -> t2;
            if t1 < i0 or t1 > i1 or t2 < i0 or t2 > i1 then
                true -> result;
                quitloop
            endif;
        endfor
    enddefine;

    if stims.mlpdata_ndim == 0 then
        if baddatarec(stims) then
            mishap(0, 'Stimulus data tries to go outside array bounds')
        endif;
        if baddatarec(outputs) then
            mishap(0,
                'Target data/output area tries to go outside array bounds')
        endif;
    endif;

enddefine;

/*
-- Net execution and training -----------------------------------------
*/

define updaterof mlp_target(machine, stims);
    ;;; Updates an "input vector" that can act as a target for a
    ;;; lower layer of machine. Must be called straight after
    ;;; mlp_learn and not straight after mlp_response.
    exacc MLP_intotarg(
        machine.mlp_wtvec,
        machine.mlp_nweights,
        machine.mlp_actvec,
        machine.mlp_ntunits,
        (machine.mlp_nhunits)(1),
        stims.mlpdata_datvec,
        stims.mlpdata_mask_origs,
        stims.mlpdata_ndim,
        stims.mlpdata_negs,
        stims.mlpdata_offset_mask,
        machine.mlp_ninunits)
enddefine;

define updaterof mlp_response(stims, machine, outputs);
    ;;; Propagates the stimuli through the machine, storing the results
    ;;; in the output array
    mlp_checkdata(machine, stims, outputs);

    lvars ifail = exacc MLP_forward(
        stims.mlpdata_datvec,
        stims.mlpdata_mask_origs,
        stims.mlpdata_ndim,
        stims.mlpdata_negs,
        stims.mlpdata_offset_mask,
        machine.mlp_ninunits,
        machine.mlp_nhunits,
        machine.mlp_nlevels,
        machine.mlp_tranfnvec,
        machine.mlp_actvec,
        machine.mlp_bsvec,
        machine.mlp_ntunits,
        machine.mlp_wtvec,
        machine.mlp_nweights,
        outputs.mlpdata_datvec,
        outputs.mlpdata_mask_origs,
        outputs.mlpdata_offset_mask,
        machine.mlp_noutunits);

    if ifail /== 0 then
        mishap(ifail, 1, 'mlp_forward error')
    endif;
enddefine;

define mlp_response(stims, machine) -> outputs;
    lvars
        negs = stims.mlpdata_negs,
        nout = machine.mlp_noutunits;
    mlp_makedata(newanyarray([1 ^nout 1 ^negs], mlpsvec_key)) -> outputs;
    stims, machine -> mlp_response(outputs)
enddefine;

define updaterof mlp_learn(stims, targs, machine) -> (err, errvar);
    ;;; Trains the machine using the given stimulus and target arrays
    ;;; Returns the current error and its variance.
    lconstant
        errp = initmlpsvec(1),
        errvarp = initmlpsvec(1);
    mlp_checkdata(machine, stims, targs);

    lvars ifail = exacc MLP_forback(
        stims.mlpdata_datvec,
        stims.mlpdata_mask_origs,
        stims.mlpdata_ndim,
        stims.mlpdata_negs,
        stims.mlpdata_offset_mask,
        machine.mlp_ninunits,
        machine.mlp_nhunits,
        machine.mlp_nlevels,
        machine.mlp_tranfnvec,
        machine.mlp_actvec,
        machine.mlp_bsvec,
        machine.mlp_ntunits,
        machine.mlp_wtvec,
        machine.mlp_nweights,
        machine.mlp_bschvec,
        machine.mlp_wtchvec,
        machine.mlp_etavec,
        machine.mlp_etbvec,
        machine.mlp_alpha,
        machine.mlp_decay,
        targs.mlpdata_datvec,
        targs.mlpdata_mask_origs,
        targs.mlpdata_offset_mask,
        machine.mlp_noutunits,
        targs.mlpdata_niter,
        targs.mlpdata_nbatch,
        targs.mlpdata_ransel,
        errp,
        errvarp);

    if ifail /== 0 then
        mishap('mlp_forback error',[ifail = ^ifail])
    endif;
    errp(1) -> err;
    errvarp(1) -> errvar
enddefine;

define mlp_learn(/* stims, targs, */ nunits, wtrange, eta)
        -> (machine, err, errvar) with_nargs 6;
    ;;; See mlp_makenet for comments on argument processing
    lvars stims, targs, alpha = 0.0, decay = -1.0;
    getnetargs();
    /* stims, targs */ -> (stims, targs);

    mlp_makenet(stims.mlpdata_nunits, nunits, wtrange, eta, alpha, decay)
        -> machine;
    stims, targs -> mlp_learn(machine) -> (err,errvar);
enddefine;

/*
-- Net printing -------------------------------------------------------
*/

define lconstant mlp_maxunits(machine) /* -> maxunits */;
    ;;; returns the maximum no of units in any layer, not including the
    ;;; input layer
    appdata(0, machine.mlp_nhunits, max)
enddefine;


define mlp_printweights(machine);
    lvars d1=3, d2=3, wlev, i, j, level, maxunits, nlower, ncurrent, blev;
    dlocal poplinemax poplinewidth;
    if isinteger(machine) then
        machine -> d2;
            -> d1;
            -> machine
    endif;
    nl(1);
    (max(machine.mlp_maxunits,machine.mlp_ninunits)+1) * (d1+d2) + 10
        ->> poplinemax -> poplinewidth;
    npr('WEIGHTS');
    pr('         ');
    pr_field('bias',d1+d2,` `,false);
    for i from 1 to max(machine.mlp_maxunits, machine.mlp_ninunits) do
        pr_field(i,d1+d2,` `,false)
    endfor;
    nl(1);
    for level from machine.mlp_nlevels by -1 to 1 do
        (machine.mlp_weights)(level) -> wlev;
        (machine.mlp_biases)(level) -> blev;
        npr('Level ' >< level);
        explode(boundslist(wlev)) -> ( , nlower, , ncurrent);
        for j from 1 to ncurrent do
            pr('unit '); pr_field(j,3,` `,false); pr(': ');
            prnum(blev(j),d1,d2);
            for i from 1 to nlower do
                prnum(wlev(i,j),d1,d2)
            endfor;
            nl(1);
        endfor;
        nl(1);
    endfor
enddefine;

define mlp_printactivs(machine);
    lvars d1=3, d2=3, alev, nuns, i, level, ncurrent;
    dlocal poplinemax poplinewidth;
    if isinteger(machine) then
        machine -> d2;
            -> d1;
            -> machine
    endif;
    machine.mlp_nhunits -> nuns;
    (machine.mlp_maxunits+1) * (d1+d2) + 11 ->> poplinemax -> poplinewidth;
    nl(1);
    npr('ACTIVATIONS');
    pr('          ');
    for i from 1 to machine.mlp_maxunits do
        pr_field(i,d1+d2,` `,false)
    endfor;
    nl(1);
    for level from machine.mlp_nlevels by -1 to 1 do
        (machine.mlp_activs)(level) -> alev;
        explode(boundslist(alev)) -> ( , ncurrent);
        pr('level '); pr_field(level,3,` `,false); pr(': ');
        for i from 1 to ncurrent do
            prnum(alev(i),d1,d2)
        endfor;
        nl(1);
    endfor
enddefine;

/*
-- Net copying --------------------------------------------------------
*/

define mlp_copypart(machine, level, unit1, unit2) -> newmachine;
    ;;; Copies the subtree of the machine below the specified units
    ;;; to a new machine.  Level 1 is the lowest hidden layer.
    lvars lev, nnewunits, accessor, vec, newvec, arr, newarr,
        uniti, unito, iunit, nlowerunits,
        nin = machine.mlp_ninunits,
        nhunits = machine.mlp_nhunits,
        noutunits = unit2-unit1+1;

    {%
        for lev from 1 to level-1 do
            nhunits(lev)
        endfor;
        noutunits %} -> nnewunits;
    mlp_makenet(nin, nnewunits, 0.0, machine.mlp_eta,
        machine.mlp_alpha, machine.mlp_decay)
        -> newmachine;

    for accessor in mlp_vecarr_access do
        machine.accessor -> vec;
        newmachine.accessor -> newvec;

        for arr, newarr with_index vec in_vectorclass vec, newvec do
            if lev < level then
                ;;; Copy the whole array
                arr -> mlp_coparr(newarr)
            elseif lev == level then
                ;;; Copy selected units only for this level
                if level == 1 then
                    nin
                else
                    nhunits(level-1)
                endif -> nlowerunits;
                0 -> unito;
                for uniti from unit1 to unit2 do
                    unito + 1 -> unito;
                    for iunit from 1 to nlowerunits do
                        arr(iunit, uniti) -> newarr(iunit,unito)
                    endfor;
                endfor
            else
                quitloop
            endif
        endfor
    endfor;

    machine.mlp_clamped and "maybe" -> newmachine.mlp_clamped
enddefine;

define updaterof mlp_copypart(net, level, unit1, unit2, dnet, dunit1);
    ;;; Copies the subtree of the net given into the
    ;;; specified units of the destination net - which must be
    ;;; an appropriate size
    lvars lev nnewunits accessor vec dlis arr darr
        uniti unito iunit nlowerunits,
        nin = net.mlp_ninunits,
        nhunits = net.mlp_nhunits;

    for accessor in mlp_vecarr_access do
        net.accessor -> vec;
        dnet.accessor -> dlis;

        0 -> lev;
        for arr, darr in vec, dlis do
            lev + 1 -> lev;
            if lev < level then
                ;;; Copy the whole array
                arr -> mlp_coparr(darr)
            elseif lev == level then
                ;;; Copy selected units only for this level
                if level == 1 then
                    nin
                else
                    nhunits(level-1)
                endif -> nlowerunits;
                dunit1 -> unito;
                for uniti from unit1 to unit2 do
                    for iunit from 1 to nlowerunits do
                        arr(iunit, uniti) -> darr(iunit,unito)
                    endfor;
                    unito + 1 -> unito;
                endfor
            else
                quitloop
            endif
        endfor
    endfor;

    if net.mlp_clamped == true then
        true
    elseif dnet.mlp_clamped or net.mlp_clamped == "maybe" then
        "maybe"
    else
        net.mlp_clamped
    endif -> dnet.mlp_clamped;
enddefine;

/*
-- Miscellaneous and experimental -------------------------------------
*/

define updaterof mlp_set_eta(rho, error, net);
    ;;; Update eta for a net to try to make the change in error on
    ;;; each presentation equal to rho times the current error.
    ;;; Depends on the past history: error must be an estimate of
    ;;; the current mean error of the network, and it must have been
    ;;; trained for long enough at the current value of eta for the
    ;;; wtchange arrays to have stabilised.
    ;;; Also updates the wtchange arrays to the values they would
    ;;; have had if eta had been its new value.
    lvars sumsqu ratio,
        eta = net.mlp_eta,
        wtchvec = net.mlp_wtchvec,
        bschvec = net.mlp_bschvec,
        nweights = net.mlp_nweights;
    mlp_sumsquares(wtchvec) + mlp_sumsquares(bschvec) -> sumsqu;
    rho * eta * error / sumsqu -> ratio;
    ratio * eta -> net.mlp_eta;
    ratio -> mlp_scalevec(wtchvec);
    ratio -> mlp_scalevec(bschvec)
enddefine;

global vars mlp = true;       ;;; for uses

endsection;

/* --- Revision History ---------------------------------------------------
--- David Young, Mar  2 2000
        Moved from Sussex local vision libraries to popvision.
--- David Young, Dec  6 1999
        In mlp_learn, put missing decay argument into call to mlp_makenet.
--- David S Young, Aug 28 1998
        Made vectors of arrays writeable again to allow datainout to work.
--- David S Young, Aug 26 1998
        Added batch learning and weight decay.
--- David S Young, Aug 20 1998
        Changed lists of arrays to non-writeable vectors of arrays.
--- David S Young, Aug 18 1998
        Added +strict compile mode and made some procedures lconstant.
 */
