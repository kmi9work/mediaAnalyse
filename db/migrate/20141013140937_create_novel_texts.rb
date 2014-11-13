class CreateNovelTexts < ActiveRecord::Migration
  def change
    create_table :novel_texts do |t|
      t.string :title
      t.text :description
      t.text :content, :limit => 16777215
      t.string :author
      t.string :url
      t.text :guid
      t.belongs_to :origin
      t.integer :emot
      t.integer :my_emot
      t.datetime :datetime
      t.datetime :created_at
    end
  end
end
