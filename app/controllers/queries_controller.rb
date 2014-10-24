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
    chdata = {}
    chdata['emot'] = []
    chdata['count'] = []
    chdata['day_emot'] = []
    chdata['day_count'] = []
    fst = (DateTime.now - 10.days).beginning_of_hour
    lst = DateTime.now
    chdata['emot'], chdata['count'] = *data_by_period(fst, lst, 1.hour, params['source'])
    chdata['day_emot'], chdata['day_count'] = *data_by_period(fst, lst, 1.day, params['source'])
    
    render json: chdata.to_json
  end
  def keyphrases
    render 'keyphrases', layout: 'only_header'
  end
  private

  def data_by_period first, last, period, source
    emot = []
    count = []
    cur = first.dup
    while cur < last
      q = ["SELECT AVG(emot), COUNT(*) FROM \"texts\" WHERE (datetime > ? AND datetime < ?) AND (origin_id IN (SELECT \"origins\".id FROM \"origins\" WHERE (origin_type like ?)))", 
              cur, cur + period, "%source#{source}%"]
      f = Text.find_by_sql(q)[0]
      if (f.count.to_i > 0)
        emot << [cur.strftime("%d.%m.%y %H:%M"), f.avg.to_f]
        count << [cur.strftime("%d.%m.%y %H:%M"), f.count.to_i]
      end
      cur += period
    end
    return [emot, count]
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
