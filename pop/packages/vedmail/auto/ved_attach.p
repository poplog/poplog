/* --- Copyright University of Birmingham 2004. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_attach.p
 > Purpose:         Read in a file mimencoded as attachment and prepare message to send
 > Author:          Aaron Sloman, Feb 11 2001 (see revisions)
 > Documentation:	HELP VED_ATTACH
 > Related Files:	LIB mimencode, LIB ved_readmime
 */

/*

ENTER attach <filename>

See HELP ved_attach

This command reads in a mime-encoded version of the file, and prepares
lines to go into message header and attachment header to allow
the attachment to be sent and decoded at the other end.

If you use the version of lib ved_send from Birmingham it will
send the additions to the header. it will not work with the default
version of ved_send, which pipes mail through mail or Mail.


REQUIRES
	lib mimencode
		http://www.cs.bham.ac.uk/research/poplog/auto/mimencode.p

	lib ved_readmime
		http://www.cs.bham.ac.uk/research/poplog/auto/ved_readmime.p
*/

section;

global vars ved_attach_first_time = true;

global vars attachment_divider = 'BARRIER-INSERTED-BY-ved_attach===';

define ved_attach();
	dlocal
	vedbreak = false,
	vedautowrite = false;

	lvars
		barrier = systmpfile(nullstring, attachment_divider, nullstring),
		files = maplist(sysparse_string(vedargument), sysfileok);


	vedpositionpush();
	;;; Insert stuff to go in mail header
	vedlinebelow();
	vedinsertstring('\nEDIT THE MARKED RANGE, THEN ENSURE IT IS STILL ALL MARKED AND SEND WITH\n\t\t ENTER sendmr\n');
	if ved_attach_first_time then
		vedinsertstring('NOTES:\n');
		vedinsertstring('   The To: and Cc:/Bcc: lines can overflow.\n');
		vedinsertstring('       Overflow address lines must start with at least four spaces or a tab. \n');
		vedinsertstring('   NB: Use comma to separate addresses.\n');
		vedinsertstring('   NB: Leave a space after each colon.\n');
		vedinsertstring('	Delete unwanted lines in the header: do NOT leave them blank.\n');
		vedinsertstring('   See HELP ved_attach, TEACH email, HELP ved_getmail, HELP send\n\n');
	;;; do not print all that again in this session
	false -> ved_attach_first_time ;
	endif;
	vedmarklo();
	vedinsertstring('To: \n');
	vedinsertstring('Subject: \n');
	vedinsertstring('Cc: \n');
	vedinsertstring('Bcc: <addresses for "blind copies">\n');
	vedinsertstring('MIME-Version: 1.0\n');
	vedinsertstring('Content-Type: multipart/mixed; boundary="');
	vedinsertstring(barrier);
	vedinsertstring('"');

	'--' sys_>< barrier -> barrier;
	
	vedinsertstring('\n\nThis is a multi-part message in MIME format,\nwith an attachment below.\n\n');

	;;; Start region for viewable plain text
	vedinsertstring(barrier);
	vedlinebelow();
	vedinsertstring('Content-Type: text/plain; charset=us-ascii; format="flowed');
	vedinsertstring('"\n\nINSERT YOUR PLAIN TEXT MESSAGE HERE\n\n');
	vedinsertstring('\n\nContent below inserted by ved_attach\n\n');

	lvars
		file;

	for file in files do

		;;; Veddebug('attaching ' >< file);

		lvars
			name = sys_fname_name(file),
			type = uppertolower(sys_fname_extn(file));

		;;; start header for attachment
		vedinsertstring(barrier);
		vedlinebelow();
		vedinsertstring('Content-Type: ');
		if type = nullstring then
			vedinsertstring('text/plain;');
		elseif type = '.html' or type = '.htm' then
			vedinsertstring('text/html;');
		elseif type = '.ps' then
			vedinsertstring('text/postscript;');
		elseif type = '.pdf' then
			vedinsertstring('application/pdf;');
		elseif type = '.zip' then
			vedinsertstring('application/zip;');
		elseif type = '.gz' or type = '.tgz' then
			vedinsertstring('application/x-gzip;');
		elseif type = '.tar' then
			vedinsertstring('application/x-tar;');
		else
			vedinsertstring('application/octet-stream;');
		endif;

		vedinsertstring(' name="'); vedinsertstring(name); vedinsertstring('"\n');
		vedinsertstring('Content-Disposition: attachment; filename="');
		vedinsertstring(name); vedinsertstring('"\n');
		vedinsertstring('Content-Transfer-Encoding: BASE64 \n');

		;;; Read in the file mime-encoded (BASE64)

		veddo('readmime ' >< file);
	endfor;

	;;; Insert closing boundary
	vedinsertstring(barrier);
	vedinsertstring('--\n');
	vedcharup();
	vedmarkhi();
	vedpositionpop();
enddefine;
	
endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Mar  7 2004
		Changed to insert information about 'application' types for
		pdf, gzip, tgz, zip and tar files
--- Aaron Sloman, Feb 11 2003
		Altered to allow multiple arguments
--- Aaron Sloman, Sep  7 2001
	Changed to insert "application/octet-stream;" after Content-type:
	in some cases.
--- Aaron Sloman, Feb 11 2001
	Made many changes (a) to ensure better mime conformity and (b) to make
	it easier to use. Now prints instructions and inserts To: lines, etc.
 */
