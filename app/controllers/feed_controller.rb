class FeedController < ApplicationController
  skip_before_filter :require_login, except: [:new, :edit, :delete, :create]
  before_action :get_origins, only: [:show_new_messages, :new_messages]
  before_action :set_session, only: [:index, :puchkov]
  def index
    @origins = Origin.where(id: session[:origins])
    get_texts
    session[:last] = Text.where(origin_id: @origins.map(&:id)).order(id: :asc).last.id
  end
  def show_new_messages
    get_novel_texts session[:last]
    session[:last] = Text.where(origin_id: @origins.map(&:id)).order(id: :asc).last.try(:id)
  end
  def new_messages
    render_tcount session[:last]
  end
  def select_sources
    session[:origins] = params[:select_sources] ? params[:select_sources].map(&:to_i) : [] 
    redirect_to action: :index
  end
  def edit
    render 'edit', layout: false
  end
  def delete
    origin = Origin.find(params[:id])
    origin.destroy
    render 'edit', layout: false
  end
  def create
    origin = Origin.create(origin_params)
    render 'edit', layout: false
  end
  def puchkov
    @origins = Origin.where(id: session[:origins])
    @texts = Text.search do
      # fulltext 'Пучков Владимир Андреевич'
      # fulltext 'Пучков В.А.'
      # fulltext 'А.В. Пучков'
      fulltext 'Владимир Пучков'
      # fulltext 'Глава МЧС России'
      # fulltext 'Глава МЧС РФ'
      # fulltext 'Глава МЧС'
      # fulltext 'Главный спасатель страны'
      # fulltext 'Министр МЧС'
    end.results
    render 'index'
  end
  private
  def get_origins
    @origins = Origin.where(group: 0)
  end
  def get_texts
    @texts = Text.where(origin_id: @origins.map(&:id))
                 .order(:datetime => :desc)
    if (@texts.try(:count) || 0) > 50
      @texts = @texts.page(params[:page]).per(50)
    end
  end
  def get_novel_texts id
    @texts = Text.where(origin_id: @origins.map(&:id)).order(:datetime => :desc).where('id > ?', id)
  end
  def render_tcount id
    @tcount = Text.where(origin_id: @origins.map(&:id))
                 .order(:datetime => :desc).where('id > ?', id).count
    render json: {tcount: @tcount.to_s}.to_json
  end

  def set_session
    if session[:origins].blank?
      session[:origins] = Origin.where(group: 0).map(&:id)
    end
    if session[:last].blank?
      session[:last] = Text.order(id: :asc).last.id
    end
  end
end
