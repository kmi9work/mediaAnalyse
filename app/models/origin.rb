class Origin < ActiveRecord::Base
  has_many :texts
  has_many :origins_queries, dependent: :destroy
  has_many :queries, through: :origins_queries
end
