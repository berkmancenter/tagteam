/* globals $ */
this.observeTagSortControls = function () {
  var sortTagsOnChange = function (e) {
    var sortBy = $('#sort-tags-by').val()
    var sort = $('#sort-tags-direction').val()

    var mappingFunction = function (elem) {
      var attributes = {}

      attributes.frequency = $(elem).find('.tag').data('tag-frequency')
      attributes.name = $(elem).find('.tag').data('tag-name').toString()

      return attributes
    }

    var compareFunction = function (a, b) {
      if (sortBy === 'frequency' && sort === 'desc') {
        return (b.value.frequency - a.value.frequency) || (b.value.frequency === a.value.frequency && a.value.name.localeCompare(b.value.name))
      } else if (sortBy === 'frequency' && sort === 'asc') {
        return (a.value.frequency - b.value.frequency) || (b.value.frequency === a.value.frequency && a.value.name.localeCompare(b.value.name))
      } else if (sortBy === 'alpha' && sort === 'asc') {
        return a.value.name.localeCompare(b.value.name)
      } else if (sortBy === 'alpha' && sort === 'desc') {
        return b.value.name.localeCompare(a.value.name)
      } else {
        return null
      }
    }

    $('#tag-cloud').detach(function () {
      $(this).sortChildren(mappingFunction, compareFunction)
    })
  }

  $('#sort-tags-by').change(sortTagsOnChange)
  $('#sort-tags-direction').change(sortTagsOnChange)
}
