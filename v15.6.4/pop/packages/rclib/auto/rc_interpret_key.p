/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_interpret_key.p
 > Purpose:			Map key codes to key names
 > Author:          Aaron Sloman, Aug 13 1997 (see revisions)
 > Documentation:	HELP * RCLIB/rc_interpret_key, HELP * RC_KEYCODES
					HELP * RC_TEXT_INPUT
 > Related Files:	LIB * RCLIB, * RC_TEXT_INPUT
 */

section;


compile_mode
            :pop11 +varsch +defpdr -defcon -lprops -constr +global
            :vm +prmfix
            :popc -wrdflt -wrclos;

define vars user_rc_interpret_key(code) -> key;
	false -> key;
enddefine;

define vars rc_interpret_key(code) -> key;
	;;; to extend or modify this procedure, copy and edit, or
	;;; redefine user_rc_interpret_key

	returnif(user_rc_interpret_key(code) ->> key);

	if code /== 0 and code < 127 then code
	elseif code == 65505 then "SHIFT" ;;; left
	elseif code == 65506 then "SHIFT" ;;; right
    elseif code == 65507 then "CONTROL" ;;; left
	elseif code == 65508 then "CONTROL_R"	;;;; on right
	elseif code == 65509 then "CAPSLOCK"
	elseif code == 65511 then "META"	;;; left
	elseif code == 65512 then "META"	;;; right
	elseif code == 65513 then "ALT"		;;; left
	elseif code == 65312 then "COMPOSE"	;;; right
	elseif code == 65307 then "ESC"
	elseif code == 65535 or code == `\^?` then "DELETE"
	elseif code == 65288 or code == `\b` then "BACKSPACE"
	elseif code == 65289 or code == `\t` then "TAB"
	elseif code == 65290 or code == `\n` then "LINEFEED"
	elseif code == 65293 or code == `\r` then "RETURN"
	elseif code == 65383 then "MENU"
	elseif code == 65386 then "HELP"
	elseif code == 65421 then "ENTER"
	elseif code == 65429 then "KP_7"
	elseif code == 65430 then "KP_4" ;;; LEFT
	elseif code == 65431 then "KP_8" ;;; UP
	elseif code == 65432 then "KP_6" ;;; RIGHT
	elseif code == 65433 then "KP_2" ;;; DOWN
	elseif code == 65434 then "KP_9"
	elseif code == 65435 then "KP_3"
	elseif code == 65436 then "KP_1"
	elseif code == 65437 then "KP_5"
	elseif code == 65438 then "KP_0" ;;; INS
	elseif code == 65439 then "KP_DEL" ;;; INS
	elseif code == 65450 then "KP_MULT" ;;; INS
	elseif code == 65455 then "KP_DIV" ;;; INS
	elseif code == 65470 then "F1"
	elseif code == 65471 then "F2"
	elseif code == 65472 then "F3"
	elseif code == 65473 then "F4"
	elseif code == 65474 then "F5"
	elseif code == 65475 then "F6"
	elseif code == 65476 then "F7"
	elseif code == 65477 then "F8"
	elseif code == 65478 then "F9"
	elseif code == 65479 then "F10"
	elseif code == 65480 then "F11"
	elseif code == 65481 then "F12"
	;;; On type 5 keyboard the following are CENTRAL arrow keys
	;;; On the type 4 (Sun4), they are the keypad keys 4,8,6,2:
	elseif code == 65361 then "LEFT"
	elseif code == 65362 then "UP"
	elseif code == 65363 then "RIGHT"
	elseif code == 65364 then "DOWN"
	elseif code == 65379 then "INSERT"
	elseif code == 65360 then "HOME"
	elseif code == 65367 then "END"
	elseif code == 65365 then "PAGEUP"
	elseif code == 65366 then "PAGEDOWN"

	;;; On type 5 keyboard these are the keypad keys 4,8,6,2
	elseif code == 65497 then "KP_8" ;;; "UP"
	elseif code == 65499 then "KP_4" ;;; "LEFT"
	elseif code == 65501 then "KP_6" ;;; "RIGHT"
	elseif code == 65503 then "KP_2" ;;; "DOWN"
	;;; More Numeric Keypad Keys
	elseif code == 65451 then "KP_Add"
	elseif code == 65453 then "KP_Subtract"
	elseif code == 65454 then "KP_Decimal"
	elseif code == 65456 then "KP_0"
	elseif code == 65494 then "KP_Divide"
	elseif code == 65495 then "KP_Multiply"
	elseif code == 65496 then "KP_7" ;;; "KP_Home"
	elseif code == 65502 then "KP_1" ;;; "KP_End"
	elseif code == 65498 then "KP_9" ;;; "KP_PgUp"
	elseif code == 65504 then "KP_3" ;;; "KP_PgDn"

	elseif code == 65407 then "NUMLOCK"
	else
		;;; should this be a mishap??
		['UNRECOGNIZED KEY CODE: ' ^code ' (extend rc_interpret_key?)']=>
		code
	endif -> key
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep  9 2002
		Changed compile mode
--- Aaron Sloman, Aug 25 2002
		Extended on linux right hand keypad
--- Aaron Sloman, Aug 16 1997
	Introduced user version
 */
