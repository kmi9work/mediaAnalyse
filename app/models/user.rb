class User < ActiveRecord::Base
  authenticates_with_sorcery!

  has_many :categories
  has_many :queries

  has_many :origins_users, dependent: :destroy
  has_many :origins, through: :origins_users

  validates :password, length: { minimum: 3 }
  validates :username, presence: true
end
