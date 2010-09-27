/*  --- Copyright Integral Solutions Ltd. 1992. All Rights Reserved --------
 > File:            $popneural/bin/mkneural.p
 > Purpose:         sets up load of Poplog-Neural
 > Author:          Julian Clinton, July 1992
 > Documentation:
 > Related Files:
 */

uses sysdefs;

define lconstant build_neural();
dlocal interrupt popgctrace;

    define dlocal prwarning(v);
    lvars v;
        printf(popfilename, poplinenum, v,
               ';;; DECLARING VARIABLE %p (line %p, file %p)\n');
    enddefine;

    define lconstant build_error();
        false -> pop_exit_ok;
        sysexit();
    enddefine;

    build_error -> interrupt;

    ;;; Find out how much memory we have
    true -> popgctrace;
    sysgarbage();
    max(popmemused + 1500000, popmemlim) -> popmemlim;
    loadlib("popneural");
enddefine;

;;; flags for different operating systems
compile('$popneural/src/pop/nn_init.p');

#_IF not(DEF XNEURAL)
global vars XNEURAL = (systranslate('NEURAL_X_REQUEST') = 'yes');
#_ENDIF

#_IF not(DEF PWMNEURAL)
global vars PWMNEURAL =
                        #_IF DEF SUN
                            (systranslate('NEURAL_PWM_REQUEST') = 'yes')
                        #_ELSE
                            false
                        #_ENDIF
                        ;
#_ENDIF

global vars GFXNEURAL = XNEURAL or PWMNEURAL;

build_neural();
sys_runtime_apply(runtime_rand_init);

/*  --- Revision History --------------------------------------------------
-- Julian Clinton, 26/08/95
    Modified declaring variable message.
-- Julian Clinton, 27/04/93
    Re-wrote so errors affect exit status.
*/
