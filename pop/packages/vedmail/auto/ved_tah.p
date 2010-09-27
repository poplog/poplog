/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_tmh.p
 > Purpose:			Tidy email header in unix mail file
 > Author:          Aaron Sloman, Nov 12 1989 (see revisions)
 > Documentation:	HELP * VED_TMH (See also HELP * VED_GETMAIL)
 > Related Files:	LIB * VED_MAIL, * VED_SEND, * VED_REPLY
 */

;;; WARNING - may have to be changed at different sites
;;; In particular check transform_mail_addresses

/*
The Tidy Mail Header command

	<ENTER> tmh

Will tidy the mail header of the current message.

	<ENTER> tah

Will tidy all headers in the current file.

They get rid of unwanted lines in the mail header and contract local
email addresses, in accordance with the contents of the list
transform_mail_addresses. The strings in that list are given to ved_gsl,
repeatedly. As a precaution, the list is made empty by default outside
Birmingham.

*/

section;


global vars

transform_mail_addresses =
	['/@uk.ac.bham.cs//' '/@cs.bham.ac.uk//' ],
;
;;; PRECAUTION FOR NON BHAM SITES
unless popsitename = '@cs.bham.ac.uk' then
	[] -> transform_mail_addresses
endunless;

;;; These default values may not suit everyone. Copy and edit
global vars unwanted_mail_headers =
	[ 	'Content-Identifier'	'Date-Received'		  'Delivery-Date'
		'Host' 					'Importance' 		  'In-Reply-To'
		'Mailer' 				'Message-Id' 		  'Mmdf-Warning'
		'Original-Via' 			'Received' 			  'Relay-Version'
		'Return-Receipt-To'
		'Sensitivity' 			'Software-Hoarding'	  'Status'
		'Via' 					'X-Envelope-To' 	  'X-Errors-To'
		'X-Face'				'X-Charset'			  'X-Char-Esc'
		'X-Confirm-Reading-To'
		'X-Mailer' 				'X-mailer'
		'X-Vms-Cc' 			  'X-Vms-To'
		'X-Pmrqc'
		'X400-Content-Type' 	'X400-Mts-Identifier' 'X-Lines'
		'X400-Received'			'X400-Recipients' 	  'X-Sun-Charset'
		'Mime-Version' 'MIME-Version'
		'Content-Type'
		'Content-Length' 		'Content-Transfer-Encoding'
		'Priority'				'Comments'
		'X-Priority' 			'X-Msmail-Priority'
		'MIME-version' 'Content-transfer-encoding'
		'X-MSMail-Priority'
   ],
;

;;;

lvars addresses_done = false;	;;; set after '@' has been transformed to '@@'

define lconstant expand_@(string) -> string;
	;;; replace '@' with '@@' in the string if it exists.
	lvars string, char;
	if strmember(`@`, string) then
		cons_with consstring
		{%
			 appdata(string,
				 procedure; ->> char;
					 if char == `@` then char endif
				 endprocedure)
		%} -> string;
	endif;
enddefine;

define lconstant prepare_addresses_list;
	;;; replace all occurrences of '@' with '@@' in transform_mail_addresses
	returnif(addresses_done  == transform_mail_addresses);
	maplist(transform_mail_addresses, expand_@) -> transform_mail_addresses;
	transform_mail_addresses -> addresses_done;
enddefine;

define lconstant tidy_addresses_in_line;
	lvars vector, string;
	dlocal vedargument;
	for string in transform_mail_addresses do
		string -> vedargument;
		ved_gsl();
	endfor;
enddefine;

define ved_tmh;
	;;; Tidy mail header, under the control of -unwanted headers-
	lvars loc,line, startline = vedline;
	dlocal vvedmarkprops ;
	dlocal ved_search_state;

	prepare_addresses_list();
	vedmarkpush();
	false -> vvedmarkprops;
	vedpositionpush();
	ved_mcm();
	;;; Go to line after From line
	vedjumpto(vvedmarklo fi_+ 1,1);
	;;; check for indented continuation of From line.
	if issubstring('via', vedthisline()) == 12 then vednextline() endif;
	repeat
		vedthisline() -> line;
		quitunless(locchar(`:`,1,line) ->>  loc);
		loc fi_- 1 -> loc;
		quitif(locchar_back(`\s`,loc,line));
		if member(substring(1,loc,line), unwanted_mail_headers) then
			vedlinedelete();
			while vvedlinesize > 4
			and isstartstring('\s\s',vedbuffer(vedline))
			or isstartstring('\^I',vedbuffer(vedline))
			do vedlinedelete() endwhile
		else
			tidy_addresses_in_line();
			vednextline();
			;;; deal with overflow
			while vvedlinesize > 4
			and (vedthisline() -> line, isstartstring('\s\s',line))
			or isstartstring('\t',line)
			do
				tidy_addresses_in_line();
				vedchardown()
			endwhile
		endif;
		quitif(vedline fi_>= vvedmarkhi)
	endrepeat;
	unless vvedmarklo == 1 then
		vedjumpto(vvedmarklo fi_-1 , 1);
		unless vedthisline() = nullstring then
			vedlinebelow()
		endunless
	endunless;

	vedpositionpop();
	;;; Go back into message if necessary
	if vedline < startline then vedchardown() endif;
	vedmarkpop();
enddefine;

define ved_tah;
	;;; Tidy All Headers
	lvars oldchanged = vedchanged;
	dlocal vedediting, vedautowrite = false;
	vedpositionpush();
	vedputmessage('TIDYING, PLEASE WAIT');
	false -> vedediting;
	vedtopfile();
	repeat
		ved_mcm();
		ved_tmh();
	quitif(vvedmarkhi >= vvedbuffersize); 	;;; last message
		vedlocate('@aFrom ');
	endrepeat;
	true -> vedediting;
	nullstring -> vedmessage;
	vedpositionpop();
	vedrefresh();
	if oldchanged then oldchanged + 1 else 1 endif -> vedchanged;
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, 31 Aug 1997
	Even more exclusions
--- Aaron Sloman, May 30 1997
		yet more exclusions
--- Aaron Sloman, May 25 1997
		exclude also 'X-Priority' 			'X-Msmail-Priority'
--- Aaron Sloman, Nov 12 1995
	Added more things to exclude from header
--- Aaron Sloman, Jun 10 1995
	Changed to use ved_search_state
 */
