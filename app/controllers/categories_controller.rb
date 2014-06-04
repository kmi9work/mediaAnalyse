class CategoriesController < ApplicationController
	def index
		@categories = Category.all
		if params[:id]
			@category = Category.find(params[:id])
			@queries = @category.queries
		else
			@queries = []
		end
	end

	def new
		@category = Category.new
	end

	def create
		
	end

	def destroy
		@category = Category.find(params[:id])
    	@category.destroys
    	respond_to do |format|
      		format.html { redirect_to categories_url }
      		format.json { head :no_content }
    	end
  	end

	private
	def category_params
		params.require(:category).permit(:id)
	end
end
