/*  --- Copyright University of Sussex 1986.  All rights reserved. ---------
 *  File:           $usepop/master/C.all/lib/lib/blocks/fits.p
 *  Purpose:        a matcher for strings
 *  Author:         Unknown, ??? (see revisions)
 *  Documentation:
 *  Related Files:
 */

;;; ?   will match any char
;;; *   will match zero or more of any character
;;; @c  will match zero or more of character c
;;; #   will match any number of digits

define 7 string fits template;
		define head(string);substring(1,1,string)enddefine;
		define tail(string);
				vars len;  string.datalength -> len;
				if      len > 1
				then    substring(2, len -1, string)
				else    ''
				endif
		enddefine;
		if      string = template
		then    true
		elseif  string = '' or template = ''
		then    false
		else    if      template.head = string.head or
						template.head = '?'
				then    string.tail fits template.tail
				elseif  template.head = '*'
				then    string.tail fits template or
						string.tail fits template.tail
				elseif  template.head = '@'
				then    if      string.head = template.tail.head
						then    string.tail fits template
						else    string fits template.tail.tail
						endif
				elseif  template.head = '#'
				then    if      isnumbercode(string(1))
						then    string.tail = '' or string.tail fits template
						else    string.tail fits template.tail
						endif
				else    false
				endif
		endif
enddefine;
