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
    query.save
    Origin.all.each{|o| o.queries << query}
    redirect_to query_path(query.id)
  end
  
  def show
    @category = @query.category
    @queries = @category.queries
    params['source'] ||= 'smi'
    session[@query.id] ||= {}
    session[@query.id][:from] ||= DateTime.now.beginning_of_day
    session[@query.id][:to] ||= DateTime.now
    @texts = @query.texts.source(params['source'])
                   .from_to_date(session[@query.id][:from], session[@query.id][:to])
                   .order(datetime: :desc)
                   .paginate(page: params[:page], per_page: 50)
    if @texts.empty?
      flash[:notice] = "Нет сообщений за выбранный период. Показаны последние 50."
      @texts = @query.texts.source(params['source']).order(datetime: :desc).limit(50).paginate(page: params[:page], per_page: 50)
    end
  end
  def change_interval
    session[@query.id] ||= {}
    if params['from'] and params['to']
      session[@query.id][:from] = DateTime.strptime(params['from'] + " +0400", "%d.%m.%Y %H:%M %Z")
      session[@query.id][:to] = DateTime.strptime(params['to'] + " +0400", "%d.%m.%Y %H:%M %Z")
    else
      session[@query.id][:from] = DateTime.now.beginning_of_day
      session[@query.id][:to] = DateTime.now
    end
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
    texts = @query.texts.source(params['source']).order(:datetime).where('datetime > ?', DateTime.now - 10.days).load
    #Faster with right SQL-query: select emot, datetime from texts
    chdata = {}
    chdata['emot'] = []
    chdata['count'] = []
    chdata['day_emot'] = []
    chdata['day_count'] = []
    return render(json: chdata.to_json) if texts.empty?
    fst = texts.first.datetime.beginning_of_hour
    lst = texts.last.datetime
    chdata['emot'], chdata['count'] = *data_by_period(fst, lst, texts, 3600)
    chdata['day_emot'], chdata['day_count'] = *data_by_period(fst, lst, texts, 3600*24)
    
    render json: chdata.to_json
  end
  def keyphrases
    render 'keyphrases', layout: 'only_header'
  end
  private

  def data_by_period first, last, texts, period
    emot = []
    count = []
    cur = first.dup + period
    fst = first.dup
    index = 0
    while cur <= last
      n = 0
      med = 0
      while index < texts.size - 1 and texts[index].datetime < cur
        med += texts[index].my_emot || texts[index].emot || 0
        n += 1
        index += 1
      end
      
      if (n > 0)
        emot << [fst.strftime("%d.%m.%y %H:%M"), med.to_f / n]
        count << [fst.strftime("%d.%m.%y %H:%M"), n]
      else
        # chdata['emot'] << [fst.strftime("%d.%m.%y %H:%M"), chdata['emot'].last[1]]
        # chdata['count'] << [fst.strftime("%d.%m.%y %H:%M"), 0]
      end
      fst = cur
      cur += period
    end
    return [emot, count]
  end
  def data_by_days first, last, texts
    cur = first.dup
  end
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
