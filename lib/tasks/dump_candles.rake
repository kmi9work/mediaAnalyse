
namespace :dump do
  desc "Dump candles query 30 to stdout."
  task candles: :environment do
    query = Query.find(30)

    chdata = []
    se = SearchEngine.where(engine_type: 'ya_news').first
    texts = query.texts.source(se)
    fst = texts.first.created_at.beginning_of_day
    cur = fst
    lst = texts.last.created_at

    while cur <= lst
      cur += 3600 * 24
      max = 0
      min = 5
      tt = texts.where(created_at: fst..cur)
      if (tt.count > 0)
        fst_emot = tt.first.my_emot || tt.first.emot
        lst_emot = tt.last.my_emot || tt.last.emot
        tt.each do |t|
          emot = t.my_emot || t.emot
          max = emot if emot > max
          min = emot if emot < min
        end
        fst = cur
        chdata << [min, fst_emot, lst_emot, max]
      else
        chdata << [nil, nil, nil, nil]
      end
    end
    puts "min;first;last;max"
    chdata.each do |c|
      puts c.join(';')
    end
  end
end