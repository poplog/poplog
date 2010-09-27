/* --- Copyright University of Sussex 1990. All rights reserved. ----------
 > File:            $poplocal/local/lib/vedsun4xtermkeys.p
 > Purpose:         VED key bindings for Sun type-4 keyboard using xterm
 > Author:          John Williams & Andreas Schoter, Jun  7 1990 (see revisions)
 > Documentation:   HELP * SUN4KEYS
 > Related Files:   LIB * SUN4KEYS, LIB * VEDSUN4KEYS
 */

/*

The following 'xrdb' key bindings should be set:

XTerm*VT100*Translations: #override \
    <Key>Num_Lock: string(0x1b) string("[110~") \n\
    <Key>R1: string(0x1b) string("[111~") \n\
    <Key>R2: string(0x1b) string("[112~") \n\
    <Key>R3: string(0x1b) string("[113~") \n\
    <Key>R4: string(0x1b) string("[114~") \n\
    <Key>R5: string(0x1b) string("[115~") \n\
    <Key>R6: string(0x1b) string("[117~") \n\
    <Key>R7: string(0x1b) string("[118~") \n\
    <Key>R9: string(0x1b) string("[120~") \n\
    <Key>R11: string(0x1b) string("[123~") \n\
    <Key>R13: string(0x1b) string("[125~") \n\
    <Key>R15: string(0x1b) string("[128~") \n\
	<Key>Help: string(0x1b) string("K") \n\
    <Key>KP_Enter: string(0x1b) string("OM") \n\
    <Key>KP_Add: string(0x1b) string("Ok") \n\
    <Key>KP_Subtract: string(0x1b) string("Om") \n\
    <Key>KP_0: string(0x1b) string("Op") \n\
    <Key>KP_Decimal: string(0x1b) string("On")

The last 5 mapppings are the same as on an NCD16 X-terminal
in its default (VT100) state.

*/

section;

uses vedset;


define vedsun4xtermkeys();
    vedset keys

    ;;; Function keys
        dotdelete         = esc [ 1 1 ~             ;;; F1
        clearhead         = esc [ 1 2 ~             ;;; F2
        linedelete        = esc [ 1 3 ~             ;;; F3
        cleartail         = esc [ 1 4 ~             ;;; F4
        wordleftdelete    = esc [ 1 5 ~             ;;; F5
        wordrightdelete   = esc [ 1 7 ~             ;;; F6
        marklo            = esc [ 1 8 ~             ;;; F7
        markhi            = esc [ 1 9 ~             ;;; F8
        ENTER m           = esc [ 2 0 ~             ;;; F9
        ENTER t           = esc [ 2 1 ~             ;;; F10
        pushkey           = esc [ 2 3 ~             ;;; F11
        exchangeposition  = esc [ 2 4 ~             ;;; F12

	;;; Added JG 19 Jun 90
        ENTER d           = esc [ 2 2 ~
        ENTER yank        = esc esc [ 2 2 ~

    ;;; ESC + function key
        "xrefresh"        = esc esc [ 1 1 ~         ;;; ESC F1
        ENTER yankw       = esc esc [ 1 2 ~         ;;; ESC F2
        ENTER yankl       = esc esc [ 1 3 ~         ;;; ESC F3
        ENTER yankw       = esc esc [ 1 4 ~         ;;; ESC F4
        ENTER yankw       = esc esc [ 1 5 ~         ;;; ESC F5
        ENTER yankw       = esc esc [ 1 7 ~         ;;; ESC F6
        ENTER mbf         = esc esc [ 1 8 ~         ;;; ESC F7
        ENTER mef         = esc esc [ 1 9 ~         ;;; ESC F8
        ENTER mi          = esc esc [ 2 0 ~         ;;; ESC F9
        ENTER ti          = esc esc [ 2 1 ~         ;;; ESC F10
        popkey            = esc esc [ 2 3 ~         ;;; ESC F11
        ENTER cps         = esc esc [ 2 4 ~         ;;; ESC F12

    ;;; Right hand keypad
        screenleft        = esc [ 1 1 1 ~           ;;; Pause       (R1)
        textright         = esc [ 1 1 2 ~           ;;; PrSc        (R2)
        screenup          = esc [ 1 1 3 ~           ;;; Scroll      (R3)
        screendown        = esc [ 1 1 0 ~           ;;; Num_Lock

        textleft          = esc esc [ 1 1 1 ~       ;;; ESC Pause   (ESC R1)
        screenright       = esc esc [ 1 1 2 ~       ;;; ESC PrSc    (ESC R2)
        topfile           = esc esc [ 1 1 3 ~       ;;; ESC Scrol   (ESC R3)
        endfile           = esc esc [ 1 1 0 ~       ;;; ESC Num_Lock

        lineabove         = esc [ 1 1 4 ~           ;;; =           (R4)
        setstatic         = esc [ 1 1 5 ~           ;;; /           (R5)
        loadline          = esc [ 1 1 7 ~           ;;; *           (R6)

        linebelow         = esc esc [ 1 1 4 ~       ;;; ESC =       (ESC R4)
        ENTER break       = esc esc [ 1 1 5 ~       ;;; ESC /       (ESC R5)
        ENTER lmr         = esc esc [ 1 1 7 ~       ;;; ESC *       (ESC R6)

        charupleft        = esc [ 1 1 8 ~           ;;; R7
        charup            = esc [ A                 ;;; R8
        charupright       = esc [ 1 2 0 ~           ;;; R9
        charleft          = esc [ D                 ;;; R10
        ENTER timed_esc   = esc [ 1 2 3 ~           ;;; R11
        charright         = esc [ C                 ;;; R12
        chardownleft      = esc [ 1 2 5 ~           ;;; R13
        chardown          = esc [ B                 ;;; R14
        chardownright     = esc [ 1 2 8 ~           ;;; R15

        charupleftlots    = esc esc [ 1 1 8 ~       ;;; ESC R7
        charuplots        = esc esc [ A             ;;; ESC R8
        charuprightlots   = esc esc [ 1 2 0 ~       ;;; ESC R9
        charleftlots      = esc esc [ D             ;;; ESC R10
        charmiddle        = esc esc [ 1 2 3 ~       ;;; ESC R11
        charrightlots     = esc esc [ C             ;;; ESC R12
        chardownleftlots  = esc esc [ 1 2 5 ~       ;;; ESC R13
        chardownlots      = esc esc [ B             ;;; ESC R14
        chardownrightlots = esc esc [ 1 2 8 ~       ;;; ESC R15

        wordleft          = esc O p                 ;;; Ins
        wordright         = esc O n                 ;;; Del
        enter             = esc O M                 ;;; Enter
        statusswitch      = esc O k                 ;;; +
        redocommand       = esc O m                 ;;; -

        ;;; Left hand keypad
        redocommand       = esc [ 3 2 ~             ;;; L8
        switchstatus      = esc [ 3 3 ~             ;;; L9
        enterkey          = esc [ 3 4 ~             ;;; L10
        helpkey           = esc K                   ;;; Help
        ENTER hkey        = esc esc K               ;;; ESC Help

	;;; Added JG 19 Jun 90
        ENTER rb          = esc [ 3 5 ~

    endvedset;

	'sun4' -> vedkeymapname;
enddefine;


endsection;


/* --- Revision History ---------------------------------------------------
--- John Williams, Oct 18 1990
		Fixed "Help" key. Also sets -vedkeymapname- 
 */
