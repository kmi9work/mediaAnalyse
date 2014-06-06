# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

cat1 = Category.create(title: "Руководство МЧС")
cat2 = Category.create(title: "Президент России")

q1 = Query.create(body: "Пучков МЧС", search_engine: "Google", max_count: 100)
q2 = Query.create(body: "Пучков Владимир Андреевич", search_engine: "Google", max_count: 100)
q3 = Query.create(body: "Шляков МЧС", search_engine: "Google", max_count: 100)
q4 = Query.create(body: "Шляков Сергей Анатольевич", search_engine: "Google", max_count: 100)

cat1.queries << q1 << q2 << q3 << q4