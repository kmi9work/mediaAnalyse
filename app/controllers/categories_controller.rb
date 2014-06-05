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

	def show
		@categories = Category.all
		@category = Category.find(params[:id])
		@queries = @category.queries
		render action: 'index'
	end

	def create
		@category = Category.new(category_params)
		respond_to do |format|
	      if @category.save
	        format.html { redirect_to categories_path}
	        format.json { render action: 'show', status: :created, location: @category }
	      else
	        format.html { render action: 'index' }
	        format.json { render json: @category.errors, status: :unprocessable_entity }
	      end
	    end
	end

	def destroy
		@category = Category.find(params[:id])
    	@category.destroy
    	respond_to do |format|
      		format.html { redirect_to categories_url }
      		format.json { head :no_content }
    	end
  	end

	private
	def category_params
		params.require(:category).permit(:id, :title)
	end
end
