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
            var dialogNode = $('<div><div id="dialog-error" class="error" style="display:none;"></div><div id="dialog-notice" class="notice" style="display:none;"></div></div>');
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
  $('a.add_item_source_to_custom_republished_feed').live({
    click: function(e){
      var item_source = $(this).attr('id').split('-');
      $('body').data('item_source_id_for_republishing', item_source[1]);
      $('body').data('item_source_type_for_republishing', item_source[0]);
    }
  });

  $('a.choose_republished_feed').live({
    click: function(e){
      e.preventDefault();
      var republished_feed_id = $(this).attr('id').split('-')[1];
      var item_source_id = $('body').data('item_source_id_for_republishing');
      var item_source_type = $('body').data('item_source_type_for_republishing');
      // TODO - make this emit when it's been added.
      $.ajax({
        cache: false,
        dataType: 'html',
        url: $.rootPath() + 'input_sources',
        type: 'post',
        data:{ input_source: {republished_feed_id: republished_feed_id, item_source_type: item_source_type, item_source_id: item_source_id, effect: 'add'}},
        beforeSend: function(){ 
          $.showSpinner();
          $('#dialog-error,#dialog-notice').html('').hide();
        },
        complete: function(){ $.hideSpinner();},
        success: function(html){
          $('#dialog-notice').show().html(html);
        },
        error: function(jqXHR, textStatus, errorThrown){
          // FIXME. Get the actual error message to display.
          $('#dialog-error').show().html(errorThrown);
        }

      });

    }
  });

});
