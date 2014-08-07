class CreateOrigins < ActiveRecord::Migration
  def change
    create_table :origins do |t|
      t.string :title
      t.string :rss_url
      t.integer :group, default: 0
      t.timestamps
    end
  end
end
