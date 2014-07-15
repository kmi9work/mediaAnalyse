class AddMyEmotToTexts < ActiveRecord::Migration
  def change
    add_column :texts, :my_emot, :integer, default: nil
  end
end
