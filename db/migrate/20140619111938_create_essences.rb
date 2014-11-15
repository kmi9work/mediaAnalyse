class CreateEssences < ActiveRecord::Migration
  def change
    create_table :essences do |t|
      t.string :title
      t.integer :rating
      t.belongs_to :text
    end
  end
end
