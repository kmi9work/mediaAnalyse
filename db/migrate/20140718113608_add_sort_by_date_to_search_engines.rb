class AddSortByDateToSearchEngines < ActiveRecord::Migration
  def change
    add_column :search_engines, :sort_by_date, :boolean, default: true
  end
end
