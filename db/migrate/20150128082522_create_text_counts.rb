class CreateTextCounts < ActiveRecord::Migration
  def change
    create_table :text_counts do |t|
      t.string :source
      t.integer :count
      t.belongs_to :query
    end
  end
end
