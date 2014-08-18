require 'rss'
require 'logger'
require 'rails'
require 'open-uri'
RICH_CONTENT_KEY = "rca.1.1.20140325T124443Z.4617706c8eb8ca49.f55bbec26c11f882a82500daa69448a3e80dfef9"

def send_email subject, body
  ActionMailer::Base.smtp_settings = {  
    :openssl_verify_mode => 'none' 
  }
  ActionMailer::Base.mail(:from => "info@msystem2.amchs.ru", 
                          :to => "kmi9.other@gmail.com", 
                          :subject => subject, :body => body).deliver
end

def s k
  if k >= 0
    sleep(rand(k * 100)/100.0 + rand(100)/100.0)
  else
    sleep(rand(100 + k)/100.0)
  end
end

def open_url url, err_text = ""
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
  # Origin.find(10).texts.each{|i| i.title = i.title.encode('WINDOWS-1251').force_encoding('UTF-8'); i.save}

    i = 0
    ret = 0
    @my_logger.info origin.rss_url
    while (i += 1) <= 3
      text = open_url(origin.rss_url).read
      # if origin.rss_url == 'http://www.pravda.com.ua/rus/rss/'
      #   text.encode!('WINDOWS-1251').force_encoding('UTF-8')
      # end

      feed = RSS::Parser.parse(text, false)
      save_feeds = []
      last = origin.texts.order(:datetime).last
      feed.items.each do |f|
        guid = f.guid.nil? ? f.link : f.guid.content || f.link
        break unless Text.where(guid: guid).blank?
        save_feeds << f
      end
      ret += save_feeds.count
      @my_logger.info "#{origin.title}: New texts: #{save_feeds.count}"
      save_feeds.reverse_each do |f|
        t = Text.new
        t.origin = origin
        t.title = ActionView::Base.full_sanitizer.sanitize (f.title || '') unless f.title.blank?
        t.description = ActionView::Base.full_sanitizer.sanitize (f.description || '') unless f.description.blank?
        t.author = ActionView::Base.full_sanitizer.sanitize (f.author || '') unless f.author.blank?
        t.guid = ActionView::Base.full_sanitizer.sanitize (f.guid.nil? ? f.link || '' : f.guid.content || f.link || '') 
        t.url = ActionView::Base.full_sanitizer.sanitize (f.link || '')
        t.datetime = f.pubDate || DateTime.now
        if origin.group != 1917
          if (arr = get_link_content(t.url, t.title))
            title, content = *arr
          else
            content = ""
          end
          t.content = content
        else
          t.content = ""
        end
        t.emot = get_emot t.title, t.description
        t.save
      end
      break
    end
    return ret
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

$running = true
Signal.trap("TERM") do 
  $running = false
end

while($running) do
  @my_logger.info "----------------------"
  @my_logger.info "Still parsing RSS's. Count: #{Origin.count}"
  count = 0
  Origin.all.each do |o|
    count += get_texts o
  end
  @my_logger.info "=== New messages: #{count} ==="
  sleep 10
end
