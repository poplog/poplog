/* --- Copyright University of Sussex 1995.	 All rights reserved. ---------
 > File:		   C.all/lib/lib/views.p
 > Purpose:		   viewpoint/context mechanisms
 > Author:		   Aaron Sloman, Oct 19 1986 (see revisions)
 > Documentation:  TEACH * VIEWS, HELP * VIEWS, *NEWANYPROPERTY, *SYSHASH
 > Related Files: LIB * NEWMAPPING, * CURRENT_VIEW
 */

;;; faster version - for V 12.4 POPLOG or later

/*
Many programs need to be able to create a network of views related in such
a way that:
a. some complex object, e.g. an assertion, may have different values in
	different views
b. certain views are 'descendents' of other views, and if an object is
	not given a specific value in a view it simply inherits the value
	in the most recent ancestor in which it was given a value.

This package provides a mechanism for creating trees or networks of views.
A net consists of one or more root views, and views descended from it,
views descended from them: e.g.

					view 1
				  /	  |	  \
				 /	  |		\
		  view 2	  view 3   view 6
		 /	\	  /			 /	\
	view 4	view 5		  view 7  view 8
				   \	 /	 \
					view 9	  view 10

Since a view can be constructed with more than one parent, the view
structure can be an arbitrary network.

Any object may be given a value relative to a view. This value is capable
of being inherited by views descended from that one. The full story is
is explained in TEACH * VIEWS and HELP * VIEWS

LIB CURRENT_VIEW extends this package with the notion of a "current" view.

*/

section;


;;; save and set some compilation switches
lconstant construct= popconstruct, popopt=pop_optimise;
true -> popconstruct;
true -> pop_optimise;
true -> popdefineprocedure;


;;; GLOBAL VARIABLES
;;; Define a unique object to indicate no value at this point:
global constant no_view_value='<no_view_value>';

;;; DEFINE A VIEW DATA-TYPE AND ASSOCIATED PROCEDURES

;;; A view contains a property (view_map) and a list of parent views.
;;; We could use one property for everything, but that would cause
;;; garbage collection problems if views are abandoned, as we can't
;;; use temporary properties.

recordclass view view_map view_parents view_mark view_props;

;;; temporary hack - fast procedures

lconstant
	procedure(fast_view_map=fast_front, fast_view_parents=fast_back);
;;; note - fast_subscrv is used below for view_mark


define lconstant view_print(view) with_props pr;
;;; print procedure for views.
	lvars view i;
	view_parents(view) -> i;
	printf(
		view_props(view),
		if isview(i) then 'parent' elseif ispair(i) then 'parents' else i endif,
		'<view <property> %p %p>')
enddefine;

view_print -> class_print(view_key);

;;; define a procedure that takes user specifications for newanyproperty
;;; and a parent or list of parent views and returns a new view which
;;; includes a property for mapping structures onto values.
;;; The only argument not supplied by the user for newanyproperty is
;;; the default value. This is always no_view_value.

define new_view(list,size,expand,thresh,hash,eqtest,gc,
							/*nodefault*/,
							perm, parents);
	lvars parents,list,size,expand,thresh,hash,eqtest,gc,perm;
	;;; create a view made of a property, parent(s), and undef view_mark
	consview(
	  newanyproperty(list,size,expand,thresh,hash,eqtest,gc,
			no_view_value,perm),
	  parents,undef,[])
enddefine;


;;; Define a default simplified version of new_view using user-assignable
;;; hashing procedure -view_hash_default- and ordinary "=".
;;; Assume initial table always has 2 elements, and expand by factor of 8
;;; each time it gets full.

global vars view_hash_gc;

unless isboolean(view_hash_gc) then false -> view_hash_gc endunless;

global vars procedure view_hash_default;

if isundef(view_hash_default) then
	syshash -> view_hash_default;
	false -> view_hash_gc;
endif;

define newsubview(parents,size);
	lvars parents,size;
		new_view([],size,1,false,view_hash_default,nonop =,view_hash_gc,
			false, parents)
enddefine;



;;;; FACILITIES TO ENSURE A UNIQUE MARK WHEN SWEEPING THROUGH CONTEXTS

lvars view_mark_count= -2:11111111111111111111111111111;	;;; largest neg int


define constant new_view_mark;
	;;; each time this is called it returns a new, unique integer or biginteger
	view_mark_count + 1 ->> view_mark_count
enddefine;

define updaterof new_view_mark with_nargs 1;
	;;; for re-setting
	-> view_mark_count
enddefine;


;;;; FACILITIES TO MANIPULATE A "FREE LIST"
;;; I.e. cut down garbage collections in procedure sweep_views

define lconstant fast_copylist(list)->newlist;
	lvars list last newlist list2;
	if list==[] then
		[] -> newlist
	else
		conspair(fast_front(list), []) ->> last -> newlist;
		fast_back(list) -> list;
		until list == [] do
			conspair(fast_front(list), []) ->> fast_back(last) -> last;
			fast_back(list) -> list;
		enduntil;
	endif
enddefine;

/*
define lconstant view_garbage(pair);
;;; for putting used pairs back on free list
	lvars pair;
	if ispair(pair) then
		[] -> fast_back(pair);
		sys_garbage_list(pair);
	else
		mishap(pair,1,'VIEW SYSTEM ERROR IN VIEW_GARBAGE')
	endif
enddefine;

*/


;;;; FACILITIES FOR SEARCHING UP ANCESTORS OF VIEWS
/*
Searching is controlled by view_search, which is user assignable.
Its value is one of:

	"depth"		-do depth-first search
	"breadth"	-do breadth-first search
	A procedure -do user-defined search. See HELP * VIEWS

The same procedures are used by appview appviewmap and view_value. For
efficiency they have been written in a not terribly clear fashion.
*/

global vars view_search;
if isundef(view_search) then "depth" -> view_search endif;

vars appquit=false; ;;; abort search if this is made true


;;; Have a global lexical procedure type identifier, so that check
;;; for procedure is done only once, when it is assigned.

lvars procedure app_user_proc;

define lconstant -5 item1 fast_nc_<> item2;
	lvars item1 next item2 _key1 _key2;
	if item1 == [] then item2
	elseif item2 == [] then item1
	else
		item1;				;;; the result
		repeat
			fast_back(item1) -> next;
			quitif(next==[]);
			next -> item1;
		endrepeat;
		item2 -> fast_back(item1);
	endif;
enddefine;

if identprops("sys_grbg_destpair") == undef then
	syssynonym("sys_grbg_destpair","fast_destpair")
endif;

define lconstant sweep_views(views,mark);
;;; if view_search is a procedure, use this - for user-defined searches
	lvars view,mark,views,newviews,procedure searchproc;
	view_search -> searchproc;	;;; error if not a procedure
	fast_copylist(views) -> views;
	until views == [] do
		;;; the list link will be added to the free list
		sys_grbg_destpair(views) -> newviews -> view;
		newviews -> views;
	nextif(view_mark(view) == mark);	;;; ignore marked view
		;;;mark -> view_mark(view);		;;; mark this one
		mark -> fast_subscrv(2,view);	;;; faster
		app_user_proc(view);
		if appquit then return endif;
		fast_view_parents(view) -> newviews;
		if isview(newviews) then
			conspair(newviews,[]) -> newviews
		elseif ispair(newviews) then
			fast_copylist(newviews) -> newviews
		else nextloop() ;;; end of a chain
		endif;
		searchproc(view,views,newviews) -> views;
	enduntil;
enddefine;

define lconstant breadth_views(views,mark);
	;;; if view_search == "breadth" use this. It runs sweep_views
	lvars view,views,mark,newviews;
	dlocal view_search;
	define lconstant temp_view_search(view,old,new) with_props breadth;
		lvars view,old,new;
		old fast_nc_<> new
	enddefine;

	temp_view_search -> view_search;	;;; used non-locally in sweep_views
	sweep_views(views,mark);
enddefine;

define lconstant depth_views(views,mark);
	lvars views,mark,view;
	repeat
		;;; chain up parents applying proc
		if ispair(views) then
			fast_destpair(views) -> views -> view;
			unless view_mark(view) == mark then
				;;;mark -> view_mark(view);		;;; mark this one
				mark -> fast_subscrv(2,view);	;;; faster
				app_user_proc(view);
				if appquit then return() endif;
				fast_view_parents(view) -> view;
				depth_views(view,mark);		;;; do the parents first
				if appquit then return() endif;
			endunless;
		nextloop()
		elseif isview(views) then
			;;; previous view in chain had only one parent
			;;; if view_mark(views) == mark then return() endif;
			if fast_subscrv(2,views) == mark then return() endif; ;;; FASTER!
			;;;mark -> view_mark(views);		;;; mark this one
			mark -> fast_subscrv(2,views);	;;; faster
			app_user_proc(views);
			if appquit then return() endif;
			;;; now get the parents
			fast_view_parents(views) -> views;
		nextloop()
		endif;
		return()	;;; end of chain
	endrepeat
enddefine;

;;; if this changes check view_val
define appview(view,proc);
	;;; chain from view up ancestors, until ancestors branch, then use
	;;; strategy determined by view_search
	lvars view,mark=new_view_mark(),proc;
	dlocal appquit=false, app_user_proc=proc;

	while isview(view) do
		if fast_subscrv(2,view) == mark then return() endif;	;;; already done
		;;;mark -> view_mark(view);		;;; mark this one
		mark -> fast_subscrv(2,view);	;;; faster
		app_user_proc(view);
		if appquit then return() endif;
		fast_view_parents(view) -> view;
	endwhile;
	;;; list of parents found, or end of chain
	if ispair(view) then
		if view_search=="depth" then
			depth_views
		elseif view_search == "breadth" then
			breadth_views
		else
			;;; view_search is a procedure
			sweep_views
		endif(view,mark);
	else	;;; end of view chain. Could flag error if view /== [] ??
	endif;
enddefine;

define appviewmap(view,proc);
	;;; do appproperty(view,proc) for view and all its ancestors
	lvars view;
	lvars procedure proc;
	appview(
		view,
		procedure(v); lvars v; appproperty(fast_view_map(v),proc) endprocedure)
enddefine;


;;;; PROCEDURES FOR WORKING OUT AN OBJECT'S VALUE IN A GIVEN VIEW

;;; The next procedure finds a value for an item in a view, searching
;;; up through parents if necessary, under control of view_search

;;; If this changes, check appview
define view_value(view,item);
	lvars view, mark=new_view_mark();
	dlvars item;
	dlocal appquit=false, app_user_proc;
	define lconstant procedure do_proc(v);
		lvars v;
		fast_view_map(v)(item) -> v;
		unless v == no_view_value then
			v;
			true -> appquit;
		endunless
	enddefine;
	;;; stay in this procedure while there's only one parent
	while isview(view) do
		if fast_subscrv(2,view) == mark then return(no_view_value) ;;; already done
		else
			do_proc(view);
			if appquit then return() endif;
		endif;
		fast_view_parents(view) -> view;
	endwhile;


	;;; list of parents found, or end of chain
	if ispair(view) then
		do_proc -> app_user_proc;
		if view_search=="depth" then
			depth_views
		elseif view_search == "breadth" then
			breadth_views
		else
			;;; view_search is a procedure
			sweep_views
		endif(view,mark);
	else	;;; end of view chain. Could flag error if view /== [] ??
	endif;
	unless appquit then no_view_value; endunless
enddefine;

define updaterof view_value(view,item);
	lvars value,view,item;
	-> view_map(view)(item)
enddefine;


define freeze_view(view,list);
	;;; for every item in list, find its current value in the view,
	;;; and copy it into the view, so that the inheritance mechanism
	;;; is no longer used.
	lvars item, list, view, procedure map=view_map(view);
	for item in list do
		view_value(view,item) -> map(item)
	endfor;
enddefine;

define merge_view_values(view1,view2,check_clash);
	;;; For every association in view1 copy it into view2.
	;;; If check_clash is non-false, then it is a procedure, and for each
	;;; item check that there is not already a different value which is being
	;;; overwritten:  if there is invoke the procedure check_clash with
	;;; arguments as below:
	lvars check_clash,view1,view2,prop1,procedure prop2;
	view_map(view1) -> prop1;
	view_map(view2) -> prop2;
	unless isproperty(prop1) then appproperty(prop1,identfn) endunless; ;;; mishap
	fast_appproperty(
		prop1,
		procedure(item,val);
			lvars item,val;
			if check_clash then
				unless val == view_value(view2,item) then
					check_clash(item,view1,val,view2,view_value(view2,item))
				endunless
			endif;
			val -> prop2(item)
		endprocedure)
enddefine;

define view_consistent(list,view1,view2,eqproc,report);
	;;; Test whether items in list have consistent values and if not report
	;;; Consistency means either one being undefined and the other defined
	;;; or both values satisfying eqproc
	lvars list,item,view1,view2,val1,val2,procedure(eqproc,report);
	for item in list do
		view_value(view1,item) -> val1;
		view_value(view2,item) -> val2;
		unless eqproc(val1,val2) then
			unless val1 == no_view_value or val2 == no_view_value then
				report(item,view1,val1,view2,val2)
			endunless
		endunless
	endfor
enddefine;


vars views=true;	;;; to help with 'uses';

;;; restore old values of globals
construct -> popconstruct;
popopt->pop_optimise;
endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul 11 1987
	removed spurious 'enddefine'
--- Aaron Sloman, Jan 11 1987
	Added merge_view_values, view_consistent
--- Aaron Sloman, Dec  6 1986
	tailored to use V12.4 facilities:
		new fast property access procedures, and sys_garbage_list
	used do_proc to simplify code
--- Aaron Sloman, Dec  3 1986
	Added freeze_view
	Extra field for each view -- view_mark, newsubview takes a size.
	Added appview appview, appviewmap. Some stuff moved to current_view
--- Aaron Sloman, Nov  8 1986  replaced for_true with for_view and
	generalised it.
--- Aaron Sloman, Nov  5 1986 no longer uses LBI HASHPROCS. Uses SYSHASH
	for view_hash_default
*/
