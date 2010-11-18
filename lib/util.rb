# Eat nils
def an(o)
	if o.nil?
		Class.new {
			def method_missing(*args)
				nil
			end
		}.new
	else
		o
	end
end

# URI encode a string
def u(string)
	string.gsub(/([^a-zA-Z0-9_.-]+)/n) do
		'%' + $1.unpack('H2' * $1.size).join('%').upcase
	end
end

# Convert relative URI to absolute URI
def relative_to_absolute(uri, relative_to)
	return nil unless uri
	uri = URI::parse(uri) unless uri.is_a?(URI)
	relative_to = URI::parse(relative_to) unless relative_to.is_a?(URI)
	return uri if uri.scheme
	uri.scheme = relative_to.scheme
	uri.host = relative_to.host
	if uri.path.to_s[0,1] != '/'
		uri.path = "/#{uri.path}" unless relative_to.path[-1,1] == '/'
		uri.path = "#{relative_to.path}#{uri.path}"
	end
	uri
end

