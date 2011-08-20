#!/usr/bin/env rackup
# encoding: utf-8
#\ -E deployment

require 'yaml'
require 'digest/md5'
require 'hmac-sha1'
require 'http_router'

$: << File.dirname(__FILE__) + '/lib'
require 'xml_feed_polyglot'
require 'make_hatom'
require 'path_info_fix'
require 'util'

begin
	$config = YAML::load_file('/etc/aggregator-singpolyma/config.yml')
rescue Errno::ENOENT
	$config = YAML::load_file(File.dirname(__FILE__) + '/config.yml')
end

use Rack::Reloader
use Rack::ContentLength
use PathInfoFix
# https://github.com/hassox/rack-rescue

run HttpRouter.new {
	get('/').head.to { |env|
		[200, {}, 'Under construction']
	}

	# For days which have no content, serve prev/next links
	get('/feeds/:user/:year/:day.xhtml').head.to { |env|
		[200, {'Content-Type' => 'application/xhtml+xml; charset=utf-8'}, <<HTML
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>singpolyma</title></head>
<body>
	<a rel="prev" href="/feeds/#{env['router.params'][:user]}/#{env['router.params'][:year]}/#{env['router.params'][:day].to_i-1}.xhtml">Previous day</a>
	<a rel="next" href="/feeds/#{env['router.params'][:user]}/#{env['router.params'][:year]}/#{env['router.params'][:day].to_i+1}.xhtml">Next day</a>
</body>
</html>
HTML
		]
	}

	get('/pshb').head.to { |env|
		req = ::Rack::Request.new(env)
		are_subscribers = (open(File.join($config['data_dir'], u(req['topic']))).read rescue '') !~ /^\s*$/
		if req['hub.mode'] == 'subscribe' ? are_subscribers : !are_subscribers
			[200, {}, req['hub.challenge']]
		else
			[404, {'Content-Type' => 'text/plain; charset=utf-8'}, "No one wants #{req['topic']}"]
		end
	}

	post('/pshb').to lambda { |env|
		req = ::Rack::Request.new(env)
		data = env['rack.input'].read

		# Verify signature
		sig = env['HTTP_X_HUB_SIGNATURE'].to_s.sub(/^sha1=/, '')
		secret = Digest::MD5.hexdigest("#{$config['secret']}#{req.GET['topic']}#{$config['secret']}")
		unless (sig == HMAC::SHA1.new(secret).update(data).hexdigest)
			return [400, {'Content-Type' => 'text/plain; charset=utf-8'}, "Bad signature\n"]
		end

		# Set input encoding to what it has declared to be
		data = data.force_encode(req.media_type_params['charset']) if req.media_type_params['charset']
		meta, items = case req.media_type
			when 'application/rss+xml', 'application/rdf+xml', 'application/atom+xml'
				xml_feed_polyglot(data)
			else
				return [400, {'Content-Type' => 'text/plain; charset=utf-8'}, "Cannot process #{req.media_type}\n"]
		end

		meta[:self] = req.GET['topic'] if req.GET['topic'] # We know the topic, so use it

		hatom = items.map {|i| make_hatom_item(meta, i) }.join
		open(File.join($config['data_dir'], 'tmp', Digest::MD5.hexdigest(data)), 'w') { |fh|
			fh.write hatom
		}

		[200, {'Content-Type' => 'text/plain; charset=utf-8'}, "Success\n"]
	}
}
