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
    integral(texts.source('smi'))
  end
  def integral_emot_sn
    integral(texts.source('sn'))
  end
  def integral_emot_blogs
    integral(texts.source('blogs'))
  end

  def last_hour_emot_smi
    ret = {}
    tt = texts.source('smi').from_to_date(DateTime.now.beginning_of_hour - 1.hour, DateTime.now.beginning_of_hour)
    if tt.blank?
      tt = texts.source('smi').last(10) 
      ttt = texts.source('smi').last(20) - tt
    else
      ttt = texts.from_to_date(DateTime.now.beginning_of_hour - 2.hour, DateTime.now.beginning_of_hour - 1.hour)
    end
    ret[:value] = integral tt
    prev = integral ttt  
    ret[:rate] = ret[:value] - prev
    return ret
  end
  def last_hour_emot_sn
    ret = {}
    tt = texts.source('sn').from_to_date(DateTime.now.beginning_of_hour - 1.hour, DateTime.now.beginning_of_hour)
    if tt.blank?
      tt = texts.source('sn').last(10) 
      ttt = texts.source('sn').last(20) - tt
    else
      ttt = texts.from_to_date(DateTime.now.beginning_of_hour - 2.hour, DateTime.now.beginning_of_hour - 1.hour)
    end
    ret[:value] = integral tt
    prev = integral ttt  
    ret[:rate] = ret[:value] - prev
    return ret
  end
  def last_hour_emot_blogs
    ret = {}
    tt = texts.source('blogs').from_to_date(DateTime.now.beginning_of_hour - 1.hour, DateTime.now.beginning_of_hour)
    if tt.blank?
      tt = texts.source('blogs').last(10) 
      ttt = texts.source('blogs').last(20) - tt
    else
      ttt = texts.from_to_date(DateTime.now.beginning_of_hour - 2.hour, DateTime.now.beginning_of_hour - 1.hour)
    end
    ret[:value] = integral tt
    prev = integral ttt  
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
