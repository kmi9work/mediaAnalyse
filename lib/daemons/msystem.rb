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
require 'thread'
require 'thwait'

# require 'get_browser_texts.rb'

RICH_CONTENT_KEY = "rca.1.1.20140325T124443Z.4617706c8eb8ca49.f55bbec26c11f882a82500daa69448a3e80dfef9"

def send_email subject, body
  @my_logger.info "send_email"
  begin
    ActionMailer::Base.smtp_settings = {  
      :openssl_verify_mode => 'none'
    }
    ActionMailer::Base.mail(:from => "info@31.24.30.28", 
                          :to => "kmi9.other@gmail.com", 
                          :subject => subject, :body => body).deliver
  rescue Exception => e
    @my_logger.error "Send Email FAILED."
    @my_logger.error e.message
    @my_logger.error e.backtrace.join("\n")
  end
end

def s k
  if k >= 0
    sleep(rand(k * 100)/100.0 + rand(100)/100.0)
  else
    sleep(rand(100 + k)/100.0)
  end
end

def get_link_content logger, link, def_title = ""
  logger.debug "Getting rich content."
  yandex_rich_url = "http://rca.yandex.com/?key=#{RICH_CONTENT_KEY}&url=#{URI.escape(link)}&content=full"
  text = open_url(logger, yandex_rich_url)
  s -50
  unless text.blank?
    begin
      rich_ret = JSON.parse(text)
    rescue Exception => e
      logger.error "RCA json parse failed."
      logger.error e.message
      logger.error e.backtrace.join("\n")
      return [nil, nil]
    end
    return [rich_ret["title"] ? CGI.unescapeHTML(rich_ret["title"]) : def_title, rich_ret["content"] ? CGI.unescapeHTML(rich_ret["content"]) : ""]
  else
    logger.error "Can't download RCA: #{link}."
    return [nil, nil]
  end
end

def parse_rss logger, origin, text
  s 1
  logger.info "#{origin.title} parsing RSS..."
  texts = []
  feed = Feedjira::Feed.parse(text)
  if feed == 0 or (feed.class.parent != Feedjira::Parser)
    logger.info "Can't parse."
    str = "Text: #{text}\n\n"
    send_email "Can't parse in rss project.", "Can't parse text #{origin.origin_type}\nMessage:\n\n" + str
    return []
  end
  save_feeds = []
  return [] if feed.entries.blank?
  logger.info "#{origin.title}: Texts: #{feed.entries.count}"
  feed.entries.each do |f|
    guid = f.entry_id || f.url
    next unless Text.where({origin_id: origin.id, guid: guid}).blank?
    save_feeds << f
  end
  logger.info "#{origin.title}: New texts: #{save_feeds.count}"
  save_feeds.reverse_each do |f|
    t = NovelText.new
    t.origin = origin
    t.title = ActionView::Base.full_sanitizer.sanitize(f.title || '').gsub(/[^\u{0}-\u{128}\u{0410}-\u{044F}ёЁ]/, '')
    t.description = ActionView::Base.full_sanitizer.sanitize(f.summary || '').gsub(/[^\u{0}-\u{128}\u{0410}-\u{044F}ёЁ]/, '')
    t.author = ActionView::Base.full_sanitizer.sanitize(f.author || '')
    t.guid = ActionView::Base.full_sanitizer.sanitize(f.entry_id || f.url || '') 
    t.url = ActionView::Base.full_sanitizer.sanitize(f.url || '')
    t.datetime = f.published || DateTime.now
    t.origin_id = origin.id
    t.content = ActionView::Base.full_sanitizer.sanitize(f.try(:content) || "").gsub(/[^\u{0}-\u{128}\u{0410}-\u{044F}ёЁ]/, '')
    texts << t if !t.content.blank? or !t.title.blank? or !t.description.blank? or !t.url.blank?
  end
  return texts
rescue Feedjira::NoParserAvailable => e
  logger.error "93: FATAL ERROR! --- #{e.message} ---"
  logger.error e.backtrace.join("\n")
  logger.info "Can't parse."
  str = "Text: #{text}\n\n" + e.message + "\n" + e.backtrace.join("\n")
  logger.info "Text: #{text}"
  logger.info "------------------------------------"
  send_email "Can't parse in rss project.", "parse_rss: Can't parse text #{origin.origin_type}\nMessage:\n\n" + str
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
  logger.info "#{origin.title} parsing vk_api..."
  s 1
  texts = []
  begin
    resp = JSON.parse text
  rescue Exception => e
    logger.error "Can't parse vk_api --- #{e.message} ---"
    logger.error e.backtrace.join("\n")
    logger.info "Can't parse."
    str = "Text: #{text}\n\n" + e.message + "\n" + e.backtrace.join("\n")
    send_email "Can't parse in msystem project.", "vk_api: Can't parse text #{origin.origin_type}\nMessage:\n\n" + str
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
      t = NovelText.new
      t.origin = origin
      t.title = ""
      t.content = (f['text'] || "").gsub(/[^\u{0}-\u{128}\u{0410}-\u{044F}ёЁ]/, '')
      t.author = ""
      t.url = 'https://vk.com/wall' + f['owner_id'].to_s + "_" + f['id'].to_s
      t.guid = t.url
      t.origin_id = origin.id
      t.datetime = f['date'] ? Time.at(f['date'].to_i).to_datetime : DateTime.now
      texts << t unless t.content.blank?
    end
  end
  return texts
end

def parse_xml logger, origin, text
  texts = []
  if origin.origin_type =~ //
    #there is nothing yet
  end
  return texts
end

def parse_json logger, origin, text
  texts = []
  if origin.origin_type =~ /vk_api/
    texts = parse_vk_api logger, origin, text
  end
  return texts
end

def open_url_curb logger, link
  i = 0
  text = nil
  while (i += 1 ) <= 2
    begin
      easy = Curl::Easy.new
      easy.follow_location = true
      easy.max_redirects = 3 
      easy.url = link
      easy.useragent = "Ruby/Curb"
      Timeout.timeout(30) do   
        easy.perform
      end
      if easy.header_str =~ /Content-Encoding: gzip/
        text = ActiveSupport::Gzip.decompress(easy.body_str)
      else
        text = easy.body_str
      end
      i += 100
    rescue StandardError, Curl::Err::CurlError, Timeout::Error => e
      text = nil
      k = rand(5) + 5
      logger.error "#{link} was not open. Sleep(#{k}). #{i}"
      logger.error e.message
      logger.error ''
      sleep(k)
    rescue IO::EAGAINWaitReadable, Exception => e
      text = nil
      str = "URL: #{link}\n\n" + e.message + "\n\n" + e.backtrace.join("\n")
      send_email "Fatal error in rss parser.", "Fatal error in open_url_curb (#{link}) inside rss project.\nMessage:\n\n" + str
      logger.error "FATAL ERROR! --- #{e.message} ---"
      logger.error e.backtrace.join("\n")
      logger.error "============================================"
      s 10
    ensure
      easy.close
    end
  end
  return text
end

def open_url logger, url, url_query_pos = -1, insert_text = ""
  link = URI.escape url.dup.insert(url_query_pos || -1, insert_text)
  return open_url_curb logger, link
end

def parse logger, origin, text
  texts = []
  if origin.origin_type =~ /rss/
    texts = parse_rss(logger, origin, text)
  elsif origin.origin_type =~ /xml/
    texts = parse_xml(logger, origin, text)
  elsif origin.origin_type =~ /json/
    texts = parse_json(logger, origin, text)
  else
    texts = []
    #There is no parser yet
  end  
  return texts
end

def get_emot logger, title, content
  s -50
  t = title || ""
  c = content || ""
  query = {"text" => t + "\n" + c}
  uri = URI('http://emot.zaelab.ru/analyze.json')
  begin
    response = Net::HTTP.post_form(uri, query)
    overall = JSON.parse(response.body)['overall']
  rescue StandardError, Timeout::Error => e
    s 1
    return nil
  rescue Exception => e
    s 1
    return nil
  end
  return overall
end


def fill_and_save logger, texts
  texts.each do |text|
    if Text.where(guid: text.guid).blank?
      t = Text.new
      t.title = text.title
      t.description = text.description
      t.content = text.content
      t.author = text.author
      t.url = text.url
      t.guid = text.guid
      t.origin_id = text.origin_id
      t.datetime = text.datetime
      if t.origin_type =~ /rca/
        t.content = get_link_content(logger, t.url)[1]
      end
      t.emot = get_emot(logger, t.title, (t.content.presence || t.description)) if t.emot.blank?
      t.save
    end
  end
end

def fill_and_add_to_query logger, query, texts
  count = 0
  texts.each do |text|
    if (t = Text.where(guid: text.guid).try(:first)).blank?
      t = Text.new
      t.title = text.title
      t.description = text.description
      t.content = text.content
      t.author = text.author
      t.url = text.url
      t.guid = text.guid
      t.origin_id = text.origin_id
      t.datetime = text.datetime
      if t.origin_type =~ /rca/
        t.content = get_link_content(logger, t.url)[1]
      end
      t.emot = get_emot(logger, t.title, (t.content.presence || t.description)) if t.emot.blank?
      t.queries << query
      t.save
      count += 1
    else
      t.queries << query if t.queries.blank? or !t.queries.include?(query)
      t.save
    end
  end
  return count
end

def save_other logger, origin, texts
  logger.info "save_other Texts: #{texts.count}"
  count = 0
  texts.each do |t|
    t.origin = origin
    count += 1 if t.save
  end
  return count
end

def start_work origins, logger
  t = Time.now
  while Time.now - t < 600
    begin
      origins.reload
      origins.each do |origin|
        unless origin.destroyed?
          logger.info "#{origin.title} processing..."
          if origin.origin_type =~ /search/
            origin.queries.each do |query|
              query.keyphrases.each do |keyphrase|
                text = open_url logger, origin.url, origin.query_position, keyphrase.body
                unless text.blank?
                  if origin.origin_type =~ /cp1251/
                    text.force_encoding('WINDOWS-1251')
                  end
                  texts = parse logger, origin, text
                  n = fill_and_add_to_query(logger, query, texts)
                  logger.info "#{origin.title} - #{query.title} - #{keyphrase.body}: #{n} saved."
                else
                  logger.error "#{origin.title} - #{query.title} - #{keyphrase.body}: Text is empty."
                end
                s 3
              end
            end
          else
            text = open_url logger, origin.url
            unless text.blank?
              if origin.origin_type =~ /cp1251/
                text.force_encoding('WINDOWS-1251')
              end
              texts = parse logger, origin, text
              n = save_other(logger, origin, texts)
              logger.info "#{origin.title}: #{n} saved."
            end
          end #if origin.origin_type =~ /search/
          s 2
        end
      end
      s 60
    rescue Exception => e
      str = "Thread: #{Thread.current.thread_variable_get(:thread_number)};\n" + e.message + "\n\n" + e.backtrace.join("\n")
      send_email "Fatal error in msystem.", "Fatal error in start_work inside msystem.\nMessage:\n\n" + str
      @my_logger.error "FATAL ERROR! --- #{e.message} --- Thread: #{Thread.current.thread_variable_get(:thread_number)};"
      @my_logger.error e.backtrace.join("\n")
      @my_logger.error "============================================"
    end
  end
end
def add_to_file root, str
  f = File.open("#{root}/tmp/memusage.csv", 'a+')
  f.print str
  f.close
end

# ----------------------------- BEGIN -----------------------------
ENV["RAILS_ENV"] ||= "production"
NTHREADS = 1

root = File.expand_path(File.dirname(__FILE__))
root = File.dirname(root) until File.exists?(File.join(root, 'config'))
Dir.chdir(root)
@my_logger = Logger.new("#{root}/log/monitoring.log")
@my_logger.formatter = proc do |severity, datetime, progname, msg|
  "#{datetime.strftime('%d.%m %H:%M:%S')} -#{severity}-: #{msg}\n"
end
require File.join(root, "config", "environment")

while true
  begin
    time_spent = Time.now
    origins = Origin.where.not(origin_type: 'browser')
    origins_browser = Origin.where(origin_type: 'browser')
    @my_logger.info "Still monitoring... Origins: #{origins.count}; Origins Browser: #{origins_browser.count};"
    #Отдельно работаем с источниками browser, т.к. у них свои ограничения
    threads = []
    loggers = []
    if NTHREADS == 1
      logger = Logger.new("#{root}/log/monitoring_0.log")
      logger.formatter = proc do |severity, datetime, progname, msg|
        "#{datetime.strftime('%d.%m %H:%M:%S')} -#{severity}-: #{msg}\n"
      end
      logger.info "------------------ STARTED. ------------------"
      Thread.current.thread_variable_set(:thread_number, 0)
      start_work(origins, logger)
      logger.info "------------------ COMPLITED. ------------------"
    elsif origins.count > NTHREADS
      for i in 0...NTHREADS
        torigins = origins[i*(origins.count-1)/NTHREADS..(i+1)*(origins.count-1)/NTHREADS] 
        loggers << Logger.new("#{root}/log/monitoring_#{i}_#{i*(origins.count-1)/NTHREADS}_#{(i+1)*(origins.count-1)/NTHREADS}.log")
        loggers.last.formatter = proc do |severity, datetime, progname, msg|
          "#{datetime.strftime('%d.%m %H:%M:%S')} -#{severity}-: #{msg}\n"
        end
        # Разбиваем источники по потокам.
        threads << Thread.new(torigins, loggers.last) do |to, logger|
          Thread.current.thread_variable_set(:thread_number, i)
          logger.info "STARTED."
          start_work(to, logger)
          logger.info "COMPLITED."
        end
      end
    else
      origins.each_with_index do |origin, i|
        loggers << Logger.new("#{root}/log/monitoring_#{i}.log")
        # Разбиваем источники по потокам.
        threads << Thread.new([origin], loggers.last) do |to, logger|
          Thread.current.thread_variable_set(:thread_number, i)
          start_work(to, logger)
        end
      end
    end
    @my_logger.info "Waiting threads..."
    threads.each(&:join)
    @my_logger.info "Threads done."
    
    
    # Прошло 12 минут. Теперь отсеиваем нужные тексты.
    NovelText.index.import NovelText.all
    Query.all.each do |query|
      texts = NovelText.select_for_query query
      fill_and_add_to_query @my_logger, query, texts
    end
    fill_and_save @my_logger, NovelText.all
    NovelText.all.each(&:destroy)
    GC.start
    memory_usage = `ps -o rss= -p #{$$}`
    add_to_file root, "#{memory_usage}\n"
    @my_logger.info "Step takes: #{Time.now - time_spent}s of 720s; Sleeping."
    sleep 120
  rescue Exception => e
    str = e.message + "\n\n" + e.backtrace.join("\n")
    send_email "Fatal error in msystem.", "Fatal error in root inside msystem.\nMessage:\n\n" + str
    @my_logger.error "FATAL ERROR! --- #{e.message} ---"
    @my_logger.error e.backtrace.join("\n")
    @my_logger.error "============================================"
  end
end
