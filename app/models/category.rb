class Category < ActiveRecord::Base
  has_many :queries, dependent: :destroy
  belongs_to :user
end
