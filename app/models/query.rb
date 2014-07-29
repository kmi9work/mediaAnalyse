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
  def track_with
    types = search_engines.map(&:engine_type)
    sources = []
    sources << "smi" if types.include?('ya_news')
    sources << "sn" if types.include?('vk') or types.include?('vk_api')
    sources << "blogs" if types.include?('ya_blogs') or types.include?('ya_blogs_api')
    return sources
  end
  def integral_emot
    integral(texts.all)
  end
  def integral_emot_smi
    source_ses = SearchEngine.where(engine_type: 'ya_news')
    integral(texts.source(source_ses))
  end
  def integral_emot_sn
    source_ses = SearchEngine.where(engine_type: ['vk', 'vk_api'])
    integral(texts.source(source_ses))
  end
  def integral_emot_blogs
    source_ses = SearchEngine.where(engine_type: ['ya_blogs','ya_blogs_api'])
    integral(texts.source(source_ses))
  end

  def last_hour_emot_smi
    source_ses = SearchEngine.where(engine_type: 'ya_news')
    ret = {}
    ret[:value] = integral texts.source(source_ses).from_to_date(DateTime.now.beginning_of_hour - 1.hour, DateTime.now.beginning_of_hour)
    prev = integral texts.source(source_ses).from_to_date(DateTime.now.beginning_of_hour - 2.hour, DateTime.now.beginning_of_hour - 1.hour)
    ret[:rate] = ret[:value] - prev
    return ret
  end
  def last_hour_emot_sn
    source_ses = SearchEngine.where(engine_type: ['vk', 'vk_api'])
    ret = {}
    ret[:value] = integral texts.source(source_ses).from_to_date(DateTime.now.beginning_of_hour - 1.hour, DateTime.now.beginning_of_hour)
    prev = integral texts.source(source_ses).from_to_date(DateTime.now.beginning_of_hour - 2.hour, DateTime.now.beginning_of_hour - 1.hour)
    ret[:rate] = ret[:value] - prev
    return ret
  end
  def last_hour_emot_blogs
    source_ses = SearchEngine.where(engine_type: ['ya_blogs','ya_blogs_api'])
    ret = {}
    ret[:value] = integral texts.source(source_ses).from_to_date(DateTime.now.beginning_of_hour - 1.hour, DateTime.now.beginning_of_hour)
    prev = integral texts.source(source_ses).from_to_date(DateTime.now.beginning_of_hour - 2.hour, DateTime.now.beginning_of_hour - 1.hour)
    ret[:rate] = ret[:value] - prev
    return ret
  end

  
  private
  def integral texts
    n = 0
    sum = 0.0
    texts.each do |t| 
      sum += t.emot
      n += 1
    end
    return 0 if n == 0 
    return sum / n
  end
end
