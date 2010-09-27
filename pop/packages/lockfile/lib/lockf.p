/* --- Copyright University of Sussex 1989. All rights reserved. ----------
 > File:            $poplocal/local/lib/lockf.p
 > Purpose:			Make C 'lockf' available
 > Author:          John Williams, Feb  1 1989 (see revisions)
 > Documentation:	MAN * LOCKF
 > Related Files:
 */

section;

global vars lockf;

external_load("lockf", [], [{type procedure} ['_lockf' lockf]]);

constant macro (
    F_ULOCK     =   0,      ;;; Unlock a previously locked section
    F_LOCK      =   1,      ;;; Lock a section for exclusive use
    F_TLOCK     =   2,      ;;; Test and lock a section (non-blocking)
    F_TEST      =   3,      ;;; Test section for other process' locks
    );


define global syslockf(device, lock_op, size);
	lvars device lock_op size;
	lockf(device_os_channel(device), lock_op, size or 0, 3, true) == 0
enddefine;


define global syslock(device, wait);
    lvars device wait;
	syslockf(device, if wait then F_LOCK else F_TLOCK endif, 0)
enddefine;


define global sysunlock(device);
    lvars device;
	syslockf(device, F_TEST, 0) and syslockf(device, F_ULOCK, 0)
enddefine;

endsection;
