/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/happy_face.p
 > Purpose:			Autoloadable Demonstration file
 > Author:          Aaron Sloman, Sep 30 2000
 > Documentation:	TEACH FACES
 > Related Files:	LIB sad_face
 */

compile_mode :pop11 +strict;

section;
uses rc_graphic
uses rclib

;;; A procedure for drawing a face without a mouth
define face_eyes(x, y, face_rad, col, eye, eyesep, eyecol);
    ;;; Draw a face of radius face_rad with eyes of radis eye, distance
    ;;; apart eyesep, using strings col for face colour, eyecol for
    ;;; eyecolour

    ;;; Draw the main circle for the face, centred at (x, y)
    rc_draw_blob(x, y, face_rad, col);
    ;;; draw the left eye, radius eye, color eyecol
    rc_draw_blob(x - eyesep*0.5, y + face_rad/3.0, eye, eyecol);
    ;;; draw the right eye, radius eye, color eyecol
    rc_draw_blob(x + eyesep*0.5, y + face_rad/3.0, eye, eyecol);
enddefine;

;;; A procedure for drawing mouths made of two circles,
;;; for smiles and frouns.
define draw_mouth(x, y, rad, down1, down2, facecol, mouthcol);
    ;;; Draw a mouth using two circles. the second one the
    ;;; colour of the background (facecol), at distances down1
    ;;; down2 from the centre x, y.
    rc_draw_blob(x, y - down1 , rad, mouthcol);
    rc_draw_blob(x, y - down2, rad, facecol);
enddefine;

define happy_face(x, y, face_rad, col, eye, mouthrad, eyesep, eyecol, mouthcol);
    face_eyes(x, y, face_rad, col, eye, eyesep, eyecol);
    draw_mouth(x, y, mouthrad, mouthrad, mouthrad*0.6, col, mouthcol);
enddefine;

endsection;
