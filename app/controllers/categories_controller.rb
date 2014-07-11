# http://glava.openregion71.ru/vote/

class CategoriesController < ApplicationController
	def index
		cookies[:track_on] = true
		@categories = Category.all
		if params[:id]
			@category = Category.find(params[:id])
			@queries = @category.queries
		else
			@queries = []
		end
	end

	def new
		@categories = Category.all
		@category = Category.new
	end

	def edit
		@categories = Category.all
		@category = Category.find(params[:id])
	end

	def show
		cookies[:track_on] = false
		@categories = Category.all
		@category = Category.find(params[:id])
		@queries = @category.queries
	end

	def create
		@category = Category.new(category_params)
		@category.save
		redirect_to @category
	end

	def update
		@category = Category.find(params[:id])
		@category.update(category_params)
		redirect_to @category
	end

	def destroy
	@category = Category.find(params[:id])
  	@category.destroy
  	respond_to do |format|
    		format.html { redirect_to categories_url }
    		format.json { head :no_content }
  	end
	end

	def negative_category
		@categories = Category.all
		@texts = Text.where("emot < ?", 0)
		render 'queries/show'
	end

	private
	def category_params
		params.require(:category).permit(:id, :title)
	end
end
