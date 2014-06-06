class CreateTexts < ActiveRecord::Migration
  def change
    create_table :texts do |t|
    	t.string :title
    	t.text :content
    	t.string :url
    	t.boolean :new, default: true
        t.timestamps
    end
  end
end
