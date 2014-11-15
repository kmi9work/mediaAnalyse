class Origin < ActiveRecord::Base
  has_many :texts
  has_many :origins_queries, dependent: :destroy
  has_many :queries, through: :origins_queries

  has_many :origins_users, dependent: :destroy
  has_many :users, through: :origins_users
end
