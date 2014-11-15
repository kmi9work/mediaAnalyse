class AddUserIdToTables < ActiveRecord::Migration
  def change
    add_column :categories, :user_id, :integer
    add_column :queries, :user_id, :integer
    add_index :categories, :user_id, :name => 'categories_user_id_ix'
    add_index :queries, :user_id, :name => 'queries_user_id_ix'
  end
end
