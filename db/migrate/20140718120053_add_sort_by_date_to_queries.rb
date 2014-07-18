class AddSortByDateToQueries < ActiveRecord::Migration
  def change
    add_column :queries, :sort_by_date, :boolean, default: true
  end
end
