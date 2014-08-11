class EfeedController < ApplicationController
  skip_before_filter :require_login
  def index
    @origins = Origin.where(group: 1917)
    @texts = Text.where(origin_id: @origins)
                 .order(:datetime => :desc).limit(100)
    @texts.where(novel: true).each{|t| t.novel = false; t.save}
  end
  def show_new_emessages
    @origins = Origin.where(group: 1917)
    @texts = Text.where(origin_id: @origins)
                 .order(:datetime => :desc).where(novel: true)
    @texts.each{|t| t.novel = false; t.save}
  end
  def new_emessages
    @origins = Origin.where(group: 1917)
    @tcount = Text.where(origin_id: @origins)
                 .order(:datetime => :desc).where(novel: true).count
    render json: {tcount: @tcount.to_s}.to_json
  end
end
