$: << File.dirname(__FILE__)
require 'util'

def make_hatom_item(meta, item)
	item[:author] ||= meta[:author] if meta[:author]
	item[:author] ||= {}
	if meta[:logo]
		item[:author] ||= {}
		item[:author][:logo] ||= meta[:logo]
	end
	item[:author][:photo] ||= item[:author][:logo] if item[:author] && item[:author][:logo]

	item[:published] ||= Time.now

	r =  '<article xmlns="http://www.w3.org/1999/xhtml" '
	r << "id=\"#{h item[:id]}\" " if item[:id]
	r << "class=\"hentry\">\n"
	r << "\t<header>\n"
	r << "\t\t"
	r << '<h1 class="entry-title">' if item[:title]
	r << "<a rel=\"bookmark\" href=\"#{h item[:bookmark]}\">" if item[:bookmark]
	r << item[:title] if item[:title]
	r << '</a>' if item[:bookmark]
	r << '</h1>' if item[:title]
	r << "\n"
	r << "\t\t<div class=\"vcard author\">"  if item[:author]
	r << "<a class=\"url\" href=\"#{h item[:author][:url]}\">" if item[:author][:url]
	r << "<img class=\"photo\" src=\"#{h item[:author][:photo]}\" alt=\"photo\" />" if item[:author][:photo]
	r << "<span class=\"fn\">#{h item[:author][:fn]}</span>" if item[:author][:fn]
	r << '</a>' if item[:author][:url]
	r << "</div>\n" if item[:author]
	r << "\t\t<time class=\"published\" pubdate=\"pubdate\" datetime=\"#{item[:published].iso8601}\">#{item[:published].strftime('%Y-%j %H:%M %Z')}</time>\n"
	(item[:in_reply_to] || []).each do |parent|
		r << "\t\t<a rev=\"reply\" rel=\"in-reply-to\" href=\"#{parent[:href]}\">in reply to</a>\n" if parent[:href]
		r << "\t\t<a rev=\"reply\" rel=\"in-reply-to\" href=\"#{parent[:ref]}\">in reply to</a>\n" if parent[:ref] && parent[:ref] != parent[:href]
	end
	r << "\t\t<a rel=\"source\" href=\"#{h meta[:self]}\">#{h meta[:title]}</a>\n"
	r << "\t</header>\n"
	r << "\t<section class=\"entry-content\">#{item[:content]}</section>\n" if item[:content]
	r << "\n<div class=\"original-content\">" << item[:xml] << "</div>\n\n" if item[:xml]
	r << "</article>\n"
end
