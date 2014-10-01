class Category < ActiveRecord::Base
	has_many :queries, dependent: :destroy
end
