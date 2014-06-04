class CreateQueries < ActiveRecord::Migration
  def change
    create_table :queries do |t|
    	t.string :body
    	t.string :search_engine
    	t.integer :max_count, default: 0
    	#parameters
    	t.string :sort, default: 't'
    	t.date :from
    	t.date :to
    	t.integer :g_period_num
    	t.integer :timeout, default: 120

        t.timestamps
    end
  end
end
