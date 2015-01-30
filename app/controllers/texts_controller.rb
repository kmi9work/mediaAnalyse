class TextsController < ApplicationController
  skip_before_filter :require_login, only: :feedback
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
    data = text.title + (text.content || text.description)
    uri = URI('http://emot.zaelab.ru/feedback.json')
    res = Net::HTTP.post_form(uri, 'text' => data, 'score' => text.my_emot, 'revision' => 2)
    @code = res.code
    render text: @code
  end
end
