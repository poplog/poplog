/* --- Copyright University of Sussex 1997. All rights reserved. ----------
 > File:			S.pcunix/src/syscomp/sysdefs_NCR.p
 > Purpose:			Definitions for machine & operating system (NCR/SVR4)
 > Author:			Robert Duncan, Jul 30 1996 (see revisions)
 */

section;

global constant macro (

	POPC_SYSDEFS_LOADED = true,


;;; == SYSTEM NAME (NCR SYSTEM 3000) ======================================

	MACHINE = [[ncr3000]],
	NCR = true,


;;; == PROCESSOR (INTEL 80x86) ============================================

	PROCESSOR = [[80386]],		;;; or similar

	;;; Values for machine and C data types are defined in mcdata.p,
	;;; and can be overidden here if necessary
	;;; We're using most of the defaults, even though the x86 can access
	;;; anything on a byte boundary

	DOUBLE_ALIGN_BITS = 32,
	CODE_POINTER_TYPE = "byte",	;;; type of pointer to machine code
	BIT_POINTER_TYPE = "byte",	;;; type of pointer for bitfield access


;;; == OPERATING SYSTEM (NCR UNIX SVR4 MP-RAS 3.0) ========================

	POSIX1 = 199808,
	OPERATING_SYSTEM = [[unix ncr 3.0 posix {^POSIX1}]],
	UNIX = true,
	SYSTEM_V = 4.0,
	SHARED_LIBRARIES = true,
	BSD_MMAP = true,
	BSD_MPROTECT = true,

	VPAGE_OFFS = 16:1000,

	;;; This is not available in any header file. The value here was
	;;; computed by experiment, but it's no longer used -- computed
	;;; dynamically in Abs_callstack_lim() instead
	;;; UNIX_USRSTACK = 16:8048000,

	;;; Lowest address -- who knows? (stack is BELOW text by default)
	LOWEST_ADDRESS = 16:1000,

	;;; Procedures to get and set the memory break and return the REAL end of
	;;; memory. (We always need the real end to ensure that the end of the
	;;; user stack is always at the true end of memory, so that user stack
	;;; underflow produces a memory access violation.)

	GET_REAL_BREAK =
		[procedure(); _extern sbrk(_0)@(b.r->vpage) endprocedure],

	SET_REAL_BREAK =
		[procedure(_break) -> _break;
			lvars _break = _break@(w.r->vpage);
			if _extern brk(_break@(w->b)) == _-1 then
				_-1 -> _break
			endif
		endprocedure],


;;; === OTHER =========================================================

	;;; ANSI C returns floats as single, not double
	ANSI_C = true,
	C_FLOAT_RESULT_SINGLE = true,

	;;; list of procedures to be optimised as subroutine calls
	;;; format of entries is
	;;;		[<pdr name> <nargs> <nresults> <subroutine name>]

	SUBROUTINE_OPTIMISE_LIST =
		[[
			[prolog_newvar	0 1 _prolog_newvar]
			[datakey		1 1 _datakey]
			[prolog_deref	1 1 _prolog_deref]
			[conspair		2 1 _conspair]
		]],

	;;; Old-style I_PUSH/POP_FIELD(_ADDR) instructions in ass.p
	OLD_FIELD_INSTRUCTIONS = true,

	;;; Include M-code listing in assembly language files

	M_DEBUG = false,

);

endsection;		/* $- */


/* --- Revision History ---------------------------------------------------
--- Robert Duncan, May 12 1997
		Added OLD_FIELD_INSTRUCTIONS. Removed is* procedures from
		SUBROUTINE_OPTIMISE_LIST (no longer required).
 */
