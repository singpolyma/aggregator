$: << File.dirname(__FILE__) + '/lib'
require 'xml_feed_polyglot'
require 'make_hatom'
require 'util'

url, response = fetch(ARGV[0])

# Parse Content-Type header
type, type_params = response['content-type'].split(/\s*;\s*/, 2)
type_params = type_params.split(/\s*;\s*/).inject({}) do |h, param|
	k, v = param.split(/=/, 2)
	h.merge({k => v})
end

# Handle encoding
data = response.body
data.force_encoding(type_params['charset']) if type_params['charset']

# Parse feed
meta, items = case type
	when 'application/rss+xml', 'application/rdf+xml', 'application/atom+xml', 'application/xml', 'text/xml'
		xml_feed_polyglot(data)
	else
		raise "Unknown MIME type for feed: #{response['content-type']}"
end

raise "Error fetching feed." unless meta and items

puts(items.map do |item|
	make_hatom_item(meta, item)
end.join("\n\n"))
