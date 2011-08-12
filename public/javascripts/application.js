( function($){

	$.extend({
		rootPath: function(){
			return '/';
		}
	});

})(jQuery);

$(document).ready(function(){
  $('.hover_row').hoverIntent(
    function(){
      $(this).addClass('over');
    },
    function(){
      $(this).removeClass('over');
    }
  );

});
