class SearchEngine < ActiveRecord::Base
  has_many :query_search_engines
  has_many :queries, through: :query_search_engines
  has_many :texts

  RICH_CONTENT_KEY = "rca.1.1.20140325T124443Z.4617706c8eb8ca49.f55bbec26c11f882a82500daa69448a3e80dfef9"

  def track!
    Delayed::Worker.logger.debug "---"
    Delayed::Worker.logger.debug "#{Time.now}: Tracking #{title} started"
    unless track?
      Delayed::Worker.logger.debug "Track complete."
      return
    end
    if Rails.env.production?
      headless = Headless.new
      headless.start
      Delayed::Worker.logger.debug "Headless started."
    end
    wait = Selenium::WebDriver::Wait.new(:timeout => 120)
    tqueries = queries.where(track: true)
    browsers = Array.new(tqueries.size, nil)
    locators = []
    current_index = nil
    current_name = nil
    begin
      catch :done  do
        loop do
          tqueries = queries.where(track: true)
          tqueries.each_with_index do |query, i|
            current_index = i
            current_name = query.title
            if query.track?
              unless browsers[i]
                s 15
                Delayed::Worker.logger.debug "Track '#{query.title}' started."
                browsers[i] = Selenium::WebDriver.for :firefox
                locators = open_page browsers[i], wait, engine_type, query.body
              else
                Delayed::Worker.logger.debug "Browser '#{query.title}' refresh."
                refresh_browser browsers[i], query.title
              end
              s 2
              fl = false
              while !fl
                begin
                  Delayed::Worker.logger.debug "Finding locator..."
                  wait.until {browsers[i].find_elements(locators[0]).count > 0}
                  fl = true
                rescue Selenium::WebDriver::Error::TimeOutError
                  Delayed::Worker.logger.error "Can't find locator ya_news '#{query.title}'. Refreshing" 
                  s 10
                  refresh_browser browsers[i], query.title
                end
              end
              get_links query, locators, browsers[i]
              t = rand(timeout) + timeout / 2
              Delayed::Worker.logger.debug "Sleeping for #{t} seconds."
              sleep(t)
            else
              if browsers[i]
                browsers[i].quit
                browsers[i] = nil
                Delayed::Worker.logger.debug "Track '#{query.title}' complete."
              end
            end
            if i == 0
              throw :done unless track?
            end
          end
        end
      end
    ensure
      browsers.each {|b| b.quit if b}
      headless.destroy if headless
      Delayed::Worker.logger.debug "#{current_index}'s query '#{current_name}' raised."
    end
    puts "#{Time.now}: Tracking #{title} done."
  end
private
  def open_page browser, wait, type, body
    fl = false
    if type == "ya_blogs"
      browser.get "http://blogs.yandex.ru/"
      wait.until {browser.find_elements(name: "text", class: "b-form-input__input").count > 0}
      input = browser.find_element(name: "text", class: "b-form-input__input")
      input.send_keys(body)
      input.submit
      s 2
      if browser.find_elements(xpath: '//a[contains(text(), "по дате")]').count > 0
        browser.find_element(xpath: '//a[contains(text(), "по дате")]').click
      end
      s 2
      if browser.find_elements(xpath: '//a[contains(text(), "без группировки")]').count > 0
        browser.find_element(xpath: '//a[contains(text(), "без группировки")]').click
      end
      s 2
      # .format(text) не группировать по сюжетам //*[@id="js"]/body/div[2]/div[3]/table/tbody/tr/td[2]/div[1]/table/tbody/tr/td[10]/div/a
      # body > table.l-page-search > tbody > tr > td.l-page-search-l > div.Ppb-c-SearchStatistics > div:nth-child(1) > h3 > a
      locator = {css: "body table.l-page-search tbody tr td.l-page-search-l div.Ppb-c-SearchStatistics div h3 a"}
      fl = wait.until {browser.find_elements(locator).count > 0}
      Delayed::Worker.logger.error("Can't find locator in ya_blogs.") unless fl
    elsif type == "ya_news"
      browser.get "http://news.yandex.ru/"
      wait.until {browser.find_elements(name: "text", class: "b-form-input__input").count > 0}
      input = browser.find_element(name: "text", class: "b-form-input__input")
      input.send_keys(body)
      input.submit
      s 2
      if browser.find_elements(xpath: '//a[contains(text(), "по времени") and @class="b-link"]').count > 0
        browser.find_element(xpath: '//a[contains(text(), "по времени") and @class="b-link"]').click
      end
      s 2
      if browser.find_elements(xpath: '//a[contains(text(), "сегодня") and @class="b-link"]').count > 0
        browser.find_element(xpath: '//a[contains(text(), "сегодня") and @class="b-link"]').click
      end
      s 2
      if browser.find_elements(xpath: '//a[contains(text(), "не группировать по сюжетам")]').count > 0
        browser.find_element(xpath: '//a[contains(text(), "не группировать по сюжетам")]').click
      end
      s 2
      # .format(text) не группировать по сюжетам //*[@id="js"]/body/div[2]/div[3]/table/tbody/tr/td[2]/div[1]/table/tbody/tr/td[10]/div/a
      # 
      locator = {css: "body div.b-page-content div.l-wrapper.page-search table tbody tr td.l-page__left div.b-news-groups.b-news-groups_mod_dups div div.b-news-groups__news-content div a"}
      fl = false
      while !fl
        begin
          fl = wait.until {browser.find_elements(locator).count > 0} 
        rescue Selenium::WebDriver::Error::TimeOutError
          Delayed::Worker.logger.error "Can't find locator in ya_news '#{body}'. Refreshing" 
          s 10 
          refresh_browser browser, body
        end
      end
      ### Selenium::WebDriver::Error::TimeOutError: timed out after 120 seconds
      Delayed::Worker.logger.error("Can't find locator in ya_news.") unless fl
    elsif type == "google"
      browser.get "http://google.ru"
      browser.manage.timeouts.page_load = 300
      unless wait.until {browser.find_elements(id: "gbqfq").count > 0}
        puts "Error in find element gbqfq"
      end
      input = browser.find_element(id: "gbqfq")
      input.send_keys(body)
      s 2
      input.submit
      wait.until {browser.find_elements(id: "gbqfb").count > 0}
      browser.find_element(id: "gbqfb", name: "btnG").click
      s 2
      wait.until {browser.find_elements(id: "hdtb_tls").count > 0}
      browser.find_element(id: "hdtb_tls").click
      s 2
      browser.find_element(xpath: "//div[@aria-label='За всё время']").click 
      s 2
      browser.find_element(css: "#qdr_d a").click
      s 2
      browser.find_element(xpath: "//div[@aria-label='По релевантности']").click
      s 2
      browser.find_element(css: "#sbd_1 a").click
      locator = {css: "#rso div li div h3 a"}
      fl = wait.until {browser.find_elements(locator).count > 0}
      Delayed::Worker.logger.error("Can't find locator in google.") unless fl
    elsif type == "vk"
      browser.get "http://google.ru"
      browser.manage.timeouts.page_load = 300
      unless wait.until {browser.find_elements(id: "gbqfq").count > 0}
        puts "Error in find element gbqfq"
      end
      input = browser.find_element(id: "gbqfq")
      input.send_keys("site:http://vk.com " + body)
      s 2
      input.submit
      wait.until {browser.find_elements(id: "gbqfb").count > 0}
      browser.find_element(id: "gbqfb", name: "btnG").click
      s 2
      wait.until {browser.find_elements(id: "hdtb_tls").count > 0}
      browser.find_element(id: "hdtb_tls").click
      s 2
      browser.find_element(xpath: "//div[@aria-label='За всё время']").click 
      s 2
      browser.find_element(css: "#qdr_d a").click
      s 2
      browser.find_element(xpath: "//div[@aria-label='По релевантности']").click
      s 2
      browser.find_element(css: "#sbd_1 a").click
      locator = {css: "#rso div li div h3 a"}
      fl = wait.until {browser.find_elements(locator).count > 0}
      Delayed::Worker.logger.error("Can't find locator in google.") unless fl
    end
    Delayed::Worker.logger.debug "Page opened. #{fl}"
    return [locator]
  end

  def s k
    sleep(rand(k * 100)/100.0 + 0.2)
  end
    
  def get_links query, locators, browser  
    ls = []
    Delayed::Worker.logger.debug "Let's get links"
    locators.each do |l|
      ls += browser.find_elements(l).map{|i| i.attribute('href')}
    end
    fl = true
    if ls.size == 0
      Delayed::Worker.logger.debug "No links"
      return
    end
    emot = {}
    ls.each do |link|
      Delayed::Worker.logger.debug "Processing #{link}"
      unless link_exists?(query, link)
        title, content = nil, nil
        if (arr = get_link_content(link))
          title, content = *arr
        else
          next
        end
        emot = get_emot title, content
        save_text query, link, title, content, emot['overall']
        fl = false
      else
        Delayed::Worker.logger.debug "Link exists."
      end
    end
    if fl
      # Необходимо просмотреть следующую страницу
    end
  end

  def get_link_content link
    yandex_rich_url = "http://rca.yandex.com/?key=#{RICH_CONTENT_KEY}&url=#{URI.escape(link)}&content=full"
    doc = open_url(yandex_rich_url, "URL: #{link}")
    if (doc)
      doc = doc.readlines.join
      rich_ret = JSON.parse(doc)
      return [rich_ret["title"] ? CGI.unescapeHTML(rich_ret["title"]) : "", rich_ret["content"] ? CGI.unescapeHTML(rich_ret["content"]) : ""]
    else
      Delayed::Worker.logger.debug "Can't download #{link}. -----------------"
      return nil
    end
  end

  def link_exists? query, link
    query.texts.where(url: link).count > 0 # May be slow???
  end

  def save_text query, link, title, content, emot
    Delayed::Worker.logger.debug "Saving text..."
    text = Text.new(url: link, title: title, content: content, emot: emot)
    text.query = query
    text.search_engine = self
    if text.save
      Delayed::Worker.logger.debug "Url #{link} saved."
    else
      Delayed::Worker.logger.debug "Url #{link} CANNOT BE saved."
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
      rescue Exception => e
        doc = nil
        k = rand(15) + 5
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
  def track?
    self.reload
    tracked_count > 0
  end
  def refresh_browser browser, title
    fl = false
    refresh_times = 0
    while !fl
      begin
        browser.navigate.refresh ### Net::ReadTimeout
        fl = true
      rescue Net::ReadTimeout
        s((Math.log(refresh_times,2) ** 4))
        Delayed::Worker.logger.error "Can't refresh '#{title}'. Retrying #{refresh_times}..." 
        browser.navigate.refresh
      end
    end
  end
  def get_emot title, content
    query = {"text" => title + "\n" + content}
    uri = URI('http://emot.zaelab.ru/analyze.json')
    response = Net::HTTP.post_form(uri, query)
    return JSON.parse(response.body)
  end
end
