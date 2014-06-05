class QueriesController < ApplicationController
	def new
		if params[:category_id]
			@category = Category.find(params[:category_id])
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
		redirect_to categories_path(@category.id)
	end
	private
	def query_params
		params.require(:query).permit(:id, :title, :body, :search_engine, :max_count)
	end
end
