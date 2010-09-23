/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/sad_face.p
 > Purpose:			Draw a sad face, demo program
 > Author:          Aaron Sloman, Sep 30 2000
 > Documentation:   TEACH FACES
 > Related Files:	LIB happy_face
 */

compile_mode :pop11 +strict;

uses rclib
uses rc_graphic

uses happy_face;

section;

define sad_face(x, y, face_rad, col, eye, mouthrad, eyesep, eyecol, mouthcol);
    face_eyes(x, y, face_rad, col, eye, eyesep, eyecol);
    draw_mouth(x, y, mouthrad, mouthrad*1.2, mouthrad*1.5, col, mouthcol);
enddefine;

endsection;
