class MakeTextContentLonger < ActiveRecord::Migration
  def change
    change_column :texts, :content, :text, :limit => 16777215
  end
end
