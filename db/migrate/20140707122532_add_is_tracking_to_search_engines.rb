class AddIsTrackingToSearchEngines < ActiveRecord::Migration
  def change
    add_column :search_engines, :is_tracking, :boolean
  end
end
