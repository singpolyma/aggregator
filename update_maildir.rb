# encoding: utf-8
$: << File.dirname(__FILE__) + '/lib'
require 'make_mime'
require 'from_hatom'
require 'fileutils'

maildir, state_file = ARGV
saw = (open(state_file).read rescue '')
to_write = saw
wrote_state = false

HOSTNAME = `hostname`.chomp

i = 0
from_hatom(STDIN.read.force_encoding('utf-8')).each do |entry|
	entry[:item][:id] = entry[:item][:bookmark] if entry[:item][:id].to_s == ''
	break if entry[:item][:id] == saw

	unless wrote_state
		to_write = entry[:item][:id]
		wrote_state = true
	end

	name = "#{Time.now.to_f}_#{$$}_#{HOSTNAME}_#{i}"
	tmp = File.join(maildir, 'tmp', name)
	new = File.join(maildir, 'new', name)
	open(tmp, 'w') {|fh|
		fh.write make_mime(entry[:meta], entry[:item])
	}
	FileUtils.ln tmp, new
	FileUtils.rm tmp

	i += 1
end

# Do not write until end so that we try again on fail
open(state_file, 'w') {|fh| fh.write(to_write)}
