/*  --- Copyright Integral Solutions Ltd. 1989. All Rights Reserved ---------
 > File:           $popneural/src/pop/nn_dtconverters.p
 > Purpose:        type conversion functions
 > Author:         Julian Clinton, Sept 1989
 > Documentation:
 > Related Files:  nn_structs.p
 */

section $-popneural =>  nn_dt_setmembers
                        nn_dt_setthreshold
                        nn_dt_lowerbound
                        nn_dt_upperbound
                        nn_dt_toggle_true
                        nn_dt_toggle_false
                        nn_dt_field_sequence
                        nn_dt_field_choiceset
                        nn_dt_field_starter
                        nn_dt_field_ender
                        nn_dt_field_separator
                        nn_dt_file_in_bytestruct
                        nn_dt_file_out_bytestruct
                        nn_dt_file_recipient
                        nn_dt_file_datatypes
                        DT_TOGGLE
                        DT_SET
                        DT_RANGE
                        DT_SEQ_FIELD
                        DT_CHOICE_FIELD
                        DT_CHAR_FILE
                        DT_ITEM_FILE
                        DT_LINE_FILE
                        DT_FULL_FILE
                        DT_GENERAL
                        nn_delete_dt
                        nn_declare_general
                        nn_declare_range
                        nn_declare_set
                        nn_declare_toggle
                        nn_declare_field_format
                        nn_declare_file_format
                        nn_declare_charfile
                        nn_declare_itemfile
                        nn_declare_linefile
                        nn_declare_fullfile
                        nn_items_needed
                        nn_units_needed
;

/* ----------------------------------------------------------------- *
    Datatype Constants
 * ----------------------------------------------------------------- */

global constant
    DT_TOGGLE = "toggle",
    DT_SET = "set",
    DT_RANGE = "range",
    DT_SEQ_FIELD = "sequence_field",
    DT_CHOICE_FIELD = "choice_field",
    DT_CHAR_FILE = "char_file",
    DT_ITEM_FILE = "item_file",
    DT_LINE_FILE = "line_file",
    DT_FULL_FILE = "full_file",
    DT_GENERAL = "general",
;


/* ----------------------------------------------------------------- *
    Datatype Accessors
 * ----------------------------------------------------------------- */

define get_dt_record(name) -> dt_rec;
lvars dt_rec name;
    if isword(name) and (nn_datatypes(name) ->> dt_rec) then
        dt_rec
    else
        name
    endif -> dt_rec;
enddefine;


define lconstant no_check_dt_accessor(type_entry, accessor) -> item;
lvars type_entry accessor item;
    get_dt_record(type_entry) -> type_entry;
    accessor(type_entry) -> item;
enddefine;

define updaterof no_check_dt_accessor(item, type_entry, accessor);
lvars type_entry accessor item;
    get_dt_record(type_entry) -> type_entry;
    item -> accessor(type_entry);
enddefine;


;;; dt_in_nargs returns the number results required by the
;;; input converter function. This number is also the number of
;;; results returned by the output converter function
define global dt_in_nargs(type_entry) -> num;
lvars type_entry num;
    get_dt_record(type_entry) -> type_entry;
    nn_dt_format(type_entry)(1) -> num;
enddefine;

define updaterof global dt_in_nargs(val, type_entry);
lvars val type_entry;
    get_dt_record(type_entry) -> type_entry;
    val -> nn_dt_format(type_entry)(1);
enddefine;


;;; dt_out_nargs returns the number results returned by the
;;; input converter function. This number is also the number of
;;; units a network needs to represent this type
define global dt_out_nargs(type_entry) -> num;
lvars type_entry num;
    get_dt_record(type_entry) -> type_entry;
    nn_dt_format(type_entry)(2) -> num;
enddefine;

define updaterof global dt_out_nargs(val, type_entry);
lvars val type_entry;
    get_dt_record(type_entry) -> type_entry;
    val -> nn_dt_format(type_entry)(2);
enddefine;



/* ----------------------------------------------------------------- *
    Datatype Converters
 * ----------------------------------------------------------------- */

define global nn_boole_real(boole) -> num;
    lvars boole num;
    if boole == "true" then
        1.0 -> num;
    elseif boole == "false" then
        0.0 -> num;
    else
        mishap(boole, 1, '"true" or "false" expected');
    endif;
enddefine;

define global nn_real_boole(num) -> boole;
lvars boole num;
    if num > 0.5 then "true" else "false" endif -> boole;
enddefine;

define global nn_bit_real(bit) -> num;
lvars bit num;
    number_coerce(bit, 1.0) -> num;
enddefine;

define global nn_real_bit(num) -> bit;
lvars bit num;
    if num > 0.5 then 1 else 0 endif -> bit;
enddefine;

define global nn_range_real(num, smallest, biggest);
lvars num smallest biggest;
    max(0.0, min(1.0,
                number_coerce((num - smallest) / (biggest - smallest), 1.0)));
enddefine;

define global nn_real_range(num, smallest, biggest);
lvars num smallest biggest tmp;
    number_coerce((num * (biggest - smallest)) + smallest, biggest) -> tmp;
    if isinteger(biggest) then
        intof(tmp + 0.5);
    else
        tmp;
    endif;
enddefine;



/* ----------------------------------------------------------------- *
    Validation Routines
 * ----------------------------------------------------------------- */

define check_dt_name(name);
lvars name;

    unless isword(name) then
        mishap(name, 1, 'Datatype name must be a word');
    endunless;
enddefine;


/* ----------------------------------------------------------------- *
    Datatype Predicates
 * ----------------------------------------------------------------- */

define global is_X_dt(type, word) -> boole;
lvars type boole word;
    get_dt_record(type) -> type;
    if isnn_dt_record(type) then
        nn_dt_type(type) -> type;
    endif;
    if type == word then
        word
    else
        false
    endif -> boole;
enddefine;

global vars procedure
    is_set_dt = is_X_dt(%DT_SET%),
    is_range_dt = is_X_dt(%DT_RANGE%),
    is_toggle_dt = is_X_dt(%DT_TOGGLE%),
    is_general_dt = is_X_dt(%DT_GENERAL%),
    is_seq_field_dt = is_X_dt(%DT_SEQ_FIELD%),
    is_choice_field_dt = is_X_dt(%DT_CHOICE_FIELD%),
    is_char_file_dt = is_X_dt(%DT_CHAR_FILE%),
    is_item_file_dt = is_X_dt(%DT_ITEM_FILE%),
    is_line_file_dt = is_X_dt(%DT_LINE_FILE%),
    is_full_file_dt = is_X_dt(%DT_FULL_FILE%),
;

define global is_simple_dt(type) -> boole;
lvars type boole;
    get_dt_record(type) -> type;
    if isnn_dt_record(type) then
        nn_dt_type(type) -> type;
    endif;
    if type == DT_SET or
        type == DT_RANGE or
        type == DT_TOGGLE or
        type == DT_GENERAL then
        type
    else
        false
    endif -> boole;
enddefine;

define global is_field_dt(type) -> boole;
lvars type boole;
    get_dt_record(type) -> type;
    if isnn_dt_record(type) then
        nn_dt_type(type) -> type;
    endif;
    if type == DT_SEQ_FIELD or
        type == DT_CHOICE_FIELD then
        type
    else
        false
    endif -> boole;
enddefine;

define global is_file_dt(type) -> boole;
lvars type boole;
    get_dt_record(type) -> type;
    if isnn_dt_record(type) then
        nn_dt_type(type) -> type;
    endif;
    if type == DT_CHAR_FILE
        or type == DT_ITEM_FILE
        or type == DT_LINE_FILE
        or type == DT_FULL_FILE then
        type
    else
        false
    endif -> boole;
enddefine;


/* ----------------------------------------------------------------- *
    General Datatype Constructor Function
 * ----------------------------------------------------------------- */

;;; nn_declare_general originally took four arguments, now by default
;;; it only takes three. In the past, separate input and output
;;; converters had to be provided. Now a single procedure with an
;;; updater can be used. When using this method, the converter function
;;; can either be passed explicitly, as a word (in which case it is
;;; passed as an argument to loadlib (i.e. re-declaring the argument
;;; re-compiles the library) or as a string (then it is passed to a
;;; trycompile). In both cases, the -valof- the word is obtained and
;;; it and its updater passed as the arguments to the declaration.
;;;
define global nn_declare_general(name, format, inconv);
lvars name format inconv outconv savedata = false;
    if isprocedure(format) then     ;;; passed an extra procedure
        inconv -> outconv;
        format -> inconv;
        name -> format; -> name;
    else
        if isword(inconv) then          ;;; definition is in a library
            inconv -> savedata;
            loadlib(inconv);
            valof(inconv) -> inconv;
        elseif isstring(inconv) then    ;;; definition is in a file
            inconv -> savedata;
            unless trycompile(inconv) then
                mishap(inconv, 1,
                    'Cannot locate datatype converter function');
            endunless;
            valof(consword(sys_fname_nam(inconv))) -> inconv;
        endif;
        updater(inconv) -> outconv;
    endif;
    check_dt_name(name);
    consnn_dt_record(format, inconv, outconv, DT_GENERAL, savedata)
        -> nn_datatypes(name);
enddefine;


/* ----------------------------------------------------------------- *
     Toggle Constructor And Conversion Functions
 * ----------------------------------------------------------------- */

;;; Toggles are used as simple flags. A toggle is mapped to a single
;;; input or output unit. The converters are closures of the two
;;; procedures -toggle_to_real- and -real_to_toggle-.
;;;
define toggle_to_real(val, true_val, false_val);
    if val = true_val then
        1.0
    elseif val = false_val then
        0.0
    else
        mishap(val, 1, 'unknown toggle value');
    endif;
enddefine;

define real_to_toggle(val, true_val, false_val);
lvars val true_val false_val;
    if val > 0.5 then
        true_val
    else
        false_val
    endif;
enddefine;

define toggle_field(type_entry, field) -> val;
lvars val type_entry;
    get_dt_record(type_entry) -> type_entry;
    frozval(field, nn_dt_inconv(type_entry)) -> val;
enddefine;

define updaterof toggle_field(val, type_entry, field);
lvars val type_entry;
    get_dt_record(type_entry) -> type_entry;
    val ->> frozval(field, nn_dt_inconv(type_entry))
        -> frozval(field, nn_dt_outconv(type_entry));
enddefine;

global vars procedure
    nn_dt_toggle_true = toggle_field(%1%),
    nn_dt_toggle_false = toggle_field(%2%),
;

;;; nn_declare_toggle used to set a unit to 1 or 0
define global nn_declare_toggle(name, true_val, false_val);
lvars name true_val false_val;
    check_dt_name(name);
    consnn_dt_record([1 1],
                     toggle_to_real(%true_val, false_val%),
                     real_to_toggle(%true_val, false_val%),
                     DT_TOGGLE, false) -> nn_datatypes(name);
enddefine;


/* ----------------------------------------------------------------- *
     Range Constructor Function
 * ----------------------------------------------------------------- */

;;; nn_declare_range
define global nn_declare_range(name, smallest, biggest);
lvars name range rangevec smallest biggest;
    check_dt_name(name);
    consnn_dt_record([1 1],
                     nn_range_real(%smallest, biggest%),
                     nn_real_range(%smallest, biggest%),
                     DT_RANGE, false) -> nn_datatypes(name);
enddefine;


/* ----------------------------------------------------------------- *
     Set Constructor And Conversion Functions
 * ----------------------------------------------------------------- */

;;; maxseq takes a sequence of numbers and returns the index
;;; of the first occurence of the highest number in the sequence.
define maxseq(seq) -> index;
lvars seq count len = length(seq),
      index = -1, num maxnum = -1000;
    for count from 1 to len do
        seq(count) -> num;
        if num > maxnum then
            num -> maxnum;
            count -> index;
        endif;
    endfor;
enddefine;

;;; base_set_in_fn is the basic procedure used to create closures for
;;; returning the values for presence or absence of set members
;;; in a form suitable for presentation to a network. The procedure
;;; can accept single items (words) or lists of items.
define base_set_in_fn(items, setsize, set);
lvars item items i;

    if islist(items) then
        fast_for i from 1 to length(items) do
            unless member(items(i), set) then
                sysprmessage(set, items(i), 2, 'item not in set',
                    'WARNING   :', 2);
            endunless;
        endfast_for;
        fast_for i from setsize by -1 to 1 do
            if member(set(i), items) then 1.0 else 0.0 endif;
        endfast_for;
    else    ;;; items as a single word, number etc.
        unless member(items, set) then
            npr(';;; Warning: ' >< items >< ' not in defined set');
        endunless;
        fast_for i from setsize by -1 to 1 do
            if set(i) = items then 1.0 else 0.0 endif;
        endfast_for;
    endif;
enddefine;

;;; cons_set_in_fn takes a set and returns a closure of -base_set_in_fn-
;;; which will convert the given set into a form to be presented
;;; to networks.
define cons_set_in_fn(set) -> fn;
    lvars set;
    lvars setlist = conslist(explode(set), length(set));
    base_set_in_fn(%length(setlist), setlist%) -> fn;
enddefine;


;;; base_set_out_fn takes the real numbers left on the stack and returns
;;; the item in the set corresponding to the highest of those values
;;; returned. Alternatively, if threshold is a number, it will return
;;; a list containing all the set items whose output unit was returning
;;; a value >= threshold (i.e. this procedure will always return 1 item)
;;;
define base_set_out_fn(outvec, set, threshold);
lvars outvec set i threshold;

    fill(outvec) -> outvec;
    if threshold then
        [% fast_for i from 1 to datalength(outvec) do
            if subscrv(i, outvec) >= threshold then
                set(i);
            endif;
        endfast_for; %];

    else
        set(maxseq(outvec));
    endif;
enddefine;


;;; cons_set_out_fn returns a closure of base_set_out_fn
define cons_set_out_fn(set, threshold) -> fn;
lvars fn set threshold len = length(set),
      setlist = conslist(explode(set), len);
    base_set_out_fn(%initv(len), setlist, threshold%) -> fn;
enddefine;


;;; nn_declare_set takes a name of a set, a list of set items (as
;;; words) and an optional threshold value. Without the threshold
;;; value, a single item is returned from the network output. When
;;; a threshold value is supplied, a list of set members whose output
;;; units had an activation >= threshold is returned.
;;;
define global nn_declare_set(name, set);
lvars name set setvec threshold = false;

    if isnumber(set) or not(set) then
        ;;; if a number or false, then user has passed a threshold so
        ;;; re-order the call arguments
        set -> threshold;
        name -> set;
        -> name;
    endif;

    check_dt_name(name);

    unless islist(set) then
        mishap('Set must be a list', [^set]);
    else
        consnn_dt_record([1 ^(length(set))],
                         cons_set_in_fn(set),
                         cons_set_out_fn(set, threshold),
                         DT_SET, false) -> nn_datatypes(name);
    endunless;
enddefine;


/* ----------------------------------------------------------------- *
     Field Format Constructor And Conversion Functions
 * ----------------------------------------------------------------- */

;;; The sequence and choice field datatypes do not have "proper"
;;; converter functions but supply data to the example parser about
;;; the format of the field.
;;;
;;;     Sequence:input and output contain the user-supplied format list
;;;
;;;     Choice:input and output contain a vector of setname, starter, ender
;;;             and separator.
;;;
;;; Note that in both cases, the same structure is used for input and output
;;; so that although altering the input structure will also alter the output
;;; structure, assigning a new value to one will not alter the other.

define lconstant extract_seq_dts(seq) -> type_list;
lvars seq item type_list = [];

    while seq /== [] do
        dest(seq) -> seq -> item;
        if item == "\" then     ;;; next item is a datatype
            dest(seq) -> seq -> item;
            item :: type_list -> type_list;
        endif;
    endwhile;
    ncrev(type_list) -> type_list;
enddefine;


define global nn_dt_field_sequence(type_entry) -> seq;
lvars type_entry seq;
    get_dt_record(type_entry) -> type_entry;
    nn_dt_inconv(type_entry) -> seq;
enddefine;

define updaterof nn_dt_field_sequence(val, type_entry);
lvars val type_entry seq;
    get_dt_record(type_entry) -> type_entry;
    val ->> nn_dt_inconv(type_entry) -> nn_dt_outconv(type_entry);
    extract_seq_dts(val) -> nn_dt_format(type_entry);
enddefine;


;;; For choice fields, use a generic function and create closures
define choice_field_item(type_entry, field) -> val;
lvars type_entry field val;
    get_dt_record(type_entry) -> type_entry;
    nn_dt_inconv(type_entry)(field) -> val;
enddefine;

define updaterof choice_field_item(val, type_entry, field);
lvars type_entry field val;
    get_dt_record(type_entry) -> type_entry;
    val ->> nn_dt_inconv(type_entry)(field)
        -> nn_dt_outconv(type_entry)(field);
enddefine;

global vars procedure
    nn_dt_field_choiceset = no_check_dt_accessor(%nn_dt_format%),
    nn_dt_field_starter = choice_field_item(%1%),
    nn_dt_field_ender = choice_field_item(%2%),
    nn_dt_field_separator = choice_field_item(%3%),
;


;;; nn_declare_field_format takes a format name and other arguments which
;;; depend on the type of format being created. Currently only text
;;; file formats are supported.
;;;
;;; For a set selection format (N-of-M items), the call is:
;;;
;;;     nn_declare_field_format(<name>, <set-name>,
;;;                         <start-item>, <end-item>, <separator>);
;;;
;;; <set-name> is a word giving the set datatype name (which must
;;; already exist.
;;; <start-item>, <separator> and <end-item> are each either characters
;;; or -false-. At least one of <separator> and <end-item> must be a
;;; character.
;;;
;;; For a sequence, format is simply a list containing the
;;; datatypes and any separators (which again must be a single
;;; character). All datatypes have to be escaped with "\" e.g.
;;;
;;;     nn_declare_range("minutes", 0, 59);
;;;     nn_declare_range("seconds", 0, 59);
;;;     nn_declare_field_format("time",
;;;                [\minutes minutes and \seconds seconds]);
;;;
;;; will parse: [15 minutes and 20 seconds] correctly. Note that
;;; you can supply alternatives as a list of items.
;;;
define global nn_declare_field_format(name, format);
lvars name format starter ender separator setname choice_vec
      all_items type_list;

    if islist(format) then
        check_dt_name(name);
        ;;; extract the basic datatypes so we can work out
        ;;; how many units will be needed
        format -> all_items;
        extract_seq_dts(all_items) -> type_list;
        consnn_dt_record(type_list, format, format,
                         DT_SEQ_FIELD, false) -> nn_datatypes(name);

    else
        ;;; must be an N-of-M selection so re-arrange the args to
        ;;; (name, setname, starter, ender, separator)
        format -> separator;
        name -> ender;
        -> starter -> setname -> name;

        check_dt_name(name);
        {%starter, ender, separator%} -> choice_vec;
        consnn_dt_record(setname, choice_vec, choice_vec,
                         DT_CHOICE_FIELD, false) -> nn_datatypes(name);
    endif;
enddefine;


/* ----------------------------------------------------------------- *
     Field Format Constructor And Conversion Functions
 * ----------------------------------------------------------------- */

define lconstant file_byte_struct(type_entry, accessor) -> seq;
lvars type_entry accessor seq;
    get_dt_record(type_entry) -> type_entry;
    accessor(type_entry) -> seq;
enddefine;

define updaterof file_byte_struct(val, type_entry, accessor);
lvars val accessor type_entry byte_struct;
    get_dt_record(type_entry) -> type_entry;
    if isinteger(val) then
        inits(val) -> byte_struct;
    elseif isvectorclass(val) then
        val -> byte_struct;
    else
        mishap(val, 1, 'Invalid byte-structure');
    endif;
    byte_struct -> accessor(type_entry);
enddefine;

global constant procedure
    nn_dt_file_in_bytestruct = file_byte_struct(%nn_dt_inconv%),
    nn_dt_file_out_bytestruct = file_byte_struct(%nn_dt_outconv%),
;

global constant procedure
    nn_dt_file_recipient = no_check_dt_accessor(%nn_dt_format%),
    nn_dt_file_datatypes = no_check_dt_accessor(%nn_dt_format%),
;

;;; nn_declare_file_format takes a format name and other arguments which
;;; depend on the type of field being created.
;;;
;;; For files where the contents are expected to be characters, the
;;; declaration is:
;;;
;;;     nn_declare_file_format("charfile", [bit], "char_file");
;;;
;;; For files which are to be itemised, the format is the name of a
;;; sequence: e.g.
;;;
;;;     nn_declare_range("minutes", 0, 59);
;;;     nn_declare_range("seconds", 0, 59);
;;;     nn_declare_field_format("time",
;;;                [\minutes minutes and \seconds seconds]);
;;;     nn_declare_field_format("time_line",
;;;                [start \time , end \time]);
;;;     nn_declare_file_format("time_file", [time_line], "item_file");
;;;
;;; will parse a file containing data such as:
;;;
;;;     start 34 minutes and 15 seconds, end 57 minutes and 12 seconds
;;;     start 23 minutes and 18 seconds, end 46 minutes and 9 seconds
;;; etc.
;;;
;;; The difference between "char" and "item" file types is that the
;;; file device for "item" is read using an itemiser rather than simply
;;; a character at a time. In both cases however, the results are left
;;; the stack for the converter routines.
;;;
;;; In the case of the next two file types "line" and "file", the method
;;; of access and conversion is slightly different. In both these cases,
;;; the declaration requires 4 arguments: the dt name, the general datatype
;;; used to convert the data, either the size of the input buffer
;;; byte-structure as an integer or the byte-structure itself,
;;; and either "line_file" or "full_file".
;;;
;;;   nn_declare_file_format("raster_8bit", "raster", 100, "line_file");
;;;
;;; When these files are read, the byte structure is left on the stack and
;;; the user-supplied data type is passed the byte-structure (this means
;;; the number of items needed for these datatypes is always 1). Note that
;;; if a structure is passed, it is copied so that there are different
;;; structures for input and output parsing.
;;;
define global nn_declare_file_format(name, format_source, format_type);
lconstant in_itemiser = discin <> incharitem,
          out_consumer = discout <> outcharitem;
lvars name format_source format_type general_type in_struct out_struct;

    unless is_file_dt(format_type) then
        mishap(format_type, 1, 'Unknown file type');
    endunless;

    if is_char_file_dt(format_type) then
        check_dt_name(name);
        ;;; files are opened using sysopen and then applying discin
        ;;; or discout to the device. The input and output converter
        ;;; for the datatype are used to to define whether these are
        ;;; then character or item repeaters/consumers. For character,
        ;;; apply identfn.
        consnn_dt_record(format_source, discin, discout,
                            DT_CHAR_FILE, false) -> nn_datatypes(name);

    elseif is_item_file_dt(format_type) then
        check_dt_name(name);
        ;;; for items, apply the appropriate itemiser
        consnn_dt_record(format_source, in_itemiser, out_consumer,
                            DT_ITEM_FILE, false) -> nn_datatypes(name);

    else    ;;; assume either a line or full file so re-order the args
        name -> general_type; -> name;

        if isinteger(format_source) then
            inits(format_source) -> in_struct;
            inits(format_source) -> out_struct;
        elseif isvectorclass(format_source) then
            format_source -> in_struct;
            copydata(format_source) -> out_struct;
        else
            mishap(format_source, 1, 'Invalid byte-structure');
        endif;

        if is_line_file_dt(format_type) then
            consnn_dt_record(general_type, in_struct, out_struct,
                        DT_LINE_FILE, false) -> nn_datatypes(name);

        elseif is_full_file_dt(format_type) then
            consnn_dt_record(general_type, in_struct, out_struct,
                        DT_FULL_FILE, false) -> nn_datatypes(name);
        else
            mishap(format_type, 1, 'Invalid file type declaration');
        endif;
    endif;
enddefine;

;;; define some convenience functions
global constant procedure (
    nn_declare_charfile = nn_declare_file_format(%DT_CHAR_FILE%),
    nn_declare_itemfile = nn_declare_file_format(%DT_ITEM_FILE%),
    nn_declare_linefile = nn_declare_file_format(%DT_LINE_FILE%),
    nn_declare_fullfile = nn_declare_file_format(%DT_FULL_FILE%),
);


/* ----------------------------------------------------------------- *
    Set Accessors/Updaters
 * ----------------------------------------------------------------- */

;;; nn_dt_setmembers returns the set list of a set
define global nn_dt_setmembers(type_entry);
lvars type_entry proc;
    if isword(type_entry) then
        nn_datatypes(type_entry) -> type_entry;
    endif;
    nn_dt_inconv(type_entry) -> proc;
    if isprocedure(proc) then frozval(2, proc) endif;
enddefine;

;;; nn_dt_setthreshold returns the set list of a set
define global nn_dt_setthreshold(type_entry);
lvars type_entry proc;
    if isword(type_entry) then
        nn_datatypes(type_entry) -> type_entry;
    endif;
    nn_dt_outconv(type_entry) -> proc;
    if isprocedure(proc) then
        frozval(3, proc)
    else
        false;
    endif;
enddefine;

;;;
;;; Now define the updaters of the accessors
;;;

define updaterof global nn_dt_setmembers(val, type_entry);
    lvars val type_entry;
    if isword(type_entry) then
        nn_datatypes(type_entry) -> type_entry;
    endif;

    cons_set_in_fn(val) -> nn_dt_inconv(type_entry);
    cons_set_out_fn(val, nn_dt_setthreshold(type_entry))
        -> nn_dt_outconv(type_entry);
    ;;; also update the number of units needed
    length(val) -> dt_out_nargs(type_entry);
enddefine;


define updaterof global nn_dt_setthreshold(val, type_entry);
    lvars val type_entry proc;
    if isword(type_entry) then
        nn_datatypes(type_entry) -> type_entry;
    endif;

    if isnumber(val) or not(val) then
        nn_dt_outconv(type_entry) -> proc;
        if isprocedure(proc) then
            val -> frozval(3, proc);
        else
            mishap(type_entry, 1, 'illegal access to set threshold');
        endif;
    else
        mishap(val, 1, 'Number or <false> expected');
    endif;
enddefine;


/* ----------------------------------------------------------------- *
    Range Accessors/Updaters
 * ----------------------------------------------------------------- */

;;; nn_dt_lowerbound returns the lower (inclusive) bound of the range
define global nn_dt_lowerbound(type_entry);
lvars type_entry proc;
    if isword(type_entry) then
        nn_datatypes(type_entry) -> type_entry;
    endif;
    nn_dt_inconv(type_entry) -> proc;
    if isprocedure(proc) then frozval(1, proc) endif;
enddefine;

define updaterof global nn_dt_lowerbound(val, type_entry);
lvars val type_entry;
    if isword(type_entry) then
        nn_datatypes(type_entry) -> type_entry;
    endif;

    val ->> frozval(1, nn_dt_inconv(type_entry));
        -> frozval(1, nn_dt_outconv(type_entry));
enddefine;

;;; nn_dt_upperbound returns the (inclusive) upperbound of the range
define global nn_dt_upperbound(type_entry);
lvars type_entry proc;
    if isword(type_entry) then
        nn_datatypes(type_entry) -> type_entry;
    endif;
    nn_dt_inconv(type_entry) -> proc;
    if isprocedure(proc) then frozval(2, proc) endif;
enddefine;

define updaterof global nn_dt_upperbound(val, type_entry);
lvars val type_entry;
    if isword(type_entry) then
        nn_datatypes(type_entry) -> type_entry;
    endif;

    val ->> frozval(2, nn_dt_inconv(type_entry));
        -> frozval(2, nn_dt_outconv(type_entry));
enddefine;


define global nn_delete_dt(name);
lvars name;
    false -> nn_datatypes(name);
    if name == nn_current_dt then
        false -> nn_current_dt;
    endif;
enddefine;


/* ----------------------------------------------------------------- *
     Built-in Datatypes
 * ----------------------------------------------------------------- */

nn_declare_general("bit", [1 1], nn_bit_real, nn_real_bit);
nn_declare_general("boolean", [1 1], nn_boole_real, nn_real_boole);
nn_declare_general("ident", [1 1], identfn, identfn);

;;; ignore is used for ignoring single items
nn_declare_general("ignore", [1 0], erase, identfn(%"ignore"%));

[bit boolean ident ignore] -> nn_builtin_dts;


/* ----------------------------------------------------------------- *
     Utilities
 * ----------------------------------------------------------------- */

define isunknown(val)->boole;
lvars val boole;
    (val == undef) or (val == false) -> boole;
enddefine;


;;; nn_items_needed takes a type or a list of types and returns the number
;;; of items required by their input converters. The appropriate entries in
;;; nn_datatypes are retrieved and the mapping patterns are summed.
;;; Note that format entries can now contain other datatypes in
;;; which case the procedure recurses until it finds the information
define global nn_items_needed(type_list) -> sum;
lvars type_list, val entry dts len type, sum = 0;
    if isunknown(type_list) then
        false -> sum;
    elseif isinteger(type_list) then
        type_list -> sum;
    elseif islist(type_list) then
        for type in type_list do
            nn_items_needed(type) -> val;
            if val then
                val + sum -> sum;
            else    ;;; no such datatype
                false -> sum;
                return();
            endif;
        endfor;
    else
        get_dt_record(type_list) -> entry;

        if isnn_dt_record(entry) then
            if is_simple_dt(entry) then
                if islist(nn_dt_format(entry)) and
                  isinteger(dt_in_nargs(entry)) then
                    dt_in_nargs(entry) -> sum;
                else    ;;; a list of datatypes
                    nn_items_needed(nn_dt_format(entry)) -> sum;
                endif;

            elseif is_seq_field_dt(entry) then
                nn_dt_format(entry) -> dts;
                if islist(dts) then
                    length(dts)
                else
                    1
                endif -> len;

                if (nn_items_needed(dts) ->> sum) then
                    ;;; need to double len to take account of the "\"
                    length(nn_dt_inconv(entry)) - (2 * len) + sum
                else
                    false
                endif -> sum;
            else
                false -> sum;
            endif;
        else
            false -> sum;
        endif;
    endif;
enddefine;


;;; nn_units_needed takes a type or a list of types and returns the number
;;; of nodes required to represent these types. The appropriate entries in
;;; nn_datatypes are retrieved and the mapping patterns are summed.
;;; Note that format entries can now contain other datatypes in
;;; which case the procedure recurses until it finds the information.
;;;
define global nn_units_needed(type_list) -> sum;
lvars type_list, val entry type, sum = 0;

    if isunknown(type_list) then
        false -> sum;
    elseif isinteger(type_list) then
        type_list -> sum;
    elseif islist(type_list) and isword(hd(type_list)) then
        ;;; a list of types
        for type in type_list do
            nn_units_needed(type) -> val;
            if val then
                val + sum -> sum;
            else    ;;; no such datatype
                false -> sum;
                return();
            endif;
        endfor;

    else
        get_dt_record(type_list) -> entry;

        if isnn_dt_record(entry) then
            if islist(nn_dt_format(entry)) and
              length(nn_dt_format(entry)) > 1 and
              isinteger(dt_out_nargs(entry)) then
                dt_out_nargs(entry) -> sum;
            else    ;;; a list of datatypes or a single datatype

                nn_units_needed(nn_dt_format(entry)) -> sum;
            endif;
        else
            false -> sum;
        endif;
    endif;
enddefine;

endsection;     /* $-popneural */

global vars nn_dtconverters = true;

/*  --- Revision History --------------------------------------------------
-- Julian Clinton, 7/9/93
    Corrected warning message for 'item not in set'.
-- Julian Clinton, 6/9/93
    Added clipping for ranges to ensure that range values passed to
        networks are 0.0 <= n <= 1.0.
-- Julian Clinton, 27/8/92
    Added -nn_declare_charfile-, -nn_declare_itemfile-,
        -nn_declare_linefile- and -nn_declare_fullfile-.
-- Julian Clinton, 30/6/92
    Added file-type accessor routines.
-- Julian Clinton, 29/6/92
    Added file-type declarations and allowed general datatypes to
        accept a single procedures (with an updater) or words or strings
        to specify the location of source code for the datatype converter.
    Added dummy -false- args to most calls of consnn_dt_record (due to
        addition of extra savedata slot).
-- Julian Clinton, 26/6/92
    Added "toggle" datatype.
-- Julian Clinton, 22/6/92
    Modified set converters to take an optional threshold value. This affects
        how items are returned from the network.
    Removed "integer", "char" and "real" datatypes - they were not very
        useful and gave the wrong impression of what they did.
    Added ignore datatype.
    Removed -vars- in procedures.
    Moved -nn_readline_file- to nn_file_utils.p
    Added -nn_dt_setthreshold- accessor and updater.
-- Julian Clinton, 19/6/92
    nn_delete_dt now assigns false to nn_current_dt if the deleted datatype
        is current.
-- Julian Clinton, 4/6/92
    PNF0035 - changed boolean values back to use 1.0 (true) and
        0.0 (false) rather than -1.0 for false.
-- Julian Clinton, 8/5/92
    Sectioned.
-- Julian Clinton, 2nd Dec 1991:
    Undid change for PNE0051 for set types
-- Julian Clinton, 15th Oct 1990:
    PNE0059 - added support for character parsing information
        when declaring datatypes
    PNE0058 - added support to allow datatype accessors to take the
        datatype name as well as a type_entry from the datatypes table
-- Julian Clinton, 25th September 1990:
    Changed datatype descriptors to be records rather than lists
-- Julian Clinton, 14th September 1990:
    PNE0051 - changed set and boolean datatypes to use -1.0 and +1.0
*/
