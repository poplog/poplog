/* --- Copyright Integral Solutions Ltd. 1992. All Rights Reserved --------
 > File:           $popneural/src/pop/nui_utils.p
 > Purpose:        miscellaneous user interface utility functions
 > Author:         Julian Clinton, July 1992
 > Documentation:
 > Related Files:
 */

section $-popneural;

pr(';;; Loading UI utilities\n');

uses fmatches;

/* ----------------------------------------------------------------- *
    UI Panel Predicates
 * ----------------------------------------------------------------- */

global constant
    NUI_MENU    = 1,        ;;; item names a menu structure
    NUI_PANEL   = 2,        ;;; item names a panel e.g. edit panel
    NUI_OPTIONS = 3,        ;;; items names an options table
;

define generic_ui_itemtype(list, type) -> boole;
lvars list type boole;
    (fast_front(list) == type) -> boole;
enddefine;

global constant procedure
    is_menu_ref     = generic_ui_itemtype(%NUI_MENU%),
    is_panel_ref    = generic_ui_itemtype(%NUI_PANEL%),
    is_options_ref  = generic_ui_itemtype(%NUI_OPTIONS%),
;


/* ----------------------------------------------------------------- *
    Support For Bold/Wide Printing On Text Terminals
 * ----------------------------------------------------------------- */

define constant prseq(seq);
;;; outputs an escape sequence, supplied either
;;; as a string or a list of ASCII codes
    seq, if vedediting
         then rawcharout
         else charout
         endif;
    if seq.islist
    then apply(applist)
    else apply(appdata)
    endif;
enddefine;


define constant IFVT100;
    unless member(nn_terminal, nn_std_ttys) then
        exitfrom(caller(1));
    endunless;
enddefine;


define constant normal_chars;
    IFVT100();
    prseq('\^[[0m');
enddefine;

define constant inverse_on;
    IFVT100();
    prseq([27 91 55 109])
enddefine;

define constant inverse_off;
    IFVT100();
    normal_chars();
enddefine;

define constant bold_on;
    IFVT100();
    prseq('\^[[1m');
enddefine;

define constant bold_off;
    IFVT100();
    normal_chars();
enddefine;

define constant underline_on;
    IFVT100();
    prseq('\^[[4m');
enddefine;

define constant underline_off;
    IFVT100();
    normal_chars();
enddefine;

define constant clear_screen;
    if member(nn_terminal, nn_std_ttys) then
        prseq([27 91 50 74]);
        if vedediting
        then
            vedrefresh();
        else
            ;;; get cursor home
            prseq([%27,91,`0,59,`0,72%]);
            ;;; prseq([12]);
        endif;
    else
        prseq([12]);
    endif;
enddefine;

define constant inverse_screen;
    IFVT100();
    prseq('\^[[?5h');
enddefine;

define constant normal_screen;
    IFVT100();
    prseq('\^[[?5l');
enddefine;

define constant reset_screen;
    normal_screen();
    normal_chars();
    clear_screen();
enddefine;

define constant boldpr(item);
lvars item;
    bold_on();
    pr(item);
    bold_off();
enddefine;

define constant boldppr(item);
lvars item;
    bold_on();
    ppr(item);
    bold_off();
enddefine;


;;; N.B. TALLPR and WIDEPR should only be used to start printing at the left
;;; margin of the screen, and throw a newline after printing.

define centre_text(string, factor);
lvars string factor num;
    ((poplinemax div 2) - ((length(string) div 2) * factor)) div factor -> num;
    repeat num times
        prseq(' ');
    endrepeat;
enddefine;

define widepr(item);
lvars item offset;
    if member(nn_terminal, nn_std_ttys) and not(vedediting) then
        centre_text(item, 2);
        prseq(sprintf(item, '\^[#6%p\n'));
    else
        centre_text(item, 1);
        npr(item);
    endif;
enddefine;

define heading(string);
lvars string offset;
    if member(nn_terminal, nn_std_ttys) then
        bold_on();
        widepr(string);
        bold_off();
    else
        nl(1);
        centre_text(string, 1);
        prseq(string);
        nl(1);
        centre_text(string, 1);
        repeat length(string) times prseq('-') endrepeat;
    endif;
    nl(1);
enddefine;

define tallpr(item);
lvars item;
    if member(nn_terminal, nn_std_ttys) and not(vedediting) then
        centre_text(item, 2);
        prseq('\^[#3');
        pr(item);nl(1);
        centre_text(item, 2);
        prseq('\^[#4');
        pr(item); nl(1);
    else
        heading(item);
    endif;
enddefine;

define banner(string);
lvars string;
    unless GUI then
        bold_on();
        tallpr(string);
        bold_off();
    endunless;
enddefine;

;;; use_basewindow will expose the base window and put the mouse cursor
;;; in it so the user can start typing data in
define constant use_basewindow(clearscr);
lvars clearscr;
    if GUI then
        if clearscr then
#_IF DEF PWMNEURAL
            if popunderpwm then
                pwm_force_input(pwmbasewindow);
            endif;
#_ENDIF
        endif;

#_IF DEF PWMNEURAL
        pwmbasewindow -> pwmtextwindow;
        sys_clear_input(poprawdevin);
        sysflush(poprawdevout);
#_ENDIF
    endif;
    if clearscr and (not(vedediting)) then
        clear_screen();
        banner(nn_banner);
    endif;
enddefine;

;;; fpr is like pr but flushes the output buffer
define constant fpr(string);
lvars string index;
    pr(string);
    sysflush(poprawdevout);
enddefine;

define constant print_list(title, list);
lvars title, list, index;
    npr(title);
    ppr(list);
    nl(1);
enddefine;

define build_titled_string(title, list) -> string;
lvars opt title list rev_list string count = listlength(list);

    rev(list) -> rev_list;
    hd(rev_list); '%p';
    fast_for opt in tl(rev_list) do
        count fi_- 1 -> count;
        if count mod 5 == 0 then
            opt, '%p,\n%s';
        else
            opt, '%p, %s';
        endif;
    endfast_for;
    sprintf(title, '%p\n%s\n') -> string;
    sys_grbg_list(rev_list);
enddefine;


/* ----------------------------------------------------------------- *
    On-line Help Utilities
 * ----------------------------------------------------------------- */

define constant ishelp_request(item) -> needs_help;
lvars needs_help = false;
    if isword(item) then
        (item == "help" or item == "?") -> needs_help;
    elseif isstring(item) then
        (item = 'help' or item = '?') -> needs_help;
    elseif islist(item) then
        (item = [help] or item = [?]) -> needs_help;
    endif;
enddefine;

define constant help_on(topic);
lvars topic;
    popval([help ^topic]);
enddefine;


;;; obey_pop takes a list and executes the command
define obey_pop(list);
dlocal nn_exitfromproc = obey_pop;
lvars list;
    popval(list);
enddefine;


/* ----------------------------------------------------------------- *
    General User Input Routines
 * ----------------------------------------------------------------- */

;;; string_input simply reads characters using CHARIN until
;;; a newline is encountered. Note that if no items are entered,
;;; string_input returns -nullstring- so == can be used to check for
;;; the empty string.
define lconstant string_input() -> string;
dlocal popprompt = ' ';
lvars count = 0, char, string;

    while (charin() ->> char) /== termin
      and char /== newline
      and char /== 10 do
        count fi_+ 1 -> count;
        char;
    endwhile;
    if count == 0 then
        nullstring
    else
        fill(inits(count))
    endif -> string;
enddefine;


;;; get_string prints the prompt and returns whatever the user
;;; typed in as a string
define constant get_string(prompt) -> string;
lvars prompt string;
    boldpr(prompt);
    string_input() -> string;
enddefine;

;;; inputerr is used if an input error has been found
define constant inputerr(str);
lvars str;
    printf(str, 'Error: %p - please re-enter...\n');
enddefine;


;;; contreadline is exactly the same as readline except that typing
;;; a '\' character as the last item causes readline to be called again
;;; with the results being appended
define contreadline() -> list;
lvars list = [], inlist butlast;

    repeat forever
        while (readline() ->> inlist) fmatches [??butlast \] then
            list <> butlast -> list;
        endwhile;
        unless inlist == termin then
            list <> inlist -> list;
        endunless;
        if ishelp_request(list) and nn_help then
            if isword(nn_help) then
                help_on(nn_help);
            elseif isprocedure(nn_help) then
                apply(nn_help);
            endif;
            [] ->> list -> inlist;
        else
            quitloop();
        endif;
    endrepeat;
enddefine;


;;; get_1_item keeps looping until the user types in a single item
;;; of the required type
;;;
define constant get_1_item(prompt, predicate, type) -> list;
dlocal pop_readline_prompt = ' ? ';
lvars prompt predicate type list = [];
    repeat forever
        boldpr(prompt);
        readline() -> list;
        if length(list) > 1 then
            inputerr('only 1 item needed');
        elseif length(list) == 1 and not(predicate(hd(list))) then
            if type then
                inputerr(type sys_>< ' needed');
            endif;
            [] -> list;
        elseif list /== [] then
            hd(list) -> list;
            quitloop();
        endif;
    endrepeat;
enddefine;


;;; contrequestline is exactly the same as requestline except that typing
;;; a '\' character as the last item causes requestline to be called again
;;; with the results being appended
define constant contrequestline(prompt) -> list;
dlocal pop_readline_prompt = ' ? ';
    boldpr(prompt);
    contreadline() -> list;
enddefine;


;;; get_item_default takes a prompt and a default. It prints the prompt
;;; along with the default and returns the first item typed or the
;;; default value if the empty list was returned.
define constant get_item_default(types, prompt, default) -> item;
dlocal pop_readline_prompt = ' ? ';
lvars types prompt default deftype = dataword(default),
      item = undef, temp;
    repeat forever
        bold_on();
        pr(prompt);
        pr(' (default ');
        pr(default);
        pr(')');
        bold_off();
        contreadline() -> item;
        if item /== [] then
            if deftype == "string" then
                packitem(item) -> temp;
                consstring(explode(temp), length(temp));
            elseif deftype == "procedure" then
                popval(item)
            elseif length(item) == 1
             and (dataword(hd(item)) == deftype
              or not(member("pair", types))) then
                hd(item)
            elseif (hd(item) ->> temp) == "[" or temp == "{" then
                popval(item)
            else
                item
            endif;
        else
            default
        endif -> item;
        if dataword(item) == deftype then
            quitloop();
        elseif isnumber(item) and isnumber(default) then
            quitloop();
        elseif member(dataword(item), types) then
            quitloop();
        else
            inputerr(deftype sys_>< ' expected');
        endif;
    endrepeat;
enddefine;


define lconstant describe_dt(dtname);
lvars dtname dt type;

    nn_datatypes(dtname) -> dt;

    npr(nn_dt_type(dt));
    nn_dt_type(dt) -> type;

    if type == "set" then
        print_list('Set members:', nn_dt_setmembers(dt));
    elseif type == "range" then
        printf(nn_dt_upperbound(dt), nn_dt_lowerbound(dt),
            'Range from %p to %p\n');
    elseif type == "toggle" then
        printf(nn_dt_toggle_false(dt), nn_dt_toggle_true(dt),
            'Toggle: true val = %p, false val = %p\n');
    else
        pr('Items needed: ');
        npr(nn_items_needed(dt));
        pr('Input converter: ');
        npr(nn_dt_inconv(dt));
        pr('Output converter: ');
        npr(nn_dt_outconv(dt));
    endif;
enddefine;


define global get_user_example(name_list, type_list) -> example;
lvars name_list type_list example filenames name type val = false;
lconstant literal_query = 'Value for %p field (%p) ';
lconstant file_query = 'Filename for %p field ?';

    if is_file_dt(hd(type_list)) then
        npr('Please enter the name of the file (without string quotes) which');
        npr('holds the example for the specified field.');
        [% for name type in name_list, type_list do
            false -> val;
            until isstring(val) do
                printf(name, file_query);
                string_input() -> val;
                if ishelp_request(val) then
                    false -> val;
                    describe_dt(type);
                endif;
            enduntil;
            [% val %];      ;;; force the whole file to be read
        endfor %] -> filenames;
        nn_get_example_from_files(filenames, type_list, false) -> example;
    else
        [% for name type in name_list, type_list do
            until val do
                printf(type, name, literal_query);
                contreadline() -> val;
                if ishelp_request(val) then
                    false -> val;
                    describe_dt(type);
                endif;
            enduntil;
            explode(val);
            false -> val;
        endfor %] -> example;
    endif;
enddefine;

define global show_user_result(name_list, type_list);
lvars name_list type_list example filenames literal_query name type val = false;
lconstant file_query = 'Filename for %p field ?';

    if is_file_dt(hd(type_list)) then
        npr('Please enter the name of the file (without string quotes) which');
        npr('holds the example for the specified field.');
        [% for name type in name_list, type_list do
            false -> val;
            until isstring(val) do
                printf(name, file_query);
                string_input() -> val;
                if ishelp_request(val) then
                    false -> val;
                    describe_dt(type);
                endif;
            enduntil;
            [% val %];      ;;; force the whole file to be read
        endfor %] -> filenames;
        nn_get_example_from_files(filenames, type_list, false) -> example;
    else
        [% for name type in name_list, type_list do
            until val do
                printf(type, name, literal_query);
                contreadline() -> val;
                if ishelp_request(val) then
                    false -> val;
                    describe_dt(type);
                endif;
            enduntil;
            explode(val);
            false -> val;
        endfor %] -> example;
    endif;
enddefine;

define constant get_directory() -> dir;
lvars dir;
    repeat forever
        sysfileok(get_item_default([], 'Which directory', sysdirectory()))
            -> dir;
        if isdirectory(dir) then
            quitloop();
        else
            inputerr('invalid directory');
        endif;
    endrepeat;
    pr('Directory: ');
    npr(dir);
enddefine;


;;; get_strings takes a prompt, and returns a list of strings typed
;;; in. Input is terminated by entering nothing or, if int is an
;;; integer, after int reads.
define constant get_strings(prompt, int) -> string_list;
lvars listify string_list = [], int index = 1, str, len;
    if isinteger(int) then
        [% for index from 1 to int do
            get_string(sprintf(index, prompt, '%p %p'));
        endfor %] -> string_list;
    else
        npr('To finish, press RETURN without typing anything.');
        [%
            while (get_string(sprintf(index, prompt, '%p %p ? ')) ->> str)
                        /== nullstring do
                index + 1 -> index;
                str;
            endwhile;
        %] -> string_list;
    endif;
enddefine;


;;; get_lists takes a length (integer or false) , a prompt, a listify flag
;;; and a terminating item (item or false) and returns a list of lists typed
;;; in. Input is terminated by entering nothing or if the user
;;; enters the "terminating" result specified by ender. The listify
;;; flag (when true) will always return the results as a list (even
;;; if there is only one item in the list)
define constant get_lists(len, prompt, listify, ender) -> listslist;
lvars listify ender listslist = [], index = 1, eg, len;
    pr('To finish, ');
    if ender then pr('type "' >< ender >< '" or '); endif;
    npr('press RETURN without typing anything.');
    [%
        while (contrequestline(prompt >< ' ' >< (index >< '')) ->> eg)
                    /== [] do
            if len and length(eg) /== len then
                inputerr(len >< ' items expected');
                nextloop();
            endif;
            index + 1 -> index;
            if listify then
                [% explode(eg) %]
            elseif length(eg) == 1 then
                hd(eg)
            elseif hd(eg) == "[" or hd(eg) == "{" then
                popval(eg)
            else
                eg
            endif;
            if ender and fast_front(eg) = ender then
                quitloop();
            endif;
        endwhile;
    %] -> listslist;
enddefine;


;;; edit_flag_value takes a string, two items which correspond to
;;; displayed values for true and false and the current value
;;; of the flag The return value is the boolean result which should
;;; be assigned into the access_var.
;;;
define edit_flag_value(prompt, true_val, false_val, access_var) -> val;
lvars prompt true_val false_val true_char false_char
      access_var val = false, default;

    if access_var then
        true_val
    else
        false_val
    endif -> default;

    true_val(1) -> true_char;
    false_val(1) -> false_char;

    until isword(val) and
      (uppertolower(val) ->> val) and
      (subscrw(1,val) == true_char or subscrw(1,val) == false_char) do
        get_item_default([word], prompt, default) -> val;
    enduntil;

    if subscrw(1,val) == true_char then
        true
    else
        false
    endif -> val;
enddefine;


;;; change_var takes an ident and updates the idval the ident
define constant change_var(var);
lvars var;
    if isboolean(idval(var)) then
        not(idval(var)) -> idval(var);
    else
        get_item_default([], 'New value', idval(var)) -> idval(var);
    endif;
enddefine;


/* ----------------------------------------------------------------- *
    General Output Routines
 * ----------------------------------------------------------------- */

define constant txt_pause();
dlocal pop_readline_prompt = '';
    unless GUI then
        use_basewindow(false);
        boldpr('(Press RETURN to continue ...)');
        readline()->;
    endunless;
enddefine;

define constant say(string);
lvars string;
    use_basewindow(false);
    npr(string);
enddefine;

;;; call_genfn is used to get any arguments required by the generator
;;; function from the user
define constant call_genfn(egsname);
lvars egsname args = [], egs_rec;

    nn_example_sets(egsname) -> egs_rec;

    unless egs_rec then
        return();
    endunless;

    if egs_from_proc(egs_rec) then
        printf(egsname,
            'Enter any arguments required by %p\'s generator function.\n');
        npr('Multiple arguments should be separated by commas.');
        contrequestline('Arguments ') -> args;
    endif;
    printf(egsname, 'Generating %p...\n');
    unless args == [] then
        nn_generate_egs(popval(args), egsname);
    else
        nn_generate_egs(egsname);
    endunless;
    npr('done.');
enddefine;


/* ----------------------------------------------------------------- *
    Interrupt Handling
 * ----------------------------------------------------------------- */

define nn_interrupt();
dlocal pop_readline_prompt = '';
    if nn_exitfromproc == interrupt then
        chain(setpop);
    else
        unless GUI then
            use_basewindow(false);
            nl(1);
            npr('(Interrupt - press RETURN ...)');
            readline()->;
            clearstack();
            if isprocedure(nn_exitfromproc) then
                exitfrom(nn_exitfromproc);
            else
                chain(setpop);
            endif;
        else
            chain(setpop);
        endunless;
    endif;
enddefine;

global vars nui_utils = true;       ;;; for "uses"

endsection;

/*  --- Revision History --------------------------------------------------
-- Julian Clinton, 26/8/95
    Added missing lvars declaration in describe_dt.
-- Julian Clinton, 22/3/94
    Modified names of some PWM routines to use the new names.
-- Julian Clinton, 27/04/93
    Changed nn_interrupt to check that nn_exitfromproc is a procedure
    before calling it and if not, to simply chain setpop.
-- Julian Clinton, 14/10/92
    Changed name of -in_string- to -string_input- and made it lconstant.
    -in_string- was clashing with the for-loop syntax which caused ved_man
    to stop working when Neural was loaded.
-- Julian Clinton, 13/8/92
    -get_user_example- now gives a little help to the user about the
        datatype being requested.
-- Julian Clinton, Jul 23 1992
    Moved text, PWM and X panel routines into separate files.
*/
