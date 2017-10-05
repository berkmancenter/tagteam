$('#active-taggers-month, #active-taggers-year')
  .live({ change: fetchActiveHubTaggers })

function fetchActiveHubTaggers (e) {
  var elem = $(this);
  var month = $('#active-taggers-month').val();
  var year = $('#active-taggers-year').val();
  var form = elem.parents('form').first();
  var loader = $('<img src="/images/loader.gif">');

  if (year != 'false') {
    form.find('p').first().append(loader);

    $.ajax({
      url: form.attr('action'),
      data: {
        month: month,
        year: year
      },
      success: function (response) {
        $('#active-taggers-period').html(response);

        loader.remove();

        if (response === 1) {
          $('#active-taggers-label').html('tagger');
        } else {
          $('#active-taggers-label').html('taggers');
        }
      }
    });
  }
}
