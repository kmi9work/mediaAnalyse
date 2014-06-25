require 'cgi'
require 'open-uri'
require 'uri'
require "selenium-webdriver"
require 'headless'

class Query < ActiveRecord::Base

	has_and_belongs_to_many :categories
	has_and_belongs_to_many :texts

	RICH_CONTENT_KEY = "rca.1.1.20140325T124443Z.4617706c8eb8ca49.f55bbec26c11f882a82500daa69448a3e80dfef9"

	def track!
		puts "Tracking started"
		self.reload
		unless track?
			puts "Track complete."
			return
		end
		if Rails.env.production?
			headless = Headless.new
			headless.start
		end
		browser = Selenium::WebDriver.for :firefox
		wait = Selenium::WebDriver::Wait.new(:timeout => 10)
		puts "Started"
		
		if search_engine == "Yandex Blogs"
			puts "Yandex Blogs"
			browser.get "http://blogs.yandex.ru/"
			wait.until {browser.find_elements(name: "text", class: "b-form-input__input").count > 0}
			input = browser.find_element(name: "text", class: "b-form-input__input")
			input.send_keys(body)
			input.submit
			sleep(1)
			if browser.find_elements(xpath: '//a[contains(text(), "по дате")]').count > 0
				browser.find_element(xpath: '//a[contains(text(), "по дате")]').click
			end
			sleep(1)
			if browser.find_elements(xpath: '//a[contains(text(), "без группировки")]').count > 0
				browser.find_element(xpath: '//a[contains(text(), "без группировки")]').click
			end
			sleep(1)
			# .format(text) не группировать по сюжетам //*[@id="js"]/body/div[2]/div[3]/table/tbody/tr/td[2]/div[1]/table/tbody/tr/td[10]/div/a
			# body > table.l-page-search > tbody > tr > td.l-page-search-l > div.Ppb-c-SearchStatistics > div:nth-child(1) > h3 > a
			locator = {css: "body table.l-page-search tbody tr td.l-page-search-l div.Ppb-c-SearchStatistics div h3 a"}
			wait.until {browser.find_elements(locator).count > 0}

			get_links_in_loop 200, [locator], browser

		elsif search_engine == "Yandex News"
			puts "Yandex News"
			browser.get "http://news.yandex.ru/"
			wait.until {browser.find_elements(name: "text", class: "b-form-input__input").count > 0}
			input = browser.find_element(name: "text", class: "b-form-input__input")
			input.send_keys(body)
			input.submit
			sleep(1)
			if browser.find_elements(xpath: '//a[contains(text(), "по времени") and @class="b-link"]').count > 0
				browser.find_element(xpath: '//a[contains(text(), "по времени") and @class="b-link"]').click
			end
			sleep(1)
			if browser.find_elements(xpath: '//a[contains(text(), "сегодня") and @class="b-link"]').count > 0
				browser.find_element(xpath: '//a[contains(text(), "сегодня") and @class="b-link"]').click
			end
			sleep(1)
			if browser.find_elements(xpath: '//a[contains(text(), "не группировать по сюжетам")]').count > 0
				browser.find_element(xpath: '//a[contains(text(), "не группировать по сюжетам")]').click
			end
			sleep(1)
			# .format(text) не группировать по сюжетам //*[@id="js"]/body/div[2]/div[3]/table/tbody/tr/td[2]/div[1]/table/tbody/tr/td[10]/div/a
			# 
			locator = {css: "body div.b-page-content div.l-wrapper.page-search table tbody tr td.l-page__left div.b-news-groups.b-news-groups_mod_dups div div.b-news-groups__news-content div a"}
			wait.until {browser.find_elements(locator).count > 0}

			get_links_in_loop 600, [locator], browser

		elsif search_engine == "Google"
			puts "Google engine"
			browser.get "http://google.ru"
			print "Getting page... "
			browser.manage.timeouts.page_load = 300
			if wait.until {browser.find_elements(id: "gbqfq").count > 0}
				puts "Done."
			else
				puts "Error in find element gbqfq"
			end

			input = browser.find_element(id: "gbqfq")
			input.send_keys(body)
			sleep(1)
			input.submit
			browser.find_element(id: "gbqfb", name: "btnG").click
			wait.until {browser.find_elements(id: "hdtb_tls").count > 0}
			browser.find_element(id: "hdtb_tls").click
			sleep(1)
			browser.find_element(xpath: "//div[@aria-label='За всё время']").click 
			sleep(1)
			browser.find_element(css: "#qdr_d a").click
			sleep(1)
			browser.find_element(xpath: "//div[@aria-label='По релевантности']").click 
			sleep(1)
			browser.find_element(css: "#sbd_1 a").click
			locator = {css: "#rso div li div h3 a"}
			get_links_in_loop 180, [locator], browser
		end
		headless.destroy
	end
	private

	def get_links_in_loop interval, locators, browser
		catch :done do
			loop do
				i = 0
				while i < interval/2
					i += interval/20
					sleep(interval/20)
					self.reload
					unless track?
						puts "Track complete."
						browser.quit
						throw :done 
					end
				end
				ls = []
				locators.each do |l| 
					ls += browser.find_elements(l).map{|i| i.attribute('href')}
				end
				fl = true
				ls.each do |link|
					self.reload
					unless track?
						puts "Track complete."
						browser.quit
						throw :done 
					end
					puts "Processing #{link}"
					unless link_exists?(link)
						title, content = nil, nil
						if (arr = get_link_content(link))
							title, content = *arr
						else
							next
						end
						save_text(link, title, content)
						fl = false
					end
				end
				self.reload
				unless track?
					puts "Track complete."
					browser.quit
					throw :done 
				end
				if fl
					# Необходимо просмотреть следующую страницу
				end
				i = 0
				while i < rand(interval/2)
					i += interval/20
					sleep(interval/20)
					self.reload
					unless track?
						puts "Track complete."
						browser.quit
						throw :done 
					end
				end
				browser.navigate.refresh
				puts "Browser refresh"
			end
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
			puts "Can't download #{link}. -----------------"
			return nil
		end
	end

	def link_exists? link
		self.texts.where(url: link).count > 0
	end

	def save_text link, title, content
		puts "Saving text..."
		text = Text.new(url: link, title: title, content: content)
		p text.save
		self.texts << text
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
				k = rand(10) + 5
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
end
