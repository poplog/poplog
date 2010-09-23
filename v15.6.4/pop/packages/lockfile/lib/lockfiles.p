/* --- Copyright University of Sussex 1989. All rights reserved. ----------
 > File:            $poplocal/local/lib/lockfiles.p
 > Purpose:         Package for locking files
 > Author:          John Williams, Nov  9 1989
 >                      (based on an idea by Mark Rubinstein)
 > Documentation:
 > Related Files:
 */


section;

;;; edit this if necessary
lvars LOCKDIRS =
        [ '$poplocal/local/lockfile/locks'];


/* Determine where locks are kept */

define lconstant Choose_lockdir();
    lvars dir;
    for dir in LOCKDIRS do
        sysfileok(dir) -> dir;
        returnif(sysisdirectory(dir)) (dir)
    endfor;
    mishap(LOCKDIRS, 1, 'Cannot allocate lock directory')
enddefine;

lconstant LOCKDIR = Choose_lockdir();


/* Generating name of lockfile */

define global lockof(file);
    lvars c d file;
    sysfileok(file) -> file;
    if fast_subscrs(1, file) /== `/` then
        current_directory dir_>< file -> file
    endif;
    `+` -> d;
    if strmember(d, file) then
        for d from 33 to 126 do
            unless strmember(d, file) do
                goto GOT_D
            endunless
        endfor;
        mishap(file, 1, 'CAN\'T GENERATE LOCK')
    endif;
GOT_D:
    cons_with consstring
    {% for c in file using_subscriptor fast_subscrs do
        if c == `/` then d else c endif
    endfor %} -> file;
    LOCKDIR dir_>< file
enddefine;


define global filename_of_lock(lock);
    lvars c d file lock;
    if isstartstring(LOCKDIR, lock) then
        allbutfirst(datalength(LOCKDIR) + 1, lock) -> lock
    endif;
    lock(1) -> d;
    cons_with consstring
    {% for c in lock using_subscriptor fast_subscrs do
        if c == d then `/` else c endif
    endfor %}
enddefine;


/* Interrogating locks */

define lconstant Read_lock(lock);
    lvars dev lock rep item;
    if (readable(lock) ->> dev) then
        incharitem(discin(dev)) -> rep;
        rep(), rep();
        sysclose(dev)
    else
        false, false
    endif
enddefine;


define lconstant Lock_key(lock) -> key;
    lvars key lock;
    Read_lock(lock) -> -> key
enddefine;


define Lock_comment(lock) -> comment;
    lvars comment lock;
    Read_lock(lock) -> comment ->
enddefine;


define global lockkey_of() with_nargs 1;
    Lock_key(lockof())
enddefine;


define global lockcomment_of() with_nargs 1;
    Lock_comment(lockof())
enddefine;


/* Locking and unlocking files */

define Checkr_lock_file(item) -> item;
    lvars item;
    unless sys_file_stat(item, nullvector) do
        mishap(item, 1, 'FILE NOT FOUND')
    endunless
enddefine;

define lconstant Checkr_lock_key(item) -> item;
    lvars item;
    if isstring(item) then
        strnumber(item) or consword(item) -> item
    elseunless isword(item) or isinteger(item) do
        mishap(item, 1, 'LOCK KEY MUST BE WORD OR INTEGER')
    endif
enddefine;


define lconstant Checkr_lock_comment(item) -> item;
    lvars item;
    unless isstring(item) do
        item >< nullstring -> item
    endunless
enddefine;


define lconstant Write_lock(lock, key, comment);
    lvars comment lock key;
    dlocal cucharout pop_file_mode pop_pr_quotes pr;
    8:666 -> pop_file_mode;
    true -> pop_pr_quotes;
    syspr -> pr;
    discout(lock) -> cucharout;
    spr(key);
    npr(comment);
    cucharout(termin);
enddefine;


define global trylockfile(file, key);
    lvars comment file key lock Comment Key;

    /* optional third argument is comment for lock file */
    if isstring(key) then
        key -> comment;
        file -> key;
        -> file
    else
        nullstring -> comment
    endif;

    Checkr_lock_file(file) -> file;
    Checkr_lock_key(key) -> key;
    Checkr_lock_comment(comment) -> comment;
    lockof(file) -> lock;
    if (Read_lock(lock) -> Comment ->> Key) then
        if key == Key then
            Comment
        else
            false
        endif
    else
        Write_lock(lock, key, comment);
        true
    endif
enddefine;


define global tryunlockfile(file, key);
    lvars file key lock oldkey;
    Checkr_lock_key(key) -> key;
    lockof(file) -> lock;
    if (Lock_key(lock) ->> oldkey) then
        key == oldkey and sysdelete(lock)
    else
        undef
    endif
enddefine;


/* Misc */

define global islocked(file);
    lvars file;
    readable(lockof(file))
enddefine;


define lconstant All_locks();
    pdtolist(valof("sys_file_match")(LOCKDIR dir_>< '*', false, false, false))
enddefine;


define global files_locked_by(key);
    lvars key lock;
    Checkr_lock_key(key) -> key;
    [% for lock in All_locks() do
        if Lock_key(lock) == key then
            filename_of_lock(lock)
        endif
    endfor %]
enddefine;


endsection;
