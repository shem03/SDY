#!/bin/bash

LUAC=./skynet/3rd/lua/luac
mkdir -p bin

Luas=`find server -name "*.lua"`
for file in $Luas
do
	filename=`basename $file`
	dir_n=`dirname $file`
	echo $dir_n
	mkdir -p bin/$dir_n
	echo $filename
	$LUAC -o bin/$file $file
done

echo ""
echo "finish!!!"