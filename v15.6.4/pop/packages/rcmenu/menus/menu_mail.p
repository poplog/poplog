/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/menus/menu_mail.p
 > Purpose:
 > Author:          Aaron Sloman, Jan 21 1995
 > Documentation:
 > Related Files:
 */

/*
-- -- Top Level Mail Menu
(Currently specific to Birmingham)
*/

section;

define :menu mail;
	'Mail Ops'
	{cols 2}
	'Menu mail: Read Send'
	['HELP GetMail' 'help ved_getmail']
	['GetMail' ved_getmail]
	['Check mail' 'checkmail']
	['Checkmail off' 'checkmail off']
	['Send' ved_send]
	['Sendmr' ved_sendmr]
	['Reply (all)' ved_Reply]
	['Respond (all)' ved_Respond]
	['reply (one)' ved_reply]
	['respond (one)' ved_respond]
	['NextMess' ved_nm]
	['PrevMess' ved_lm]
	['PageDown' vednextscreen]
	['TidyMess' ved_tmh]
	['MarkMess' ved_mcm]
	['DelMessage' ved_ccm]
	['ListMessgs' ved_mdir]
	['GoMessage' ved_gm]
	['NextFile' ved_nextmail]
	['PrevFile' ved_prevmail]
	['LatestFile' ved_lastmail]
	['MergeFiles' ved_mergemail]
	['SaveMess*'
		[ENTER 'wappcm <file>'
		'Give name of file to which message\nis to be saved (or appended)']]
	['PurgeMail' ved_purgemail]
	['AliasFor*'
		[ENTER 'aliases <name>'
		[
'You can find the email aliases containing <name>\
by giving the command below. To get several names\
at once separate them with "|", as in\
"ENTER aliases smith|jones"'
		]]]
	['ShowAliases' 'do;aliases -people']
	['ShowLists' 'aliases -l']
	['ShowLogfile' 'ved $MAILREC']
	['HELP Send(mr)' 'help send']
	['HELP Reply' 'do;help ved_getmail;/Reply']
	['HELP Respond' 'do;help ved_getmail;/Respond']
	['HELP Aliases' 'help ved_aliases']
	['HELP Purge' 'do;help ved_getmail;/purgemail']
	['HELP Checkmail' 'help ved_checkmail']
	['MENUS...' [MENU toplevel]]
enddefine ;

endsection;
