class CreateKeyphrases < ActiveRecord::Migration
  def change
    create_table :keyphrases do |t|
      t.string :body
      t.belongs_to :query
    end
  end
end
