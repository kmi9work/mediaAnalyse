require 'rss'
require 'logger'
require 'rails'
RICH_CONTENT_KEY = "rca.1.1.20140325T124443Z.4617706c8eb8ca49.f55bbec26c11f882a82500daa69448a3e80dfef9"

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
    query = {"text" => title + "\n" + content}
    uri = URI('http://emot.zaelab.ru/analyze.json')
    begin
      response = Net::HTTP.post_form(uri, query)
    rescue StandardError, Timeout::Error => e
      s 10
      @my_logger.error "#{response.value} to emot.zaelab.ru. Retrying..."
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
      begin
        open(origin.rss_url) do |rss|
          if origin.rss_url == 'http://www.pravda.com.ua/rus/rss/'
            text = rss.read.encode('WINDOWS-1251').force_encoding('UTF-8')
          else
            text = rss.read
          end

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
            if (arr = get_link_content(t.url, t.title))
              title, content = *arr
            else
              content = ""
            end
            t.content = content
            t.emot = get_emot t.title, t.content
            t.save
          end
        end
        break
      rescue StandardError, Timeout::Error => e
        ret = 0
        k = rand(15) + 5
        @my_logger.error "#{origin.rss_url} was not open. Sleep(#{k}). #{i}"
        @my_logger.error e.message
        @my_logger.error ''
        sleep(k)
      end
    end
    return ret
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
