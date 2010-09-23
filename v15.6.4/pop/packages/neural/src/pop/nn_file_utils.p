/*  --- Copyright Integral Solutions Ltd. 1992. All Rights Reserved --------
 > File:            $popneural/src/pop/nn_file_utils.p
 > Purpose:         utilities for accessing example data files
 > Author:          Julian Clinton, July 1992
 > Documentation:
 > Related Files:   nn_examplesets.p
*/

section $-popneural =>
                        nn_file_line_count
                        nn_file_column_count
                        nn_readline_file
;

include sysdefs;

;;; setup_file_dev takes a filename and a filetype (which is either
;;; "line", "item" or "char") and returns the raw file device, the
;;; appropriate repeater procedure, the end_of_line marker and
;;; a flag which defines the value of popnewline.
;;;
define setup_file_dev(filename, type)
            -> rawdev -> repeater -> endline_marker -> popnewline_p;
lvars filename type rawdev repeater endline_marker popnewline_p;

    ;;; can we open the file ?
    unless (sysopen(filename, 0, type, `A`) ->> rawdev) then
        mishap(filename, 1, 'Cannot open file');
    else    ;;; setup item or character repeater as appropriate
        discin(rawdev) -> repeater;
        `\n` -> endline_marker;
        false -> popnewline_p;
        if (type == "item") or (type == "line") then
            incharitem(repeater) -> repeater;
            newline -> endline_marker;
            true -> popnewline_p;
        endif;
    endunless;
enddefine;

;;; setup_file_count_vector takes the store_data (which may be an integer
;;; giving the size of the vector, the vector itself or false if the
;;; size is unknown), the file type and line flag. It returns the structure
;;; (a vector) which is to be used to store the file information. If
;;; store_data is false then store_structure will be returned as false
;;; except if type is "line" and the line_p flag is true (needed to
;;; signify whether we're are counting lines a line at a time or
;;; a column a line at a time).
;;;
define setup_file_count_vector(store_data, type, line_p) -> store_structure;
lvars store_data, type, line_p, store_structure;

    if isinteger(store_data) then
        if type == "line" then      ;;; only returning an integer
            0 -> store_structure;
        else                        ;;; else a vector of items
            consvector(repeat store_data times 0; endrepeat, store_data) -> store_structure;
        endif;
    elseif isvectorclass(store_data) then
        unless type == "line" then
            fill(repeat store_data times 0; endrepeat, store_data) -> store_structure;
        else    ;;; user has passed a vector for "line" type
            mishap(store_data, 1, 'integer needed for "line" file type');
        endunless;
    elseif store_data then     ;;; can pass false
        mishap(store_data, 1, 'integer or vectorclass needed');
    else        ;;; must have passed false
        if type == "line" and line_p then
            0
        else
            false
        endif -> store_structure;
    endif;
enddefine;


;;; get_filenames takes a pathname (which may contain wildcard characters)
;;; and returns a list of filenames which match the path specification.
;;;
define get_filenames(path) -> filelist;
lvars path nextfile nextdir fname dirpath file filter filelist;

    define lconstant has_wildcards(path) -> boole;
    lvars path boole;
#_IF DEF VMS
        (locchar(`*`, 1, path) or locchar(`%`, 1, path)) -> boole;
#_ELSE  /* UNIX */
        (locchar(`*`, 1, path) or locchar(`?`, 1, path)) -> boole;
#_ENDIF
    enddefine;

    ;;; if a path name has been nested within a list, this signifies
    ;;; that there is only one file to be read or written to but
    ;;; it has to be read as a complete file. In this case, we simply
    ;;; return the path...
    ;;;
    if islist(path) then
        path -> filelist;
        return();
    endif;

    ;;; otherwise we should have a string which we may be able to
    ;;; use to match against pathnames
    ;;;
    sys_fname_name(path) -> fname;

    ;;; have to use allbutlast to preserve any environment vars
    allbutlast(length(fname), path)-> dirpath;

    ;;; if the path does not contain wildcards then exit immediately
    ;;; returning the pathname
    unless has_wildcards(path) then
        path -> filelist;
        return();
    endunless;

    sys_file_match(fname, dirpath, false, true) -> nextfile;

    if nextfile() /== termin then
        erase();
        [% until (nextfile() ->> file) == termin do
            if file and not(sysisdirectory((dirpath dir_>< file) ->> file)) then
                file
            endif;
        enduntil %] -> filelist;
    endif;
enddefine;


/* ----------------------------------------------------------------- *

    Text File Information Routines.

    The following functions are used to try and find out information
    about example set data held in text files. The data can be arranged
    in rows or columns.

 * ----------------------------------------------------------------- */


;;; nn_file_line_count takes a string (the filename), the number of
;;; columns expected in the file (an integer OR a vector whose length
;;; is the number of columns) and a flag for the type of file. This
;;; flag takes the following args:
;;;
;;;         ORG         Use For
;;;         ---         -------
;;;         "char"      Character counting
;;;         "item"      Item counting
;;;         "line"      Line only
;;;
;;; Note that if the type is "line", the return result of the procedure
;;; is an integer.
;;; The procedure returns an integer or a vector (or the vector passed
;;; as the cols argument) where each item in the vector gives the
;;; number of lines of data in that column. This information may be
;;; used to calculate the number of examples in column-oriented
;;; continuous data.
;;;
define nn_file_line_count(filename, n_cols, type) -> line_data;
lvars col = 0, i accessor filename n_cols line_data filedev in_dev
        type endline item = false, maxcol = 0;
lconstant column_count = writeable newproperty([], 50, false, "perm");

dlocal popnewline;

    setup_file_dev(filename, type) -> filedev -> in_dev
                                    -> endline -> popnewline;

    setup_file_count_vector(n_cols, type, true) -> line_data;

    ;;; either do a fast loop updating integers or a slower loop
    ;;; updating the items in the vector
    if isinteger(line_data) then
        while (in_dev() ->> item) /== termin do
            if item == endline then
                0 -> col;
                line_data fi_+ 1 -> line_data;
            else
                col fi_+ 1 -> col;
            endif;
        endwhile;

        if (col /== 0) then     ;;; file has incomplete last line so
                                ;;; increment total by 1
            line_data fi_+ 1 -> line_data;
        endif;
    elseif isvectorclass(line_data) then
        class_subscr(datakey(line_data)) -> accessor;
        while (in_dev() ->> item) /== termin do
            if item == endline then
                0 -> col;
            else
                col fi_+ 1 -> col;
                accessor(col, line_data) fi_+ 1 -> accessor(col, line_data);
            endif;
        endwhile;
    else    ;;; we don't know how many columns in this file so
            ;;; use a property table
        while (in_dev() ->> item) /== termin do
            if item == endline then
                0 -> col;
            else
                col fi_+ 1 -> col;
                if col fi_> maxcol then
                    0 -> column_count(col);
                    col -> maxcol;
                endif;
                column_count(col) fi_+ 1 -> column_count(col);
            endif;
        endwhile;
        {% fast_for i from 1 to maxcol do
            column_count(i);
           endfast_for %} -> line_data;
    endif;
enddefine;


;;; nn_file_column_count takes a string (the filename), the number of
;;; lines expected in the file (an integer, a vector whose length
;;; is the number of lines or false if this is not known) and a flag
;;; for the type of file. This flag takes the following args:
;;;
;;;         ORG         Use For
;;;         ---         -------
;;;         "char"      Character counting
;;;         "item"      Item counting
;;;         "line"      Line only
;;;
;;; The procedure returns an integer or a vector (or the vector passed
;;; as the lines argument) where each item in the vector gives the
;;; number of columns of data in each line.
;;;
;;; Note that if the file type is "line", the return result of the procedure
;;; is undefined (it is effectively counting the number of lines per line).
;;;
define nn_file_column_count(filename, n_lines, type) -> column_data;
lvars row = 1, accessor filename n_lines column_data filedev in_dev
        current_line type endline item = false;
dlocal popnewline;

    setup_file_dev(filename, type) -> filedev -> in_dev
                                    -> endline -> popnewline;

    setup_file_count_vector(n_lines, type, false) -> column_data;

    ;;; either do a fast loop updating integers or a slower loop
    ;;; updating the items in the vector
    if isinteger(column_data) then
        while (in_dev() ->> item) /== termin do
            if item == endline then
                row fi_+ 1 -> row;
            else
                column_data fi_+ 1 -> column_data;
            endif;
        endwhile;
    elseif isvectorclass(column_data) then
        class_subscr(datakey(column_data)) -> accessor;
        while (in_dev() ->> item) /== termin do
            if item == endline then
                row fi_+ 1 -> row;
            else
                accessor(row, column_data) fi_+ 1
                                    -> accessor(row, column_data);
            endif;
        endwhile;
    else
        0 -> current_line;
        {% while (in_dev() ->> item) /== termin do
            if item == endline then
                row fi_+ 1 -> row;
                current_line;
                0 -> current_line;
            else
                current_line fi_+ 1 -> current_line;
            endif;
        endwhile;
        if current_line /== 0 then
            current_line;
        endif; %} -> column_data;
    endif;
enddefine;


;;; nn_readline_file takes a string representing a filename
;;; and returns a vector of vectors of items read from the
;;; file. The procedure can be passed a vector of vectors
;;; which it will use rather than creating a new vector.
;;;
define global nn_readline_file(name) -> vec;
lvars name vec = false, line linevec column item = 0, filedev;
dlocal popnewline;

    ;;; see if the user has passed somewhere to store the data
    if isvector(name) then
        name -> vec; -> name;
    endif;

    true -> popnewline;

    incharitem(discin(name)) -> filedev;

    if vec then     ;;; use existing vector
        1 ->> line -> column;
        while item /== termin do
            subscrv(line, vec) -> linevec;
            while (filedev() ->> item) /== termin and item /== newline do
                item -> subscrv(column, linevec);
                column fi_+ 1 -> column;
            endwhile;
            line fi_+ 1 -> line;
        endwhile;
    else
        {%
            while item /== termin do
                {% while (filedev() ->> item) /== termin and item /== newline do
                        item;
                    endwhile; %} -> line;
                unless length(line) == 0 then       ;;; ignore empty lines
                    line;
                endunless;
            endwhile;
        %} -> vec;
    endif;
enddefine;

global vars nn_file_utils = true;       ;;; for "uses"

endsection;     /* $-popneural */

/*  --- Revision History --------------------------------------------------
-- Julian Clinton, 27/4/93
    Fixed PNF0037 (nn_readline_file checking with isvectorclass).
-- Julian Clinton, 21/8/92
    Changed get_filenames so that it treats lists as a pre-supplied
    list of files.
-- Julian Clinton, 29/6/92
    Added get_filenames routine.
*/
