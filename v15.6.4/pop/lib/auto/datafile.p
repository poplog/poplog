/* --- Copyright University of Birmingham 2009. All rights reserved. ------
   --- Copyright University of Sussex 1992.  All rights reserved. ---------
 > File:			C.all/lib/auto/datafile.p
 >					(also newdatafile.p)
 >  Purpose:        Allows certain data structures to be saved on disk
 >  Author:         David Hogg, Feb 1982 (see revisions)
 >           		Riccardo Poli, Aaron Sloman, 13 Nov 1995 (lib newdatafile)
 > 						Extend datafile to deal with closures and procedures
 > 					Modified by Brian Logan 1997 to cope with poparray_by_row
 > 					Aaron Sloman, Sep  1 2009
 >						Merged the previous versions, making newdatafile unnecessary.
 > Documentation: 	HELP DATAFILE (needs updating)
 > Related Files:	LIB NEWDATAFILE (Now just compiles this one)
 */

compile_mode :pop11 +strict;

;;; Datafile allows certain pop data structures to be
;;; recorded on disk. To write a structure to disk type
;;;
;;;     <struc> -> datafile(<filename>);
;;;
;;; Similarly to read a structure back from disk type
;;;
;;;     datafile(<filename>) -> <struc>;
;;;
;;; Permitted datatypes are:
;;;     words, numbers, lists, vector types, record types,
;;;     vector arrays, ordinary properties, booleans

;;; Added by RP and AS:
;;; 	simple closures of named procedures
;;; 	named procedures


section;

lconstant
	procedure (datafread, datafwrite),
;

lvars
	charsonline,
	procedure (rditem, outrep),
;

define lconstant outrepct(x);
	lvars x;
	outrep(x);
	1 + charsonline -> charsonline;
enddefine;

define global datafile(filename);
	lvars filename;
	dlocal rditem = incharitem(discin(filename));
	datafread();
enddefine;

define updaterof datafile(x, filename);
	lvars x, filename;
	dlocal charsonline = 0, outrep = discout(filename), cucharout = outrepct;
	datafwrite(x);
	cucharout(termin);
enddefine;

define lconstant datafwrite(x);
	lvars x, lo;
	if charsonline > 60 then nl(1); 0 -> charsonline endif;
	sp(1);
	if isnumber(x) then
		pr(x);
	elseif isword(x) then
	;;; printing the structure takes up more space and is slower than
	;;; just printing the word but it ensures that words with non printing
	;;; characters are stored properly (eg -space-) and datafile control
	;;; words (e.g. zw) are not confused.
		spr("zw"); pr(datalength(x));
		appdata(x, datafwrite);
	elseif islist(x) then
		spr("zl"); pr(length(x));
		applist(x,datafwrite);
	elseif isstring(x) then
		spr("zs"); pr(datalength(x));
		appdata(x,datafwrite);
	elseif isvector(x) then
		spr("zv"); pr(datalength(x));
		appdata(x,datafwrite);
	elseif isarray(x) then
		arrayvector_bounds(x) -> (, lo);
		pr("za");
		datafwrite(isarray_by_row(x));
		datafwrite(lo - 1);
		datafwrite(boundslist(x));
		datafwrite(arrayvector(x));

		;;; old version
		;;;pr("za"); datafwrite(boundslist(x)); appdata(arrayvector(x),datafwrite);
	elseif isref(x) then
		pr("zr"); datafwrite(cont(x));
	elseif isboolean(x) then
		spr("zb");
		pr(if x then "true" else "false" endif)
	elseif isvectorclass(x) then       ;;; user defined vector
		spr("zu"); spr(dataword(x)); pr(datalength(x)); appdata(x,datafwrite);
	elseif isproperty(x) then
		spr("zh");
		datafwrite(datalist(x));
		datafwrite(property_size(x));
		datafwrite(property_default(x));
		datafwrite(true);       ;;; Can't tell if permanent or not
 	elseif isclosure(x) then
 	    spr("zC"); pr(pdprops(pdpart(x))); pr(' ');
 	    datafwrite(datalist(x))
 	elseif isprocedure(x) then
 	    spr("zP"); pr(pdprops(x));
	else
		spr("zc"); pr(dataword(x)); appdata(x,datafwrite);
	endif
enddefine;

define lconstant datafread -> x;
	lvars x, y, n, b, key, t;
	rditem() -> x;
	if x == "zl" then
		rditem() -> n;
		conslist(repeat n times datafread() endrepeat, n) -> x
;;; old version
;;; 		nil -> x;
;;; 		repeat t times
;;; 			cons(datafread(), x) -> x;
;;; 		endrepeat;
;;; 		rev(x) -> x;
	elseif x == "zp" then
		conspair(datafread(),datafread()) -> x;
	elseif x == "zs" then
		rditem() -> y;
		inits(y) -> x;
		for n from 1 to y do
			datafread() -> fast_subscrs(n,x);
		endfor;
	elseif x == "zv" then
		rditem() -> y;
		initv(y) -> x;
		for n from 1 to y do
			datafread() -> fast_subscrv(n,x);
		endfor;
	elseif x == "za" then
		datafread() -> b;
		if isboolean(b) then
	    	;;; new format - this is the by_row flag,
	    	;;; offset, bounds & arrayvector follow.
	    	datafread() -> n;
	    	newanyarray(datafread(), datafread(), n, b) -> x;
		else
	    	;;; old format - this is the boundslist, data follows
	    	newarray(b) -> x;
	    	arrayvector(x) -> y;
			datalength(y) -> t;
	    	for n from 1 to t do
				datafread() -> fast_subscrv(n, y)
			endfor
	    endif;
;;; old version
;;; 		newarray(datafread()) -> x;
;;; 		datalength(arrayvector(x)) -> t;
;;; 		for n from 1 to t do
;;; 			datafread() -> fast_subscrv(n,arrayvector(x));
;;; 		endfor;
	elseif x == "zr" then
		consref(datafread()) -> x;
	elseif x == "zb" then
		valof(datafread()) -> x;
	elseif x == "zw" then
		rditem() -> n;
		consword(repeat n times datafread() endrepeat, n) -> x;
	elseif x == "zc" then
		;;; get dataword and check for valid key - R. Evans Jan 83
		datafread() -> y;
		key_of_dataword(y) -> key;
		unless key then
			mishap('Unknown dataword encountered in datafile\n' sys_><
				   ';;;          (recordclass declaration not loaded?)', [^y]);
		endunless;
		repeat datalength(key) times datafread() endrepeat;
		apply(class_cons(key)) -> x
	elseif x == "zu" then
		;;; get vectorclass - Aled, June 1st, 1987
		datafread() -> y;
		key_of_dataword(y) -> key;
		unless key then
			mishap('Unknown dataword encountered in datafile\n' sys_><
				   ';;;          (vectorclass declaration not loaded?)', [^y]);
		endunless;
		repeat (datafread() ->> n) times datafread() endrepeat;
		apply(n, class_cons(key)) -> x;
	elseif x == "zh" then
		newproperty(datafread(), datafread(), datafread(), datafread()) -> x
 	elseif x == "zC" then
		;;; deal with closure
		rditem() -> t;
		partapply(valof(t),datafread()) -> x;
 	elseif x == "zP" then
		;;; deal with named procedure
		valof(rditem()) -> x;
	endif;
enddefine;


global vars newdatafile = true;
endsection;


/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep  1 2009
	Merged datafile.p (with Brian Logan's changes) with
	Riccardo Poli's changes.
--- Brian Logan 15 Sep 1997
	Merged V15.5. version of datafile with changes to cope with
	poparray_by_row
--- Riccardo Poli, Nov 13 1995
		Extended to cope with procedures (in part).
--- Riccardo Poli and Aaron Sloman, Nov 12 1995
		Extended to cope with closures (in part).
--- John Williams, Dec 12 1995
		Copes with non- full vector arrays (and arrayvector offsets).
		Can still read arrays in the old format.
--- John Gibson, Oct 10 1992
		Made stuff lexical, added strict etc.
--- John Williams, May  4 1990
		Now uses -property_size- instead of -datalength-
--- John Gibson, Mar 22 1990
		Replaced use of length(class_spec(key)) with datalength(key)
		(only the latter guarantees to give the actual number of fields
		in a record).
--- John Williams, Mar 14 1988
		Fixed to work with ordinary properties
--- Aled Morris, Jun  1 1987
		Fixed to work with user defined vectorclasses
--- Mark Rubinstein, Jan 23 1986
		Fixed saving and restoring of words so that
		words with funny characters are okay.
		General tidying and adding of lvars.
--- Roger Evans, Jan 1983
		Extra check for valid key added to datafread
*/
