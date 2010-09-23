/* --- Copyright University of Sussex 1990. All rights reserved. ----------
 > File:            $popneural/lib/netfileutil.p
 > Purpose:         save and load NN network utilities
 > Author:          David Young, Jan 23 1990
 > Related Files:   backprop.p  complearn.p
 */

section;

define global constant procedure devarrvec(dev,arr);
    lvars arr dev;
    lvars buff = arrayvector(arr);
    syswrite(dev,buff,4*(datasize(buff)-2))
enddefine;

define updaterof devarrvec(dev,arr);
    lvars arr dev;
    lvars buff = arrayvector(arr), nbytes = 4*(datasize(buff)-2);
    unless sysread(dev,buff,nbytes) == nbytes then
        mishap('end of file',[^dev])
    endunless
enddefine;

define global constant procedure devstring(dev,str);
    lvars str dev;
    syswrite(dev,str,datalength(str));
enddefine;

define updaterof devstring(dev,str);
    lvars str dev;
    lvars nbytes = datalength(str);
    unless sysread(dev,str,nbytes) == nbytes then
        mishap('end of file',[^dev])
    endunless
enddefine;

define global constant procedure stringout(str);
    lvars str;
    lvars strptr = 0, strlen = datalength(str);
    procedure(ch);
        strptr fi_+ 1 -> strptr;
        ch -> str(strptr)
    endprocedure
enddefine;

define global constant procedure wtvarstring(dev,str);
    ;;; Write a string to the device, preceded by its length as
    ;;; 4 bytes of ascii
    lvars dev str;
    lvars nbytes = datalength(str);
    lconstant slen = 4,     ;;; must match rdvarstring
         maxl = 10**slen - 1, strbuf = inits(slen);
    dlocal cucharout = stringout(strbuf), pr = sys_syspr;
    if nbytes fi_> maxl then mishap('String too long',[^nbytes ^maxl]) endif;
    pr_field(nbytes,slen,`\s,false);
    devstring(dev, strbuf);
    devstring(dev, str)
enddefine;

define global constant procedure rdvarstring(dev) -> str;
    ;;; Read a string as written by wtvarstring
    lvars dev str;
    lvars strlen;
    lconstant slen = 4,   ;;; must match wtvarstring
         strbuf = inits(slen);
    dev -> devstring(strbuf);
    incharitem(stringin(strbuf))() -> strlen;
    inits(strlen) -> str;
    dev -> devstring(str)
enddefine;

define global constant procedure putnum(dev,num);
    lvars dev num;
    lconstant strlen = 25,  ;;; must match getnum
         strbuf = inits(strlen);
    dlocal cucharout = stringout(strbuf),
         pop_pr_exponent = true;
    pr_field(num,strlen,`\s,false);
    devstring(dev,strbuf)
enddefine;

define global constant procedure getnum(dev) /* -> num */;
    lvars dev;
    lconstant strlen = 25,  ;;; must match putnum
         strbuf = inits(strlen);
    dev -> devstring(strbuf);
    incharitem(stringin(strbuf))() /* -> num */
enddefine;

vars netfileutil = true;

endsection;

/* --- Copyright University of Sussex 1990. All rights reserved. ------- */


/*  --- Revision History --------------------------------------------------
*/
