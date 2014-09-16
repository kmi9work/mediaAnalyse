class CreateOriginsQueries < ActiveRecord::Migration
  def change
    create_table :origins_queries do |t|
      t.belongs_to :origin
      t.belongs_to :query
    end
  end
end
