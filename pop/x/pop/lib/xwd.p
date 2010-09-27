/* --- Copyright University of Birmingham 2009. All rights reserved. ------
 > File:			$usepop/pop/x/pop/lib/xwd.p
 > Purpose:			Dump a poplog graphic window to file, using xwd
 > Author:			Aaron Sloman, Sep  1 2009 (see revisions)
 > Documentation:   HELP XWD
 > Related Files:
 */


define xwd(widgetname, newname);

	;;; e.g. xwd('Xgraphic', 'fig1.jpg')
	;;; creates a jpeg dump of the Xgraphic window, called fig1.jpg

    lvars xwdname1 = widgetname >< '.xwd';
	;;; invoke xwd
    sysobey('xwd -nobdrs -out ' >< xwdname1 >< ' -name Xgraphic');
	;;; invoke 'convert' to create new graphic file
    sysobey('convert ' >< xwdname1 >< ' ' >< newname);
	;;; delete the xwd file
    sysdelete(xwdname1) ->;

enddefine;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep  1 2009
		removed quotes from argument of sysdelete!!
 */
