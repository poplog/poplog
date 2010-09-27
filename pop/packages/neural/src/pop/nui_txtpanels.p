/* --- Copyright Integral Solutions Ltd. 1992. All Rights Reserved --------
 > File:            $popneural/src/pop/nui_txtpanels.p
 > Purpose:         Text UI panel creators
 > Author:          Julian Clinton, July 1992
 > Documentation:
 > Related Files:
 */

section $-popneural;

pr(';;; Loading text panels\n');

uses nui_utils;


/* ----------------------------------------------------------------- *
     Text Dialogs
 * ----------------------------------------------------------------- */

;;; y_or_n_txt prints a the query message until a user
;;; types y, Y, yes, YES, n, N, no or NO and returns
;;; true if the request was positive (i.e. y, Y, yes or YES)
define constant y_or_n_txt(query) -> saidyes;
lvars query saidyes ans = [];

    until ans /== [] and (hd(ans) ->> ans) and
      (uppertolower(ans) ->> ans) and (ans == "y" or ans == "n") do
        boldpr(query <> ' (y/n) ');
        readline() -> ans ;
    enduntil;

    if ans == "y" then
        true
    else
        false
    endif -> saidyes;
enddefine;


define nui_message_txt(string);
lvars string;
    vedscreenbell();
    use_basewindow(false);
    npr(string);
    txt_pause();
enddefine;

;;; nui_confirm_txt takes a prompt, a set of options and a
;;; default (an integer which is the index of the default
;;; item in the list of options) and returns an integer which
;;; is the index of the options actually selected.
;;;
define nui_confirm_txt(prompt, options, default) -> val;
lvars prompt options rev_options opt default query firstchars val = false;

    ;;; need to remove any query characters as these are added to
    ;;; the prompt
    if (locchar(`?`, 1, prompt) ->> query) then
        substring(1, query - 1, prompt) -> prompt;
    endif;

    [%  fast_for opt in options do
            (uppertolower(opt))(1);
        endfast_for %] -> firstchars;

    subscrl(default, options) -> default;

    rev(options) -> rev_options;
    hd(rev_options); 'or %p';
    fast_for opt in tl(rev_options) do
        opt, '%p, %s';
    endfast_for;
    sprintf(prompt, '%p (%s)') -> prompt;

    sys_grbg_list(rev_options);

    until isword(val) and (uppertolower(val) ->> val) and
      member(val(1), firstchars) do
        get_1_item(prompt, isword, false) -> val;
    enduntil;

    index_in_list(val(1), firstchars) -> val;
enddefine;


define nui_singlechoice_txt(choice_list, prompt, list_label, action_label) -> val;
lvars choice_list prompt list_label action_label val = false;

    use_basewindow(true);
    nl(1);
    heading(prompt);
    nl(1);
    if islist(choice_list) and choice_list /== [] then
        print_list(sprintf(list_label, '%p: '), choice_list);
        get_1_item(prompt, member(%choice_list%), false) -> val;
    else
        npr('Sorry, no options available');
        txt_pause();
        false -> val;
    endif;
enddefine;


define nui_multichoice_txt(choice_list, prompt, list_label, action_label) -> vals;
lvars choice_list prompt list_label action_label vals;

    use_basewindow(true);
    nl(1);
    heading(prompt);
    nl(1);
    if islist(choice_list) and choice_list /== [] then
        print_list(sprintf(list_label, '%p: '), choice_list);
        get_lists(1, 'Selection', false, "all") -> vals;
        if vals = [all] then
            choice_list -> vals;
        endif;
    else
        npr('Sorry, no options available');
        txt_pause();
        false -> vals;
    endif;
enddefine;


/* ----------------------------------------------------------------- *
     Text Menu Utility Functions
 * ----------------------------------------------------------------- */

;;; print_menu_txt takes a title, a list of strings, a list of
;;; values and a boolean and displays a numbered list of the
;;; strings. If the boolean is true then the value of the corresponding
;;; variable is displayed. Note that  if values are being displayed
;;; then the maximum width is left as an extra argument on the stack.
define print_menu_txt(title, labels, values, show_vals);
lvars title maxwidth labels values show_vals num = length(labels);

    if show_vals then
        -> maxwidth;
    endif;

    nl(1);
    heading(title);
    bold_on();
    if show_vals then
        lvars index;
        for index from 1 to num do
            pr_field(index, 5, ` `, false);
            pr(' - ');
            pr(labels(index));
            sp(maxwidth - length(labels(index)));
            printf(idval(front(values(index))), ' (value %p)\n');
        endfor;
        nl(1);
    else
        for index from 1 to num do
            pr_field(index, 30, ` `, false);
            pr(' - ');
            npr(labels(index));
        endfor;
        nl(1);
    endif;
    bold_off();
enddefine;


;;; menu_choice_txt takes a list of values and a boolean
;;; and returns the value from the values list or false if false
;;; was allowed
define menu_choice_txt(values, allow_q) -> val;
lvars values allow_q int = 0, len = length(values), val = false;

    use_basewindow(false);
    while (int > len) or (int < 1) do
        bold_on();
        pr('Choose 1 to ');
        pr(len);
        if allow_q then
            pr(', q (to quit menu)');
        endif;
        pr(' or r (to redisplay) ');
        bold_off();
        contreadline() -> int;
        if int == [] or int = [?] then
            0 -> int;
        elseif allow_q and (int = [q] or int = [Q]) then
            quitloop();
        elseif int = [exit] and not(GUI) then
            nl(1);
            if nui_confirm_txt('Really exit from Poplog-Neural',
                ['Exit' 'Cancel'],1) == 1 then
                sysexit();
            else
                0 -> int;
            endif;
        elseif int = [r] then
            "r" -> val;
            quitloop();
        elseif member(hd(int), nn_commands) then
            obey_pop(int <> [^termin]);
            0 -> int;
        elseunless isinteger(hd(int) ->> int) then
            0 -> int;
        endif;
    endwhile;
    unless val == "r" then
        if isinteger(int) then
            menu_valof(values(int));
        else
            false
        endif -> val;
    endunless;
enddefine;


define show_menu_txt(title, labels, values, show_vals, allow_q) -> val;
dlocal nn_help = menuhelpfiles(title);
lvars title maxwidth labels values show_vals allow_q val = "r";

    ;;; if show vals then the window width should have been passed
    if show_vals then
        -> maxwidth;
    endif;
    while val == "r" then
        if show_vals then
            maxwidth;
        endif;
        print_menu_txt(title, labels, values, show_vals);
        menu_choice_txt(values, allow_q) -> val;
    endwhile;
enddefine;

define show_panel_txt(title, labels, values, show_vals, allow_q) -> val;
dlocal nn_help = menuhelpfiles(title);
lvars title, labels, values, show_vals, allow_q val = "r";
    while val == "r" then
        print_menu_txt(title, labels, values, show_vals);
        menu_choice_txt(values, allow_q) -> val;
    endwhile;
enddefine;


define show_options_txt(title, maxwidth, labels, values);
dlocal nn_help = menuhelpfiles(title);
lvars title maxwidth labels values show_vals result;
    repeat forever
        clear_screen();
        banner(nn_banner);
        show_menu_txt(maxwidth, title, labels, values, true, true) -> result;
        if result then
            change_var(front(result));
        else
            quitloop();
        endif;
    endrepeat;
enddefine;


;;; show_mainpanel_txt displays the top-level control panel.
;;;
define show_mainpanel_txt(title, labels, values) -> result;
dlocal nn_help = menuhelpfiles(title);
lvars title labels values result = "r";

    while result == "r" then
        print_menu_txt(title, labels, values, false);
        menu_choice_txt(values, false) -> result;
    endwhile;
enddefine;

global vars nui_txtpanels = true;       ;;; for "uses"

endsection;

/*  --- Revision History --------------------------------------------------
-- Julian Clinton, 26/8/95
    Added missing lvars declaration in print_menu_txt.
-- Julian Clinton, 11/8/92
    Added "exit" command to allow non-graphical UI users to exit
        Neural at anytime.
*/
