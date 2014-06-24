require 'net/http'

class Text < ActiveRecord::Base
	has_and_belongs_to_many :queries
	has_many :essences
	def get_emot
		query = {"text" => title + "\n" + content}
		uri = URI('http://emot.zaelab.ru/analyze.json')
		response = Net::HTTP.post_form(uri, query)
		return JSON.parse(response.body)
	end

	def get_text
		if (html = open_url(self.url))
			doc = Nokogiri::HTML(html)	
			return doc.text
		else
			return nil
		end
	end
	private
	def open_url url, err_text = ""
		i = 0
		doc = nil
		while (i += 1 ) <= 3
			begin
				if (url =~ /https/)
					doc = open(url, {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE})
				else
					doc = open(url)
				end
				break
			rescue Exception => e
				doc = nil
				k = rand(10) + 5
				$stderr.puts "#{url} was not open. Sleep(#{k}). #{i}"
				$stderr.puts e.message 
				$stderr.puts err_text
				$stderr.puts 
				# ОБРАБОТАТЬ ПРАВИЛЬНО ОШИБКИ
				sleep(k)
			end
		end
		return doc
	end
end
