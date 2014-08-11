class EfeedController < ApplicationController
  skip_before_filter :require_login
  def index
    @origins = Origin.where(group: 1917)
    @texts = Text.where(origin_id: @origins)
                 .order(:datetime => :desc).limit(100)

  end
end
