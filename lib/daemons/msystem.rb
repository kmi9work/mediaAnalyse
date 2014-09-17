# *** MONITORING SYSTEM ***

# require 'selenium-webdriver'
# require 'headless'
require 'rss'
require 'logger'
require 'rails'
require 'open-uri'
require 'feedjira'
require 'curb'
require 'timeout'

# require 'get_browser_texts.rb'

RICH_CONTENT_KEY = "rca.1.1.20140325T124443Z.4617706c8eb8ca49.f55bbec26c11f882a82500daa69448a3e80dfef9"

def send_email subject, body
  @my_logger.info "send_email"
  begin
    ActionMailer::Base.smtp_settings = {  
      :openssl_verify_mode => 'none'
    }
    ActionMailer::Base.mail(:from => "info@msystem2.amchs.ru", 
                          :to => "kmi9.other@gmail.com", 
                          :subject => subject, :body => body).deliver
  rescue
    @my_logger.error "Send Email FAILED."
  end
end

def s k
  if k >= 0
    sleep(rand(k * 100)/100.0 + rand(100)/100.0)
  else
    sleep(rand(100 + k)/100.0)
  end
end

def get_link_content link, def_title = ""
  @my_logger.debug "Getting rich content."
  yandex_rich_url = "http://rca.yandex.com/?key=#{RICH_CONTENT_KEY}&url=#{URI.escape(link)}&content=full"
  doc = open_url(yandex_rich_url, "URL: #{link}")
  s -50
  if (doc)
    doc = doc.readlines.join
    rich_ret = JSON.parse(doc)
    return [rich_ret["title"] ? CGI.unescapeHTML(rich_ret["title"]) : def_title, rich_ret["content"] ? CGI.unescapeHTML(rich_ret["content"]) : ""]
  else
    @my_logger.debug "Can't download #{link}. -----------------"
    return nil
  end
end

def select_texts texts, queries
  #here You should choose only texts according quieries.
  return texts.count
end

def parse_rss logger, origin, text
  texts = []
  logger.info "get_rss_texts URL: #{origin.rss_url}"
  feed = Feedjira::Feed.parse(text)
  if feed == 0 or (feed.class.parent != Feedjira::Parser)
    logger.info "Can't parse."
    str = "Text: #{text}\n\n"
    send_email "Can't parse in rss project.", "Can't parse text #{origin.type}\nMessage:\n\n" + str
    return texts
  end
  save_feeds = []
  feed.entries.each do |f|
    guid = f.entry_id || f.url
    break unless Text.where({origin_id: origin.id, guid: guid}).blank?
    save_feeds << f
  end
  logger.info "#{origin.title}: New texts: #{save_feeds.count}"
  
  save_feeds.reverse_each do |f|
    t = Text.new
    t.origin = origin
    t.title = ActionView::Base.full_sanitizer.sanitize(f.title || '')
    t.description = ActionView::Base.full_sanitizer.sanitize(f.summary || '')
    t.author = ActionView::Base.full_sanitizer.sanitize(f.author || '')
    t.guid = ActionView::Base.full_sanitizer.sanitize(f.entry_id || f.url) 
    t.url = ActionView::Base.full_sanitizer.sanitize(f.url)
    t.datetime = f.published || DateTime.now
    #t.content = f.content || "" ???
    texts << t if !t.content.blank? or !t.title.blank? or !t.description.blank? or !t.url.blank?
  end
  return texts
rescue Feedjira::NoParserAvailable => e
  logger.error "FATAL ERROR! --- #{e.message} ---"
  logger.error e.backtrace.join("\n")
  logger.info "Can't parse."
  str = "Text: #{text}\n\n" + e.message + "\n" + e.backtrace.join("\n")
  send_email "Can't parse in rss project.", "parse_rss: Can't parse text #{origin.type}\nMessage:\n\n" + str
  return []
rescue Exception => e
  str = "Origin: #{origin.title}\n\n" + e.message + "\n\n" + e.backtrace.join("\n")
  send_email "Fatal error in msystem project.", "Fatal error in parse_rss inside msystem project.\nMessage:\n\n" + str

  logger.error "FATAL ERROR! --- #{e.message} ---"
  logger.error e.backtrace.join("\n")
  logger.error "============================================"
  s 10
  return []
end

def parse_vk_api logger, origin, text
  texts = []
  begin
    resp = JSON.parse text
  rescue Exception => e
    logger.error "Can't parse vk_api --- #{e.message} ---"
    logger.error e.backtrace.join("\n")
    logger.info "Can't parse."
    str = "Text: #{text}\n\n" + e.message + "\n" + e.backtrace.join("\n")
    send_email "Can't parse in msystem project.", "vk_api: Can't parse text #{origin.type}\nMessage:\n\n" + str
    return []
  end
  if resp['response']
    save_feeds = []
    for i in 1...resp['response'].size
      f = resp['response'][i]
      link = 'https://vk.com/wall' + f['owner_id'].to_s + "_" + f['id'].to_s
      guid = link
      break unless Text.where({origin_id: origin.id, guid: guid}).blank?
      save_feeds << f
    end
    logger.info "#{origin.title}: New texts: #{save_feeds.count}"
    save_feeds.reverse_each do |f|
      t = Text.new
      t.origin = origin
      t.title = ""
      t.content = f['text'] || ""
      t.author = ""
      t.url = 'https://vk.com/wall' + f['owner_id'].to_s + "_" + f['id'].to_s
      t.guid = t.url
      t.datetime = DateTime.now
      texts << t unless t.content.blank?
    end
  end
  return texts
end

def parse_xml logger, origin, text
  texts = []
  if origin.type =~ //
    #there is nothing yet
  end
  return texts
end

def parse_json logger, origin, text
  texts = []
  if origin.type =~ /vk_api/
    texts = parse_vk_api logger, origin, text
  end
  return texts
end

def open_url_curb logger, link, text
  i = 0
  text = nil
  easy = Curl::Easy.new
  while (i += 1 ) <= 2
    begin
      easy.follow_location = true
      easy.max_redirects = 3 
      easy.url = url
      easy.useragent = "Ruby/Curb"
      Timeout.timeout(30) do   
        easy.perform
      end
      text = easy.body_str
      break
    rescue StandardError, Curl::Err::CurlError, Timeout::Error => e
      text = nil
      k = rand(5) + 5
      logger.error "#{url} was not open. Sleep(#{k}). #{i}"
      logger.error e.message
      logger.error err_text
      logger.error ''
      sleep(k)
    rescue IO::EAGAINWaitReadable, Exception => e
      str = "URL: #{url}\n\n" + e.message + "\n\n" + e.backtrace.join("\n")
      send_email "Fatal error in rss parser.", "Fatal error in open_url_curb (#{url}) inside rss project.\nMessage:\n\n" + str
      logger.error "FATAL ERROR! --- #{e.message} ---"
      logger.error e.backtrace.join("\n")
      logger.error "============================================"
      easy.close
      s 10
      return nil
    end
  end
  easy.close
  return text
end

def open_url logger, url, url_query_pos = -1, insert_text = ""
  link = URI.escape url.insert(url_query_pos || -1, insert_text)
  return open_url_curb logger, link
end

def parse logger, origin, text
  texts = []
  if origin.type =~ /rss/
    texts = parse_rss(logger, origin, type, text)
  elsif origin.type =~ /xml/
    texts = parse_xml(logger, origin, type, text)
  elsif origin.type =~ /json/
    texts = parse_json(logger, origin, type, text)
  else
    texts = []
    #There is no parser yet
  end  
  return texts
end

def select_texts logger, texts, query
  return []
end


def get_emot title, content
  s -50
  t = title || ""
  c = content || ""
  query = {"text" => t + "\n" + c}
  uri = URI('http://emot.zaelab.ru/analyze.json')
  begin
    response = Net::HTTP.post_form(uri, query)
  rescue StandardError, Timeout::Error => e
    s 1
  end
  return JSON.parse(response.body)['overall']
end


def fill_and_save logger, origin, query, texts
  if origin.group != 1917
    texts.each do |t|
      if origin.type =~ /rca/
        t.content = get_link_content(t.url)[1]
      end
      t.emot = get_emot t.title, (t.content.presence || t.description)
      t.origin = origin
      t.query = query
      t.save
    end
  else
    texts.each do |t|
      t.origin = origin
      t.query = query
      t.save
    end
  end
end

def start_work origins, logger
  t = Time.now
  while Time.now - t < 1800
    origins.each do |origin|
      if origin.type =~ /search/
        origin.queries.each do |query|
          text = open_url logger, origin.url, origin.url_query_pos, query.body
          unless text.blank?
            texts = parse logger, origin, text
            fill_and_save(logger, texts, origin, query)
          end
        end
      else
        text = open_url logger, origin.url
        unless text.blank?
          texts = parse logger, origin, text
          origin.queries.each do |query|
            tt = select_texts(logger, origin, texts, query)
            fill_and_save(logger, origin, query, tt)
            fill_and_save(logger, origin, nil, texts - tt)
          end
        end
      end #if origin.type =~ /search/
    end
    s 60
  end
end

# ----------------------------- BEGIN ------------------------------------
ENV["RAILS_ENV"] ||= "production"
NTHREADS = 4

root = File.expand_path(File.dirname(__FILE__))
root = File.dirname(root) until File.exists?(File.join(root, 'config'))
Dir.chdir(root)

@my_logger = Logger.new("#{root}/log/rsser.log")

require File.join(root, "config", "environment")

while true
  origins = Origin.where.not(type: 'browser')
  origins_browser = Origin.where(type: 'browser') 
  #Отдельно работаем с источниками browser, т.к. у них свои ограничения
  threads = []
  loggers = []
  for i in 0...NTHREADS
    torigins = origins[i*(origins.count-1)/NTHREADS..(i+1)*(origins.count-1)/NTHREADS] 
    loggers << Logger.new("#{root}/log/monitoring_#{i}_#{origins.count-1)/NTHREADS}_#{(i+1)*(origins.count-1)/NTHREADS}.log")
    # Разбиваем источники по потокам.
    threads << Thread.new do
      start_work(torigins, loggers.last)
    end
  end
  ThreadsWait.all_wait(*threads)
  GC.start
  s 20
end

# ----------------------------- END ------------------------------------

=begin
origins.each do |origin|
  if type == :rss
    thr_rss = Thread.new do
      while (true) do
        otracked = otyped #.where('tracked_count > 0') ??? Пока не нужны, т.к. для каждого запроса в одном типе парсятся все источники
        @my_logger_rss.info "----------------------"
        @my_logger_rss.info "Still parsing RSS's. Count: #{otracked.count}"
        count_rss = 0
        selected_rss = 0
        otracked.each do |o|
          texts = get_rss_texts o
          count_rss += texts.count
          selected_rss += select_texts(texts, o.quieries) #save is inside. returns count selected
        end
        @my_logger_rss.info "=== New messages: #{count_rss} | Selected: #{selected_rss}==="
        GC.start
        s 50
      end
    end
  elsif type == :api
    thr_api = Thread.new do
      while (true) do
        otracked = otyped #.where('tracked_count > 0') ???
        @my_logger_api.info "----------------------"
        @my_logger_api.info "Still parsing API's. Count: #{otracked.count}"
        count_api = 0
        otracked.each do |o|
          count_api += get_api_texts o
        end
        @my_logger_api.info "=== New messages: #{count_api} ==="
        GC.start
        s 50
      end
    end
  elsif type == :browser
    next
    # thr_browser = Thread.new do
    #   if Rails.env.production?
    #     headless = Headless.new
    #     headless.start
    #     logger.info "Headless started."
    #   end
    #   wait = Selenium::WebDriver::Wait.new(:timeout => 60)
    #   browsers = {}
    #   while (true) do
    #     otracked = otyped #.where('tracked_count > 0') ???
    #     @my_logger_browser.info "----------------------"
    #     @my_logger_browser.info "Still parsing Browser's. Count: #{otracked.count}"
    #     count_browser = 0
    #     otracked.each do |o|
    #       count_browser += get_browser_texts o
    #     end
    #     @my_logger_browser.info "=== New messages: #{count_browser} ==="
    #     GC.start
    #     s 500
    #   end
    # end
  end
end
=end