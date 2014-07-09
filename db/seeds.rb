#encoding: utf-8
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

cat1 = Category.create(title: "Руководство МЧС")
cat2 = Category.create(title: "Президент России")

g = SearchEngine.create(title: "Google", engine_type: 'google', timeout: 180)
yb = SearchEngine.create(title: "Yandex Blogs", engine_type: 'ya_blogs', timeout: 180)
yn = SearchEngine.create(title: "Yandex News", engine_type: 'ya_news', timeout: 180)
vk = SearchEngine.create(title: "Vk.com", engine_type: 'vk', timeout: 180)

q1 = Query.new(title: "Пучков МЧС", body: "Пучков МЧС", max_count: 100)
q1.search_engines << g;
q1.save
q2 = Query.new(title: "Пучков Владимир Андреевич", body: "Пучков Владимир Андреевич", max_count: 100)
q2.search_engines << g;
q2.save
q3 = Query.new(title: "Шляков МЧС", body: "Шляков МЧС", max_count: 100)
q3.search_engines << g;
q3.save
q4 = Query.new(title: "Шляков Сергей Анатольевич", body: "Шляков Сергей Анатольевич", max_count: 100)
q4.search_engines << g;
q4.save

cat1.queries << q1 << q2 << q3 << q4
