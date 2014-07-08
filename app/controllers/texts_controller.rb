class TextsController < ApplicationController

	def get_new_links
		texts = Text.where(novel: true)
		respond = {}
		respond[:html] = []
		respond[:counts] = {}
		if texts.size > 3
			respond[:html] << {
				content: "Новых текстов: #{texts.size}",
				type: 'notice'
			}
		else
			texts.each do |t| 
				respond[:html] << {
					content: "<a href='#{category_query_path(t.query.category.id, t.query.id)}'><strong> #{t.query.title} </strong></a> <br> <a href='#{t.url}'>#{t.title}</a>", 
					type: t.search_engine.engine_type
				}
			end
		end
		#queryid to id
		Category.all.each{|c| c.queries.each{|q| respond[:counts]["qtexts_count_#{q.id}"] = q.texts.count}}# May be slow!!! May be do it right through SQL.
		render :json => respond.to_json
	end
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
end
