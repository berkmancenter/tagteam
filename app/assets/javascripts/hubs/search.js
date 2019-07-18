$(function () {
  $('#hub_search_form .datepicker').datepicker({
    changeMonth: true,
    changeYear: true,
    changeDay: true,
    yearRange: 'c-500',
    dateFormat: 'mm/dd/yy',
    onChangeMonthYear: function (year, month, inst) {
      var dayToday = new Date().getDate()
      var date = $(this).val()
      if (inst.currentDay !== 0) {
        currentDay = inst.currentDay
      } else {
        currentDay = dayToday
      }
      var newDate = month + '/' + currentDay + '/' + year
      var newDateObject = new Date(newDate)
      $(this).val($.datepicker.formatDate('mm/dd/yy', newDateObject))
      $(this).datepicker('setDate', newDateObject)
    }
  })

  var searchForm = $('#hub_search_form')
  // Make sure it won't submit empty fields
  searchForm.submit(function () {
    $(this).find(':input').filter(function () {
      return !this.value
    }).attr('disabled', 'disabled')

    return true
  })
  // Un-disable form fields when page loads, in case they click back after submission
  searchForm.find(':input').prop('disabled', false)
})
