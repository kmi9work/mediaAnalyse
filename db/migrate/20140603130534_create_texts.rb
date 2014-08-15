class CreateTexts < ActiveRecord::Migration
  def change
    create_table :texts, id: false do |t|
      t.integer :id, :limit => 8
    	t.string :title
      t.text :description
    	t.text :content, :limit => 16777215
      t.string :author
    	t.string :url
      t.string :guid
      t.belongs_to :query
      t.belongs_to :search_engine
      t.belongs_to :origin
      t.integer :emot
      t.integer :my_emot
      t.datetime :datetime

      t.timestamps
    end
  end
end
