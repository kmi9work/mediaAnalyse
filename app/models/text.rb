require 'net/http'

class Text < ActiveRecord::Base
  has_many :queries_texts, dependent: :destroy
  has_many :queries, through: :queries_texts
  belongs_to :origin
  has_many :essences

  include Tire::Model::Search
  include Tire::Model::Callbacks

  mapping do
    indexes :id,           index:    :not_analyzed
    indexes :title,        analyzer: 'snowball', boost: 100
    indexes :description,  analyzer: 'snowball', boost: 30
    indexes :content,      analyzer: 'snowball'
    indexes :novel,        type: 'boolean'
    indexes :origin_type
    indexes :emot,         as: 'my_emot || emot'
    indexes :datetime,     type: 'date', :include_in_all => false
  end

  def Text.search_novel query
    # tire.search(per_page: 1000000, load: true) do
    #   filtered do
    #     query { string query }
    #     filter :term, :novel => true
    #   end
    # end
  end

  def Text.search query
    tire.search(per_page: 1000000, load: true) do
      query { string query } if query.present?
    end.results
  end  

  def Text.select_novel_for_query query
    texts = []
    query.keyphrases.each do |kp|
      texts += Text.search_novel(kp.body).results
    end
    return texts
  end

  def Text.select_all_for_query query
    texts = []
    query.keyphrases.each do |kp|
      texts += Text.search(kp.body).results
    end
    return texts
  end

  def Text.from_to from, to
    if from and to
      f = DateTime.strptime(from + " +0400", "%d.%m.%Y %H:%M %Z")
      t = DateTime.strptime(to + " +0400", "%d.%m.%Y %H:%M %Z")
      return where(created_at: f..t)
    elsif from
      return where('created_at > ?', DateTime.strptime(from + " +0400", "%d.%m.%Y %H:%M %Z").in_time_zone(Time.zone))
    elsif to
      return where('created_at < ?', DateTime.strptime(to + " +0400", "%d.%m.%Y %H:%M %Z").in_time_zone(Time.zone))
    else
      return where('created_at > ?', DateTime.now.beginning_of_day)
    end
  end
  def Text.source source
    origins = Origin.where('origin_type like ?', "%source#{source}%")
    return where(origin_id: origins.map(&:id))
  end
  def Text.from_to_date from, to
    return where(created_at: from..to).load
  end

  def to_indexed_json
    to_json methods: [:origin_type]
  end

  def origin_type
    origin.try(:origin_type)
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
