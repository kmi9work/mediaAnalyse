class KeyphrasesController < ApplicationController
	def commit_keyphrase
		query = Query.find(params[:query_id])
	    @keyphrase = Keyphrase.create(keyphrase_params)
	    query.keyphrases << @keyphrase
	    respond_to do |format|
			format.html {redirect_to :back}
			format.js
	    end
  	end

	def destroy
		@keyphrase = Keyphrase.find(params[:id])
		@keyphrase.destroy
	end
	private
	def keyphrase_params
		params.require(:keyphrase).permit(:body)
	end
end
