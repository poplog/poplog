/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_blob_demo.p
 > Purpose:			Demonstrate pretty moving patterns
 > Author:          Aaron Sloman, Aug 18 1997
 > Documentation:	HELP * RCLIB/rc_draw_blob
 > Related Files:	LIB * RC_WINDOW_OBJECT, * RC_DRAW_BLOB
 */

/*
;;;TESTS

rc_blob_demo(10,10,800,800,500,3000,true);
rc_blob_demo(10,10,800,800,200,3000, false);
rc_blob_demo(10,10,800,800,100,4000, false);

*/


section;
uses rclib
uses rc_window_object;


global vars blobcolours =

  [
  	  'DarkGreen'
  	  'DeepPink'
  	  'LemonChiffon1'
  	  'LightBlue1'
  	  'LightBlue2'
  	  'LightBlue3'
  	  'LightBlue4'
  	  'LightPink'
  	  'LightSlateBlue'
  	  'LightYellow'
  	  'LimeGreen'
  	  'MediumOrchid1'
  	  'MediumOrchid2'
  	  'MediumOrchid3'
  	  'MediumOrchid4'
  	  'PowderBlue'
  	  'aquamarine'
  	  'azure'
  	  'black'
  	  'blue'
  	  'brown'
  	  'chocolate'
  	  'coral'
  	  'cornsilk'
  	  'cyan'
  	  'firebrick'
  	  'gold'
  	  'goldenrod'
  	  'green'
  	  'green1'
  	  'green2'
  	  'green3'
  	  'green4'
  	  'grey30'
  	  'grey5'
  	  'grey70'
  	  'grey95'
  	  'honeydew'
  	  'ivory1'
  	  'ivory2'
  	  'ivory3'
  	  'ivory4'
  	  'khaki'
  	  'linen'
  	  'magenta'
  	  'maroon'
  	  'navy'
  	  'orange'
  	  'orangered'
  	  'orchid'
  	  'palegreen'
  	  'pink'
  	  'purple'
  	  'red'
  	  'salmon1'
  	  'salmon2'
  	  'salmon3'
  	  'salmon4'
  	  'seagreen'
  	  'sienna'
  	  'tomato1'
  	  'tomato2'
  	  'tomato3'
  	  'tomato4'
  	  'turquoise'
  	  'wheat'
  	  'white'
  	  'yellow'
  ];

define rc_blob_demo(x, y, width, height, maxrad, num, new);

	if new then
		rc_new_window_object(x, y, width, height, true, 'BLOBS') -> rc_current_window_object
	endif;

	repeat  num times
		rc_draw_blob(
			width-random(2*width),height-random(2*height), 5+random(maxrad),
			oneof(blobcolours));
		;;;syssleep(1);
	endrepeat;

enddefine;
endsection;
