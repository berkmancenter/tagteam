$(document).ready(function(){
  $('#add_feed_button').click(function(e){
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
      before_send: function(){
      },
      complete: function(){
      },
      success: function(json){
      },
      error: function(){
      }

    });
  });
});
