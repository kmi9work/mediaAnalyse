class KeyqueriesController < ApplicationController
  def commit_keyquery
    query = Query.find(params[:query_id])
    @keyquery = Keyquery.create(keyquery_params)
    query.keyqueries << @keyquery
    respond_to do |format|
      format.html {redirect_to :back}
      format.js
    end
  end

  def destroy
    @keyquery = Keyquery.find(params[:id])
    @keyquery.destroy
  end
  private
  def keyquery_params
    params.require(:keyquery).permit(:body)
  end
end
