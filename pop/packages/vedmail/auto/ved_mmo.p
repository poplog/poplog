;;; $poplocal/local/auto/ved_mmo.p

;;; LIB VED_MMO
;;; Move current Message Out to end of another file.         A.Sloman Nov 1985

;;; If no argument, then to next file in ved buffer, otherwise to end
;;; of named file.
;;; (For use with mail files)

section;

define ved_mmo;
	dlocal vvedsrchstring vvedsrchsize;
	vedmarkpush();					;;; save current marked range

	ved_mcm();						;;; mark current message

									;;; Now get to other file
	if vedargument = vednullstring then
		vedswapfiles()
	else ved_ved()
	endif;

	vedendfile();					;;; go to end
	vedswapfiles();					;;; go back to first file
	ved_mo();						;;; move marked range out
	vedmarkpop();					;;; restore old marked range
									;;; make sure text in ved window
	if vedline > vvedbuffersize then
		vedjumpto(max(1,vvedbuffersize - vedwindowlength + 1), 1)
	else
		vedlocate('@?')
	endif;
enddefine;

endsection;
