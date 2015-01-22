class NovelText < ActiveRecord::Base
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
  def NovelText.search query
    tire.search(per_page: 1000000, load: true) do
      query { string query } if query.present?
    end
  end

  def NovelText.select_for_query query
    texts = []
    query.keyqueries.each do |kq|
      texts += NovelText.search(kq.body).results
    end
    return texts
  end
end
