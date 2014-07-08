class QuerySearchEngine < ActiveRecord::Base
  belongs_to :query
  belongs_to :search_engine
end
