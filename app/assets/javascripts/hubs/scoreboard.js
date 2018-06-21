$(document).ready(function () {
  $('.scoreboard .nav-tabs a').each(function () {
    if (location.href.indexOf($(this).attr('href')) != -1) {
      $(this).click();
    }
  });
});
