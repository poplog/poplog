/* --- Copyright University of Sussex 1997. All rights reserved. ----------
 > File:		S.pcunix/src/syscomp/sysdefs_SCO.p
 > Purpose:		Definitions for machine & operating system (PC/SVR4)
 > Author:		Robert Duncan, Oct 31 1988 (see revisions)
 */


section;

global constant macro (

	POPC_SYSDEFS_LOADED = true,


;;; === SYSTEM NAME (PC) ==============================================


	MACHINE = [[pc]],

	PC = true,


;;; === PROCESSOR (INTEL 80x86) =======================================


	PROCESSOR = [[80386]],		;;; or similar

	BYTE_OFFS = 1,				;;; byte address offset of a byte
	SHORT_OFFS = 2,				;;; short address offset of a short
	WORD_OFFS = 4,				;;; word address offset of a word

	BYTE_BITS = 8,				;;; bits in a byte
	SHORT_BITS = 16,			;;; bits in a short
	WORD_BITS = 32,				;;; bits in a word

	SHORT_ALIGN_BITS = 8,		;;; alignment in bits for short access
	WORD_ALIGN_BITS	= 8,		;;; alignment in bits for word access
	DOUBLE_ALIGN_BITS = 8,		;;; alignment in bits for double access

	CODE_POINTER_TYPE = "byte",	;;; type of pointer to machine code
	BIT_POINTER_TYPE = "byte",	;;; type of pointer for bitfield access

	POPINT_BITS	= 29,			;;; max number of bits in a +VE pop integer
	BIGINT_SPEC	= "int",		;;; vector element spec for bigintegers


;;; === OPERATING SYSTEM = AT&T UNIX SYSTEM V.3.2/386 ==================


	OPERATING_SYSTEM = [[unix att 3.2]], ;;; type of os
	UNIX 		= true,
	SYSTEM_V 	= 3.2,
	ATT386 		= 3.2,
	SCO			= 1.1,
	COFF 		= true,			;;; Uses System V Common Object File Format
	TERMINFO	= true,			;;; uses terminfo rather than termcap

	BSD_SOCKETS = true, 		;;; has Berkeley socket system calls

	VPAGE_OFFS = 16:4000,		;;; word address offset of a virtual page

	;;; LOWEST_ADDRESS:
	LOWEST_ADDRESS = 16:0D0,

	;;; UNIX_USRSTACK:
	;;; 	????

	UNIX_USRSTACK	= 16:7FFFFFFC,
	;;; stack size (this is a guess - I can't find the answer in any headers.
	UNIX_USRSTACK_SIZE = 16:80000,

	HERTZ = 60,					;;; clock ticks per second

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

	;;; Alignments for fields in C-type "struct" definitions.
	;;; These depend on the C compiler.

	STRUCT_SHORT_ALIGN_BITS	= 16,	;;; bit alignment for short
	STRUCT_WORD_ALIGN_BITS = 32,	;;; bit alignment for word
	STRUCT_DOUBLE_ALIGN_BITS = 32,	;;; bit alignment for double

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
--- Poplog System, Jan 18 1995 (Julian Clinton)
		A SCO Open Desktop 3.0 version of sysdefs.p
--- Robert John Duncan, Jan 26 1994
		Modified from Sun386 (now defunct) for PC running SVR4
		(some things left unchecked for now ...)
--- John Gibson, Oct 22 1992
		Changed P*OPC to POPC_SYSDEFS_LOADED
--- Robert John Duncan, Jun 23 1992
		Added BSD_VFORK
--- John Gibson, Dec 11 1990
		SUNOS 4.1
--- Rob Duncan, Aug 31 1989
		Put in value for UNIX_USRSTACK
--- John Gibson, Aug 31 1989
		Added comment for UNIX_USRSTACK, but have no way of finding value.
--- John Gibson, Aug 24 1989
		Removed S+IGNALS
--- Rob Duncan, Apr  3 1989
		Changed OPERATING_SYSTEM definition to include "unix" as well as
		"sunos"
 */
