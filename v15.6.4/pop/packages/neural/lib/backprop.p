/* --- Copyright University of Sussex 1988. All rights reserved. ----------
 > File:            $popneural/lib/backprop.p
 > Purpose:         PDP feed-forward networks with back-propagation learning
 > Author:          David Young, Dec  7 1988
 > Documentation:   $popneural/ref/backprop
 > Related Files:   backprop.f, backprop.o, backcomp, backfordef.p,
                    ranvecs.f and its relatives
 */

section;

/* POP-11 interface to Fortran implementation */

uses ranvecs;
uses netfileutil;
uses backcdef;


/* A network record just has the following:

a name for the network
a list of the weight arrays (one element per level)
the combined weight array
a list of the weight change arrays
the combined weight change array
a list of the bias arrays
the combined bias array
a list of the bias change arrays
the combined bias change array
a list of the activation arrays
the combined activation array
the no of input units
an array giving the numbers of units per layer from the lowest
    hidden layer to the output layer
the no of output units
eta, the learning rate
alpha, the learning inertia
the no of levels
the total no of weights
the total no of units (not counting input units)
an array of the last input to the net
the number of training patterns presented

*/

recordclass bpropnet
            bpnetwork_name
            bpweights bpwtarr
            bpwtchange bpwtcharr
            bpbiases bpbsarr
            bpbschange bpbscharr
            bpactivs bpactarr
            bpninunits bpnhunits bpnoutunits
            bpeta bpalpha
            bpnlevels
            bpnweights
            bpntunits
            bpinputarr
            bppatterns;


define updaterof updater_coerce(type,proc);
    ;;; updates the updater of the procedure proc so that it subsequently
    ;;; coerces values to the type of 'type'. The updater must take just
    ;;; two arguments.
    lvars proc type;
    lvars orig_updater = updater(proc);
    unless pdnargs(orig_updater) == 2 then
        mishap('Updater must take exactly 2 arguments', [^proc])
    endunless;

    procedure(value,target); lvars value target;
        orig_updater(number_coerce(value,type),target)
    endprocedure -> updater(proc)
enddefine;

0.0s0 ->> updater_coerce(bpeta) -> updater_coerce(bpalpha);
false ->> updater(bpninunits) ->> updater(bpnhunits)
      ->> updater(bpnoutunits) ->> updater(bpnlevels)
      ->> updater(bpnweights) -> updater(bpntunits);

define actarrtolist(array,nunits) /* -> list */;
    ;;; Returns a list of separate level
    ;;; arrays mapped onto an activations array
    lvars array nunits;
    lvars list ncurrent level cpos;
    [] -> list;
    0 -> cpos;
    for level from 1 to length(nunits) do
        nunits(level) -> ncurrent;
        newanyarray([1 ^ncurrent],array,cpos) :: list -> list;
        cpos + ncurrent -> cpos
    endfor;
    ncrev(list)
enddefine;

define actarrlist(nunits,ntunits) /* -> arr -> list */;
    ;;; Returns an array and also a list of separate level
    ;;; arrays mapped onto it
    lvars nunits ntunits;
    lvars array;
    array_of_double([1 ^ntunits]) -> array;
    actarrtolist(array,nunits), array    ;;; left on stack in this order
enddefine;


define wtarrtolist(array,nin,nunits) /* -> list */;
    ;;; Like actarrtolist but for weights etc
    lvars array nin nunits;
    lvars list ncurrent nlower level cpos;
    [] -> list;
    0 -> cpos;
    nin -> nlower;
    for level from 1 to length(nunits) do
        nunits(level) -> ncurrent;
        newanyarray([1 ^nlower 1 ^ncurrent],array,cpos) :: list -> list;
        cpos + ncurrent * nlower -> cpos;
        ncurrent -> nlower
    endfor;
    ncrev(list)
enddefine;

define wtarrlist(nin,nunits,nweights) /* -> arr -> list */;
    ;;; Like actarrlist but for weights etc
    lvars nin nunits nweights;
    lvars array;
    array_of_double([1 ^nweights]) -> array;
    wtarrtolist(array,nin,nunits), array
enddefine;

define global make_bpnet(nin, nunits, wtrange, et, al) -> network;
    ;;; nin is the the of input units
    ;;; nunits is the no of units in each layer, numbered from 1 upwards,
    ;;; starting at the lowest hidden layer, and including the
    ;;; output units but not the input units.
    ;;; The weights get set randomly - wtrange determines the range.
    lvars nin nunints wtrange et al network;
    lvars level nlevels ntunits nweights nlower ncurrent
         wtarr wtcharr bsarr bscharr actarr;
    lconstant realnumber = 0.0s0;
    length(nunits) -> nlevels;
    0 ->> ntunits -> nweights;
    nin -> nlower;
    for level from 1 to nlevels do
        nunits(level) -> ncurrent;
        ntunits + ncurrent -> ntunits;
        nweights + ncurrent*nlower -> nweights;
        ncurrent -> nlower
    endfor;
    consbpropnet(
        'Back propagation network',
        wtarrlist(nin,nunits,nweights),
        wtarrlist(nin,nunits,nweights),
        actarrlist(nunits,ntunits),
        actarrlist(nunits,ntunits),
        actarrlist(nunits,ntunits),
        nin,
        array_of_int([1 ^nlevels],subscrv(%nunits%)),
        ;;; consintvec(explode(nunits), nlevels),
        nunits(nlevels),
        number_coerce(et,realnumber), number_coerce(al,realnumber),
        nlevels, nweights, ntunits, array_of_double([1 ^nin]), 0)
        -> network;
    ;;; set initial weights randomly
    if wtrange > 0 then
        ranuvec(network.bpwtarr,nweights,-wtrange/2.0, wtrange/2.0);
        ranuvec(network.bpbsarr, ntunits, -wtrange/2.0, wtrange/2.0)
    endif
enddefine;

define global bp_checkvecs(network,invec,outvec,targ);
    ;;; Mishaps if the vectors are inadequate for the network.
    ;;; Should be called before bp_response or bp_learn, but not every
    ;;; time.
    lvars network invec outvec targ;

    unless datalength(invec) >= network.bpninunits then
        mishap('input array too short',[^invec])
    endunless;
    unless datalength(outvec) >= network.bpnoutunits then
        mishap('output array too short',[^outvec])
    endunless;
    unless datalength(targ) >= network.bpnoutunits then
        mishap('target vector too short',[^targ])
    endunless;
enddefine;

define global bp_response(invec,network,outvec);
    lconstant ifail_ptr = writeable array_of_int([1 1]);
    lvars invec network outvec;
    lvars i ifail = 0;        ;;; non-checking!   ;;; change 0 to 1 here
                            ;;; and uncomment 3 lines below if there is
                            ;;; any doubt about the setup.

    fast_for i from 1 to network.bpninunits do
        invec(i) -> bpinputarr(network)(i);
    endfast_for;
    ifail -> ifail_ptr(1);
    fprop(invec,    network.bpninunits,
        network.bpnhunits,  network.bpnlevels,
        network.bpactarr,   network.bpbsarr,    network.bpntunits,
        network.bpwtarr,    network.bpnweights,
        outvec,     network.bpnoutunits,
        ;;; ident ifail);
        ifail_ptr);
    if (ifail_ptr(1) ->> ifail) /== 0 then
        mishap('fprop error',[ifail = ^ifail])
    endif;
enddefine;


define global bp_response_set(/* stepsize, */ input_set,network,outvecs);
    ;;; Applies the network to a load of examples and stores the
    ;;; results in the outvecs array.
    ;;; If input_set is 1-D, then treat it as a continuous vector
    ;;; with possibly overlapping inputs; expect to find
    ;;; another value on the stack giving the step size.
    lvars input_set network outvecs;
    lvars stepsize nstims nin nout bs bt negs i ifail = 1;
    lconstant ifail_ptr = writeable array_of_int([1 1]);

    ;;; do some checking now
    boundslist(input_set) -> bs;
    boundslist(outvecs) -> bt;
    network.bpninunits -> nin;
    network.bpnoutunits -> nout;
    if length(bt) == 4 then
        unless bt(2) - bt(1) + 1 == nout then
            mishap('outputs wrong length',[^outvecs])
        endunless;
        bt(4) - bt(3) + 1 -> negs;
    elseif length(bt) == 2 then
        unless (bt(2) - bt(1) + 1) mod nout == 0 then
            mishap('outputs wrong length',[^outvecs])
        endunless;
        (bt(2) - bt(1) + 1) div nout -> negs;
    else
        mishap(outvecs, 1, 'output array has wrong dimension');
    endif;


    if length(bs) == 4 then     ;;; Input is set of disjoint examples
        unless bs(2) - bs(1) + 1 == nin then
            mishap('inputs wrong length for network',[^input_set])
        endunless;
        unless bs(4) - bs(3) + 1 == negs then
            mishap('different no of egs in stim & output arrays',[^bs ^bt])
        endunless;
        ;;; Treat as 1-D array to avoid having too many Fortran procedures
        nin * negs -> nstims;
        newanyarray([1 ^nstims], input_set) -> input_set;
        nin -> stepsize
    elseif length(bs) == 2 then     ;;; Overlapping inputs in a vector
            -> stepsize;            ;;; stepsize should be on the stack
        bs(2) - bs(1) + 1 -> nstims;
        if nstims < ((negs-1) * stepsize + nin) then
            mishap('input array too short compared to output array',[^input_set])
        endif;
    else
        mishap('need 1- or 2-D array',[^input_set])
    endif;
    ;;; copy first example to network
    fast_for i from 1 to nin do
        input_set(i) -> bpinputarr(network)(i);
    endfast_for;
    ifail -> ifail_ptr(1);
    fpropseq
    (
        input_set, nstims, stepsize, nin, negs,
        network.bpnhunits,     network.bpnlevels,
        network.bpactarr,
        network.bpbsarr,       network.bpntunits,
        network.bpwtarr,       network.bpnweights,
        outvecs, nout,         ifail_ptr
    );

    if (ifail_ptr(1) ->> ifail) /== 0 then
        mishap('fpropseq error',[ifail = ^ifail])
    endif;
enddefine;


define global bp_learn(invec,targvec,network);
    lconstant ifail_ptr = writeable array_of_int([1 1]);
    lvars invec targvec network;
    lvars i ifail = 0;        ;;; non-checking!

    fast_for i from 1 to network.bpninunits do
        invec(i) -> bpinputarr(network)(i);
    endfast_for;
    ifail -> ifail_ptr(1);
    bprop(targvec, network.bpnoutunits,
        network.bpnhunits,   network.bpnlevels,
        network.bpactarr,
        network.bpbsarr,    network.bpbscharr,  network.bpntunits,
        network.bpwtarr,    network.bpwtcharr,  network.bpnweights,
        network.bpeta,      network.bpalpha,
        invec,  network.bpninunits,
        ifail_ptr);

    if (ifail_ptr(1) ->> ifail) /== 0 then
        mishap('bprop error',[ifail = ^ifail])
    endif;
enddefine;

define global bp_backinvec(network,invec);
    ;;; Updates an "input vector" that can act as a target for a
    ;;; lower layer of network. Must be called straight after
    ;;; bp_learn and not straight after bp_response or
    ;;; bp_response_set.
    lvars network invec;
    bpin(network.bpwtarr,   network.bpnweights,
        network.bpactarr,   network.bpntunits,
        (network.bpnhunits)(1),
        invec,     network.bpninunits)
enddefine;

define global bp_learn_set(/* stepsize, */ stims,targs,niter,cycle,network,outvec);
    ;;; Trains the network using the arrays of stimuli and targets in
    ;;; stims and targs. Does niter presentations (of individual
    ;;; stimuli). If cycle is true the stimuli are presented in
    ;;; rotation; otherwise they're selected at random.
    ;;; If stims is a 1-D array, treats it as a vector, expects to
    ;;; find stepsize on the stack in front of it, and presents
    ;;; possibly overlapping examples from it.
    ;;;    lvars stims targs niter cycle network outvec;
    lvars stims targs niter cycle network outvec;
    lvars stepsize nstims nin nout bs bt negs i ifail = 1;
    lconstant ifail_ptr = writeable array_of_int([1 1]);

    ;;; do some checking now
    boundslist(stims) -> bs;
    boundslist(targs) -> bt;
    network.bpninunits -> nin;
    network.bpnoutunits -> nout;

    unless datalength(outvec) >= nout then
        mishap('output array too short',[^outvec])
    endunless;

    if length(bt) == 4 then
        unless bt(2) - bt(1) + 1 == nout then
            mishap('targets wrong length',[^targs])
        endunless;
        bt(4) - bt(3) + 1 -> negs;
    elseif length(bt) == 2 then
        unless (bt(2) - bt(1) + 1) mod nout == 0 then
            mishap('targetss wrong length',[^targs])
        endunless;
        (bt(2) - bt(1) + 1) div nout -> negs;
    else
        mishap(targs, 1, 'targets array has wrong dimension');
    endif;


    if length(bs) == 4 then     ;;; Input is set of disjoint examples
        unless bs(2) - bs(1) + 1 == nin then
            mishap('inputs wrong length for network',[^stims])
        endunless;
        unless bs(4) - bs(3) + 1 == negs then
            mishap('different no of egs in stim & targ arrays',[^bs ^bt])
        endunless;
        negs * nin -> nstims;
        newanyarray([1 ^nstims], stims) -> stims;
        nin -> stepsize;
    elseif length(bs) == 2 then     ;;; Overlapping inputs in a vector
            -> stepsize;            ;;; stepsize should be on the stack
        bs(2) - bs(1) + 1 -> nstims;
        if nstims < ((negs-1) * stepsize + nin) then
            mishap('input array too short compared to target array',[^stims])
        endif;
        else
        mishap('need 1- or 2-D array',[^stims])
    endif;

    ;;; copy first example to network
    fast_for i from 1 to nin do
        stims(i) -> bpinputarr(network)(i);
    endfast_for;
    ifail -> ifail_ptr(1);
    ;;; Put args on stack now as there are so many of them
    (
        niter, targs, nout, negs,
        stims, nstims, stepsize, nin,
        network.bpnhunits,   network.bpnlevels,
        network.bpactarr,
        network.bpbsarr,    network.bpbscharr,  network.bpntunits,
        network.bpwtarr,    network.bpwtcharr,  network.bpnweights,
        network.bpeta,      network.bpalpha,
        outvec, ifail_ptr
    );
    ;;; and call the right procedure on them
    if cycle then .bplearnseqc else .bplearnseqr endif;

    if (ifail_ptr(1) ->> ifail) /== 0 then
        mishap('bplearn error',[ifail = ^ifail])
    endif;
enddefine;


define global bp_maxunits(network) -> maxunits;
    ;;; returns the maximum no of units in any layer, not including the
    ;;; input layer
    lvars network maxunits;
    lvars i nuns;
    network.bpnhunits -> nuns;
    0 -> maxunits;
    for i from 1 to network.bpnlevels do
        if nuns(i) > maxunits then nuns(i) -> maxunits endif
    endfor
enddefine;


define global pr_bpweights(network);
    lvars network;
    lvars d1=3, d2=3, wlev, i, j, level, maxunits, nlower, ncurrent, blev;
    dlocal poplinemax poplinewidth;
    if isinteger(network) then
        network -> d2;
            -> d1;
            -> network
    endif;
    nl(1);
    (max(network.bp_maxunits,network.bpninunits)+1) * (d1+d2) + 10
        ->> poplinemax -> poplinewidth;
    npr('WEIGHTS');
    pr('         ');
    pr_field('bias',d1+d2,` `,false);
    for i from 1 to max(network.bp_maxunits, network.bpninunits) do
        pr_field(i,d1+d2,` `,false)
    endfor;
    nl(1);
    network.bpnlevels -> level;
    for wlev, blev in rev(network.bpweights), rev(network.bpbiases) do
        npr('Level ' >< level);
        explode(boundslist(wlev)) -> ncurrent -> -> nlower ->;
        for j from 1 to ncurrent do
            pr('unit '); pr_field(j,3,` `,false); pr(': ');
            prnum(blev(j),d1,d2);
            for i from 1 to nlower do
                prnum(wlev(i,j),d1,d2)
            endfor;
            nl(1);
        endfor;
        nl(1);
        level - 1 -> level
    endfor
enddefine;

define global pr_bpactivs(network);
    lvars network;
    lvars d1=3, d2=3, alev, nuns, i, level, ncurrent;
    dlocal poplinemax poplinewidth;
    if isinteger(network) then
        network -> d2;
            -> d1;
            -> network
    endif;
    network.bpnhunits -> nuns;
    (network.bp_maxunits+1) * (d1+d2) + 11 ->> poplinemax -> poplinewidth;
    nl(1);
    npr('ACTIVATIONS');
    pr('          ');
    for i from 1 to network.bp_maxunits do
        pr_field(i,d1+d2,` `,false)
    endfor;
    nl(1);
    network.bpnlevels -> level;
    for alev in rev(network.bpactivs) do
        explode(boundslist(alev)) -> ncurrent -> ;
        pr('level '); pr_field(level,3,` `,false); pr(': ');
        for i from 1 to ncurrent do
            prnum(alev(i),d1,d2)
        endfor;
        nl(1);
        level - 1 -> level
    endfor
enddefine;


define global bp_save(filename,machine) -> result;
    ;;; Stores a backprop network in a file
    ;;; Writes an ascii header to make it easier to inspect the file.
    ;;; Dumps arrays in binary to save space.
    ;;; Simply returns false if a problem (as requested by ISL)
    ;;; rather than mishapping.

    lvars machine filename result = true;

    dlocal prmishap =
        procedure(str, list);
            lvars str list;
            npr(';;; MISHAP - BP_SAVE ERROR : ' >< str);
            false; exitfrom(bp_save)
        endprocedure;

    lvars i nuns = machine.bpnhunits, dev = syscreate(filename,1,true);

    wtvarstring(dev,'bpropnet\n');
    wtvarstring(dev,machine.bpnetwork_name);
    devstring(dev,'\ninput units:  ');
    putnum(dev,machine.bpninunits);
    devstring(dev,'\nno levels:    ');
    putnum(dev,machine.bpnlevels);
    devstring(dev,'\nhigher units: ');
    for i from 1 to machine.bpnlevels do
        devstring(dev,'level ' sys_>< i);
        putnum(dev,nuns(i))
    endfor;
    devstring(dev,'\neta:          ');
    putnum(dev,machine.bpeta);
    devstring(dev,'\nalpha:        ');
    putnum(dev,machine.bpalpha);
    devstring(dev,'\ntotal no wts: ');
    putnum(dev,machine.bpnweights);
    devstring(dev,'\ntot no units: ');
    putnum(dev,machine.bpntunits);
    devstring(dev,'\nWeight, wtchange, bias, bschange & activation arrays \
follow in binary without gaps. Values are real*4 and read from input towards \
output. For wts, unit nearest input changes fastest. \n');
    devarrvec(dev,machine.bpwtarr);
    devarrvec(dev,machine.bpwtcharr);
    devarrvec(dev,machine.bpbsarr);
    devarrvec(dev,machine.bpbscharr);
    devarrvec(dev,machine.bpactarr);
    devstring(dev,'\npatterns:     ');
    putnum(dev,machine.bppatterns);

    sysclose(dev);
enddefine;


define global bp_load(filename) -> machine;
    ;;; Restore a network saved using bp_save
    ;;; If the filename is a device, it is assumed that the first line,
    ;;; identifying the file as a backprop machine, has been read and is
    ;;; OK.

    lvars machine filename;
    lvars i dev nlevels nin nhunits eta alpha name nweights ntunits;

    dlocal prmishap =
        procedure(str,list);
            lvars str list;
            npr(';;; MISHAP - BP_LOAD ERROR : ' >< str);
            false; exitfrom(bp_load)
        endprocedure;

    if isdevice(filename) then
        filename -> dev
    else
        sysopen(filename,0,true) -> dev;
        rdvarstring(dev) -> name;
        unless name = 'bpropnet\n' then
            mishap('NOT BACK PROPAGATION NETWORK',[])
        endunless
    endif;

    rdvarstring(dev) -> name;
    dev -> devstring('\ninput units:  ');
    getnum(dev) -> nin;
    dev -> devstring('\nno levels:    ');
    getnum(dev) -> nlevels;
    dev -> devstring('\nhigher units: ');
    initv(nlevels) -> nhunits;
    for i from 1 to nlevels do
        dev -> devstring('level ' sys_>< i);
        getnum(dev) -> nhunits(i)
    endfor;
    dev -> devstring('\neta:          ');
    getnum(dev) -> eta;
    dev -> devstring('\nalpha:        ');
    getnum(dev) -> alpha;
    dev -> devstring('\ntotal no wts: ');
    getnum(dev) -> nweights;
    dev -> devstring('\ntot no units: ');
    getnum(dev) -> ntunits;
    dev -> devstring('\nWeight, wtchange, bias, bschange & activation arrays \
follow in binary without gaps. Values are real*4 and read from input towards \
output. For wts, unit nearest input changes fastest. \n');

    make_bpnet(nin,nhunits,0.0,eta,alpha) -> machine;

    unless machine.bpnweights == nweights and
        machine.bpntunits == ntunits then
        mishap('MISMATCH BETWEEN NETWORK AND FILE',[])
    endunless;

    name -> machine.bpnetwork_name;
    dev -> devarrvec(machine.bpwtarr);
    dev -> devarrvec(machine.bpwtcharr);
    dev -> devarrvec(machine.bpbsarr);
    dev -> devarrvec(machine.bpbscharr);
    dev -> devarrvec(machine.bpactarr);
    dev -> devstring('\npatterns:     ');
    getnum(dev) -> machine.bppatterns;

    sysclose(dev);
enddefine;

global vars backprop = true;

endsection;

/*  --- Revision History --------------------------------------------------
Julian Clinton, 6/7/93
    Changed array_of_int to initintvec as array_of_int gives incorrect
    results on DECstation with newexternal.
Julian Clinton, 1/7/93
    Changed to use array_of_int (for C) rather than array_of_integer
    (for Fortran).
Julian Clinton, 18/6/92
    Modified bp_response_set and bp_learn_set so that it can
    take a 1-D array.
Julian Clinton, 11/5/92
    Made pr_* and bp_* global.
*/
