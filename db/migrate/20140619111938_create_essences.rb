class CreateEssences < ActiveRecord::Migration
  def change
    create_table :essences do |t|
    	t.string :title
    	t.integer :rating
    	t.belongs_to :text
    	t.timestamps
    end
  end
end
