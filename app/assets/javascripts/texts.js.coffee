# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ -> setTimeout(getNewLinks, 3000)

window.track_on = false

window.getNewLinks = () ->
  if track_on
    $.ajax(url: "/texts/get_new_links").done (respond) ->
      $('.qtexts_count').each (span) ->
        $(this).html(respond.counts[$(this).attr('id')])
    setTimeout(getNewLinks, 7000)

$ -> $(".feedback").on("click", (e) ->
  id = $(this).attr('textid')
  my_this = this
  score = document.forms['feedback_' + id]['score'].value
  $.ajax(url: "/texts/" + id + "/feedback?score=" + score).done (respond) ->
    $(my_this).after('Реальная тональность: <div class="emot emot_'+ (parseInt(score) + 3).toString() + '"> ' + score + ' </div>')
    #$(my_this).remove()
  e.preventDefault();
  false;
)
