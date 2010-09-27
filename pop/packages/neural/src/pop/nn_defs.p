/*  --- Copyright Integral Solutions Ltd. 1989. All Rights Reserved --------
 > File:           $popneural/src/pop/nn_defs.p
 > Purpose:        global constant and variable declarations
 > Author:         Julian Clinton, Sept 1989
 > Documentation:
 > Related Files:
 */

section $-popneural =>	nn_version
                        nn_events
                        nn_event_timer
                        nn_iterations
                        nn_random_select
                        nn_use_curr_net
                        nn_use_curr_egs
                        nn_call_genfn
                        nn_show_targ
                        nn_show_errors
                        nn_builtin_dts
                        nn_logfile
                        nn_logscreen
;

uses fortran_dec;
uses sort;

global constant nn_version = 2.03s0,
                nn_banner = sprintf(nn_version, 'Poplog-Neural V%p'),
                nn_commands = [load help ref teach doc ved cd pwd
                               im lib showlib];

global vars nn_net_type_menu = [[]],
            nn_exitfromproc = false,
            nn_events = [],
            nn_event_timer = 0,
            nn_iterations = 0,
            nn_help = false,
            nn_std_ttys = [vt100 vt101 vt102 vt220 vt300],
			nn_builtin_dts = [],
            nn_terminal = "dumb";


/* ----------------------------------------------------------------- *
    Error And Warning Messages
 * ----------------------------------------------------------------- */

global constant
    NO_NETS     	= 1,
    NO_EGSS     	= 2,
    NO_DTSS     	= 3,
    NOSU_NET    	= 4,
    NOSU_EG     	= 5,
    NOSU_DT     	= 6,
	FAIL_WINMAKE 	= 7;

global constant
    err = newarray([1 7]);
'No networks have been defined' -> err(NO_NETS),
'No example sets have been defined' -> err(NO_EGSS),
'No datatypes have been defined' -> err(NO_DTSS),
'No such network' -> err(NOSU_NET),
'No such example set' -> err(NOSU_EG),
'No such datatype' -> err(NOSU_DT),
'Could not make window' -> err(FAIL_WINMAKE),
;


/* ----------------------------------------------------------------- *
    GUI constants and vars
 * ----------------------------------------------------------------- */

;;; ui_options_table holds the various popup menus/windows used in the UI
;;; accessed on the name (a word)
global vars ui_options_table;		;;; defined in nui_main.p
global vars procedure nn_logfile;
global vars procedure nn_logscreen;


/* ----------------------------------------------------------------- *
    Option Variables
 * ----------------------------------------------------------------- */

;;; these variables are predicates and storers of particular information
;;; to do with how the example set is selected, whether a menu window exists
;;; etc.
;;;
vars GUI = false;

global vars
     nn_random_select = false,
     nn_use_curr_net = false,
     nn_use_curr_egs = false,
     nn_call_genfn = false,
     nn_show_targ = true,
     nn_show_errors = false;


endsection;		/* $-popneural */

/*  --- Revision History --------------------------------------------------
-- Julian Clinton, 25/08/95
	Updated version for Poplog 15.0.
-- Julian Clinton, 11/07/93
	Updated version for IRIX 5.x.
-- Julian Clinton, 27/04/93
	Removed assignment of setpop to interrupt.
	Changed initial setting of nn_exitfromproc to false.
-- Julian Clinton, Feb  1 1993
    Moved definition of nn_update_wins from here to nn_activevars.p.
-- Julian Clinton, 12/8/92
	Made nn_terminal a word.
-- Julian Clinton, 23/7/92
	Made entries in -nn_std_ttys- words rather than strings.
-- Julian Clinton, 19/6/92
	Changed initial values of nn_current_net and nn_current_egs to
		false.
    Changed "var_options" and "var_options_win" to "training_options" and
        "training_options_win".
-- Julian Clinton, 29/5/92
    Menus and window ids now held in ui_options_table rather than
	variables.
-- Julian Clinton, 8/5/92
    Sectioned.
-- Julian Clinton, 15th Oct. 1990:
	Added "nn_builtin_dts", a global list of built-in datatypes
-- Julian Clinton, 14th Sept. 1990:
    PNE0055 Added variable "nn_std_ttys" which is a list of terminals
    which can display bold, tall, etc. characters
-- Julian Clinton, 14th Sept. 1990:
    PNE0029 Added variable "logerror"
*/
