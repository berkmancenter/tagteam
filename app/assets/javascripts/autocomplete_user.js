/* global $ */
$.extend({
  observeSearchSelectControl () {
    $('.search_select_control').live({
      click (e) {
        e.preventDefault();

        var container = $(this).closest('ul');

        $(this).closest('li.search_select').remove();

        if (container.children('li').length === 0) {
          $('input#add_roles').prop('disabled', true);
        }
      }
    });
  },

  observeAutocomplete (url, rootId, paramName, containerId, elementClass, singleValue) {
    function split (val) {
      return val.split(/,\s*/);
    }

    function extractLast (term) {
      return split(term).pop();
    }

    $(rootId)
      .live('keydown', function (event) {
        if (event.keyCode === $.ui.keyCode.TAB && $(this).data('autocomplete').menu.active) {
          event.preventDefault();
        }
      })
      .live('focus', function () {
        $(this)
          .autocomplete({
            source (request, response) {
              $.getJSON(url, {
                term: extractLast(request.term)
              }, response);
            },
            search () {
              const term = extractLast(this.value);
              if (term.length < 2) {
                return false;
              }
            },
            focus () {
              return false;
            },
            select (event, ui) {
              if (typeof singleValue != 'undefined' && singleValue === true) {
                $(containerId).empty();
              }
              
              const node = $('<li>').attr('class', elementClass);
              $(node).html($(`<input name="${paramName}[]" type="hidden" />`).val(ui.item.value));
              $(node).append(ui.item.label);
              $(node).append('<span class="search_select_control"> X </span>');
              $(containerId).show().append(node);
              $('input#add_roles').prop('disabled', false);
              this.value = '';
              return false;
            }
          });
      });
  }
});
