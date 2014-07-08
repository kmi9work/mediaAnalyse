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
			se.tracked_count = se.queries.where(track: true).count
			se.save
			if se.tracked_count == 1 || Delayed::Job.count == 0
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
		@texts = @query.texts
		@query.texts.where(novel: true).each{|t| t.novel = false; t.save}
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
	private
	def query_params
		params.require(:query).permit(:id, :title, :body, :max_count, search_engine_ids: [])
	end
end
