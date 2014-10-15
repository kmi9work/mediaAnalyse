class NovelText < ActiveRecord::Base
	has_many :queries_texts, dependent: :destroy
  has_many :queries, through: :queries_texts
  belongs_to :origin
  has_many :essences

  include Tire::Model::Search
  include Tire::Model::Callbacks

  mapping do
    indexes :id,           index:    :not_analyzed
    indexes :title,        type: 'string', boost: 100
    indexes :description,  type: 'string', boost: 30
    indexes :content,      type: 'string'
	end
  def Text.search query
    tire.search(per_page: 1000000, load: true) do
      query { string query } if query.present?
    end
  end  

  def Text.select_for_query query
    texts = []
    query.keyphrases.each do |kp|
      texts += Text.search(kp.body).results
    end
    return texts
  end
end
