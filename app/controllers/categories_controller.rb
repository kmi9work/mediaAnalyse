# http://glava.openregion71.ru/vote/

class CategoriesController < ApplicationController
	before_action :categories_find, only: [:index, :new, :edit, :show, :negative_category]
	before_action :category_find, only: [:edit, :show, :update, :destroy]
	def index
	end

	def new
		@category = Category.new
	end

	def edit
		@queries = @category.queries
	end

	def show
		@queries = @category.queries
	end

	def create
		@category = Category.new(category_params)
		@category.save
		redirect_to @category
	end

	def update
		@category.update(category_params)
		redirect_to @category
	end

	def destroy
		@category.destroy
		respond_to do |format|
	  		format.html { redirect_to categories_url }
	  		format.json { head :no_content }
		end
	end

	def negative_category
		@texts = Text.where('created_at > ?', DateTime.now.beginning_of_day).where("emot < ?", 0)
		@query = Query.new(title: 'Негатив МЧС')
		render 'queries/show'
	end

	private
	def categories_find
		@categories = Category.all
	end
	def category_find
		@category = Category.find(params[:category_id])
	end
	def category_params
		params.require(:category).permit(:id, :title)
	end
end
