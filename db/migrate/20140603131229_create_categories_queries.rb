class CreateCategoriesQueries < ActiveRecord::Migration
  def change
    create_table :categories_queries do |t|
    	t.belongs_to :category
    	t.belongs_to :query
    end
  end
end
