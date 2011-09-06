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

  $('.more').live({
    mouseover: function(){
      $(this).css('cursor','pointer');
    },
    click: function(e){
      e.preventDefault();
      var id = $(this).attr('id').split('_')[3];
      if($(this).attr('id').match(/republished/)){
        $('#republished_feed_metadata_' + id).toggle('medium');
      } else{
        $('#hub_feed_metadata_' + id).toggle('medium');
      }
    }
  });

});
