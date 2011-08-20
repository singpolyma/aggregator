$: << File.dirname(__FILE__)
require 'util'

require 'nokogiri'

def from_hatom(string)
	Nokogiri::parse("<html xmlns=\"http://www.w3.org/1999/xhtml\">#{string}</html>").search('.hentry').map do |entry|
		content_node = entry.at('.entry-content')
		{
			:item => {
				:id => entry.attributes['id'].to_s,
				:title => (entry.at('.entry-title').text rescue ''),
				:content => content_node.to_xhtml.sub(/^<#{content_node.name}[^>]*>/, '').sub(/<\/#{content_node.name}>$/, ''),
				:in_reply_to => entry.search('*[rev~=reply]').map {|r|
					uri = (r.attributes['href'].to_s rescue nil)
					if uri && uri =~ /^http/
						{:href => uri}
					elsif uri
						{:ref => uri}
					end
				}.compact,
				:author => {
					:fn => entry.at('.author .fn').text,
					:url => (entry.at('.author .url').attributes['href'].to_s rescue nil)
				},
				:bookmark => (entry.at('a[rel~=bookmark]').attributes['href'].to_s rescue nil),
				:published => hentry_published(entry),
				:xml => an(entry.at('.original-content')).inner_html
			},
			:meta => {
				:self => (entry.at('*[rel~=source]').attributes['href'].to_s rescue nil),
				:title => (entry.at('*[rel~=source]').text rescue nil)
			}
		}
	end
end
