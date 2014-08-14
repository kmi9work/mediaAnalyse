class EfeedController < FeedController
  skip_before_filter :require_login
  before_action :set_session, only: :index
  def index
    @origins = Origin.where(id: session[:eorigins])
    get_texts
    session[:elast] = @texts.order(:created_at => :asc).last.created_at
    render 'index', layout: false
  end
  def show_new_emessages
    @origins = Origin.where(id: session[:eorigins])
    get_novel_texts session[:elast]
    session[:elast] = @texts.order(:created_at => :asc).last.created_at
  end
  def new_emessages
    @origins = Origin.where(id: session[:eorigins])
    render_tcount session[:elast]
  end
  def select_esources
    session[:eorigins] = params[:select_sources] ? params[:select_sources].map(&:to_i) : [] 
    redirect_to action: :index
  end
  private
  def set_session
    if session[:eorigins].blank?
      session[:eorigins] = Origin.where(group: 1917).map(&:id)
    end
    if session[:elast].blank?
      session[:elast] = DateTime.now
    end
  end
end
