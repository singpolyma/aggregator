require 'rexml/document'
require 'htmlentities'
require 'time'

$: << File.dirname(__FILE__)
require 'util'

def txt(el)
	el.texts.join(' ')
end

def xml_feed_polyglot(string)
	root = REXML::Document.new(string).root

	meta = {:self => @self}
	items = []

	# Channel contains root-level elements
	root.elements.each('./channel') do |channel|
		channel.children.each {|el| root << el}
	end

	root.add_namespace('content', 'http://purl.org/rss/1.0/modules/content/')
	root.add_namespace('dc', 'http://purl.org/dc/elements/1.1/')
	root.add_namespace('atom', 'http://www.w3.org/2005/Atom')
	root.add_namespace('thr', 'http://purl.org/syndication/thread/1.0')

	root.elements.each('./title') {|el| meta[:title] = ''; el.write(meta[:title]); meta[:title].gsub!(/<[^>]+>/, '').strip!}
	root.elements.each('./link') {|el| meta[:link] = el.attributes['href'] ? el.attributes['href'].to_s : txt(el); break }
	root.elements.each('./atom:link[@rel="self"]') {|el| meta[:self] = el.attributes['href'] }

	root.elements.each('./image/url|./logo') {|el| meta[:logo] = txt(el)}

	root.elements.each('./atom:author|./author|./dc:creator') {|el|
		n = el.children.inject(0) {|n,c| c.class != REXML::Text ? n+1 : n }
		if n > 0
			meta[:author] = {}
			el.elements.each('./name') {|c| meta[:author][:fn] = txt(c)}
			el.elements.each('./uri') {|c| meta[:author][:url] = txt(c)}
		else
			meta[:author] = {:fn => txt(el)}
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
				item[:title] = txt(el)
			else
				item[:title] = txt(el)
			end
		}
		itemel.elements.each('./link') {|el| item[:bookmark] = txt(el)}
		itemel.elements.each('./atom:link[@rel="alternate"][@type="text/html"]') {|el| item[:bookmark] = el.attributes['href']}
		itemel.elements.each('./guid|./atom:id') {|el| item[:id] = txt(el)}
		itemel.elements.each('./description') {|el|
			# Always end up HTML-safe
			item[:content] = HTMLEntities.decode_entities(txt(el))
		}
		itemel.elements.each('./content:encoded') {|el|
			# Always end up HTML-safe
			item[:content] = HTMLEntities.decode_entities(txt(el))
		}
		itemel.elements.each('./atom:content') {|el|
			item[:content] = ''
			el.write(item[:content])
			item[:content].sub!(/<content[^>]+>/, '')
			item[:content].sub!(/<\/content>/, '')
			if el.attributes['type'] == 'html'
				# Always ends up HTML-safe
				item[:content] = HTMLEntities.decode_entities(item[:content])
			elsif el.attributes['type'] == 'text'
				item[:content] = h(item[:content])
			end
		}
		itemel.elements.each('./atom:author|./author|./dc:creator') {|el|
			n = el.children.inject(0) {|n,c| c.class != REXML::Text ? n+1 : n }
			if n > 0
				item[:author] = {}
				el.elements.each('./name') {|c| item[:author][:fn] = txt(c)}
				el.elements.each('./uri') {|c| item[:author][:url] = txt(c)}
			else
				item[:author] = {:fn => txt(el)}
			end
		}
		itemel.elements.each('./pubDate|./dc:date|./published') {|el| item[:published] = Time.parse(txt(el))}

		itemel.elements.each('./category|./atom:category') {|el| item[:category] << (txt(el) || el.attributes['term'])}
		itemel.elements.each('./thr:in-reply-to') {|el| item[:in_reply_to] << {:ref => el.attributes['ref'], :href => el.attributes['href']}}

		itemel.elements.each('./source') {|el|
			item[:source] = {
				:id    => el.attributes['url'],
				:self  => el.attributes['url'],
				:title => txt(el)
			}
		}

		itemel.elements.each('./atom:source') {|el|
			item[:source] = {}
			el.elements.each('./id') {|c| item[:source][:id] = txt(c)}
			el.elements.each('./title') {|c| item[:source][:title] = txt(c)}
			el.elements.each('./atom:link[@rel="self"]') {|c| item[:source][:self] = c.attributes['href']}
		}

		items << item
	}

	[meta, items]
end
