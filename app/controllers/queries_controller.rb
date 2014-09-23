class QueriesController < ApplicationController
  before_action :categories_find, only: [:new, :show]
  before_action :query_find, only: [:show, :change_interval, :destroy, :chart_data, :keyphrases]
  def new
    if params[:category_id]
      @category = Category.find(params[:category_id])
      @queries = @category.queries
      @query = @category.queries.build
    else
      @query = Query.new
    end
  end
  def create
    query = Query.new(query_params)
    query.title = params[:query][:body] if params[:query][:title].blank?
    query.body = params[:query][:title] if params[:query][:body].blank?
    
    query.save
    redirect_to query_path(query.id)
  end
  
  def show
    @category = @query.category
    @queries = @category.queries
    params['source'] ||= 'smi'
    session[@query.id] ||= {}
    session[@query.id][:from] ||= DateTime.now.beginning_of_day
    session[@query.id][:to] ||= DateTime.now
    @texts = @query.texts.from_to_date(session[@query.id][:from], session[@query.id][:to])
  end
  def change_interval
    session[@query.id] ||= {}
    session[@query.id][:from] = DateTime.strptime(params['from'] + " +0400", "%d.%m.%Y %H:%M %Z")
    session[@query.id][:to] = DateTime.strptime(params['to'] + " +0400", "%d.%m.%Y %H:%M %Z")
    redirect_to query_path(@query.id, source: params['source'])
  end

  def destroy
    @category = @query.category
    @query.destroy
    respond_to do |format|
      format.html { redirect_to @category }
      format.json { head :no_content }
    end
  end

  def chart_data
    source_ses = SearchEngine.source params['source']
    texts = @query.texts.source(source_ses).order(:created_at).load
    #Faster with right SQL-query: select emot, created_at from texts
    chdata = {}
    chdata['emot'] = []
    chdata['count'] = []
    return render(json: chdata.to_json) if texts.empty?
    med = texts[0].my_emot || texts[0].emot
    n = 1.0
    fst = texts.first.created_at.beginning_of_hour
    cur = fst.dup
    lst = texts.last.created_at
    index = 0
    cur += 3600
    while cur <= lst      
      n = 0
      med = 0
      while index < texts.size - 1 and texts[index].created_at < cur
        med += texts[index].my_emot || texts[index].emot
        n += 1
        index += 1
      end
      fst = cur
      if (n > 0)
        chdata['emot'] << [fst.strftime("%d.%m.%y %H:%M"), med.to_f / n]
        chdata['count'] << [fst.strftime("%d.%m.%y %H:%M"), n]
      else
        chdata['emot'] << [fst.strftime("%d.%m.%y %H:%M"), chdata['emot'].last[1]]
        chdata['count'] << [fst.strftime("%d.%m.%y %H:%M"), 0]
      end
      cur += 3600
    end
    unless (cur > DateTime.now)
      n = 0
      med = 0
      while index < texts.size - 1 and texts[index].created_at < cur
        med += texts[index].my_emot || texts[index].emot
        n += 1
        index += 1
      end
      fst = cur
      if (n > 0)
        chdata['emot'] << [fst.strftime("%d.%m.%y %H:%M"), med.to_f / n]
        chdata['count'] << [fst.strftime("%d.%m.%y %H:%M"), n]
      else
        chdata['emot'] << [fst.strftime("%d.%m.%y %H:%M"), chdata['emot'].last[1]]
        chdata['count'] << [fst.strftime("%d.%m.%y %H:%M"), 0]
      end
    end
    render json: chdata.to_json
  end
  def keyphrases
    render 'keyphrases', layout: 'only_header'
  end
  private
  def categories_find
    @categories = Category.all
  end
  def query_find
    @query = Query.find(params[:query_id])
  end

  def query_params
    params.require(:query).permit(:id, :title, :category_id)
  end
end
