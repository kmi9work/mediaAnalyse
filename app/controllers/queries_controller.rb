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
		@query = Query.find(params[:query_id])
		@query.track = true
		@query.save
		ses = @query.search_engines
		ses.each do |se|
			fl = (se.tracked_count == 0)
			se.tracked_count = se.queries.where(track: true).count
			se.save
			if Delayed::Job.count == 0 or (fl and se.tracked_count == 1)
				puts "Track started.\n\n\n\n"
				se.delay.track!
			end
		end
		respond_to do |format|
			format.html { redirect_to :back}
			format.json { render :none }
		end
	end

	def stop_work
		@query = Query.find(params[:query_id])
		@query.track = false
		@query.save
		ses = @query.search_engines
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
		@texts = @query.from_to(params[:from], params[:to])
		# @query.texts.where(novel: true).each{|t| t.novel = false; t.save}
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
		texts = query.texts.order(:created_at)
		#Faster with right sql-query: select emot, created_at from texts
		return render(json: [[]].to_json) if texts.empty?
		med = texts[0].my_emot || texts[0].emot
		n = 1.0
		fst = texts[0].created_at
		chdata = []
		for i in 1...texts.count
			if texts[i].created_at - fst > 3600 # Все новости за час.
				chdata << [fst.strftime("%d.%m.%y %H:%M"), med / n]
				fst = texts[i].created_at
				med = texts[i].my_emot || texts[i].emot
				n = 1.0
			else
				med += texts[i].my_emot || texts[i].emot
				n += 1.0
			end
		end
		chdata << [fst.strftime("%d.%m.%y %H:%M"), med / n]
		render json: chdata.to_json
	end
	private
	def query_params
		params.require(:query).permit(:id, :title, :body, :max_count, search_engine_ids: [])
	end
end
