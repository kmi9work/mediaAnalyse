class QueriesController < ApplicationController
	before_action :categories_find, only: [:new, :show]
	before_action :query_find, only: [:start_work, :stop_work, :show, :change_interval, :destroy, :chart_data]
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
	def start_work
		ses = SearchEngine.source params['source']
		@query.track = true
		@query.search_engine_ids += ses.map(&:id)
		@query.save
		ses.each do |se|
			fl = (se.tracked_count == 0)
			se.tracked_count = se.queries.where(track: true).count
			se.save
			if Delayed::Job.count == 0 or (fl and se.tracked_count == 1)
				se.delay.track!
			end
		end
		respond_to do |format|
			format.html { redirect_to :back}
			format.js { render :none }
		end
	end

	def stop_work
		ses = SearchEngine.source params['source']
		@query.track = false
		@query.search_engine_ids -= ses.map(&:id)
		@query.save
		ses.each do |se|
			se.tracked_count = se.queries.where(track: true).count
			se.save
		end
		respond_to do |format|
			format.html { redirect_to :back}
			format.js { render :none }
		end
	end

	def show
		@category = @query.category
		@queries = @category.queries
		params['source'] ||= 'smi'
		session[@query.id] ||= {}
		session[@query.id][:from] ||= DateTime.now.beginning_of_day
		session[@query.id][:to] ||= DateTime.now
		source_ses = SearchEngine.source params['source']
		@texts = @query.texts.source(source_ses).from_to_date(session[@query.id][:from], session[@query.id][:to])
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
		while cur <= lst
			cur += 3600
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
	private
	def categories_find
		@categories = Category.all
	end
	def query_find
		@query = Query.find(params[:query_id])
	end

	def query_params
		params.require(:query).permit(:id, :title, :body, :max_count, :sort_by_date, :category_id, search_engine_ids: [])
	end
end
