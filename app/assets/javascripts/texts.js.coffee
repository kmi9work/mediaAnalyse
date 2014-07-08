# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ -> setTimeout(getNewLinks, 3000)

window.track_on = true

window.getNewLinks = () -> 
  if track_on 
    $.ajax(url: "/texts/get_new_links").done (respond) ->
      respond.html.forEach (text) ->
        $().toastmessage('showToast', {text: text.content, sticky: false, type: text.type, position: 'bottom-right'})
      $('.qtexts_count').each (span) ->
        $(this).html(respond.counts[$(this).attr('id')])
    setTimeout(getNewLinks, 7000)