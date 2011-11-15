( function($){

	$.extend({
		rootPath: function(){
			return '/';
    },
    showSpinner: function(spinnerId){
      var spinnerNode = $(spinnerId);
      $(spinnerNode).html('<img src="' + $.rootPath() + 'images/spinner.gif" />').show();
    },
    hideSpinner: function(spinnerId){
      var spinnerNode = $(spinnerId);
      $(spinnerNode).hide();
    }, 
    observeDialogShow: function(rootClass){
      $(rootClass).live('click',function(e){
        e.preventDefault();
        var windowTitle = $(this).attr('title');
        $.ajax({
          cache: false,
          dataType: 'html',
          url: $(this).attr('href'),
          beforeSend: function(){
            $.showSpinner();
          },
          complete: function(){
            $.hideSpinner();
          },
          error: function(xhr){
            $.showMajorError(xhr);
          },
          success: function(html){
            var dialogNode = $('<div></div>');
            $(dialogNode).append(html);
            $(dialogNode).dialog({
              modal: true,
              width: 600,
              minWidth: 400,
              height: 'auto',
              position: 'top',
              title: windowTitle,
              buttons: {
                Close: function(){
                  $(dialogNode).dialog('close');
                  $(dialogNode).remove();
                },
              }
            });
            $('.tabs').tabs({
              ajaxOptions: {
                cache: false,
                dataType: 'html'
              }
            });
          }
        });
      });

    },
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

  $('.toggler').bind({
    mouseover: function(){
      $(this).css({cursor: 'pointer', textDecoration: 'underline'})
    },
    mouseout: function(){
      $(this).css({textDecoration: 'none'})
    },
    click: function(e){
      e.preventDefault();
      var targetId = '#' + $(this).attr('id') + '-target';
      if($(targetId).is(':visible')){
        $(targetId).hide('medium');
        $(this).find('.toggler-indicator').attr('class', 'toggler-indicator ui-silk ui-silk-arrow-right inline');
      } else {
        $(this).find('.toggler-indicator').attr('class', 'toggler-indicator ui-silk ui-silk-arrow-down inline');
        $(targetId).show('medium');
        if($(this).hasClass('remove_after_toggling')){
          $(this).remove();
        }
        
      }
    }
  });


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
  // For tabs that don't need options.
  $('.tabs').tabs();

  $('.control').live({
    click: function(e){
      e.preventDefault();
      var id = $(this).attr('id');
      $(this).bt({
        trigger: 'none',
        contentSelector: $('#' + id + '-target'),
        textzIndex: 101,
        boxzIndex: 100,
        wrapperzIndex: 99,
        closeWhenOthersOpen: true
      });
      $(this).btOn();
    }
  });

  $.observeDialogShow('.dialog-show');

});
