$: << File.dirname(__FILE__) + '/lib'
require 'util'
require 'rexml/document'

def process_node(node, path='')
	node.elements.each('./outline') do |el|
		title = el.attributes['text'].to_s
		title = el.attributes['xmlUrl'].gsub(/\/, '.'/) if title == ''
		if el.attributes['xmlUrl']
			puts "#{path}#{title}\t#{el.attributes['xmlUrl']}"
		end
		# Process as structure node
		process_node(el, path + title + '/')
	end
end

root = REXML::Document.new(STDIN.read).root
root.elements.each('./body') do |el|
	process_node(el)
end
