/* --- Copyright University of Sussex 1997. All rights reserved. ----------
 > File:            $poplocal/local/auto/newmaster_transport.p
 > Purpose:         Poplog interface to 'transport' script
 > Author:          John Williams, Feb  7 1989 (see revisions)
 > Documentation:   HELP * TRANSPORT
 > Related Files:   $poplocal/transport/transport
                    $poplocal/local/lib/newmaster/install.p
 */

section;

uses lockfiles;

lconstant CRN_HOSTS     =   'rsunx.crn';
lconstant LOG           =   '$poplocal/transport/LOG';
lconstant TRANSPORT     =   '$poplocal/transport/transport';
lconstant ADMIN_DIR     =   '/local/admin/';


define lconstant Logobey(command);
    dlvars command, dev;
    dlocal interrupt;

    if (sysopen(LOG, 2, false) ->> dev) then
        sysseek(dev, 0, 2)
    else
        syscreate(LOG, 2, false) -> dev
    endif;

    unless trylockfile(LOG, "transport") == true do
        vederror('Transport currently in use  - please try again later')
    endunless;

    procedure(interrupt);
        dlocal interrupt;
        tryunlockfile(LOG, "transport") -> ;
        interrupt();
    endprocedure(% interrupt %) -> interrupt;

    procedure();
        dlocal popdeverr = dev, popdevout = dev;
        sysobey(command, `%`);
        pop_status == 0
    endprocedure();

    unless tryunlockfile(LOG, "transport") do
        vederror('Error unlocking ' <> LOG)
    endunless;
enddefine;


define global newmaster_transport(file, option_transport);
    lvars file, hosts, option_transport, poplocal, admin, tmpfile;
    dlocal 0 % (false -> tmpfile),
               (if tmpfile then sysdelete(tmpfile) -> endif) %;

    sysfileok(file) -> file;
    systranslate('$poplocal') -> poplocal;
    if isstartstring(poplocal, file) then
        allbutfirst(datalength(poplocal), file) -> file
    else
        vederror('File spec must begin with \'$poplocal\'')
    endif;

    if (isstartstring(ADMIN_DIR, sys_fname_path(file)) ->> admin) then
        CRN_HOSTS
    elseif option_transport then
        ''
    else
        CRN_HOSTS
    endif -> hosts;

    vedputmessage('Writing temporary file');
    systmpfile(false, "transport", popusername) -> tmpfile;
    procedure(vedargument);
        dlocal vedargument, pop_file_mode, vedchanged = 1;
    #_IF pop_internal_version >= 150200
        dlocal
            vedbuffer = mapdata(vedbuffer, copy),   ;;; removes text data!
            vvedmarkprops = false,
            ;
        vedmarkpush();
        ved_mbe();
        veddo('chat r -A');
        vedmarkpop();
    #_ENDIF
        if admin then 8:660 -> pop_file_mode endif;
        ved_w()
    endprocedure(tmpfile);

    /* File permissions.
       Preserve the permissions of the original if possible,
       Otherwise use those of vedpathname, if it exists.
       Then ensure file is readable by all and writeable by owner and group.
    */
    unless admin then
        vedputmessage('Setting file permissions');
        if sys_file_exists(poplocal dir_>< file) then
            sysfilemode(poplocal dir_>< file) -> sysfilemode(tmpfile)
        elseif sys_file_exists(vedpathname) then
            sysfilemode(vedpathname) -> sysfilemode(tmpfile)
        endif;
        sysobey('chmod a+r,ug+w ' <> tmpfile);
    endunless;

    vedputmessage('Installing/transporting file');
    if Logobey(TRANSPORT <> ' ' <> tmpfile <> ' ' <> file <> ' ' <> hosts)
    then
        vedputmessage('Done')
    else
        vederror('Error installing/transporting file')
    endif
enddefine;


endsection;


/* --- Revision History ---------------------------------------------------
--- Maria-Magdalena Portmann & John Williams, Feb 28 1997
        Changed rsuna.crn to rsunx.crn
--- John Williams, May 28 1996
        Removes embedded text actions and active attribute (because
        older Poplog systems can't read them into Ved).
--- John Williams, Apr 19 1996
        Added support for $poplocal/local/admin
            (files that should be readable by "cogfac" only).
--- John Williams, Nov  8 1995
        Improved file permission handling - now (a) preserves executability,
        (b) ensures file is readable by all and writeable by owner & group.
--- John Williams, Jul  9 1992
        Changed 'rsuna' to 'rsuna.crn'
--- John Williams, May 29 1992
        Removed 'tboba' from CRN_HOSTS
--- Robert John Duncan, Mar 17 1992
        Moved to top section and made global to keep it independent of the
        rest of NEWMASTER
--- Robert John Duncan, Feb  7 1992
        Changed to unlock the log file when interrupted
--- John Williams, Nov 26 1991
        Added 'rsuna' & removed 'csuna/b' from list of CRN hosts
--- John Williams, Nov 27 1990
        Uses 'chmod' rather than -popfilemode-
--- John Williams, Sep 12 1990
        Now uses LIB LOCKFILES instead of LIB LOCKF, which is buggy.
--- John Williams, Sep  6 1990
        Added 'tboba' to CRN_HOSTS
--- John Williams, Jun  1 1990
        Now sets -pop_file_mode- to 8:664 before writing temp file
--- John Williams, Mar  2 1989
        Added exit action to delete temp file
 */
