/* --- Copyright University of Sussex 2009. All rights reserved. ----------
 > File:            $popvision/lib/sunrasterfile.p
 > File:            $poplocal/local/popvision/lib/sunrasterfile.p
 > Purpose:         Read and write Sun rasterfiles
 > Author:          David S Young, Dec 13 1993 (see revisions)
 > Documentation:   HELP *SUNRASTERFILE, MAN *RASTERFILE
 */

compile_mode:pop11 +strict;

section;

uses oldarray


/* Rasterfile constants from /usr/include/rasterfile.h */

defclass lconstant rasterfile {
    >-> ras_magic       :uint,       /* magic number */
        ras_width       :uint,       /* width (pixels) of image */
        ras_height      :uint,       /* height (pixels) of image */
        ras_depth       :uint,       /* depth (1, 8, or 24 bits) of pixel */
        ras_length      :uint,       /* length (bytes) of image */
        ras_type        :uint,       /* type of file; see RT_* below */
        ras_maptype     :uint,       /* type of colormap; see RMT_* below */
        ras_maplength   :uint        /* length (bytes) of following map */
    /* color map follows for ras_maplength bytes, followed by image */
};

lconstant
    RAS_MAGIC       =   16:59A66A95,

    /* Sun supported ras_types */
    RT_OLD          =   0,  /* Raw pixrect image in 68000 byte order */
    RT_STANDARD     =   1,  /* Raw pixrect image in 68000 byte order */
    RT_BYTE_ENCODED =   2,  /* Run-length compression of bytes */
    RT_FORMAT_RGB   =   3,  /* XRGB or RGB instead of XBGR or BGR */
    RT_FORMAT_TIFF  =   4,  /* tiff <-> standard rasterfile */
    RT_FORMAT_IFF   =   5,  /* iff (TAAC format) <-> standard rasterfile */
    RT_EXPERIMENTAL =   16:FFFF,    /* Reserved for testing */

    /* Sun registered ras_maptypes */
    RMT_RAW         =   2,
    /* Sun supported ras_maptypes */
    RMT_NONE        =   0,  /* ras_maplength is expected to be 0 */
    RMT_EQUAL_RGB   =   1,  /* red[ras_maplength/3],green[],blue[] */

    /* Rows get rounded out to a multiple of this (unless depth is 24) */
    RAS_ROUNDROW    =   16;

/* A constant record is sufficient for the header */

lconstant
    rasheader = consrasterfile(0, 0, 0, 0, 0, 0, 0, 0),
    (, bits_per_int) = field_spec_info("int"),
    (, bits_per_byte) = field_spec_info("byte"),
    rasheadbytes = length(rasheader) * bits_per_int div bits_per_byte;

;;; Keys for vectors to hold image data - all sizes must
;;; be multiples or exact divisors of -bits_per_byte- (which is
;;; unlikely to be anything other than 8).
lconstant
    key_of_size = newproperty([
            [1      % conskey("rasarray1", 1) %]
            [8      % conskey("rasarray8", 8) %]
            [24     % conskey("rasarray24", 24) %]],
        3, false, "perm");

;;; Recordclass and buffers to hold colour map and default colour map
;;; - default is just full grey-scale ramp.
defclass lconstant raster_cmap :byte;
lconstant cmap_max = 2 ** bits_per_byte;
lvars i;
lconstant
    NRGB = 3,       ;;; no of colour entries in an RGB colour map
    cmap_buff = initraster_cmap(NRGB * cmap_max),
    cmap_default = consraster_cmap(
                        repeat NRGB times
                            for i from 0 to cmap_max-1 do i endfor
                        endrepeat, NRGB * cmap_max);

#_IF not(DEF sunrasterfile_converter)
    vars sunrasterfile_converter = "imconv";

	#_IF sys_os_type(2) == "sunos"
		;;; may need to be changed
		vars sunrasterfile_converter = "imconv";

	#_ELSEIF sys_os_type(2) == "linux"
		vars sunrasterfile_converter = "convert";
	#_ENDIF

#_ENDIF

define lconstant pipe_in(command, args) -> din;
    ;;; This is like *pipein from the system library, but always returns
    ;;; a device opened with org = <true>, which is what is needed for
    ;;; reading lots of data from a pipe quickly.
    lvars command, args, din, dout;
    ;;; Make the pipe.
    syspipe(true) -> (dout, din);
    if sys_vfork(false) then        ;;; parent
        sysclose(dout);
    else                            ;;; child
        sysclose(din);
        dout ->> popdevout -> popdeverr; ;;; ensure you get error messages
        sysexecute(command, args, false);
        mishap(command, args, 2, 'pipe_in: COMMAND NOT FOUND ??');
    endif
enddefine;

define lconstant pipe_out(command, args) -> dout;
    ;;; Converse of pipe_in. Completely different from pipeout (see *sysutil)
    lvars command, args, din, dout;
    ;;; Make the pipe.
    syspipe(true) -> (dout, din);
    if sys_vfork(false) then        ;;; parent
        sysclose(din);
    else                            ;;; child
        sysclose(dout);
        din -> popdevin;
        sysexecute(command, args, false);
        mishap(command, args, 2, 'pipe_out: COMMAND NOT FOUND ??');
    endif
enddefine;


define lconstant cmap_buff_to_vec(cmap, ncols) /* -> vecs */;
    ;;; Convert a cmap buffer as read from disc to a vector of
    ;;; vectors in the order r, g, b.
    lvars cmap, ncols, vecs;
    lvars col, p;
    newanyarray([1 ^ncols 1 ^NRGB], cmap, true) -> cmap;
    {% for col from 1 to NRGB do
            {% for p from 1 to ncols do cmap(p, col) endfor %}
        endfor %}
enddefine;

define lconstant cmap_vec_to_buff(vecs) /* -> buff */;
    ;;; Convert a vector of vectors to a cmap buffer to write to
    ;;; disc - actually uses the constant vector set up above.
    lvars vecs;
    lvars i, c, col, cmap,
        ncols = length(vecs(1));
    unless ncols <= cmap_max then
        mishap(0, 'Colour map vector too long')
    endunless;
    newanyarray([1 ^ncols 1 ^NRGB], cmap_buff, true) -> cmap;
    for i from 1 to NRGB do
        vecs(i) -> c;
        unless length(c) == ncols then
            mishap(0, 'Colour map vectors different lengths')
        endunless;
        for col from 1 to ncols do
            c(col) -> cmap(col, i);
        endfor
    endfor;
    cmap_buff /* -> buff */
enddefine;


define lconstant endisoneof(str, list) -> pos;
    ;;; If str ends in one of the strings in list, returns the
    ;;; starting index, otherwise false
    lvars ext;
    for ext in list do
    quitif (isendstring(ext, str) ->> pos)
    endfor
enddefine;

define lconstant israsfile(filename) /* -> pos */;
    lconstant rasextensions = ['.ras' '.sun' '.sr' '.scr'];
    endisoneof(filename, rasextensions) /* -> pos */
enddefine;

define lconstant iszipped(filename) /* -> pos */;
    ;;; Check if filename string ends in one of the gzip-type extensions.
    lconstant zipextensions = ['.gz' '-gz' '.z' '_z' '.Z'];
    endisoneof(filename, zipextensions) /* -> pos */
enddefine;

define lconstant iszippedras(filename) /* -> pos */;
    lvars pos;
    (iszipped(filename) ->> pos) and
    israsfile(substring(1, pos-1, filename))
enddefine;

define lconstant isimconvfmt(filename) /* -> fmt */;
    ;;; Check if filename string ends in one of the extensions listed
    ;;; in the imconv man page, excluding .ras. Return format found
    lconstant imconvextensions =
        ['.bmp' '.cur' '.eps' '.epi' '.epsf' '.epsi' '.gif' '.giff' '.hdf'
        '.df' '.ncsa' '.icon' '.cursor' '.mbfx' '.mbfavs'
        '.ico' '.pr' '.iff' '.vff' '.suniff' '.taac' '.mpnt' '.macp' '.pntg'
        '.pbm' '.pcx' '.pcc' '.pgm' '.pic' '.picio' '.pixar' '.pict' '.pict2'
        '.pix' '.alias' '.pnm' '.ppm' '.ps' '.postscript' '.ras' '.sun' '.sr'
        '.scr' '.rgb' '.iris' '.sgi' '.rla' '.rlb' '.rle' '.rpbm' '.rpgm'
        '.rpnm' '.rppm' '.synu' '.tga' '.vda' '.ivb' '.tiff' '.tif' '.viff'
        '.xv' '.x' '.avs' '.xbm' '.bm' '.xwd' '.x11'];
    lvars pos;
    (endisoneof(filename, imconvextensions) ->> pos) and
    substring(pos+1, length(filename)-pos, filename)
enddefine;

define lconstant iszippedimconv(filename) /* -> fmt */;
    lvars pos;
    (iszipped(filename) ->> pos) and
    isimconvfmt(substring(1, pos-1, filename))
enddefine;

define lconstant bufstring(buf, nbytes) /* -> string */;
    lvars i;
    consstring(
        for i from 1 to nbytes do
            fsub_b(i, buf)
        endfor, nbytes)
enddefine;

define lconstant read_with_imconv(filename) -> dev;
    lvars fmt;
    if iszippedimconv(filename) ->> fmt then
        pipe_in('/bin/csh', [
                'csh' '-c' ^('gunzip -c ' <> filename <>
                ' | imconv -' <> fmt <> ' - -outcompress none -ras -')
            ]) -> dev
    elseif isimconvfmt(filename) then
        lconstant imconvref = consref('imconv');
        pipe_in(imconvref, [
                'imconv' ^filename '-outcompress' 'none' '-ras' '-'])
            -> dev
    else
        mishap(filename, 1, 'Unrecognised filename extension')
    endif
enddefine;

define lconstant read_with_convert(filename) -> dev;
    ;;; Do not bother to check extensions as no definitive list in man page.
    ;;; Deals with gzipped files by itself.
    lconstant convertref = consref('convert');
    pipe_in(convertref, ['convert' '+compress' ^filename 'sun:-']) -> dev
enddefine;

define lconstant read_convert(filename) /* -> dev */;
    switchon sunrasterfile_converter ==
    case "imconv" then
        read_with_imconv(filename)
    case "convert" then
        read_with_convert(filename)
    case false then
        false
    else
        mishap(sunrasterfile_converter, 1, 'Illegal value for sunrasterfile_converter')
    endswitchon
enddefine;

define lconstant write_with_imconv(filename) -> dev;
    lconstant imconvref = consref('imconv');
    lvars fmt;
    if isimconvfmt(filename) then
        pipe_out(imconvref, ['imconv' '-ras' '-' ^filename]) -> dev
    elseif iszippedimconv(filename) ->> fmt then
        pipe_out('/bin/csh', ['csh' '-c' %
                'imconv -ras - -' <> fmt <> ' - | gzip > ' <> filename
            %]) -> dev
    else
        mishap(filename, 1, 'Unrecognised filename extension')
    endif
enddefine;

define lconstant write_with_convert(filename) /* -> dev */;
    lconstant convertref = consref('convert');
    pipe_out(convertref, ['convert' '-' ^filename])
enddefine;

define lconstant write_convert(filename) /* -> dev */;
    switchon sunrasterfile_converter ==
    case "imconv" then
        write_with_imconv(filename)
    case "convert" then
        write_with_convert(filename)
    case false then
        false
    else
        mishap(sunrasterfile_converter, 1, 'Illegal value for sunrasterfile_converter')
    endswitchon
enddefine;

define lconstant readrasheader(filename, dev)
        -> (dev, dep, wid, ht, data_len,
        bits_per_row, bytes_per_row, bits_to_fill, veckey);
    ;;; Reads rasterfile header. A separate procedure in order to
    ;;; enable another shot at non-RT_STANDARD rasterfiles using converter.

returnunless(dev);  ;;; in case previous open failed

    ;;; This is needed for DEC alpha, or PC + linux
    ;;; #_IF hd(sys_processor_type) == "alpha" or hd(sys_processor_type) == 80386
    ;;; Test for littlendian: fsub_b(1, consintvec(1,1)) /== 0
#_IF fsub_b(1, consintvec(1,1)) /== 0

    define lconstant next_int(index, string1) -> int;
        ;;; Get 4 bytes from string1, and convert to int.
        lvars index, string1, int;

        ((subscrs(index, string1) && 2:1111111) << 24)
        || (fast_subscrs(index fi_+1, string1) << 16)
        || (fast_subscrs(index  fi_+2, string1) << 8)
        || fast_subscrs(index fi_+3, string1) -> int
    enddefine;

    ;;; Hack by A.Sloman, for alpha byte ordering

    lconstant string1 = inits(rasheadbytes);

    ;;; Read the header
    unless sysread(dev, string1, rasheadbytes) == rasheadbytes then
        mishap(0, 'Unable to read rasterfile header')
    endunless;

    ;;; Assume it is 8 separate 4 byte words for now

    next_int(1, string1) -> rasheader.ras_magic;
    next_int(5, string1) -> rasheader.ras_width;
    next_int(9, string1) -> rasheader.ras_height;
    next_int(13, string1) -> rasheader.ras_depth;
    next_int(17, string1) -> rasheader.ras_length;
    next_int(21, string1) -> rasheader.ras_type;
    next_int(25, string1) -> rasheader.ras_maptype;
    next_int(29, string1) -> rasheader.ras_maplength;

#_ELSE
    ;;; Not alpha. Read the header unchanged

    lvars bytesread = sysread(dev, rasheader, rasheadbytes);
    unless bytesread == rasheadbytes then
        mishap(filename, bufstring(rasheader, bytesread), 2,
            'Unable to read rasterfile header')
    endunless;

#_ENDIF

    rasheader.ras_depth -> dep;
    rasheader.ras_width -> wid;
    rasheader.ras_height -> ht;
    ;;; Round up row length
    ((dep*wid - 1) div RAS_ROUNDROW + 1) * RAS_ROUNDROW -> bits_per_row;
    bits_per_row div bits_per_byte -> bytes_per_row;
    bytes_per_row * ht -> data_len;
    bits_per_row - dep*wid -> bits_to_fill;
    key_of_size(dep) -> veckey;

    ;;; Checks on legality
    unless rasheader.ras_magic = RAS_MAGIC then ;;; big int so not ==
        sysclose(dev);
        mishap(filename, bufstring(rasheader, rasheadbytes), 2,
            'Not rasterfile - wrong magic number')
    endunless;
    unless rasheader.ras_type == RT_STANDARD
    or rasheader.ras_type = RT_FORMAT_RGB then
        sysclose(dev);
        false -> dev;
        return
    endunless;
    unless veckey then
        sysclose(dev);
        mishap(filename, dep, 2, 'Depth must be 1, 8 or 24')
    endunless;
    unless data_len == rasheader.ras_length then
        ;;; print a warning (imconv seems to get this wrong for 24 bit files,
        ;;; rounding up to a multiple of 48)
        sys_pr_message(filename, rasheader, data_len, 3,
            'Header length field is not computed value', nullstring, `W`);
    endunless;
enddefine;

;;; Hackish method to convert from little-endian int to big-endian int if
;;; on little-endian platform. Needed to write the headers correctly.
define lconstant to_bigendian(integer) -> big_endian;
    #_IF (fsub_b(1, consintvec(1,1)) /== 0)
       lvars result = 0;
       result + ( ( integer && 16:FF000000 ) >> 24) -> result;
       result + ( ( integer && 16:00FF0000 ) >> 8 ) -> result;
       result + ( ( integer && 16:0000FF00 ) << 8 ) -> result;
       result + ( ( integer && 16:000000FF ) << 24) -> result;
       result -> big_endian;
    #_ELSE
        integer -> big_endian;
    #_ENDIF;
enddefine;

define sunrasterfile(filename) /* -> (array, [cmap])*/;
    lvars return_cmap = false, tag = false, array, cmap;

    ;;;  Get optional args.
    ;;; Boolean to say whether to return cmap as well as array
    if filename.isboolean then
        filename -> (filename, return_cmap)
    endif;
    ;;; Object to act as tag for oldarray
    unless filename.isstring then
        filename -> (filename, tag)
    endunless;

    ;;; File description variables
    lvars dev, dep, wid, ht, len,
        bits_per_row, bytes_per_row, bits_to_fill, veckey;

    ;;; Try to read file directly
    lvars dev = false;
    if israsfile(filename) then
        sysopen(filename, 0, true, `N`) -> dev;
        readrasheader(filename, dev)
            -> (dev, dep, wid, ht, len,
            bits_per_row, bytes_per_row, bits_to_fill, veckey)
    endif;

    ;;; If this was unsuccessful (file had wrong extension or
    ;;; was not RT_STANDARD), test whether file needs gzip,
    ;;; converter or both on the basis of the filename extension.
    ;;; Complex structure is due to need to read device to see whether
    ;;; it is an RLE-encoded rasterfile which needs to go through converter.
    unless dev then
        sysfileok(filename) -> filename;
        if readable(filename) ->> dev then  ;;; test existence
            sysclose(dev);   ;;; will be reopening through pipe
            false -> dev
        else
            mishap(filename, 1, 'File not readable')
        endif;
        if iszippedras(filename) then
            lconstant gunzipref = consref('gunzip');  ;;; so $path is searched
            pipe_in(gunzipref, ['gunzip' '-c' ^filename]) -> dev;
            readrasheader(filename, dev)
                -> (dev, dep, wid, ht, len,
                bits_per_row, bytes_per_row, bits_to_fill, veckey)
        endif;

        unless dev then
            ;;; Read header from pipe
            read_convert(filename) -> dev;
            readrasheader(filename, dev)
                -> (dev, dep, wid, ht, len,
                bits_per_row, bytes_per_row, bits_to_fill, veckey);

            unless dev then
                mishap(filename, 1, 'Unable to convert to rasterfile format')
            endunless
        endunless
    endunless;

    ;;; Deal with colour map
    if rasheader.ras_maptype == RMT_NONE then
        unless rasheader.ras_maplength == 0 then
            mishap(filename, 1, 'Expecting 0-length colour map')
        endunless;
        false -> cmap;
    elseif rasheader.ras_maptype == RMT_EQUAL_RGB
    or rasheader.ras_maptype == RMT_RAW then
        ;;; Not really sure what RMT_RAW is supposed to mean.  But other
        ;;; software seems to treat it same as RMT_EQUAL_RGB
        lvars ncols = rasheader.ras_maplength div NRGB;
        unless rasheader.ras_maplength == NRGB * ncols then
            mishap(filename, 1, 'Map length not divisible by no. colours')
        elseunless ncols <= cmap_max then
            mishap(filename, 1, 'Too many entries in colour map')
        endunless;
        unless sysread(dev, cmap_buff, rasheader.ras_maplength)
            == rasheader.ras_maplength then
            mishap(filename, 1, 'Could not read colour map entries')
        endunless;
        if return_cmap then
            cmap_buff_to_vec(cmap_buff, ncols) -> cmap
        endif
    endif;

    ;;; Create vector big enough to hold all the data, and read it
    lvars data,
        nitems = (len * bits_per_byte - 1) div dep + 1;     ;;; round up
    if tag then
        arrayvector(oldanyarray(tag, [1 ^nitems], veckey))   ;;; may get
    else                                                     ;;; previous array
        class_init(veckey)(nitems)
    endif -> data;
    lvars lenread;
    unless (sysread(dev, data, len) ->> lenread) == len then
        mishap(filename, lenread, len, 3, 'Error reading data')
    endunless;
    ;;; Might as well close the device for tidiness
    sysclose(dev);

    ;;; If necessary, shuffle up the data to avoid gaps at the end of
    ;;; each line.
    lvars in_sub = 1, out_sub = 1;
    if bits_to_fill /== 0 then
        if dep > bits_per_byte then
            ;;; Assume dep is a multiple of bits_per_byte.  Must not use
            ;;; move_subvector as real data may not lie on vector element
            ;;; boundaries if dep = 24.
            lvars bytes_per_row_out = wid * (dep div bits_per_byte);
            repeat ht - 1 times
                in_sub + bytes_per_row -> in_sub;
                out_sub + bytes_per_row_out -> out_sub;
                move_bytes(in_sub, data, out_sub, data, bytes_per_row_out)
            endrepeat
        else
            ;;; Assume bits_per_byte is a multiple of dep.
            ;;; Must not use move_bytes as there may be the odd few bits
            ;;; to fill in if dep = 1.
            lvars items_per_row = bytes_per_row * (bits_per_byte div dep);
            repeat ht - 1 times
                in_sub + items_per_row -> in_sub;
                out_sub + wid -> out_sub;
                move_subvector(in_sub, data, out_sub, data, wid)
            endrepeat
        endif
    endif;

	;;; Now fix byte-order if necessary by swapping bytes 1 and 3 throughout.
	;;; Added by A.Sloman 4 Jan 2003
	;;; Could be speeded up by doing this in C.
	if rasheader.ras_type == RT_FORMAT_RGB and rasheader.ras_depth == 24 then
		;;; Swap bytes 1 and 3 of every 3.
		lvars
			buf = '0',
			index = 1,
			len = datalength(data)*3;

		while index fi_< len do
			move_bytes(index fi_+ 2, data, 1, buf, 1);
			move_bytes(index, data, index fi_+ 2, data, 1);
			move_bytes(1, buf, index, data, 1);
			  index fi_+ 3 -> index;
		endwhile;

		;;; fix the type field
    	RT_STANDARD -> rasheader.ras_type;
		
	endif;

    ;;; Create the output array and maybe colour map
    newanyarray([1 ^wid 1 ^ht], data, true) /* -> array */;
    if return_cmap then
        cmap
    endif
enddefine;


define updaterof sunrasterfile(array, filename);
    lvars array, cmap = false, filename;
    lvars cmap_type, cmap_length; ;;; Calculated later on
    if array.isvector then
        ;;; There is a colour map argument.
        (array, filename) -> (array, cmap, filename)
    endif;

    lvars dev;
    sysfileok(filename) -> filename;
    if israsfile(filename) then
        syscreate(filename, 1, true) -> dev
    elseif iszippedras(filename) then
        pipe_out('/bin/csh', ['csh' '-c' % 'gzip > ' <> filename %]) -> dev
    else
        write_convert(filename) -> dev
    endif;
    unless dev then
        mishap(filename, 1, 'Unable to open output')
    endunless;

    lvars
        (x0, x1, y0, y1) = explode(boundslist(array)),
        wid = x1 - x0 + 1,
        ht = y1 - y0 + 1,
        data = arrayvector(array),
        dep = class_spec(datakey(data)),
        veckey = key_of_size(dep),
        (vmax, vmin) = arrayvector_bounds(array),
        (bits_before, bytes_before) = ((vmin - 1) * dep) // bits_per_byte,
    ;;; Round up row length
        bits_per_row = ((dep*wid - 1) div RAS_ROUNDROW + 1) * RAS_ROUNDROW,
        bytes_per_row = bits_per_row div bits_per_byte,
        bits_to_fill = bits_per_row - dep*wid,   ;;; do not use //
        len = bytes_per_row * ht;

    unless veckey then
        mishap(datakey(data), 1, 'Illegal type of array for rasterfile')
    endunless;

    ;;; Deal with colour map
    if cmap then
        RMT_EQUAL_RGB -> cmap_type;
        length(cmap(1)) * NRGB -> cmap_length;
        cmap_vec_to_buff(cmap) -> cmap;
    elseif dep == 1 or dep == 24 then
        RMT_NONE -> cmap_type;
        0 -> cmap_length
    else
        RMT_EQUAL_RGB -> cmap_type;
        NRGB * cmap_max -> cmap_length;
        cmap_default -> cmap;
    endif;

    ;;; Set up header
    ;;; Hack: On little-endian machines the fields will need to be reversed.
    ;;; Calling to_bigendian(int) does this if it needs to be done.
    to_bigendian(RAS_MAGIC) -> rasheader.ras_magic;
    to_bigendian(wid) -> rasheader.ras_width;
    to_bigendian(ht) -> rasheader.ras_height;
    to_bigendian(dep) -> rasheader.ras_depth;
    to_bigendian(len) -> rasheader.ras_length;
    to_bigendian(RT_STANDARD) -> rasheader.ras_type;
    to_bigendian(cmap_type) -> rasheader.ras_maptype;
    to_bigendian(cmap_length) -> rasheader.ras_maplength;

    ;;; Write header and colour map
    syswrite(dev, rasheader, rasheadbytes);
    if cmap then
        syswrite(dev, cmap, cmap_length)
    endif;

    ;;; Write the data itself.
    ;;; If nothing to fill and start on a byte boundary, then no need
    ;;; to copy - just write the array vector
    if bits_to_fill == 0 and bits_before == 0 then
        syswrite(dev, bytes_before + 1, data, len)
    else ;;; need to pad each row - use a one-row buffer
        lvars
            items_per_row = ((bits_per_row - 1) div dep) + 1,
            buff = class_init(veckey)(items_per_row),
            in_sub = vmin;
        repeat ht times
            move_subvector(in_sub, data, 1, buff, wid);
            syswrite(dev, buff, bytes_per_row);
            in_sub + wid -> in_sub
        endrepeat
    endif;

    sysclose(dev)
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Feb 21 2009
	Modified to avoid repeatedly checking for endianness

--- Aaron Sloman, Feb 20 2009
	Installed Jack Hollingworth's fix for updater of sunrasterfile
	for use on little-endian machines.

--- Jack Hollingworth (Reading University), Feb 17 2009
    Fixed writing of file header on little-endian machines

--- Aaron Sloman, Dec  6 2004
	For linux set the default value of -sunrasterfile_converter-
	to "convert"
			
--- Aaron Sloman, Jan  8 2003
	Forgot to fix the type field
    	RT_STANDARD -> rasheader.ras_type;
	after the conversion mentioned below.

--- Aaron Sloman, Jan  4 2003
	Extended sunrasterfile to swap bytes 1 and 3 throughout if image depth 24
	and ras_type = RT_FORMAT_RGB (3)
	This fixes wrong display of colours after conversion of some files to .ras
	format by the 'convert' utility.
		
--- David Young, Oct 26 2001
        Allowed use of convert as well as imconv for input and output
        filtering. Added variable -sunrasterfile_converter-.
--- Aaron Sloman, Sep 27 2001
        Using advice from David Young produced more portable test to
        distinguish big-endian and little-endian machines.
--- Aaron Sloman, Oct  1 1999
        Extended the Alpha fixes for PC+linux version.
        Added separate File line in header to simplify installation process
        in Birmingham
--- Aaron Sloman, 25 Sep 1999
        Added code for reading in sunrasterfiles on DEC Alpha, after
        help from Anthony Worrall. Still only works for 8 bit images.
--- David S Young, Feb 26 1999
        Warns instead of mishaps if ras_length field in header does not
        agree with computed value, and uses computed value. See comment.
--- David S Young, Feb 25 1999
        Added call to sysfileok in the updater - needed if filename
        passed to imconv.
--- David S Young, Dec  4 1998
        Now pipes non-rasterfiles through imconv. Will no longer read or
        write files with a non-standard extension.
--- David S Young, Jun 29 1998
        Removed read_from_pipe after John Gibson pointed out that sysread
        operates as required if the pipe is opened with org=<true>.
--- David S Young, Jun 22 1998, from an idea of Ian Eiloart
        Added code to read and write files compressed using gzip.
        Also changed org in sysopen and syscreate to <true>.
--- David S Young, Jul  8 1996
        Added option to reuse output arrays using *oldarray.
--- David S Young, Dec 23 1993
        Changed "lconstant macro" to "lconstant"; former has no advantage.
--- David S Young, Dec 21 1993
        Removed a couple of numerical constants.
 */
