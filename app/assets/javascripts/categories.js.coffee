# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ -> $('#queries_accord').accordion();

$ -> $( "#queries_accord" ).on( "accordionactivate", ( event, ui ) -> 
	alert( $(ui.newPanel).attr('queryid')) 
);