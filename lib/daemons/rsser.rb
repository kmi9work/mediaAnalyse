require 'rss'
require 'logger'
require 'rails'
require 'open-uri'
require 'feedjira'
require 'curb'
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
  @my_logger.info "s"
  if k >= 0
    sleep(rand(k * 100)/100.0 + rand(100)/100.0)
  else
    sleep(rand(100 + k)/100.0)
  end
end

def open_url url, err_text = ""
  @my_logger.info "open_url"
  i = 0
  doc = nil
  while (i += 1 ) <= 2
    begin
      if (url =~ /https/)
        doc = open(url, {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE})
      else
        doc = open(url)
      end
      break
    rescue StandardError, Timeout::Error => e
      doc = nil
      k = rand(5) + 5
      @my_logger.error "#{url} was not open. Sleep(#{k}). #{i}"
      @my_logger.error e.message
      @my_logger.error err_text
      @my_logger.error ''
      # ОБРАБОТАТЬ ПРАВИЛЬНО ОШИБКИ
      sleep(k)
    rescue IO::EAGAINWaitReadable, Exception => e
      str = "Origin: #{origin.title}\n\n" + e.message + "\n\n" + e.backtrace.join("\n")
      send_email "Fatal error in rss project.", "Fatal error in open_url (#{url}) inside rss project.\nMessage:\n\n" + str
      @my_logger.error "FATAL ERROR! --- #{e.message} ---"
      @my_logger.error e.backtrace.join("\n")
      @my_logger.error "============================================"
      s 10
      return nil
    end
  end
  return doc
end

def open_url_curb url, err_text = ""
  @my_logger.info "open_url_curb"
  i = 0
  doc = nil
  while (i += 1 ) <= 2
    begin
      easy = Curl::Easy.new
      easy.follow_location = true
      easy.max_redirects = 3 
      easy.connect_timeout = 120
      easy.dns_cache_timeout = 120
      easy.url = url
      easy.useragent = "Ruby/Curb"
      easy.perform
      doc = easy.body_str
      break
    rescue StandardError, Curl::Err::CurlError, Timeout::Error => e
      doc = nil
      k = rand(5) + 5
      @my_logger.error "#{url} was not open. Sleep(#{k}). #{i}"
      @my_logger.error e.message
      @my_logger.error err_text
      @my_logger.error ''
      # ОБРАБОТАТЬ ПРАВИЛЬНО ОШИБКИ
      sleep(k)
    rescue IO::EAGAINWaitReadable, Exception => e
      str = "Origin: #{origin.title}\n\n" + e.message + "\n\n" + e.backtrace.join("\n")
      send_email "Fatal error in rss project.", "Fatal error in open_url (#{url}) inside rss project.\nMessage:\n\n" + str
      @my_logger.error "FATAL ERROR! --- #{e.message} ---"
      @my_logger.error e.backtrace.join("\n")
      @my_logger.error "============================================"
      s 10
      return nil
    end
  end
  return doc
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

def get_emot title, content
    @my_logger.info "get_emot"
    s -50
    t = title || ""
    c = content || ""
    query = {"text" => t + "\n" + c}
    uri = URI('http://emot.zaelab.ru/analyze.json')
    begin
      response = Net::HTTP.post_form(uri, query)
    rescue StandardError, Timeout::Error => e
      s 10
      @my_logger.error "Can't connect to emot.zaelab.ru. Retrying..."
      return get_emot title, content
    end
    return JSON.parse(response.body)['overall']
  end

def get_texts origin
    @my_logger.info "get_texts"
  # Origin.find(10).texts.each{|i| i.title = i.title.encode('WINDOWS-1251').force_encoding('UTF-8'); i.save}

    i = 0
    ret = 0
    @my_logger.info origin.rss_url
    while (i += 1) <= 3
      # if origin.rss_url == 'http://www.pravda.com.ua/rus/rss/'
      #   text.encode!('WINDOWS-1251').force_encoding('UTF-8')
      # end
      @my_logger.info "before fetch_and_parse"
      text = open_url_curb origin.rss_url
      return 0 if text.blank?
      feed = Feedjira::Feed.parse(text)
      @my_logger.info "after fetch_and_parse"
      return 0 if feed == 0 or feed.class != Feedjira::Parser::RSS
      save_feeds = []
      last = origin.texts.order(:datetime).last
      feed.entries.each do |f|
        guid = f.entry_id || f.url
        break unless Text.where(guid: guid).blank?
        save_feeds << f
      end
      ret += save_feeds.count
      @my_logger.info "#{origin.title}: New texts: #{save_feeds.count}"
      save_feeds.reverse_each do |f|
        t = Text.new
        t.origin = origin
        t.title = ActionView::Base.full_sanitizer.sanitize(f.title || '')
        t.description = ActionView::Base.full_sanitizer.sanitize(f.summary || '')
        t.author = ActionView::Base.full_sanitizer.sanitize(f.author || '')
        t.guid = ActionView::Base.full_sanitizer.sanitize(f.entry_id || f.url) 
        t.url = ActionView::Base.full_sanitizer.sanitize(f.url)
        t.datetime = f.published || DateTime.now
        if origin.group != 1917
          if (arr = get_link_content(t.url, t.title))
            title, content = *arr
          else
            content = ""
          end
          t.content = content
          t.emot = get_emot t.title, t.description
        else
          t.content = ""
        end
        t.save if t.title or t.description or t.url
      end
      break
    end
    return ret
  rescue Feedjira::NoParserAvailable => e
    # осле трёх ошибок match origin as corrupted. 
    # And write to it resume_at = Time.now + 3600. Or Time.now + timeout. 
    # And make timeout greater. НО ЭТО НЕСТАБИЛЬНО.
    # Выводить в view сообщение о том, что источник сломан.
    @my_logger.error "FATAL ERROR! --- #{e.message} ---"
    @my_logger.error e.backtrace.join("\n")
    @my_logger.info "============================================"
    @my_logger.info text
    @my_logger.info "============================================"
    return 0
  rescue Exception => e
    str = "Origin: #{origin.title}\n\n" + e.message + "\n\n" + e.backtrace.join("\n")
    send_email "Fatal error in rss project.", "Fatal error in get_texts inside rss project.\nMessage:\n\n" + str

    @my_logger.error "FATAL ERROR! --- #{e.message} ---"
    @my_logger.error e.backtrace.join("\n")
    @my_logger.error "============================================"
    s 10
    return 0
  end

#!/usr/bin/env ruby

# You might want to change this
ENV["RAILS_ENV"] ||= "production"

root = File.expand_path(File.dirname(__FILE__))
root = File.dirname(root) until File.exists?(File.join(root, 'config'))
Dir.chdir(root)

if Rails.env.production?
  @my_logger = Logger.new("/home/web/public_html/msystem2/log/rsser.log")
else
  @my_logger = Logger.new("#{Rails.root}/log/rsser.log")
end

# @my_logger = Rails.logger
require File.join(root, "config", "environment")

while (true) do
  @my_logger.info "----------------------"
  @my_logger.info "Still parsing RSS's. Count: #{Origin.count}"
  count = 0
  Origin.all.each do |o|
    count += get_texts o
    s 5
  end
  @my_logger.info "=== New messages: #{count} ==="
  s 60
end
