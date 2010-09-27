/* --- Copyright University of Sussex 1993.  All rights reserved. ---------
 > File:           	C.all/lib/obsolete/old_showtree.p
 > Purpose:        	Old names for showtree identifiers
 > Author:         	Jonathan Cunningham, June 1982 (see revisions)
 > Documentation:  	HELP * SHOWTREE
 > Related Files:
 */

#_TERMIN_IF DEF POPC_COMPILING

section;

uses showtree;

identof("showtree_node_location")	-> identof("node_location");
identof("showtree_node_daughters")	-> identof("node_daughters");
identof("showtree_node_draw_data")	-> identof("node_draw_data");
identof("showtree_subtree_rootnode_name") -> identof("subtree_rootnode_name");
identof("showtree_name")			-> identof("showtreename");
identof("showtree_vgap")			-> identof("vgap");
identof("showtree_isleaf")			-> identof("isleaf");
identof("showtree_root")			-> identof("root");
identof("showtree_daughters")		-> identof("daughters");
identof("showtree_defaults")		-> identof("showtreedefaults");
identof("showtree_init")			-> identof("showtreeinit");
identof("showtree_name_&_subtrees")	-> identof("name_&_subtrees");
identof("showtree_width")			-> identof("width");
identof("showtree_height")			-> identof("height");
identof("showtree_box")				-> identof("box");
identof("showtree_draw_node")		-> identof("draw_node");
identof("showtree_printable")		-> identof("tree_printable");
identof("showtree_graphical")		-> identof("tree_graphical");
identof("showtree_quit")			-> identof("quittree");
identof("showtree_mid")				-> identof("mid");
identof("showtree_mess")			-> identof("showtreemess");

global constant old_showtree = true;

endsection;


/*  --- Revision History ---------------------------------------------------
--- John Gibson, Aug 24 1993
		Moved to lib/obsolete/old_showtree.p
--- John Gibson, Nov 12 1992
		Moved to lib new_showtree with above renaming of identifiers.
--- Adrian Howard, Oct 13 1992
		Fixed bug with the new -pop_pr_quotes- stuff
--- John Williams, Sep 29 1992
		Fixed BR christ.7 by making transformtree variable
--- Adrian Howard, Aug 20 1992
		Made it act sanely when -pop_pr_quotes- is -true-.
--- John Williams, Aug  5 1992
		Fixed BR ianr.33, by making -shapetree- and -connectup- global
		variables instead of lconstants.
--- John Williams, Aug  5 1992
		Fixed BR ianr.32 & BR isl-fr.4460, by adding explicit vars
		declarations for the identifiers documented as variables
		in HELP SHOWTREE
--- John Gibson, Jun 22 1992
		Made sure it draws tree immediately if already in vedprocess
--- John Gibson, Apr  9 1992
		Changed to generate different filenames for each tree, and
		generally cleaned up
--- John Gibson, Feb 13 1992
		Removed all references to old lib g*raphcharsetup
--- John Williams, Jul 28 1989
	Changed 'vedstartwindow = 24' to 'vedstartwindow = vedscreenlength'
	Changed -vars- inside procedures to -dlocal-
--- Aaron Sloman, Oct 27 1988
	Stopped call of vedsetup in background processes
--- John Gibson, Feb 24 1988
		Removed use of /==_nil
--- Mark Rubinstein, Jun  6 1986 - altered sys_>< to ><.
--- Mark Rubinstein, May 15 1986 - sectionised, lvarsed and made some of the
	code more efficient.  Moved into the public library, beefed up the HELP
	file, cleaned up -tree_printable- and introduced -tree_graphical-.
--- Mark Rubinstein, Nov 26 1985 - Made several of the identifiers global.
--- Mark Rubinstein, Dec 1984 -fix so that it doesn't mishap
	when first called from pop
--- Jonathan Cunningham, Mar 1984 Re-written and extended.  Main reason was
	to allow arbitray sized rectangular nodes.
--- Roger Evans, Sep 1983 - modified to VEDFILEPROP and user procs
	SHOWTREEDEFAULTS and SHOWTREEINIT added.  user definable procedure:
		name_&_subtrees(tree) -> name -> subtrees;
	this procedure is given a subtree, and should return the node name
	to be used for that subtree, and the list of sub-trees
	the default assumes that a list in the node name positon is a subtree
--- Aaron Sloman, Nov 1982 modified to accommodate terminals other than Visual
	200
 */
