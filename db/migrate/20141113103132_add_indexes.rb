class AddIndexes < ActiveRecord::Migration
  def change
    add_index :texts, :origin_id, :name => 'texts_origin_id_ix'
    add_index :texts, :datetime, :name => 'texts_datetime_id_ix'
    add_index :queries, :category_id, :name => 'queries_category_id_ix'
    add_index :queries_texts, :query_id, :name => 'queries_texts_query_id_ix'
    add_index :queries_texts, :text_id, :name => 'queries_texts_text_id_ix'
    add_index :origins_queries, :origin_id, :name => 'origins_queries_origin_id_ix'
    add_index :origins_queries, :query_id, :name => 'origins_queries_query_id_ix'
  end
end
