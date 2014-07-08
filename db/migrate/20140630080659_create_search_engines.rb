class CreateSearchEngines < ActiveRecord::Migration
  def change
    create_table :search_engines do |t|
      t.string :title
      t.string :engine_type, default: :google # ya_blogs, ya_news, google, ...
      t.integer :timeout, default: 120 # in seconds
      t.integer :tracked_count, default: 0 #count of tracked
      t.timestamps
    end
  end
end
