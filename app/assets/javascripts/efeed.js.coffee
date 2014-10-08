# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ -> setTimeout(getNewEMessages, 3000)

window.track_efeed_on = false

window.getNewEMessages = () -> 
  if track_efeed_on 
    $.ajax(url: "/new_emessages").done (respond) ->
      if respond.tcount > 0
        $('#tcount').html(respond.tcount);
        $('#new_rows').show();
    setTimeout(getNewEMessages, 7000)

$ -> 
  $(':checkbox[name=selectAll]').click () ->
    $(':checkbox[name="select_sources[]"]').prop('checked', this.checked)
