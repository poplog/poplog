/* --- Copyright University of Sussex 2009. All rights reserved. ----------
	--- Copyright University of Sussex 1999. All rights reserved. ----------
 > File:            $popvision/lib/Xcolour_to_rgb.p
 > Purpose:         Get r, g, b components of X colour specifications
 > Author:          David S Young, Feb 20 1994 (see revisions)
 > Documentation:   HELP * Xcolour_to_rgb
 > Related Files:   rgb.txt
 */

compile_mode:pop11 +strict;

section;

vars Xcolour_to_rgb_filelist = [
	'/usr/share/X11/rgb.txt'
    '/usr/lib/X11/rgb.txt'
    '$Xroot/lib/X11/rgb.txt'
    '/usr/openwin/lib/rgb.txt'
    '$OPENWINHOME/lib/rgb.txt'];

lvars colour_prop = false;      ;;; Initialise on first call

define lconstant rgb_file -> dev;
    lvars filename, dev = false;
    for filename in Xcolour_to_rgb_filelist do
    quitif (readable(filename) ->> dev)
    endfor;
    unless dev then
        mishap(0, 'Unable to open colour database text file')
    endunless
enddefine;

define lconstant readcolours -> prop;
    lvars prop = newproperty([], 500, false, "perm");
    dlocal popnewline = true;
    lconstant spaceword = consword(' ');
    lvars r, g, b, w, w1,
        rdin = incharitem(discin(rgb_file()));
    until (rdin() ->> r) == termin do
        if r == "!" then            ;;; ignore comments
            until rdin() == newline do enduntil
        else
            rdin() -> g;
            rdin() -> b;
            rdin() -> w;
            until (rdin() ->> w1) == newline do
                if w1.isword then
                    w <> spaceword <> w1
                else
                    consword(w >< spaceword >< w1)
                endif -> w
            enduntil;
            {% r, g, b %} -> prop(w)
        endif
    enduntil
enddefine;

define lconstant hxnum(char) -> num;
    lvars char, num = false;
    if char.isnumbercode then
        char - `0` -> num
    elseif char.isalphacode then
        10 + lowertoupper(char) - `A` -> num
    endif;
    checkinteger(num, 0, 15)
enddefine;

define lconstant parsergbstring(str) -> (r, g, b);
    lvars str, r, g, b;
    lvars
        len = length(str),
        nc = (len - 1) div 3;       ;;; characters per number
    unless nc * 3 + 1 == len then
        mishap(str, 1, 'Unequal numbers of characters for colours')
    endunless;

    ;;; As only 2 chars per number matter, might as well just write
    ;;; out the whole calculation
    if nc == 1 then
        16 * hxnum(str(2)) -> r;
        16 * hxnum(str(3)) -> g;
        16 * hxnum(str(4)) -> b;
    else
        16 * hxnum(str(2)) + hxnum(str(3)) -> r;
        16 * hxnum(str(2+nc)) + hxnum(str(3+nc)) -> g;
        16 * hxnum(str(2+nc+nc)) + hxnum(str(3+nc+nc)) -> b;
    endif
enddefine;

define Xcolour_to_rgb(colname) /* -> (r, g, b) */;
    lvars colname, r, g, b;
    if colname.isvector and length(colname) == 3 then
        ;;; Just return components
        explode(colname)
    elseif colname(1) == `#` then
        parsergbstring(colname)
    else
        unless colour_prop then
            readcolours() -> colour_prop
        endunless;
        if colname.isstring then
            consword(colname) -> colname
        endif;
        if dup(colour_prop(colname)) then
            explode()
        else
            false, false
        endif
    endif
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, 20 Feb 2009
		Added '/usr/share/X11/rgb.txt' to
		Xcolour_to_rgb_*filelist
--- David Young, Sep 24 1999
        Added Anthony Worrall's modification for iris to readcolours
        (looks like it allows space-separated numbers in colour names)
--- David S Young, Sep 19 1995
        Ability to ignore comments starting ! added to readcolours
 */
