class EfeedController < ApplicationController
  skip_before_filter :require_login
  before_filter :set_session, only: :index
  def index
    @origins = Origin.where(id: session[:origins])
    @texts = Text.where(origin_id: @origins)
                 .order(:datetime => :desc).page(params[:page]).per(50)
    Text.where({origin_id: @origins, novel: true}).each{|t| t.novel = false; t.save}
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
  def select_sources
    session[:origins] = params[:select_sources].map(&:to_i)
    redirect_to action: :index
  end
  private
  def set_session
    if session[:origins].blank?
      session[:origins] = Origin.where(group: 1917).map(&:id)
    end
  end
end
