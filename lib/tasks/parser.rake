# require 'net/http'
# require 'nokogiri'
# require 'iconv'

require 'nokogiri'
require 'open-uri'
require 'uri'

def get_links_sections url
  sleep(rand(3) + 2)
  while true
    begin
      doc = Nokogiri::HTML(open(url))
      break
    rescue
      my_logger.error "Error in open url. 1"
      sleep(rand(50) + 100)
    end
  end
  sections = []
  links = {}
  doc.css('table.countryMap a').each do |link|
    if link.content == ">>>"
      sections << 'http://rp5.ru' + link["href"]
      if links.key(sections.last)
        links.delete_if{|_, value| value == sections.last}
      end
    else
      links[link.content] = 'http://rp5.ru' + link["href"]
    end
  end
  sections.uniq!
  return [links, sections]
end

namespace :parse do
  desc "Parse rp5."
  task rp5: :environment do
    my_logger = Logger.new("#{Rails.root}/log/parser_rp5.log")

    f_links = File.open "#{Rails.root}/tmp/links_russia.txt", 'w+'
    f_sections = File.open "#{Rails.root}/tmp/sections_russia.txt", 'w+'

    meteo_ids = {}
    links, sections = *get_links_sections('http://rp5.ru/%D0%9F%D0%BE%D0%B3%D0%BE%D0%B4%D0%B0_%D0%B2_%D0%A0%D0%BE%D1%81%D1%81%D0%B8%D0%B8')

    sections.each do |section|
      my_logger.info "get links... #{section}"
      l, s = *get_links_sections(URI::encode section)
      links.merge!(l)
      unless s.empty?
        s.each do |sect|
          ln, ss = *get_links_sections(URI::encode sect)
          links.merge!(ln)
        end
      end
    end
    # sleep(1)



    f_links.puts links.values
    my_logger.info "links collected. Count: #{links.size}. Time: #{links.size * 6} seconds."
    i = 0
    links.each do |key, value|
      i += 1
      my_logger.info  "Downloading #{i} from #{links.size}."
      begin
        my_logger.info value
        f_ids = File.open("#{Rails.root}/tmp/ids_russia.txt", 'a+')
        sleep(2)
        while true
          begin
            doc = Nokogiri::HTML(open(URI::encode value))
            break
          rescue
            my_logger.error "Error in open url. 2"
            sleep(rand(50) + 100)
          end
        end
        my_logger.debug archive_link = doc.at_css('#archive_link')['href']
        sleep(rand(3) + 2)
        while true
          begin
            doc = Nokogiri::HTML(open(URI::encode archive_link))
            break
          rescue
            puts "Error in open url. 3"
            sleep(rand(50) + 100)
          end
        end

        my_logger.debug meteo_ids[key] = doc.text.match(/statist_fconfirm\(\d+, \'?(\d+)'?\)/)[1]
        
        coord = doc.at_css('#leftNavi div span:nth-child(2) a')['onclick'].match(/show_map\((\d+(\.\d+)?), (\d+(\.\d+)?),/)
        states = []
        doc.css('nobr').each do |state|
          states << state.content
        end
        f_ids.puts "#{key};#{meteo_ids[key]};#{coord[1]};#{coord[3]};#{states.join(';')}"
        f_ids.close
      rescue

        my_logger.error "------"
        my_logger.error "Error in #{key} => #{value.to_s}"
        my_logger.error "======"    
        next
      end
    end
  end
end

# content > script

# latitude=45.05&longitude=39.033333333333&




# All sections (>>>)

# puts page.scan(/<div class="RuLinks">.*<a href="(.+?)">/)#\s*<\/a>\s*,\s*<\/b>/)#.*<a style="color:#000" href="(.+?)"><span class="ToWeather">.*/)
