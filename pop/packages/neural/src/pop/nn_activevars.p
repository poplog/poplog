/*  --- Copyright Integral Solutions Ltd. 1989. All Rights Reserved --------
 > File:           $popneural/src/pop/nn_activevars.p
 > Purpose:        active variable declarations
 > Author:         Julian Clinton, July 1992
 > Documentation:
 > Related Files:
 */

section $-popneural =>
                        nn_current_net
                        nn_current_egs
                        nn_current_dt
                        nn_training_cycles
                        nn_update_wins
                        nn_winrefresh
                        logfilename
                        logfrequency
                        logecho
                        logfilewrite
                        logerror
                        logaccuracy
                        logtestset
                        logsavenet
                        isexampleset
                        isneuralnet
                        isdatatype
;


/* ----------------------------------------------------------------- *
    Predicates Used By Active Variables
 * ----------------------------------------------------------------- */

define global procedure isexampleset(item);
lvars item;
    not(nn_example_sets(item) == false);
enddefine;

define global procedure isneuralnet(item);
lvars item;
    not(nn_neural_nets(item) == false);
enddefine;

define global procedure isdatatype(item);
lvars item;
    not(nn_datatypes(item) == false);
enddefine;


/* ----------------------------------------------------------------- *
    Variable Display Utilities
 * ----------------------------------------------------------------- */

;;; pre-declare ui_variable_display. If the UI hasn't been loaded then
;;; do nothing. Otherwise, these definitions should have been overwritten
;;; by the real definitions in nui_panels.p

global vars procedure ui_variable_display;

define ui_variable_display(var_ident, type) -> val;
lvars var_ident type val;
    undef -> val;
enddefine;

define updaterof ui_variable_display(val, var_ident, type);
lvars var_ident type val;
    ;;; do nothing
enddefine;


define global vars nn_winrefresh;
    mishap(0, 'NUI: No window system to update');
enddefine;


lvars
     curr_net = false,
     curr_egs = false,
     curr_dt = "boolean",
     t_cycles = 1000,
     update_wins = false;


;;; nn_current_net holds the name of the current default network
;;;
define global active:1 nn_current_net;
    curr_net;
enddefine;

define updaterof global active:1 nn_current_net(val);
lvars val tmp_id;
    if isstring(val) then consword(val) -> val; endif;
    if (isword(val) and isneuralnet(val)) or not(val) then
        val -> curr_net;
        val -> ui_variable_display(ident nn_current_net, word_key);
    endif;
enddefine;


;;; nn_current_egs holds the name of the current default example set
;;;
define global active:1 nn_current_egs;
    curr_egs;
enddefine;

define updaterof global active:1 nn_current_egs(val);
lvars val tmp_id;
    if isstring(val) then consword(val) -> val; endif;
    if (isword(val) and isexampleset(val)) or not(val) then
        val -> curr_egs;
        val -> ui_variable_display(ident nn_current_egs, word_key);
    endif;
enddefine;


;;; nn_current_dt holds the name of the current default datatype
;;;
define global active:1 nn_current_dt;
    curr_dt;
enddefine;

define updaterof global active:1 nn_current_dt(val);
lvars val;
    if isstring(val) then consword(val) -> val; endif;
    val -> curr_dt;
enddefine;


;;; nn_training_cycles holds the number of iterations per training session
;;;
define global active:1 nn_training_cycles;
    t_cycles;
enddefine;

define updaterof global active:1 nn_training_cycles(val);
lvars val tmp_id;
    if isinteger(val)
       or (isstring(val) and
           (strnumber(val) ->> val) and isinteger(val)) then
        abs(intof(val)) -> t_cycles;
        t_cycles -> ui_variable_display(ident nn_training_cycles, integer_key);
    endif;
enddefine;



;;; nn_update_wins holds the number of iterations per training session
;;;
define global active:1 nn_update_wins;
    update_wins;
enddefine;

define updaterof global active:1 nn_update_wins(val);
lvars val tmp_id;
    if isboolean(val) then
        val -> update_wins;
        if update_wins then
            unless member(nn_winrefresh, nn_events) then
                nn_winrefresh :: nn_events -> nn_events;
            endunless;
        else
            ncdelete(nn_winrefresh, nn_events, nonop =) -> nn_events;
        endif;
        val -> ui_variable_display(ident nn_update_wins, boolean_key);
    endif;
enddefine;



/* ----------------------------------------------------------------- *
    Logfile Variables
 * ----------------------------------------------------------------- */

lvars lgname = 'neural.log', lgwrite = false, lgecho = false,
    lgerror = false, lgaccuracy = false, lgtestset = false,
    lgsavenet = false;


;;; logfilename is a string which defines the name of the log file
define global active:1 logfilename;
    lgname;
enddefine;

define updaterof global active:1 logfilename(val);
lvars val tmp_id;
    if isstring(val) then
        val -> lgname;
        val -> ui_variable_display(ident logfilename, string_key);
    endif;
enddefine;


;;; logfrequency defines how often logging should occur during training
define global active:1 logfrequency;
    nn_event_timer;
enddefine;

define updaterof global active:1 logfrequency(val);
lvars val tmp_id;
    if isinteger(val)
       or ((strnumber(val) ->> val) and isinteger(val)) then
        val -> nn_event_timer;
        val -> ui_variable_display(ident logfrequency, boolean_key);
    endif;
enddefine;


;;; logecho defines whether log information is echoed to the screen
define global active:1 logecho;
    lgecho;
enddefine;

define updaterof global active:1 logecho(val);
lvars val;
    if isboolean(val) then
        val -> lgecho;
        if lgecho then
            unless member(nn_logscreen, nn_events) then
                nn_logscreen :: nn_events -> nn_events;
            endunless;
        else
            ncdelete(nn_logscreen, nn_events, nonop =) -> nn_events;
        endif;
        val -> ui_variable_display(ident logecho, boolean_key);
    endif;
enddefine;


;;; logfilewrite defines whether a log file is written
define global active:1 logfilewrite;
    lgwrite;
enddefine;

define updaterof global active:1 logfilewrite(val);
lvars val;
    if isboolean(val) then
        val -> lgwrite;
        if lgwrite then
            unless member(nn_logfile, nn_events) then
                nn_logfile :: nn_events -> nn_events;
            endunless;
        else
            ncdelete(nn_logfile, nn_events, nonop =) -> nn_events;
        endif;
        val -> ui_variable_display(ident logfilewrite, boolean_key);
    endif;
enddefine;


;;; logerror defines whether the error should be displayed in the logfile
define global active:1 logerror;
    lgerror;
enddefine;

define updaterof global active:1 logerror(val);
lvars val;
    if isboolean(val) then
        val -> lgerror;
        val -> ui_variable_display(ident logerror, boolean_key);
    endif;
enddefine;


;;; logaccuracy defines whether the accuracy (measured using high-level
;;; items) should be displayed in the logfile
define global active:1 logaccuracy;
    lgaccuracy;
enddefine;

define updaterof global active:1 logaccuracy(val);
lvars val;
    if isboolean(val) then
        val -> lgaccuracy;
        val -> ui_variable_display(ident logaccuracy, boolean_key);
    endif;
enddefine;


;;; logtestset defines whether the test example set should be applied
;;; to the network and displayed in the log file
define global active:1 logtestset;
    lgtestset;
enddefine;

define updaterof global active:1 logtestset(val);
lvars val;
    if isboolean(val) then
        val -> lgtestset;
        val -> ui_variable_display(ident logtestset, boolean_key);
    endif;
enddefine;


;;; logsavenet defines whether the current state of the network should
;;; be saved after each log
define global active:1 logsavenet;
    lgsavenet;
enddefine;

define updaterof global active:1 logsavenet(val);
lvars val;
    if isboolean(val) then
        val -> lgsavenet;
        val -> ui_variable_display(ident logsavenet, boolean_key);
    endif;
enddefine;

global vars nn_activevars = true;       ;;; for "uses"

endsection;     /* $-popneural */

/*  --- Revision History --------------------------------------------------
-- Julian Clinton, Feb  1 1993
    Moved definition of nn_update_wins in here from nn_defs.p.
-- Julian Clinton, Jul 28 1992
    Moved true definition of ui_variable_display to nui_panels.p.
*/
