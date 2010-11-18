#!/bin/sh

# Pass us the path to where feeds are
cd "$1"

for USER in *; do
	cd "$USER"
	unlink index.xhtml
	ln -s `date +%Y/%j.xhtml` index.xhtml
	cd -
done
