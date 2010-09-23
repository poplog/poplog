/*  --- Copyright University of Sussex 1987.  All rights reserved. ---------
 >  File:           C.all/lib/lib/evpics.p
 >  Purpose:        data for evans analogy problem
 >  Author:         Jon Cunningham 1983 (see revisions)
 >  Documentation:  HELP * ANALOGY, TEACH * EVANS
 >  Related Files:  LIB * ANALOGY
 */

#_TERMIN_IF DEF POPC_COMPILING

define square(n);
	repeat 4 times draw(n-1); turn(90) endrepeat
enddefine;

define triangle(n);
	drawby(2*n-2,0);
	drawby(1-n,n-1);
	drawby(1-n,1-n)
enddefine;

define dot();
	square(2)
enddefine;

define pic1();
	newpicture(25,10);
	jumpto(5,2);
	triangle(5);
	jumpto(16,4);
	dot();
	jumpto(1,1)
enddefine;

define pic2();
	newpicture(25,10);
	jumpto(5,4);
	dot();
	jumpto(11,2);
	triangle(5);
	jumpto(1,1)
enddefine;

define fourpic();
	newpicture(20,15);
	jumpto(3,2);
	square(9);
	jumpto(5,7);
	triangle(7);
	jumpto(1,1)
enddefine;

define pic3();
	newpicture(20,10);
	jumpto(2,2);
	square(7);
	jumpto(12,5);
	dot();
	jumpto(1,1)
enddefine;

define pic4();
	newpicture(25,10);
	jumpto(5,4);
	dot();
	jumpto(11,2);
	square(7);
	jumpto(1,1)
enddefine;

define pic5();
	newpicture(11,11);
	jumpto(2,2);
	square(9);
	jumpto(5,5);
	dot();
	jumpto(1,1)
enddefine;

define dopic(x,y,pic);
	newpicture(x,y);
	pic();
	jumpto(1,1)
enddefine;

define pica();
	jumpto(2,2);
	square(8);
	jumpto(4,4);
	square(4);
	jumpto(14,2);
	triangle(4)
enddefine;

dopic(%20,10,pica%) -> pica;

define picb();
	jumpto(4,4);
	square(4);
	jumpto(14,2);
	triangle(4)
enddefine;

dopic(%20,10,picb%) -> picb;

define picc();
	jumpto(1,4);
	triangle(9);
	jumpto(6,6);
	triangle(4);
	jumpto(19,6);
	square(5)
enddefine;

dopic(%30,15,picc%) -> picc;

pr('Loaded picture procedures: pic1,pic2,pic3,pic4,pic5,pica,picb,picc,fourpic\n');

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jan 24 1987 put in public area because referred to in
	lib analogy
*/
