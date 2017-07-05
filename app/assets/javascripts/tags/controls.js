/* globals $ */
$(function () {
  if ($('#logged_in, #bookmarklet-tag-controls-allowed').length > 0) {
    $('.tag').live({
      click: function (e) {
        e.preventDefault()

        var tagId = $(this).attr('data-tag-id') || 0

        if (tagId === 0) {
          return false
        }

        var hubId = $(this).attr('data-hub-id') || 0
        var hubFeedId = $(this).attr('data-hub-feed-id') || 0
        var hubFeedItemId = $(this).attr('data-hub-feed-item-id') || 0
        var anchor = $(this).parents('td').find('div a').first()

        if (anchor) {
          var anchorHTML = anchor.html()

          if (anchorHTML !== '' && anchorHTML !== null && anchorHTML !== undefined) {
            document.cookie = 'return_to=' + anchorHTML
          }
        }

        $(this).bt({
          ajaxPath: $.rootPath() + 'hubs/' + hubId + '/tag_controls/?tag_id=' + tagId + '&hub_feed_id=' + hubFeedId + '&hub_feed_item_id=' + hubFeedItemId,
          trigger: 'none',
          closeWhenOthersOpen: true,
          clickAnywhereToClose: true
        })

        $(this).btOn()
      }
    })
  }
})
