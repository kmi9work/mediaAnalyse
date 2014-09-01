class EfeedController < FeedController
  # skip_before_filter :require_login
  before_action :set_session, only: :index
  def index
    get_texts
    session[:elast] = Text.where(origin_id: @origins).last.id
    render 'index', layout: false
  end
  def show_new_emessages
    @origins = Origin.where(id: session[:eorigins])
    get_novel_texts session[:elast]
    session[:elast] = @texts.order(id: :asc).last.id
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
    render 'edit', layout: false
  end
  def create
    origin = Origin.create(origin_params)
    render 'edit', layout: false
  end
  private
  def origin_params
    params.require(:origin).permit(:title, :rss_url, :group)
  end
  def set_session
    if session[:eorigins].blank?
      session[:eorigins] = Origin.where(group: 1917).map(&:id)
    end
    @origins = Origin.where(id: session[:eorigins])
    if session[:elast].blank?
      session[:elast] = Text.where(origin_id: @origins).last.id
    end
  end
end
