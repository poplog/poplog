/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/menus/menu_latex.p
 > Purpose:
 > Author:          Aaron Sloman, Jan 21 1995
 > Documentation:
 > Related Files:
 */

/*
-- -- Menu to go with LIB VED_LATEX
See HELP VED_LATEX
*/

section;

define :menu latex;
	'Latex Ops'
	{cols 2}
	'Menu latex: latex & xdvi'
	['Latex*' [ENTER 'latex'
		['This command runs the latex program.'
		 'It will produce a new file showing errors and other'
		 'messages. If there are no errors you can preview or print'
		 '(See HELP VED_LATEX)']]]
	['RunLatex' 'latex']
	['Preview' 'xdvi']
	['AsciiPreview' 'dvi2tty']
	['Print' 'latex print']
	['Pr ManualFeed' 'latex print -m']    ;;; manual feed
	['PrToFile' 'latex print ps']
	['ClearDviLogAux' 'latex clear']
	['SetBold*'
		[ENTER 'latex bold <item>'
		['The <item> can be one of: range (or mr),'
		 'line (or l), word (or w). Default is l']]]
	['SetBoldMR' 'latex bold mr']
	['CentreMR' 'latex centre mr']
	['CenterLine' 'latex centre']
	['ItalicWd' 'latex italic word']
	['ItalicMR' 'latex italic mr']
	['CommentMR' 'latex comment mr']
	['TidyPara' 'jlp']
	['Latex Demo' 'teach latex.tex']
	['TEACH Latex' 'teach latex']
	['HELP Latex' 'help latex']
	['HELP VedLatex' 'help ved_latex']
	['MENUS...' [MENU toplevel]]
enddefine ;

endsection;
