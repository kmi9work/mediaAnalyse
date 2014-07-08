class CreateQuerySearchEngines < ActiveRecord::Migration
  def change
    create_table :query_search_engines do |t|
      t.belongs_to :query
      t.belongs_to :search_engine
      t.timestamps
    end
  end
end
