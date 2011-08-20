require 'nokogiri'
require 'yaml'
require 'fileutils'
require 'digest/md5'

$: << File.dirname(__FILE__) + '/lib'
require 'util'

begin
	$config = YAML::load_file('/etc/aggregator-singpolyma/config.yml')
rescue Errno::ENOENT
	$config = YAML::load_file(File.dirname(__FILE__) + '/config.yml')
end

entries = Hash.new {|h, k| h[k] = {}}

# Go through all the tmp files, read out the entries, and delete the files
Dir::glob(File.join($config['data_dir'], 'tmp', '*')).each do |file|
	Nokogiri::parse("<html>#{open(file).read.force_encoding('utf-8')}</html>").search('.hentry').each do |entry|
		published = hentry_published(entry)
		source = entry.at('*[rel~=source][href]').attributes['href'].to_s
		entries[source][published.strftime('%Y-%j')] ||= []
		entries[source][published.strftime('%Y-%j')] << {:entry => entry, :published => published}
	end
	FileUtils.rm(file)
end

entries.each do |source, entries|
	users = (open(File.join($config['data_dir'], u(source))).read rescue '').split(/\s+/)
	next unless users.length > 0
	entries.each do |date, entries|
		users.each do |user|
			published = entries.first[:published] # Granularity down to day
			path = File.join(File.dirname(__FILE__), 'feeds', user, published.strftime('%Y'))
			FileUtils.mkdir_p(path) # Make sure the directory exists

			# Add entries already from that day
			doc = Nokogiri::parse((open(File.join(path, "#{published.strftime('%j')}.xhtml")).read rescue ''))
			doc.search('.hentry').each do |entry|
				entries << {:entry => entry, :published => hentry_published(entry)}
			end
			# Sort entries by pubdate within day
			entries.sort! {|a,b| b[:published] <=> a[:published]}
			# Dedup items
			seen = []
			entries.reject! {|entry|
				id = (entry[:entry].attributes['id'] || Digest::MD5.hexdigest(entry[:entry].to_xhtml)).to_s
				next true if seen.include?(id)
				seen << id
				false
			}

			open(File.join(path, "#{published.strftime('%j')}.xhtml"), 'w') { |fh|
				fh.puts '<!DOCTYPE html>'
				fh.puts '<html xmlns="http://www.w3.org/1999/xhtml">'
				fh.puts "<head><title>#{user}</title></head>"
				fh.puts '<body>'
				entries.each do |entry|
					fh.puts entry[:entry].to_xhtml
				end
				fh.puts "<a rel=\"prev\" href=\"/feeds/#{user}/#{published.strftime('%Y')}/#{published.strftime('%j').to_i-1}.xhtml\">Previous day</a>"
				fh.puts "<a rel=\"next\" href=\"/feeds/#{user}/#{published.strftime('%Y')}/#{published.strftime('%j').to_i+1}.xhtml\">Next day</a>"
				fh.puts '</body>'
				fh.puts '</html>'
			}
		end
	end
end
