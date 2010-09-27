/* --- Copyright University of Birmingham 2009. All rights reserved. ------
 > File:            $poplocal/local/ved_latex/auto/ved_bib.p
 > Linked to        $poplocal/local/auto/ved_bib.p
 > Purpose:         Create BIBTEX file entry
 > Author:          Aaron Sloman, Jun 24 1996 (see revisions)
 > Documentation:	HELP * VED_BIB also HELP * LATEX, HELP * VED_LATEX
 > Related Files:
 */

/*

Bibtex file entries can take various formats, including
the following, with appropriate entries between the "..." quote marks.

@InCollection{XXX95 ,
	author = "  ",
	title = "  ",
	booktitle = "  ",
	year = "  ",
	editor = " ",
	pages = "  ",
	publisher = "  ",
	address = "  "
}
@Inproceedings{YYY83 ,
	author = "  ",
	year = "  ",
	title = "  ",
	booktitle = "  ",
	pages = "  "
	publisher = "  ",
	address = "  ",
}
@Article{ZZZ85 ,
	author = "  ",
	title = "  ",
	journal = "  ",
	year = "  ",
	volume = "  ",
	number = "  ",
	pages = "  "
}

To use ENTER bib, create something like the following, starting with the
citation you want to use in latex files, then on each line one of the
KEYS listed below, followed by a space followed by the associated entry
for the key.

beaudoin93
AU L.P. Beaudoin and A. Sloman
TI A study of motive processing and attention
BO Prospects for Artificial Intelligence
AU A.Sloman and D.Hogg and G.Humphreys and D. Partridge
	and A. Ramsay
PA 229--238
YE 1993
PU IOS Press
AD Amsterdam

Then mark the above and do "ENTER bib". It converts the above to the
following, after which you can delete the unwanted headings.

@PhdThesis
@InCollection
@InProceedings
@Article
@Book
{beaudoin93,
  author = "L.P. Beaudoin and A. Sloman",
  title = "A study of motive processing and attention",
  booktitle = "Prospects for Artificial Intelligence",
  author = "A.Sloman and D.Hogg and G.Humphreys and D. Partridge
	and A. Ramsay",
  pages = "229--238",
  year = "1993",
  publisher = "IOS Press",
  address = "Amsterdam",
}

If you know that it should be @PhdThesis, then put that in the
marked range in the line before beaudoin93, and the ENTER bib
command will not print the full list of possible document types.

*/

section;
compile_mode: pop11 +strict;

;;; Set up the KEYS in a property. Users can extend this
global vars procedure bibfield =
	newproperty(
		[
		[AD 'address']
		[AN 'annote']	;;; for annotated bibliographies
		[AU 'author']
		[BO 'booktitle']
		[CH 'chapter']
		[ED 'editor']
		[EN 'edition']
		[HO 'howpublished']
		[IN 'institution']
		[ISB 'isbn']
		[ISS 'issn']
		[JO 'journal']
		[KE 'key']	;;; use when author and editor are missing
		[MO 'month']
		[NO 'note']
		[NU 'number']
		[OR 'organization']
		[PA 'pages']
		[PL 'place']
		[PU 'publisher']
		[SC 'school']	;;; Use this for university, etc.
		[SE 'series']
		[SU 'subtitle']
		[TI 'title']
		[TY 'type']		;;; e.g. research report
		[URL 'url']
		[VO 'volume']
		[YE 'year']
		], 24, false, "perm");

;;; some fields need to be put in braces to preserve capitalisation.
;;; List them here
global vars
	title_fields = [TI BO];

define check_abbreviations();
	lvars key, field;
	vedpositionpush();
	vedmarkfind();
	if isstartstring('@', vedthisline()) then
		vednextline();
	endif;
	repeat
		vednextline();
		quitif(vedline > vvedmarkhi);	;;; end of range
		nextif(strmember(vedcurrentchar(), '\s\t'));	;;; continuation
		vednextitem() -> key;
		bibfield(key) -> field;
		unless field then
			vederror('UNRECOGNIZED KEY '>< key);
		endunless;
	endrepeat;
	vedpositionpop();
enddefine;
	

define ved_bib();
	dlocal vedbreak = false;

	;;; Make sure only correct abbreviations are used.
	check_abbreviations();
	vedmarkfind();
	if isstartstring('@', vedthisline()) then
		;;; go down one line and shift marked range
		vednextline();
	else
		vedlineabove();
		applist(
			[
				'@Article\n'
				'@Book\n'
				'@Booklet\n'
				'@Conference\n'
				'@InBook\n'
				'@InCollection\n'
				'@InProceedings\n'
				'@Manual\n'
    			'@MastersThesis\n'
    			'@Misc\n'
    			'@PhdThesis\n'
    			'@Proceedings\n'
				'@TechReport\n'
    			'@Unpublished'
			],
			vedinsertstring);
		vednextline();
	endif;
	vedinsertstring('{');
	vedtextright();
	vedinsertstring(',');
	lvars key, field;
	repeat
		vednextline();
	quitif(vedline > vvedmarkhi);	;;; end of range
	nextif(strmember(vedcurrentchar(), '\s\t'));
		vednextitem() -> key;
		bibfield(key) -> field;
		unless field then
			vederror('UNRECOGNIZED KEY '>< key);
		endunless;

		;;; check if a title field requiring braces
		lvars insert_brace = lmember(key, title_fields);

		vedwordrightdelete();
		vedinsertstring('  ');
		vedinsertstring(field);
		vedinsertstring(' = {');
		if insert_brace then vedcharinsert(`{`) endif;
		while (vednextline(); strmember(vedcurrentchar(), '\s\t')) do
			;;; leading space or tab. Treat as continuation
		quitif(vedline > vvedmarkhi)
		endwhile;
		;;; got to end of continuation, so go back and insert '"'
		vedcharup();
		vedtextright();
		if insert_brace then vedcharinsert(`}`) endif;
		vedinsertstring('},');
	endrepeat;
	vedlineabove();
	vedcharinsert(`}`);
	vedmarkfind();
enddefine;


endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Apr 14 2009
		altered to use braces for all lines instead of double quotes.
--- Aaron Sloman, Feb  8 2003
	Added URL field
--- Aaron Sloman, Feb  4 2001
	Added ISB and ISN for "isbn" and "isbn" fields.
--- Aaron Sloman, Sep 22 2000
	Changed to insert braces round book or article titles,
	depending on whether the list title_fields contains
	the words "BO" "TI" which it does by default.
--- Aaron Sloman, Mar 18 2000
	Allowed user to insert @Book, or whatever at the top.
--- Aaron Sloman, Dec  6 1998
	Added Subtitle
--- Aaron Sloman, Nov  8 1998
	replaced \r with \n
--- Aaron Sloman, Dec 14 1996
	Added @Techreport
 */
