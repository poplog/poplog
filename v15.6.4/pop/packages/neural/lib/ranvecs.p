/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/neural/lib/ranvecs.p
 > Purpose:         see below
 > Author:          Aaron Sloman, Mar  4 2000 (see revisions)
 > Documentation:
 > Related Files:
 */

/* --- Copyright University of Sussex 1989. All rights reserved. ----------
 > File:            $popneural/lib/ranvecs.p
 > Purpose:         Random number utility
 > Author:          David Young, Mar 28 1989
 > Related Files:   $popneural/src/fortran/ranvecs.f,
					$popneural/bin/<arch>/ranvecs.o,
					$popneural/src/pop/ranvfordef.p
 */

section;

/* Interface to fortran random number generator */

vars ranvecs = true;    ;;; to avoid reloading

uses ranvcdef;

define random_init(i);
    lvars i;
    if i.isinteger then
        randinit(i)
    elseif i then
        mishap('need integer or false',[^i])
    else
        rrandinit(0)
    endif
enddefine;

;;; random_init(false);

;;; Can't be  lconstant since used in mkneural.p
define constant runtime_rand_init();
	random_init(sys_real_time() && 2**24);
enddefine;

;;; sys_runtime_apply(runtime_rand_init);


/* Generators for random-number repeaters */

lconstant ntostore = 100;   ;;; determines freq. of external calls

define constant procedure randigen(i0,i1) /* -> ran_repeater */;
    ;;; Returns a repeater for random integers in the range
    ;;; i0 to i1 inclusive
    lvars i0 i1;
    lvars randihold = array_of_int([1 ^ntostore]);
    lvars index = 0, rani0 = i0, rani1 = i1;
    ;;; Intialisation
    ranivec(randihold,ntostore,i0,i1);

    procedure /* -> ranint */;
        index fi_+ 1 -> index;
        if index fi_> ntostore then
            ranivec(randihold,ntostore,rani0,rani1);
            1 -> index;
        endif;
        randihold(index)
    endprocedure /* -> ran_repeater */
enddefine;

define constant procedure randfgen(i0,i1) /* -> ran_repeater */;
    ;;; Returns a repeater for random floats in the range
    ;;; i0 to i1 inclusive
    lvars i0 i1;
    lvars randfhold = array_of_double([1 ^ntostore]);
    lvars index = 0,
         ranf0 = number_coerce(i0,0.0s0),
         ranf1 = number_coerce(i1,0.0s0);
    ;;; Intialisation
    ranuvec(randfhold,ntostore,ranf0,ranf1);

    procedure /* -> ranflt */;
        index fi_+ 1 -> index;
        if index fi_> ntostore then
            ranuvec(randfhold,ntostore,ranf0,ranf1);
            1 -> index;
        endif;
        randfhold(index)
    endprocedure /* -> ran_repeater */

enddefine;

define constant procedure randggen(m,s) /* -> ran_repeater */;
    ;;; Returns a repeater for random Gaussian floats
    ;;; with mean m and sd s
    lvars m s;
    lvars ranghold = array_of_double([1 ^ntostore]);
    lvars index = 0,
         ranf0 = number_coerce(m,0.0s0),
         ranf1 = number_coerce(s,0.0s0);
    ;;; Intialisation
    rangvec(ranghold,ntostore,ranf0,ranf1);

    procedure /* -> ranflt */;
        index fi_+ 1 -> index;
        if index fi_> ntostore then
            rangvec(ranghold,ntostore,ranf0,ranf1);
            1 -> index;
        endif;
        ranghold(index)
    endprocedure /* -> ran_repeater */

enddefine;

global vars ranvecs = true;    ;;; to avoid reloading

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Mar  4 2000
	replaced lconstant with constant in definition of runtime_rand_init
Julian Clinton, 6/7/93
    Changed array_of_int to initintvec as array_of_int gives incorrect
    results on DECstation with newexternal.
Julian Clinton, 1/7/93
    Changed to use array_of_int (for C) rather than array_of_integer
    (for Fortran).
-- Julian Clinton, 25/8/92
	Made random number initialisation occur at runtime.
*/
