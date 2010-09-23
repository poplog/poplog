/* --- Copyright University of Birmingham 1998. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_clock.p
 > File:           $poplocal/local/auto/ved_clock.p
 > Purpose:        A status-line clock for VED
 > Author:         Roger Evans, July 1983 (see revisions)
 > Documentation:  See below
  --- Copyright University of Sussex 1987.  All rights reserved. ---------
 */

/*
    This library provides two ved commands ENTER CLOCK and ENTER SECS.
    ENTER CLOCK switches the clock on and off alternately, while ENTER SECS
    switches between displaying or not displaying seconds.

    ENTER ALARM allows you to set a time for an alarm to go off. eg
        <enter> alarm 12:02
    NB: alarm string must match time string exactly for alarm to ring.

    The clock appears on the status line on the right hand side

    Note: if you go out of VED the clock is stopped - you may get a
          double prompt from POP11 (ignore it)

    Do
        uses ved_clock
        $-clock$-startclock -> vedinitfile;

    in your VEDINIT.P to get clock on whenever you are in ved
*/

section $-clock => ved_clock ved_secs ved_alarm;

constant
    clockinterval  =  1,      ;;; value of pop_timeout_secs
    ;

vars
    alarmstring   =  false,    ;;; no alarm initially
    clockon       =  false,    ;;; clock off initially
    clocksecs     =  60,       ;;; clock tick rate (secs)
    lasttime      =  false,    ;;; last value of SYS_REAL_TIME DIV CLOCKSECS
    lastoffset    =  false,    ;;; last value of VEDSCREENOFFSET
    ;


/* Alarm handling */

define global ved_alarm;
    unless vedargument = vednullstring do
        vedargument -> alarmstring
    endunless;
    if alarmstring then
        'ALARM is: ' sys_>< alarmstring
    else
        'no alarm set'
    endif -> vedmessage
enddefine;

define alarm;
    repeat 3 times
        vedputmessage('ALARM');
        vedscreenbell();
        syssleep(10);
        vedputmessage('')
    endrepeat;
    vedsetcursor();
    sysflush(popdevraw)
enddefine;


/* check the time - update if it's changed */

vars procedure stopclock;

define CLOCKCHECK;
    lvars time;

    /* Don't update if
        (a) clock turned off
        (b) vedediting is set false
        (c) input is waiting
    */
    unless clockon then
        return
    endunless;
    unless vedediting then
        stopclock();
        return
    endunless;
    if ispair(ved_char_in_stream) or sys_inputon_terminal(popdevraw) then
        return
    endif
    ;
    sys_real_time() div clocksecs -> time;
    if (time /== lasttime) or (vedscreenoffset /== lastoffset) then
        time -> lasttime;
        vedscreenoffset -> lastoffset;
        ;;; send new clock string
        substring(12, if clocksecs == 60 then 5 else 8 endif, sysdaytime())
            -> time;
        vedscreenxy(vedscreenwidth - 10, vedscreenoffset + 1);
        if clocksecs == 60 then
            vedscreenoutput(vedscreencursor);
            vedscreenoutput(vedscreencursor);
            vedscreenoutput(vedscreencursor)
        endif;
        vedscreenoutput(vedscreencursor);
        appdata(time, vedscreenoutput);
        vedscreenoutput(vedscreencursor);
        vedscreenoutput(vedscreencursor);
        ;;; reset cursor
        1000 -> vedscreenline;
        vedsetcursor();
        sysflush(popdevraw)
    endif;
    if alarmstring and alarmstring = time then
        alarm();
        false -> alarmstring
    endif
enddefine;


/* this procedure gets put in vedprocesstrap - check clock every time
   a character is processed */

define CLOCK(vedprocesstrap);
    dlocal vedprocesstrap;
    CLOCKCHECK();
    vedprocesstrap(); /* run old vedprocesstrap */
enddefine;

define stopclock;
    if clockon then
        if pdpart(vedprocesstrap) == CLOCK then
            frozval(1, vedprocesstrap) -> vedprocesstrap
        endif;
        identfn -> pop_timeout;
        false -> pop_timeout_secs;
        false -> clockon;
		vedrefreshstatus();
    endif;
    /* force clock to refresh next time */
    false ->> lasttime -> lastoffset
enddefine;

/* setting vedprocesstrap isn't enough - set pop_timeout too to cope with
   long waits at the keyboard */

define startclock;
    unless clockon do
        CLOCK(% vedprocesstrap %) -> vedprocesstrap;
        CLOCKCHECK -> pop_timeout;
        clockinterval -> pop_timeout_secs;
        true -> clockon
    endunless;
    /* force clock to refresh next time */
    false ->> lasttime -> lastoffset
enddefine;

define global ved_clock;
    if clockon then
        stopclock();
        'CLOCK OFF'
    else
        startclock();
        'CLOCK ON'
    endif -> vedmessage
enddefine;


/* SECS just alters parameters detailed above */

define global ved_secs;
    if clocksecs == 60 then
        'SECS ON',  1
    else
        'SECS OFF', 60
    endif -> clocksecs -> vedmessage;
    /* force clock to refresh next time */
    false ->> lasttime -> lastoffset
enddefine;


endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul  3 1998
	Inserted vedrefreshstatus in stopclock
 */
