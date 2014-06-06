# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
window.trackOn = (id) -> 
	$.ajax(url: "/queries/" + id + "/start_work").done (html) ->
  		$("#track_button" + id).html("<button type=\"button\" class=\"btn btn-success btn-lg btn-block\" onclick=\"trackOff(" + id + ")\">Отслеживать</button>")

window.trackOff = (id) -> 
	$.ajax(url: "/queries/" + id + "/stop_work").done (html) ->
  		$("#track_button" + id).html("<button type=\"button\" class=\"btn btn-primary btn-lg btn-block\" onclick=\"trackOn(" + id + ")\">Отслеживать</button>")