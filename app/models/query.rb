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
  def integral_emot
    n = 0
    sum = 0.0
    texts.all.each do |t| 
      sum += t.emot
      n += 1
    end
    return 0 if n == 0 
    return sum / n
  end
  def from_to from, to
    if from and to
      return texts.where(created_at: DateTime.strptime(from, "%d.%m.%Y %H:%M")..DateTime.strptime(to, "%d.%m.%Y %H:%M"))
    elsif from
      return texts.where('created_at > ?', DateTime.strptime(from, "%d.%m.%Y %H:%M"))
    elsif to
      return texts.where('created_at < ?', DateTime.strptime(to, "%d.%m.%Y %H:%M"))
    else
      return texts.where('created_at > ?', 6.hours.ago)
    end
  end
end
