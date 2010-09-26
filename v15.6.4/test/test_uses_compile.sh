#!/bin/bash

. `dirname $0`/../pop/com/poplog.sh

T=/tmp/test_uses_compile.$$

echo '<?xml version="1.0"?>'
echo '<testsuite name="test_uses_compile">'

print_case () {
	class=$1
	name=$2
	type=$3

	echo "<testcase classname=\"$class\" name=\"$name\">"
	echo "    <$type message=\"$name\" line=\"0\">"
	if [[ $type == 'failure' ]] ; then
		echo "<![CDATA["
		cat $T
		echo "]]>"
	else
		echo $file
	fi
	echo "    </$type>"
	echo "</testcase>"
}

execute_test () {
	class=$1
	name=$2
	cmd=$3
	shift; shift; shift
	$cmd "$*" < /dev/null > $T 2>&1
	if [[ `grep -c MISHAP $T` -gt 0 ]] ; then
		print_case $class $name 'failure' 
	else 
		print_case $class $name 'info' 
	fi
}

# do the standard libraries compile?
for d in $poplocalauto $popautolib $popvedlib $usepop/pop/lib/database $poplocal/local/lib $usepop/pop/packages/lib $popliblib $popdatalib ; do
	if [[ -d $d ]] ; then
		for f in $d/*.p ; do
			f=$(basename $f)
			f=${f%.*}
			execute_test $d $f pop11 ":uses $f"
		done
	fi
done

echo '</testsuite>'
