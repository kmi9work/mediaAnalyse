class CreateQueries < ActiveRecord::Migration
  def change
    create_table :queries do |t|
      t.string :title
      t.integer :timeout, default: 3600 #it is not antibot
      t.belongs_to :category
      t.timestamps
    end
  end
end
