# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
window.trackOn = (id) -> 
	$.ajax(url: "/queries/" + id + "/start_work").done (html) ->
  		$("#track_button" + id).html("<button type=\"button\" class=\"btn btn-success btn-lg btn-block\" onclick=\"trackOff(" + id + ")\">Остановить</button>")

window.trackOff = (id) -> 
	$.ajax(url: "/queries/" + id + "/stop_work").done (html) ->
  		$("#track_button" + id).html("<button type=\"button\" class=\"btn btn-primary btn-lg btn-block\" onclick=\"trackOn(" + id + ")\">Отслеживать</button>")

# $ -> $(".query_show").click -> 
# 	$.ajax(url: "/queries/" + $(this).attr('queryid')).done (html) ->
# 		$('#texts').html(html)
# 		false

$ -> $(".get_text").click ->
	id = $(this).attr('textid')
	$.ajax(url: "/texts/" + id + "/get_text").done (html) ->
		$("#get_text_" + id).parent().append("<hr> <p>" + html + "</p>")
	false

$ -> $(".get_emot").click ->
	id = $(this).attr('textid')
	$.ajax(url: "/texts/" + id + "/get_emot").done (html) ->
		$("#get_emot_" + id).parent().html("<hr>" + html)
	false
	