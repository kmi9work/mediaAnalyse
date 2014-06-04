class CreateQueriesTexts < ActiveRecord::Migration
  def change
    create_table :queries_texts do |t|
    	t.belongs_to :text
    	t.belongs_to :query
    end
  end
end
