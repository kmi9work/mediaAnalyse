require 'cgi'
require 'open-uri'
require 'uri'
require "selenium-webdriver"
require 'headless'

class Query < ActiveRecord::Base

	belongs_to :category
  has_many :queries_texts
	has_many :texts, through: :queries_texts
  has_many :origins_queries
  has_many :origins, through: :origins_queries
  has_many :keyphrases
  
  def integral_emot
    integral(texts.all)
  end
  def integral_emot_smi
  end
  def integral_emot_sn
  end
  def integral_emot_blogs
  end

  def last_hour_emot_smi
    ret = {}
    ret[:value] = integral texts.from_to_date(DateTime.now.beginning_of_hour - 1.hour, DateTime.now.beginning_of_hour)
    prev = integral texts.from_to_date(DateTime.now.beginning_of_hour - 2.hour, DateTime.now.beginning_of_hour - 1.hour)
    ret[:rate] = ret[:value] - prev
    return ret
  end
  def last_hour_emot_sn
    ret = {}
    ret[:value] = integral texts.from_to_date(DateTime.now.beginning_of_hour - 1.hour, DateTime.now.beginning_of_hour)
    prev = integral texts.from_to_date(DateTime.now.beginning_of_hour - 2.hour, DateTime.now.beginning_of_hour - 1.hour)
    ret[:rate] = ret[:value] - prev
    return ret
  end
  def last_hour_emot_blogs
    ret = {}
    ret[:value] = integral texts.from_to_date(DateTime.now.beginning_of_hour - 1.hour, DateTime.now.beginning_of_hour)
    prev = integral texts.from_to_date(DateTime.now.beginning_of_hour - 2.hour, DateTime.now.beginning_of_hour - 1.hour)
    ret[:rate] = ret[:value] - prev
    return ret
  end

  
  private
  def integral texts
    n = 0
    sum = 0.0
    texts.each do |t| 
      sum += t.my_emot || t.emot || 0
      n += 1
    end
    return 0 if n == 0 
    return sum / n
  end
end
