require 'cgi'
require 'open-uri'
require 'uri'
require "selenium-webdriver"
require 'headless'

class Query < ActiveRecord::Base

  belongs_to :category
  belongs_to :user
  has_many :queries_texts, dependent: :destroy
  has_many :texts, through: :queries_texts
  has_many :origins_queries, dependent: :destroy
  has_many :origins, through: :origins_queries
  has_many :keyphrases, dependent: :destroy
  has_many :keyqueries, dependent: :destroy
  has_many :text_counts, dependent: :destroy

  def integral_emot
    integral(texts.all)
  end

  def update_text_counts
    text_counts.each do |tc|
      tc.tcount = texts.source_count(tc.source)
      tc.emot = integral(texts.source(tc.source))
      tc.save
    end
  end

  def texts_source_count source
    text_counts.where(source: source).tcount
  end

  def integral_emot source
    text_counts.where(source: source).emot
  end

  def last_hour_emot_smi user
    ret = {}
    tt = texts.source_user('smi', user).from_to_date(DateTime.now.beginning_of_hour - 1.hour, DateTime.now.beginning_of_hour)
    if tt.blank?
      tt = texts.source_user('smi', user).last(10)
      ttt = texts.source_user('smi', user).last(20) - tt
    else
      ttt = texts.from_to_date(DateTime.now.beginning_of_hour - 2.hour, DateTime.now.beginning_of_hour - 1.hour)
    end
    ret[:value] = integral tt
    prev = integral ttt
    ret[:rate] = ret[:value] - prev
    return ret
  end
  def last_hour_emot_sn user
    ret = {}
    tt = texts.source_user('sn', user).from_to_date(DateTime.now.beginning_of_hour - 1.hour, DateTime.now.beginning_of_hour)
    if tt.blank?
      tt = texts.source_user('sn', user).last(10)
      ttt = texts.source_user('sn', user).last(20) - tt
    else
      ttt = texts.from_to_date(DateTime.now.beginning_of_hour - 2.hour, DateTime.now.beginning_of_hour - 1.hour)
    end
    ret[:value] = integral tt
    prev = integral ttt
    ret[:rate] = ret[:value] - prev
    return ret
  end
  def last_hour_emot_blogs user
    ret = {}
    tt = texts.source_user('blogs', user).from_to_date(DateTime.now.beginning_of_hour - 1.hour, DateTime.now.beginning_of_hour)
    if tt.blank?
      tt = texts.source_user('blogs', user).last(10)
      ttt = texts.source_user('blogs', user).last(20) - tt
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
