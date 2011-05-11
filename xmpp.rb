$: << File.dirname(__FILE__) + '/lib'
require 'xmpp4r/client'
require 'make_xmpp'
require 'from_hatom'

def hack_filter(item)
	item[:content] =~ /(?:Links is out!.*Top stories today)|(?:\(@.*4sq\.com)|(?:News is out! http\S+$)/
end

from, password, to, state_file = ARGV
xmpp_saw = (open(state_file).read rescue '')
wrote_state = false

# Create a list of XMPP messages

to_send = []

from_hatom(STDIN.read).each do |entry|
	break if entry[:item][:id] == xmpp_saw
	next if hack_filter(entry[:item])

	unless wrote_state
		open(state_file, 'w') {|fh| fh.write(entry[:item][:id])}
		wrote_state = true
	end

	msg = make_xmpp_message(entry[:meta], entry[:item])
	msg.set_to(to)

	to_send << msg
end

# Actually send XMPP messages

rcount = 0
begin
	xmpp = Jabber::Client.new(Jabber::JID.new(from))
	xmpp.connect
	xmpp.auth(password)
rescue Exception
	if rcount < 3
		rcount += 1
		retry
	else
		raise $!
	end
end

to_send.reverse_each do |msg|
	xmpp.send(msg)
end

xmpp.close
