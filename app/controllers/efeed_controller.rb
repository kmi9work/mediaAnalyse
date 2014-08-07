class EfeedController < ApplicationController
  skip_before_filter :require_login
  def index
    @origins = Origin.where(group: 1917)
    @texts = Text.where(origin_id: @origins)
                 .from_to_date(DateTime.now - 1.day, DateTime.now)
                 .order(:datetime).limit(100)

  end
end
