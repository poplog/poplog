;;; $poplocal/local/setup/Poplib/vedfiletypes.p
;;; -- See  HELP * VEDFILETYPES
;;; Aaron Sloman
;;; 17 Sep 2000

;;; Compiled by vedinit.p

;;; Suffixes identifying ML files
;;; edit if needed
global vars pmlfiletypes = ['.ml' '.ML' '.sml' '.sig'];

;;; Suffixes identifying files that don't automatically wrap

global vars vednonbreakfiles =
	[ '.ph'  '.s' '.ps' '.c' '.bib'
		'.xstart' '.xsession' '.xclients' '.xinitrc'
		'.xmain' '.Xdefaults'
		'.bashrc' '.login' '.cshrc'
		'.uwmrc' '.twmrc' '.tvtwmrc' '.ctwmrc'
		lispfiletypes
	    '.openwin-init' '.openwin-menu' '.openwin-ncd-init'
		pmlfiletypes
	] <> vednonbreakfiles;


;;; lispfiletypes set by the system

;;; Now, how to treat each set of file types.
;;; Ensure VED variables are set up right for different types of files
;;; by assigning the following control list to -vedfiletypes-
;;; a list of lists each of form [<condition> <action1> <action2> ...]



[
	;;; First the default case --  empty string matches any file name
	[''
		{vedindentstep 4} {vednotabs ^true} {vedbreak ^true}
			;;; {popcompiler compile}
		{vedlinemax 72}]

	;;; setup right margin for help, ref, doc files etc.
	[ [^(hassubstring(%'/help/'%)) ^(hassubstring(%'/ref/'%))
			^(hassubstring(%'/doc/'%)) ^(hassubstring(%'/teach/'%))
			^(hassubstring(%'/l:/'%))
	  ]
		{vedlinemax 72}]

	;;; get value of popcompiler, etc right

	['.p'           {subsystem "pop11}]

	[lispfiletypes  {subsystem "lisp}]

    [prologfiletypes          {subsystem "prolog}]

	[pmlfiletypes {subsystem "ml}]
	['.csh'
		{popcompiler csh_compile}]
	['.sh'
		{popcompiler sh_compile}]
	[['.p' '.pl' lispfiletypes pmlfiletypes]
		{vedcompileable ^true}]

	;;; The list -vednonbreakfiles- is defined below
	[vednonbreakfiles {vedbreak ^false}]

    ;;; Make sure VED's output files, from lmr etc are not compiled
	;;; by ENTER L, ENTER C, etc.
	[is_ved_output_file {vedcompileable ^false}]

	;;; make sure vednotabs set false for program, lib and data files
	[['.p' '.ph' '.pl' lispfiletypes '.com' '.s' '.c' '.i'
		pmlfiletypes
		^(hassubstring(%'/lib/'%)) ^(hassubstring(%'/data'%))]
	 		{vednotabs ^false} ]

	[['.s' '.s-' '.out' '.ps' '.c' ]
		{vedindentstep 8}]


	;;; make system mail file and "output" and "picture" files non-writeable
	;;; replace XXXX with your login name
	[ [^(hassubstring(%'/mail/XXXX'%))
		^(hasendstring(%'/mailbox'%))
		^(hasendstring(%'picture'%))
		^(hasendstring(%'output'%))
		^(hasendstring(%'OUTPUT'%))
		^(hasendstring(%'/output.p'%))
		^(hasendstring(%'/output.pl'%))
		^(hassubstring(%'/interact.'%))
		^(hasendstring(%'output.lsp'%))]
		{vedwriteable ^false}]
] -> vedfiletypes;

vars ved_g_string;

global vars vedoutputfileschanged = [];
define vedsetoutput();
    if vedusewindows == "x"
    and  not(lmember(vedcurrentfile, vedoutputfileschanged))
    then
        12, 6, 580 -> xved_value("currentWindow", [numRows x y]);
        vedcurrentfile::vedoutputfileschanged
            -> vedoutputfileschanged;   ;;; prevent repetition
    endif;
enddefine;


define vedinitfile;
	;;; run whenever a file is set or re-set on screen
	lvars firstline =  subscrv(1,vedbuffer);
	if isstartstring('HELP ', firstline)
	or isstartstring('TEACH ', firstline)
	or isstartstring('REF ', firstline)
	then
		72 -> vedlinemax; true -> vednotabs
	endif;

	;;; optional
    ;;; if 'output' = sys_fname_nam(vedpathname) then vedsetoutput() endif;
enddefine;
