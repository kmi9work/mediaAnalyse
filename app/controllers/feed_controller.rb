class FeedController < ApplicationController
  skip_before_filter :require_login, except: [:new, :edit, :delete, :create]
  before_action :get_origins, only: [:show_new_messages, :new_messages]
  before_action :set_session, only: :index
  def index
    @origins = Origin.where(id: session[:origins])
    get_texts
    session[:last] = @texts.order(id: :asc).last.id
  end
  def show_new_messages
    get_novel_texts session[:last]
    session[:last] = @texts.order(id: :asc).last.id
  end
  def new_messages
    render_tcount session[:last]
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
  end
  def get_novel_texts id
    @texts = Text.where(origin_id: @origins).order(:datetime => :desc).where('id > ?', id)
  end
  def render_tcount id
    @tcount = Text.where(origin_id: @origins)
                 .order(:datetime => :desc).where('id > ?', id).count
    render json: {tcount: @tcount.to_s}.to_json
  end

  def set_session
    if session[:origins].blank?
      session[:origins] = Origin.where(group: 0).map(&:id)
    end
    if session[:last].blank?
      session[:last] = Text.last.id
    end
  end
end
