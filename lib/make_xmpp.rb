# encoding: utf-8
require 'rexml/document'
require 'xmpp4r/client'
require 'htmlentities'

$: << File.dirname(__FILE__)
require 'util'

def make_xmpp_message(meta, item)
	item[:author] ||= meta[:author] if meta[:author]
	if meta[:logo]
		item[:author] ||= {}
		item[:author][:logo] ||= meta[:logo]
	end
	item[:author][:photo] ||= item[:author][:logo] if item[:author] && item[:author][:logo]

	# Build plain text body
	title = HTMLEntities.decode_entities(item[:title].to_s.gsub(/<[^<>]+>/, '')).strip
	content = HTMLEntities.decode_entities(item[:content].to_s.gsub(/<[^<>]+>/, '')).gsub(/\s+/, ' ').strip
	content = title if content.length < title.length * 3 && content.include?(title)
	text = "#{item[:author][:fn] rescue meta[:title]}: #{content} / #{item[:bookmark]}"
	text << ' ↶' if item[:in_reply_to] && item[:in_reply_to].length > 0
	(item[:in_reply_to] || []).each do |parent|
		text << " #{parent[:href]} " if parent[:href]
	end

	r = Jabber::Message::new(nil, text).set_type(:headline).set_subject(title)

	begin
		html =  "<html xmlns='http://jabber.org/protocol/xhtml-im'><body xmlns='http://www.w3.org/1999/xhtml' class='hentry'"
		html << " id=\"#{h item[:id]}\"" if item[:id]
		html << '>'
		html << "<span class=\"vcard author\">"  if item[:author]
		html << "<a class=\"url\" href=\"#{h item[:author][:url]}\">" if item[:author][:url]
		html << "<span class=\"fn\">#{h item[:author][:fn]}</span>" if item[:author][:fn]
		html << '</a>' if item[:author][:url]
		html << "</span>: " if item[:author]
		html << "<span class='entry-content'>#{item[:content]}</span> " if item[:content]
		html << "<a rel='bookmark' href='#{h item[:bookmark]}'>#</a>" if item[:bookmark]
		(item[:in_reply_to] || []).each do |parent|
			html << " <a rev=\"reply\" rel=\"in-reply-to\" href=\"#{parent[:href]}\">in reply to</a> " if parent[:href]
		end
		html << '</body></html>'
		r.add_element(REXML::Document.new(html).root)
	rescue Exception
		# Invalid XHTML
	end

	r
end
