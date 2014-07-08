class CreateQueries < ActiveRecord::Migration
  def change
    create_table :queries do |t|
        t.string :title
    	t.string :body
    	t.integer :max_count, default: 0
    	#parameters
    	t.string :sort, default: 't'
    	t.date :from
    	t.date :to
    	t.integer :g_period_num
    	t.integer :timeout, default: 3600 #it is not antibot
        t.boolean :track, default: false
        t.belongs_to :search_engine
        t.belongs_to :category

        t.timestamps
    end
  end
end
