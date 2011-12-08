$(document).ready(function(){

  $('.hub_tabs').tabs({
    cookie: {
      expires: 3 
    },
    ajaxOptions: {
      beforeSend: function(){
        $.showSpinner('#spinner');
      },
      complete: function(){
        $.hideSpinner('#spinner');
        $('#add_feed_to_hub').ajaxForm({
          dataType: 'html',
          beforeSend: function(){
            $('#add_feed_button').append('<img src="' + $.rootPath() + 'images/spinner.gif" id="feedaddspinner" />');
            $('.add_feed_container .messages').html('');
          },
          complete: function(){
            $('#feedaddspinner').remove();
          },
          success: function(html){
            $('.add_feed_container .messages').append('<div class="notice">' + html + '</div>');
            // Update the feed list.
            var current_index = $('.hub_tabs').tabs('option','selected');
            $('.hub_tabs').tabs('load',current_index);
          },
          error: function(jqXHR){
            $('.add_feed_container .messages').append('<div class="error">' + jqXHR.responseText + '</div>');
          }
        });
      }
    }
  });

});
