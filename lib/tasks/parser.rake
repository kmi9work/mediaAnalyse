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
      puts "Error in open url. 1"
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

    f_links = File.open "#{Rails.root}/links_russia.txt", 'w+'
    f_sections = File.open "#{Rails.root}/sections_russia.txt", 'w+'

    meteo_ids = {}
    links, sections = *get_links_sections('http://rp5.ru/%D0%9F%D0%BE%D0%B3%D0%BE%D0%B4%D0%B0_%D0%B2_%D0%90%D0%B4%D1%8B%D0%B3%D0%B5%D0%B5')

    sections.each do |section|
      my_logger.debug "get links... #{section}"
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
    my_logger.debug "links collected. Count: #{links.size}. Time: #{links.size * 6} seconds."
    i = 0
    links.each do |key, value|
      i += 1
      my_logger.debug  "Downloading #{i} from #{links.size}."
      begin
        my_logger.debug value
        f_ids = File.open("#{Rails.root}/ids_russia.txt", 'a+')
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
        p doc.at_css('/html/body/script[6]').content

  # document.fmetar.metar.value = 'URKK';
  # changeTabMetar(3);
  # statist_fconfirm(1348585200, 4991, 'URKK');
  
  # document.fwmo.wmo_id.value = '37014';
  # changeTabSynop(2);
  # statist_fconfirm(1356998400, '37014');


        my_logger.debug meteo_ids[key] = doc.at_css('div.archButton')['onclick'].match(/statist_fconfirm\(\d+,(\d+)\)/)[1]
        
        coord = doc.at_css('#leftNavi div span:nth-child(2) a')['onclick'].match(/show_map\((\d+(\.\d+)?), (\d+(\.\d+)?),/)
        f_ids.puts "#{key};#{meteo_ids[key]};#{coord[1]};#{coord[3]}"
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
