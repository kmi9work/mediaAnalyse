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
f_links = File.open "links_russia.txt", 'w+'
f_sections = File.open "sections_russia.txt", 'w+'

meteo_ids = {}
links, sections = *get_links_sections('http://rp5.ru/%D0%9F%D0%BE%D0%B3%D0%BE%D0%B4%D0%B0_%D0%B2_%D0%A0%D0%BE%D1%81%D1%81%D0%B8%D0%B8')

sections.each do |section|
  print "get links..."
  puts section
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
puts "links collected. Count: #{links.size}. Time: #{links.size * 6} seconds."
i = 0
links.each do |key, value|
  i += 1
  print "Downloading #{i} from #{links.size}."
  begin
    puts value
    f_ids = File.open('ids_krasnoyarsky_dist.txt', 'a+')
    sleep(2)
    while true
      begin
        doc = Nokogiri::HTML(open(URI::encode value))
        break
      rescue
        puts "Error in open url. 2"
        sleep(rand(50) + 100)
      end
    end
    print "."
    puts archive_link = doc.at_css('#archive_link')['href']
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
    puts "."
    puts meteo_ids[key] = doc.at_css('div.archButton')['onclick'].match(/fconfirm\(\d+,(\d+)\)/)[1]
    coord = doc.at_xpath('//*[@id="content"]/script').content.match(/latitude=(\d+(\.\d+)?)&longitude=(\d+(\.\d+)?)&/)
    f_ids.puts "#{key};#{meteo_ids[key]};#{coord[1]};#{coord[3]}"
    f_ids.close
  rescue
    puts "------"
    puts "Error in #{key} => #{value.to_s}"
    puts "======"    
    next
  end
end


# content > script

# latitude=45.05&longitude=39.033333333333&


puts 



# All sections (>>>)

# puts page.scan(/<div class="RuLinks">.*<a href="(.+?)">/)#\s*<\/a>\s*,\s*<\/b>/)#.*<a style="color:#000" href="(.+?)"><span class="ToWeather">.*/)
