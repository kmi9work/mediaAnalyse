class FeedController < ApplicationController
  skip_before_filter :require_login
  before_action :get_origins, only: [:show_new_messages, :new_messages]
  before_action :set_session, only: :index
  def index
    @origins = Origin.where(id: session[:origins])
    get_texts
  end
  def show_new_messages
    get_novel_texts
  end
  def new_messages
    render_tcount
  end
  def select_sources
    session[:origins] = params[:select_sources] ? params[:select_sources].map(&:to_i) : [] 
    redirect_to action: :index
  end
  private
  def get_origins
    @origins = Origin.where(group: 0)
  end
  def get_texts
    @texts = Text.where(origin_id: @origins)
                 .order(:datetime => :desc).page(params[:page]).per(50)
    Text.where({origin_id: @origins, novel: true}).each{|t| t.novel = false; t.save}
  end
  def get_novel_texts
    @texts = Text.where(origin_id: @origins).order(:datetime => :desc).where(novel: true)
    puts '------------', @texts.count
    @texts.each{|t| t.novel = false; t.save}
    puts @texts.count, '========='
  end
  def render_tcount
    @tcount = Text.where(origin_id: @origins)
                 .order(:datetime => :desc).where(novel: true).count
    render json: {tcount: @tcount.to_s}.to_json
  end

  def set_session
    if session[:origins].blank?
      session[:origins] = Origin.where(group: 0).map(&:id)
    end
  end
end
