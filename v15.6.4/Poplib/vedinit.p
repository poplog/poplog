/* --- Copyright University of Birmingham 2004. All rights reserved. ------
 > File:            /bham/common/system/templates/user.poplog/Poplib/vedinit.p
 >					$poplocal/local/setup/Poplib/vedinit.p
 > Purpose:			Default vedinit.p for new poplog users
 > Author:          Aaron Sloman, 17 Sep 2000 (see revisions)
 */

;;; If user's init.p not compiled, then compile it
vars initfiledone;
unless initfiledone == true then
    trycompile('$poplib/init.p') ->
endunless;

global vars
	vednosunviewkeys = true;	;;; change if using Sunview keys on left

;;;Uncomment the next line if you want your vedfiletypes.p file
;;; to be used to control how VED treats different files.
;;;trycompile('$poplib/vedfiletypes.p') ->;

;;; Next command makes VED mouse work, but then requires SHIFT
;;; key for select and paste in xterm window. Make true if desired
;;; See HELP vedxgotomouse
global vars vedgotomouse = false;

;;; using $DISPLAY variable try to work out what terminal is in use
lconstant XHOST = false;
;;; Alternative for machines installed at Birmingham
;;; lconstant XHOST = xplatform();

;;; Use the recognized terminal type to selected VED's keyboard mapping
global vars vedxtermkeys_default =
valof(
    if not(XHOST) then
		;;; the default
	    "vedncdxtermkeys"
	elseif XHOST = 'exceed' and systranslate('DISPLAY') then
         uses rclib;
         "vedncdxtermkeys";
	elseif isstartstring('Sun3', XHOST) then
	    "vedsun3keys"
	elseif isstartstring('Sun', XHOST) then
	    "vedsunxtermkeys"
    elseif
	    isstartstring('DEC', XHOST)
	or
	    isstartstring('HP', XHOST)
	or
	    isstartstring('NCD', XHOST)
    then
	    "vedncdxtermkeys"
    elseif isstartstring('Apple', XHOST) then
	    "vedmacxkeys"
    else
	    ;;; default NCD = PC type keys
	    "vedncdxtermkeys"
    endif);

;;; See HELP * VED_GETMAIL for the next lot of identifiers
;;; Set these variables for LIB VED_GETMAIL
global vars
    vedmaildirectory = systranslate('MD'),	;;; set in .login
    vedmailbox = systranslate('MAIL'),		;;; See HELP * VED_GETMAIL/vedmailbox
    vedmailfile,
	vedmailmax = 100000,		;;; merge mailfiles smaller than this
;

;;; Get "root" path for mail files.
if vedmaildirectory then
	vedmaildirectory dir_>< 'mail'
elseif sysisdirectory('~/mail') then
	sysfileok('~/mail' dir_>< 'mail')
else
	sysfileok('~/Mail')
endif -> vedmailfile;

;;; Set up directories for VED to search in
if vedmaildirectory then
	['~'  ^vedmaildirectory] -> vedsearchlist;
endif;

unless sysfileok('$poplib') = sysfileok('~') then
	[^^vedsearchlist '$poplib'] -> vedsearchlist
endunless;

;;; turn on autosaving
uses ved_autosave
0 -> vedautosave_min_write;     ;;; Minimum number of changes required for save
5 -> vedautosave_minutes;       ;;; Frequency of saving
5000 -> vedautowrite;			;;; number of changes since last write

;;; See HELP VEDEXPAND for the following
`^` -> vedexpandchar;

vars
	ved_v = ved_ved,        ;;; abbreviation for ENTER ved
;

;;; define a procedure to run if poplog is run in an xterm window
define lconstant setupxterm();
	useslib("popxlib");
	useslib("vedxterm");
	compile([vedxterm();]);
	vedsetkey('\^L', "vedxrefresh");

	;;; speed up xterm compared with VT100
	false -> vednocharinsert;
	false -> vednochardelete;
	'\^[[P' -> vvedscreendeletechar;
	'\^[[h' -> vvedscreeninsertmode;
	'\^[[l' -> vvedscreenovermode;
	'\^[[@' -> vvedscreeninsertchar;
enddefine;

;;; Find out terminal type, and whether XVed is running.
lvars TERM = systranslate('TERM'),
	Inxved = vedusewindows = "x"
;

unless Inxved or not(systranslate('DISPLAY')) then
	/* If you wish always to be asked whether you want XVed, if it's
	   not already running and $DISPLAY is set, then uncomment next line.
	*/
	;;; ask_xved() ; INXVED -> Inxved
endunless;

if vedgotomouse and not(Inxved) then
	compile([vedxgotomouse();]);
else
	syscancelword("vedgotomouse");
endif;


define vedinit();
	;;; uncomment next line to load file defining key bindings
	;;; if trycompile('$poplib/vedkeys.p') then  valof("vedkeys")() endif;
	if Inxved then
		vedxtermkeys_default();
		#_IF DEF sun
			useslib("vedsunxvedkeys");
			valof("vedsunxvedkeys")();
		#_ELSE
			useslib("vedxvedkeys");
			valof("vedxvedkeys")();

			;;; turn Alt Graph key into linefeed. 	
			;;; May not always work
			vedsetkey('\^[[FF7E', vednextline);
		#_ENDIF
	elseif vedterminalselect or vedterminalname == false then
		if TERM = 'xterm' then
			setupxterm();
		endif;
	elseif TERM = 'xterm' and vedterminalname /= "xterm" then
		setupxterm();
	elseif TERM = 'xved' then
		;;; Not sure this case can occur
		;;; vedxtermkeys_default();
		useslib("vedxvedkeys");
		valof("vedxvedkeys")();
	endif;

	;;; Make backspace delete to left
	vedsetkey('\^H', "vedchardelete");

	;;; garbage collect this procedure after use.
	identfn -> vedinit;

	if systranslate('DISPLAY') then
		if Inxved then
			if poparglist == [] then
				;;; No file name given. Choose default
	    		vedinput(veddo(%'ved '<> vedvedname%));
			endif;
		endif;
		;;; If you don't have motif available you can't run ved_menu
		if DEF popxlink_motif
		then
			;;; Start VED with menus running (requires motif)
			;;; Comment out if you don't always want this (use "ENTER menu" instead)
			;;; Uncomment if you have rcmenu package installed and want menus
			;;; always
			;;; 	vedinput(valof("ved_menu"));
		endif;


	endif;
/*
;;; for XVed in PC linux Poplog
	vedsetkey('\^[[FF52',"vedcharup");
	vedsetkey('\^[[FF54',"vedchardown");
	vedsetkey('\^[[FF51',"vedcharleft");
	vedsetkey('\^[[FF53',"vedcharright");

	vedsetkey('\^[[FF8D', "vedenterkey");
	vedsetkey('\^[[FFAB', "vedstatusswitch");
	vedsetkey('\^[[FFAD', "vedredokey");


    vedsetkey('\^[[FF9E',"vedwordleft");
    vedsetkey('\^[[FF9F',"vedwordright");

    vedsetkey('\^[[FF97',"vedcharup");
    vedsetkey('\^[[FF99',"vedchardown");
    vedsetkey('\^[[FF96',"vedcharleft");
    vedsetkey('\^[[FF98',"vedcharright");
*/
enddefine;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Dec 30 2004
		Modified to make XVED work on linux.
		Previously prevented from working properly because of
		configuration for Suns
--- Aaron Sloman, Sep 17 2000
	New version for linux poplog
--- Aaron Sloman, Sep 25 1999
	Altered to allow exceed option
--- Aaron Sloman, Sep  3 1999
	Tidiedup a bit
--- Aaron Sloman, Apr 26 1999
	Put test for motif before ved_menu
--- Aaron Sloman, Sep 21 1998
	Changed to make backspace do delete, by default
 */
