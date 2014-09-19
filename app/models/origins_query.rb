class OriginsQuery < ActiveRecord::Base
  belongs_to :origin
  belongs_to :query
end
