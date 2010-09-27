/* --- Copyright University of Sussex 1995. All rights reserved. ----------
 > File:			C.all/lib/objectclass/rt/slots.p
 > Purpose:			Objectclass runtime support
 > Author:			Robert John Duncan, Sep 29 1995
 */
compile_mode:pop11 +strict;

section $-objectclass;

;;; check_slot_init:
;;;     check result of a slot initialiser: _s is the stacklength now, _n
;;;     is the stacklength before the call

define check_slot_init(s, n, name) with_props false;
	unless s == n fi_+ 1 then
		mishap(
			if s > n then
				'TOO MANY RESULTS RETURNED BY SLOT INITIALISER'
			else
				'TOO FEW RESULTS RETURNED BY SLOT INITIALISER'
			endif,
			[^name]
		)
	endunless
enddefine;

;;; shared_slot:
;;; 	implement a simple shared slot with a known initial value: the
;;; 	____slot is a ref containing the value

define shared_slot(obj, slot);
	fast_cont(slot);
enddefine;
;;;
define updaterof shared_slot(obj, slot);
	-> fast_cont(slot);
enddefine;

;;; computed_shared_slot:
;;;     implement a shared slot with an initialisation procedure: the
;;;     ____slot is a 3-vector containing a ____flag to indicate whether it's
;;;     been initialised, a _____value which will be the init procedure until
;;;     first access, and the slot ____name: {^____flag ^_____value ^____name}

define computed_shared_slot(obj, slot) with_props shared_slot;
	unless fast_subscrv(1, slot) then
		;;; first time
		lvars sl = stacklength();
		check_slot_init(
			fast_subscrv(2, slot)(obj),
			stacklength(), sl, fast_subscrv(3, slot)
		) -> fast_subscrv(2, slot);
		true -> fast_subscrv(1, slot);
	endunless;
	fast_subscrv(2, slot);
enddefine;
;;;
define updaterof computed_shared_slot(slot) with_nargs 3;
	((), (), true) -> (fast_subscrv(2, slot), (), fast_subscrv(1, slot));
enddefine;

;;; if_needed:
;;;     compute initial value of an if-needed method: ___obj is the
;;;     instance, ____prop a property for caching results, _______initial the
;;;     procedure to compute the value and ____name the method name

define if_needed(obj, prop, initial, name);
	lvars sl = stacklength();
	check_slot_init(initial(obj), stacklength(), sl, name) ->> prop(obj);
enddefine;

endsection;		/* $-objectclass */
