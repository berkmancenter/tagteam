$(document).ready(function(){

  $('#add_feed_button').live({
    click: function(e){
    e.preventDefault();

    var hubId = $('.hub.detailed').first().attr('id').split('_')[1];
    $.ajax({
      type: 'POST',
      cache: false,
      dataType: 'json',
      url: $.rootPath() + 'hubs/' + hubId + '/add_feed',
      data: {
        feed_url: $('#feed_url').val()
      },
      beforeSend: function(){
				$('#add_feed_button').append('<img src="' + $.rootPath() + 'images/spinner.gif" id="feedaddspinner" />');
        $('.add_feed_container .messages').html('');
      },
      complete: function(){
				$('#feedaddspinner').remove();
      },
      success: function(json){
        $('.add_feed_container .messages').append('<div class="notice">' + json.message + '</div>');
        // Update the feed list.
        window.location.reload();
      },
      error: function(jqXHR){
        $('.add_feed_container .messages').append('<div class="error">' + jqXHR.responseText + '</div>');
      }

    });
  }
  });
});
