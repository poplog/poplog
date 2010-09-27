/*  --- Copyright University of Sussex 1988.  All rights reserved. ---------
 >  File:           C.all/lib/lib/river.p
 >  Purpose:        A model of the river problem world
 >  Author:         Max Clowes (originally) and Aaron Sloman (see revisions)
 >  Documentation:  TEACH * RIVER, TEACH * RIVER2
 >  Related Files:
 */

#_TERMIN_IF DEF POPC_COMPILING

compile_mode :pop11 +oldvar;

uses database;

vars show_style="view";		;;; can also be false, or "database"

vars showstate;		;;; defined below

define start();
;;; A procedure to initialize the world
	[[boat isat left]
	 [chicken isat left]
	 [fox isat left]
	 [grain isat left]
	 [man isat left]
	] -> database;
	showstate();
enddefine;

define goalstate() -> result;
	vars count = 0;
	foreach [== isat right] do
		count + 1 -> count;
	endforeach;
	if count == 5 then
		true -> result;
	else
		false -> result
	endif;
enddefine;

;;; four variables referring to entities in the world
vars man, fox, chicken, grain, boat;

"man" -> man;
"fox" -> fox;
"chicken" -> chicken;
"grain"-> grain;
"boat" -> boat;

;;; ****    Utility procedures  ***

define opposite(here)->there;
	if  here = "left" then
		"right" -> there
	else
		"left" -> there
	endif
enddefine;

define boatempty();
	not(present([== isat boat]))
enddefine;

define absent(item);
	not(present([^item isat ==]))
enddefine;

define sameplace(item1,item2);
	vars place;
	present([^item1 isat ?place]) and present([^item2 isat ^place])
enddefine;

define river_mishap(string,list);
	vars cucharerr=cucharout;
	sysprmishap(string,list);
	showstate();
	interrupt();
enddefine;

define eat(item1,item2);
;;; dispose of edible, unattended item
	vars place;
	remove([^item2 isat ?place]);
	river_mishap('DISASTER',[^item1 has eaten ^item2 TOO BAD])
enddefine;


define checkeat();
;;; check if last move was safe
	if  sameplace(chicken,grain) then
		eat(chicken,grain)
	elseif  sameplace(fox,chicken) then
		eat(fox,chicken)
	endif
enddefine;

;;; Now the procedures which perform the actions

define crossriver();
	vars place newplace;
	if  present([man isat boat]) then
		lookup([boat isat ?place]);
		opposite(place) -> newplace;
		remove([boat isat ^place]);
		add([boat isat ^newplace]);
		showstate();
	else
		river_mishap('BOAT NOT SELF PROPELLING: MAN NOT IN BOAT', [])
	endif
enddefine;

define putin(item);
	vars place;
	if  item = man then
		river_mishap('USING PUTIN WITH MAN -- PLEASE USE GETIN();', [])
	elseif  absent(item) then
		river_mishap('USING PUTIN WITH NON-EXISTENT ITEM', [^item]);
	elseif  not(sameplace(boat,item)) then
		river_mishap('BOAT NOT IN RIGHT PLACE', [ putin ^item]);
	elseif  present([man isat boat]) then
		river_mishap('MAN IN BOAT, UNSAFE TO LOAD', [putin ^item]);
	elseif  not(boatempty()) then
		river_mishap('SOMETHING ALREADY IN BOAT',[]);
	elseif  not(sameplace(man,item)) then
		river_mishap('MAN NOT ON CORRECT BANK', [putin ^item]);
	else
		lookup([^item isat ?place]);
		remove([^item isat ^place]);
		add([^item isat boat]);
		showstate();
	endif
enddefine;

define getin();
	vars place;
	if  present([man isat boat]) then
		river_mishap('MAN ALREADY IN BOAT',[])
	else
		remove([man isat ?place]);
		add([man isat boat]);
		showstate();
	endif;
	checkeat();
enddefine;

define getout();
	vars place;
	if  not(present([man isat boat])) then
		river_mishap('MAN ALREADY OUT OF BOAT',[])
	else
		remove([man isat boat]);
		lookup([boat isat ?place]);
		add([man isat ^place]);
		showstate();
	endif;
enddefine;

define takeout(item);
	vars item place;
	if  absent(item) then
		river_mishap('CANNOT TAKE OUT NON-EXISTENT ITEM', [takeout ^item])
	elseif  not(present([^item isat boat])) then
		river_mishap('ITEM NOT IN BOAT NOW', [takeout ^item])
	elseif  present([man isat boat]) then
		river_mishap('MAN IN BOAT! UNSAFE TO UNLOAD', [takeout ^item])
	else
		lookup([boat isat ?place]);
		remove([^item isat boat]);
		add([^item isat ^place]);
		showstate();
	endif
enddefine;


;;; ***Procedures to display the state of the world***

define transportable(thing);
	member(thing,[man fox chicken grain])
enddefine;


define view();
	;;; Obscure procedure used to print picture of scene
	vars item;
	[%
		 foreach [?item:transportable isat left] do
			   item
		 endforeach,
		 "---\",
		 if present([boat isat left]) then
			 "\_",
			 foreach [?item isat boat] do
				 item
			 endforeach,
			 "_/"
		 endif,
		 "_________________",
		 if present([boat isat right]) then
			 "\_",
			 foreach [?item isat boat] do
				 item
			 endforeach,
			 "_/"
		 endif,
		 "/---",
		 foreach [?item:transportable isat right] do
			   item
		 endforeach,
	 %] =>
enddefine;

define showstate;
	if show_style then
		'Here is the state of the river-world:' =>
	endif;
	if show_style = "view" then
		view()
	elseif show_style = "database" then
		database ==>
	else
		;;; nothing
	endif;
	if show_style and goalstate() then
		[WELL DONE -- YOU HAVE SOLVED THE PROBLEM !] =>
	endif;
enddefine;

;;; A procedure to print out instructions

define intro();
pr(
'You are a farmer crossing a river on the way to market\
with a chicken, a bag of grain and a fox. If left unattended the\
fox will eat the chicken, and the chicken will eat the grain.\
Your boat will only hold you and one of these marketablesat a time.\
Your task is to work out a sequence of crossings that will effect\
a safe transfer of you and all your things across the river.\
The sequence must be expressed in terms of these commands:\
getin();\
	-- to climb into the boat\
getout();\
	-- to climb out of the boat\
crossriver();\
	--to paddle the boat across\
putin(item);\
	--to load an item  i.e the fox, chicken or grain.\
takeout(item);\
	--the opposite of putin();\
start();\
	--sets up (or resets) the river scene.\
database ==>\
	-- prints out the current world model.\
view();\
	-- shows you the current situation, pictorially.\
If you make an illegal move a "MISHAP" message will appear!\n')
enddefine;

start();
pr('Please type\n\tintro();\n');

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Nov 14 1988
	Altered to make it congratulate you if you succeed.
--- Aaron Sloman, Sep 13 1988
	Minor improvements
--- Aaron Sloman, Sep 13 1988
	Cleaned up and generally revised.
 */
