class RenameCountColumn < ActiveRecord::Migration
  def change
    rename_column :text_counts, :count, :tcount
  end
end
