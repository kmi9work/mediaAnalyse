class FeedController < ApplicationController
  skip_before_filter :require_login
  def index
    @origins = Origin.where(group: 0)
    @texts = Text.where(origin_id: @origins)
                 .order(:datetime => :desc).limit(100)

  end
end
