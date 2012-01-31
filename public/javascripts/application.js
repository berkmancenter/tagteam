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
    showMajorError: function(error){
        $('<div></div>').html("We're sorry, there appears to have been an error.<br/>" + error).dialog({
            modal: true
        }).dialog('open');
    },
    observeListPagination: function(){
      $('.pagination a').live('click',function(e){
        var paginationTarget = $(this).closest('.search_results,.ui-widget-content');
        e.preventDefault();
        $.ajax({
          type: 'GET',
          cache: false,
          url: $(this).attr('href'),
          dataType: 'html',
          beforeSend: function(){
            $.showSpinner();
          },
          error: function(xhr){
            $.showMajorError(xhr);
          },
          complete: function(){
            $.hideSpinner();
          },
          success: function(html){
            $(paginationTarget).html(html);
          }
        });
      });
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
              cookie: {
                expires: 3
              },
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

  jQuery.bt.options.ajaxCache = false;

  if($('#reset_filter').length > 0){

    $('#reset_filter').click(function(e){
      $('.tag').show();
    });
    var filterStuff = function(e){
      if(e != ''){
        e.preventDefault();
      }
      $('a.tag').show();
      var filterVal = $('#filter_by').val();
      var filterregex = new RegExp(filterVal,'i');
      $('a.tag').each(function(){
        if(! $(this).html().match(filterregex)){
          $(this).hide();
        }
      });
    };
    $('#filter_button').click(filterStuff);
    $('#filter_by').observe_field(1,filterStuff);

    $('#tag_slider').slider({
      value: 0,
      min: 0,
      max: 9,
      step: 1,
      slide: function(event, ui){
        $('.tag').show();
        for(var i = 1; i <= ui.value; i=i+1){
          $('.s' + i).hide();
        }
      }
    });
  }
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
  // For tabs that need minimal options.
  $('.tabs').tabs({
    cookie: {
      expires: 3
    },
    ajaxOptions: {
      cache: false,
      dataType: 'html'
    }
  });

  if($('#logged_in').length > 0){
    $('.tag').live({
      click: function(e){
        e.preventDefault();
        var tag_id = $(this).attr('data_tag_id');
        var hub_id = $(this).attr('data_hub_id');
        $(this).bt({
          ajaxPath: $.rootPath() + 'hubs/' + hub_id + '/tag_controls/?tag_id=' + tag_id,
          trigger: 'none',
          closeWhenOthersOpen: true
        });
        $(this).btOn();
      }
    });
    $('.add_filter_control').live({
      click: function(e){
        e.preventDefault();
        $.ajax({
          dataType: 'html',
          cache: false,
          url: $(this).attr('href'),
          type: 'post',
          data: {filter_type: $(this).attr('data_type')}
        });

      }
    });
  }


  $('.control').live({
    click: function(e){
      e.preventDefault();
      var id = $(this).attr('id');
      $(this).bt({
        trigger: 'none',
        contentSelector: $('#' + id + '-target'),
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
          console.log(jqXHR);
          console.log(textStatus);
          console.log(errorThrown);
          $('#dialog-error').show().html(jqXHR.responseText);
        }

      });

    }
  });
  $.observeListPagination();

});
