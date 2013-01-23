( function($){

	$.extend({
		rootPath: function(){
			return '/';
    },
    showSpinner: function(){
      $('#spinner').show();
    },
    hideSpinner: function(){
      $('#spinner').hide();
    }, 
    showMajorError: function(jqXHR,textStatus,errorThrown){
      if (window.console && console.log){
        console.log(jqXHR);
        console.log(textStatus);
        console.log(errorThrown);
      }
      if(errorThrown != '' && textStatus != 'abort'){
        $('<div></div>').html("There appears to have been an error.<br/><p class='error'>" + jqXHR.responseText + '</p>').dialog({
          modal: true
          }).dialog({modal: true, width: 700, height: 'auto'}).dialog('open');
        }
    },
    initPerPage: function(){
      $('.per_page_selector').val($.cookie('per_page') || 25);
    },
    observeListPagination: function(){
      if($('.search_results,.ui-widget-content').length > 0){
        // Only allow ajax-y stuff when actually in ajax-y context.
        $('.pagination a').live('click',function(e){
          var paginationTarget = $(this).closest('.search_results,.ui-widget-content');
          e.preventDefault();
          $.ajax({
            type: 'GET',
            url: $(this).attr('href'),
            dataType: 'html',
            beforeSend: function(){
              $.showSpinner();
            },
            success: function(html){
              $(paginationTarget).html(html);
            }
          });
        });
        $('.per_page_selector').live('change', function(e){
          e.preventDefault();
          $.cookie('per_page',$(this).val(), {expires: 365, path: $.rootPath()});
          var paginationTarget = $(this).closest('.search_results,.ui-widget-content');
          var paginationLink = $(this).parent().prev().find('a').first().attr('href').replace(/page=\d+/,'page=1');
          if (! paginationLink.match(/page=\d+/)){
            paginationLink = paginationLink + "&page=1";
          }
          $.ajax({
            type: 'GET',
            url: paginationLink,
            dataType: 'html',
            beforeSend: function(){
              $.showSpinner();
            },
            success: function(html){
              $(paginationTarget).html(html);
            }
          });
        });
      }
    },
    observeDialogShow: function(rootClass){
      $(rootClass).live('click',function(e){
        e.preventDefault();
        var windowTitle = $(this).attr('title');
        $.ajax({
          dataType: 'html',
          url: $(this).attr('href'),
          success: function(html){
            var dialogNode = $('<div><div id="dialog-error" class="error" style="display:none;"></div><div id="dialog-notice" class="notice" style="display:none;"></div></div>');
            $(dialogNode).append(html);
            $(dialogNode).dialog({
              modal: true,
              width: 600,
              minWidth: 400,
              height: 'auto',
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
              beforeLoad: function(){
                $.showSpinner();
              },
              ajaxOptions: {
                dataType: 'html',
                complete: function(){
                  $.checkPlaceholders();
                  $.initPerPage();
                  $.hideSpinner();
                  $.initTabHistory('.tabs');
                },
                error: function(jqXHR,textStatus,errorThrown){
                  $.showMajorError(jqXHR,textStatus,errorThrown);
                }
              }
            });
          }
        });
      });
    },
    submitTagFilter: function(href,filter_type,tag_id,new_tag,modify_tag){
      $.ajax({
        dataType: 'html',
        cache: false,
        url: href,
        type: 'post',
        data: {filter_type: filter_type, tag_id: tag_id, new_tag: new_tag, modify_tag: modify_tag},
        success: function(html){
          window.location.reload();
        }
      });
    },
    bindHoverRows: function(){
/*      $('.hover_row').hoverIntent(
        function(){
          $(this).addClass('over');
        },
        function(){
          $(this).removeClass('over');
        }
        ); */
       $('.hover_row').live({
         mouseover: function(){
           $(this).addClass('over');
         },
         mouseout: function(){
           $(this).removeClass('over');
         }
       });
    },
    observeTagCloudControls: function(){
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
    },

    observeSearchSelectControl: function(){
      $('.search_select_control').live({
        click: function(e){
          e.preventDefault();
          $(this).closest('span.search_select').remove();
        }
      });
    },

    observeAutocomplete: function(url, rootId, paramName, containerId, elementClass){
      function split( val ) {
        return val.split( /,\s*/ );
      }
      function extractLast( term ) {
        return split( term ).pop();
      }
      $( rootId )
      .bind( "keydown", function( event ) {
        if ( event.keyCode === $.ui.keyCode.TAB &&
        $( this ).data( "autocomplete" ).menu.active ) {
          event.preventDefault();
        }
      })
      .autocomplete({
        source: function( request, response ) {
          $.getJSON( url, {
            term: extractLast( request.term )
          }, response );
        },
        search: function() {
          // custom minLength
          var term = extractLast( this.value );
          if ( term.length < 2 ) {
            return false;
          }
        },
        focus: function() {
          // prevent value inserted on focus
          return false;
        },
        select: function( event, ui ) {
          var node = $('<span />').attr('class', elementClass);
          $(node).html($('<input name="' + paramName + '[]" type="hidden" />').val(ui.item.id));
          $(node).append(ui.item.label);
          $(node).append('<span class="search_select_control"> X </span>');
          $(containerId).show().append(node);
          this.value = "";
          return false;
        }
      });
    },
    initNicEditor: function(textArea){
      if($(textArea).attr('id') != undefined){
        new nicEditor({
          iconsPath: $.rootPath() + 'images/nicEditorIcons.gif', 
          maxHeight: 300,
          buttonList: ['bold','italic','left','center','right','justify','ol','ul','subscript','superscript','strikethrough','removeformat','indent','outdent','hr','image','forecolor','link','unlink','fontFormat','xhtml']
        }).panelInstance($(textArea).attr('id'));
      }
    },
    initBookmarkCollectionChoices: function(hubChoiceId){
      $.cookie('bookmarklet_hub_choice', hubChoiceId, {expires: 365, path: $.rootPath()});
      $.ajax({
        type: 'GET',
        cache: false,
        url: $.rootPath() + 'hubs/' + hubChoiceId + '/my_bookmark_collections',
        dataType: 'json',
        success: function(json){
          $('#feed_item_bookmark_collection_id_input').show();
          $('#feed_item_tag_list_input').show();
          $('#feed_item_bookmark_collection_id').html('');
          $(json.feeds).each(function(i,bookmarkCollectionObj){
            $('#feed_item_bookmark_collection_id').append(
              $('<option />').attr({value: bookmarkCollectionObj.id}).text(bookmarkCollectionObj.title)
            );
          });

          if($.cookie('bookmarklet_bookmark_collection_id_choice') != undefined ){
            $('#feed_item_bookmark_collection_id').val($.cookie('bookmarklet_bookmark_collection_id_choice'));
          }

          $('#feed_item_bookmark_collection_id').change(function(){
            $.cookie('bookmarklet_bookmark_collection_id_choice', $(this).val(), {expires: 365, path: $.rootPath()});
          });

          $.observeSearchSelectControl();

          function split( val ) {
            return val.split( /,\s*/ );
          }
          function extractLast( term ) {
            return split( term ).pop();
          }

          $( "#feed_item_tag_list" )
          .bind( "keydown", function( event ) {
            if ( event.keyCode === $.ui.keyCode.TAB &&
            $( this ).data( "autocomplete" ).menu.active ) {
              event.preventDefault();
            }
          })
          .autocomplete({
            source: function( request, response ) {
              $.getJSON( $.rootPath() + 'hubs/' + hubChoiceId + '/tags/autocomplete', {
                term: extractLast( request.term )
              }, response );
            },
            search: function() {
              // custom minLength
              var term = extractLast( this.value );
              if ( term.length < 2 ) {
                return false;
              }
            },
            focus: function() {
              // prevent value inserted on focus
              return false;
            },
            select: function( event, ui ) {
              var terms = split( this.value );
              // remove the current input
              terms.pop();
              // add the selected item
              terms.push( ui.item.value );
              // add placeholder to get the comma-and-space at the end
              terms.push( "" );
              this.value = terms.join( ", " );
              return false;
            }
          });

        }
      });
    },
    observeHubSelector: function(){
      if($.cookie('bookmarklet_hub_choice') != undefined){
        // A selection! Set the defaults.
        $('#feed_item_hub_id').val($.cookie('bookmarklet_hub_choice'));
        $.initBookmarkCollectionChoices($.cookie('bookmarklet_hub_choice'));
      }
      $('#feed_item_hub_id').change(function(){
        $.initBookmarkCollectionChoices($(this).val());
      });
    },
    initBookmarklet: function(tagJsonOutput){
      $('#feed_item_bookmark_collection_id_input').hide();
      $('#feed_item_tag_list_input').hide();
      $.observeHubSelector();
      $('.bookmarklet_tabs').tabs();
      $('.datepicker').datepicker({
        changeMonth: true,
        changeYear:true,
        changeDay: true,
        yearRange: 'c-500',
        dateFormat: 'yy-mm-dd'
      });
      $.initNicEditor($('#feed_item_description'));
        // <span class="search_select tag"><input name="include_tag_ids[]" type="hidden" value="<%= tag.id %>" /><%= tag.name %><span class="search_select_control"> X </span></span>
      $(tagJsonOutput).each(function(i,el){
        $('#feed_item_tag_list_input').append(
          $('<span class="search_select tag" />')
          .append($('<input name="tag_ids[]" type="hidden"/>').val(el.id))
          .append(el.name)
          .append('<span class="search_select_control"> X </span>')
          );
      });
    },
    checkPlaceholders: function(){
      if(!Modernizr.input.placeholder){
        $('[placeholder]').focus(function() {
          var input = $(this);
          if (input.val() == input.attr('placeholder')) {
            input.val('');
            input.removeClass('placeholder');
          }
        }).blur(function() {
          var input = $(this);
          if (input.val() == '' || input.val() == input.attr('placeholder')) {
            input.addClass('placeholder');
            input.val(input.attr('placeholder'));
          }
        }).blur();
        $('[placeholder]').parents('form').submit(function() {
          $(this).find('[placeholder]').each(function() {
            var input = $(this);
            if (input.val() == input.attr('placeholder')) {
              input.val('');
            }
          })
        });
      }
    },
    refreshBackgroundActivity: function(){
      $.ajax({
        url: $.rootPath() + 'hubs/background_activity',
        dataType: 'json',
        cache: false,
        success: function(json){
          $('#activity').html('');
          if(json.running.length == 0){
            $('#activity').html('<p>No background jobs are currently running.</p>');
          } else {
            $('#activity').html('<ul></ul>');
            $(json.running).each(function(i,job){
              $('#activity ul').append('<li>' + job.description + ' since "' + job.since + '", running for ' + job.running_for + '</li>');
            });
            if(json.queued > 0){
              $('#activity ul').append('<li>' + json.queued + ' more jobs queued' + '</li>')
            }
          }
        }
      });
    },
    initTabHistory: function(tabClass){
      if($(tabClass).length > 0){
        var tabs = $(tabClass);
        var tab_a_selector = 'ul.ui-tabs-nav a';
        tabs.tabs({ event: 'change' });
        tabs.find( tab_a_selector ).click(function(){
          var state = {};
          id = $(this).closest( tabClass ).attr( 'id' );
          idx = $(this).parent().prevAll().length;
          state[ id ] = idx;
          $.bbq.pushState( state );
        });

        $(window).bind( 'hashchange', function(e) {
          tabs.each(function(){
            var idx = $.bbq.getState( this.id, true ) || 0;
            $(this).find( tab_a_selector ).eq( idx ).triggerHandler( 'change' );
          });
        });
      }
    },
    simpleClassFilter: function(filterContainer,objectSelector){

      $('.filter_control').live({click: function(){
        $(objectSelector + '.' + $(this).attr('id')).toggle();
      }});
      $('#reset_filter').live({click: function(){
        $(objectSelector).show();
      }});

      var classesOfImport = {};
      $(objectSelector).each(function(){
        classesOfImport[$(this).attr('class')] = 1;
      });
      $.each(classesOfImport,function(key,value){
        $(filterContainer).append($('<span/> ').attr({id: key, 'class': 'filter_control'}).html(key + ' '));
      });

      $(filterContainer).append($('<span/> ').attr({id: 'reset_filter' }).html("<strong>Show all</strong>"));


    },

});

})(jQuery);

$(document).ready(function(){
  $.initTabHistory('.hub_tabs');
  $.initTabHistory('.tabs');
  $(window).trigger( 'hashchange' );

  if($('#user_role_list').length > 0){
    $.simpleClassFilter('#user_role_filter_container','#user_role_list li');
  }

  $('#background_jobs').click(function(e){
    e.preventDefault();
    var dialogNode = $('<div><div id="activity"></div></div>');
    $(dialogNode).dialog({
      modal: true,
      height: 'auto',
      width: 600,
      title: 'Background jobs running in this TagTeam',
      create: function(){
        $.refreshBackgroundActivity();
      },
      buttons: {
        Refresh: function(){
          $.refreshBackgroundActivity();
        },
        Close: function(){
          $(dialogNode).dialog('close');
          $(dialogNode).remove();
        }
      }
    });
  });

  $.checkPlaceholders();


  $.ajaxSetup({
    beforeSend: function(){
      $.showSpinner();
    },
    complete: function(){
      $.initPerPage();
      $.hideSpinner();
    },
    error: function(jqXHR,textStatus,errorThrown){
      $.showMajorError(jqXHR,textStatus,errorThrown);
    }
  });

  jQuery.bt.options.ajaxCache = false;
  jQuery.bt.options.fill = '#dddddd';
  jQuery.bt.options.strokeWidth = 2;
  jQuery.bt.options.strokeStyle = '#999';
  jQuery.bt.options.textzIndex = 999;
  jQuery.bt.options.boxzIndex = 998;
  jQuery.bt.options.wrapperzIndex = 997;
  jQuery.bt.options.postShow = function(){
    $.hideSpinner();
  };

  $('#new_feed_item,#edit_feed_item').submit(function(e){
    $.showSpinner();
  });

  $('.hub_tabs').tabs({
    cookie: {
      expires: 3 
    },
    beforeLoad: function(){
      $.showSpinner();
    },
    ajaxOptions: {
      error: function(jqXHR,textStatus,errorThrown){
        $.showMajorError(jqXHR,textStatus,errorThrown);
      },
      complete: function(){
        $.checkPlaceholders();
        $.initPerPage();
        $.hideSpinner();
        $('#add_feed_to_hub').ajaxForm({
          dataType: 'html',
          beforeSend: function(){
            $.showSpinner();
            $('.add_feed_container .messages').html('');
          },
          complete: function(){
            $.hideSpinner();
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
  
  // bound dynamically b/c the jquery ui tabs() function creates elements
  $('.hub_tabs .ui-tabs-nav').addClass('grid_3');
  $('.hub_tabs .ui-tabs-panel').addClass('grid_13');
  $('.hub_tabs').append('<div class="clear"></div>');

  $.bindHoverRows();

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

  // For tabs that need minimal options.
  $('.tabs').tabs({
    cookie: {
      expires: 3
    },
    beforeLoad: function(){
      $.showSpinner();
    },
    ajaxOptions: {
      dataType: 'html',
      complete: function(){
        $.checkPlaceholders();
        $.initPerPage();
        $.hideSpinner();
      },
      error: function(jqXHR,textStatus,errorThrown){
        $.showMajorError(jqXHR,textStatus,errorThrown);
      }
    }
  });

  // bound dynamically b/c the jquery ui tabs() function creates elements
  $('.tabs .ui-tabs-nav').addClass('grid_3');
  $('.tabs .ui-tabs-panel').addClass('grid_13');
  $('.tabs').append('<div class="clear"></div>');

  if($('#logged_in').length > 0){

    $('textarea').not('.noNicEditor').each(function(){
      $.initNicEditor(this);
    });

    $('.tag').live({
      click: function(e){
        e.preventDefault();

        var tag_id = $(this).attr('data_tag_id') || 0;
        if(tag_id == 0){
          return false;
        }
        var hub_id = $(this).attr('data_hub_id') || 0;
        var hub_feed_id = $(this).attr('data_hub_feed_id') || 0;
        var hub_feed_item_id = $(this).attr('data_hub_feed_item_id') || 0;
        
        $(this).bt({
          ajaxPath: $.rootPath() + 'hubs/' + hub_id + '/tag_controls/?tag_id=' + tag_id + '&hub_feed_id=' + hub_feed_id + '&hub_feed_item_id=' + hub_feed_item_id,
          trigger: 'none',
          closeWhenOthersOpen: true,
          clickAnywhereToClose: true
        });
        $(this).btOn();
      }
    });
    $('.add_filter_control').live({
      click: function(e){
        e.preventDefault();
        var tag_id = $(this).attr('data_id');
        var hub_id = $(this).attr('data_hub_id');
        var filter_type = $(this).attr('data_type');
        var filter_href = $(this).attr('href');
        if(filter_type == 'ModifyTagFilter' || (filter_type == 'AddTagFilter' && tag_id == undefined) || (filter_type == 'DeleteTagFilter' && tag_id == undefined)){
          var dialogNode = $('<div><div id="dialog-error" class="error" style="display:none;"></div><div id="dialog-notice" class="notice" style="display:none;"></div></div>');
          var message = '';
          var prepend = '';
          if(filter_type == 'AddTagFilter'){
            message = "<h2>Please enter the tag you'd like to add<h2>";
          } else if (filter_type == 'ModifyTagFilter') {
            if(tag_id == undefined){
              prepend = "<h2>Please enter the tag you want to replace</h2><input type='text' id='modify_tag_for_filter' size='40' /><div id='replace_tag_container'></div>";
            }
            message = "<h2>Please enter the replacement tag</h2>";
          } else if (filter_type == 'DeleteTagFilter'){
            message = "<h2>Please enter the tag you'd like to remove</h2>";
          }
          $(dialogNode).append(prepend + '<h2>' + message + '</h2><input type="text" id="new_tag_for_filter" size="40" /><div id="new_tag_container"></div>');
          $(dialogNode).dialog({
            modal: true,
            width: 600,
            minWidth: 400,
            height: 'auto',
            title: '',
            create: function(){
              $( "#new_tag_for_filter,#modify_tag_for_filter" ).autocomplete({
                source: $.rootPath() + "hubs/" + hub_id + "/tags/autocomplete",
                minLength: 2
              });
            },
            buttons: {
              Close: function(){
                $(dialogNode).dialog('close');
                $(dialogNode).remove();
              },
              Submit: function(){
                var replace_tag = undefined;
                if($('#modify_tag_for_filter').length > 0){
                  replace_tag = $('#modify_tag_for_filter').val();
                }
                $.submitTagFilter(filter_href, filter_type, tag_id, $('#new_tag_for_filter').val(), replace_tag);
                $(dialogNode).dialog('close');
                $(dialogNode).remove();
              }
            }
          });
          return false;
        }
        $.submitTagFilter($(this).attr('href'), filter_type, tag_id,'','');
      }
    });
  }

  $('.control').live({
    click: function(e){
      e.preventDefault();
      var url = $(this).attr('href');
      $(this).bt({
        trigger: 'none',
        ajaxPath: url,
        closeWhenOthersOpen: true
      });
      $(this).btOn();
    }
  });

  $('.hub_feed_more_control,.republished_feed_more_control').live({
    click: function(e){
      e.preventDefault();
      if($(this).hasClass('more_details_included')){
        $(this).closest('tr').after().next().remove();
        $(this).removeClass('more_details_included');
        $(this).removeClass('ui-silk-bullet-toggle-minus');
        $(this).addClass('ui-silk-bullet-toggle-plus');
        return;
      }
      var elem = this;
      $.ajax({
        url: $(this).attr('href'),
        success: function(html){
          $(elem).addClass('more_details_included');
          $(elem).closest('tr').after(html);
          $(elem).removeClass('ui-silk-bullet-toggle-plus');
          $(elem).addClass('ui-silk-bullet-toggle-minus');
        }
      });
    }
  });

  if($('.ui-widget-content').length > 0){
    $('#hub_search_form,#hub_tag_search_form').live({
      submit: function(e){
        e.preventDefault();
        $(this).ajaxSubmit({
          success: function(html){
            $('#hub_search_form').closest('.ui-widget-content').html(html);
          }
        });
      }
    });
  }

  $.observeDialogShow('.dialog-show');

  $('a.add_item_source_to_custom_republished_feed,a.remove_item_source_from_custom_republished_feed').live({
    click: function(e){
      $('body').data('item_source_id_for_republishing', $(this).attr('data_item_id'));
      $('body').data('item_source_type_for_republishing', $(this).attr('data_item_type'));
      if($(this).hasClass('add_item_source_to_custom_republished_feed')){
        $('body').data('item_effect_for_republishing', 'add');
      } else {
        $('body').data('item_effect_for_republishing', 'remove');
      }
    }
  });

  $('a.choose_republished_feed').live({
    click: function(e){
      e.preventDefault();
      var republished_feed_id = $(this).attr('data_id');
      var item_source_id = $('body').data('item_source_id_for_republishing');
      var item_source_type = $('body').data('item_source_type_for_republishing');
      var item_effect = $('body').data('item_effect_for_republishing');
      // TODO - make this emit when it's been added.
      $.ajax({
        cache: false,
        dataType: 'html',
        url: $.rootPath() + 'input_sources',
        type: 'post',
        data:{ input_source: {republished_feed_id: republished_feed_id, item_source_type: item_source_type, item_source_id: item_source_id, effect: item_effect}},
        beforeSend: function(){ 
          $.showSpinner();
          $('#dialog-error,#dialog-notice').html('').hide();
        },
        complete: function(){ $.hideSpinner();},
        success: function(html){
          $('#dialog-notice').show().html(html);
        },
        error: function(jqXHR, textStatus, errorThrown){
          $('#dialog-error').show().html(jqXHR.responseText);
        }
      });
    }
  });
  $.observeListPagination();

});
