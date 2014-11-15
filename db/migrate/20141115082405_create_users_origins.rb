class CreateUsersOrigins < ActiveRecord::Migration
  def change
    create_table :users_origins do |t|
      t.belongs_to :user
      t.belongs_to :origin
    end
  end
end
