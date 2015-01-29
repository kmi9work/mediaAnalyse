class AddGuidIndexes < ActiveRecord::Migration
  def change
    add_index :texts, :guid, :name => 'texts_guid_ix'
    add_index :texts, [:origin_id, :guid], :name => 'texts_guid_ix'
  end
end
