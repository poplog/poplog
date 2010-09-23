/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/lib/vedscreendown.p
 > Purpose:			Fix vedscreendown for end of file
 > Author:          Aaron Sloman, Sep 12 1995
 > Documentation:	Below
 > Related Files:
 */

;;; Change behaviour of vedscreendown on last screenful to show only
;;; new text and last line of previously visible text.


/*
Date: Tue Sep 12 08:33:29 BST 1995
Subject: fixing behaviour of vedscreendown at end of file
Newsgroups: comp.lang.pop

I wonder whether other people find vedscreendown as annoying as I do
when it reaches the end of a file?

You can be reading a file a window at a time, and each time you use
vedscreendown it gets a new page and ensures that what was the last
visible line previously becomes the new top line.

Thus you can easily continue reading beyond the end of the previous
page.

However, when it gets to the last screenful, instead of doing this it
tries to make as much as possible of the text fit on the screen. Thus if
you were reading, you have to search for the unread bit of text which
could start ANYWHERE on the screen.

I suppose there are some people who like this behaviour, which is why it
has not been changed. If you are one of those who dislikes it, here's
a file you can compile when VED starts up (before setting any
key bindings). You could put it into $poplocal/local/lib/vedscreendown.p
and then invoke it as

    loadlib("vedscreendown");
=======================================================================
*/



section;
;;; Unfortunately this is yet another VED identifier which is protected,
;;; and should not be.
sysunprotect("vedscreendown");


define lconstant vedwantrefresh(line);
	;;; Required for some old dumb vdus with vednolinedelete true.
    ;;; This could be removed for modern terminals and xterm windows etc.
	;;; See * vedrefreshneeded (current REF entry is not very clear)
	lvars line;
	unless vedonstatus then
        ;;; see whether to increase amount of window requiring refreshing.
		if vedrefreshneeded then
			min(vedrefreshneeded,line)
		else
			line
		endif -> vedrefreshneeded
	endunless
enddefine;

define global vars procedure vedscreendown();
    ;;; New version
	;;; The VED procedure Vedwindowbottom should have been exported?

	lvars windowbottom = vedlineoffset fi_+ vedwindowlength fi_- 1;

	if vedline fi_>= windowbottom then
        ;;; current line is at or beyond bottom of window.
		if vedline fi_> vvedbuffersize then
			vederror('END OF FILE');
		else
			;;; Find next cursor line, to put at bottom of screen
			vedline fi_+ vedwindowlength fi_- 2 -> vedline;
			;;; Either scroll or refresh.
			unless vedscrollscreen then
				;;; Not scrolling, so put previous bottom line at top
				windowbottom fi_- 1 -> vedlineoffset;
                ;;; refresh changed bit of screen if there's no input waiting
				if vedinputwaiting() then
					vedwantrefresh(2)
				else
					vedrefreshrange(
						vedlineoffset + 1,
						vedlineoffset fi_+ vedwindowlength fi_- 1,
						undef)
				endif
			endunless
		endif;
	else
        ;;; Just move the current line to end of visible screen.
		windowbottom -> vedline;
	endif;
	vedsetlinesize();
enddefine;

endsection;
