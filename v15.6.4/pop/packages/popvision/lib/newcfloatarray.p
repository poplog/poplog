/* --- Copyright University of Sussex 2003. All rights reserved. ----------
 > File:            $popvision/lib/newcfloatarray.p
 > Purpose:         Packed arrays of complex values
 > Author:          David Young, Jul 15 2003
 > Documentation:   HELP * NEWCFLOATARRAY
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses oldarray

defclass cfloatvec :sfloat;

/* Redefine cfloatvec's associated procedures */

lconstant
    init = class_init(cfloatvec_key),
    conser = class_cons(cfloatvec_key),
    dester = class_dest(cfloatvec_key),
    subscr = class_subscr(cfloatvec_key),
    fast_subscr = class_fast_subscr(cfloatvec_key);

define initcfloatvec(n);
    init(n * 2)
enddefine;

define conscfloatvec(n) -> v;
    lvars i = n, val;
    repeat n times
        realpart(subscr_stack(i) ->> val);
        imagpart(val);
        i fi_+ 1 -> i
    endrepeat;
    conser(n * 2) -> v;
    erasenum(n);
enddefine;

define destcfloatvec(v) -> n;
    datalength(v) -> n;
    lvars i = 0;
    until i == n do
        fast_subscr(i fi_+ 1 ->> i, v) +: fast_subscr(i fi_+ 1 ->> i, v)
    enduntil;
    n fi_>> 1 -> n
enddefine;

define lconstant prcfloatvec(v);
    lvars i = 0, s = '<cfloatvec ';;
    until i == datalength(v) do
        sys_syspr(s);
        ' ' -> s;
        sys_syspr(fast_subscr(i fi_+ 1 ->> i, v)
            +: fast_subscr(i fi_+ 1 ->> i, v));
    enduntil;
    sys_syspr('>');
enddefine;

prcfloatvec -> class_print(cfloatvec_key);

define subscrcfloatvec(i, v);
    lvars ii = i * 2;
    subscr(ii - 1, v) +: subscr(ii, v)
enddefine;

define updaterof subscrcfloatvec(val, i, v);
    lvars ii = i * 2;
    realpart(val) -> subscr(ii - 1, v);
    imagpart(val) -> subscr(ii, v);
enddefine;

subscrcfloatvec -> class_apply(cfloatvec_key);
updater(subscrcfloatvec) -> updater(class_apply(cfloatvec_key));

define fast_subscrcfloatvec(i, v);
    lvars ii = i fi_<< 1;
    fast_subscr(ii fi_- 1, v) +: fast_subscr(ii, v)
enddefine;

define updaterof fast_subscrcfloatvec(val, i, v);
    lvars ii = i fi_<< 1;
    realpart(val) -> fast_subscr(ii fi_- 1, v);
    imagpart(val) -> fast_subscr(ii, v);
enddefine;

/* Now can define the arrays */

define newcfloatarray = newanyarray(% initcfloatvec, fast_subscrcfloatvec%);
enddefine;

lconstant initpair   ;;; vector needs twice as many elements as array
    = conspair(initcfloatvec, nonop fi_<< (% 1 %));

define oldcfloatarray = oldanyarray(% initpair, fast_subscrcfloatvec %);
enddefine;

define iscfloatarray(arr);
    arr.isarray and arr.arrayvector.dataword == "cfloatvec"
enddefine;

endsection;
