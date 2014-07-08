require 'cgi'
require 'open-uri'
require 'uri'
require "selenium-webdriver"
require 'headless'

class Query < ActiveRecord::Base

	belongs_to :category
	has_many :texts
	has_many :query_search_engines
	has_many :search_engines, through: :query_search_engines

end
