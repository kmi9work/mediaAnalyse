require 'cgi'
require 'open-uri'
require 'uri'
require "selenium-webdriver"

class Query < ActiveRecord::Base

	has_and_belongs_to_many :categories
	has_and_belongs_to_many :texts

	RICH_CONTENT_KEY = "rca.1.1.20140325T124443Z.4617706c8eb8ca49.f55bbec26c11f882a82500daa69448a3e80dfef9"

	def track!
		browser = Selenium::WebDriver.for :chrome
		if @search_engine == "Yandex"
			browser.get "http://yandex.ru"
			browser.find_element(name: "text").send_keys(body)
			browser.find_element(class: "b-form-button__input", type: "submit").click
			locator = {css: "a.b-link.b-link_ajax_yes.b-pager__link"}
			wait = Selenium::WebDriver::Wait.new(:timeout => 10)
			wait.until {browser.find_elements(locator).count > 0}
			browser.find_element(locator).click
			loop do
				sleep(rand(100)+ 80)
				browser.navigate.refresh
			end
		elsif search_engine == "Google"
			browser.get "http://google.ru"
			browser.manage.timeouts.page_load = 300
			wait = Selenium::WebDriver::Wait.new(:timeout => 10)
			wait.until {browser.find_elements(id: "gbqfq").count > 0}
			input = browser.find_element(id: "gbqfq")
			input.send_keys(body)
			sleep(1)
			input.submit
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
			loop do
				i = 0
				while i < 80
					i += 3
					sleep(3)
					self.reload
					break unless track?
				end
				ls = browser.find_elements(css: "#rso div li div h3 a").map{|i| i.attribute('href')}
				fl = true
				ls.each do |link|
					self.reload
					break unless track?
					puts "Processing #{link}"
					unless link_exists?(link)
						title, content = nil, nil
						unless (arr = get_link_content(link))
							next
						else
							title, content = *arr
						end
						save_text(link, title, content)
						fl = false
					end
				end
				self.reload
				break unless track?
				if fl
					# Необходимо просмотреть следующую страницу
				end
				i = 0
				while i < rand(100)
					i += 3
					sleep(3)
					self.reload
					break unless track?
				end
				browser.navigate.refresh
				puts "Browser refresh"
			end
		end
	end
	private

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
		p text = Text.new(url: link, title: title, content: content)
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
