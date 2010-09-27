/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/sim/lib/sim_faces.p
 > Purpose:			Five faces used in TEACH SIM_FEELINGS
 > Author:          Aaron Sloman, Mar  2 1999 (see revisions)
 > Documentation:	HELP SIM_FACES also HELP RCLIB
 > Related Files:	TEACH SIM_FEELINGS
 */


section;

/*

-- -- . Face drawing utilities (various expressions)

These are used in demo_show_feeling_ruleset, in TEACH SIM_FEELINGS

;;; Test the drawing commands, defined below.
rc_start();

;;; neutral_face(x, y, face_rad, col, eye, mouth, eyesep, eyecol, mouthcol);

neutral_face(-90, 90, 60, 'red', 15, 24, 50, ,'blue','white');

surprised_face(-90, -90, 60, 'red', 15, 24, 50, 'blue','white');

happy_face(90, 90, 60, 'red', 15, 24, 50, 'blue','white');

glum_face(90, -90, 60, 'red', 15, 24, 50,'blue','white');

frustrated_face(0, 0, 60, 'red', 15, 24, 50,'blue','white');

*/

uses objectclass;
uses rclib;
uses rc_draw_coloured_square;


define :mixin face_pic;
	;;; A mixin for objects with faces

    ;;; Window in which to show the objects's face
    slot face_window = "faces_window";

	;;; The face colour
    slot face_colour;

    ;;; Where to draw facial expression, and what size
    slot face_xloc;
    slot face_yloc;
    slot face_rad = 40;
    slot face_margin = 10;
	
enddefine;

define :method sim_draw_face(thing:face_pic, feeling);
    ;;; The main face-drawing method.
    ;;; Draw a face showing the thing's current feeling
    dlocal
        ;;; suppress other event handlers while doing this
        rc_in_event_handler = true,

        rc_current_window_object = recursive_valof(face_window(thing));

    lvars
        ;;; Get the thing's colour (red or blue, or...)
        colour = face_colour(thing),
        ;;; and other characteristics
        face_x = face_xloc(thing),
        face_y = face_yloc(thing),
        face_size = face_rad(thing),
        eye_rad = round(face_size / 4),
        mouth_rad = round(face_size / 2.5),
        eyesep = face_size * 5/8.0,
        eye_col = 'white',
        mouth_col = 'white',
        framesize = face_size*2+face_margin(thing),
        ;

    ;;; Draw grey background square for face
    rc_draw_coloured_square(face_x, face_y, 'grey85', framesize);

    ;;; Draw the frame
    rc_draw_centred_rect(face_x, face_y, framesize, framesize, colour, 2);

    ;;; Now draw the face according to the feeling
    ;;; It would be possible to add more types of facial expressions,
    ;;; and to make them more convincing!

    ;;; Create name of face procedure from the name of the feeling, then
    ;;; get the corresponding procedure and apply it

    lvars procedure face_proc = valof(consword(feeling >< '_face'));

    face_proc(
        face_x, face_y, face_size, colour, eye_rad, mouth_rad, eyesep,
            eye_col, mouth_col);
enddefine;

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

;;; A procedure to draw a drooping mouth made of three lines
define draw_drooping_mouth(x, y, mouthrad, col);
    ;;; get coordinates of ends of horizontal bit
    lvars
        ;;; left end of horizontal bit
        x1 = x-mouthrad*0.6,  y1 = y - mouthrad,
        ;;; right end of horizontal bit
        x2 = x+mouthrad*0.6, y2 = y - mouthrad,
        ;;; left bit far end
        x3 = x - mouthrad,  y3 = y - mouthrad*1.25,
        ;;; right bit far end
        x4 = x + mouthrad, y4 = y3,
        thick = mouthrad*0.4,
        overlap = thick*0.15;

    ;;; draw mouthrad with one horizontal line and two drooping bits
    ;;; We extend the horizontal bit by overlap at each end.
    rc_drawline_relative(x1-overlap,y1, x2+overlap, y2, col, thick);
    rc_drawline_relative(x1,y1, x3, y3, col, thick);
    rc_drawline_relative(x4,y4, x2, y2, col, thick);
enddefine;


define neutral_face(x, y, face_rad, col, eye, mouthrad, eyesep, eyecol, mouthcol);
    ;;; Draw a face with a horizontal bar for mouthrad. Slightly reduce the mouthrad
    mouthrad*0.85 -> mouthrad;
    face_eyes(x, y, face_rad, col, eye, eyesep, eyecol);
    rc_drawline_relative(x-mouthrad, y - mouthrad, x+mouthrad,y-mouthrad, mouthcol, mouthrad*0.4);
enddefine;

define surprised_face(x, y, face_rad, col, eye, mouthrad, eyesep, eyecol, mouthcol);
    ;;; Face with a circular mouthrad. Slightly reduce the mouthrad size
    mouthrad*0.85 -> mouthrad;
    face_eyes(x, y, face_rad, col, eye, eyesep, eyecol);
    rc_draw_blob(x, y - mouthrad, mouthrad, mouthcol);
enddefine;

;;; Procedures for drawing whole faces.
define happy_face(x, y, face_rad, col, eye, mouthrad, eyesep, eyecol, mouthcol);
    face_eyes(x, y, face_rad, col, eye, eyesep, eyecol);
    draw_mouth(x, y, mouthrad, mouthrad, mouthrad*0.6, col, mouthcol);
enddefine;

define glum_face(x, y, face_rad, col, eye, mouthrad, eyesep, eyecol, mouthcol);
    face_eyes(x, y, face_rad, col, eye, eyesep, eyecol);
    draw_mouth(x, y, mouthrad, mouthrad*1.2, mouthrad*1.5, col, mouthcol);
enddefine;

define frustrated_face(x, y, face_rad, col, eye, mouthrad, eyesep, eyecol, mouthcol);
    ;;; This picture is not used yet. An exercise would be to make the
    ;;; agent show this face if its path is blocked by something very
    ;;; close.

    face_eyes(x, y, face_rad, col, eye, eyesep, eyecol);
    ;;; draw mouth with one horizontal line and two drooping bits
    draw_drooping_mouth(x, y, mouthrad, mouthcol);
enddefine;



global vars sim_faces = true; 	;;; for uses
endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Mar 16 1999
	Added mixin and methods
 */
