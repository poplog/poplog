/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_showtree.p
 > Purpose:         Version of LIB SHOWTREE using rc_graphic
 > Author:          Riccardo Poli, Dec 14 1996 (see revisions)
 > Documentation:	HELP SHOWTREE and below
 > Related Files:   LIB SHOWTREE
 */

;;;
;;; Program:        rc_showtree.p
;;;
;;; Author:         Riccardo Poli
;;;
;;; Creation date:  Dec 1996
;;;
;;; Description:    A graphical version of showtree based on RC_GRAPHIC
;;;
;;; Changes: March 1 1997 Added capability of drawing sideways trees
;;;

/*

;;; A few examples on how to use rc_showtree
;;; First run them with showtree_sideways=false then assign:
;;; true -> showtree_sideways;

rc_start();
rc_showtree([+ [* 1 x][/ [+ 3 y] 10]],-200,0);

;;; Changing fonts and types of connections
rc_start();
rc_showtree([OR [NAND x2 x1] [NOR x1 x1]],-200,-230,'9x15');
true -> showtree_ortho_links;
rc_showtree([OR [NAND x2 x1] [NOR x1 x1]],0,-230,'fixed');
false -> showtree_oblong_nodes;
rc_showtree([OR [NAND x2 x1] [NOR x1 x1]],-100,0,'10x20');

;;; A bigger tree
rc_destroy();
1000 -> rc_window_xsize;
false -> rc_clipping;
rc_start();
false -> showtree_ortho_links;
true -> showtree_oblong_nodes;
rc_showtree([University
       [Science
        [Psychology Glyn Cristina '...']
        [ComputerScience Aaron Riccardo Manfred '...']
        '...']
       [Engineering
        MechEng
        ElecEng
        '...']
       '...'],-300,-200,'5x7');


;;; A parse tree
rc_start();
rc_showtree([s [np [pn he]]
      [vp [vnplocnp put]
          [ppnplocnp [np [snp [det a]
                              [qn [adj big] [qn [noun dog]]]]]
                     [locprep into]
                     [np [snp [det each] [qn [noun car]]]]]]],-300,-200,
	             '8x13');
*/

uses showtree;
uses rc_graphic;
uses rclib;
uses rc_font;

section;

vars showtree_sideways = false;
vars showtree_oblong_nodes = true;
vars showtree_ortho_links = false;
vars showtree_scale = 10;

define showtree_box(r1,c1,r2,c2);
    if showtree_sideways then
	(r1,c1,r2,c2) -> (c1,r1,c2,r2)
    endif;
    rc_jumpto(r1,c1);
    if showtree_oblong_nodes then
    	rc_draw_oblong(r2-r1,c2-c1,1);
    else
    	rc_draw_rectangle(r2-r1,c2-c1);
    endif;
enddefine;

define vars showtree_width(node, name);
    lvars node, name, size;
    if showtree_sideways then
    	XpwFontHeight(rc_window)  / rc_yscale  -> size;
	if showtree_node_daughters()(node) then
	    size + 2
	else
	    size
	endif;
    else
    	unless name.isstring then
            name><'' -> name
    	endunless;
    	XpwTextWidth(rc_window, name)  / rc_xscale + 1 -> size;
	if showtree_node_daughters()(node) then
	    size + 2
	else
	    size
	endif;
    endif;
enddefine;

define vars showtree_height(node,name);
    lvars node, name, size;
    if showtree_sideways then
    	unless name.isstring then
            name><'' -> name
    	endunless;
    	XpwTextWidth(rc_window, name)  / rc_xscale + 1 -> size;
	if showtree_node_daughters()(node) then
	    size + 2
	else
	    size
	endif;
    else
    	if XpwFontHeight(rc_window) < 10 then
	    2;
    	else
    	    XpwFontHeight(rc_window) / 10.0 * 2;
    	endif;
    endif;
enddefine;

define vars showtree_draw_node(node, val);
    lvars node, val, name, r1, c1, r2, c2, size, h;

    dl(val) -> c2 -> c1 -> r2 -> r1;
    hd(showtree_node_draw_data()(node)) -> name;
    unless name.isstring then
        name><'' -> name
    endunless;
    if showtree_node_daughters()(node) then
	showtree_box(c1, r1, c2-2, r2);
 	c1 + 1 -> c1
    endif;
    XpwTextWidth(rc_window, name)  / rc_xscale -> size;
    XpwFontHeight(rc_window) / 10.0 -> h;

    if showtree_sideways then
    	rc_print_at(r1 + size/length(name), c1  + /* if h <= 1.3 then 0 else */ h/2  /* endif*/, name);
    else
    	rc_print_at(c1, r1 +  h, name);
    endif;
enddefine;

define  connectup();
    define vars join(node, unode);
	lvars node, unode, loc1, loc2, elem;
	if islist(unode) then
	    for elem in unode do join(node,elem) endfor;
	else
	    showtree_node_location()(node) -> loc1;
	    showtree_node_location()(unode) -> loc2;
	    drawline(showtree_mid(loc1(4),loc1(3)),
		     loc1(2),
		     showtree_mid(loc2(4),loc2(3)),
		     loc2(1))
	endif;
    enddefine;

    appproperty(showtree_node_daughters(),
		procedure(node, val);
		    lvars val, node, unode, subnodes;
		    if listlength(val) > 0 then
			dest(val) -> subnodes -> unode;
			if subnodes == [] then
			    join(node, unode)
			else
			    join(node, unode);
			    last(subnodes) -> unode;
			    allbutlast(1, subnodes) -> subnodes;
			    join(node, unode);
			    join(node, subnodes)
			endif
		    endif
		endprocedure);
enddefine;


define vars rc_showtree(tree,x,y);
    lvars font, oldfont = rc_font(rc_window);

    if isstring(y) then
        ;;; font given, so re-set input locals
        tree,x,y -> (tree,x,y,font);
        font -> rc_font(rc_window);
    else
        false -> font
    endif;

	;;; set exit action if font given
    dlocal
        0 % ,
            if font and dlocal_context < 3 then
                oldfont -> rc_font(rc_window);
            endif%;

    dlocal drawline = rc_drawline,
           showtree_vgap,
	   showtree_mid,
           rc_xscale = showtree_scale * rc_xscale,
	   rc_yscale = -showtree_scale * rc_yscale,
	   rc_xorigin = rc_xorigin + x,
	   rc_yorigin = rc_yorigin + y;

	   procedure(c1, c2);
	       (c1 + c2 - 3) / 2.0
	   endprocedure -> showtree_mid;

    if showtree_sideways then
	procedure(r1,c1,r2,c2);
	    (r1,c1,r2,c2) -> (c1,r1,c2,r2);
    	    rc_drawline(r1,c1,r2,c2);
	endprocedure -> drawline;
 	intof(showtree_scale/2) -> showtree_vgap;
    endif;

    showtree_init();
    newproperty([], 59, false, true) -> showtree_node_location();
    newproperty([], 59, false, true) -> showtree_node_daughters();
    newproperty([], 59, false, true) -> showtree_node_draw_data();
    newproperty([], 59, false, true) -> showtree_subtree_rootnode_name();
    $-showtree$-shapetree($-showtree$-transformtree(tree,1));
    appproperty(showtree_node_location(), showtree_draw_node);
    if showtree_ortho_links then
    	$-showtree$-connectup();
    else
	connectup();
    endif;
enddefine;

vars procedure rc_drawtree = rc_showtree;

endsection;

/* --- Revision History ---------------------------------------------------
--- Riccardo Poli, Mar  1 1997
	Added capability of drawing sideways trees
 */
