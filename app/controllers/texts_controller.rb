class TextsController < ApplicationController

	def get_text
		@text = Text.find(params[:id])
		render :text => @text.get_text, layout: false
	end
end
