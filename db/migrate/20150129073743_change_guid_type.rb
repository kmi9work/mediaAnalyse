class ChangeGuidType < ActiveRecord::Migration
  def change
    change_column :texts, :guid, :string
  end
end
