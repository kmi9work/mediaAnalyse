class EssencesController < ApplicationController
  def commit_essence
    text = Text.find(params[:id])
    @essence = Essence.create(essence_params)
    text.essences << @essence
    respond_to do |format|
      format.html {redirect_to :back}
      format.js
    end
  end

  def destroy
    @essence = Essence.find(params[:id])
    @essence.destroy
  end

private
  def essence_params
    params.require(:essence).permit(:title, :rating)
  end
end
