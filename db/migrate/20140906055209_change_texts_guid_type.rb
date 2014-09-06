class ChangeTextsGuidType < ActiveRecord::Migration
  def change
    change_column :texts, :guid,  :text
  end
end
