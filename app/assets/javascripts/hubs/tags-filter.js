/* globals $ */
this.observeTagFilterControls = function () {
  $('#reset-filter').click(function (e) {
    $('#tag-cloud li').show()
    $('#filter-by').val('')
  })

  var filterStuff = function (e) {
    if (e !== '') {
      e.preventDefault()
    }

    $('#tag-cloud li').show()

    var filterVal = $('#filter-by').val()
    var filterregex = new RegExp(filterVal, 'i')

    $('#tag-cloud li').each(function () {
      if (!$(this).find('.tag').html().match(filterregex)) {
        $(this).hide()
      }
    })
  }

  $('#filter-button').click(filterStuff)
  $('#filter-by').observe_field(1, filterStuff)
}
