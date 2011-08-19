#!/bin/sh

# Pass us the path to where feeds are
cd "$1"

for USER in *; do
	cd "$USER"
	touch `date +%Y/%j.xhtml`
	ln -sf `date +%Y/%j.xhtml` index.xhtml
	cd -
done
