# encoding: utf-8
BOUNDARY = 'naeburaxurkbxrcubxkrcbxrgapbxurcbpucbiuhxbs4409573940985672064'

require 'html2markdown'
require 'htmlentities'

def make_mime(meta, item)
	item[:author] ||= meta[:author] if meta[:author]
	if meta[:logo]
		item[:author] ||= {}
		item[:author][:logo] ||= meta[:logo]
	end
	item[:author][:photo] ||= item[:author][:logo] if item[:author] && item[:author][:logo]

	r = 'From '
	if item[:author][:email]
		r << item[:author][:email]
	end
	r << ' ' << item[:published].rfc2822 << "\n"

	r = ''

	r << "Message-ID: <#{item[:id] || item[:bookmark] || "#{Time.now.to_i}@no-id.example.com"}>\n"
	r << "Subject: #{(item[:title].to_s != '' ? item[:title] : (HTMLEntities.decode_entities(item[:content].gsub(/<[^>]*>/, ''))[0,50] + '…')).gsub(/\s/, ' ')}\n"
	r << "Content-Location: <#{item[:bookmark]}>\n" if item[:bookmark]
	r << "From: \"#{item[:author][:fn]}\" <#{item[:author][:email]}>\n"
	r << "X-URL: #{item[:author][:url]}\n" if item[:author][:url]
	r << "X-Image-URL: #{item[:author][:photo]}\n" if item[:author][:photo]
	r << "Date: #{item[:published].rfc2822}\n"

	(item[:in_reply_to] || []).each do |parent|
		r << "In-Reply-To: <#{parent[:ref]}>\n" if parent[:ref]
		r << "In-Reply-To: <#{parent[:href]}>\n" if parent[:href]
	end

	r << "X-Originally-From: \"#{meta[:title]}\" <#{meta[:self]}>\n"

	r << "Content-Type: multipart/alternative; boundary=#{BOUNDARY}\n"
	r << "Content-Transfer-Encoding: 8bit\n"

	r << "\n"

	
	r << "--#{BOUNDARY}\n"
	r << "Content-Type: text/plain; charset=utf-8\n"
	r << "Content-Transfer-Encoding: 8bit\n"
	r << "\n"
	r << HTML2Markdown.new(item[:content].to_s.force_encoding('utf-8').gsub(/\s+/, ' ')).to_s.sub(/^\n*/, '').sub(/\n*$/, '')

	r << "\n\n"
	
	r << "--#{BOUNDARY}\n"
	r << "Content-Type: text/html; charset=utf-8\n"
	r << "Content-Transfer-Encoding: 8bit\n"
	r << "\n"
	r << item[:content].to_s

	r << "\n\n"

	r << "--#{BOUNDARY}\n"
	r << "Content-Type: application/xml; charset=utf-8\n"
	r << "Content-Transfer-Encoding: 8bit\n"
	r << "\n"
	r << item[:xml].to_s
end
