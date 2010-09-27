/* --- Copyright University of Sussex 1990. All rights reserved. ----------
 > File:            $poplocal/local/lib/vedsun4keys.p
 > Purpose:         Set up VED function keys on a Sun type-4 keyboard
 > Author:          John Williams, Mar 12 1990 (see revisions)
 > Documentation:   HELP * SUN4KEYS
 > Related Files:
 */


section;

define lconstant Setkey(key, pdr, esc_pdr);
    lvars esc_pdr pdr key;
    vedsetkey(key, pdr);
    if esc_pdr then
        vedsetkey('\^[' <> key, esc_pdr)
    endif
enddefine;


define global vedsun4keys();

    /* Function keys F1 - F12 */

    Setkey('\^[[202z',  veddotdelete,       vedrefresh);    ;;; F1
    Setkey('\^[[225z',  vedclearhead,       ved_yankw);     ;;; F2
    Setkey('\^[[226z',  vedlinedelete,      ved_yankl);     ;;; F3
    Setkey('\^[[227z',  vedcleartail,       ved_yankw);     ;;; F4
    Setkey('\^[[228z',  vedwordleftdelete,  ved_yankw);     ;;; F5
    Setkey('\^[[229z',  vedwordrightdelete, ved_yankw);     ;;; F6
    Setkey('\^[[230z',  vedmarklo,          ved_mbf);       ;;; F7
    Setkey('\^[[231z',  vedmarkhi,          ved_mef);       ;;; F8
    Setkey('\^[[232z',  ved_m,              ved_mi);        ;;; F9
    Setkey('\^[[233z',  ved_t,              ved_ti);        ;;; F10
    Setkey('\^[[234z',  vedpushkey,         vedpopkey);     ;;; F11
    Setkey('\^[[235z',  vedexchangeposition,ved_cps);       ;;; F12

    /* Numeric keypad */

    Setkey('\^[[220z',  vedchardownleft,    vedchardownleftlots);
    Setkey('\^[[B',     vedchardown,        vedchardownlots);
    Setkey('\^[[222z',  vedchardownright,   vedchardownrightlots);
    Setkey('\^[[D',     vedcharleft,        vedcharleftlots);
    Setkey('\^[[218z',  ved_timed_esc,      vedcharmiddle);
    Setkey('\^[[C',     vedcharright,       vedcharrightlots);
    Setkey('\^[[214z',  vedcharupleft,      vedcharupleftlots);
    Setkey('\^[[A',     vedcharup,          vedcharuplots);
    Setkey('\^[[216z',  vedcharupright,     vedcharuprightlots);

    Setkey('\^[[247z',  vedwordleft,        false);         ;;; 0
    Setkey('\^[[249z',  vedwordright,       false);         ;;; .
    Setkey('\^[[250z',  vedenter,           false);         ;;; Enter
    Setkey('\^[[253z',  vedstatusswitch,    false);         ;;; +
    Setkey('\^[[254z',  vedredocommand,     false);         ;;; -

    Setkey('\^[[211z',  vedlineabove,   vedlinebelow);      ;;; =
    Setkey('\^[[212z',  ved_static,     ved_break);         ;;; /
    Setkey('\^[[213z',  vedloadline,    ved_lmr);           ;;; *

    Setkey('\^[[208z',  vedscreenleft,  vedtextleft);       ;;; Pause
    Setkey('\^[[209z',  vedtextright,   vedscreenright);    ;;; PrSc
    Setkey('\^[[210z',  vedscreenup,    vedtopfile);        ;;; Scroll
    Setkey('\^[[255z',  vedscreendown,  vedendfile);        ;;; NumLock

    /* Left hand keypad (for old Sun keyboard compability) */

    Setkey('\^[[237z',  vedredocommand,     false);         ;;; L8
    Setkey('\^[[206z',  vedswitchstatus,    false);         ;;; L9
    Setkey('\^[[238z',  vedenter,           false);         ;;; L10

    Setkey('\^[[207z',  ved_hkeys,  ved_hkey);              ;;; Help

    'sun4' -> vedkeymapname;
enddefine;


/* Redefine -vedsunkeys- to call -vedsun4keys- */

define global vedsunkeys();
    vedsun4keys()
enddefine;


endsection;


/* --- Revision History ---------------------------------------------------
--- John Williams, Oct 18 1990
        Now uses -ved_hkeys- and -vedkeymapname-
 */
