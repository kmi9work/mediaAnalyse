class CreateOriginsUsers < ActiveRecord::Migration
  def change
    create_table :origins_users do |t|
      t.belongs_to :origin
      t.belongs_to :user
      t.timestamps
    end
  end
end
