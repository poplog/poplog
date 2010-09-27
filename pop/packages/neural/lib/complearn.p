/* --- Copyright University of Sussex 1988. All rights reserved. ----------
 > File:            $popneural/lib/complearn.p
 > Purpose:         Feed-forward networks with competitive learning
 > Author:          David Young, Dec  7 1988
 > Documentation:   $popneural/ref/complearn
 > Related Files:   complearn.f, complearn.o, compcomp, compfordef.p,
                    ranvecs.f and its relatives
 */

section;

/* POP-11 interface to Fortran implementation */

uses ranvecs;
uses netfileutil;
uses compcdef;

/* A network record just has the following:

a name for the network
a list of lists of the weight arrays (by layer then by cluster)
the combined weight array
a list of lists of the bias arrays
the combined bias array
a list of lists of the activation arrays
the combined activation array
the output vector (part of the activation array)
the no of input units
an array giving the number of units per layer from the lowest
    hidden layer to the output layer
an array giving the number of units per cluster
an array giving the number of clusters per layer
the no of output units
gw the learning rate for winning units
gl the learning rate for losing units (-ve for none)
rw the sensitivity change rate for winning units
rl the sensitivity change rate for losing units (-ve for none)
the no of levels
the total no of clusters
the total no of weights
the total no of units (not counting input units)
an array of the last input to the net
the number of training patterns presented

*/

recordclass clearnnet
            clnetwork_name
            clweights clwtarr
            clbiases clbsarr
            clactivs clactarr
            cloutvec
            clninunits clnhunits
            clclusters clclustlev
            clnoutunits
            clgw clgl clrw clrl
            clnlevels
            clnclusters
            clnweights
            clntunits
            clinputarr
            clpatterns;

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

0.0s0 ->> updater_coerce(clgw) ->> updater_coerce(clgl)
      ->> updater_coerce(clrw) -> updater_coerce(clrl);

false ->> updater(clninunits) ->> updater(clnhunits)
      ->> updater(clclusters) ->> updater(clclustlev)
      ->> updater(clnoutunits) ->> updater(clnlevels)
      ->> updater(clnclusters) ->> updater(clnweights)
      -> updater(clntunits);


define clactarrtolist(array,nunits) /* -> list */;
    ;;; Returns a list of lists of separate level
    ;;; arrays mapped onto an activations array
    lvars array nunits;
    lvars ncurrent level cluster cpos clev;
    0 ->> cpos -> cluster;
    [%
         for level from 1 to length(nunits) do
             nunits(level) -> clev;
             [%
                  for cluster from 1 to length(clev) do
                      clev(cluster) -> ncurrent;
                      newanyarray([1 ^ncurrent],array,cpos);    ;;; on stack
                      cpos + ncurrent -> cpos
                  endfor
                  %]
         endfor
         %]
enddefine;

define clactarrlist(nunits,ntunits) /* -> arr -> list */;
    ;;; Returns an array and also a list of lists of cluster
    ;;; arrays mapped onto it
    lvars nunits ntunits;
    lvars array;
    array_of_double([1 ^ntunits]) -> array;
    clactarrtolist(array,nunits), array    ;;; left on stack in this order
enddefine;

define clwtarrtolist(array,nin,nunits) /* -> list */;
    ;;; Returns a list of lists of separate level
    ;;; arrays mapped onto a weights array
    lvars array nin nunits;
    lvars ncurrent level cluster cpos nlower clev ninlev;
    0 ->> cpos -> cluster;
    nin -> nlower;
    [%
         for level from 1 to length(nunits) do
             nunits(level) -> clev;
             0 -> ninlev;
             [%
                  for cluster from 1 to length(clev) do
                      clev(cluster) -> ncurrent;
                      newanyarray([1 ^nlower 1 ^ncurrent],array,cpos);    ;;; on stack
                      cpos + nlower * ncurrent -> cpos;
                      ninlev + ncurrent -> ninlev
                  endfor
                  %];
             ninlev -> nlower
         endfor
         %]
enddefine;

define clwtarrlist(nin,nunits,nweights) /* -> arr -> list */;
    ;;; Like clactarrlist but for weights etc
    lvars nin nunits nweights;
    lvars array;
    array_of_double([1 ^nweights]) -> array;
    clwtarrtolist(array,nin,nunits), array
enddefine;

define global cl_specs(nin,nunits) -> clusters -> nclusters -> clustlev
        -> ntunits -> nweights -> nhunits -> nlevels;
    ;;; Flattens the nunits spec to make it suitable for passing out
    ;;; to the fortran routines.
    ;;; nclusters is the total no of clusters, clusters is an array
    ;;; giving the no of units in each cluster and clustlev is an
    ;;; array giving the no of clusters in each level.
    ;;; ntunits is the total no of units, nweights the total no of
    ;;; weights, and nhunits an array of the no of units in each level.
    lvars nunits clusters nclusters clustlev ntunits nweights nhunits
         nlevels;
    lvars level ncl cluster cinl nlower ncurrent ninl;

    length(nunits) -> nlevels;
    array_of_int([1 ^nlevels]) -> clustlev;
    0 -> nclusters;
    for level from 1 to nlevels do
        length(nunits(level)) -> ncl;
        nclusters + ncl -> nclusters;
        ncl -> clustlev(level)
    endfor;

    array_of_int([1 ^nclusters]) -> clusters;
    array_of_int([1 ^nlevels]) -> nhunits;
    0 ->> cluster ->> ntunits -> nweights;
    nin -> nlower;
    for level from 1 to nlevels do
        0 -> ninl;
        nunits(level) -> cinl;
        for ncl from 1 to length(cinl) do
            cluster + 1 -> cluster;
            cinl(ncl) -> ncurrent;
            ncurrent -> clusters(cluster);
            ncurrent + ninl -> ninl
        endfor;
        ninl -> nhunits(level);
        ntunits + ninl -> ntunits;
        nweights + ninl * nlower -> nweights;
        ninl -> nlower
    endfor
enddefine;

define global cl_getoutvec(actarr,nunits,ntunits) /* -> outvec */;
    lvars actarr nunits ntunits;
    lvars ntop;
    nunits(length(nunits)) -> ntop;
    newanyarray([1 ^ntop],actarr,ntunits-ntop)
enddefine;

define global make_clnet(nin, nunits, gw, gl, rw, rl) -> network;
    ;;; nin is the the of input units
    ;;; nunits is a list of lists describing the network structure,
    ;;; not including input units. Each element of nunits is for
    ;;; one layer, and each element of one of these lists is the number
    ;;; of units in one cluster in that layer.
    ;;; The weights get set randomly.
    lvars nin nunints gw gl rw rl network;
    lvars clusters nclusters clustlev ntunits nweights nhunits nlevels
         activs actarr biases bsarr outvec;
    lconstant realnumber = 0.0s0;

    cl_specs(nin,nunits) -> clusters -> nclusters -> clustlev
        -> ntunits -> nweights -> nhunits -> nlevels;

    unless gw then -1.0s0 -> gw endunless;
    unless gl then -1.0s0 -> gl endunless;
    unless rl and rw then -1.0s0 -> rl endunless;
    unless rw then -1.0s0 -> rw endunless;

    clactarrlist(nunits,ntunits) -> bsarr -> biases;
    clactarrlist(nunits,ntunits) -> actarr -> activs;
    cl_getoutvec(actarr,nhunits,ntunits) -> outvec;

    ;;; This is what a network has:
    ;;; nn_cl_networkname
    ;;; clweights clwtarr
    ;;; clbiases clbsarr
    ;;; clactivs clactarr
    ;;; cloutvec
    ;;; clninunits clnhunits clclusters clclustlev clnoutunits
    ;;; clgw clgl clrw clrl
    ;;; clnlevels clnclusters clnweights clntunits;

    consclearnnet(
        'Competitive learning network',
        clwtarrlist(nin,nunits,nweights),
        biases, bsarr,
        activs, actarr,
        outvec,
        nin, nhunits, clusters, clustlev, nhunits(nlevels),
        number_coerce(gw,realnumber), number_coerce(gl,realnumber),
        number_coerce(rw,realnumber), number_coerce(rl,realnumber),
        nlevels, nclusters, nweights, ntunits,
        array_of_double([1 ^nin]),0)
        -> network;

    ;;; set initial weights randomly and normalise them
    ranuvec(network.clwtarr,nweights,0.0s0,100.0s0);
    clnorm(network.clwtarr,nweights,nin,nhunits,nlevels);
enddefine;


define global cl_response(invec,network,outvec);
    lconstant ifail_ptr = writeable array_of_int([1 1]);
    lvars invec machine outvec;
    lvars i ifail = 0;        ;;; non-checking!   ;;; change 0 to 1 here
    ;;; and uncomment 3 lines below if there is
    ;;; any doubt about the setup.
    fast_for i from 1 to network.clninunits do
        invec(i) -> clinputarr(network)(i);
    endfast_for;
    ifail -> ifail_ptr(1);
    cprop(invec,    network.clninunits,
        network.clnhunits,  network.clnlevels,
        network.clactarr,   network.clbsarr,    network.clntunits,
        network.clwtarr,    network.clnweights,
        network.clclusters, network.clnclusters, network.clclustlev,
        outvec, network.clnoutunits,
        ifail_ptr);
    if (ifail_ptr(1) ->> ifail) /== 0 then
        mishap('clresponse error',[ifail = ^ifail])
    endif;
enddefine;


define global cl_response_set(/* stepsize, */ invecs,network,outvecs);
    lconstant ifail_ptr = writeable array_of_int([1 1]);
    ;;; Like cl_response but for a set of inputs and outputs.
    ;;; If invecs is 1-D then looks for a stepsize on the stack and
    ;;; goes along taking sequences from invecs starting every
    ;;; stepsize elements. If invecs is 2-D then takes each column
    ;;; as a separate input.
    lvars invecs network outvecs;
    lvars stepsize nstims negs nin nout bs bt negs i ifail = 1;

    ;;; do some checking now
    boundslist(invecs) -> bs;
    boundslist(outvecs) -> bt;
    network.clninunits -> nin;
    network.clnoutunits -> nout;
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

    if length(bs) == 4 then
        unless bs(2) - bs(1) + 1 == nin then
            mishap('inputs wrong length',[^invecs])
        endunless;
        unless bs(4) - bs(3) + 1 == negs then
            mishap('nos of inputs and outputs don\'t match',[^bs ^bt])
        endunless;
        nin * negs -> nstims;
        newanyarray([1 ^nstims], invecs) -> invecs;
        nin -> stepsize;
    elseif length(bs) == 2 then
            -> stepsize;            ;;; must be on stack
        bs(2) - bs(1) + 1 -> nstims;
        if nstims < ((negs-1) * stepsize + nin) then
            mishap('input array too short',[^invecs])
        endif
    else
        mishap('needs 1- or 2-D array',[^invecs])
    endif;

    ;;; copy first example to network
    fast_for i from 1 to nin do
        invecs(i) -> clinputarr(network)(i);
    endfast_for;
    ifail -> ifail_ptr(1);
    ;;; Put args on stack now as there are so many of them
    cpropseq
    (
        invecs, nstims, stepsize, nin, negs,
        network.clnhunits,   network.clnlevels,
        network.clactarr, network.clbsarr,  network.clntunits,
        network.clwtarr, network.clnweights,
        network.clclusters, network.clnclusters, network.clclustlev,
        outvecs, nout,
        ifail_ptr
    );

    if (ifail_ptr(1) ->> ifail) /== 0 then
        mishap('clpropseq error',[ifail = ^ifail])
    endif;
enddefine;


define global cl_learn(invec,targvec,network);
    lconstant ifail_ptr = writeable array_of_int([1 1]);
    lvars invec network targvec;
    lvars i ifail = 0;        ;;; non-checking!   ;;; change 0 to 1 here
    ;;; and uncomment 3 lines below if there is
    ;;; any doubt about the setup.

    fast_for i from 1 to network.clninunits do
        invec(i) -> clinputarr(network)(i);
    endfast_for;
    ifail -> ifail_ptr(1);
    clearn(invec,    network.clninunits,
        network.clnhunits,  network.clnlevels,
        network.clactarr,   network.clbsarr,    network.clntunits,
        network.clwtarr,    network.clnweights,
        network.clclusters, network.clnclusters, network.clclustlev,
        network.clgw, network.clgl, network.clrw, network.clrl,
        ifail_ptr);
    if (ifail_ptr(1) ->> ifail) /== 0 then
        mishap('cllearn error',[ifail = ^ifail])
    endif;
enddefine;


define global cl_learn_set(/* stepsize, */ stims,targs,niter,cycle,network,outvec);
    ;;; Trains the network using the arrays of stimuli and targets in
    ;;; stims and targs. Does niter presentations (of individual
    ;;; stimuli). If cycle is true the stimuli are presented in
    ;;; rotation; otherwise they're selected at random.

    ;;; If stims is a 1-D array then expects to find a stepsize argument
    ;;; on the stack.  Then stimuli are taken from stims starting every
    ;;; stepsize elements, overlapping if stepsize is less than the
    ;;; number of input units.
    lconstant ifail_ptr = writeable array_of_int([1 1]);
    lvars stims niter cycle network;
    lvars targs outvec;
    lvars stepsize nstims nin nout bs bt i ifail = 1;

    ;;; do some checking now
    boundslist(stims) -> bs;
    network.clninunits -> nin;
    network.clnoutunits -> nout;

    if length(bs) == 4 then
        unless bs(2) - bs(1) + 1 == nin then
            mishap('inputs wrong length',[^stims])
        endunless;
        (bs(4) - bs(3) + 1) * nin -> nstims;
        newanyarray([1 ^nstims], stims) -> stims;
        nin -> stepsize
    elseif length(bs) == 2 then
            -> stepsize;        ;;; expected on stack
        bs(2) - bs(1) + 1 -> nstims;
        unless nstims >= nin then
            mishap('input array too short',[^bs])
            endunless
        else
        mishap('needs 1- or 2-D array',[^stims])
    endif;

    ;;; copy first example to network
    fast_for i from 1 to nin do
        stims(i) -> clinputarr(network)(i);
    endfast_for;

    ifail -> ifail_ptr(1);
    ;;; Put args on stack now as there are so many of them
    (
        niter, stims, nstims, stepsize, nin,
        network.clnhunits,   network.clnlevels,
        network.clactarr, network.clbsarr,  network.clntunits,
        network.clwtarr, network.clnweights,
        network.clclusters, network.clnclusters, network.clclustlev,
        network.clgw, network.clgl, network.clrw, network.clrl,
        ifail_ptr
    );
    ;;; and call the right procedure on them
    if cycle then .clearnseqc else .clearnseqr endif;

    if (ifail_ptr(1) ->> ifail) /== 0 then
        mishap('cl_learn_set error',[ifail = ^ifail])
    endif;
enddefine;


define global clwinner(arr) /* -> n */;
    ;;; Should be in Fortran?
    ;;; Returns the winning unit no from an activations array.
    lvars arr;
    lvars i i0 i1;
    explode(boundslist(arr)) -> i1 -> i0;
    for i from i0 to i1 do
        if arr(i) > 0.5 then
        return(i)
        endif
    endfor;
    mishap('No winning unit found',[^arr])
enddefine;

define global cl_maxunits(network) -> maxunits;
    ;;; returns the maximum no of units in any layer, not including the
    ;;; input layer
    lvars network maxunits;
    lvars i nuns;
    network.clnhunits -> nuns;
    0 -> maxunits;
    for i from 1 to network.clnlevels do
        if nuns(i) > maxunits then nuns(i) -> maxunits endif
    endfor
enddefine;

define global cl_activunits(m) /* -> alist */;
    ;;; Returns all the active units in a network. Units are indexed
    ;;; by their position in their cluster. The result is a list of
    ;;; lists, one for each level, counting up.
    lvars m;
    lvars levlist clusarr;
    [%
         for levlist in m.clactivs do
             [%
                  for clusarr in levlist do
                      clwinner(clusarr)
                  endfor
                  %]
         endfor
         %]
enddefine;


define global pr_clweights(network);
    lvars network;
    lvars d1=3, d2=3, wlev, i, j, level, maxunits, nlower, ncurrent, blev
         wclus bclus unit cluster sensvar;
    dlocal poplinemax poplinewidth;

    if isinteger(network) then
        network -> d2;
            -> d1;
            -> network
    endif;
    nl(1);
    (max(network.cl_maxunits,network.clninunits)+1) * (d1+d2) + 10
        ->> poplinemax -> poplinewidth;
    network.clrl > 0 -> sensvar;    ;;; test for variable sensitivity
    npr('WEIGHTS');
    pr('          ');
    if sensvar then
        pr_field('Offset',d1+d2,` `,false);
    endif;
    for i from 1 to max(network.cl_maxunits, network.clninunits) do
        pr_field(i,d1+d2,` `,false)
    endfor;
    nl(1);
    network.clnlevels -> level;
    for wlev, blev in rev(network.clweights), rev(network.clbiases) do
        npr('Level ' >< level);
        1 ->> cluster -> unit;
        for bclus, wclus in blev, wlev do
            npr('    Cluster ' >< cluster);
            explode(boundslist(wclus)) -> ncurrent -> -> nlower ->;
            for j from 1 to ncurrent do
                pr('unit '); pr_field(unit,3,` `,false); pr(': ');
                if sensvar then
                    prnum(bclus(j),d1,d2);
                endif;
                for i from 1 to nlower do
                    prnum(wclus(i,j),d1,d2)
                endfor;
                nl(1);
                unit + 1 -> unit;
            endfor;
            cluster + 1 -> cluster;
        endfor;
        nl(1);
        level - 1 -> level
    endfor
enddefine;

define global pr_clactivs(network);
    lvars network;
    lvars d1=4, d2=0, alev, nuns, i, level, ncurrent, aclus firstclus;
    dlocal poplinemax poplinewidth;
    if isinteger(network) then
        network -> d2;
            -> d1;
            -> network
    endif;
    network.clnhunits -> nuns;
    (network.cl_maxunits+1) * (d1+d2) + 11 ->> poplinemax -> poplinewidth;
    nl(1);
    npr('ACTIVATIONS');
    pr('           ');
    for i from 1 to network.cl_maxunits do
        pr_field(i,d1+d2,` `,false)
    endfor;
    nl(1);
    network.clnlevels -> level;
    for alev in rev(network.clactivs) do
        pr('level '); pr_field(level,3,` `,false); pr(': ');
        true -> firstclus;
        for aclus in alev do
            explode(boundslist(aclus)) -> ncurrent -> ;
            if firstclus then
                prnum(aclus(1),d1,d2);
                false -> firstclus
            else
                pr(' |');    ;;; cluster divider
                prnum(aclus(1),d1-2,d2)
            endif;
            for i from 2 to ncurrent do
                prnum(aclus(i),d1,d2)
            endfor;
        endfor;
        nl(1);
        level - 1 -> level
    endfor
enddefine;


define global cl_save(filename,machine) -> result;
    ;;; Stores a comp learning network in a file
    ;;; Writes an ascii header to make it easier to inspect the file.
    ;;; Dumps arrays in binary to save space.
    ;;; Simply returns false if a problem (as requested by ISL)
    ;;; rather than mishapping.

    lvars machine filename result = true;

    dlocal prmishap =
        procedure(str, list);
            lvars str list;
            npr(';;; MISHAP - CL_SAVE ERROR : ' >< str);
            false; exitfrom(cl_save)
        endprocedure;

    lvars i j clusters = machine.clclusters,
            clustlev = machine.clclustlev,
            dev = syscreate(filename,1,true);

    wtvarstring(dev,'clearnnet\n');
    wtvarstring(dev,machine.clnetwork_name);
    devstring(dev,'\ninput units:  ');
    putnum(dev,machine.clninunits);
    devstring(dev,'\nno levels:    ');
    putnum(dev,machine.clnlevels);
    devstring(dev,'\nhigher units: ');
    0 -> j;
    for i from 1 to machine.clnlevels do
        devstring(dev,'\nlevel ' sys_>< i);
        putnum(dev,clustlev(i));
        repeat clustlev(i) times
            j + 1 -> j;
            putnum(dev,clusters(j))
        endrepeat
    endfor;
    devstring(dev,'\ngw:           ');
    putnum(dev,machine.clgw);
    devstring(dev,'\ngl:           ');
    putnum(dev,machine.clgl);
    devstring(dev,'\nrw:           ');
    putnum(dev,machine.clrw);
    devstring(dev,'\nrl:           ');
    putnum(dev,machine.clrl);
    devstring(dev,'\ntotal no wts: ');
    putnum(dev,machine.clnweights);
    devstring(dev,'\ntot no units: ');
    putnum(dev,machine.clntunits);
    devstring(dev,'\nWeight, , bias, & activation arrays \
follow in binary without gaps. Values are real*4 and read from input towards \
output. For wts, unit nearest input changes fastest. \n');
    devarrvec(dev,machine.clwtarr);
    devarrvec(dev,machine.clbsarr);
    devarrvec(dev,machine.clactarr);
    devstring(dev,'\npatterns:     ');
    putnum(dev,machine.clpatterns);

    sysclose(dev);
enddefine;


define global cl_load(filename) -> machine;
    ;;; Loads a comp learning network stored by cl_save
    ;;; If the filename is a device, it is assumed that the first line,
    ;;; identifying the file as a complearn machine, has been read and is
    ;;; OK.
    lvars machine filename;

    dlocal prmishap =
        procedure(str,list);
            lvars str list;
            npr(';;; MISHAP - CL_LOAD ERROR : ' >< str);
            false; exitfrom(cl_load)
        endprocedure;

    lvars dev i j name gw gl rw rl nin nunits nlevels ncinlev nweights ntunits;

    if isdevice(filename) then
        filename -> dev
    else
        sysopen(filename,0,true) -> dev;
        rdvarstring(dev) -> name;
        unless name = 'clearnnet\n' then
            mishap('NOT COMPETITIVE LEARNING NETWORK',[])
        endunless
    endif;
    rdvarstring(dev) -> name;
    dev -> devstring('\ninput units:  ');
    getnum(dev) -> nin;
    dev -> devstring('\nno levels:    ');
    getnum(dev) -> nlevels;
    dev -> devstring('\nhigher units: ');
    {%
         repeat nlevels times
             dev -> devstring('\nlevel ' sys_>< i);
             getnum(dev) -> ncinlev;
             {%
                  repeat ncinlev times
                      getnum(dev)
                  endrepeat
                  %}
         endrepeat
         %} -> nunits;
    dev -> devstring('\ngw:           ');
    getnum(dev) -> gw;
    dev -> devstring('\ngl:           ');
    getnum(dev) -> gl;
    dev -> devstring('\nrw:           ');
    getnum(dev) -> rw;
    dev -> devstring('\nrl:           ');
    getnum(dev) -> rl;
    dev -> devstring('\ntotal no wts: ');
    getnum(dev) -> nweights;
    dev -> devstring('\ntot no units: ');
    getnum(dev) -> ntunits;
    dev -> devstring('\nWeight, , bias, & activation arrays \
follow in binary without gaps. Values are real*4 and read from input towards \
output. For wts, unit nearest input changes fastest. \n');

    make_clnet(nin,nunits,gw,gl,rw,rl) -> machine;

    unless machine.clnweights == nweights and
        machine.clntunits == ntunits then
        mishap('MISMATCH BETWEEN NETWORK AND FILE',[])
    endunless;

    name -> machine.clnetwork_name;
    dev -> devarrvec(machine.clwtarr);
    dev -> devarrvec(machine.clbsarr);
    dev -> devarrvec(machine.clactarr);
    dev -> devstring('\npatterns:     ');
    getnum(dev) -> machine.clpatterns;

    sysclose(dev);
enddefine;


global vars complearn = true;

endsection;

/*  --- Revision History --------------------------------------------------
Julian Clinton, 6/7/93
    Changed array_of_int to initintvec as array_of_int gives incorrect
    results on DECstation with newexternal.
Julian Clinton, 1/7/93
    Changed to use array_of_int (for C) rather than array_of_integer
    (for Fortran).
Julian Clinton, 18/6/92
    Modified cl_response_set so that it can take a 1-D array.
Julian Clinton, 11/5/92
    Made pr_* and cl_* global.
*/
