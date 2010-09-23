/*
TEACH RIVER2.P                                 Aaron Sloman, 12 Oct 1996

[Changed to use "!" as pattern prefix]

This is a set of sample procedure definitions suited to the task
described in TEACH RIVER2


You can make your own copy of this file by giving a command something
like:

    ENTER name myriver2.p

after which the file will belong to you and can be written to your own
directory using the name given.

NOTE this file contains only program text with very few comments or
explanations. All the explanatory material is in TEACH RIVER2

Here are the procedures defined below

CONTENTS
 define riv_start();
 define riv_setup(left_things, right_things, boat_things);
 define riv_whereis(thing) -> place;
 define riv_is_at(thing, place) -> boolean;
 define riv_is_in(thing1, thing2) -> boolean;
 define riv_can_eat(thing1, thing2) -> boolean;
 define riv_will_eat(thing1, thing2) -> result;
 define riv_which_at(place) -> list;
 define riv_which_in(thing) -> list;
 define riv_exists(thing) -> boolean;
 define riv_putin(thing) -> result;
 define riv_eat(thing1, thing2) -> result;
 define riv_getin() -> result;
 define riv_getout() -> result;
 define riv_takeout(thing) -> result;
 define riv_cross() -> result;
 define riv_view();


*/

define riv_start();

    ;;; empty the database
    [] -> database;

    ;;; Use "alladd" to add a lot of items at once to the database

    alladd(
     [
        [at boat left]
        [at man left]
        [at fox left]
        [at chicken left]
        [at grain left] ]);

enddefine;

define riv_setup(left_things, right_things, boat_things);

    ;;; first clear the database
    [] -> database;

    ;;; then for each item in the left_things list, put it at the
    ;;; left bank
    lvars item;
    for item in left_things do
        add([at ^item left]);
    endfor;

    ;;; now do the same for the right bank, re-using the variable item
    for item in right_things do
        add([at ^item right]);
    endfor;

    ;;; now put things in the boat
    for item in boat_things do
        add([in ^item boat]);
    endfor;

enddefine;


define riv_whereis(thing) -> place;
    ;;; thing and place are automatically declared as lexical variables.
    ;;; thing represents the input, which should be a word, and the
    ;;; value of place, set by present, below, will be returned as the
    ;;; result of the procedure.

    ;;; declare pattern variable
    lvars place;

    ;;; "^" means "use the value of", "?" means "set the value of"
    if present( ! [at ^thing ?place ] ) then
        ;;; no need to do anything, as the variable place has a value
    else
        "nowhere" -> place
    endif

enddefine;


define riv_is_at(thing, place) -> boolean;
    ;;; This one gives a yes/no answer

    ;;; find the bank containing the thing and compare it with place.
    ;;; assing the result of the comparison to the output local variable
    riv_whereis(thing) == place -> boolean

enddefine;


define riv_is_in(thing1, thing2) -> boolean;
    present([in ^thing1 ^thing2])  -> boolean;
enddefine;


define riv_can_eat(thing1, thing2) -> boolean;
    (thing1 == "fox" and thing2 == "chicken")
    or
    (thing1 == "chicken" and thing2 == "grain")  -> boolean;
enddefine;


define riv_will_eat(thing1, thing2) -> result;
	;;; check if conditions are right for thing1 to eat thing2.

    lvars place;    ;;; pattern variable

    ;;; check all the conditions
    ;;; first make sure thing1 can eat thing2
    if not( riv_can_eat(thing1, thing2) ) then
        [^thing1 cannot eat ^thing2] -> result
        ;;; they are of the right types, so check the location
        ;;; conditions

    ;;; They are of the right types, so check the location conditions,
    ;;; i.e. find if thing1 is on a bank and set the value of place
    elseif not( present( ! [at ^thing1 ?place]) ) then
        [^thing1 not on a bank] -> result;

    ;;; use the value of place and check location of thing2
    elseif not( present([at ^thing2 ^place]) ) then
        [^thing1 and ^thing2 not at same place] -> result

    ;;; make sure man isn't there
    elseif present( [at man ^place] )  then
        [man guarding ^thing2] -> result
    else
        ;;; all preconditions satisfied, so thing1 will eat thing2
        "ok" -> result
    endif

enddefine;


define riv_which_at(place) -> list;
    ;;; Make a list of everything that is at place

    lvars item;

    [%foreach ! [at ?item ^place] do item endforeach%] -> list

enddefine;



define riv_which_in(thing) -> list;
	;;; return a list of things in the boat

	lvars item;
    [%foreach ! [in ?item boat] do item endforeach%] -> list

enddefine;



define riv_exists(thing) -> boolean;

    ;;; see if there is some assertion about the object
    present([ == ^thing ==]) -> boolean

enddefine;


define riv_putin(thing) -> result;
    ;;; put the thing into the boat, after checking

    ;;; declare pattern variable
	lvars place;

    ;;; make sure the thing exists
    if not( riv_exists(thing) ) then
        [^thing does not exist] -> result

    elseif thing == "man" then
        [man cannot put himself in boat] -> result

    ;;; Now check nothing else is in the boat. "=" matches any item.
    elseif present([in = boat]) then
        it -> result

    ;;; now check that man and thing are on the same bank
    elseif not( allpresent( ! [[at man ?place] [at ^thing ?place]]) ) then
        [man and ^thing not on same bank] -> result;
    else
        ;;; preconditions all satisfied, now manage the effects
        remove([at ^thing ^place]);
        ;;; You should complete the next line
        add([in ^thing boat]);
        "ok" -> result;
    endif
enddefine;


define riv_eat(thing1, thing2) -> result;

    riv_will_eat(thing1, thing2) -> result;

    if result == "ok" then
        remove([at ^thing2 =]);
    endif
enddefine;



define riv_getin() -> result;
	;;; put the man in the boat, and do suitable checks
	;;; if eating occurs, put the information into result

	lvars place;
    ;;; check that the man is at some bank
    if present( ! [at man ?place]) then
        ;;; get man off whichever bank he's on
        remove(it);     ;;; remove the item found

        ;;; and into the boat
        add([in man boat]);
        "ok" -> result;

        if riv_eat("fox", "chicken") == "ok" then
            [fox has eaten the chicken] =>
        elseif riv_eat("chicken", "grain") == "ok" then
            [chicken has eaten the grain] =>
        endif

    else
        [man not on the bank] -> result;
    endif
enddefine;

define riv_getout() -> result;
    /*
    ... check that man is in the boat, and if not
    ... assign [man not in boat] to result
    ... otherwise
    ...     remove the assertion that the man is in the boat
    ...     lookup( ! [at boat ?place])
    ...     add([ ... ])
    ...     set the result "ok"
    */
	lvars place;

    if not( present([in man boat]) ) then
        [man not in boat] -> result
    else
        ;;; found [in man boat]
        remove(it);     ;;; "it" is what present found
        lookup(! [at boat ?place]);
        add([at man ^place]);
        "ok" -> result;
    endif
enddefine;


define riv_takeout(thing) -> result;
	;;; take thing out if possible.

	lvars place;

    ;;; make sure the thing exists
    if not( riv_exists(thing) ) then
        [^thing does not exist] -> result

    ;;; now Check that the man is not in the boat
    ;;; This check is redundandant, given the next one. Why?
    elseif present([in man boat]) then
        it -> result

    ;;; Check that the thing is in the boat
    elseif not( present([in ^thing boat]) ) then
        [^thing not in the boat] -> result

    else
        ;;; Preconditions all satisfied, now manage the effects
        ;;; We don't need to check that the man is at the same bank as
        ;;; the boat, if our procedures don't allow the boat to move
        ;;; without the man. Otherwise a check would be needed.

        ;;; Find which bank the man is on
        lookup( ! [at man ?place ] );

        remove([in ^thing boat]);
        add([at ^thing ^place]);
        "ok" -> result;
    endif
enddefine;

/*
;;;; Some tests
    riv_start();
    riv_getin() =>
    riv_takeout("chicken") =>
    riv_takeout("fox") =>
    riv_getout() =>
    riv_takeout("fox") =>
    riv_putin("fox") =>
    riv_getin() =>
    database ==>
    riv_takeout("fox") =>
    riv_getout() =>
    riv_takeout("fox") =>
    database ==>

*/

define riv_cross() -> result;
	;;; move boat, an contents to opposite bank.

	lvars place;

    if present([in man boat]) then
        remove(! [at boat ?place]);
        if place == "left" then "right" else "left" endif -> place;
        add([at boat ^place]);
        "ok" -> result;
    else
        [man not in boat] -> result;
    endif;

enddefine;

/*
    riv_start();
    riv_cross() =>
    riv_getin() =>
    database ==>
    riv_cross() =>
    database ==>
    riv_cross() =>
    riv_getout() =>
    database ==>
    riv_putin("fox") =>
    riv_getin() =>
    database ==>
    riv_cross() =>
*/

define riv_view();
    ;;; Obscure procedure used to print picture of scene.
    lvars
        lefts  = riv_which_at("left"),
        inboat = riv_which_in("boat"),
        rights = riv_which_at("right"),
        boatleft = present([at boat left]),
        water = "_________________",
        ;;; Now make a picture of the boat and its load, plus water
        water_picture =
            if boatleft then
                [ \_ ^^inboat  _/  ^water ]
            else
                [ ^water \_ ^^inboat _/ ]
            endif;

    ;;; Make sure the word "boat" is not included in the lefts or rights
    ;;; lists

    delete("boat", lefts) -> lefts;

    delete("boat", rights) -> rights;

    ;;; Now make a picture of the whole scene, and print it out.

    [   ^^lefts ---\ ^^water_picture /--- ^^rights ] =>
enddefine;


/*
;;; tests for riv_view
    riv_start();
    riv_view();
    riv_getin() =>
    riv_view();
    riv_cross() =>
    riv_view();
    riv_cross() =>
    riv_getout() =>
    riv_view();
    riv_putin("fox") =>
    riv_getin() =>
    riv_view();
    riv_cross() =>
    riv_view();
*/



/*
--- $poplocal/local/teach/river2.p
--- Copyright University of Birmingham 1996. All rights reserved. ------
*/
