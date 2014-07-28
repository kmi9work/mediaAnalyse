class SearchEngine < ActiveRecord::Base
  has_many :query_search_engines
  has_many :queries, through: :query_search_engines
  has_many :texts

  RICH_CONTENT_KEY = "rca.1.1.20140325T124443Z.4617706c8eb8ca49.f55bbec26c11f882a82500daa69448a3e80dfef9"

  def track!
    if engine_type.include? "api"
      api_track!
    else
      browser_track!
    end
  end

  def api_track!
    Delayed::Worker.logger.debug "---"
    Delayed::Worker.logger.debug "Tracking #{title} started"
    return unless track?
    catch :done do
      loop do
        tqueries = queries.where(track: true)
        tqueries.each do |query|
          if engine_type == "vk_api"
            url = URI.escape "https://api.vk.com/method/newsfeed.search?q=#{query.body}&count=140"
            Delayed::Worker.logger.debug "Get vk api url: #{url}"
            str = open_url(url)
            if str
              resp = JSON.parse str.read
              if resp['response']
                for i in 1...resp['response'].size
                  set = resp['response'][i]
                  unless set['text'].strip.empty?
                    link = set['owner_id'].to_s + "_" + set['id'].to_s
                    unless link_exists?(query, link)
                      save_text query, link, "No title", set['text'], get_emot('', set['text'])['overall']
                      sleep 0.01
                    end
                  end
                end
              end
            else 
              s 10
            end
          elsif engine_type == "ya_blogs_api"
            url = URI.escape "http://blogs.yandex.ru/search.rss?text=#{query.body}&ft=blog"
            Delayed::Worker.logger.debug "Get yandex blogs api url: #{url}"
            str = open_url(url)
            if str
              resp = Hash.from_xml str.read
              if resp['rss'] and resp['rss']['channel'] and resp['rss']['channel']['item']
                resp['rss']['channel']['item'].each do |item|
                  if item['link'] and !link_exists?(query, item['link'])
                    title = item['title'] ? item['title'] : ''#--- title
                    if (arr = get_link_content(item['link'], title))
                      title, content = *arr
                      save_text query, item['link'], title, content, get_emot(title, content)['overall']
                      sleep 0.01
                    end
                  end
                end
              end
            else
              s 10
            end
          end
          throw :done unless track?
          t = rand(timeout) + timeout / 2
          Delayed::Worker.logger.debug "Sleeping for #{t} seconds."
          sleep(t)
          throw :done unless track?
        end
        throw :done unless track?
      end #loop
    end #catch
  end

  def browser_track!
    Delayed::Worker.logger.debug "---"
    Delayed::Worker.logger.debug "Tracking #{title} started"
    unless track?
      Delayed::Worker.logger.debug "Track complete."
      return
    end
    if Rails.env.production?
      headless = Headless.new
      headless.start
      Delayed::Worker.logger.debug "Headless started."
    end
    wait = Selenium::WebDriver::Wait.new(:timeout => 60)
    tqueries = queries.where(track: true)
    browsers = {}
    locators = []
    current_index = nil
    current_name = nil
    captcha_timeout = 1000
    begin #ensure
      catch :done do
        loop do
          tqueries = queries.where(track: true)
          tqueries.each do |query|
            current_name =  "id: #{query.id} #{query.title}"
            if query.reload.track?

              #in function or in if.
              unless browsers[query.id]
                Delayed::Worker.logger.debug "Track '#{query.title}' started."
                browsers[query.id] = Selenium::WebDriver.for :firefox
                locators = open_page browsers[query.id], wait, engine_type, query.body, query.sort_by_date
              else
                #refresh
                status = refresher browsers[query.id], "Can't refresh '#{query.title}'." do |pos|
                  Delayed::Worker.logger.debug "Browser '#{query.title}' refresh."
                  browsers[query.id].navigate.refresh if pos == :main
                end
                unless status
                  if browsers[query.id]
                    browsers[query.id].quit
                    browsers[query.id] = nil
                  end
                  next
                end
                # ***
              end

              throw :done unless track?
              s 2
              if locators.class == Array
                locators = get_links query, locators, browsers[query.id]  #Каким-то образом установить, что ссылки закончились. Может быть здесь: ***
              end

              #captcha or nothing on page.
              if locators == :captcha
                Delayed::Worker.logger.error "Captcha returned in query #{query.title}."
                Delayed::Worker.logger.debug "Let's take some coffee. About #{captcha_timeout} seconds."
                s captcha_timeout
                captcha_timeout *= 2
                if browsers[query.id] # КОСТЫЛЬ!!! ***
                  browsers[query.id].quit
                  browsers[query.id] = nil
                end
              elsif !locators
                Delayed::Worker.logger.debug "No search results in query #{query.title}."
                if browsers[query.id] # КОСТЫЛЬ!!! ***
                  browsers[query.id].quit
                  browsers[query.id] = nil
                end
                captcha_timeout = 1000
              else
                captcha_timeout = 1000
              end

              t = rand(timeout) + timeout / 2
              Delayed::Worker.logger.debug "Sleeping for #{t} seconds."
              sleep(t)
            else
              if browsers[query.id]
                browsers[query.id].quit
                browsers[query.id] = nil
                Delayed::Worker.logger.debug "Track '#{query.title}' complete."
              end
            end
            throw :done unless track?
          end
          throw :done unless track?
        end #loop
      end #catch :done
      browser_track! if track?
    ensure
      browsers.each {|_, b| b.quit if b}
      headless.destroy if headless
      Delayed::Worker.logger.debug "Query '#{current_name}' done."
      browser_track! if track?
    end
    browser_track! if track?
    puts "#{Time.now}: Tracking #{title} done."
  end
private
  def open_page browser, wait, type, body, sort_by_date
    fl = false
    if type == "ya_blogs"
      browser.get "http://blogs.yandex.ru/"
      refresher browser, "Can't find input text field in ya_blogs #{body}." do
        wait.until {browser.find_elements(name: "text", class: "b-form-input__input").count > 0}
      end
      input = browser.find_element(name: "text", class: "b-form-input__input")
      input.send_keys(body)
      input.submit
      s 2
      if sort_by_date
        if browser.find_elements(xpath: '//a[contains(text(), "по дате")]').count > 0
          browser.find_element(xpath: '//a[contains(text(), "по дате")]').click
        end
      else
        if browser.find_elements(xpath: '//a[contains(text(), "по релевантности")]').count > 0
          browser.find_element(xpath: '//a[contains(text(), "по релевантности")]').click
        end 
      end
      s 2
      if browser.find_elements(xpath: '//a[contains(text(), "без группировки")]').count > 0
        browser.find_element(xpath: '//a[contains(text(), "без группировки")]').click
      end
      s 2
      # .format(text) не группировать по сюжетам //*[@id="js"]/body/div[2]/div[3]/table/tbody/tr/td[2]/div[1]/table/tbody/tr/td[10]/div/a
      # body > table.l-page-search > tbody > tr > td.l-page-search-l > div.Ppb-c-SearchStatistics > div:nth-child(1) > h3 > a
      locators = [{css: "body table.l-page-search tbody tr td.l-page-search-l div.Ppb-c-SearchStatistics div h3 a"},
                  {css: "body table.l-page-search tbody tr td.l-page-search-l div.Ppb-c-SearchStatistics div div div.short.ItemMore-Text div a"}]
      refresher browser, "Can't find locator ya_blogs '#{body}'." do |pos|
        if pos == :main
          Delayed::Worker.logger.debug "Finding locators..."
          wait.until {browser.find_elements(locators[0]).count > 0 or 
                      browser.find_elements(locators[1]).count > 0}
        elsif pos == :no_locator_on_page
          Delayed::Worker.logger.debug "Maybe no links?"
          return :captcha if browser.page_source.include? "Введите, пожалуйста, символы с картинки в поле ввода и нажмите «Отправить». Это нужно, чтобы мы поняли, что Вы живой пользователь"
          return nil if browser.page_source.include? 'Извините, по вашему запросу не найдено записей' 
        end
      end
    elsif type == "ya_news"
      Delayed::Worker.logger.debug "get http://news.yandex.ru/"
      browser.get "http://news.yandex.ru/"
      refresher browser, "Can't find input text field in ya_news #{body}." do
        wait.until {browser.find_elements(name: "text", class: "b-form-input__input").count > 0}
      end
      input = browser.find_element(name: "text", class: "b-form-input__input")
      input.send_keys(body)
      input.submit
      s 2
      if sort_by_date
        if browser.find_elements(xpath: '//a[contains(text(), "по дате") and @class="b-link"]').count > 0
          browser.find_element(xpath: '//a[contains(text(), "по дате") and @class="b-link"]').click
        end
      else
        if browser.find_elements(xpath: '//a[contains(text(), "по релевантности") and @class="b-link"]').count > 0
          browser.find_element(xpath: '//a[contains(text(), "по релевантности") and @class="b-link"]').click
        end
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
      locators = [{css: "body div.b-page-content div.l-wrapper.page-search table tbody tr td.l-page__left div.b-news-groups.b-news-groups_mod_dups div div.b-news-groups__news-content div a"}]
      refresher browser, "Can't find locator ya_news '#{body}'." do |pos|
        if pos == :main
          Delayed::Worker.logger.debug "Finding locators..."
          wait.until {browser.find_elements(locators[0]).count > 0}
        elsif pos == :no_locator_on_page
          Delayed::Worker.logger.debug "Maybe no links or captcha?"
          captcha_text = "Введите, пожалуйста, символы с картинки в поле ввода и нажмите «Отправить». Это нужно, чтобы мы поняли, что Вы живой пользователь"
          return :captcha if browser.page_source.include? captcha_text or browser.find_elements(css: '.b-captcha__image').count > 0
          return nil if browser.page_source.include? 'Новостей по вашему запросу не найдено.' 
        end
      end

    elsif type == "google"
      browser.get "http://google.ru"
      browser.manage.timeouts.page_load = 300
      refresher browser, "Can't find input text field in google #{body}." do
        wait.until {browser.find_elements(id: "gbqfq").count > 0}
      end
      input = browser.find_element(id: "gbqfq")
      input.send_keys(body)
      s 2
      input.submit
      refresher browser, "Can't find button ok in google #{body}." do
        wait.until {browser.find_elements(id: "gbqfb").count > 0}
      end
      browser.find_element(id: "gbqfb", name: "btnG").click
      s 2
      refresher browser, "Can't find 'Инструменты поиска' in google #{body}." do
        wait.until {browser.find_elements(id: "hdtb_tls").count > 0}
      end
      browser.find_element(id: "hdtb_tls").click
      s 2
      browser.find_element(xpath: "//div[@aria-label='За всё время']").click
      s 2
      browser.find_element(css: "#qdr_d a").click
      if sort_by_date
        s 2
        browser.find_element(xpath: "//div[@aria-label='По релевантности']").click
        s 2
        browser.find_element(css: "#sbd_1 a").click
      end
      locators = [{css: "#rso div li div h3 a"}]
      refresher browser, "Can't find locator google '#{body}'." do |pos|
        if pos == :main
          Delayed::Worker.logger.debug "Finding locators..."
          wait.until {browser.find_elements(locators[0]).count > 0}
          if browser.page_source.include?("Нет результатов для") and browser.page_source.include?("Результаты по запросу")
            return nil
          end
        elsif pos == :no_locator_on_page
          Delayed::Worker.logger.debug "Maybe no links?"
          return nil if browser.page_source.include?('По запросу') and 
                    browser.page_source.include?('ничего не найдено') and 
                    browser.page_source.include?('Рекомендации:')
        end
      end
    elsif type == "vk"
      browser.get "http://google.ru"
      browser.manage.timeouts.page_load = 300
      refresher browser, "Can't find input text field in google #{body}." do
        wait.until {browser.find_elements(id: "gbqfq").count > 0}
      end
      input = browser.find_element(id: "gbqfq")
      input.send_keys("site:http://vk.com " + body + " -inurl:away")
      s 2
      input.submit
      refresher browser, "Can't find button ok in google #{body}." do
        wait.until {browser.find_elements(id: "gbqfb").count > 0}
      end
      browser.find_element(id: "gbqfb", name: "btnG").click
      s 2
      refresher browser, "Can't find 'Инструменты поиска' in google #{body}." do
        wait.until {browser.find_elements(id: "hdtb_tls").count > 0}
      end
      browser.find_element(id: "hdtb_tls").click
      s 2
      browser.find_element(xpath: "//div[@aria-label='За всё время']").click
      s 2
      browser.find_element(css: "#qdr_d a").click
      if sort_by_date
        s 2
        browser.find_element(xpath: "//div[@aria-label='По релевантности']").click
        s 2
        browser.find_element(css: "#sbd_1 a").click
      end
      locators = [{css: "#rso div li div h3 a"}]
      refresher browser, "Can't find locator vk '#{body}'." do |pos|
        if pos == :main
          Delayed::Worker.logger.debug "Finding locators..."
          wait.until {browser.find_elements(locators[0]).count > 0}
          if browser.page_source.include?("Нет результатов для") and browser.page_source.include?("Результаты по запросу")
            Delayed::Worker.logger.debug "No results found."
            return nil
          end
        elsif pos == :no_locator_on_page
          Delayed::Worker.logger.debug "Maybe no links?"
          Delayed::Worker.logger.debug "No results found. return nil"
          return nil if browser.page_source.include?('По запросу') and 
                    browser.page_source.include?('ничего не найдено') and 
                    browser.page_source.include?('Рекомендации:')
        end
      end
    elsif type == "vk_api"

    elsif type == "ya_blogs_api"

    end
    Delayed::Worker.logger.debug "Page opened. #{fl}"
    return locators
  end

  def s k
    sleep(rand(k * 100)/100.0 + rand(100)/100.0)
  end
    
  def get_links query, locators, browser  
    ls = []
    Delayed::Worker.logger.debug "Let's get links"
    locators.each do |l|
      ls += browser.find_elements(l).map{|i| i.attribute('href')}
    end
    Delayed::Worker.logger.debug "There is #{ls.size} links"
    fl = true
    if ls.size == 0
      Delayed::Worker.logger.debug "Maybe no links or captcha?"
      captcha_text = "Введите, пожалуйста, символы с картинки в поле ввода и нажмите «Отправить». Это нужно, чтобы мы поняли, что Вы живой пользователь"
      return :captcha if browser.page_source.include? captcha_text or browser.find_elements(css: '.b-captcha__image').count > 0
      return nil if browser.page_source.include? 'Новостей по вашему запросу не найдено.' 
      Delayed::Worker.logger.debug "I don't know why there is no links... <<<-------------"
      return locators
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
    return locators
  end

  def get_link_content link, def_title = ""
    Delayed::Worker.logger.debug "Getting rich content."
    yandex_rich_url = "http://rca.yandex.com/?key=#{RICH_CONTENT_KEY}&url=#{URI.escape(link)}&content=full"
    doc = open_url(yandex_rich_url, "URL: #{link}")
    s 0.1
    if (doc)
      doc = doc.readlines.join
      rich_ret = JSON.parse(doc)
      return [rich_ret["title"] ? CGI.unescapeHTML(rich_ret["title"]) : def_title, rich_ret["content"] ? CGI.unescapeHTML(rich_ret["content"]) : ""]
    else
      Delayed::Worker.logger.debug "Can't download #{link}. -----------------"
      return nil
    end
  end

  def link_exists? query, link
    return true if !link or link.empty?
    t = Time.now
    fl = query.texts.where(url: link).count > 0 # May be slow???
    Delayed::Worker.logger.debug "link_exists? takes #{t - Time.now} seconds. #{fl}"
    return fl
  end

  def save_text query, link, title, content, emot
    Delayed::Worker.logger.debug "Saving text... #{emot}"
    c = content.gsub(/[^\u{0}-\u{128}\u{0410}-\u{044F}ёЁ]/, '')
    t = title.gsub(/[^\u{0}-\u{128}\u{0410}-\u{044F}ёЁ]/, '')
    text = Text.new(url: link, title: title, content: c, emot: emot)
    text.query = query
    unless query
      Delayed::Worker.logger.error "FATAL! Query is nil!"
    end
    text.search_engine = self
    begin
    if text.save
      Delayed::Worker.logger.debug "Url #{link} saved."
    else
      Delayed::Worker.logger.error "Url #{link} CANNOT BE saved."
    end
    rescue ActiveRecord::StatementInvalid
      Delayed::Worker.logger.error "Url #{link} CANNOT BE saved."
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
        Delayed::Worker.logger.error "#{url} was not open. Sleep(#{k}). #{i}"
        Delayed::Worker.logger.error e.message
        Delayed::Worker.logger.error err_text
        Delayed::Worker.logger.error ''
        # ОБРАБОТАТЬ ПРАВИЛЬНО ОШИБКИ
        sleep(k)
      end
    end
    return doc
  end

  def track?
    Delayed::Worker.logger.debug "track? QUERIES: #{queries.where(track: true).count}"
    queries.where(track: true).count > 0
  end

  def refresher browser, msg
    refresh_times = 1
    while refresh_times <= 5
      begin
        yield :main
        return true
      rescue Errno::ECONNREFUSED => e
        Delayed::Worker.logger.error "#{e.message}\n" + msg + " closing browser."
        return false
      rescue StandardError, Timeout::Error => e
        yield :no_locator_on_page
        s(Math.log(refresh_times,2) ** 4)
        Delayed::Worker.logger.error "#{e.message}\n" + msg + " Refreshing #{refresh_times}"
        browser.navigate.refresh
      end
      refresh_times += 1
      unless track?
        Delayed::Worker.logger.debug 'THROW DONE.'
        throw :done 
      end
    end
    raise StandardError.new("Refresh doesn't helps. Maybe Captcha #{msg}.")
  end

  def get_emot title, content
    s 0
    query = {"text" => title + "\n" + content}
    uri = URI('http://emot.zaelab.ru/analyze.json')
    begin
      response = Net::HTTP.post_form(uri, query)
    rescue StandardError, Timeout::Error => e
      s 15
      Delayed::Worker.logger.error "#{response.value} to emot.zaelab.ru. Retrying..."
      return get_emot title, content
    end
    return JSON.parse(response.body)
  end
end
