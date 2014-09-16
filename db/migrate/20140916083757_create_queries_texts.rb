class CreateQueriesTexts < ActiveRecord::Migration
  def change
    create_table :queries_texts do |t|
      t.belongs_to :query
      t.belongs_to :text
    end
  end
end
