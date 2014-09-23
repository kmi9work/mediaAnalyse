class TextsController < ApplicationController
	def show
		@categories = Category.all
		@category = Category.find(params[:category_id])
		@queries = @category.queries
		@query = Query.find(params[:query_id])
		@text = Text.find(params[:id])
		# @essence = @text.essences.build
	end
	def get_text
		@text = Text.find(params[:id])
		render :text => @text.get_text, layout: false
	end

	def get_emot
		@text = Text.find(params[:id])
		@data = @text.get_emot
		render 'get_emot', layout: false
	end
	def feedback
		text = Text.find(params[:id])
		text.my_emot = params[:score]
		text.save
		render nothing: true
	end
end
