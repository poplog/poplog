
/* TEACH TOURIST_GUIDE.P                          Mike Sharples Jan 2005
                                            Slightly Modifed by A.Sloman


This is a Pop11 program file and can be compiled, e.g. using
	ENTER l1
in Ved.

Then run the program by giving the command

	converse();

Things you can try are

	where is nelsons column
    where is the theatre
    where is a gallery
    how much is the fare to brixton
    what is the fare to charing cross

You will need to examine the code to work out what else can be
typed in without producing a 'don't know' answer.

Do not expect a seriously usable program: this is a teaching example.

*/


/***********************************************************************

This is a listing of a complete Tourist Guide based on
one programmed by a student. It makes use of the `prodsys' and `semnet'
POP-11 libraries. The program can be called by the command:
converse();

For an example dialogue with the program see the book Computers and Thought
*************************************************************************/

lib semnet;
lib prodsys;

/********************************************************************

   Defines the pretty print arrow =>>

********************************************************************/

define ppr(x);
lvars x;
    if x=nil then
      sp(1)
    elseif ispair(x) then
        applist(x,ppr)
    else
        spr(x)
    endif;
enddefine;

define macro =>> ;
   ".",
   "ppr",
    ";",
   "nl",
   "(",
   1,
   ")",
   ";"
enddefine;

/*****************************************************
   Rule-Based System for Advising on Entertainment
                   - see Chapter 7
******************************************************/


;;; following rules deal with entertainment in London

[] -> rulebase;
false -> chatty;
false -> repeating;

rule find_type [entertainment medium unknown];
    vars enttype;
    [what type of entertainment would you like:
     cinema or theatre?] =>>
    readline() -> enttype;
    remove([entertainment medium unknown]);
    add([entertainment medium ^^enttype]);
endrule;


rule find_style [entertainment style unknown];
    vars styletype;
    [would you like western, drama or horror]=>>
    readline() -> styletype;
    remove([entertainment style unknown]);
    add([entertainment style ^^styletype]);
endrule;


rule cinema_western [entertainment style western]
    [entertainment medium cinema];
    [soldier blue is on this week at the eros.] =>>
endrule;


rule cinema_horror [entertainment style horror]
    [entertainment medium cinema];
    [[the amazing doctor vulture is on this week
      at the classic and abc1.]
     [i was an american vulture in london is on
      this week at abc2.]] =>>
endrule;


rule cinema_drama [entertainment style drama]
    [entertainment medium cinema];
    [[twenty tiny ants is on this week at the carlton.]
     [dog on a shed roof is on until thursday at the rialto.]
     [sharp shooter the prequel
      is on for two weeks at dominion.]]=>>
endrule;


rule theatre_western [entertainment style western]
    [entertainment medium theatre];
    [home on the range is on at the criterion.]=>>
endrule;

rule theatre_horror [entertainment style horror]
    [entertainment medium theatre];
    [[cant slay wont slay is on at the adelphi.]
     [sweaters is on at the piccadilly.]]=>>
endrule;


rule theatre_drama [entertainment style drama]
    [entertainment medium theatre];
    [[world go away is on at the phoenix.]
     [slaving over a hot keyboard is on at the lyric.]]=>>
endrule;

/*****************************************************
    Syntactic and Semantic Analysis of Noun Phrases
                   - see Chapter 5
******************************************************/


define DET(word);
    return(member(word, [a the]))
enddefine;


define PREP(word);
    if member(word, [in containing]) then
        return(word)
    elseif member(word, [near by]) then
        return("near")
    else
        return(false)
    endif;
enddefine;


define NOUN(word);
    if member(word, [[avenue] [street] [road]]) then
        return([road])
    else
        return(member(word, [[gallery] [square] [museum]
                             [theatre] [cinema] [monument]
                             [lake] [park]]))
    endif
enddefine;


define PROPN(list);
    return(member(list, [[the abc1] [the abc2] [the carlton]
                [the odeon] [the rialto] [the dominion]
                [the classic] [the eros] [the haymarket]
                [the criterion] [the phoenix] [the adelphi]
                [the savoy] [the piccadilly] [the lyric]
                [the royal albert hall]
                [the royal opara house]
                [the british museum]
                [the natural history museum]
                [the victoria and albert museum]
                [the science museum] [the tower of london]
                [hms belfast] [the houses of parliament]
                [st pauls cathedral] [westminster abbey]
                [london zoo] [the serpentine]
                [st katherines dock] [the national gallery]
                [nelsons column] [hyde park] [the serpentine]
                [the tate gallery] [shaftesbury avenue]
                [leicester square] [haymarket]
                [piccadilly circus] [coventry street]
                [tottenham court road] [trafalgar square]
                [jermyn street] [the strand] [denman street]
                [kensington gore] [floral street]
                [great russel street] [cromwell road]
                [exhibition road] [millbank] [tower hill]
                [st catherines way] ] ))
enddefine;


define NP(list);
    vars pn d n p np sym1 sym2;
    if list matches [??pn:PROPN] then
        return(pn)
    elseif list matches [?d:DET ??n:NOUN]  then
		;;; create new variable and declare it as global.
        gensym("v") -> sym1;
		ident_declare(sym1, 0, false);
        return([ [ ? ^sym1 isa ^n] ])
    elseif list matches [?d:DET ??n:NOUN ?p:PREP ??np:NP]
      then
		;;; create two new variables and declare them as global.
        gensym("v") -> sym1;
		ident_declare(sym1, 0, false);
        gensym("v") -> sym2;
		ident_declare(sym2, 0, false);

        if np matches [[= ?sym2 isa =] ==] then
            ;;; meaning of noun phrase is list of patterns
            if p = "containing" then
                return([ [? ^sym1 isa ^n]
                         [? ^sym2 in ? ^sym1] ^^np ])
            else
                return([ [? ^sym1 isa ^n]
                         [? ^sym1 ^p ? ^sym2] ^^np ])
            endif
        else
            ;;; meaning of noun phrase is proper name
            return([ [? ^sym1 isa ^n] [? ^sym1 ^p ^np] ])
        endif;
    else
        ;;; unknown noun phrase form
        return(false)
    endif;
enddefine;


define referent(meaning);

    ;;;
    ;;; find the thing referred by meaning structure
    ;;;

    vars sym, vals, x;

    if meaning matches [[= ?sym isa =] ==] then
        ;;; meaning is a list of patterns

        which(sym, meaning) -> vals;

        if vals matches [?x ==] then
            ;;; at least one thing referred to
            return(x)
        else
            ;;; nothing referred to
            return(false)
        endif;
    else
        ;;; meaning is a proper name
        return(meaning);
    endif
enddefine;

/*********************************************
        Finding a Route on the Underground
                - see Chapter 4
**********************************************/

vars verychatty;
false -> verychatty;

/* first set travel and change times */
vars travtime changetime;
2 -> travtime;
3 -> changetime;


define addonefuture(newplace,newtime,comefrom);
    ;;; This records in the database a single pending
    ;;; arrival at a place (where place means
    ;;; a line-station combination as in the database),
    ;;; unless there has already been an
    ;;; arrival at that place.
    ;;; Also protects against inserting the same future event
    ;;; twice, as could happen when looking at
    ;;; line changes due to the fact that the
    ;;; information that a station is on a given line can
    ;;; appear twice in the database.
    ;;; Can also say what it's doing.
    vars futureevent;

    [will arrive ^newplace at ^newtime mins from ^comefrom]
        -> futureevent;

    if not(present([arrived ^newplace at = mins from =]))
    and not(present(futureevent))
    then
        add(futureevent);
        if verychatty then
            [ . . will arrive ^newplace at ^newtime mins] =>>
        endif;
    endif;

enddefine;


define addfuture(event);
    ;;; Given an event, adds the pending events that
    ;;; follow it into the database
    vars place newplace time station line newln;

    ;;; Get breakdown of event
    ;;; Note that the matcher arrow --> could be
    ;;; replaced by MATCHES except that it
    ;;; does not return a TRUE/FALSE value.
    ;;; We know that the event passed to
    ;;; ADDFUTURE will have the right format.
    event --> [arrived ?place at ?time mins from =];
    place --> [?line ??station];

    ;;; First get all the connections on the same line
    foreach [^place connects ?newplace] do
        addonefuture(newplace,time+travtime,place);
    endforeach;

    ;;; This repeats the last bit for patterns
    ;;; the other way round
    foreach [?newplace connects ^place] do
        addonefuture(newplace,time+travtime,place);
    endforeach;

    ;;; Then all the changes to other lines
    foreach [[?newln ^^station] connects =] do
        addonefuture([^newln ^^station],
                     time+changetime,place);
    endforeach;

    ;;; And again for patterns the other way round
    foreach [= connects [?newln ^^station]] do
        addonefuture([^newln ^^station],
                     time+changetime,place);
    endforeach;

enddefine;

define next();
    ;;; This looks at all the future events in the database
    ;;; and finds the one that will happen next - that is,
    ;;; the one with the smallest value of time, and returns
    ;;; a list giving the corresponding actual event.
    vars leasttime place time lastplace event;
    ;;; leasttime has to start bigger than any likely time
    100000 -> leasttime;

    foreach [will arrive ?place at ?time mins
             from ?lastplace] do
        if time < leasttime then
            [arrived ^place at ^time mins from ^lastplace]
                                            -> event;
            time -> leasttime;
        endif;
    endforeach;

    return(event);
enddefine;

define insertnext(event);
    ;;; Takes an event returned by NEXT and inserts it
    ;;; into the database, then removes all pending events
    ;;; which would cause later arrivals at the same station.
    ;;; Can also print out the event.
    vars place;

    ;;; addition
    add(event);

    ;;; removal
    event --> [arrived ?place at = mins from =];
    foreach ([will arrive ^place at = mins from =]) do
        remove(it);
    endforeach;

    if chatty or verychatty then
        event =>>
    endif;

enddefine;


define start(station);
    ;;; This sets up the database ready to start by inserting
    ;;; pending arrivals at the starting station
    vars line;

    foreach [[?line ^^station] connects =] do
            addonefuture([^line ^^station],0,[start]);
    endforeach;

    ;;; This is the same as the first half but
    ;;; for the other sort of patterns
    foreach [= connects [?line ^^station]] do
            addonefuture([^line ^^station],0,[start]);
    endforeach;
enddefine;


define search(startstat,deststat);
    ;;; Inserts information into the database till the "tree"
    ;;; as far as the destination station has grown
    vars nextevent destline;
    start(startstat);

    repeat
        next() -> nextevent;
        insertnext(nextevent);
    quitif (nextevent matches
            [arrived [?destline ^^deststat]
             at = mins from =]);
        addfuture(nextevent);
    endrepeat;

    add([finished at [^destline ^^deststat]]);
enddefine;


define traceroute();
    ;;; Assuming the tree has been grown in the database,
    ;;; and event is the arrival at the destination station,
    ;;; return a list of the stations through which the
    ;;; quickest route passes
    vars place lastplace time ok routelist;

    ;;; ok will always be true
    present([finished at ?place]) -> ok;

    present([arrived ^place at ?time mins from ?lastplace])
                                                    -> ok;
    [[^place at ^time mins]] -> routelist;

    until lastplace = [start] do
        lastplace -> place;
        ;;; the next line is there for its side effects.
        ;;; ok will always be true
        present([arrived ^place at ?time mins from
                 ?lastplace]) -> ok;
        [[^place at ^time mins] ^^routelist] -> routelist;
    enduntil;

    return(routelist);
enddefine;


define checkstat(station);
    ;;; simply checks that a station is present
    ;;; in the database
    return(present([[= ^^station] connects =])
        or present([= connects [= ^^station]]));
enddefine;


define tidyup();
    ;;; this removes any previous route-finding information
    ;;;from the database, in order to clear the way
    ;;; for a new route
    foreach [will arrive = at = mins from =] do
        remove(it);
    endforeach;
    foreach [arrived = at = mins from =] do
        remove(it);
    endforeach;
    foreach [finished at =] do
        remove(it);
    endforeach;
enddefine;


define route(startstat,deststat);
    ;;; this is the overall calling program for route finding
    ;;; this sets up the database for the other routines.

    ;;; checking
    if not(checkstat(startstat)) then
        [start station ^^startstat not found] =>>
        return(false);
    endif;
    if not(checkstat(deststat)) then
        [destination station ^^deststat not found] =>>
        return(false);
    endif;

    ;;; tidy the database in preparation
    tidyup();

    ;;; do the search
    search(startstat,deststat);

    ;;; return the result. Note that the database is left
    ;;; with all the search stuff still in it
    return(traceroute());

enddefine;


define reply(list);

    ;;;
    ;;; Convert a route list into
    ;;; an English description of the form:
    ;;;
    ;;;  travelling by underground, take the ... line to ...
    ;;;       then change and take the ... line to ...
    ;;;       then change and take the ... line to ...
    ;;;                       ...

    vars line, station, line1, response;

    list --> [[[?line ??station] ==] ??list];
    [travelling by underground, take the
        ^line line to] -> response;
    while list matches [[[?line1 ??station] ==] ??list] do
        if line1 /= line then
            [^^response ^^station then change and
             take the ^line1 line to] -> response;
            line1 -> line;
        endif;
    endwhile;
    [^^response ^^station] -> response;
    return(response);
enddefine;

/***************************************************
         Top-Level Procedures of the
            Automated Tourist Guide
****************************************************/


define setup();

    ;;;
    ;;; setup the database of facts about London
    ;;;

    [

;;; cinemas

      [[the abc1] in [shaftesbury avenue]]
      [[the abc1] underground [leicester square]]
      [[the abc1] isa [cinema]]
      [[the abc2] in [shaftesbury avenue]]
      [[the abc2] underground [leicester square]]
      [[the abc2] isa [cinema]]
      [[the carlton] in [haymarket]]
      [[the carlton] underground [piccadilly circus]]
      [[the carlton] isa [cinema]]
      [[the odeon] in [haymarket]]
      [[the odeon] underground [piccadilly circus]]
      [[the odeon] isa [cinema]]
      [[the rialto] in [coventry street]]
      [[the rialto] underground [piccadilly circus]]
      [[the rialto] isa [cinema]]
      [[the dominion] in [tottenham court road]]
      [[the dominion] underground [piccadilly circus]]
      [[the dominion] isa [cinema]]
      [[the classic] in [piccadilly circus]]
      [[the classic] underground [piccadilly circus]]
      [[the classic] isa [cinema]]
      [[the eros] in [piccadilly circus ]]
      [[the eros] underground [piccadilly circus]]
      [[the eros] isa [cinema]]

;;; theatres

      [[the haymarket] in [haymarket]]
      [[the haymarket] underground [piccadilly circus]]
      [[the haymarket] isa [theatre]]
      [[the criterion] in [jermyn street]]
      [[the criterion] underground [piccadilly circus]]
      [[the criterion] isa [theatre]]
      [[the phoenix] in [charing cross road]]
      [[the phoenix] underground [tottenham court road]]
      [[the phoenix] isa [theatre]]
      [[the adelphi] in [the strand]]
      [[the adelphi] underground [charing cross]]
      [[the adelphi] isa [theatre]]
      [[the savoy] in [the strand]]
      [[the savoy] underground [charing cross]]
      [[the savoy] isa [theatre]]
      [[the piccadilly] in [denman street]]
      [[the piccadilly] underground [piccadilly circus]]
      [[the picadilly] isa [theatre]]
      [[the lyric] in [shaftesbury avenue]]
      [[the lyric] underground [piccadilly circus]]
      [[the lyric] isa [theatre]]
      [[the royal albert hall] in [kensington gore]]
      [[the royal albert hall] underground
       [south kensington]]
      [[the royal albert hall] isa [theatre]]
      [[the royal opera house] in [floral street]]
      [[the royal opera house] underground [covent garden]]
      [[the royal opera house] isa [theatre]]

;;; museums

      [[the british museum] in [great russel street]]
      [[the british museum] underground
       [tottenham court road]]
      [[the british museum] isa [museum]]
      [[the natural history museum] in [cromwell road]]
      [[the natural history museum] underground
       [south kensington]]
      [[the natural history museum] isa [museum]]
      [[the victoria and albert museum] in [cromwell road]]
      [[the victoria and albert museum] underground
       [south kensington]]
      [[the victoria and albert museum] isa [museum]]
      [[the science museum] in [exhibition road]]
      [[the science museum] underground [south kensington]]
      [[the science museum] isa [museum]]

;;; galleries

      [[the national gallery] in [trafalgar square]]
      [[the national gallery] underground [charing cross]]
      [[the national gallery] isa [gallery]]
      [[the tate gallery] in [millbank]]
      [[the tate gallery] underground [pimlico]]
      [[the tate gallery] isa [gallery]]

;;; places of interest

      [[the tower of london] near [tower hill]]
      [[the tower of london] underground [tower hill]]
      [[the tower of london] isa [place of interest]]
      [[hms belfast] near [the tower of london]]
      [[hms belfast] underground [london bridge]]
      [[hms belfast] isa [place of interest]]
      [[the houses of parliament] near [parliament square]]
      [[the houses of parliament] underground [westminster]]
      [[the houses of parliament] isa [place of interest]]
      [[st pauls cathedral] in [newgate street]]
      [[st pauls cathedral] underground [st pauls]]
      [[the houses of parliament] isa [place of interest]]
      [[westminster abbey] in [millbank]]
      [[westminster abbey] underground [westminster]]
      [[westminster abbey] isa [place of interest]]
      [[st katharines dock] near [st katharines way]]
      [[st katharines dock] underground [tower hill]]
      [[st katharines dock] isa [place of interest]]
      [[nelsons column] in [trafalgar square]]
      [[nelsons column] underground [charing cross]]
      [[nelsons column] isa [place of interest]]
      [[nelsons column] isa [monument]]
      [[london zoo] in [regents park]]
      [[london zoo] underground [camden town]]
      [[london zoo] isa [place of interest]]
      [[the serpentine] in [hyde park]]
      [[the serpentine] underground [hyde park corner]]
      [[the serpentine] isa [lake]]

;;; roads

      [[shaftesbury avenue] isa [road]]
      [[haymarket] isa [road]]
      [[coventry street] isa [road]]
      [[tottenham court road] isa [road]]
      [[jermyn street] isa [road]]
      [[the strand] isa [road]]
      [[denman street] isa [road]]
      [[kensington gore] isa [road]]
      [[floral street] isa [road]]
      [[great russell street] isa [road]]
      [[cromwell road] isa [road]]
      [[exhibition road] isa [road]]
      [[millbank] isa [road]]
      [[tower hill] isa [road]]
      [[st catherines way] isa [road]]

;;; squares

      [[leicester square] isa [square]]
      [[piccadilly circus] isa [square]]
      [[parliament square] isa [square]]
      [[trafalgar square] isa [square]]

;;; parks

      [[hyde park] isa [park]]
      [[regents park] isa [park]]

;;; underground topology for route finder

    [[JUBILEE charing cross] connects [JUBILEE green park]]
    [[JUBILEE green park] connects [JUBILEE bond street]]
    [[JUBILEE bond street] connects [JUBILEE baker street]]
    [[BAKERLOO embankment] connects [BAKERLOO charing cross]]
    [[BAKERLOO charing cross] connects
     [BAKERLOO piccadilly circus]]
    [[BAKERLOO piccadilly circus] connects
     [BAKERLOO oxford circus]]
    [[CIRCLE embankment] connects [CIRCLE westminster]]
    [[CIRCLE westminster] connects [CIRCLE st jamess park]]
    [[CIRCLE st jamess park] connects [CIRCLE victoria]]
    [[CIRCLE victoria] connects [CIRCLE sloane square]]
    [[CIRCLE sloane square] connects
     [CIRCLE south kensington]]
    [[PICCADILLY south kensington] connects
     [PICCADILLY knightsbridge]]
    [[PICCADILLY knightsbridge] connects
     [PICCADILLY hyde park corner]]
    [[PICCADILLY hyde park corner] connects
     [PICCADILLY green park]]
    [[PICCADILLY green park] connects
     [PICCADILLY piccadilly circus]]
    [[CENTRAL lancaster gate] connects [CENTRAL marble arch]]
    [[CENTRAL marble arch] connects [CENTRAL bond street]]
    [[CENTRAL bond street] connects [CENTRAL oxford circus]]
    [[CENTRAL oxford circus] connects
     [CENTRAL tottenham court road]]
    [[VICTORIA warren street] connects
     [VICTORIA oxford circus]]
    [[VICTORIA oxford circus] connects [VICTORIA green park]]
    [[VICTORIA green park] connects [VICTORIA victoria]]
    [[VICTORIA victoria] connects [VICTORIA pimlico]]
    [[VICTORIA pimlico] connects [VICTORIA vauxhall]]
    [[NORTHERN charing cross] connects
     [NORTHERN leicester square]]
    [[NORTHERN leicester square] connects
     [NORTHERN convent garden]]

;;; fare and zones for fare finder

   [[zone1 station] fare [40 pence]]
   [[zone2 station] fare [60 pence]]
   [[green park] isa [zone1 station]]
   [[picadilly circus] isa [zone1 station]]
   [[shepherds bush] isa [zone2 station]]
   [[goodge street] isa [zone2 station]]
   [[brixton] isa [zone2 station]]

    ] -> database;

enddefine;


define introduction();

    ;;;
    ;;; output welcome and instructions to user
    ;;;

    [Hello, this is the automated London tourist guide]=>>
    [I can offer information on the following]=>>
    [cinema]=>>
    [theatre]=>>
    [museums]=>>
    [galleries]=>>
    [places of interest]=>>
    [routes and fares on the underground]=>>
    [Please ask about any of the above
     and I will try to help you]=>>
    [Type in your question using lowercase letters only]=>>
    [and then press RETURN]=>>
    [If you want to exit please type "bye"
     and press RETURN]=>>

enddefine;


define answer(question);

    ;;;
    ;;; produce a response to question
    ;;;

    vars list, museums, response, x, y, place, routelist;


    if question matches [== places of interest ==] then

        ;;; this is a question about places of interest

        [] -> list;
        foreach [?place isa [place of interest]] do
            [^^list , ^place] -> list;
        endforeach;
        ;;; strip off leading comma from reply
        list --> [, ??list];
        [I know about the following places of interest:
         ^^list] -> response;

    elseif question matches [== where is ??np:NP] or
            question matches [== where ??np:NP is] then

            ;;; a question about where somewhere is

            ;;; find the place referred to by noun-phrase
            referent(np) -> place;

            if place and present([^place in ?y]) then
                [^^place is in ^^y] -> response;
            elseif place and present([^place near ?y]) then
                [^^place is near ^^y] -> response;
            elseif place and present([^place underground ?y])
              then
                [^^place is near ^^y underground station]
                                                -> response;
            else
                [I do not know where that place is]
                                                -> response;
            endif;

    elseif question matches [== get to ??np:NP] then

        ;;; route finding question

        ;;; find place referred to by noun-phrase
        referent(np) -> place;

        if place and present([^place underground ?y]) then
            route([victoria], y) -> routelist;
            if not(routelist) then
                [route not found] -> response
            else
                reply(routelist) -> response
            endif
        else
                [I do not know where that place is]
                                                -> response;
        endif

    elseif question matches [== fare to ??x] then

        ;;; question about fare to a given underground station

        if spresent([^x fare ?y]) then
            [The fare to ^^x is ^^y] -> response
        else
            [I do not know about the underground station ^^x]
                                                -> response
        endif

    elseif question matches [== entertainment ==] or
            question matches [== cinema==] or
            question matches [== theatre==] or
            question matches [== theatres ==] or
            question matches [== cinemas ==] then

            ;;; answer question about entertainment in London
            ;;; using LIB PRODSYS

        ;;; add initial entertainment facts to database

        add([entertainment medium unknown]);
        add([entertainment style unknown]);

        ;;; run production system
        run();

        ;;; remove database entries created by
        ;;; production system
        flush([entertainment ==]);

        [I hope you enjoy the show] -> response;

    elseif question matches [] then

        ;;; blank line input

        [please type in your question and press RETURN]
                                            -> response

    elseif question matches [bye] then

        ;;; produce response to terminate session

        [bye] -> response

    else

        ;;; cannot handle this question

        [Sorry I do not understand. Try rewording
         your question] -> response

    endif;

    return(response);

enddefine;


define converse();

    ;;;
    ;;; main calling procedure
    ;;;

    vars question, response;

    ;;; setup the database of facts about London
    setup();

    ;;; output welcome and instructions to tourist user
    introduction();

    ;;; read and answer queries until done
    repeat

        ;;; read in question from keyboard
        readline() -> question;

        ;;; produce an answer to question
        answer(question) -> response;

        ;;; output answer to user
        response =>>

        ;;; quit if answer indicates end of session
        quitif(response = [bye]);

    endrepeat;
enddefine;


/* --- University of Birmingham 2005 ------
 > File:			$poplocal/local/teach/tourist_guide.p
 > Purpose:			Teaching
 > Author:			Mike Sharples, Jan  1 2005 (see revisions)
 > Documentation:   HELP SEMNET, TEACH PRODSYS,
 > Related Files:	LIB SEMNET, LIB PRODSYS
 */


/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jan  1 2005
	Had to convert lib semnet to work with current versions of pop11,
	Old version still available as
		http://www.cs.bham.ac.uk/research/poplog/lib/semnet_old.p
	Inserted some calls of ident_declare to prevent 'DECLARING VARIABLE'
	warnings.
	
 */

/*
--- $poplocal/local/teach/tourist_guide.p
	http://www.cs.bham.ac.uk/research/poplog/teach/tourist_guide.p
*/
