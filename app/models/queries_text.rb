class QueriesText < ActiveRecord::Base
  belongs_to :text
  belongs_to :query
end
