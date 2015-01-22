class CreateKeyqueries < ActiveRecord::Migration
  def change
    create_table :keyqueries do |t|
      t.string :body
      t.belongs_to :query
    end
  end
end
