/* --- Copyright University of Sussex 2003. All rights reserved. ----------
 > File:            $popvision/lib/newzfloatarray.p
 > Purpose:         Packed arrays of double precision complex values
 > Author:          David Young, Jul 15 2003
 > Documentation:   HELP * NEWZFLOATARRAY
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses oldarray

defclass zfloatvec :dfloat;

/* Redefine zfloatvec's associated procedures */

lconstant
    init = class_init(zfloatvec_key),
    conser = class_cons(zfloatvec_key),
    dester = class_dest(zfloatvec_key),
    subscr = class_subscr(zfloatvec_key),
    fast_subscr = class_fast_subscr(zfloatvec_key);

define initzfloatvec(n);
    init(n * 2)
enddefine;

define conszfloatvec(n) -> v;
    lvars i = n, val;
    repeat n times
        realpart(subscr_stack(i) ->> val);
        imagpart(val);
        i fi_+ 1 -> i
    endrepeat;
    conser(n * 2) -> v;
    erasenum(n);
enddefine;

define destzfloatvec(v) -> n;
    datalength(v) -> n;
    lvars i = 0;
    until i == n do
        fast_subscr(i fi_+ 1 ->> i, v) +: fast_subscr(i fi_+ 1 ->> i, v)
    enduntil;
    n fi_>> 1 -> n
enddefine;

define lconstant przfloatvec(v);
    lvars i = 0, s = '<zfloatvec ';;
    until i == datalength(v) do
        sys_syspr(s);
        ' ' -> s;
        sys_syspr(fast_subscr(i fi_+ 1 ->> i, v)
            +: fast_subscr(i fi_+ 1 ->> i, v));
    enduntil;
    sys_syspr('>');
enddefine;

przfloatvec -> class_print(zfloatvec_key);

define subscrzfloatvec(i, v);
    lvars ii = i * 2;
    subscr(ii - 1, v) +: subscr(ii, v)
enddefine;

define updaterof subscrzfloatvec(val, i, v);
    lvars ii = i * 2;
    realpart(val) -> subscr(ii - 1, v);
    imagpart(val) -> subscr(ii, v);
enddefine;

subscrzfloatvec -> class_apply(zfloatvec_key);
updater(subscrzfloatvec) -> updater(class_apply(zfloatvec_key));

define fast_subscrzfloatvec(i, v);
    lvars ii = i fi_<< 1;
    fast_subscr(ii fi_- 1, v) +: fast_subscr(ii, v)
enddefine;

define updaterof fast_subscrzfloatvec(val, i, v);
    lvars ii = i fi_<< 1;
    realpart(val) -> fast_subscr(ii fi_- 1, v);
    imagpart(val) -> fast_subscr(ii, v);
enddefine;

/* Now can define the arrays */

define newzfloatarray = newanyarray(% initzfloatvec, fast_subscrzfloatvec%);
enddefine;

lconstant initpair   ;;; vector needs twice as many elements as array
    = conspair(initzfloatvec, nonop fi_<< (% 1 %));

define oldzfloatarray = oldanyarray(% initpair, fast_subscrzfloatvec %);
enddefine;

define iszfloatarray(arr);
    arr.isarray and arr.arrayvector.dataword == "zfloatvec"
enddefine;

endsection;
