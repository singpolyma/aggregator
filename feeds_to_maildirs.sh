#!/bin/sh

# Path to where other scripts are
scripts="$(readlink -sen "`dirname "$0"`")"

# Create the target dir and move to it
mkdir -p "$1"
cd "$1"

while read feed; do
	dir="`echo "$feed" | cut -d'	' -f1`"
	mkdir -p "$dir"
	cd "$dir"
	mkdir -p new cur tmp # It's a maildir for sure

	url="`echo "$feed" | cut -d'	' -f2-`"
	ruby "$scripts/poll_feed.rb" "$url" | ruby "$scripts/update_maildir.rb" "`pwd`" "`pwd`/.state"

	cd -
	echo "Done <$url>..."
done

echo "Done"
