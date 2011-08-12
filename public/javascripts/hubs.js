$(document).ready(function(){

  $('.more').live({
    mouseover: function(){
      $(this).css('cursor','pointer');
    },
    click: function(e){
      e.preventDefault();
      var id = $(this).attr('id').split('_')[3];
      $('#hub_feed_metadata_' + id).toggle('medium');
    }
  });

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
        $.ajax({
          dataType: 'html',
          url: $.rootPath() + 'hubs/' + hubId + '/feeds',
          success: function(data){
            $('#hub_feed_list_' + hubId).html(data);
          }
        });
      },
      error: function(jqXHR){
        $('.add_feed_container .messages').append('<div class="error">' + jqXHR.responseText + '</div>');
      }

    });
  });
});
