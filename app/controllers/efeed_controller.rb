class EfeedController < ApplicationController
  #skip_before_filter :require_login, except: [:new, :edit, :delete, :create]
  def index
    set_session
    @texts = Text.where(origin_id: @origins.map(&:id)).order(:datetime => :desc).paginate(page: params[:page], per_page: 50)
    session[:elast] = Text.where(origin_id: @origins.map(&:id)).order(id: :asc).last.try(:id)
    render action: :index, layout: false
  end
  def show_new_emessages
    @origins = Origin.where(id: session[:eorigins])
    get_novel_texts session[:elast]
    session[:elast] = Text.where(origin_id: @origins.map(&:id)).order(id: :asc).last.try(:id)
  end
  def new_emessages
    @origins = Origin.where(id: session[:eorigins])
    render_tcount session[:elast]
  end
  def select_esources
    session[:eorigins] = params[:select_sources] ? params[:select_sources].map(&:to_i) : []
    if params[:commit] == "Сохранить"
      current_user.origin_ids = session[:eorigins]
    end
    redirect_to efeed_path
  end
  def style
    session[:estyle] = params[:style]
  end
  def edit
    render action: :edit, layout: false
  end
  def delete
    origin = Origin.find(params[:id])
    origin.destroy
    render action: :edit, layout: false
  end
  def create
    origin = Origin.create(origin_params)
    redirect_to action: :edit, layout: false
  end
  private

  def origin_params
    params.require(:origin).permit(:title, :url, :origin_type, :query_position)
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
    if logged_in?
      session[:eorigins] = current_user.origin_ids
    else
      if session[:eorigins].blank?
        session[:eorigins] = Origin.all.map(&:id)
      end
    end
    @origins = Origin.where(id: session[:eorigins])
    if session[:elast].blank?
      session[:elast] = Text.where(origin_id: @origins.map(&:id)).order(id: :asc).last.try(:id)
    end
  end

end
