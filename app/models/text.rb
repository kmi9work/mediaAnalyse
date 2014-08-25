require 'net/http'

class Text < ActiveRecord::Base
	belongs_to :query
	belongs_to :search_engine
  belongs_to :origin
	has_many :essences

  searchable do
    text :title, :description, :content
    integer :origin_id
  end

	def Text.source(ids)
		where(search_engine_id: ids)
	end

  def Text.source_text(ses)
    ids = SearchEngine.source(ses).map(&:id)
    where(search_engine_id: ids)
  end  

	def Text.from_to from, to
    if from and to
      f = DateTime.strptime(from + " +0400", "%d.%m.%Y %H:%M %Z")
      t = DateTime.strptime(to + " +0400", "%d.%m.%Y %H:%M %Z")
      return where(created_at: f..t).load
    elsif from
      return where('created_at > ?', DateTime.strptime(from + " +0400", "%d.%m.%Y %H:%M %Z").in_time_zone(Time.zone)).load
    elsif to
      return where('created_at < ?', DateTime.strptime(to + " +0400", "%d.%m.%Y %H:%M %Z").in_time_zone(Time.zone)).load
    else
      return where('created_at > ?', DateTime.now.beginning_of_day).load
    end
  end

  def Text.from_to_date from, to
    return where(created_at: from..to).load
  end

  

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
