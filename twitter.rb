require 'oauth'
require 'json'
require 'time'

$: << File.dirname(__FILE__) + '/lib'
require 'make_hatom'

# Usage: ruby twitter.rb CONSUMER_TOKEN CONSUMER_SECRET ACCESS_TOKEN ACCESS_SECRET username

consumer = OAuth::Consumer.new(ARGV[0], ARGV[1], :site => 'http://api.twitter.com')
token = OAuth::AccessToken.new(consumer, ARGV[2], ARGV[3])

['/statuses/home_timeline.json', '/statuses/mentions.json'].each do |endpoint|
	begin
		response = token.get(endpoint).body # in here to handle timeouts
		data = JSON::parse(response)
	rescue Exception
		# Twitter API barfed, just ignore and say we got nothing
		data = []
	end

	puts data.map { |tweet|
		next nil if tweet['user']['screen_name'] == ARGV[4]
		item = {
			:bookmark => "http://twitter.com/#{tweet['user']['screen_name']}/statuses/#{tweet['id_str']}",
			:content => tweet['text'],
			:author => {
				:fn => tweet['user']['screen_name'],
				:url => "http://twitter.com/#{tweet['user']['screen_name']}",
				:photo => tweet['user']['profile_image_url']
			},
			:published => Time.parse(tweet['created_at'])
		}
		item[:id] = "tag:twitter.com,2007:#{item[:bookmark]}"
		item[:in_reply_to] = [{:ref => "tag:twitter.com,2007:http://twitter.com/#{tweet['in_reply_to_screen_name']}/statuses/#{tweet['in_reply_to_status_id_str']}", :href => "http://twitter.com/#{tweet['in_reply_to_screen_name']}/statuses/#{tweet['in_reply_to_status_id_str']}"}] if tweet['in_reply_to_status_id_str']
		item[:xml] = '<object class="twitter" type="application/json" data="data:application/json;base64,'+[JSON::generate(tweet)].pack('m').gsub(/\s/,'')+'"></object>'
		item
	}.compact.map {|item|
		make_hatom_item({:self => "http://twitter.com/statuses/home_timeline/#{ARGV[4]}.json", :title => "twitter / #{ARGV[4]} / home+mentions"}, item)
	}.join("\n")
end
