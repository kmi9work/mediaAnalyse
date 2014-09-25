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
'http://vognebroda.net/rss.xml' => 'В огне брода нет',
'http://www.unn.com.ua/rss/news_ru.xml' => 'Украинские Национальные Новости',
'http://rss.unian.net/site/news_rus.rss' => 'ИА УНИАН',
'http://regnum.ru/rss/ukraina.xml' => 'ИА REGNUM',
'http://k.img.com.ua/rss/ru/all_news2.0.xml' => 'Корреспондент.net',
'http://112.ua/rss' => '112.ua',
'http://vesti.ua/feed/53-glavnye-vesti-strany.rss' => 'Вести UA',
'http://www.pravda.com.ua/rus/rss/' => 'Украинская правда',
'http://lifenews.ru/xml/feed.xml' => 'Lifenews',
'http://russian.rt.com/rss/' => 'Russia Today',
'http://www.president.gov.ua/ru/rss/' => 'PRESIDENT.GOV.UA',
'http://partyofregions.ua/news/rss/' => 'Партия регионов',
'http://www.svoboda.org.ua/feed/' => 'Свобода',
'http://batkivshchyna.com.ua/rss' => 'Батьковщина',
'http://itar-tass.com/rss/v2.xml' => 'ТАСС',
'http://www.interfax.ru/rss.asp' => 'Интерфакс',
'http://interfax.com.ua/news/last.rss' => 'Интерфакс-Украина',
'http://ria.ru/export/rss2/world/index.xml' => 'РИА Новости - В мире',
'http://ria.ru/export/rss2/politics/index.xml' => 'РИА Новости - Политика',
'http://rian.com.ua/export/rss2/world/index.xml' => 'РИА Новости Украина - В мире',
'http://rian.com.ua/export/rss2/politics/index.xml' => 'РИА Новости Украина - Политика',
'http://novorossy.ru/news/rss/1' => 'Заря Новороссии',
'http://www.ukrinform.ua/rus/rss/news/lastnews	' => 'Укринформ'
}

eurls.each do |url, name|
  Origin.create(url: url, origin_type: "rss_sourcesmi", title: name)
end

oo = Origin.all.last(2).each{|o| o.corrupted = true; o.save}

