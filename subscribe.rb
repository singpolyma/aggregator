require 'yaml'

$: << File.dirname(__FILE__) + '/lib'
require 'util'
require 'subscribe'

begin
	$config = YAML::load_file('/etc/aggregator-singpolyma/config.yml')
rescue Errno::ENOENT
	$config = YAML::load_file(File.dirname(__FILE__) + '/config.yml')
end

# Usage: ruby subscribe.rb TOPIC USER

# Send the subscribe call
subscribe(ARGV[0], ($config['approot'].split('/') + ['pshb']).join('/'), $config['secret']) { |topic|
	# Add the user to the file so the subscribe will succeed
	open(File.join($config['data_dir'], u(topic)), 'a') { |fh|
		fh.puts ARGV[1]
	}
	true
}
