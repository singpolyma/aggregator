require 'rexml/document'
require 'cgi'
require 'time'

def xml_feed_polyglot(string)
	root = REXML::Document.new(string).root

	meta = {:self => @self}
	items = []

	if root.name == 'rss'
		root.elements.each('./channel') {|el| root = el} # <channel> is really the root
	end

	root.add_namespace('content', 'http://purl.org/rss/1.0/modules/content/')
	root.add_namespace('dc', 'http://purl.org/dc/elements/1.1/')
	root.add_namespace('atom', 'http://www.w3.org/2005/Atom')
	root.add_namespace('thr', 'http://purl.org/syndication/thread/1.0')

	root.elements.each('./title') {|el| meta[:title] = ''; el.write(meta[:title]); meta[:title].gsub!(/<[^>]+>/, '').strip!}
	root.elements.each('./link') {|el| meta[:link] = el.attributes['href'] ? el.attributes['href'].to_s : el.text}
	root.elements.each('./atom:link[@rel="self"]') {|el| meta[:self] = el.attributes['href'] }

	root.elements.each('./atom:author|./author|./dc:creator') {|el|
		if el.children.length > 0
			meta[:author] = {}
			el.elements.each('./name') {|c| meta[:author][:fn] = c.text}
			el.elements.each('./uri') {|c| meta[:author][:url] = c.text}
		else
			meta[:author] = {:fn => el.text}
		end
	}

	root.elements.each('./item|./entry') {|itemel|
		item = {:category => [], :in_reply_to => [], :xml => ''}
		itemel.add_namespace('http://www.w3.org/2005/Atom') if itemel.name == 'entry'
		# Cheat and use RSS1 namespace for 1&2
		itemel.add_namespace('http://purl.org/rss/1.0/modules/') if itemel.name == 'item'
		itemel.namespaces.each do |ns, uri|
			next if ns == 'xmlns' # We already added the default namespace
			itemel.add_namespace(ns, uri)
		end
		itemel.write(item[:xml])
		itemel.elements.each('./title') {|el|
			# Always end up HTML-safe
			if el.attributes['type'].to_s == 'xhtml'
				item[:title] = ''
				el.write(item[:title])
				item[:title].gsub!(/<[^>]+>/, '').strip!
			elsif el.attributes['type'].to_s == 'html'
				item[:title] = CGI::unescapeHTML(el.text)
			else
				item[:title] = el.text
			end
		}
		itemel.elements.each('./link') {|el| item[:bookmark] = el.text}
		itemel.elements.each('./atom:link[@rel="alternate"][@type="text/html"]') {|el| item[:bookmark] = el.attributes['href']}
		itemel.elements.each('./guid|./atom:id') {|el| item[:id] = el.text}
		itemel.elements.each('./description|./content:encoded') {|el|
			# Always end up HTML-safe
			item[:content] = CGI::unescapeHTML(el.text)
		}
		itemel.elements.each('./atom:content') {|el|
			item[:content] = ''
			el.write(item[:content])
			item[:content].sub!(/<content[^>]+>/, '')
			item[:content].sub!(/<\/content>/, '')
			if el.attributes['type'] == 'html'
				# Always ends up HTML-safe
				item[:content] = CGI::unescapeHTML(item[:content])
			elsif el.attributes['type'] == 'text'
				item[:content] = CGI::escapeHTML(item[:content])
			end
		}
		itemel.elements.each('./atom:author|./author|./dc:creator') {|el|
			if el.children.length > 0
				item[:author] = {}
				el.elements.each('./name') {|c| item[:author][:fn] = c.text}
				el.elements.each('./uri') {|c| item[:author][:url] = c.text}
			else
				item[:author] = {:fn => el.text}
			end
		}
		itemel.elements.each('./pubDate|./dc:date|./published') {|el| item[:published] = Time.parse(el.text)}

		itemel.elements.each('./category') {|el| item[:category] << el.text}
		itemel.elements.each('./thr:in-reply-to') {|el| item[:in_reply_to] << {:ref => el.attributes['ref'], :href => el.attributes['href']}}

		items << item
	}

	[meta, items]
end
