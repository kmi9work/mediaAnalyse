class CreateOrigins < ActiveRecord::Migration
  def change
    create_table :origins do |t|
      t.string :title
      t.string :url
      t.integer :query_position
      t.string :origin_type
      t.integer :group, default: 0
      t.integer :timeout, default: 20
      t.timestamps
    end
  end
end
