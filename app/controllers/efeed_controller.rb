class EfeedController < FeedController
  # skip_before_filter :require_login
  def index
    set_session
    get_texts
    session[:elast] = Text.where(origin_id: @origins.map(&:id)).order(id: :asc).last.try(:id)
    render 'index', layout: false
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
    redirect_to efeed_path
  end
  def style
    session[:estyle] = params[:style]
  end
  def edit
    render 'edit', layout: false
  end
  def delete
    origin = Origin.find(params[:id])
    origin.destroy
    render '/efeed/edit', layout: false
  end
  def create
    origin = Origin.create(origin_params)
    redirect_to '/efeed/edit', layout: false
  end
  private
  def origin_params
    params.require(:origin).permit(:title, :url, :group, :origin_type, :query_position)
  end
  def set_session
    if session[:eorigins].blank?
      session[:eorigins] = Origin.where(group: 1917).map(&:id)
    end
    @origins = Origin.where(id: session[:eorigins])
    if session[:elast].blank?
      session[:elast] = Text.where(origin_id: @origins.map(&:id)).order(id: :asc).last.try(:id)
    end
  end
end
