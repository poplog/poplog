;;; VEDLASTITEM								Mark Rubinstein January 1985
;;; returns the previous item (current item if teh cursor is currently in the
;;; middle of an item) without affecting the cursor position.

section $-lib => vedlastitem;

define global vedlastitem;
vars vedcolumn vedline;			;;; in case of interrupts;
	vedpositionpush();
	vedmovebackitem();
	vedpositionpop();
enddefine;

endsection;
