#encoding: utf-8
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

 # t.string :title
 #      t.string :url
 #      t.integer :query_position
 #      t.string :origin_type
 #      t.integer :group, default: 0
 #      t.integer :timeout, default: 20
 #origin_type: rss, xml, json, vk_api, browser
eurls = { 
'http://regnum.ru/rss/ukraina.xml' => 'ИА REGNUM',
'http://lifenews.ru/xml/feed.xml' => 'Lifenews',
'http://russian.rt.com/rss/' => 'Russia Today',
'http://itar-tass.com/rss/v2.xml' => 'ТАСС',
'http://www.interfax.ru/rss.asp' => 'Интерфакс',
'http://ria.ru/export/rss2/world/index.xml' => 'РИА Новости - В мире',
'http://ria.ru/export/rss2/politics/index.xml' => 'РИА Новости - Политика',
'http://rian.com.ua/export/rss2/world/index.xml' => 'РИА Новости Украина - В мире',
'http://rian.com.ua/export/rss2/politics/index.xml' => 'РИА Новости Украина - Политика',
}

eurls.each do |url, name|
  Origin.create(url: url, origin_type: "rss_sourcesmi", title: name)
end

urls = {
'http://news.yandex.ru/society.rss' => 'Яндекс.Общество',
'http://news.yandex.ru/fire.rss' => 'Яндекс.Пожары',
'http://news.yandex.ru/politics.rss' => 'Яндекс.Политика',
'http://news.yandex.ru/incident.rss' => 'Яндекс.Происшествия'
}

urls.each do |url, name|
  Origin.create(url: url, origin_type: "rss_sourcesmi", title: name)
end


cat1 = Category.create(title: "Руководство МЧС")
cat2 = Category.create(title: "Президент России")

q1 = Query.new(title: "Пучков МЧС")
q1.save
q2 = Query.new(title: "Пучков Владимир Андреевич")
q2.save
q3 = Query.new(title: "Шляков МЧС")
q3.save
q4 = Query.new(title: "Шляков Сергей Анатольевич")
q4.save

cat1.queries << q1 << q2 << q3 << q4

url = "https://api.vk.com/method/newsfeed.search?q=&extended=1&count=140"
url_query_pos = 44
name = "VK API"
Origin.create(url: url, origin_type: "json_vk_api_search_sourcesn", title: name, query_position: url_query_pos, timeout: 60)

url = "http://blogs.yandex.ru/search.rss?text=&ft=all"
url_query_pos = 39
name = "Yandex Blogs API"
Origin.create(url: url, origin_type: "rss_ya_blogs_search_sourceblogs", title: name, query_position: url_query_pos, timeout: 60)

User.create(username: 'admin', password: 'gfhjkm')

