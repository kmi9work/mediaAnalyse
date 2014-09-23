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
'http://vognebroda.net/rss.xml' => "В огне брода нет", 
'http://www.unn.com.ua/rss/news_ru.xml' => "Украинские Национальные Новости", 
'http://rss.unian.net/site/news_rus.rss' => "ИА УНИАН", 
'http://regnum.ru/rss/ukraina.xml' => "ИА REGNUM", 
'http://novorossy.ru/news/rss/1' => "Заря Новороссии", 
'http://k.img.com.ua/rss/ru/all_news2.0.xml' => "Корреспондент.net", 
'http://112.ua/rss' => "112.ua", 
'http://vesti.ua/feed/53-glavnye-vesti-strany.rss' => "Вести UA", 
'http://www.pravda.com.ua/rus/rss/' => "Украинская правда", 
'http://lifenews.ru/xml/feed.xml' => "Lifenews", 
'http://russian.rt.com/rss/' => "Russia Today", 
'http://www.president.gov.ua/ru/rss/' => "PRESIDENT.GOV.UA", 
'http://partyofregions.ua/news/rss/' => "Партия регионов", 
'http://www.svoboda.org.ua/feed/' => "Свобода", 
'http://batkivshchyna.com.ua/rss' => "Батьковщина" 
}

eurls.each do |url, name|
  Origin.create(url: url, origin_type: "rss", title: name, group: 1917)
end

urls = {
'http://news.yandex.ru/society.rss' => 'Яндекс.Общество',
'http://news.yandex.ru/fire.rss' => 'Яндекс.Пожары',
'http://news.yandex.ru/politics.rss' => 'Яндекс.Политика',
'http://news.yandex.ru/incident.rss' => 'Яндекс.Происшествия'
}

urls.each do |url, name|
  Origin.create(url: url, origin_type: "rss", title: name)
end


cat1 = Category.create(title: "Руководство МЧС")
cat2 = Category.create(title: "Президент России")

q1 = Query.new(title: "Пучков МЧС", body: "Пучков МЧС")
q1.save
q2 = Query.new(title: "Пучков Владимир Андреевич", body: "Пучков Владимир Андреевич")
q2.save
q3 = Query.new(title: "Шляков МЧС", body: "Шляков МЧС")
q3.save
q4 = Query.new(title: "Шляков Сергей Анатольевич", body: "Шляков Сергей Анатольевич")
q4.save

cat1.queries << q1 << q2 << q3 << q4
