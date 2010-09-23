HELP EMACS                                  Robert Duncan, November 1992
                                            Updated Brian Logan, March 1997,
                                                             September 1999
Poplog for Emacs users.


    CONTENTS - (Use <ENTER> g to access required sections)

 -- Introduction
 -- Driving Poplog from Emacs
 -- Pop mode
 -- Procedure definitions
 -- Lists and Sexps
 -- Completing sexps and Pop-11 words
 -- Indentation
 -- Syntax highlighting
 -- Inferior Pop Mode
 -- Compiling and loading Pop-11 code
 -- Pop Help Mode
 -- Editing help files
 -- Installation
 -- Making VED look like Emacs
 -- Related Documentation


-- Introduction -------------------------------------------------------

This file is meant as an aid to Emacs users coming to Poplog for the first
time and finding themselves confused or irritated by the built-in editor
VED. The relationship between Poplog and VED is close, and there is no doubt
that VED is the most effective medium for interacting with Poplog. Yet
although VED is similar in functionality to Emacs, its style and feel are
sufficiently different that some Emacs users find it difficult to get on
with.

Emacs users who want to use Poplog thus have a choice: either to stay with
Emacs and use that as the front-end to Poplog (possibly suffering some loss
of functionality), or else to get to grips with VED. For those in the first
group, the Poplog CONTRIB directory tree contains an Emacs Lisp package
which customises Emacs for Poplog; for the second group, there is a VED
library which installs Emacs-like key bindings to make things seem more
familiar.


-- Driving Poplog from Emacs ------------------------------------------

The directory $popcontrib/emacs contains pop-mode for XEmacs/FSF Emacs,
which allows Pop-11 development to be done in Emacs with (almost) as much
support as in in VED. Pop-mode provides support for editing Pop-11 code,
compiling code from an Emacs buffer and reading the Poplog documentation.

The package actually comprises three major modes: Pop mode for editing
Pop-11 code, Inferior Pop mode for running the Pop-11 compiler from within
Emacs, and Pop Help mode for reading the Poplog documentation.  This file is
based on the Emacs documentation for Lisp mode and C mode on which Pop mode
is modelled.  (See also the Emacs info node on Editing Programs.)


-- Pop mode ------------------------------------------------------------

Pop mode is similar to the other Emacs language editing modes (e.g. Lisp
mode, C mode etc.) in providing commands which understand the syntax of
Pop-11.  There are commands to:

   * Move over or kill balanced expressions ("sexps").

   * Move over or mark top-level balanced expressions ("procedures").

   * Follow the usual indentation conventions of the language.

   * Completion on words in Pop-11 code.

   * Highlighting the syntax of Pop-11 code.


-- Procedure definitions ------------------------------------------------

Each Pop-11 program is made up of separate procedures.  There are editing
commands to operate on them.

In Emacs, any top level top-level parenthetical traditionally counts a
`defun' regardless of its contents or the programming language.  For
example, in C, the body of a function definition is a defun.  However, in
Pop-mode, the more mnemonic term `define' is used.

`C-M-a'
     Move to beginning of current or preceding define
     (`pop-beginning-of-define').

`C-M-e'
     Move to end of current or following define (`pop-end-of-define').

`C-M-h'
     Put region around whole current or following define (`pop-mark-define').

   The commands to move to the beginning and end of the current defun
are `C-M-a' (`pop-beginning-of-define') and `C-M-e' (`pop-end-of-define').

To operate on the current defun, use `C-M-h' (`pop-mark-define') which puts
point at the beginning and the mark at the end of the current or next
procedure definition.  This is the easiest way to prepare for moving the
definition to a different place.


-- Lists and Sexps -----------------------------------------------------

The commands for editing lits and sexps fall into two classes.  Some
commands deal only with "lists" (parenthetical groupings).  They see nothing
except parentheses, brackets, braces, and escape characters that might be
used to quote those.

The other commands deal with expressions or "sexps".  In Emacs, the notion
of `sexp' is not limited to Lisp.  In Pop-mode, sexps include symbols,
numbers, and string constants.  It also includes syntactic keyword pairs,
including: define/enddefine, procedure/endprocedure, defmethod/enddefmethod,
if/endif, unless/endunless, while/endwhile, until/enduntil, fast_for/endfor,
for/endfor, repeat/endrepeat, and switchon/endswitchon.

As with other languages that use prefix and infix operators, it is not
possible for all expressions to be sexps.  For example, Pop-mode does not
recognise `foo + bar' as an sexp, even though it is a Pop-11 expression; it
recognises `foo' as one sexp and `bar' as another, with the `+' as
punctuation between them.  This is a fundamental ambiguity: both `foo + bar'
and `foo' are legitimate choices for the sexp to move over if point is at
the `f'.  Note that `(foo + bar)' is a sexp in C mode.

By convention, Emacs keys for dealing with balanced expressions are usually
`Control-Meta-' characters.  They tend to be analogous in function to their
`Control-' and `Meta-' equivalents.

`M-f'
     Move forward over a Pop-11 word (`pop-forward-word').

`M-b'
     Move backward over a Pop-11 word (`pop-backward-word').

`C-M-f'
     Move forward over an sexp (`pop-forward-sexp').

`C-M-b'
     Move backward over an sexp (`pop-backward-sexp').

`C-M-u'
     Move up and backward in list structure (`backward-up-list').

`C-M-d'
     Move down and forward in list structure (`down-list').

`C-M-n'
     Move forward over a list (`forward-list').

`C-M-p'
     Move backward over a list (`backward-list').

`C-M-@'
     Put mark after following expression (`pop-mark-structure').

To move forward over an sexp, use `C-M-f' (`pop-forward-sexp').  If the
first significant character after point is an opening delimiter `(', `[', or
`{' in Pop-11, `C-M-f' moves past the matching closing delimiter.  If the
character begins a symbol, string, or number, `C-M-f' moves over that.  If
the character after point is a closing delimiter, `C-M-f' just moves past
it.  (This last is not really moving across an sexp; it is an exception
which is included in the definition of `C-M-f' because it is as useful a
behaviour as anyone can think of for that situation.)  The sexp commands
move across comments as if they were whitespace.

The command `C-M-b' (`pop-backward-sexp') moves backward over a sexp.  The
detailed rules are like those above for `C-M-f', but with directions
reversed.

`C-M-f' or `C-M-b' with an argument repeats that operation the specified
number of times; with a negative argument, it moves in the opposite
direction.

The "list commands", `C-M-n' (`forward-list') and `C-M-p' (`backward-list'),
move over lists like the sexp commands but skip over any number of other
kinds of sexps (symbols, strings, etc).

`C-M-n' and `C-M-p' stay at the same level in parentheses, when that is
possible.  To move up one (or N) levels, use `C-M-u' (`backward-up-list').
`C-M-u' moves backward up past one unmatched opening delimiter.  A positive
argument serves as a repeat count; a negative argument reverses direction of
motion and also requests repetition, so it moves forward and up one or more
levels.  To move down in list structure, use `C-M-d' (`down-list').  An
argument specifies the number of levels of parentheses to go down.

To make the region be the next sexp in the buffer, use `C-M-@'
(`pop-mark-structure') which sets the mark at the same place that `C-M-f'
would move to.  `C-M-@' takes arguments like `C-M-f'.  In particular, a
negative argument is useful for putting the mark at the beginning of the
previous sexp.


-- Completing sexps and Pop-11 words -----------------------------------

'M-;'
    Close the current sexp ('pop-closeit').

'M-TAB'
    Complete Pop-11 word at or before point ('pop-complete-word').

To insert a correctly indented closing keyword, type 'M-;' (or 'M-]'). With
a prefix argument, this command closes the last N sexps.  For example, if
your code looks like:

    define macro lvars foo (x)
	lvars x;

	repeat x times
	    'hello'=> [=]

where [=] is the cursor, you can type M-; and emacs will insert the
`endrepeat', correctly indented

    define macro lvars foo (x)
        lvars x;

	repeat x times
	    'hello'=> 
	endrepeat;[=]

typing M-; again closes the define

    define macro lvars foo (x)
        lvars x;

	repeat x times
	    'hello'=> 
    enddefine;    ;;;  macro foo[=]

If the sexp being closed is a `define' and the variable
'pop-closeit-define-comments' is non nil, this command adds a comment naming
the sexp together with any keywords listed in the variable
'pop-interesting-declaration-modifiers' which appear in the declaration.

The command `M-TAB' (`pop-complete-word') takes the partial Pop-11 word
before point to be an abbreviation, and compares it against all Pop-11 words
currently known to Emacs.  Any additional characters that they all have in
common are inserted at point.  Since this command queries the inferior pop
process, it will only work if there is an inferior Pop process (see below)
and Pop-11 is at the top-level in the interaction buffer.

If the partial name in the buffer has more than one possible completion and
they have no additional characters in common, a list of all possible
completions is displayed in another window.


-- Indentation ---------------------------------------------------------

`TAB'
     Adjust indentation of current line.

`LFD'
     Equivalent to RET followed by TAB (`pop-newline-indent').

';'
     Insert a `;' and indent the current line ('pop-semicolon-indent').

The basic indentation command is TAB, which gives the current line the
correct indentation as determined from the previous lines.  TAB inserts or
deletes whitespace at the beginning of the current line, independent of
where point is in the line.  If point is inside the whitespace at the
beginning of the line, TAB leaves it at the end of that whitespace;
otherwise, TAB leaves point fixed with respect to the characters around it.

   Use `C-q TAB' to insert a tab at point.

When entering a large amount of new code, use LFD (`pop-newline-indent'),
which is equivalent to a RET followed by a TAB, or `;'
('pop-semicolon-indent') which inserts a `;' followed by a TAB.

TAB indents the second and following lines of the body of a parenthetical
grouping each under the preceding one; therefore, if you alter one line's
indentation to be nonstandard, the lines below tend to follow it.  This is
the right behaviour in cases where the standard result of TAB does not look
good.

Several commands are available to re-indent several lines of code which have
been altered or moved to a different level in an expression.

`C-M-p'
     Re-indent all lines in the current procedure (`pop-indent-define').

`C-M-q'
     Re-indent all the lines within one sexp (`pop-indent-structure').

`C-M-r'
     Re-indent all lines in the region (`pop-indent-region').

To re-indent all the lines in the current procedure definition, type
'C-M-p'.  To re-indent the contents of a single sexp, position point before
the beginning of it and type `C-M-q'.

Another way to specify a range to be re-indented is with point and mark.
The command `C-M-r' (`pop-indent-region') applies TAB to every line whose
first character is between point and mark.

Pop-mode uses a set of default rules to decide how Pop-11 code should be
indented.  To customise the indentation of Pop-11 code, you can change the
value of the variable `pop-indentation-info':

'pop-indentation-info'
    An association list which determines how Pop-11 structures are indented.
    Each entry starts with a string giving the name of a syntax word. This
    is followed by two numbers, the first gives the change in indentation of
    the current line while the second gives the change in indentation of
    succeeding lines.  For example, the default entry for `if then else'
    looks like

        ("if" 0 8)
        ("then" 0 -4)
        ("else" -4 4)

    i.e. don't change the indentation of the line containing the `if', and
    indent the following line by 8 relative to the proceeding line.  Note
    how the entry for `else' uses a negative argument to move the else back
    to the previous indentation level.


-- Syntax highlighting -------------------------------------------------

Syntax highlighting is a way of making code easier to read, by displaying
comments, strings, keywords etc. in different styles.  In Emacs, this is
achieved using the minor mode Font Lock mode, which controls how text
patterns are highlighted.  (If you are using FSF Emacs you have to be
running under X for this to work; with XEmacs, Font Lock mode works with
ttys as well.)

To make the text you type be fontified, use M-x font-lock-mode.  When this
minor mode is on, the fonts of the current line will be updated with every
insertion or deletion.  Once it has been turned on, font-lock will
automatically put newly loaded files into font-lock-mode.

As with other programming modes, the text patterns for keywords are defined
by the variable `font-lock-keywords' (comments and strings are handled
automatically using the syntax tables for the appropriate major mode).  By
default, Pop mode defines the value of `font-lock-keywords' to the value of
the variable 'pop-font-lock-keywords'.  The easiest way to change the
highlighting patterns is to change the value of 'pop-font-lock-keywords'.
See the doc string of the variable `font-lock-keywords' for the appropriate
syntax.

The default value for `pop-font-lock-keywords' is the value of the variable
`pop-font-lock-keywords-1'.  You may like `pop-font-lock-keywords-2' better;
it highlights many more words, but is slower and makes your buffers be very
visually noisy.

You can make font-lock default to the gaudier variety of keyword
highlighting by setting the variable `font-lock-use-maximal-decoration'
before loading font-lock, or by calling the functions
`font-lock-use-default-maximal-decoration' or
`font-lock-use-default-minimal-decoration'.


-- Inferior Pop Mode ---------------------------------------------------

You can run a Pop-11 process as an inferior of Emacs, and pass expressions
to it to be evaluated.  You can also pass changed function definitions
directly from the Emacs buffers in which you edit the Pop-11 programs to the
inferior Pop-11 process (see below).

To run an inferior Pop-11 process, type `M-x run-pop'.  This runs the
program named by the variable 'pop-program-name' (this is usually "pop11",
i.e. the same program you would run by typing `pop11' as a shell command),
with both input and output going through an Emacs buffer named `*Pop-11*'. 
In other words, any "terminal output" from Pop-11 will go into the buffer,
advancing point, and any "terminal input" for Pop-11 comes from text in the
buffer.  Running an inferior Pop-11 process creates a new Emacs window for
the '*Pop-11*' buffer if one doesn't exist.  To run an inferior Pop-11
process in another X window (frame), type 'M-x run-pop-other-frame'.

The `*Pop-11*' buffer is in Inferior Pop mode, which has all the special
characteristics of Pop mode and Comint mode (See also the Emacs
documentation for Shell Mode.)  Comint mode defines several special keys
attached to the `C-c' prefix.  They are chosen to resemble the usual editing
and job control characters present in shells that are not under Emacs,
except that you must type `C-c' first.  Here is a list of the special key
bindings of Comint mode:

`RET'
     At end of buffer send line as input; otherwise, copy current line to
     end of buffer and send it (`comint-send-input').  When a line is
     copied, any text at the beginning of the line that matches the variable
     `pop-prompt-regexp' is left out; this variable's value should be a
     regexp string that matches the prompts that you use in your Pop-11
     process (usually ": ").

`C-c C-d'
     Send end-of-file as input, probably causing Poplog to finish
     (`comint-send-eof').

`C-c C-u'
     Kill all text from last stuff output by the inferior Pop-11 process
     to point (`comint-kill-input').

`C-c C-z'
     Stop Poplog (`comint-stop-subjob').

`C-c C-\'
     Send quit signal to Poplog (`comint-quit-subjob').

The '*Pop-11*' buffer maintains a history of previously typed Pop-11
commands.  You can cycle backwards and forwards through this history to save
re-typing a command you entered previously.

`C-M-p'
     Move backward through the input history.  Search for a matching
     command if you have typed the beginning of a command
     (`comint-previous-input').

`C-M-n'
     Move forward through the input history.  Useful when you are using
     M-p quickly and go past the desired command (`comint-next-input').

'M-p'
    Search backwards through input history for commands which match the
    current input.  With prefix argument N, search for Nth previous
    match. If N is negative, search forwards for the -Nth following match
    (`comint-previous-matching-input-from-input').

'M-n'
    Search forwards through input history for match for current input. With
    prefix argument N, search for Nth following match. If N is negative,
    search backwards for the -Nth previous match.

'M-r'
    Search backwards through input history for match for REGEXP.


-- Compiling and loading Pop-11 code -----------------------------------

In addition, running an inferior pop process makes the following commands
available in Pop mode buffers.

'C-M-x'
   Compile the current procedure definition ('pop-send-define').

'C-x-C-e'
   Compile the current line ('pop-send-line').

'C-c-C-r'
   Compile the current region ('pop-send-region').

'C-c-C-b'
   Compile the current buffer ('pop-send-buffer').

'C-C-l'
    Load a file ('pop-load-file').

When you edit a function in a Pop-11 program you are running, the easiest
way to send the changed definition to the inferior Pop-11 process is the key
`C-M-x' (or 'C-c-C-c').  In Pop mode, this key runs the function
`pop-send-define', which finds the procedure definition around or following
point and sends it as input to the Pop-11 process.  (Emacs can send input to
any inferior process regardless of what buffer is current.)  Any output
generated by the compilation is appended to the end of the '*Pop-11*'
buffer.

The commands `pop-send-region' and 'pop-send-buffer' compile the current
region and the current buffer respectively, with output going to the
'*Pop-11*' buffer.  The command 'pop-send-line' compiles the current line
only; this is useful if you want to e.g. reinitialise a global variable.

If the variable 'pop-compilation-messages' is no nil, then a message
describing what is being compiled is printed in the '*Pop-11*' buffer in
addition to any output from the compilation itself.


-- Pop Help Mode -------------------------------------------------------

To get help on a particular subject, read the Poplog (Pop-11) documentation
or examine one of the Pop-11 libraries, the following commands are
available.  Note that although there a number of different types of
documentation (HELP, TEACH, DOC, REF and LIB), for simplicity we shall refer
only to `help' files, since all the commands listed below can be used with
any documentation file (with the possible exception of library files, which
often do not have the appropriate structure for the section commands).

'M-x pop-apropos'
    Get summary help for everything matching SUBJECT.

'M-x pop-help'
    Get Poplog help file for SUBJECT.

'M-x pop-teach'
    Get Poplog teach file for SUBJECT.

'M-x pop-ref'
    Get Poplog ref file for SUBJECT.

'M-x pop-doc'
    Get Poplog doc file for SUBJECT.

'M-x pop-showlib'
    Get Poplog library for SUBJECT.

These commands are always available (assuming that Pop mode has been set up
correctly at your site), even if you an not visiting a Pop-11 source file or
running an inferior Poplog process.  If there is an inferior Poplog process
running, Pop Help mode will query Pop-11 for the current searchlists.  This
means that you can find the documentation for packages with their own HELP
and TEACH files etc. after the package has been loaded.  If Poplog is not at
the top level and therefore unable to respond to the request, the default
searchlists are used.  If the variable
'pop-help-always-use-default-searchlists' is non nil, the default
searchlists are always used, even if there is a running Poplog process.
This can be useful in situations where you want to define your own
searchlists, for example so that the documentation for packages is always
available, even if the package is not loaded.

If the variable 'pop-short-help-commands' is non nil, the command names are
abbrevated by omitting the pop- prefix, i.e., the command 'M-x pop-apropos'
becomes 'M-x apropos'.  Note that this effectively redefines some standard
Emacs commands, e.g. 'help'.

Each command prompts for a SUBJECT, offering as a default the word under
point.  The SUBJECT should be a string which names a help file, except in
the case of 'pop-apropos' where it can be a substring which will be matched
against the names of all the HELP files.

Running any of the above commands visits the relevant file in a Pop Help
buffer.  By default one buffer is created for each type of help file HELP,
TEACH etc.  This is convenient, since each HELP etc. file always appears in
the same buffer.  However, there are occasions where it is useful to be able
to refer to more than one file at a time.  Making the variable
'pop-help-always-create-buffer' non nil creates a new buffer for each file
and it is up to the user to manage the resulting buffers.  In the case of
'pop-apropos', a special buffer is created containing the names of all the
files that matched the subject string, together with a one line description
of the file.

Pop Help buffers are in Pop Help mode, a major mode for reading Poplog help
documentation.  The following commands are available in Pop Help mode:

'C-h p'
     Get help for the word under or following point ('pop-get-help').

'C-h n'
     Go to the next cross reference in the current help file
     ('pop-next-help').

'C-h g'
     Jump to the next section within the current help file
     ('pop-goto-section').

'M-x pop-help-toggle-pop-mode'
     Put the current help buffer in Pop mode.

To get help on a particular word, type 'C-h p' (or '?', both bound to the
command 'pop-get-help') which attempts to find an appropriate help file.
For example, if you are reading a help file which contains the term
"strings" and you want to see the help file for STRINGS, place the cursor on
or before the word and type 'C-h p'.  Note that while 'C-h p' is bound in
Pop mode and Inferior pop mode as well Pop help mode, '?' is only bound in
Pop help mode.

Poplog documentation files contain many cross references.  To move to the
next cross reference in a file, type 'C-h n' (or '/'); this places point
immediately before the cross reference.  Typing 'C-h b' again skips to the
next cross reference and so on.  To follow a particular reference, type 'C-h
p'.

To skip to the next section in a help file, type 'C-h g'
('pop-goto-section').  If point is currently on one of the section headings
at the top of the help file, 'pop-goto-section' jumps to the section for
that heading.  If point is anywhere else, this command jumps to the next
section heading in the table of contents.  Typing 'C-h g' again will then
jump to that section.  This makes it is easy to move around the file, by
jumping back to the contents list, selecting another section heading and
then typing 'C-h g' again to jump to that section.

The normal Pop mode commands to move over program code, compile definitions
etc. are not available in Pop Help mode.  It is sometimes useful to look at
a Poplog library file in Pop mode with its movement and compilation commands
rather than in Pop Help mode.  The function 'pop-help-toggle-pop-mode'
toggles between Pop mode and Pop Help mode, trying to preserve the buffer
local vars that lets Pop Help mode keep track of the buffer.


-- Editing help files --------------------------------------------------

There are also two commands for creating and editing Poplog help files.

'M-x ved-heading'
     Change current line into a VED style heading for a help file.

'M-x ved-indexify'
     Make a VED style index for the current help file.  

These command mimic the behaviour of the ved commands 'heading' and
'indexify' respectively.  See HELP * VED_INDEXIFY for more details on these
commands.  The command 'ved-heading' converts the current line into a VED
style heading, by inserting dashes before and after the heading.  The
command 'ved-indexify' searches a buffer for headings created by
'ved-heading' to create an index for the file.  The index is inserted at
point and any old indexes are not deleted.


-- Installation --------------------------------------------------------

Pop-mode is user-contributed software (see HELP * CONTRIB).  Instructions
for use can be found in:

    $popcontrib/emacs/README


-- Making VED look like Emacs -----------------------------------------

The library *VEDEMACS changes VED's key map to make some common key bindings
the same as the Emacs defaults. There is no sense in which this can be
described as an emulator for Emacs: the idea is to allow users familiar with
Emacs key bindings to perform simple editing operations without having to
work too hard. The library is useful for those who have to use VED
occasionally or temporarily; longer-term use really requires getting to know
VED in its own right.

The simplest way to use of the library is via a saved image. Run this
command from the shell to make the image:

    % pop11 %nort mkimage vedemacs vedemacs

and this command to invoke it:

    % pop11 +vedemacs ved

Once inside VED, typing:

    <ESC> x help vedemacs <RETURN>

will display the documentation for the library.


-- Related Documentation ---------------------------------------------

See also:

    HELP *VED      - The poplog builtin editor.
    HELP *VEDEMACS - How to make VED look like emacs.
    HELP *JUSTIFY  - indentation in VED, pop-mode tries to be similar.

For more information about Emacs see the Emacs online tutorial, which can be
invoked by typing 'C-h t'. This is a very good introduction to using Emacs.


--- C.all/help/emacs
--- Copyright University of Sussex 1992. All rights reserved. ----------
