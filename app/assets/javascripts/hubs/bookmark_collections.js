/* globals $ */
$('.hub_feed_more_control, .republished_feed_more_control')
  .live({ click: toggleListItemMetadata })

$('.bookmark-collections-toggler')
  .live({
    click: toggleAllBookmarkCollections
  })

function toggleListItemMetadata (e) {
  e.preventDefault()

  var element = $(this)

  if (element.hasClass('more_details_included')) {
    hideListItemMetadata(element)
  } else {
    showListItemMetadata(element)
  }
}

function hideListItemMetadata (element) {
  element.removeClass('more_details_included')
  element.closest('li').find('.metadata').empty()
  element.find('.fa').removeClass('fa-caret-down').addClass('fa-caret-right')
}

function showListItemMetadata (element) {
  $.ajax({
    url: element.attr('href'),
    success: function (html) {
      element.addClass('more_details_included')
      element.closest('li').find('.metadata').replaceWith(html)
      element.find('.fa').removeClass('fa-caret-right').addClass('fa-caret-down')
    }
  })
}

function toggleAllBookmarkCollections (e) {
  e.preventDefault();

  var toggler = $(this);

  if (toggler.hasClass('more_details_all_open')) {
    $('.hub_feed_more_control, .republished_feed_more_control').each(function (index, el) {
      var element = $(el);

      hideListItemMetadata(element);
    });

    toggler.removeClass('more_details_all_open');
    toggler.find('.fa').removeClass('fa-caret-down').addClass('fa-caret-right')
  } else {
    $('.hub_feed_more_control, .republished_feed_more_control').each(function (index, el) {
      var element = $(el);

      showListItemMetadata(element);
    });

    toggler.addClass('more_details_all_open');
    toggler.find('.fa').removeClass('fa-caret-right').addClass('fa-caret-down');
  }
}
