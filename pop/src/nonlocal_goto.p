/* --- Copyright University of Sussex 1995. All rights reserved. ----------
 > File:            C.all/src/nonlocal_goto.p
 > Purpose:
 > Author:          John Gibson, Mar 10 1988 (see revisions)
 */

;;; -------------- RUN-TIME SUPPORT FOR NON-LOCAL GOTOS ---------------------

#_INCLUDE 'declare.ph'
#_INCLUDE 'gctypes.ph'

global constant
		procedure (Sys$-Chainto_frame),
		_caller_return
	;

;;; ------------------------------------------------------------------------

section $-Sys;

lvars next_stack_frame_num = 0;
;;;
define Gen_stack_frame_num();
	next_stack_frame_num fi_+ 1 ->> next_stack_frame_num
enddefine;


	/*	Non-local goto to target procedure and offset given by the
		-pdrlab- argument (a procedure_label). This is the simple version,
		where there can be no intervening stack frame for the procedure.
		(Results from a goto inside a straight call of a lexically enclosed
		procedure that isn't pushed.)
	*/
define lconstant Nl_goto(pdrlab);
	lvars	pdrlab, _sframe = _caller_sp();
	if _sframe >=@(csword) _call_stack_hi then
		mishap(pdrlab!PLAB_OWNER, 1, 'TARGET CALL OF NON-LOCAL GOTO NO LONGER EXISTS')
	elseif pdrlab!PLAB_OWNER == _sframe!SF_OWNER then
		;;; Reached target -- pdrlab contains the code offset
		;;; from the execute address. Change the return address to go to it.
		if pdrlab!PLAB_LABEL then
			;;; PLAB_OFFSET contains an absolute address (generated by Popc)
			pdrlab!PLAB_OFFSET
		else
			;;; PLAB_OFFSET contains an offset from PD_EXECUTE
			_sframe!SF_OWNER!PD_EXECUTE@(code){pdrlab!PLAB_OFFSET}
		endif -> _caller_return()
		;;; then just return
	else
		;;; continue unwinding
		_chainfrom_caller(pdrlab, Nl_goto)
	endif
enddefine;

define Non_local_goto() with_nargs 1;
	_sp_flush() -> ;
	chain(Nl_goto)
enddefine;

	/*	This is the complicated version, where there can be intervening stack
		frames for the target procedure (or where the target is no longer
		extant). It results from a goto inside a lexically enclosed procedure
		which crosses a push boundary.
		-target_num- is the integer identifying the target call, which is
		looked for in the idvals of the unique dynamic identifier associated
		with the target procedure (and held in the procedure_label record).
	*/
define Non_local_goto_id(pdrlab, _target_num);
	lvars	pdrlab, id, _sframe = _caller_sp_flush(), _sflim, _owner, _saved,
			_target_num, _id_save_offs;
	pdrlab!PLAB_IDENT -> id;
	if fast_idval(id) == _target_num then
		;;; no intervening stack frames -- go to pdrlab
		_chainfrom_caller(pdrlab, Nl_goto)
	endif;

	;;; else check target call still extant
	pdrlab!PLAB_OWNER -> _owner;
	Dlocal_frame_offset(id, _owner, true) -> _id_save_offs;
	fast_idval(id) -> _saved;
	_call_stack_seg_hi -> _sflim;

	repeat
		if iscompound(_saved) then
			;;; idval is compound at top, no more calls extant for this procedure
			mishap(_owner, 1, 'TARGET CALL OF NON-LOCAL GOTO NO LONGER EXISTS')
		endif;
		;;; find next call of this procedure
		repeat
			_nextframe(_sframe) -> _sframe;
			if _sframe == _sflim then
				_sframe!SF_NEXT_SEG_HI -> _sflim;
				_sframe!SF_NEXT_SEG_SP -> _sframe
			endif;
			quitif(_sframe!SF_OWNER == _owner)
		endrepeat;
		;;; if saved value of id is _target_num then call is
		;;; somewhere further up
		quitif((_sframe!(csword){_id_save_offs} ->> _saved) == _target_num)
	endrepeat;

	;;; OK, target call is still extant
	_chainfrom_caller(
			pdrlab, Nl_goto,
			_pint( ##(csword){_call_stack_hi, _nextframe(_sframe)} ),
			Chainto_frame)
enddefine;


;;; --- KEY FOR PROCEDURE LABEL RECORDS --------------------------------

constant
	procedure_label_key = struct KEY_R_NAFULL =>> {%
		_NULL,					;;; K_GC_RELOC
		key_key,				;;; KEY
		_:M_K_SPECIAL_RECORD
			_biset _:M_K_COPY
			_biset _:M_K_NONWRITEABLE,
								;;; K_FLAGS
		_:GCTYPE_NFULLREC,		;;; K_GC_TYPE
		Record_getsize,			;;; K_GET_SIZE

		"procedure_label",		;;; K_DATAWORD
		false,					;;; K_SPEC
		false,					;;; K_RECOGNISER
		WREF Exec_nonpd,		;;; K_APPLY
		nonop ==,				;;; K_SYS_EQUALS
		WREF nonop ==,			;;; K_EQUALS
		Minimal_print,			;;; K_SYS_PRINT
		WREF Minimal_print,		;;; K_PRINT
		WREF Fullrec1_hash,		;;; K_HASH

		_:NUMTYPE_NON_NUMBER,	;;; K_NUMBER_TYPE
		_:PROLOG_TYPE_OTHER,	;;; K_PLOG_TYPE
		_:EXTERN_TYPE_NORMAL,	;;; K_EXTERN_TYPE
		_0,						;;; K_SPARE_BYTE

		@@(struct PROCEDURE_LABEL)++,	;;; K_RECSIZE_R
		false,					;;; K_CONS_R
		false,					;;; K_DEST_R
		false,					;;; K_ACCESS_R

		@@(int)[_3],			;;; K_FULL_OFFS_SIZE
		=>> {%					;;; K_FULL_OFFS_TAB[_3]
				@@PLAB_OWNER,
				@@PLAB_IDENT,
				@@PLAB_LABEL
			%}
		%};


endsection;		/* $-Sys */



/* --- Revision History ---------------------------------------------------
--- John Gibson, Sep 18 1995
		Changed Nl_goto to interpret the PLAB_OFFSET field of a procedure
		label rec as containing an absolute address if PLAB_LABEL is true
		(relieves Popc of having to generate offsets into procedure code)
--- John Gibson, Apr  7 1995
		Revised key layout
--- John Gibson, Mar 14 1990
		Change to key layout.
--- John Gibson, Dec  4 1989
		Changes for new pop pointers
--- John Gibson, Nov 15 1989
		Changed for segmented callstack
 */