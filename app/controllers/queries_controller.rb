class QueriesController < ApplicationController
	def new
		@categories = Category.all	
		if params[:category_id]
			@category = Category.find(params[:category_id])
			@queries = @category.queries
			@query = @category.queries.build
		else
			@category = nil
			@categories = Category.all
			@query = Query.new
		end
	end
	def create
		@category = Category.find(params[:category_id])
		@query = Query.create(query_params)

		# @query.categories << @category
		@category.queries << @query
		redirect_to category_query_path(@category.id, @query.id)
	end
	def start_work
		ses = SearchEngine.source params['source']
		@query = Query.find(params[:query_id])
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
			format.json { render :none }
		end
	end

	def stop_work
		ses = SearchEngine.source params['source']
		@query = Query.find(params[:query_id])
		@query.track = false
		@query.search_engine_ids -= ses.map(&:id)
		@query.save
		ses.each do |se|
			se.tracked_count = se.queries.where(track: true).count
			se.save
		end
		respond_to do |format|
			format.html { redirect_to :back}
			format.json { render :none }
		end
	end

	def show
		@categories = Category.all
		@category = Category.find(params[:category_id])
		@queries = @category.queries
		@query = Query.find(params[:id])
		params['source'] = 'smi' unless params['source']
		source_ses = SearchEngine.source params['source']
		@texts = @query.texts.source(source_ses).from_to(params[:from], params[:to])
		respond_to do |format|
			format.html { render :show}
			format.js { render :show}
		end
	end

	def destroy
		@category = Category.find(params[:category_id])
		@query = Query.find(params[:id])
  	@query.destroy
  	respond_to do |format|
    		format.html { redirect_to @category }
    		format.json { head :no_content }
  	end
	end

	def chart_data
		query = Query.find(params[:id])
		source_ses = SearchEngine.source params['source']
		texts = query.texts.source(source_ses).order(:created_at)
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
		
		while cur <= lst
			cur += 3600
			n = 0
			med = 0
			texts.from_to_date(fst,cur).each do |t|
				med += t.my_emot || t.emot
				n += 1
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
	def query_params
		params.require(:query).permit(:id, :title, :body, :max_count, :sort_by_date, search_engine_ids: [])
	end
end
