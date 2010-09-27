/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/ved_latex/auto/latex_end.p
 > Purpose:         Automatic insertion of \end statements
 > Author:          Adrian Howard, Oct 13 1992
 */

/* --- Copyright University of Sussex 1992. All rights reserved. ----------
 > File:            auto/latex_end.p
 > Purpose:         Automatic insertion of \end statements
 > Author:          Adrian Howard, Oct 13 1992
 > Documentation:
 > Related Files:
 */



compile_mode: pop11 +strict;
section;



/*
 * Returns -true- if the position (ROW1, COL1) is before (ROW2, COL2).
 * Returns -false- otherwise.
 */
define:inline lconstant IsBefore(ROW1, COL1, ROW2, COL2);
    (ROW1<ROW2 or (ROW1==ROW2 and COL1<COL2))
enddefine;



/*
 * RETURNS A STRING CONTAINING THE ENVIRONMENT NAME OF THE MOST RECENT
 * \begin STATEMENT WITHOUT A MATCHING \end STATEMENT.
 *
 * RETURNS THE NULL STRING IF NO ENVIRONTMENT AFTER \begin
 *
 * DOES A -vederror- IF NO \begin STATEMENT EXISTS
 */
define lconstant find_end() -> end_string;
    lvars end_string = '';
    lvars nesting = 0,          ;;; # NESTED begin/end STATEMENTS
        begin_line, begin_col,  ;;; POSITION OF LAST \begin STATEMENT
        last_line, last_col,    ;;; POSITION OG LAST \end STATEMENT
        orig_line = vedline,    ;;; INITIAL POSITION IN VED FILE
        orig_col = vedcolumn;

    ;;; MOVE TO START POSITION ON EXIT
    dlocal 0 %, vedjumpto(orig_line, orig_col)%;

    ;;; SEARCH FOR \begin & \end STATEMENTS UNTIL A \begin WITHOUT A
    ;;; MATCHING \end IS FOUND
    lvars finished = false;
    until finished do;

        nesting+1 -> nesting;

        repeat nesting times;
            veddo('backsearch \\\\\\begin{');
        endrepeat;

        (vedline, vedcolumn) -> (begin_line, begin_col);
        -1 -> last_line;

        false;
        repeat nesting times;
            unless vedtestsearch('\\\\end', true)
                and IsBefore(last_line, last_col, vedline, vedcolumn)
                and IsBefore(vedline, vedcolumn, orig_line, orig_col)
                and IsBefore(begin_line, begin_col, vedline, vedcolumn)
            then
                erase(); true; quitloop;
            else
                (vedline, vedcolumn) -> (last_line, last_col);
            endunless;
        endrepeat -> finished;
    enduntil;

    ;;; GET THE STRING BETWEEN THE BRACES OF THE \begin STATEMENT
    vedjumpto(begin_line, begin_col);
    lvars line = vedbuffer(vedline);
    lvars start, fin;
    if (locchar(`{`, vedcolumn, line) ->> start) then
        if (locchar(`}`, start, line) ->> fin) then
            substring(start+1, fin-start-1, line) -> end_string;
        endif;
    endif;

enddefine;


/*
 * Insert a LaTex \end statement which matches the appropriate \bgin
 * in the current VED buffer.
 */
define global latex_end();
    lvars end_string;

    if (find_end() ->> end_string) = '' then
        vederror('COULD NOT FIND MATCHING \begin');
    else
        vedinsertstring('\\end{');
        vedinsertstring(end_string);
        vedinsertstring('}');
    endif;

enddefine;

endsection;
